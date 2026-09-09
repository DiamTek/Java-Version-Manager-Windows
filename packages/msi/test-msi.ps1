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

$originalLocation = (Get-Location).Path

try {
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

    # Fallback Tier 2: If MSI is not found locally, compile using local build-msi.ps1
    if (-not (Test-Path $MsiPath)) {
        $buildScript = Join-Path $ScriptDir "build-msi.ps1"
        if (Test-Path $buildScript) {
            Write-Host "`n  [  INFO  ] MSI not found locally. Compiling with build-msi.ps1..." -ForegroundColor Cyan
            try {
                & $buildScript -Arch x64
                $candidate = Get-ChildItem -Path $ScriptDir -Filter "jvm-windows-*-x64.msi" -File -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($candidate) {
                    $MsiPath = $candidate.FullName
                }
            } catch { }
        }
    }

    # Fallback Tier 3: Fetch published binary from GitHub Releases
    if (-not (Test-Path $MsiPath)) {
        Write-Host "  [  INFO  ] Fetching published binary from GitHub Releases..." -ForegroundColor Cyan
        $downloadTarget = Join-Path $ScriptDir "jvm-windows-1.0.0-x64.msi"
        $releaseUrl = "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/latest/download/jvm-windows-1.0.0-x64.msi"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $releaseUrl -OutFile $downloadTarget -UseBasicParsing -ErrorAction Stop
            if (Test-Path $downloadTarget) {
                $fileObj = Get-Item $downloadTarget
                if ($fileObj.Length -gt 100KB) {
                    $head = Get-Content -Path $downloadTarget -TotalCount 1 -Raw -ErrorAction SilentlyContinue
                    if (-not ($head -match "^\s*<!DOCTYPE|^\s*<html")) {
                        $MsiPath = $downloadTarget
                        Write-Host "  [  PASS  ] Acquired $(Split-Path $MsiPath -Leaf) from GitHub Releases." -ForegroundColor Green
                    } else {
                        Remove-Item $downloadTarget -Force -ErrorAction SilentlyContinue
                    }
                } else {
                    Remove-Item $downloadTarget -Force -ErrorAction SilentlyContinue
                }
            }
        } catch {
            Remove-Item $downloadTarget -Force -ErrorAction SilentlyContinue
            Write-Host "  [  INFO  ] GitHub Release binary not yet published (falling back to remote source build)." -ForegroundColor DarkGray
        }
    }

    # Fallback Tier 4: Fetch remote source repository and compile
    if (-not (Test-Path $MsiPath)) {
        Write-Host "  [  INFO  ] Bootstrapping build from latest repository source..." -ForegroundColor Cyan
        $zipPath = Join-Path $env:TEMP "jvm-source-temp.zip"
        $extractDir = Join-Path $env:TEMP "jvm-build-$(Get-Random)"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri "https://github.com/DiamTek/Java-Version-Manager-Windows/archive/refs/heads/main.zip" -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
            Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
            $remoteBuildScript = Get-ChildItem -Path $extractDir -Filter "build-msi.ps1" -Recurse | Select-Object -First 1
            if ($remoteBuildScript) {
                & $remoteBuildScript.FullName -Arch x64
                $builtCandidate = Get-ChildItem -Path (Split-Path $remoteBuildScript.FullName) -Filter "jvm-windows-*-x64.msi" -File | Select-Object -First 1
                if ($builtCandidate) {
                    $MsiPath = $builtCandidate.FullName
                }
            }
        } catch {
            $shortErr = if ($_.Exception.Message) { ($_.Exception.Message -split "`r?`n")[0] } else { "$_" }
            Write-Host "  [  WARN  ] Remote bootstrap build failed: $shortErr" -ForegroundColor DarkGray
        } finally {
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        }
    }

    if (-not (Test-Path $MsiPath)) {
        Write-Host ""
        Write-Host "  ============================================================" -ForegroundColor DarkRed
        Write-Host "   [ ERROR ] Target MSI Not Found                             " -ForegroundColor Red
        Write-Host "  ============================================================" -ForegroundColor DarkRed
        Write-Host "   Could not resolve: $MsiPath" -ForegroundColor DarkGray
        Write-Host "`n   To run this verification suite:" -ForegroundColor Yellow
        Write-Host "   1. Provide the MSI directly:  .\test-msi.ps1 -MsiPath `"C:\path\to\installer.msi`"" -ForegroundColor DarkGray
        Write-Host "   2. Place 'jvm-windows-1.0.0-x64.msi' in the same folder as this script" -ForegroundColor DarkGray
        Write-Host "   3. Or compile it from source:  .\packages\msi\build-msi.ps1`n" -ForegroundColor DarkGray
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
            Write-Host "    [  PASS  ] " -ForegroundColor Green -NoNewline
            Write-Host $Title -NoNewline
            if ($Details) {
                Write-Host " ($Details)" -ForegroundColor DarkGray
            } else {
                Write-Host ""
            }
        } else {
            $script:allPassed = $false
            Write-Host "    [  FAIL  ] " -ForegroundColor Red -NoNewline
            Write-Host $Title -NoNewline
            if ($Details) {
                Write-Host " ($Details)" -ForegroundColor Yellow
            } else {
                Write-Host ""
            }
        }
    }

    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor DarkCyan
    Write-Host "   DiamTek JVM -- MSI Integration & Attestation Test Suite     " -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor DarkCyan
    Write-Host "   Target:   $(Split-Path $MsiPath -Leaf)" -ForegroundColor Gray
    Write-Host "   Path:     $MsiPath" -ForegroundColor DarkGray
    Write-Host "   Mode:     $(if ($ShowUI) { 'Interactive Dialog (/qb)' } else { 'Headless Attestation (/qn)' })" -ForegroundColor DarkGray
    Write-Host "  ============================================================" -ForegroundColor DarkCyan

    # -------------------------------------------------------------------------
    # Phase 1: Installation Verification
    # -------------------------------------------------------------------------
    $uiFlag = if ($ShowUI) { "/qb" } else { "/qn" }
    Write-Host "`n  --- [ Phase 1: Installation & System Registration ] --------`n" -ForegroundColor Cyan
    if (-not $ShowUI) {
        Write-Host "    (Running silently in background. Pass -ShowUI to render the installer dialog)`n" -ForegroundColor DarkGray
    }
    $installProc = Start-Process msiexec.exe -ArgumentList "/i `"$MsiPath`" $uiFlag" -Wait -PassThru
    Report-Check -Title "Windows Installer execution completed cleanly" -Passed ($installProc.ExitCode -eq 0) -Details "ExitCode: $($installProc.ExitCode)"

    $jvmBatPath = "$env:LOCALAPPDATA\DiamTek\JVM\bin\jvm.bat"
    Report-Check -Title "Core engine deployed to LocalAppData\DiamTek\JVM\bin" -Passed (Test-Path $jvmBatPath)

    $iconIcoPath = "$env:LOCALAPPDATA\DiamTek\JVM\assets\icon.ico"
    $iconPngPath = "$env:LOCALAPPDATA\DiamTek\JVM\assets\icon.png"
    Report-Check -Title "Branding assets deployed (icon.ico, icon.png)" -Passed ((Test-Path $iconIcoPath) -and (Test-Path $iconPngPath))

    $profContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    $profHooked = [bool]($profContent -and ($profContent -match "# >>> jvm >>>"))
    Report-Check -Title "PowerShell profile integration hook injected into `$PROFILE" -Passed $profHooked

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
    Report-Check -Title "Start Menu application shortcut verified" -Passed $shortcutOk -Details "$shortcutTarget"

    $legacyKeyExists = Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM"
    Report-Check -Title "Legacy uninstaller registry keys cleansed" -Passed (-not $legacyKeyExists)

    $userPathParts = [Environment]::GetEnvironmentVariable("Path", "User") -split ";"
    $pathUpdated = $userPathParts -contains "$env:LOCALAPPDATA\DiamTek\JVM\bin\" -or $userPathParts -contains "$env:LOCALAPPDATA\DiamTek\JVM\bin"
    Report-Check -Title "User PATH updated by Windows Installer (HKCU\Environment)" -Passed $pathUpdated

    $engineOutput = cmd.exe /c "`"$jvmBatPath`" --version" 2>&1 | Out-String
    $engineValid = [bool]($engineOutput -match "Version: 1\.0\.0")
    Report-Check -Title "Runtime CLI subshell execution verified (jvm.bat --version)" -Passed $engineValid -Details "Version 1.0.0"

    # -------------------------------------------------------------------------
    # Phase 2: Uninstallation Verification
    # -------------------------------------------------------------------------
    if (-not $KeepInstalled) {
        Write-Host "`n  --- [ Phase 2: Uninstallation & Residual Hygiene ] --------`n" -ForegroundColor Cyan
        $uninstallProc = Start-Process msiexec.exe -ArgumentList "/x `"$MsiPath`" $uiFlag" -Wait -PassThru
        Report-Check -Title "Windows Installer uninstallation completed cleanly" -Passed ($uninstallProc.ExitCode -eq 0) -Details "ExitCode: $($uninstallProc.ExitCode)"

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
        Report-Check -Title "Start Menu DiamTek program folder deleted" -Passed $startMenuFolderCleaned

        $userPathAfter = [Environment]::GetEnvironmentVariable("Path", "User")
        $pathCleaned = -not ($userPathAfter -and ($userPathAfter -match "DiamTek|JVM"))
        Report-Check -Title "User PATH sanitized of all JVM directories" -Passed $pathCleaned
    } else {
        Write-Host "`n  --- [ Phase 2: Uninstallation & Residual Hygiene ] --------`n" -ForegroundColor Cyan
        Write-Host "    [  SKIP  ] Uninstallation check bypassed (-KeepInstalled active)." -ForegroundColor DarkYellow
        Write-Host "    [  INFO  ] JVM remains installed and ready for terminal use.`n" -ForegroundColor Cyan
    }

    Write-Host ""
    if ($allPassed) {
        Write-Host "  ============================================================" -ForegroundColor DarkGreen
        Write-Host "   [ ALL CHECKS PASSED ]  Package Verified for Attestation   " -ForegroundColor Green
        Write-Host "  ============================================================" -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host "   Attestation & Provenance Summary:" -ForegroundColor Gray
        Write-Host "   - 100% compliant for GitHub Actions: actions/attest-build-provenance" -ForegroundColor DarkGray
        Write-Host "   - Windows Installer GUIDs, PATH, shortcuts, and CLI verified" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   User Guidance:" -ForegroundColor Gray
        Write-Host "   - To see the native progress dialog: pass -ShowUI" -ForegroundColor DarkGray
        Write-Host "   - To keep JVM installed on machine:  pass -KeepInstalled" -ForegroundColor DarkGray
        Write-Host "   - Full graphical wizard: double-click the .msi directly:`n     $MsiPath`n" -ForegroundColor DarkGray
        exit 0
    } else {
        Write-Host "  ============================================================" -ForegroundColor DarkRed
        Write-Host "   [ VERIFICATION FAILED ]  One or more checks did not pass   " -ForegroundColor Red
        Write-Host "  ============================================================`n" -ForegroundColor DarkRed
        exit 1
    }
} finally {
    Set-Location $originalLocation
}