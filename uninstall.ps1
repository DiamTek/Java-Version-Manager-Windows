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
    [switch]$DeleteJava,
    [switch]$DeleteTarget,
    [string]$SourceDir
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

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

# Also remove SourceDir and its bin folder if provided
if ($SourceDir) {
    if ($jvmLocations -notcontains $SourceDir) { $jvmLocations += $SourceDir }
    $sourceBin = Join-Path $SourceDir "bin"
    if ($jvmLocations -notcontains $sourceBin) { $jvmLocations += $sourceBin }
}

# Also remove the script's own directory if it differs
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

$taskbarLnk = Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Java Version Manager.lnk"
if (Test-Path $taskbarLnk) {
    Remove-Item -Path $taskbarLnk -Force -ErrorAction SilentlyContinue
    Write-Host "[   OK   ] Removed pinned Taskbar shortcut." -ForegroundColor Green
}

# Windows Terminal Profile cleanup
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
                $filtered = @($wtJson.profiles.list | Where-Object { $_.guid -ne '{b20650a4-4212-4d64-9edf-744e9285e2be}' -and $_.name -ne 'Java Version Manager' })
                if ($filtered.Count -ne $wtJson.profiles.list.Count) {
                    $wtJson.profiles.list = $filtered
                    if ($wtJson.defaultProfile -eq '{b20650a4-4212-4d64-9edf-744e9285e2be}' -and $filtered.Count -gt 0) {
                        $wtJson.defaultProfile = $filtered[0].guid
                    }
                    $newWtContent = $wtJson | ConvertTo-Json -Depth 32
                    Set-Content $wtSettings $newWtContent -Encoding utf8
                    Write-Host "[   OK   ] Removed Windows Terminal profile." -ForegroundColor Green
                }
            }
        } catch { }
    }
}

# Cleanup temporary session files
Remove-Item -Path "$env:TEMP\.jvm_session_target" -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "jvm_*" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "[   OK   ] Windows uninstall registration removed." -ForegroundColor Green

# ----------------------------------------------------------------
# AppData & Ecosystem Candidate folders - always removed on a complete uninstall
# ----------------------------------------------------------------
Write-Host "`n[ ACTION ] Deleting JVM AppData and Candidate folders..." -ForegroundColor Cyan
$diamtekAppData = Join-Path $localAppData "DiamTek"
$jvmAppData = Join-Path $diamtekAppData "JVM"
if (Test-Path $jvmAppData) {
    try {
        Remove-Item -LiteralPath $jvmAppData -Recurse -Force -ErrorAction Stop
        Write-Host "[   OK   ] Deleted: $jvmAppData" -ForegroundColor Green
    } catch {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c cd /d `"$env:TEMP`" & timeout /t 1 >nul & rmdir /s /q `"$jvmAppData`"" -WindowStyle Hidden
        Write-Host "[   OK   ] Scheduled deletion of: $jvmAppData" -ForegroundColor Green
    }
} else {
    Write-Host "[   OK   ] AppData folder already missing." -ForegroundColor Green
}

if (Test-Path $diamtekAppData) {
    $remaining = Get-ChildItem -LiteralPath $diamtekAppData -Force -ErrorAction SilentlyContinue
    if (-not $remaining) {
        Remove-Item -LiteralPath $diamtekAppData -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[   OK   ] Cleaned up parent directory: $diamtekAppData" -ForegroundColor Green
    }
}

# Legacy and shared state folders
$legacyJvm = Join-Path $localAppData "JavaVersionManager"
if (Test-Path $legacyJvm) {
    Remove-Item -LiteralPath $legacyJvm -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[   OK   ] Cleaned up: $legacyJvm" -ForegroundColor Green
}

# Candidate tools and caches (Maven, Gradle, etc. in ~/.jvm)
$userJvmCandidates = Join-Path $userProfileDir ".jvm"
if (Test-Path $userJvmCandidates) {
    Remove-Item -LiteralPath $userJvmCandidates -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[   OK   ] Cleaned up candidates folder: $userJvmCandidates" -ForegroundColor Green
}

# ----------------------------------------------------------------
# JDK folder - only prompt if C:\Program Files\Java actually exists
# ----------------------------------------------------------------
$javaDir = if (Test-Path "C:\Program Files\Java") { "C:\Program Files\Java" } elseif ($env:ProgramFiles -and (Test-Path (Join-Path $env:ProgramFiles "Java"))) { Join-Path $env:ProgramFiles "Java" } else { $null }
if ($javaDir) {
    Write-Host ""
    Write-Host "============================================================"
    Write-Host "[ WARNING] JVM installs JDKs into '$javaDir'." -ForegroundColor Yellow
    $shouldDeleteJava = $DeleteJava -or $false
    if (-not $shouldDeleteJava -and -not $Quiet) {
        $confirmJava = Read-Host "Do you want to PERMANENTLY DELETE '$javaDir' and ALL installed JDKs? (y/N)"
        if ($confirmJava -match '^y') {
            $shouldDeleteJava = $true
        }
    }

    if ($shouldDeleteJava) {
        Write-Host "[ ACTION ] Deleting $javaDir..." -ForegroundColor Cyan
        $deleted = $false
        try {
            Remove-Item -LiteralPath $javaDir -Recurse -Force -ErrorAction Stop
            $deleted = $true
        } catch {
            Write-Host "[ ACTION ] Requesting Administrator privileges to delete '$javaDir'..." -ForegroundColor Cyan
            try {
                $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Remove-Item -LiteralPath '$javaDir' -Recurse -Force -ErrorAction SilentlyContinue`"" -Verb RunAs -Wait -PassThru
                if (-not (Test-Path $javaDir)) {
                    $deleted = $true
                }
            } catch {
                Write-Host "[ ERROR  ] Administrator elevation was declined or failed." -ForegroundColor Red
            }
        }

        if ($deleted -and (-not (Test-Path $javaDir))) {
            Write-Host "[   OK   ] JDK installation directory deleted." -ForegroundColor Green
        } else {
            Write-Host "[ ERROR  ] Could not delete '$javaDir'. Please remove it manually." -ForegroundColor Red
        }
    }
}

# ----------------------------------------------------------------
# Standalone / workspace cleanup (if running from a portable copy outside AppData)
# ----------------------------------------------------------------
$targetFolder = $null
if ($SourceDir -and (Test-Path $SourceDir)) {
    $targetFolder = (Resolve-Path $SourceDir).Path
} elseif ($scriptDir -and (Test-Path $scriptDir)) {
    $targetFolder = (Resolve-Path $scriptDir).Path
}

if ($targetFolder) {
    $normalizedAppData = Join-Path $localAppData "DiamTek"
    if (Test-Path $normalizedAppData) { $normalizedAppData = (Resolve-Path $normalizedAppData).Path }

    # If target is outside AppData and outside Temp, check standalone / test copy
    if (-not $targetFolder.StartsWith($normalizedAppData, [StringComparison]::OrdinalIgnoreCase) -and -not $targetFolder.StartsWith($env:TEMP, [StringComparison]::OrdinalIgnoreCase)) {
        # Protect active development repository from accidental deletion
        $isDevRepo = (Test-Path (Join-Path $targetFolder ".git")) -or (Test-Path (Join-Path $targetFolder "..\.git"))

        if ($isDevRepo) {
            Write-Host "`n[  INFO  ] Active development repository detected at: $targetFolder" -ForegroundColor Yellow
            Write-Host "           Source repository will NOT be deleted." -ForegroundColor Yellow
        } else {
            $deleteTarget = $DeleteTarget -or $false
            if (-not $deleteTarget -and -not $Quiet) {
                $confirmTarget = Read-Host "`nDo you also want to delete this JVM directory and all its files? ($targetFolder) (y/N)"
                if ($confirmTarget -match '^y') {
                    $deleteTarget = $true
                }
            }
            if ($deleteTarget) {
                Write-Host "[ ACTION ] Deleting JVM directory: $targetFolder..." -ForegroundColor Cyan
                Set-Location $env:TEMP
                try {
                    Remove-Item -LiteralPath $targetFolder -Recurse -Force -ErrorAction Stop
                    Write-Host "[   OK   ] Deleted directory: $targetFolder" -ForegroundColor Green
                } catch {
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c cd /d `"$env:TEMP`" & timeout /t 2 >nul & rmdir /s /q `"$targetFolder`"" -WindowStyle Hidden
                    Write-Host "[   OK   ] Directory scheduled for deletion: $targetFolder" -ForegroundColor Green
                }

                # Clean up parent container folder if it is now empty (e.g. jvm-test-copy created for testing)
                $parentDir = Split-Path -Parent $targetFolder
                $systemRoots = @($env:USERPROFILE, [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('MyDocuments'))
                if ($parentDir -and (Test-Path $parentDir) -and ($parentDir -notin $systemRoots)) {
                    $remaining = Get-ChildItem -LiteralPath $parentDir -Force -ErrorAction SilentlyContinue
                    if (-not $remaining) {
                        Remove-Item -LiteralPath $parentDir -Force -Recurse -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host "[   OK   ] Uninstallation Complete." -ForegroundColor Green
Write-Host "           Please close and restart all terminals for environment changes to take effect."
Write-Host ""
if (-not $Quiet) {
    Write-Host "Press any key to exit..."
    try {
        if ([System.Console]::IsInputRedirected) {
            $null = [System.Console]::ReadLine()
        } else {
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
    } catch {
        # Fallback if console is non-interactive
    }
}