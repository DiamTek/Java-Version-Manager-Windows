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

if (-not $PSBoundParameters.ContainsKey('Channel') -and $env:JVM_CHANNEL) {
    $Channel = $env:JVM_CHANNEL
}
if (-not $PSBoundParameters.ContainsKey('Branch') -and $env:JVM_BRANCH) {
    $Branch = $env:JVM_BRANCH
}

if ($Branch) {
    if ($Branch -notmatch '^[a-zA-Z0-9_.\-]+(/[a-zA-Z0-9_.\-]+)*$' -or $Branch -match '\.\.') {
        Write-Host "[ ERROR  ] Invalid branch or tag name: '$Branch'" -ForegroundColor Red
        exit 1
    }
}

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$isFullLanguage = ($ExecutionContext.SessionState.LanguageMode -eq 'FullLanguage')

if ($isFullLanguage) {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072 -bor 12288
    } catch { }

    try {
        if ([System.Net.WebRequest]::DefaultWebProxy) {
            [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        }
    } catch { }
}

if ($PSVersionTable.PSVersion.Major -ge 6) {
    $PSDefaultParameterValues['Invoke-WebRequest:ProxyUseDefaultCredentials'] = $true
    $PSDefaultParameterValues['Invoke-RestMethod:ProxyUseDefaultCredentials'] = $true
}

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

function Get-FileSha256 {
    param([string]$Path)
    if (Get-Command Get-FileHash -ErrorAction SilentlyContinue) {
        try {
            return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLower()
        } catch {}
    }
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead((Resolve-Path $Path))
    try {
        $hashBytes = $sha256.ComputeHash($stream)
        return ([System.BitConverter]::ToString($hashBytes) -replace '-','').ToLower()
    } finally {
        $stream.Close()
        $sha256.Dispose()
    }
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
if (-not $Update -and $PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "jvm.bat"))) {
    $content = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot "jvm.bat"))
} else {
    $content = $null
    # If on a tagged release on Stable channel, attempt direct release asset download to preserve exact binary layout
    if ($Channel -ne "Nightly" -and $rawBranch -match '^v?[0-9]') {
        try {
            $relUrl = "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/$rawBranch/jvm.bat"
            $tempBatPath = "$batPath.tmp.$([System.IO.Path]::GetRandomFileName())"
            Invoke-WebRequest -Uri $relUrl -Headers $noCacheHeaders -OutFile $tempBatPath -UseBasicParsing -TimeoutSec 10
            if ((Test-Path $tempBatPath) -and (Get-Item $tempBatPath).Length -gt 0) {
                $content = [System.IO.File]::ReadAllText($tempBatPath)
            }
            Remove-Item $tempBatPath -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    if (-not $content) {
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
                $rawWget = Invoke-WebRequest -Uri $url -Headers $noCacheHeaders -UseBasicParsing -TimeoutSec 5
                $content = if ($rawWget.Content -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($rawWget.Content) } else { [string]$rawWget.Content }
            } catch {}
        }
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
            $resp = Invoke-WebRequest -Uri "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/$rawBranch/SHA256SUMS.txt" -Headers $noCacheHeaders -UserAgent "DiamTek-JVM" -UseBasicParsing -TimeoutSec 5
            $shaText = if ($resp.Content -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($resp.Content) } else { [string]$resp.Content }
        } catch {
            try {
                $shaText = (Invoke-RestMethod -Uri "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/$rawBranch/SHA256SUMS.txt" -Headers $noCacheHeaders -UserAgent "DiamTek-JVM" -TimeoutSec 5)
            } catch {
                try {
                    $relJson = (Invoke-RestMethod -Uri "https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/releases/tags/$rawBranch" -UserAgent "DiamTek-JVM")
                    $asset = $relJson.assets | Where-Object { $_.name -eq "SHA256SUMS.txt" } | Select-Object -First 1
                    if ($asset) {
                        $rawAsset = Invoke-WebRequest -Uri $asset.browser_download_url -UserAgent "DiamTek-JVM" -UseBasicParsing -TimeoutSec 5
                        $shaText = if ($rawAsset.Content -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($rawAsset.Content) } else { [string]$rawAsset.Content }
                    }
                } catch {}
            }
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
$sanitizedContent = ($content -replace "`r?`n", "`r`n").Replace([char]160, ' ')

# Stage to an isolated temporary file first to prevent TOCTOU and avoid clobbering existing installation on failure
$stageBat = "$batPath.stage.$([Guid]::NewGuid().ToString('N')).tmp"
[System.IO.File]::WriteAllText($stageBat, $sanitizedContent, (New-Object System.Text.UTF8Encoding($false)))

# Verify jvm.bat SHA256 integrity on the staged file
$actualJvmHash = Get-FileSha256 -Path $stageBat
if ($shaHashMap.ContainsKey("jvm.bat")) {
    $expectedJvmHash = $shaHashMap["jvm.bat"]
    if ($actualJvmHash -ne $expectedJvmHash) {
        Write-Host ""
        Write-Host "[ ERROR  ] Cryptographic integrity check failed for jvm.bat!" -ForegroundColor Red
        Write-Host "           Expected: $expectedJvmHash" -ForegroundColor Red
        Write-Host "           Computed: $actualJvmHash" -ForegroundColor Red
        Write-Host "           Installation aborted to prevent untrusted execution." -ForegroundColor Red
        Remove-Item -LiteralPath $stageBat -Force -ErrorAction SilentlyContinue
        exit 1
    }
} elseif ($Channel -ne "Nightly" -and $rawBranch -match '^v?[0-9]') {
    Write-Host ""
    Write-Host "[ ERROR  ] Cryptographic integrity manifest (SHA256SUMS.txt) required for official release $rawBranch on Stable channel." -ForegroundColor Red
    Write-Host "           Could not verify jvm.bat hash against release manifest. Aborting installation." -ForegroundColor Red
    Remove-Item -LiteralPath $stageBat -Force -ErrorAction SilentlyContinue
    exit 1
}

# Move verified staged engine into place atomically
Move-Item -LiteralPath $stageBat -Destination $batPath -Force

Update-Progress -Percent 65 -Activity "Fetching documentation, license, & uninstaller..."
if (-not (Test-Path $repoRoot)) { New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null }
$companionFiles = @("LICENSE", "README.md", "uninstall.ps1", "assets/icon.ico", "assets/icon.png")
foreach ($cf in $companionFiles) {
    $destFile = Join-Path $repoRoot ($cf -replace '/', '\')
    $destDir = Split-Path $destFile -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    $localSource = if ($PSScriptRoot) { Join-Path $PSScriptRoot ($cf -replace '/', '\') } else { $null }
    if ($localSource -and (Test-Path $localSource)) {
        Copy-Item $localSource $destFile -Force
    } else {
        $downloadSuccess = $false
        $baseName = Split-Path $destFile -Leaf
        if ($Channel -ne "Nightly" -and $rawBranch -match '^v?[0-9]' -and @("LICENSE", "README.md", "uninstall.ps1") -contains $baseName) {
            try {
                $relAssetUrl = "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/$rawBranch/$baseName"
                Invoke-WebRequest -Uri $relAssetUrl -Headers $noCacheHeaders -OutFile $destFile -UseBasicParsing -TimeoutSec 10
                if ((Test-Path $destFile) -and (Get-Item $destFile).Length -gt 0) {
                    $downloadSuccess = $true
                }
            } catch {}
        }
        if (-not $downloadSuccess) {
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
        }
        if ($downloadSuccess -and (Test-Path $destFile)) {
            $baseName = Split-Path $destFile -Leaf
            if ($shaHashMap.ContainsKey($baseName)) {
                $actualCfHash = Get-FileSha256 -Path $destFile
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

function Normalize-PathEntry([string]$p) {
    if (-not $p) { return "" }
    $clean = $p.Trim().Trim('`"').Trim("'").Trim()
    if ($clean.Length -gt 3) {
        return $clean.TrimEnd('\', '/')
    }
    return $clean
}

$userPath = ""
$existingKind = [Microsoft.Win32.RegistryValueKind]::ExpandString
try {
    $envKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment")
    if ($null -ne $envKey) {
        try {
            $raw = $envKey.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            if ($null -ne $raw) { $userPath = [string]$raw }
            $existingKind = try { $envKey.GetValueKind("Path") } catch { [Microsoft.Win32.RegistryValueKind]::ExpandString }
        } finally {
            $envKey.Close()
        }
    }
} catch {
    try {
        $userPath = (Get-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -ErrorAction SilentlyContinue).Path
    } catch { }
}

$pathArray = @($userPath -split ';' | Where-Object { $_ -ne '' } | ForEach-Object { Normalize-PathEntry $_ })
$normalizedInstallDir = Normalize-PathEntry $installDir

if ($normalizedInstallDir -notin $pathArray) {
    $newPathList = @()
    foreach ($p in ($pathArray + $normalizedInstallDir)) {
        if ($p -and ($newPathList -notcontains $p)) { $newPathList += $p }
    }
    $newPath = $newPathList -join ';'

    # Query Machine PATH to compute effective Combined PATH
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $combinedLength = if ($machinePath) { $machinePath.Length + 1 + $newPath.Length } else { $newPath.Length }

    if ($combinedLength -gt 8191) {
        Write-Host ""
        Write-Host "[ ERROR  ] Combined PATH length ($combinedLength chars) exceeds Windows 8191-character limit!" -ForegroundColor Red
        Write-Host "           System PATH ($($machinePath.Length) chars) + User PATH ($($newPath.Length) chars)." -ForegroundColor Red
        Write-Host "           Modification aborted to prevent environment block corruption." -ForegroundColor Red
    } else {
        if ($combinedLength -gt 2048) {
            Write-Host ""
            Write-Host "[ WARNING] Combined PATH length ($combinedLength chars) exceeds 2048 characters (User: $($newPath.Length), System: $($machinePath.Length))." -ForegroundColor Yellow
            Write-Host "           Some legacy Win32 applications may truncate PATH." -ForegroundColor Yellow
        }

        # Preserve REG_SZ only if existing was String and no variable references exist; otherwise enforce ExpandString
        $targetKind = if ($existingKind -eq [Microsoft.Win32.RegistryValueKind]::String -and $newPath -notmatch '%') {
            [Microsoft.Win32.RegistryValueKind]::String
        } else {
            [Microsoft.Win32.RegistryValueKind]::ExpandString
        }

        try {
            Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $newPath -Type $targetKind -Force
        } catch {
            [Microsoft.Win32.Registry]::SetValue("HKEY_CURRENT_USER\Environment", "Path", $newPath, $targetKind)
        }

        # Broadcast WM_SETTINGCHANGE safely
        try {
            if (-not ("Win32.NativeMethods" -as [type])) {
                $code = @'
[DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
                Add-Type -MemberDefinition $code -Name NativeMethods -Namespace Win32 -ErrorAction SilentlyContinue
            }
            $HWND_BROADCAST = [IntPtr]0xFFFF
            $WM_SETTINGCHANGE = 0x001A
            $result = [UIntPtr]::Zero
            [Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result) | Out-Null
        } catch { }
    }
}

# 4. Install PowerShell Profile Hook natively
Update-Progress -Percent 90 -Activity "Configuring PowerShell profile..."
$profileCode = @'
# >>> jvm >>>
function jvm {
    $bat = '__FALLBACK_BAT__'
    if (-not (Test-Path -LiteralPath $bat)) {
        $bat = Get-Command jvm.bat -CommandType Application -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
    }

    # Handle UNC directory paths via pushd
    $isUnc = ($pwd.Provider.Name -eq 'FileSystem' -and $pwd.Path -like '\\*')
    if ($isUnc) {
        pushd -LiteralPath $pwd.Path
        try {
            & $bat @args
        } finally {
            popd
        }
    } else {
        & $bat @args
    }

    function Set-JvmVar {
        param([string]$Name, [string]$OldValue, [string]$NewValue)

        $allowedVars = @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME')
        if ($allowedVars -notcontains $Name) { return }

        if ($OldValue) { $OldValue = $OldValue.Trim('`"').TrimEnd('\') }
        if ($NewValue) { $NewValue = $NewValue.Trim('`"').TrimEnd('\') }

        # Validate NewValue is a genuine directory and contains no injection characters
        if (-not [string]::IsNullOrWhiteSpace($NewValue)) {
            if ($NewValue -match '[\0;&|<>`"\r\n\$%]') { return }
            if (-not (Test-Path -LiteralPath $NewValue -PathType Container)) { return }

            # Storage boundary enforcement
            $canonicalPath = (Resolve-Path -LiteralPath $NewValue -ErrorAction SilentlyContinue).Path
            $allowedRoots = @(
                "$env:LOCALAPPDATA\DiamTek\JVM",
                "$env:LOCALAPPDATA\JavaVersionManager",
                "$env:ProgramFiles\Java",
                "${env:ProgramFiles(x86)}\Java",
                "$env:USERPROFILE\.jdks"
            )
            $isAllowed = $false
            foreach ($root in $allowedRoots) {
                $normRoot = $root.TrimEnd('\')
                $rootPrefix = $normRoot + '\'
                if ($canonicalPath -and ($canonicalPath.Equals($normRoot, [StringComparison]::OrdinalIgnoreCase) -or $canonicalPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase))) {
                    $isAllowed = $true
                    break
                }
            }
            if (-not $isAllowed) { return }
        }

        # CLM-compliant environment update
        Set-Item -Path "env:$Name" -Value $NewValue -Force

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
        $lines = Get-Content $sessionFile -ErrorAction SilentlyContinue
        Remove-Item $sessionFile -Force -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            if ($line -match '^([A-Za-z0-9_]+)=(.*)$') {
                $key = $matches[1]
                $val = $matches[2]
            } else {
                $key = 'JAVA_HOME'
                $val = $line
            }
            $old = (Get-Item -Path "env:$key" -ErrorAction SilentlyContinue).Value
            Set-JvmVar -Name $key -OldValue $old -NewValue $val
        }
    } else {
        foreach ($v in @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME')) {
            $old = (Get-Item -Path "env:$v" -ErrorAction SilentlyContinue).Value
            $new = (Get-ItemProperty -Path 'HKCU:\Environment' -Name $v -ErrorAction SilentlyContinue).$v
            if ([string]::IsNullOrEmpty($new)) {
                $new = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name $v -ErrorAction SilentlyContinue).$v
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

$batPathEscaped = $batPath.Replace("'", "''")
$profileCode = $profileCode.Replace('__FALLBACK_BAT__', $batPathEscaped)

$userProfile = [Environment]::GetFolderPath('UserProfile')
$myDocs = [Environment]::GetFolderPath('MyDocuments')
$regDocs = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -Name 'Personal' -ErrorAction SilentlyContinue).Personal
$expandedDocs = if ($regDocs) { [System.Environment]::ExpandEnvironmentVariables($regDocs) } else { $null }

$profiles = @(
    $PROFILE,
    (Join-Path $userProfile 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $userProfile 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $myDocs 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $myDocs 'PowerShell\Microsoft.PowerShell_profile.ps1')
)
if ($expandedDocs) {
    $profiles += (Join-Path $expandedDocs 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
    $profiles += (Join-Path $expandedDocs 'PowerShell\Microsoft.PowerShell_profile.ps1')
}
$profiles = $profiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

$utf8 = New-Object System.Text.UTF8Encoding($true)
foreach ($p in $profiles) {
    if ([string]::IsNullOrWhiteSpace($p)) { continue }
    try {
        $profileDir = Split-Path $p
        if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force -ErrorAction SilentlyContinue | Out-Null }
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
    } catch { }
}

# 5. Register Windows Uninstaller & Start Menu Shortcuts
Update-Progress -Percent 96 -Activity "Registering Windows uninstaller & shortcuts..."
try {
    # Windows Settings / Control Panel 'Installed Apps' Registration
    $uninstallRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM"
    if (-not (Test-Path $uninstallRegPath)) { New-Item -Path $uninstallRegPath -Force | Out-Null }
    
    $sys32Dir = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
    $systemPowerShell = Join-Path $sys32Dir "WindowsPowerShell\v1.0\powershell.exe"
    if (-not (Test-Path $systemPowerShell)) { $systemPowerShell = "powershell.exe" }
    $uninstallScriptPath = "$repoRoot\uninstall.ps1"
    $uninstallCommand = "`"$systemPowerShell`" -NoProfile -ExecutionPolicy Bypass -File `"$uninstallScriptPath`""
    
    $displayVer = "1.0.1"
    if (Test-Path $batPath) {
        $batHead = Get-Content $batPath -Raw -ErrorAction SilentlyContinue
        if ($batHead -match 'set\s+"JVM_VERSION=(.*?)"') {
            $displayVer = $matches[1].Trim()
        }
    }

    Set-ItemProperty -Path $uninstallRegPath -Name "DisplayName" -Value "DiamTek Java Version Manager"
    Set-ItemProperty -Path $uninstallRegPath -Name "DisplayVersion" -Value $displayVer
    Set-ItemProperty -Path $uninstallRegPath -Name "Publisher" -Value "DiamTek / Alexéy Shishkin"
    Set-ItemProperty -Path $uninstallRegPath -Name "InstallLocation" -Value $repoRoot
    Set-ItemProperty -Path $uninstallRegPath -Name "UninstallString" -Value $uninstallCommand
    Set-ItemProperty -Path $uninstallRegPath -Name "QuietUninstallString" -Value $uninstallCommand
    $iconPath = Join-Path $repoRoot "assets\icon.ico"
    if (-not (Test-Path $iconPath)) { $iconPath = Join-Path $repoRoot "icon.ico" }
    if (-not (Test-Path $iconPath)) { $iconPath = Join-Path $sys32Dir "shell32.dll,27" }

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
                # Strip JSONC comments (block comments /* ... */ and line comments // ...) and trailing commas
                $cleanJson = $wtContent -replace '(?s)/\*.*?\*/', '' -replace '(?m)(?<!:)\/\/.*$', '' -replace ',\s*([\}\]])', '$1'
                $wtJson = $cleanJson | ConvertFrom-Json
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
    $shortcut.TargetPath = $systemPowerShell
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$uninstallScriptPath`""
    $shortcut.IconLocation = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::System)) "shell32.dll,31"
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