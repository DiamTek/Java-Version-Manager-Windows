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
    [string]$TargetDir
)

$ErrorActionPreference = 'Stop'
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
    $paddedActivity = $Activity.PadRight(45)
    Write-Host ("`r[ ACTION ] [{0}] {1,3}%  {2}" -f $bar, $clamped, $paddedActivity) -NoNewline -ForegroundColor Cyan
}

# 1. Determine destination directory
Update-Progress -Percent 5 -Activity "Initializing environment..."

$normTarget = if ($TargetDir -and (Test-Path $TargetDir)) { (Resolve-Path $TargetDir).Path } else { $null }
$isDevRepo = $normTarget -and ((Test-Path (Join-Path $normTarget ".git")) -or (Test-Path (Join-Path $normTarget "..\.git")))

if ($normTarget -and -not $isDevRepo) {
    $installDir = $normTarget
} else {
    $installDir = "$env:LOCALAPPDATA\DiamTek\JVM\bin"
}

if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
$batPath = Join-Path $installDir "jvm.bat"
$repoRoot = if ($installDir.EndsWith("\bin", [StringComparison]::OrdinalIgnoreCase)) { Split-Path $installDir -Parent } else { $installDir }

Update-Progress -Percent 15 -Activity "Resolving latest release from GitHub..."
$rawBranch = "main"
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

$cacheBuster = [DateTimeOffset]::UtcNow.Ticks
$noCacheHeaders = @{ 'Cache-Control' = 'no-cache'; 'Pragma' = 'no-cache' }
$url = "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/$rawBranch/jvm.bat?t=$cacheBuster"

Update-Progress -Percent 35 -Activity "Fetching core JVM engine..."
if (-not $Update -and (Test-Path "$PSScriptRoot\jvm.bat")) {
    $content = [System.IO.File]::ReadAllText("$PSScriptRoot\jvm.bat")
} else {
    $content = (Invoke-WebRequest -Uri $url -Headers $noCacheHeaders -UseBasicParsing).Content
}

# 2. Integrity Check
if ($content.Length -eq 0 -or $content -notmatch "rem END OF SCRIPT") {
    Write-Host ""
    Write-Host "[ ERROR  ] Download failed integrity check. File is empty or truncated." -ForegroundColor Red
    exit 1
}

Update-Progress -Percent 50 -Activity "Sanitizing code format and encoding..."
$lines = ($content.Replace([char]160, ' ') -split "\r?\n")
[System.IO.File]::WriteAllLines($batPath, $lines, (New-Object System.Text.UTF8Encoding($false)))

Update-Progress -Percent 65 -Activity "Fetching documentation, license, & uninstaller..."
try {
    if (-not $Update -and (Test-Path "$PSScriptRoot\LICENSE")) { Copy-Item "$PSScriptRoot\LICENSE" "$repoRoot\LICENSE" -Force }
    else { Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/$rawBranch/LICENSE?t=$cacheBuster" -Headers $noCacheHeaders -OutFile "$repoRoot\LICENSE" -UseBasicParsing }

    if (-not $Update -and (Test-Path "$PSScriptRoot\README.md")) { Copy-Item "$PSScriptRoot\README.md" "$repoRoot\README.md" -Force }
    else { Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/$rawBranch/README.md?t=$cacheBuster" -Headers $noCacheHeaders -OutFile "$repoRoot\README.md" -UseBasicParsing }

    if (-not $Update -and (Test-Path "$PSScriptRoot\uninstall.ps1")) {
        Copy-Item "$PSScriptRoot\uninstall.ps1" "$repoRoot\uninstall.ps1" -Force
    } else {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/$rawBranch/uninstall.ps1?t=$cacheBuster" -Headers $noCacheHeaders -OutFile "$repoRoot\uninstall.ps1" -UseBasicParsing
    }
    if (Test-Path "$installDir\uninstall.ps1" -and ((Resolve-Path "$installDir\uninstall.ps1").Path -ne (Resolve-Path "$repoRoot\uninstall.ps1").Path)) {
        Remove-Item "$installDir\uninstall.ps1" -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-Host ""
    Write-Host "           [WARN] Could not fetch LICENSE/README/uninstall.ps1. Proceeding anyway." -ForegroundColor Yellow
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
    Set-ItemProperty -Path $uninstallRegPath -Name "DisplayIcon" -Value "$env:SystemRoot\System32\shell32.dll,31"
    Set-ItemProperty -Path $uninstallRegPath -Name "URLInfoAbout" -Value "https://diamtek.github.io/Java-Version-Manager-Windows"
    Set-ItemProperty -Path $uninstallRegPath -Name "HelpLink" -Value "https://github.com/DiamTek/Java-Version-Manager-Windows/issues"
    Set-ItemProperty -Path $uninstallRegPath -Name "NoModify" -Value 1 -Type DWord
    Set-ItemProperty -Path $uninstallRegPath -Name "NoRepair" -Value 1 -Type DWord

    # Start Menu Shortcuts
    $startMenuPrograms = [Environment]::GetFolderPath('Programs')
    $startMenuDir = Join-Path $startMenuPrograms "DiamTek"
    if (-not (Test-Path $startMenuDir)) { New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null }
    
    $wshell = New-Object -ComObject WScript.Shell
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