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
    [string]$Version,
    [switch]$NoPack
)

$ErrorActionPreference = 'Stop'

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
$RootDir = (Resolve-Path "$ScriptDir\..\..").Path

# Auto-detect version from jvm.bat if not passed
if ([string]::IsNullOrWhiteSpace($Version)) {
    $batPath = Join-Path $RootDir "jvm.bat"
    if (Test-Path $batPath) {
        $batRaw = Get-Content $batPath -Raw -ErrorAction SilentlyContinue
        if ($batRaw -match 'set\s+"JVM_VERSION=(.*?)"') {
            $Version = $matches[1].Trim()
        }
    }
    if (-not $Version) { $Version = "1.0.0" }
}

$nuspecPath = Join-Path $ScriptDir "jvm.nuspec"
if (Test-Path $nuspecPath) {
    $nuspecContent = Get-Content $nuspecPath -Raw
    $updatedNuspec = $nuspecContent -replace '<version>.*?</version>', "<version>$Version</version>"
    [System.IO.File]::WriteAllText($nuspecPath, $updatedNuspec, [System.Text.Encoding]::UTF8)
    Write-Host "[ OK ] Synchronized jvm.nuspec version to: $Version" -ForegroundColor Green
}

$chocoInstall = Join-Path $ScriptDir "tools\chocolateyInstall.ps1"
if (Test-Path $chocoInstall) {
    $content = Get-Content $chocoInstall -Raw
    $updated = $content -replace '/v[0-9.]+/install\.ps1', "/v$Version/install.ps1"
    [System.IO.File]::WriteAllText($chocoInstall, $updated, [System.Text.Encoding]::UTF8)
}

$chocoUninstall = Join-Path $ScriptDir "tools\chocolateyUninstall.ps1"
if (Test-Path $chocoUninstall) {
    $content = Get-Content $chocoUninstall -Raw
    $updated = $content -replace '/v[0-9.]+/uninstall\.ps1', "/v$Version/uninstall.ps1"
    [System.IO.File]::WriteAllText($chocoUninstall, $updated, [System.Text.Encoding]::UTF8)
}

if (-not $NoPack) {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Packing Chocolatey package (jvm-windows.$Version.nupkg)..." -ForegroundColor Cyan
        & choco pack $nuspecPath --outputdirectory $ScriptDir
    } else {
        Write-Host "[ INFO ] 'choco' CLI not found on PATH. jvm.nuspec updated to v$Version." -ForegroundColor DarkGray
        Write-Host "         Run 'choco pack packages/choco/jvm.nuspec' to compile the package." -ForegroundColor DarkGray
    }
}