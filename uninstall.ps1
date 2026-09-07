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
    [switch]$DeleteJava
)

$ErrorActionPreference = 'Continue'

Write-Host ""
Write-Host "============================================================"
Write-Host "         Java Version Manager - Uninstaller"
Write-Host "============================================================"
Write-Host ""

# ----------------------------------------------------------------
# PATH cleanup - remove ALL known JVM install locations from User PATH.
# Machine PATH is read-only without elevation; we attempt it silently
# and skip if it fails (JVM never writes to Machine PATH in normal use).
# ----------------------------------------------------------------
Write-Host "[ ACTION ] Removing JVM from system PATH..." -ForegroundColor Cyan

$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$jvmLocations = @(
    "$localAppData\DiamTek\JVM\bin",
    "$localAppData\DiamTek\JVM\current\bin"
)

# Also remove the script's own directory if it differs (dev-workspace installs)
$scriptDir = Split-Path -Parent $PSCommandPath
if ($scriptDir -and ($jvmLocations -notcontains $scriptDir)) {
    $jvmLocations += $scriptDir
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
    $cleanUser = ($userPath -split ';' | Where-Object { $_ -and ($jvmLocations -notcontains $_) }) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $cleanUser, 'User')
    Write-Host "[   OK   ] User PATH cleaned." -ForegroundColor Green
}

# Attempt Machine PATH cleanup (silently skipped if no elevation)
try {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if ($machinePath) {
        $cleanMachine = ($machinePath -split ';' | Where-Object { $_ -and ($jvmLocations -notcontains $_) }) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $cleanMachine, 'Machine')
    }
} catch { <# No elevation - skip silently #> }

# Broadcast WM_SETTINGCHANGE so running terminals pick up the new PATH
try {
    if (-not ('Win32.NativeMethods' -as [type])) {
        Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
    }
    $HWND_BROADCAST = [IntPtr]0xFFFF
    $WM_SETTINGCHANGE = 0x001A
    $result = [UIntPtr]::Zero
    [Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result) | Out-Null
} catch { <# Non-critical - ignore #> }

# ----------------------------------------------------------------
# PowerShell profile hook removal - all PS versions
# ----------------------------------------------------------------
Write-Host "[ ACTION ] Removing PowerShell Profile Hook..." -ForegroundColor Cyan
$userProfileDir = [Environment]::GetFolderPath('UserProfile')
$profiles = @(
    (Join-Path $userProfileDir "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path $userProfileDir "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"),
    $PROFILE
) | Select-Object -Unique

$blockPattern = '(?s)# >>> jvm >>>.*?# <<< jvm <<<'
foreach ($p in $profiles) {
    if (Test-Path $p) {
        $profContent = Get-Content $p -Raw -ErrorAction SilentlyContinue
        $m = [Regex]::Match($profContent, $blockPattern)
        if ($m.Success) {
            $profContent = $profContent.Remove($m.Index, $m.Length).Trim()
            if ([string]::IsNullOrWhiteSpace($profContent)) {
                Remove-Item $p -Force -ErrorAction SilentlyContinue
            } else {
                Set-Content -Path $p -Value $profContent -Encoding UTF8
            }
            Write-Host "[   OK   ] Profile hook removed from: $p" -ForegroundColor Green
        }
    }
}

# ----------------------------------------------------------------
# Environment variables
# ----------------------------------------------------------------
Write-Host "`n[ ACTION ] Cleaning up Environment Variables..." -ForegroundColor Cyan
$vars = @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME')
$removedVars = 0
foreach ($v in $vars) {
    foreach ($scope in @('User', 'Machine')) {
        try {
            $val = [Environment]::GetEnvironmentVariable($v, $scope)
            if ($val) {
                [Environment]::SetEnvironmentVariable($v, $null, $scope)
                $removedVars++
            }
        } catch { <# Machine scope may need elevation - skip silently #> }
    }
}
Write-Host "[   OK   ] Removed $removedVars environment variables." -ForegroundColor Green

# ----------------------------------------------------------------
# Registry uninstall entry + Start Menu shortcuts
# ----------------------------------------------------------------
Write-Host "`n[ ACTION ] Removing Windows Uninstall Registry & Shortcuts..." -ForegroundColor Cyan
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM" -Recurse -Force -ErrorAction SilentlyContinue
try { Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM" -Recurse -Force -ErrorAction SilentlyContinue } catch {}

$startMenuDirs = @(
    (Join-Path ([Environment]::GetFolderPath('Programs')) "DiamTek"),
    (Join-Path ([Environment]::GetFolderPath('CommonPrograms')) "DiamTek")
)
foreach ($sm in $startMenuDirs) {
    if (Test-Path $sm) {
        Remove-Item -Path $sm -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[   OK   ] Removed Start Menu folder: $sm" -ForegroundColor Green
    }
}
Write-Host "[   OK   ] Windows uninstall registration removed." -ForegroundColor Green

# ----------------------------------------------------------------
# AppData folder - always removed on a complete uninstall
# ----------------------------------------------------------------
Write-Host "`n[ ACTION ] Deleting JVM AppData folder..." -ForegroundColor Cyan
$diamtekAppData = Join-Path $localAppData "DiamTek"
$jvmAppData = Join-Path $diamtekAppData "JVM"
if (Test-Path $jvmAppData) {
    Remove-Item $jvmAppData -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[   OK   ] Deleted: $jvmAppData" -ForegroundColor Green
} else {
    Write-Host "[   OK   ] AppData folder already missing." -ForegroundColor Green
}

if (Test-Path $diamtekAppData) {
    $remaining = Get-ChildItem $diamtekAppData -Force -ErrorAction SilentlyContinue
    if (-not $remaining) {
        Remove-Item $diamtekAppData -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[   OK   ] Cleaned up parent directory: $diamtekAppData" -ForegroundColor Green
    }
}

# ----------------------------------------------------------------
# JDK folder - prompt because C:\Program Files\Java is sensitive
# ----------------------------------------------------------------
Write-Host ""
Write-Host "============================================================"
Write-Host "[ WARNING] JVM installs JDKs into 'C:\Program Files\Java'." -ForegroundColor Yellow
$shouldDeleteJava = $DeleteJava -or $false
if (-not $shouldDeleteJava -and -not $Quiet) {
    $confirmJava = Read-Host "Do you want to PERMANENTLY DELETE 'C:\Program Files\Java' and ALL installed JDKs? (y/N)"
    if ($confirmJava -match '^y') {
        $shouldDeleteJava = $true
    }
}

if ($shouldDeleteJava) {
    if (Test-Path "C:\Program Files\Java") {
        Write-Host "[ ACTION ] Deleting C:\Program Files\Java..." -ForegroundColor Cyan
        $deleted = $false
        try {
            Remove-Item "C:\Program Files\Java" -Recurse -Force -ErrorAction Stop
            $deleted = $true
        } catch {
            Write-Host "[ ACTION ] Requesting Administrator privileges to delete 'C:\Program Files\Java'..." -ForegroundColor Cyan
            try {
                $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Remove-Item -Path 'C:\Program Files\Java' -Recurse -Force -ErrorAction SilentlyContinue`"" -Verb RunAs -Wait -PassThru
                if (-not (Test-Path "C:\Program Files\Java")) {
                    $deleted = $true
                }
            } catch {
                Write-Host "[ ERROR  ] Administrator elevation was declined or failed." -ForegroundColor Red
            }
        }

        if ($deleted -and (-not (Test-Path "C:\Program Files\Java"))) {
            Write-Host "[   OK   ] JDK installation directory deleted." -ForegroundColor Green
        } else {
            Write-Host "[ ERROR  ] Could not delete 'C:\Program Files\Java'. Please remove it manually." -ForegroundColor Red
        }
    } else {
        Write-Host "[  INFO  ] The directory 'C:\Program Files\Java' does not exist." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host "[   OK   ] Uninstallation Complete." -ForegroundColor Green
Write-Host "           Please close and restart all terminals for environment changes to take effect."
Write-Host ""
if (-not $Quiet) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}