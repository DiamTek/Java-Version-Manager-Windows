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

# Dynamically locates MSVC and Windows SDK to build both x64 and ARM64 native Windows executables (jvm.exe)

param(
    [ValidateSet("all", "x64", "arm64")]
    [string]$Arch = "all"
)

$ErrorActionPreference = 'Stop'

$ScriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($PSCommandPath) {
    Split-Path -Parent $PSCommandPath
} else {
    (Get-Location).Path
}

$RootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$LauncherDir = Join-Path $RootDir "launcher"

if (-not (Test-Path -LiteralPath $LauncherDir)) {
    throw "Launcher directory not found at $LauncherDir"
}

function Find-MsvcArm64Environment {
    # 1. Locate Visual Studio installation via vswhere or standard roots
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    $vsRoots = [System.Collections.Generic.List[string]]::new()
    if (Test-Path -LiteralPath $vswhere) {
        try {
            $paths = & $vswhere -latest -prerelease -products * -property installationPath
            if ($paths) {
                foreach ($p in $paths) {
                    if ($p -and (Test-Path -LiteralPath $p)) { $vsRoots.Add($p) }
                }
            }
        } catch { }
    }

    $progFiles = ${env:ProgramFiles}
    $progFilesX86 = ${env:ProgramFiles(x86)}
    $fallbackRoots = @(
        (Join-Path $progFiles "Microsoft Visual Studio\18\Insiders"),
        (Join-Path $progFiles "Microsoft Visual Studio\2022\Enterprise"),
        (Join-Path $progFiles "Microsoft Visual Studio\2022\Professional"),
        (Join-Path $progFiles "Microsoft Visual Studio\2022\Community"),
        (Join-Path $progFilesX86 "Microsoft Visual Studio\2022\BuildTools")
    )
    foreach ($fb in $fallbackRoots) {
        if ((Test-Path -LiteralPath $fb) -and -not $vsRoots.Contains($fb)) {
            $vsRoots.Add($fb)
        }
    }

    $msvcArm64Lib = $null
    $msvcArm64Bin = $null
    foreach ($vs in $vsRoots) {
        $msvcRoot = Join-Path $vs "VC\Tools\MSVC"
        if (Test-Path -LiteralPath $msvcRoot) {
            $versions = Get-ChildItem -LiteralPath $msvcRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
            foreach ($v in $versions) {
                $candidateLib = Join-Path $v.FullName "lib\arm64"
                $candidateBin = Join-Path $v.FullName "bin\Hostx64\arm64"
                if ((Test-Path -LiteralPath $candidateLib) -and (Test-Path -LiteralPath (Join-Path $candidateBin "link.exe"))) {
                    $msvcArm64Lib = $candidateLib
                    $msvcArm64Bin = $candidateBin
                    break
                }
            }
            if ($msvcArm64Lib) { break }
        }
    }

    # Fallback to any MSVC toolchain directory with arm64 libraries if link.exe is elsewhere
    if (-not $msvcArm64Lib) {
        foreach ($vs in $vsRoots) {
            $msvcRoot = Join-Path $vs "VC\Tools\MSVC"
            if (Test-Path -LiteralPath $msvcRoot) {
                $versions = Get-ChildItem -LiteralPath $msvcRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
                foreach ($v in $versions) {
                    $candidateLib = Join-Path $v.FullName "lib\arm64"
                    if (Test-Path -LiteralPath $candidateLib) {
                        $msvcArm64Lib = $candidateLib
                        $candidateBin = Join-Path $v.FullName "bin\Hostx64\x64"
                        if (Test-Path -LiteralPath (Join-Path $candidateBin "link.exe")) {
                            $msvcArm64Bin = $candidateBin
                        }
                        break
                    }
                }
                if ($msvcArm64Lib) { break }
            }
        }
    }

    # 2. Locate Windows 10/11 SDK arm64 libraries
    $sdkRoots = @(
        (Join-Path $progFilesX86 "Windows Kits\10\Lib"),
        (Join-Path $progFiles "Windows Kits\10\Lib")
    )
    $sdkUmArm64 = $null
    $sdkUcrtArm64 = $null
    foreach ($sr in $sdkRoots) {
        if (Test-Path -LiteralPath $sr) {
            $sdkVersions = Get-ChildItem -LiteralPath $sr -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
            foreach ($sv in $sdkVersions) {
                $candidateUm = Join-Path $sv.FullName "um\arm64"
                $candidateUcrt = Join-Path $sv.FullName "ucrt\arm64"
                if ((Test-Path -LiteralPath $candidateUm) -and (Test-Path -LiteralPath $candidateUcrt)) {
                    $sdkUmArm64 = $candidateUm
                    $sdkUcrtArm64 = $candidateUcrt
                    break
                }
            }
            if ($sdkUmArm64) { break }
        }
    }

    if ($msvcArm64Lib -and $sdkUmArm64 -and $sdkUcrtArm64) {
        $extraLib = "$msvcArm64Lib;$sdkUmArm64;$sdkUcrtArm64"
        $currentLib = [Environment]::GetEnvironmentVariable("LIB", "Process")
        $combinedLib = if ([string]::IsNullOrEmpty($currentLib)) { $extraLib } else { "$extraLib;$currentLib" }
        [Environment]::SetEnvironmentVariable("LIB", $combinedLib, "Process")

        if ($msvcArm64Bin) {
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Process")
            $combinedPath = if ([string]::IsNullOrEmpty($currentPath)) { $msvcArm64Bin } else { "$msvcArm64Bin;$currentPath" }
            [Environment]::SetEnvironmentVariable("PATH", $combinedPath, "Process")
        }
        return $true
    }

    return $false
}

Push-Location $LauncherDir
try {
    if ($Arch -eq "all" -or $Arch -eq "x64") {
        Write-Host "[ ACTION ] Building native x64 jvm.exe launcher..." -ForegroundColor Cyan
        & cargo build --release
        if ($LASTEXITCODE -ne 0) { throw "x64 launcher build failed with exit code $LASTEXITCODE" }
        $x64Out = Join-Path $LauncherDir "target\release\jvm.exe"
        Write-Host "[   OK   ] Built x64 launcher: $x64Out" -ForegroundColor Green
    }

    if ($Arch -eq "all" -or $Arch -eq "arm64") {
        Write-Host "[ ACTION ] Building native ARM64 jvm.exe launcher..." -ForegroundColor Cyan
        $hasEnv = Find-MsvcArm64Environment
        if (-not $hasEnv) {
            Write-Warning "Could not automatically resolve MSVC/SDK arm64 library paths. Attempting default toolchain invocation..."
        }
        & cargo build --release --target aarch64-pc-windows-msvc
        if ($LASTEXITCODE -ne 0) { throw "ARM64 launcher build failed with exit code $LASTEXITCODE" }
        $arm64Out = Join-Path $LauncherDir "target\aarch64-pc-windows-msvc\release\jvm.exe"
        Write-Host "[   OK   ] Built ARM64 launcher: $arm64Out" -ForegroundColor Green
    }
} finally {
    Pop-Location
}