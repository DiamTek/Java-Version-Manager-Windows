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

if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    Write-Host "[ ERROR  ] PowerShell is operating in $($ExecutionContext.SessionState.LanguageMode) mode." -ForegroundColor Red
    Write-Host "           FullLanguage mode is required by DiamTek Java Version Manager uninstaller" -ForegroundColor Yellow
    Write-Host "           to safely clean system environment variables, remove NTFS DACLs, and unbind junctions." -ForegroundColor Yellow
    exit 1
}

Set-Location -LiteralPath $env:TEMP

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

$sys32Dir = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
$systemPowerShell = Join-Path $sys32Dir "WindowsPowerShell\v1.0\powershell.exe"
if (-not (Test-Path -LiteralPath $systemPowerShell)) {
    throw "Fatal Security Error: System PowerShell not found at '$systemPowerShell'."
}
$sysCmd = Join-Path $sys32Dir "cmd.exe"
if (-not (Test-Path -LiteralPath $sysCmd)) {
    $sysCmd = "cmd.exe"
}

function Test-HasReparsePointInLineage([string]$TargetPath) {
    if ([string]::IsNullOrWhiteSpace($TargetPath)) { return $false }
    try {
        $curr = [System.IO.Path]::GetFullPath($TargetPath)
        $root = [System.IO.Path]::GetPathRoot($curr)
        while ($curr -and ($curr.TrimEnd('\') -ne $root.TrimEnd('\'))) {
            if (Test-Path -LiteralPath $curr) {
                $item = Get-Item -LiteralPath $curr -Force -ErrorAction Stop
                if ([bool]($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) { return $true }
            }
            $curr = Split-Path -Path $curr -Parent
        }
    } catch { return $true }
    return $false
}

function Invoke-DeferredDirectoryCleanup([string]$TargetDir) {
    if ([string]::IsNullOrWhiteSpace($TargetDir) -or (Test-HasReparsePointInLineage $TargetDir)) { return }
    $b64Target = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($TargetDir))
    $parentPid = $PID
    $cleanScript = "try { `$p = Get-Process -Id $parentPid -ErrorAction SilentlyContinue; if (`$p) { `$p.WaitForExit(15000) | Out-Null } } catch { Start-Sleep -Seconds 2 }; `$t = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('$b64Target')); if ((Test-Path -LiteralPath `$t) -and (-not [bool]((Get-Item -LiteralPath `$t -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint))) { Remove-Item -LiteralPath `$t -Recurse -Force -ErrorAction SilentlyContinue }"
    $encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cleanScript))
    Start-Process -FilePath $systemPowerShell -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encoded) -WindowStyle Hidden
}

$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$userProfileDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
$winDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
$systemDriveRoot = [System.IO.Path]::GetPathRoot($winDir).TrimEnd('\')
$progFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
$progFilesX86 = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86)
$forbiddenRoots = @(
    $systemDriveRoot, "$systemDriveRoot\",
    $userProfileDir, "$userProfileDir\",
    $winDir, "$winDir\",
    $progFiles, "$progFiles\",
    $progFilesX86, "$progFilesX86\"
)

function Test-TrustedJvmInstallDirectory([string]$CandidateDir) {
    if ([string]::IsNullOrWhiteSpace($CandidateDir)) { return $null }
    if ($CandidateDir -match '\.\.' -or (Test-HasReparsePointInLineage $CandidateDir)) {
        Write-Host "[ ERROR  ] Security violation (CWE-59/CWE-73): Invalid or reparse-point directory rejected: $CandidateDir" -ForegroundColor Red
        return $null
    }
    if (-not (Test-Path -LiteralPath $CandidateDir)) { return $null }
    try {
        $resolvedSrc = (Resolve-Path -LiteralPath $CandidateDir -ErrorAction Stop).Path.TrimEnd('\')
        $normWinDir = $winDir.TrimEnd('\')
        $normProg = $progFiles.TrimEnd('\')
        $normProg86 = $progFilesX86.TrimEnd('\')
        if (($forbiddenRoots -contains $resolvedSrc) -or
            $resolvedSrc.StartsWith("$normWinDir\", [StringComparison]::OrdinalIgnoreCase) -or
            $resolvedSrc.StartsWith("$normProg\", [StringComparison]::OrdinalIgnoreCase) -or
            ($normProg86 -and $resolvedSrc.StartsWith("$normProg86\", [StringComparison]::OrdinalIgnoreCase))) {
            Write-Host "[ ERROR  ] Security violation (CWE-73): Refusing protected system/user root folder: $resolvedSrc" -ForegroundColor Red
            return $null
        }
        $normAppDataRoot = Join-Path $localAppData "DiamTek"
        $isInsideAppData = $resolvedSrc.StartsWith($normAppDataRoot, [StringComparison]::OrdinalIgnoreCase)
        $hasJvmMarker = (Test-Path -LiteralPath (Join-Path $resolvedSrc "jvm.bat")) -or
                        (Test-Path -LiteralPath (Join-Path $resolvedSrc "bin\jvm.bat")) -or
                        (Test-Path -LiteralPath (Join-Path $resolvedSrc "uninstall.ps1"))
        if ($isInsideAppData -or $hasJvmMarker) {
            return $resolvedSrc
        }
        Write-Host "[ ERROR  ] Security violation (CWE-73): Refusing unverified directory without JVM installation markers: $resolvedSrc" -ForegroundColor Red
    } catch {
        Write-Verbose "Directory validation check skipped for '$CandidateDir': $($_.Exception.Message)"
    }
    return $null
}

$validatedSourceDir = if (-not [string]::IsNullOrWhiteSpace($SourceDir)) { Test-TrustedJvmInstallDirectory $SourceDir } else { $null }
if (-not [string]::IsNullOrWhiteSpace($SourceDir) -and -not $validatedSourceDir) {
    Write-Host "[ ERROR  ] Security violation (CWE-73): Specified -SourceDir '$SourceDir' failed security validation. Aborting." -ForegroundColor Red
    exit 1
}

$jvmLocations = @(
    "$localAppData\DiamTek\JVM\bin",
    "$localAppData\DiamTek\JVM\current\bin"
)

# Validate Registry InstallLocation against tampering before adding to $jvmLocations (CWE-73)
try {
    $regInstallLoc = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM" -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation
    $validatedRegLoc = if ($regInstallLoc) { Test-TrustedJvmInstallDirectory $regInstallLoc } else { $null }
    if ($validatedRegLoc) {
        if ($jvmLocations -notcontains $validatedRegLoc) { $jvmLocations += $validatedRegLoc }
        $regBin = Join-Path $validatedRegLoc "bin"
        if ($jvmLocations -notcontains $regBin) { $jvmLocations += $regBin }
    }
} catch {
    Write-Verbose "Registry InstallLocation lookup skipped: $($_.Exception.Message)"
}

# Also remove validated SourceDir and its bin folder if provided
if ($validatedSourceDir) {
    if ($jvmLocations -notcontains $validatedSourceDir) { $jvmLocations += $validatedSourceDir }
    $sourceBin = Join-Path $validatedSourceDir "bin"
    if ($jvmLocations -notcontains $sourceBin) { $jvmLocations += $sourceBin }
}

# Also remove the script's own directory only if it passes Test-TrustedJvmInstallDirectory
$scriptDir = Split-Path -Parent $PSCommandPath
$validatedScriptDir = if ($scriptDir) { Test-TrustedJvmInstallDirectory $scriptDir } else { $null }
if ($validatedScriptDir -and ($jvmLocations -notcontains $validatedScriptDir)) {
    $jvmLocations += $validatedScriptDir
}

$normJvmLocations = @($jvmLocations | ForEach-Object { $_.TrimEnd('\', '/') } | Where-Object { $_ } | Select-Object -Unique)

function Test-IsJvmPath([string]$p) {
    if (-not $p) { return $false }
    $cleanP = $p.Trim().TrimEnd('\', '/')
    foreach ($loc in $normJvmLocations) {
        if ([string]::Equals($cleanP, $loc, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

$userKey = $null
try {
    $userKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    if ($null -ne $userKey) {
        $rawUserPath = $userKey.GetValue('Path', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if ($null -ne $rawUserPath -and $rawUserPath -ne '') {
            $userKind = try { $userKey.GetValueKind('Path') } catch { Write-Verbose "Defaulting User Path kind to ExpandString: $($_.Exception.Message)"; [Microsoft.Win32.RegistryValueKind]::ExpandString }
            $cleanUser = ($rawUserPath -split ';' | Where-Object { $_ -and -not (Test-IsJvmPath $_) }) -join ';'
            $targetKind = if ($userKind -eq [Microsoft.Win32.RegistryValueKind]::String -and $cleanUser -notmatch '%') {
                [Microsoft.Win32.RegistryValueKind]::String
            } else {
                [Microsoft.Win32.RegistryValueKind]::ExpandString
            }
            $userKey.SetValue('Path', $cleanUser, $targetKind)
            Write-Host "[   OK   ] User PATH cleaned." -ForegroundColor Green
        }
    }
} catch {
    Write-Verbose "Primary User PATH registry cleanup failed, attempting fallback: $($_.Exception.Message)"
    try {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($userPath) {
            $cleanUser = ($userPath -split ';' | Where-Object { $_ -and -not (Test-IsJvmPath $_) }) -join ';'
            $targetKind = if ($cleanUser -match '%') { [Microsoft.Win32.RegistryValueKind]::ExpandString } else { [Microsoft.Win32.RegistryValueKind]::ExpandString }
            [Microsoft.Win32.Registry]::SetValue("HKEY_CURRENT_USER\Environment", "Path", $cleanUser, $targetKind)
            Write-Host "[   OK   ] User PATH cleaned." -ForegroundColor Green
        }
    } catch {
        Write-Verbose "Fallback User PATH cleanup failed: $($_.Exception.Message)"
    }
} finally {
    if ($null -ne $userKey) { $userKey.Close() }
}

# Attempt Machine PATH cleanup (skipped with verbose diagnostic if no elevation)
$machineKey = $null
try {
    $machineKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment', $true)
    if ($null -ne $machineKey) {
        $rawMachinePath = $machineKey.GetValue('Path', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if ($null -ne $rawMachinePath -and $rawMachinePath -ne '') {
            # System PATH on Windows NT must always default to ExpandString
            $machineKind = try { $machineKey.GetValueKind('Path') } catch { Write-Verbose "Defaulting Machine Path kind to ExpandString: $($_.Exception.Message)"; [Microsoft.Win32.RegistryValueKind]::ExpandString }
            $cleanMachine = ($rawMachinePath -split ';' | Where-Object { $_ -and -not (Test-IsJvmPath $_) }) -join ';'
            $targetKind = if ($machineKind -eq [Microsoft.Win32.RegistryValueKind]::String -and $cleanMachine -notmatch '%') {
                [Microsoft.Win32.RegistryValueKind]::String
            } else {
                [Microsoft.Win32.RegistryValueKind]::ExpandString
            }
            $machineKey.SetValue('Path', $cleanMachine, $targetKind)
        }
    }
} catch {
    Write-Verbose "Machine PATH cleanup skipped (requires elevation): $($_.Exception.Message)"
} finally {
    if ($null -ne $machineKey) { $machineKey.Close() }
}

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
    [Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, 'Environment', 2, 1000, [ref]$result) | Out-Null
} catch {
    Write-Verbose "WM_SETTINGCHANGE broadcast skipped: $($_.Exception.Message)"
}

# ----------------------------------------------------------------
# PowerShell profile hook removal - all PS versions
# ----------------------------------------------------------------
Write-Host "[ ACTION ] Removing PowerShell Profile Hook..." -ForegroundColor Cyan
$userProfileDir = [Environment]::GetFolderPath('UserProfile')
$myDocs = [Environment]::GetFolderPath('MyDocuments')
$profiles = @(
    (Join-Path $userProfileDir "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path $userProfileDir "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path $myDocs "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path $myDocs "PowerShell\Microsoft.PowerShell_profile.ps1"),
    $PROFILE
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$blockPattern = '(?s)# >>> jvm >>>.*?# <<< jvm <<<'
foreach ($p in $profiles) {
    if (Test-Path -LiteralPath $p) {
        if (Test-HasReparsePointInLineage $p) { continue }
        $stageProf = $null
        try {
            $profContent = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
            $m = [Regex]::Match($profContent, $blockPattern)
            if ($m.Success) {
                $profContent = $profContent.Remove($m.Index, $m.Length).Trim()
                if ([string]::IsNullOrWhiteSpace($profContent)) {
                    Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
                } else {
                    $stageProf = "$p.stage.$([Guid]::NewGuid().ToString('N')).tmp"
                    [System.IO.File]::WriteAllText($stageProf, $profContent, $utf8NoBom)
                    if (-not (Test-HasReparsePointInLineage $p)) {
                        Move-Item -LiteralPath $stageProf -Destination $p -Force
                    }
                }
                Write-Host "[   OK   ] Profile hook removed from: $p" -ForegroundColor Green
            }
        } catch {
            Write-Verbose "Profile hook removal warning for '$p': $($_.Exception.Message)"
        } finally {
            if ($stageProf -and (Test-Path -LiteralPath $stageProf)) {
                Remove-Item -LiteralPath $stageProf -Force -ErrorAction SilentlyContinue
            }
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
        } catch {
            Write-Verbose "Environment variable '$v' ($scope) removal skipped: $($_.Exception.Message)"
        }
    }
}
Write-Host "[   OK   ] Removed $removedVars environment variables." -ForegroundColor Green

# ----------------------------------------------------------------
# Registry uninstall entry + Start Menu shortcuts
# ----------------------------------------------------------------
Write-Host "`n[ ACTION ] Removing Windows Uninstall Registry & Shortcuts..." -ForegroundColor Cyan
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM" -Recurse -Force -ErrorAction SilentlyContinue
try { Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM" -Recurse -Force -ErrorAction SilentlyContinue } catch { Write-Verbose "HKLM Uninstall key removal skipped: $($_.Exception.Message)" }
Remove-Item -Path "HKCU:\Software\DiamTek\JVM" -Recurse -Force -ErrorAction SilentlyContinue
try { Remove-Item -Path "HKLM:\Software\DiamTek\JVM" -Recurse -Force -ErrorAction SilentlyContinue } catch { Write-Verbose "HKLM DiamTek\JVM key removal skipped: $($_.Exception.Message)" }

# Only prune parent DiamTek registry key if it has no remaining subkeys or values
try {
    $cuDiamTek = Get-Item -Path "HKCU:\Software\DiamTek" -ErrorAction SilentlyContinue
    if ($cuDiamTek -and ($cuDiamTek.SubKeyCount -eq 0) -and ($cuDiamTek.ValueCount -eq 0)) {
        Remove-Item -Path "HKCU:\Software\DiamTek" -Force -ErrorAction SilentlyContinue
    }
} catch { Write-Verbose "HKCU DiamTek parent key check skipped: $($_.Exception.Message)" }
try {
    $lmDiamTek = Get-Item -Path "HKLM:\Software\DiamTek" -ErrorAction SilentlyContinue
    if ($lmDiamTek -and ($lmDiamTek.SubKeyCount -eq 0) -and ($lmDiamTek.ValueCount -eq 0)) {
        Remove-Item -Path "HKLM:\Software\DiamTek" -Force -ErrorAction SilentlyContinue
    }
} catch { Write-Verbose "HKLM DiamTek parent key check skipped: $($_.Exception.Message)" }

function Remove-DirectorySafely([string]$Path) {
    if (-not $Path) { return }
    $parentPath = Split-Path -Path $Path -Parent
    if ($parentPath -and (Test-HasReparsePointInLineage $parentPath)) {
        Write-Host "[ ERROR  ] Security violation (CWE-59): Ancestor reparse point detected for '$Path'. Refusing deletion." -ForegroundColor Red
        return
    }
    if (-not (Test-Path -LiteralPath $Path) -and -not (Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue)) {
        return
    }
    $sysCmd = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::System)) "cmd.exe"

    # 1. If root itself is a reparse point, unbind it immediately
    $rootItem = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($rootItem -and ($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        if ($rootItem.PSIsContainer) {
            try { [System.IO.Directory]::Delete($rootItem.FullName, $false) } catch { Write-Verbose "Falling back to cmd rmdir for root junction: $($_.Exception.Message)"; & $sysCmd /c "rmdir /q `"$($rootItem.FullName)`"" 2>$null }
        } else {
            Remove-Item -LiteralPath $rootItem.FullName -Force -ErrorAction SilentlyContinue
        }
        return
    }

    # 2. Unbind all child reparse points (bottom-up) without recursing into reparse points (CWE-674 / CWE-59)
    try {
        $reparseList = New-Object System.Collections.Generic.List[System.IO.FileSystemInfo]
        $queue = New-Object System.Collections.Generic.Queue[string]
        $visited = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
        $normRoot = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        $queue.Enqueue($normRoot)
        $maxDepth = 32
        $depthMap = @{ $normRoot = 0 }

        while ($queue.Count -gt 0) {
            $currDir = $queue.Dequeue()
            $currDepth = $depthMap[$currDir]
            if ($currDepth -ge $maxDepth -or -not $visited.Add($currDir)) { continue }

            $children = Get-ChildItem -LiteralPath $currDir -Force -ErrorAction SilentlyContinue
            foreach ($child in $children) {
                if ($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    $reparseList.Add($child)
                    # Never traverse into child reparse points: prevents cyclic loops & external traversal (CWE-674 / CWE-59)
                } elseif ($child.PSIsContainer) {
                    $depthMap[$child.FullName] = $currDepth + 1
                    $queue.Enqueue($child.FullName)
                }
            }
        }

        $reparseList | Sort-Object -Property { $_.FullName.Length } -Descending | ForEach-Object {
            if ($_.PSIsContainer) {
                try {
                    [System.IO.Directory]::Delete($_.FullName, $false)
                } catch {
                    Write-Verbose "Falling back to cmd rmdir for child junction: $($_.Exception.Message)"
                    & $sysCmd /c "rmdir /q `"$($_.FullName)`"" 2>$null
                }
            } else {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-Verbose "Child reparse point enumeration warning for '$Path': $($_.Exception.Message)"
    }

    # 3. Prefer cmd.exe rmdir /s /q for tree deletion to guarantee junction safety in PS 5.1
    & $sysCmd /c "rmdir /s /q `"$Path`"" 2>$null
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Remove-ShortcutSafely([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return }
    if (Test-HasReparsePointInLineage $Path) {
        Write-Verbose "Skipping shortcut with reparse point in lineage: $Path"
        return
    }
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item -or $item.PSIsContainer) { return }
    $targetOk = $false
    $wshell = $null
    $sc = $null
    try {
        $wshell = New-Object -ComObject WScript.Shell
        $sc = $wshell.CreateShortcut($Path)
        if ($sc -and ($sc.TargetPath -match 'DiamTek[\\/]JVM' -or $sc.TargetPath -match 'jvm\.bat' -or $sc.TargetPath -match 'uninstall\.ps1' -or $sc.Description -match 'DiamTek|Java Version Manager')) {
            $targetOk = $true
        }
    } catch {
        Write-Verbose "Could not inspect shortcut target for '$Path': $($_.Exception.Message)"
        if ($item.Name -match 'Java Version Manager|DiamTek|JVM') { $targetOk = $true }
    } finally {
        if ($sc) { [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($sc) | Out-Null }
        if ($wshell) { [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($wshell) | Out-Null }
        [System.GC]::Collect()
    }
    if ($targetOk) {
        Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        Write-Host "[   OK   ] Removed shortcut: $($item.Name)" -ForegroundColor Green
    }
}

$startMenuDirs = @(
    (Join-Path ([Environment]::GetFolderPath('Programs')) "DiamTek"),
    (Join-Path ([Environment]::GetFolderPath('CommonPrograms')) "DiamTek")
)
foreach ($sm in $startMenuDirs) {
    if ((Test-Path -LiteralPath $sm) -and (-not (Test-HasReparsePointInLineage $sm))) {
        Get-ChildItem -LiteralPath $sm -Filter "*.lnk" -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-ShortcutSafely -Path $_.FullName
        }
        $remaining = Get-ChildItem -LiteralPath $sm -Force -ErrorAction SilentlyContinue
        if (-not $remaining) {
            Remove-DirectorySafely -Path $sm
            Write-Host "[   OK   ] Removed Start Menu folder: $sm" -ForegroundColor Green
        }
    }
}

$desktopLocations = @(
    [Environment]::GetFolderPath('Desktop'),
    [Environment]::GetFolderPath('CommonDesktopDirectory'),
    [Environment]::GetFolderPath('Programs'),
    [Environment]::GetFolderPath('CommonPrograms'),
    (Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar")
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

foreach ($dl in $desktopLocations) {
    Remove-ShortcutSafely -Path (Join-Path $dl "Java Version Manager.lnk")
    Remove-ShortcutSafely -Path (Join-Path $dl "Uninstall Java Version Manager.lnk")
}

# Windows Terminal Profile cleanup
$wtSettingsCandidates = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
foreach ($wtSettings in $wtSettingsCandidates) {
    if ((Test-Path -LiteralPath $wtSettings) -and (-not (Test-HasReparsePointInLineage $wtSettings))) {
        $stageWt = $null
        try {
            $wtContent = [System.IO.File]::ReadAllText($wtSettings, [System.Text.Encoding]::UTF8)
            # Strip JSONC comments (block comments /* ... */ and line comments // ...) while preserving strings, and strip trailing commas
            $jsoncPattern = '(?s)("(?:\\.|[^"\\])*")|/\*.*?\*/|(?m)//.*$'
            $cleanJson = [System.Text.RegularExpressions.Regex]::Replace($wtContent, $jsoncPattern, { param($m) if ($m.Groups[1].Success) { $m.Groups[1].Value } else { '' } }) -replace ',\s*([\}\]])', '$1'
            $wtJson = $cleanJson | ConvertFrom-Json
            if ($wtJson.profiles -and $wtJson.profiles.list) {
                $filtered = @($wtJson.profiles.list | Where-Object {
                    $isJvm = ($_.guid -eq '{b20650a4-4212-4d64-9edf-744e9285e2be}') -or
                             ($_.name -eq 'Java Version Manager' -and $_.commandline -match '(?i)DiamTek.*jvm\.bat')
                    -not $isJvm
                })
                if ($filtered.Count -ne $wtJson.profiles.list.Count) {
                    $wtJson.profiles.list = $filtered
                    if ($wtJson.defaultProfile -eq '{b20650a4-4212-4d64-9edf-744e9285e2be}' -and $filtered.Count -gt 0) {
                        $wtJson.defaultProfile = $filtered[0].guid
                    }
                    $newWtContent = $wtJson | ConvertTo-Json -Depth 32
                    $stageWt = "$wtSettings.stage.$([Guid]::NewGuid().ToString('N')).tmp"
                    [System.IO.File]::WriteAllText($stageWt, $newWtContent, $utf8NoBom)
                    if (-not (Test-HasReparsePointInLineage $wtSettings)) {
                        Move-Item -LiteralPath $stageWt -Destination $wtSettings -Force
                    }
                    Write-Host "[   OK   ] Removed Windows Terminal profile." -ForegroundColor Green
                }
            }
        } catch {
            Write-Verbose "Windows Terminal profile cleanup warning for '$wtSettings': $($_.Exception.Message)"
        } finally {
            if ($stageWt -and (Test-Path -LiteralPath $stageWt)) {
                Remove-Item -LiteralPath $stageWt -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# ----------------------------------------------------------------
# AppData & Ecosystem Candidate folders - always removed on a complete uninstall
# ----------------------------------------------------------------

# Cleanup temporary session & extraction files safely (preventing CWE-59 reparse traversal in shared %TEMP%)
if (Test-Path -LiteralPath "$env:TEMP\.jvm_session_target") {
    $stItem = Get-Item -LiteralPath "$env:TEMP\.jvm_session_target" -Force -ErrorAction SilentlyContinue
    if ($stItem -and -not ($stItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        Remove-Item -LiteralPath "$env:TEMP\.jvm_session_target" -Force -ErrorAction SilentlyContinue
    }
}
Get-ChildItem -LiteralPath $env:TEMP -Filter "jdk_*_extract*" -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-DirectorySafely $_.FullName
}
Get-ChildItem -LiteralPath $env:TEMP -Filter "jvm_*" -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'uninstall' -and -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) } | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
Get-ChildItem -LiteralPath $env:TEMP -Filter "diamtek_uninstall_*" -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne $PSCommandPath -and -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) } | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }

Write-Host "[   OK   ] Windows uninstall registration removed." -ForegroundColor Green

Write-Host "`n[ ACTION ] Deleting JVM AppData and Candidate folders..." -ForegroundColor Cyan
$diamtekAppData = Join-Path $localAppData "DiamTek"
$jvmAppData = Join-Path $diamtekAppData "JVM"
if (Test-Path -LiteralPath $jvmAppData) {
    # Terminate any dangling JVM processes locking files
    try {
        Get-Process | Where-Object {
            try {
                $_.Path -and $_.Path.StartsWith($jvmAppData, [System.StringComparison]::OrdinalIgnoreCase)
            } catch {
                Write-Verbose "Process path inspection skipped: $($_.Exception.Message)"
                $false
            }
        } | Stop-Process -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Verbose "Process termination sweep warning: $($_.Exception.Message)"
    }

    Remove-DirectorySafely $jvmAppData
    if (-not (Test-Path -LiteralPath $jvmAppData)) {
        Write-Host "[   OK   ] Deleted: $jvmAppData" -ForegroundColor Green
    } else {
        Invoke-DeferredDirectoryCleanup $jvmAppData
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

# Legacy and shared state folders (unbind junctions first to protect linked host JDKs)
$legacyJvm = Join-Path $localAppData "JavaVersionManager"
if (Test-Path $legacyJvm) {
    Remove-DirectorySafely $legacyJvm
    Write-Host "[   OK   ] Cleaned up: $legacyJvm" -ForegroundColor Green
}

# Candidate tools and caches (Maven, Gradle, etc. in ~/.jvm)
$userJvmCandidates = Join-Path $userProfileDir ".jvm"
if (Test-Path $userJvmCandidates) {
    Remove-DirectorySafely $userJvmCandidates
    Write-Host "[   OK   ] Cleaned up candidates folder: $userJvmCandidates" -ForegroundColor Green
}

# ----------------------------------------------------------------
# JDK folder - only prompt if C:\Program Files\Java actually exists
# ----------------------------------------------------------------
$javaDir = if (Test-Path "C:\Program Files\Java") { "C:\Program Files\Java" } elseif ($env:ProgramFiles -and (Test-Path (Join-Path $env:ProgramFiles "Java"))) { Join-Path $env:ProgramFiles "Java" } else { $null }
if ($javaDir) {
    $shouldDeleteJava = $DeleteJava -or $false
    if (-not $shouldDeleteJava -and -not $Quiet -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        $confirm = Read-Host "`nDo you also want to delete the Java installations directory? ($javaDir) (y/N)"
        if ($confirm -match '^y') {
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
            $proc = $null
            try {
                $delB64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($javaDir))
                $delScript = @"
`$target = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('$delB64'))
if (Test-Path -LiteralPath `$target) {
    Remove-Item -LiteralPath `$target -Recurse -Force -ErrorAction SilentlyContinue
}
"@
                $encDel = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($delScript))
                $sysDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
                $proc = Start-Process -FilePath $systemPowerShell -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encDel) -Verb RunAs -WorkingDirectory $sysDir -Wait -PassThru
                if ($null -ne $proc -and $proc.ExitCode -ne 0) {
                    Write-Host "[  WARN  ] Elevated deletion process exited with non-zero code $($proc.ExitCode)." -ForegroundColor Yellow
                }
                if (-not (Test-Path $javaDir)) {
                    $deleted = $true
                }
            } catch {
                Write-Verbose "Elevated deletion handoff exception: $($_.Exception.Message)"
                Write-Host "[ ERROR  ] Administrator elevation was declined or failed." -ForegroundColor Red
            } finally {
                if ($null -ne $proc) { $proc.Dispose() }
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
if (-not [string]::IsNullOrWhiteSpace($SourceDir)) {
    $targetFolder = $validatedSourceDir
    if (-not $targetFolder) {
        Write-Host "[ ERROR  ] Security violation (CWE-73): Specified -SourceDir '$SourceDir' failed security validation. Skipping directory cleanup." -ForegroundColor Red
    }
} elseif ($scriptDir -and (Test-Path -LiteralPath $scriptDir)) {
    $targetFolder = Test-TrustedJvmInstallDirectory $scriptDir
}

if ($targetFolder) {
    $normalizedAppData = Join-Path $localAppData "DiamTek"
    if (Test-Path $normalizedAppData) { $normalizedAppData = (Resolve-Path $normalizedAppData).Path }

    # Protect filesystem roots
    $winDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
    $systemDriveRoot = [System.IO.Path]::GetPathRoot($winDir).TrimEnd('\')
    $progFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
    $progFilesX86 = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86)
    $forbiddenRoots = @(
        $systemDriveRoot, "$systemDriveRoot\",
        $userProfileDir, "$userProfileDir\",
        $winDir, "$winDir\",
        $progFiles, "$progFiles\",
        $progFilesX86, "$progFilesX86\"
    )
    if ($forbiddenRoots -contains $targetFolder) {
        Write-Host "[ ERROR  ] Refusing to delete protected system/user root folder: $targetFolder" -ForegroundColor Red
        return
    }

    # If target is outside AppData and outside Temp, check standalone / test copy
    if (-not $targetFolder.StartsWith($normalizedAppData, [StringComparison]::OrdinalIgnoreCase) -and -not $targetFolder.StartsWith($env:TEMP, [StringComparison]::OrdinalIgnoreCase)) {
        # Strict marker verification: target folder MUST contain JVM installation markers
        $hasJvmMarker = (Test-Path -LiteralPath (Join-Path $targetFolder "jvm.bat")) -or
                        (Test-Path -LiteralPath (Join-Path $targetFolder "bin\jvm.bat")) -or
                        (Test-Path -LiteralPath (Join-Path $targetFolder "uninstall.ps1"))
        if (-not $hasJvmMarker) {
            Write-Host "[ ERROR  ] Target directory '$targetFolder' does not contain JVM installation markers. Aborting deletion." -ForegroundColor Red
            return
        }

        # Protect active development repository from accidental deletion
        $isDevRepo = (Test-Path (Join-Path $targetFolder ".git")) -or (Test-Path (Join-Path $targetFolder "..\.git"))

        if ($isDevRepo) {
            Write-Host "`n[  INFO  ] Active development repository detected at: $targetFolder" -ForegroundColor Yellow
            Write-Host "           Source repository will NOT be deleted." -ForegroundColor Yellow
        } else {
            $deleteTarget = $DeleteTarget -or $false
            if (-not $deleteTarget -and -not $Quiet -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
                $confirmTarget = Read-Host "`nDo you also want to delete this JVM directory and all its files? ($targetFolder) (y/N)"
                if ($confirmTarget -match '^y') {
                    $deleteTarget = $true
                }
            }
            if ($deleteTarget) {
                Write-Host "[ ACTION ] Deleting JVM directory: $targetFolder..." -ForegroundColor Cyan
                Set-Location $env:TEMP

                Remove-DirectorySafely $targetFolder
                if (-not (Test-Path -LiteralPath $targetFolder)) {
                    Write-Host "[   OK   ] Deleted directory: $targetFolder" -ForegroundColor Green
                } else {
                    Invoke-DeferredDirectoryCleanup $targetFolder
                    Write-Host "[   OK   ] Directory scheduled for deletion: $targetFolder" -ForegroundColor Green
                }

                # Clean up parent container folder if it is an empty test directory inside TEMP
                $parentDir = Split-Path -Parent $targetFolder
                $tempDir = [System.IO.Path]::GetFullPath($env:TEMP)
                if ($parentDir -and (Test-Path $parentDir)) {
                    $parentFull = [System.IO.Path]::GetFullPath($parentDir)
                    $parentName = Split-Path -Leaf $parentFull
                    if ($parentFull.StartsWith($tempDir, [System.StringComparison]::OrdinalIgnoreCase) -and ($parentName -match '^(jvm-test|diamtek-temp)')) {
                        $remaining = Get-ChildItem -LiteralPath $parentFull -Force -ErrorAction SilentlyContinue
                        if (-not $remaining) {
                            Remove-Item -LiteralPath $parentFull -Force -Recurse -ErrorAction SilentlyContinue
                        }
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
        Write-Verbose "Console ReadKey skipped in non-interactive session: $($_.Exception.Message)"
    }
}