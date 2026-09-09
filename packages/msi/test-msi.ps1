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

param(
    [string]$MsiPath,
    [switch]$KeepInstalled
)

$ErrorActionPreference = 'Continue'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Resolve target MSI package
if (-not $MsiPath) {
    $candidate = Get-ChildItem -Path $ScriptDir -Filter "jvm-windows-*-x64.msi" -File | Select-Object -First 1
    if ($candidate) {
        $MsiPath = $candidate.FullName
    } else {
        $MsiPath = Join-Path $ScriptDir "jvm-windows-1.0.0-x64.msi"
    }
}

if (-not (Test-Path $MsiPath)) {
    Write-Host "[ ERROR ] Target MSI file not found: $MsiPath" -ForegroundColor Red
    Write-Host "          Run build-msi.ps1 first before running tests." -ForegroundColor Yellow
    exit 1
}

$MsiPath = (Resolve-Path $MsiPath).Path
$allPassed = $true

function Report-Check {
    param(
        [string]$Title,
        [bool]$Passed,
        [string]$Details = ""
    )
    if ($Passed) {
        $extra = if ($Details) { " - $Details" } else { "" }
        Write-Host "  [ PASS ] $Title$extra" -ForegroundColor Green
    } else {
        $script:allPassed = $false
        $extra = if ($Details) { " ($Details)" } else { "" }
        Write-Host "  [ FAIL ] $Title$extra" -ForegroundColor Red
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  MSI END-TO-END TEST SUITE: $(Split-Path $MsiPath -Leaf)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# -------------------------------------------------------------------------
# Phase 1: Installation Verification
# -------------------------------------------------------------------------
Write-Host "`n[ PHASE 1 ] Testing Silent Installation..." -ForegroundColor Cyan
$installProc = Start-Process msiexec.exe -ArgumentList "/i `"$MsiPath`" /qn" -Wait -PassThru
Report-Check -Title "MSI Installation completed with Exit Code 0" -Passed ($installProc.ExitCode -eq 0) -Details "ExitCode: $($installProc.ExitCode)"

$jvmBatPath = "$env:LOCALAPPDATA\DiamTek\JVM\bin\jvm.bat"
Report-Check -Title "jvm.bat deployed to LocalAppData\DiamTek\JVM\bin" -Passed (Test-Path $jvmBatPath)

$iconIcoPath = "$env:LOCALAPPDATA\DiamTek\JVM\assets\icon.ico"
$iconPngPath = "$env:LOCALAPPDATA\DiamTek\JVM\assets\icon.png"
Report-Check -Title "Application assets deployed (icon.ico, icon.png)" -Passed ((Test-Path $iconIcoPath) -and (Test-Path $iconPngPath))

$profContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
$profHooked = [bool]($profContent -and ($profContent -match "# >>> jvm >>>"))
Report-Check -Title "PowerShell profile hook injected into `$PROFILE" -Passed $profHooked

$wtSettingsCandidates = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
$hasWtInstalled = $false
$wtProfileConfigured = $false
foreach ($wtPath in $wtSettingsCandidates) {
    if (Test-Path $wtPath) {
        $hasWtInstalled = $true
        try {
            $wtJson = Get-Content $wtPath -Raw | ConvertFrom-Json
            $jvmProf = $wtJson.profiles.list | Where-Object { $_.name -eq "Java Version Manager" }
            if ($jvmProf -and $jvmProf.closeOnExit -eq "always") {
                $wtProfileConfigured = $true
                break
            }
        } catch { }
    }
}
if ($hasWtInstalled) {
    Report-Check -Title "Windows Terminal profile configured with closeOnExit='always'" -Passed $wtProfileConfigured
} else {
    Report-Check -Title "Windows Terminal profile configured" -Passed $true -Details "Skipped (Windows Terminal not installed on runner)"
}

$startMenuDir = Join-Path ([Environment]::GetFolderPath("Programs")) "DiamTek"
$shortcutPath = Join-Path $startMenuDir "Java Version Manager.lnk"
$ws = New-Object -ComObject WScript.Shell
$shortcutOk = $false
$shortcutTarget = ""
if (Test-Path $shortcutPath) {
    $shortcutObj = $ws.CreateShortcut($shortcutPath)
    $shortcutTarget = $shortcutObj.TargetPath
    $shortcutOk = [bool]($shortcutTarget -and (Test-Path $shortcutTarget))
}
Report-Check -Title "Start Menu shortcut created" -Passed $shortcutOk -Details "$shortcutTarget"

$legacyKeyExists = Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM"
Report-Check -Title "Legacy script uninstaller registry key cleaned" -Passed (-not $legacyKeyExists)

$userPathParts = [Environment]::GetEnvironmentVariable("Path", "User") -split ";"
$pathUpdated = $userPathParts -contains "$env:LOCALAPPDATA\DiamTek\JVM\bin\" -or $userPathParts -contains "$env:LOCALAPPDATA\DiamTek\JVM\bin"
Report-Check -Title "User PATH updated by Windows Installer" -Passed $pathUpdated

$engineOutput = cmd.exe /c "`"$jvmBatPath`" --version" 2>&1 | Out-String
$engineValid = [bool]($engineOutput -match "Version: 1\.0\.0")
Report-Check -Title "JVM engine functional verification (jvm.bat --version)" -Passed $engineValid -Details "Version 1.0.0 confirmed"

# -------------------------------------------------------------------------
# Phase 2: Uninstallation Verification
# -------------------------------------------------------------------------
if (-not $KeepInstalled) {
    Write-Host "`n[ PHASE 2 ] Testing Silent Uninstallation..." -ForegroundColor Cyan
    $uninstallProc = Start-Process msiexec.exe -ArgumentList "/x `"$MsiPath`" /qn" -Wait -PassThru
    Report-Check -Title "MSI Uninstallation completed with Exit Code 0" -Passed ($uninstallProc.ExitCode -eq 0) -Details "ExitCode: $($uninstallProc.ExitCode)"

    Start-Sleep -Seconds 1

    $profContentAfter = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    $profHookCleaned = -not ($profContentAfter -and ($profContentAfter -match "# >>> jvm >>>"))
    Report-Check -Title "PowerShell profile hook completely removed" -Passed $profHookCleaned

    $wtProfileCleaned = $true
    foreach ($wtPath in $wtSettingsCandidates) {
        if (Test-Path $wtPath) {
            try {
                $wtJson = Get-Content $wtPath -Raw | ConvertFrom-Json
                $jvmProf = $wtJson.profiles.list | Where-Object { $_.name -eq "Java Version Manager" }
                if ($jvmProf) { $wtProfileCleaned = $false; break }
            } catch { }
        }
    }
    Report-Check -Title "Windows Terminal profile cleanly removed" -Passed $wtProfileCleaned

    $shortcutCleaned = -not (Test-Path $shortcutPath)
    Report-Check -Title "Start Menu shortcut deleted" -Passed $shortcutCleaned

    $startMenuFolderCleaned = -not (Test-Path $startMenuDir)
    Report-Check -Title "Start Menu DiamTek directory deleted" -Passed $startMenuFolderCleaned

    $userPathAfter = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathCleaned = -not ($userPathAfter -and ($userPathAfter -match "DiamTek|JVM"))
    Report-Check -Title "User PATH completely sanitized of JVM directories" -Passed $pathCleaned
} else {
    Write-Host "`n[ INFO ] Skipping Uninstallation test (-KeepInstalled specified)." -ForegroundColor Yellow
}

Write-Host "`n============================================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "  [ ALL TESTS PASSED ] MSI package is verified & ready for attestation!" -ForegroundColor Green
    Write-Host "============================================================`n" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "  [ TESTS FAILED ] One or more verification checks did not pass." -ForegroundColor Red
    Write-Host "============================================================`n" -ForegroundColor Cyan
    exit 1
}
