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
    [switch]$KeepInstalled,
    [switch]$ShowUI
)

$ErrorActionPreference = 'Continue'

# Ensure process-level execution policy allows running hooks and commands
try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
} catch { }

# Resolve script directory robustly across PowerShell hosts and invocation modes
$ScriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($PSCommandPath) {
    Split-Path -Parent $PSCommandPath
} elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} elseif ($MyInvocation.MyCommand.Definition) {
    Split-Path -Parent $MyInvocation.MyCommand.Definition
} else {
    (Get-Location).Path
}

# Auto-unblock script and companion files if flagged with Zone.Identifier (downloaded from web/untrusted zone)
try {
    if (Get-Command Unblock-File -ErrorAction SilentlyContinue) {
        if ($PSCommandPath) { Unblock-File -Path $PSCommandPath -ErrorAction SilentlyContinue }
        if ($ScriptDir) {
            Get-ChildItem -Path $ScriptDir -Filter "*.ps1" -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
            Get-ChildItem -Path $ScriptDir -Filter "*.msi" -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
        }
    }
} catch { }

# Resolve target MSI package
if (-not $MsiPath) {
    # Check in script directory first
    $candidate = Get-ChildItem -Path $ScriptDir -Filter "jvm-windows-*-x64.msi" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $candidate) {
        # Check current working directory or subdirectories if invoked from repo root
        $candidate = Get-ChildItem -Path (Get-Location).Path -Filter "jvm-windows-*-x64.msi" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if ($candidate) {
        $MsiPath = $candidate.FullName
    } else {
        $MsiPath = Join-Path $ScriptDir "jvm-windows-1.0.0-x64.msi"
    }
} else {
    # If explicitly specified, check if it's relative to current dir, script dir, or pure filename
    if (-not (Test-Path $MsiPath)) {
        $candidateScript = Join-Path $ScriptDir $MsiPath
        if (Test-Path $candidateScript) {
            $MsiPath = $candidateScript
        } else {
            $leafName = Split-Path $MsiPath -Leaf
            $candidateLeaf = Join-Path $ScriptDir $leafName
            if (Test-Path $candidateLeaf) {
                $MsiPath = $candidateLeaf
            }
        }
    }
}

# If MSI is not found, automatically compile it using build-msi.ps1
if (-not (Test-Path $MsiPath)) {
    $buildScript = Join-Path $ScriptDir "build-msi.ps1"
    if (Test-Path $buildScript) {
        Write-Host "[ INFO ] Target MSI not found. Automatically compiling with build-msi.ps1..." -ForegroundColor Yellow
        try {
            & $buildScript -Arch x64
            $candidate = Get-ChildItem -Path $ScriptDir -Filter "jvm-windows-*-x64.msi" -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($candidate) {
                $MsiPath = $candidate.FullName
            }
        } catch { }
    }
}

# If still not found (e.g. standalone test-msi.ps1 without build-msi.ps1 or build tools), download from GitHub Releases
if (-not (Test-Path $MsiPath)) {
    Write-Host "[ INFO ] Target MSI not found locally. Fetching latest release from GitHub..." -ForegroundColor Yellow
    $downloadTarget = Join-Path $ScriptDir "jvm-windows-1.0.0-x64.msi"
    $releaseUrl = "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/latest/download/jvm-windows-1.0.0-x64.msi"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $releaseUrl -OutFile $downloadTarget -UseBasicParsing -ErrorAction Stop
        if (Test-Path $downloadTarget) {
            $fileObj = Get-Item $downloadTarget
            # Verify the downloaded payload is a valid binary package (> 100KB) and not an HTML error document
            if ($fileObj.Length -gt 100KB) {
                $head = Get-Content -Path $downloadTarget -TotalCount 1 -Raw -ErrorAction SilentlyContinue
                if (-not ($head -match "^\s*<!DOCTYPE|^\s*<html")) {
                    $MsiPath = $downloadTarget
                    Write-Host "[ PASS ] Downloaded $(Split-Path $MsiPath -Leaf) from GitHub Releases." -ForegroundColor Green
                } else {
                    Remove-Item $downloadTarget -Force -ErrorAction SilentlyContinue
                    Write-Host "[ INFO ] GitHub returned an HTML page instead of a release binary." -ForegroundColor DarkGray
                }
            } else {
                Remove-Item $downloadTarget -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Remove-Item $downloadTarget -Force -ErrorAction SilentlyContinue
        $shortErr = if ($_.Exception.Response.StatusCode) {
            "HTTP " + [int]$_.Exception.Response.StatusCode + " " + $_.Exception.Response.StatusCode
        } elseif ($_.Exception.Message) {
            ($_.Exception.Message -split "`r?`n")[0]
        } else {
            "Not found or network error"
        }
        Write-Host "[ INFO ] Official release binary not yet published on GitHub ($shortErr)." -ForegroundColor DarkGray
    }
}

# If still not found (e.g. unreleased build or release assets not yet posted), fetch source from GitHub and build from source
if (-not (Test-Path $MsiPath)) {
    Write-Host "[ INFO ] Release binary not found. Fetching source repository from GitHub to build MSI..." -ForegroundColor Yellow
    $zipPath = Join-Path $env:TEMP "jvm-source-temp.zip"
    $extractDir = Join-Path $env:TEMP "jvm-build-$(Get-Random)"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "https://github.com/DiamTek/Java-Version-Manager-Windows/archive/refs/heads/main.zip" -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
        $remoteBuildScript = Get-ChildItem -Path $extractDir -Filter "build-msi.ps1" -Recurse | Select-Object -First 1
        if ($remoteBuildScript) {
            Write-Host "[ INFO ] Compiling MSI from fetched repository source..." -ForegroundColor Yellow
            & $remoteBuildScript.FullName -Arch x64
            $builtCandidate = Get-ChildItem -Path (Split-Path $remoteBuildScript.FullName) -Filter "jvm-windows-*-x64.msi" -File | Select-Object -First 1
            if ($builtCandidate) {
                $MsiPath = $builtCandidate.FullName
                Write-Host "[ PASS ] Successfully built $MsiPath from fetched source!" -ForegroundColor Green
            }
        }
    } catch {
        $shortErr = if ($_.Exception.Message) { ($_.Exception.Message -split "`r?`n")[0] } else { "$_" }
        Write-Host "[ WARN ] Could not bootstrap build from source: $shortErr" -ForegroundColor DarkGray
    } finally {
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path $MsiPath)) {
    Write-Host "`n[ ERROR ] Target MSI file not found: $MsiPath" -ForegroundColor Red
    Write-Host "  To test the MSI on this machine:" -ForegroundColor Yellow
    Write-Host "    1. Download 'jvm-windows-1.0.0-x64.msi' into the same directory as this script, or" -ForegroundColor DarkGray
    Write-Host "    2. Pass the MSI path: .\test-msi.ps1 -MsiPath `"C:\path\to\jvm-windows-1.0.0-x64.msi`"" -ForegroundColor DarkGray
    Write-Host "    3. Or compile it from the repository: .\packages\msi\build-msi.ps1`n" -ForegroundColor DarkGray
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
$uiFlag = if ($ShowUI) { "/qb" } else { "/qn" }
Write-Host "`n[ PHASE 1 ] Testing Installation ($uiFlag)..." -ForegroundColor Cyan
if (-not $ShowUI) {
    Write-Host "  (Running silently in background with no GUI window. Pass -ShowUI to show the Windows Installer dialog)" -ForegroundColor DarkGray
}
$installProc = Start-Process msiexec.exe -ArgumentList "/i `"$MsiPath`" $uiFlag" -Wait -PassThru
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
    Write-Host "`n[ PHASE 2 ] Testing Uninstallation ($uiFlag)..." -ForegroundColor Cyan
    $uninstallProc = Start-Process msiexec.exe -ArgumentList "/x `"$MsiPath`" $uiFlag" -Wait -PassThru
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
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "`n  Tip: The test suite runs in silent mode (/qn) by design for CI automation." -ForegroundColor DarkGray
    Write-Host "       - To see the installer progress window: pass -ShowUI" -ForegroundColor DarkGray
    Write-Host "       - To keep JVM installed on your system:  pass -KeepInstalled" -ForegroundColor DarkGray
    Write-Host "       - To open the full graphical Setup Wizard: double-click the .msi file:" -ForegroundColor DarkGray
    Write-Host "         $MsiPath`n" -ForegroundColor DarkGray
    exit 0
} else {
    Write-Host "  [ TESTS FAILED ] One or more verification checks did not pass." -ForegroundColor Red
    Write-Host "============================================================`n" -ForegroundColor Cyan
    exit 1
}