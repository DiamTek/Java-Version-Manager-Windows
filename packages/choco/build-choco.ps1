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
if ($Version -notmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$' -or $Version -match '\.\.') {
    throw "Security validation failed (CWE-20): Invalid semantic version '$Version'."
}

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$ESC = [char]27
$cReset  = "$ESC[0m"
$cBold   = "$ESC[1m"
$cCyan   = "$ESC[36m"
$cGreen  = "$ESC[32m"
$cYellow = "$ESC[33m"
$cRed    = "$ESC[31m"
$cGray   = "$ESC[90m"

Write-Host ""
Write-Host "${cCyan}${cBold}========================================================================${cReset}"
Write-Host "${cCyan}${cBold}        DiamTek JVM Chocolatey Package Builder & Validator              ${cReset}"
Write-Host "${cCyan}${cBold}========================================================================${cReset}"
Write-Host "  Repository: $RootDir"
Write-Host "  Version   : v$Version"
Write-Host ""
Write-Host "${cBold}[STAGE 1] Manifest Synchronization & Checksum Binding${cReset}"

$nuspecPath = Join-Path $ScriptDir "jvm.nuspec"
if (Test-Path -LiteralPath $nuspecPath) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $nuspecContent = [System.IO.File]::ReadAllText($nuspecPath, $utf8NoBom)
    $updatedNuspec = $nuspecContent -replace '<version>.*?</version>', "<version>$Version</version>"
    [System.IO.File]::WriteAllText($nuspecPath, $updatedNuspec, $utf8NoBom)
    try {
        $xmlSettings = New-Object System.Xml.XmlReaderSettings
        $xmlSettings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
        $xmlSettings.XmlResolver = $null
        $sr = New-Object System.IO.StringReader([System.IO.File]::ReadAllText($nuspecPath, $utf8NoBom))
        $xr = [System.Xml.XmlReader]::Create($sr, $xmlSettings)
        try {
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.XmlResolver = $null
            $xmlDoc.Load($xr)
        } finally {
            $xr.Close()
            $sr.Close()
        }
    } catch {
        throw "XML validation failed on jvm.nuspec: $($_.Exception.Message)"
    }
    $sw.Stop()
    Write-Host "  ${cGreen}[PASS]${cReset} Synchronized and validated jvm.nuspec (v$Version) ${cGray}($($sw.ElapsedMilliseconds) ms)${cReset}"
}

$chocoInstall = Join-Path $ScriptDir "tools\chocolateyInstall.ps1"
if (Test-Path $chocoInstall) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $content = [System.IO.File]::ReadAllText($chocoInstall, $utf8NoBom)
    $updated = [regex]::Replace($content, "(?m)^(\`$packageVersion\s*=\s*')[^']*(')", "`${1}$Version`${2}")
    $msiX64 = Join-Path $RootDir "packages\msi\jvm-windows-$Version-x64.msi"
    if (Test-Path $msiX64) {
        $msiHash = (Get-FileHash -LiteralPath $msiX64 -Algorithm SHA256).Hash.ToUpperInvariant()
        $updated = [regex]::Replace($updated, "(?m)^(\`$checksum64\s*=\s*')[^']*(')", "`${1}$msiHash`${2}")
        $sw.Stop()
        Write-Host "  ${cGreen}[PASS]${cReset} Synchronized checksum64 in chocolateyInstall.ps1 ($msiHash) ${cGray}($($sw.ElapsedMilliseconds) ms)${cReset}"
    }
    [System.IO.File]::WriteAllText($chocoInstall, $updated, $utf8NoBom)
}

$chocoUninstall = Join-Path $ScriptDir "tools\chocolateyUninstall.ps1"
if (Test-Path $chocoUninstall) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $content = [System.IO.File]::ReadAllText($chocoUninstall, $utf8NoBom)
    $updated = $content -replace '/v[0-9a-zA-Z.-]+/uninstall\.ps1', "/v$Version/uninstall.ps1"
    [System.IO.File]::WriteAllText($chocoUninstall, $updated, $utf8NoBom)
    $sw.Stop()
    Write-Host "  ${cGreen}[PASS]${cReset} Synchronized chocolateyUninstall.ps1 (v$Version) ${cGray}($($sw.ElapsedMilliseconds) ms)${cReset}"
}

if (-not $NoPack) {
    Write-Host ""
    Write-Host "${cBold}[STAGE 2] Chocolatey NuGet Packaging (.nupkg)${cReset}"
    $chocoCmd = if (Get-Command choco -ErrorAction SilentlyContinue) {
        "choco"
    } elseif (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe") {
        "C:\ProgramData\chocolatey\bin\choco.exe"
    } else {
        $null
    }

    if ($chocoCmd) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & $chocoCmd pack $nuspecPath --outputdirectory $ScriptDir
        if ($LASTEXITCODE -ne 0) { throw "choco pack failed with exit code $LASTEXITCODE" }
        $sw.Stop()
        Write-Host "  ${cGreen}[PASS]${cReset} Compiled Chocolatey package (jvm-windows.$Version.nupkg) ${cGray}($($sw.ElapsedMilliseconds) ms)${cReset}"
    } else {
        Write-Host "  ${cYellow}[INFO]${cReset} 'choco' CLI not found on PATH. jvm.nuspec updated to v$Version."
    }
}
Write-Host ""
Write-Host "${cCyan}${cBold}========================================================================${cReset}"
Write-Host "${cCyan}${cBold}                      CHOCOLATEY BUILD SUMMARY                          ${cReset}"
Write-Host "${cCyan}${cBold}========================================================================${cReset}"
Write-Host "  Target Version       : v$Version"
Write-Host "  Status               : ${cGreen}SUCCESS${cReset}"
Write-Host "${cCyan}${cBold}========================================================================${cReset}"
Write-Host ""