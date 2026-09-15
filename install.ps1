# Java Version Manager
# Copyright (C) 2026 DiamTek / Alexéy Shishkin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

[CmdletBinding()]
param(
    [switch]$Quiet,
    [switch]$Update,
    [string]$TargetDir,
    [string]$Branch,
    [string]$Channel = "Stable"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$actionName = if ($Update) { "Updating" } else { "Installing" }
Write-Host "[ ACTION ] $actionName DiamTek Java Version Manager..." -ForegroundColor Cyan

function Update-Progress {
    param(
        [int]$Percent,
        [string]$Activity
    )
    if ($Quiet) { return }
    $clamped = [math]::Max(0, [math]::Min(100, $Percent))
    $barLength = 30
    $filled = [math]::Floor(($clamped / 100) * $barLength)
    $empty = $barLength - $filled
    $bar = ('=' * $filled) + (' ' * $empty)
    $paddedActivity = $Activity.PadRight(52)
    Write-Host ("`r[ ACTION ] [{0}] {1,3}%  {2}$([char]27)[K" -f $bar, $clamped, $paddedActivity) -NoNewline -ForegroundColor Cyan
}

# 1. Determine destination directory
Update-Progress -Percent 5 -Activity "Initializing environment..."

$normTarget = if ($TargetDir -and (Test-Path $TargetDir)) { (Resolve-Path $TargetDir).Path } else { $null }

if ($normTarget) {
    $installDir = $normTarget
} else {
    $installDir = "$env:LOCALAPPDATA\DiamTek\JVM\bin"
}

if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
$batPath = Join-Path $installDir "jvm.bat"
$repoRoot = if ($installDir.EndsWith("\bin", [StringComparison]::OrdinalIgnoreCase)) { Split-Path $installDir -Parent } else { $installDir }

Update-Progress -Percent 15 -Activity "Resolving latest release from GitHub..."
$rawBranch = if ($Branch) { $Branch } else { "" }
if (-not $rawBranch) {
    if ($Channel -ne "Nightly") {
        try {
            $apiReq = [Net.HttpWebRequest]::Create("https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/releases/latest")
            $apiReq.UserAgent = "DiamTek-JVM"
            $apiReq.Timeout = 3000
            $apiRes = $apiReq.GetResponse()
            $sr = New-Object System.IO.StreamReader($apiRes.GetResponseStream())
            $json = $sr.ReadToEnd()
            $sr.Close(); $apiRes.Close()
            if ($json -match '"tag_name":\s*"([^"]+)"') {
                $rawBranch = $matches[1]
            }
        } catch {}
        if (-not $rawBranch) {
            try {
                $redirReq = [Net.HttpWebRequest]::Create("https://github.com/DiamTek/Java-Version-Manager-Windows/releases/latest")
                $redirReq.AllowAutoRedirect = $false
                $redirReq.UserAgent = "DiamTek-JVM"
                $redirReq.Timeout = 4000
                $redirRes = $redirReq.GetResponse()
                $loc = $redirRes.GetResponseHeader("Location")
                $redirRes.Close()
                if ($loc -and $loc -match '/releases/tag/([^/]+)$') {
                    $rawBranch = $matches[1]
                }
            } catch {}
        }
    }
    if (-not $rawBranch) {
        try {
            $apiReq = [Net.HttpWebRequest]::Create("https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/commits/main")
            $apiReq.UserAgent = "DiamTek-JVM"
            $apiReq.Timeout = 3000
            $apiRes = $apiReq.GetResponse()
            $sr = New-Object System.IO.StreamReader($apiRes.GetResponseStream())
            $json = $sr.ReadToEnd()
            $sr.Close(); $apiRes.Close()
            if ($json -match '"sha":\s*"([0-9a-f]{40})"') {
                $rawBranch = $matches[1]
            }
        } catch {
            $rawBranch = "HEAD"
        }
    }
}

$cacheBuster = [DateTimeOffset]::UtcNow.Ticks
$noCacheHeaders = @{ 'Cache-Control' = 'no-cache'; 'Pragma' = 'no-cache' }
$url = "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/$rawBranch/jvm.bat?t=$cacheBuster"

Update-Progress -Percent 35 -Activity "Fetching core JVM engine..."
if (-not $Update -and (Test-Path "$PSScriptRoot\jvm.bat")) {
    $content = [System.IO.File]::ReadAllText("$PSScriptRoot\jvm.bat")
} else {
    $content = $null
    try {
        $apiReq = [Net.HttpWebRequest]::Create("https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/contents/jvm.bat?ref=$rawBranch")
        $apiReq.Method = "GET"
        $apiReq.Timeout = 4000
        $apiReq.UserAgent = "DiamTek-JVM"
        $apiReq.Accept = "application/vnd.github.v3.raw"
        $apiReq.Headers.Add("Cache-Control", "no-cache")
        $apiReq.Headers.Add("Pragma", "no-cache")
        $apiRes = $apiReq.GetResponse()
        $sr = New-Object System.IO.StreamReader($apiRes.GetResponseStream())
        $content = $sr.ReadToEnd()
        $sr.Close(); $apiRes.Close()
    } catch {
        try {
            $content = (Invoke-WebRequest -Uri $url -Headers $noCacheHeaders -UseBasicParsing -TimeoutSec 5).Content
        } catch {}
    }
}

# 2. Integrity Check
if (-not $content -or $content.Length -eq 0 -or $content -notmatch "rem END OF SCRIPT") {
    Write-Host ""
    Write-Host "[ ERROR  ] Download failed integrity check. File is empty or truncated." -ForegroundColor Red
    exit 1
}

# Fetch SHA256SUMS.txt if on Stable channel / tagged release
$shaHashMap = @{}
if ($Channel -ne "Nightly" -and $rawBranch -match '^v?[0-9]') {
    try {
        $shaText = $null
        try {
            $shaText = (Invoke-WebRequest -Uri "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/$rawBranch/SHA256SUMS.txt" -Headers $noCacheHeaders -UserAgent "DiamTek-JVM" -UseBasicParsing -TimeoutSec 5).Content
        } catch {
            try {
                $relJson = (Invoke-RestMethod -Uri "https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/releases/tags/$rawBranch" -UserAgent "DiamTek-JVM")
                $asset = $relJson.assets | Where-Object { $_.name -eq "SHA256SUMS.txt" } | Select-Object -First 1
                if ($asset) {
                    $shaText = (Invoke-WebRequest -Uri $asset.browser_download_url -UserAgent "DiamTek-JVM" -UseBasicParsing -TimeoutSec 5).Content
                }
            } catch {}
        }
        if ($shaText) {
            foreach ($sLine in ($shaText -split "`r?`n")) {
                if ($sLine -match '^([0-9a-fA-F]{64})\s+[\*]?(.+)$') {
                    $shaHashMap[$matches[2].Trim()] = $matches[1].ToLower()
                }
            }
        }
    } catch {}
}

Update-Progress -Percent 50 -Activity "Sanitizing code format and encoding..."
$lines = ($content.Replace([char]160, ' ') -split "\r?\n")
[System.IO.File]::WriteAllLines($batPath, $lines, (New-Object System.Text.UTF8Encoding($false)))

# Verify jvm.bat SHA256 integrity
$actualJvmHash = (Get-FileHash -Path $batPath -Algorithm SHA256).Hash.ToLower()
if ($shaHashMap.ContainsKey("jvm.bat")) {
    $expectedJvmHash = $shaHashMap["jvm.bat"]
    if ($actualJvmHash -ne $expectedJvmHash) {
        Write-Host ""
        Write-Host "[ ERROR  ] Cryptographic integrity check failed for jvm.bat!" -ForegroundColor Red
        Write-Host "           Expected: $expectedJvmHash" -ForegroundColor Red
        Write-Host "           Computed: $actualJvmHash" -ForegroundColor Red
        Write-Host "           Installation aborted to prevent untrusted execution." -ForegroundColor Red
        Remove-Item -Path $batPath -Force -ErrorAction SilentlyContinue
        exit 1
    }
} elseif ($Channel -ne "Nightly" -and $rawBranch -match '^v?[1-9]') {
    Write-Host ""
    Write-Host "[ ERROR  ] Cryptographic integrity manifest (SHA256SUMS.txt) required for official release $rawBranch on Stable channel." -ForegroundColor Red
    Write-Host "           Could not verify jvm.bat hash against release manifest. Aborting installation." -ForegroundColor Red
    Remove-Item -Path $batPath -Force -ErrorAction SilentlyContinue
    exit 1
}

Update-Progress -Percent 65 -Activity "Fetching documentation, license, & uninstaller..."
if (-not (Test-Path $repoRoot)) { New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null }
$companionFiles = @("LICENSE", "README.md", "uninstall.ps1", "assets/icon.ico", "assets/icon.png")
foreach ($cf in $companionFiles) {
    $destFile = Join-Path $repoRoot ($cf -replace '/', '\')
    $destDir = Split-Path $destFile -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    $localSource = Join-Path $PSScriptRoot ($cf -replace '/', '\')
    if (Test-Path $localSource) {
        Copy-Item $localSource $destFile -Force
    } else {
        $downloadSuccess = $false
        try {
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/$rawBranch/$cf`?t=$cacheBuster" -Headers $noCacheHeaders -OutFile $destFile -UseBasicParsing -TimeoutSec 10
            $downloadSuccess = $true
        } catch {
            try {
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/HEAD/$cf`?t=$cacheBuster" -Headers $noCacheHeaders -OutFile $destFile -UseBasicParsing -TimeoutSec 10
                $downloadSuccess = $true
            } catch {
                if (-not (Test-Path $destFile)) {
                    Write-Host ""
                    Write-Host "           [WARN] Could not fetch $cf. Proceeding anyway." -ForegroundColor Yellow
                }
            }
        }
        if ($downloadSuccess -and (Test-Path $destFile)) {
            $baseName = Split-Path $destFile -Leaf
            if ($shaHashMap.ContainsKey($baseName)) {
                $actualCfHash = (Get-FileHash -Path $destFile -Algorithm SHA256).Hash.ToLower()
                $expectedCfHash = $shaHashMap[$baseName]
                if ($actualCfHash -ne $expectedCfHash) {
                    Write-Host ""
                    Write-Host "           [ ERROR  ] Integrity check failed for $baseName (SHA256 mismatch)!" -ForegroundColor Red
                    Write-Host "                      Expected: $expectedCfHash" -ForegroundColor Red
                    Write-Host "                      Computed: $actualCfHash" -ForegroundColor Red
                    Remove-Item -Path $destFile -Force -ErrorAction SilentlyContinue
                    if ($baseName -eq "uninstall.ps1" -and $Channel -ne "Nightly") {
                        Write-Host "           [ FATAL  ] Security-critical uninstaller failed integrity verification. Aborting." -ForegroundColor Red
                        exit 1
                    }
                }
            }
        }
    }
}
if ($installDir -ne $repoRoot) {
    $legacyUninstall = Join-Path $installDir "uninstall.ps1"
    if (Test-Path $legacyUninstall) {
        Remove-Item $legacyUninstall -Force -ErrorAction SilentlyContinue
    }
}
$channelFile = Join-Path $repoRoot "channel.txt"
if (-not (Test-Path $channelFile)) {
    $cVal = if ($Channel -eq "Nightly") { "NIGHTLY" } else { "STABLE" }
    [System.IO.File]::WriteAllText($channelFile, "$cVal`r`n")
}

# 3. Safe REG_EXPAND_SZ Path Injection
Update-Progress -Percent 80 -Activity "Configuring User PATH..."

$userPath = ""
$envKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment")
if ($null -ne $envKey) {
    try {
        $raw = $envKey.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if ($null -ne $raw) { $userPath = [string]$raw }
    } finally {
        $envKey.Close()
    }
}

$pathArray = $userPath -split ';' | Where-Object { $_ -ne '' }
if ($installDir -notin $pathArray) {
    $newPath = ($pathArray + $installDir) -join ';'
    [Microsoft.Win32.Registry]::SetValue("HKEY_CURRENT_USER\Environment", "Path", $newPath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
    
    # Broadcast WM_SETTINGCHANGE
    if (-not ("Win32.NativeMethods" -as [type])) {
        $code = '[DllImport("user32.dll")] public static extern bool SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam, int fuFlags, int uTimeout, out IntPtr lpdwResult);'
        Add-Type -MemberDefinition $code -Name NativeMethods -Namespace Win32
    }
    [Win32.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [IntPtr]0, 'Environment', 2, 5000, [ref][IntPtr]::Zero) | Out-Null
}

# 4. Install PowerShell Profile Hook natively
Update-Progress -Percent 90 -Activity "Configuring PowerShell profile..."
$profileCode = @'
# >>> jvm >>>
function jvm {
    $bat = Get-Command jvm.bat -CommandType Application -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
    if (-not $bat) { $bat = '__FALLBACK_BAT__' }
    & $bat @args

    function Set-JvmVar {
        param([string]$Name, [string]$OldValue, [string]$NewValue)

        if ($OldValue) { $OldValue = $OldValue.TrimEnd('\') }
        if ($NewValue) { $NewValue = $NewValue.TrimEnd('\') }

        [Environment]::SetEnvironmentVariable($Name, $NewValue, 'Process')

        $parts = $env:Path -split ';' | Where-Object { $_ -ne '' }
        if (-not [string]::IsNullOrWhiteSpace($OldValue)) {
            $parts = $parts | Where-Object { $_.TrimEnd('\') -ne "$OldValue\bin" }
        }
        if (-not [string]::IsNullOrWhiteSpace($NewValue)) {
            $parts = $parts | Where-Object { $_.TrimEnd('\') -ne "$NewValue\bin" }
            $parts = @("$NewValue\bin") + $parts
        }
        $env:Path = $parts -join ';'
    }

    $sessionFile = "$env:TEMP\.jvm_session_target"
    if (Test-Path $sessionFile) {
        foreach ($line in (Get-Content $sessionFile)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            if ($line -match '^([^=]+)=(.*)$') {
                $key = $matches[1]
                $val = $matches[2]
            } else {
                $key = 'JAVA_HOME'
                $val = $line
            }
            $old = [Environment]::GetEnvironmentVariable($key, 'Process')
            Set-JvmVar -Name $key -OldValue $old -NewValue $val
        }
        Remove-Item $sessionFile -Force
    } else {
        foreach ($v in @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME')) {
            $old = [Environment]::GetEnvironmentVariable($v, 'Process')
            $new = [Environment]::GetEnvironmentVariable($v, 'User')
            if ([string]::IsNullOrEmpty($new)) {
                $new = [Environment]::GetEnvironmentVariable($v, 'Machine')
            }
            if ($old -eq $new) { continue }
            Set-JvmVar -Name $v -OldValue $old -NewValue $new
        }
    }
}

if (Get-Command Register-ArgumentCompleter -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName @('jvm', 'jvm.bat', '.\jvm.bat') -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $subcommands = @(
            'list', 'ls', 'install', 'uninstall', 'rm', 'remove', 'use', 'default',
            'pin', 'local', 'current', 'status', 'info', 'whoami', 'which', 'path',
            'doctor', 'check', 'clean', 'prune', 'clear', 'update', 'self-update',
            'self-uninstall', 'open', 'home', 'exec', 'run', 'env', 'hook',
            'link', 'unlink', 'version', 'help', 'channel'
        )
        $candidates = @('java', 'maven', 'gradle', 'kotlin', 'scala', 'groovy')
        $vendors = @('adoptium', 'temurin', 'oracle', 'corretto', 'zulu', 'microsoft', 'graalvm', 'liberica', 'bellsoft', 'semeru', 'ibm', 'openj9')
        $openTargets = @('home', 'dir', 'bin', 'config', 'cache', 'downloads', 'backup', 'backups', 'links')
        $hookTargets = @('install', 'status', 'check', 'remove', 'uninstall')
        $flags = @(
            '--vendor', '--symlink', '--registry', '--legacy', '--session', '--global',
            '--skip-checksum', '--no-verify', '--latest', '--yes', '-y', '--no-color',
            '--channel', '--nightly', '--stable',
            '--version', '-v', '--help', '-h'
        )

        $elements = @($commandAst.CommandElements | ForEach-Object { $_.Extent.Text })
        $count = $elements.Count
        $prev = if ($wordToComplete -and $count -ge 2) { $elements[-2] } elseif (-not $wordToComplete -and $count -ge 1) { $elements[-1] } else { '' }

        $completions = @()
        if ($prev -in @('--vendor')) {
            $completions = $vendors
        } elseif ($prev -in @('channel', '--channel')) {
            $completions = @('stable', 'nightly')
        } elseif ($prev -in @('open', 'home')) {
            $completions = $openTargets
        } elseif ($prev -in @('hook')) {
            $completions = $hookTargets
        } elseif ($prev -in @('use', 'default', 'pin', 'local', 'uninstall', 'rm', 'remove', 'which', 'path')) {
            $installed = @()
            $linksDir = "$env:LOCALAPPDATA\JavaVersionManager\links"
            if (Test-Path -LiteralPath $linksDir) {
                $installed += @(Get-ChildItem -LiteralPath $linksDir -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
            }
            $jdksDir = "$env:USERPROFILE\.jdks"
            if (Test-Path -LiteralPath $jdksDir) {
                $installed += @(Get-ChildItem -LiteralPath $jdksDir -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
            }
            $completions = @($installed | Select-Object -Unique) + $candidates
        } elseif ($wordToComplete -like '-*') {
            $completions = $flags
        } else {
            $completions = $subcommands + $candidates + $flags
        }

        $completions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}
# <<< jvm <<<
'@

$profileCode = $profileCode.Replace('__FALLBACK_BAT__', $batPath)

$userProfile = [Environment]::GetFolderPath('UserProfile')
$profiles = @(
    $PROFILE,
    (Join-Path $userProfile 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $userProfile 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1')
) | Select-Object -Unique

$utf8 = New-Object System.Text.UTF8Encoding($true)
foreach ($p in $profiles) {
    if ([string]::IsNullOrWhiteSpace($p)) { continue }
    $profileDir = Split-Path $p
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    $profContent = ''
    if (Test-Path $p) { $profContent = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }

    $blockPattern = '(?s)# >>> jvm >>>.*?# <<< jvm <<<'
    $m = [Regex]::Match($profContent, $blockPattern)
    if ($m.Success) {
        $profContent = $profContent.Substring(0, $m.Index) + $profileCode + $profContent.Substring($m.Index + $m.Length)
    } else {
        $profContent = if ([string]::IsNullOrWhiteSpace($profContent)) { $profileCode } else { "$profContent`r`n`r`n$profileCode" }
    }
    [System.IO.File]::WriteAllText($p, $profContent, $utf8)
}

# 5. Register Windows Uninstaller & Start Menu Shortcuts
Update-Progress -Percent 96 -Activity "Registering Windows uninstaller & shortcuts..."
try {
    # Windows Settings / Control Panel 'Installed Apps' Registration
    $uninstallRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM"
    if (-not (Test-Path $uninstallRegPath)) { New-Item -Path $uninstallRegPath -Force | Out-Null }
    
    $uninstallScriptPath = "$repoRoot\uninstall.ps1"
    $uninstallCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$uninstallScriptPath`""
    
    Set-ItemProperty -Path $uninstallRegPath -Name "DisplayName" -Value "DiamTek Java Version Manager"
    Set-ItemProperty -Path $uninstallRegPath -Name "DisplayVersion" -Value "1.0.0"
    Set-ItemProperty -Path $uninstallRegPath -Name "Publisher" -Value "DiamTek / Alexéy Shishkin"
    Set-ItemProperty -Path $uninstallRegPath -Name "InstallLocation" -Value $repoRoot
    Set-ItemProperty -Path $uninstallRegPath -Name "UninstallString" -Value $uninstallCommand
    Set-ItemProperty -Path $uninstallRegPath -Name "QuietUninstallString" -Value $uninstallCommand
    $iconPath = Join-Path $repoRoot "assets\icon.ico"
    if (-not (Test-Path $iconPath)) { $iconPath = Join-Path $repoRoot "icon.ico" }
    if (-not (Test-Path $iconPath)) { $iconPath = "$env:SystemRoot\System32\shell32.dll,27" }

    Set-ItemProperty -Path $uninstallRegPath -Name "DisplayIcon" -Value $iconPath
    Set-ItemProperty -Path $uninstallRegPath -Name "URLInfoAbout" -Value "https://diamtek.github.io/Java-Version-Manager-Windows"
    Set-ItemProperty -Path $uninstallRegPath -Name "HelpLink" -Value "https://github.com/DiamTek/Java-Version-Manager-Windows/issues"
    Set-ItemProperty -Path $uninstallRegPath -Name "NoModify" -Value 1 -Type DWord
    Set-ItemProperty -Path $uninstallRegPath -Name "NoRepair" -Value 1 -Type DWord

    $totalBytes = (Get-ChildItem $repoRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $dotJvm = Join-Path $env:USERPROFILE ".jvm"
    if (Test-Path $dotJvm) {
        $totalBytes += (Get-ChildItem $dotJvm -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    }
    $estimatedSizeKB = [math]::Max(1024, [int][math]::Ceiling($totalBytes / 1KB))
    Set-ItemProperty -Path $uninstallRegPath -Name "EstimatedSize" -Value $estimatedSizeKB -Type DWord

    # Windows Terminal Profile Registration (if Windows Terminal is installed)
    $wtProfileAdded = $false
    $wtSettingsCandidates = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )
    foreach ($wtSettings in $wtSettingsCandidates) {
        if (Test-Path $wtSettings) {
            try {
                $wtContent = Get-Content $wtSettings -Raw -ErrorAction Stop
                $wtJson = $wtContent | ConvertFrom-Json
                if ($wtJson.profiles -and $wtJson.profiles.list) {
                    $existing = $wtJson.profiles.list | Where-Object { $_.guid -eq '{b20650a4-4212-4d64-9edf-744e9285e2be}' -or $_.name -eq 'Java Version Manager' }
                    if (-not $existing) {
                        $newProfile = [PSCustomObject]@{
                            commandline       = 'cmd.exe /c "%LOCALAPPDATA%\DiamTek\JVM\bin\jvm.bat"'
                            guid              = '{b20650a4-4212-4d64-9edf-744e9285e2be}'
                            hidden            = $false
                            icon              = '%LOCALAPPDATA%\DiamTek\JVM\assets\icon.png'
                            name              = 'Java Version Manager'
                            startingDirectory = '%USERPROFILE%'
                            closeOnExit       = 'always'
                        }
                        $profileList = [System.Collections.Generic.List[object]]@($wtJson.profiles.list)
                        $profileList.Add($newProfile)
                        $wtJson.profiles.list = $profileList
                        $newWtContent = $wtJson | ConvertTo-Json -Depth 32
                        Set-Content $wtSettings $newWtContent -Encoding utf8
                    } else {
                        $existing.commandline = 'cmd.exe /c "%LOCALAPPDATA%\DiamTek\JVM\bin\jvm.bat"'
                        $existing | Add-Member -NotePropertyName "closeOnExit" -NotePropertyValue "always" -Force
                        $newWtContent = $wtJson | ConvertTo-Json -Depth 32
                        Set-Content $wtSettings $newWtContent -Encoding utf8
                    }
                    $wtProfileAdded = $true
                }
            } catch {
                # Silently ignore if settings.json has non-standard formatting or comments
            }
        }
    }

    $hasWt = $wtProfileAdded -and [bool](Get-Command wt.exe -ErrorAction SilentlyContinue)
    $targetPath = if ($hasWt) { "wt.exe" } else { "cmd.exe" }
    $targetArgs = if ($hasWt) { "-p `"Java Version Manager`"" } else { "/c `"$batPath`"" }

    # Start Menu Shortcuts
    $startMenuPrograms = [Environment]::GetFolderPath('Programs')
    $startMenuDir = Join-Path $startMenuPrograms "DiamTek"
    if (-not (Test-Path $startMenuDir)) { New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null }
    
    $wshell = New-Object -ComObject WScript.Shell
    $appShortcut = $wshell.CreateShortcut((Join-Path $startMenuDir "Java Version Manager.lnk"))
    $appShortcut.TargetPath = $targetPath
    $appShortcut.Arguments = $targetArgs
    $appShortcut.IconLocation = $iconPath
    $appShortcut.Description = "DiamTek Java Version Manager"
    $appShortcut.WorkingDirectory = $repoRoot
    $appShortcut.Save()

    # Update pinned Taskbar shortcut if it exists
    $taskbarLnk = Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Java Version Manager.lnk"
    if (Test-Path $taskbarLnk) {
        $tbShortcut = $wshell.CreateShortcut($taskbarLnk)
        $tbShortcut.TargetPath = $targetPath
        $tbShortcut.Arguments = $targetArgs
        $tbShortcut.IconLocation = $iconPath
        $tbShortcut.WorkingDirectory = $repoRoot
        $tbShortcut.Save()
        (Get-Item $taskbarLnk).LastWriteTime = Get-Date
    }

    $shortcut = $wshell.CreateShortcut((Join-Path $startMenuDir "Uninstall Java Version Manager.lnk"))
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$uninstallScriptPath`""
    $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,31"
    $shortcut.Description = "Uninstall DiamTek Java Version Manager"
    $shortcut.Save()
} catch {
    Write-Host ""
    Write-Host "           [WARN] Could not register uninstaller shortcut: $($_.Exception.Message)" -ForegroundColor Yellow
}

Update-Progress -Percent 100 -Activity "Finalizing setup..."
Write-Host ""

if ($Update) {
    Write-Host "`n[   OK   ] Update Complete!" -ForegroundColor Green
} else {
    Write-Host "`n[   OK   ] Installation Complete!" -ForegroundColor Green
    Write-Host "           Open a new terminal and type 'jvm' to start.`n"
}