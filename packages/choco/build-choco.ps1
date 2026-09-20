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

if (-not (Get-Command choco -ErrorAction SilentlyContinue) -and (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe")) {
    $env:PATH = "C:\ProgramData\chocolatey\bin;$env:PATH"
}

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
    if (-not $Version) { $Version = "1.0.1" }
}
$Version = $Version.TrimStart('v')

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$nuspecPath = Join-Path $ScriptDir "jvm.nuspec"
if (Test-Path $nuspecPath) {
    $nuspecContent = [System.IO.File]::ReadAllText($nuspecPath, $utf8NoBom)
    $updatedNuspec = $nuspecContent -replace '<version>.*?</version>', "<version>$Version</version>"
    [System.IO.File]::WriteAllText($nuspecPath, $updatedNuspec, $utf8NoBom)
    try {
        [xml]$null = [System.IO.File]::ReadAllText($nuspecPath, $utf8NoBom)
    } catch {
        throw "XML validation failed on jvm.nuspec: $($_.Exception.Message)"
    }
    Write-Host "[ OK ] Synchronized and validated jvm.nuspec (v$Version)" -ForegroundColor Green
}

$chocoInstall = Join-Path $ScriptDir "tools\chocolateyInstall.ps1"
if (Test-Path $chocoInstall) {
    $content = [System.IO.File]::ReadAllText($chocoInstall, $utf8NoBom)
    $updated = [regex]::Replace($content, "(?m)^(\`$packageVersion\s*=\s*')[^']*(')", "`${1}$Version`${2}")
    [System.IO.File]::WriteAllText($chocoInstall, $updated, $utf8NoBom)
}

$chocoUninstall = Join-Path $ScriptDir "tools\chocolateyUninstall.ps1"
if (Test-Path $chocoUninstall) {
    $content = [System.IO.File]::ReadAllText($chocoUninstall, $utf8NoBom)
    $updated = $content -replace '/v[0-9a-zA-Z.-]+/uninstall\.ps1', "/v$Version/uninstall.ps1"
    [System.IO.File]::WriteAllText($chocoUninstall, $updated, $utf8NoBom)
}

if (-not $NoPack) {
    $chocoCmd = if (Get-Command choco -ErrorAction SilentlyContinue) {
        "choco"
    } elseif (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe") {
        "C:\ProgramData\chocolatey\bin\choco.exe"
    } else {
        $null
    }

    if ($chocoCmd) {
        Write-Host "Packing Chocolatey package (jvm-windows.$Version.nupkg)..." -ForegroundColor Cyan
        & $chocoCmd pack $nuspecPath --outputdirectory $ScriptDir
        if ($LASTEXITCODE -ne 0) { throw "choco pack failed with exit code $LASTEXITCODE" }
    } else {
        Write-Host "[ INFO ] 'choco' CLI not found on PATH. jvm.nuspec updated to v$Version." -ForegroundColor DarkGray
        Write-Host "         Run 'choco pack packages/choco/jvm.nuspec' to compile the package." -ForegroundColor DarkGray
    }
}