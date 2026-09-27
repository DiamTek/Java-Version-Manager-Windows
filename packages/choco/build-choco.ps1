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
$chocoInstall = Join-Path $ScriptDir "tools\chocolateyInstall.ps1"
$chocoUninstall = Join-Path $ScriptDir "tools\chocolateyUninstall.ps1"

$origNuspec = if (Test-Path -LiteralPath $nuspecPath) { [System.IO.File]::ReadAllText($nuspecPath, $utf8NoBom) } else { $null }
$origInstall = if (Test-Path -LiteralPath $chocoInstall) { [System.IO.File]::ReadAllText($chocoInstall, $utf8NoBom) } else { $null }
$origUninstall = if (Test-Path -LiteralPath $chocoUninstall) { [System.IO.File]::ReadAllText($chocoUninstall, $utf8NoBom) } else { $null }

try {
    if (Test-Path -LiteralPath $nuspecPath) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $updatedNuspec = $origNuspec -replace '<version>.*?</version>', "<version>$Version</version>"
        [System.IO.File]::WriteAllText($nuspecPath, $updatedNuspec, $utf8NoBom)
        $sr = $null
        $xr = $null
        try {
            $xmlSettings = New-Object System.Xml.XmlReaderSettings
            $xmlSettings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
            $xmlSettings.XmlResolver = $null
            $sr = New-Object System.IO.StringReader([System.IO.File]::ReadAllText($nuspecPath, $utf8NoBom))
            $xr = [System.Xml.XmlReader]::Create($sr, $xmlSettings)
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.XmlResolver = $null
            $xmlDoc.Load($xr)
        } catch {
            throw "XML validation failed on jvm.nuspec: $($_.Exception.Message)"
        } finally {
            if ($null -ne $xr) { $xr.Close() }
            if ($null -ne $sr) { $sr.Close() }
        }
        $sw.Stop()
        Write-Host "  ${cGreen}[PASS]${cReset} Synchronized and validated jvm.nuspec (v$Version) ${cGray}($($sw.ElapsedMilliseconds) ms)${cReset}"
    }

    if (Test-Path -LiteralPath $chocoInstall) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $updated = [regex]::Replace($origInstall, "(?m)^(\`$packageVersion\s*=\s*')[^']*(')", "`${1}$Version`${2}")
        $msiX64 = Join-Path $RootDir "packages\msi\jvm-windows-$Version-x64.msi"
        if (Test-Path -LiteralPath $msiX64) {
            $msiHash = (Get-FileHash -LiteralPath $msiX64 -Algorithm SHA256).Hash.ToUpperInvariant()
            $updated = [regex]::Replace($updated, "(?m)^(\`$checksum64\s*=\s*')[^']*(')", "`${1}$msiHash`${2}")
            $sw.Stop()
            Write-Host "  ${cGreen}[PASS]${cReset} Synchronized checksum64 in chocolateyInstall.ps1 ($msiHash) ${cGray}($($sw.ElapsedMilliseconds) ms)${cReset}"
        }
        [System.IO.File]::WriteAllText($chocoInstall, $updated, $utf8NoBom)
    }

    if (Test-Path -LiteralPath $chocoUninstall) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $updated = $origUninstall -replace '/v[0-9a-zA-Z.-]+/uninstall\.ps1', "/v$Version/uninstall.ps1"
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
            $expectedNupkg = Join-Path $ScriptDir "jvm-windows.$Version.nupkg"
            & $chocoCmd pack $nuspecPath --outputdirectory $ScriptDir
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $expectedNupkg)) {
                throw "choco pack failed (ExitCode: $LASTEXITCODE) or did not produce expected package '$expectedNupkg'"
            }
            $sw.Stop()
            Write-Host "  ${cGreen}[PASS]${cReset} Compiled Chocolatey package (jvm-windows.$Version.nupkg) ${cGray}($($sw.ElapsedMilliseconds) ms)${cReset}"
        } else {
            throw "Chocolatey CLI ('choco.exe') not found. Install Chocolatey or pass -NoPack to skip packaging."
        }
    }
} catch {
    $expectedNupkg = Join-Path $ScriptDir "jvm-windows.$Version.nupkg"
    if (Test-Path -LiteralPath $expectedNupkg) { Remove-Item -LiteralPath $expectedNupkg -Force -ErrorAction SilentlyContinue }
    Get-ChildItem -LiteralPath $ScriptDir -Filter "*.nupkg.tmp" -File -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    if ($null -ne $origNuspec -and (Test-Path -LiteralPath $nuspecPath))       { [System.IO.File]::WriteAllText($nuspecPath, $origNuspec, $utf8NoBom) }
    if ($null -ne $origInstall -and (Test-Path -LiteralPath $chocoInstall))    { [System.IO.File]::WriteAllText($chocoInstall, $origInstall, $utf8NoBom) }
    if ($null -ne $origUninstall -and (Test-Path -LiteralPath $chocoUninstall)){ [System.IO.File]::WriteAllText($chocoUninstall, $origUninstall, $utf8NoBom) }
    throw "Chocolatey package build failed (manifests restored): $($_.Exception.Message)"
}
Write-Host ""
Write-Host "${cCyan}${cBold}========================================================================${cReset}"
Write-Host "${cCyan}${cBold}                      CHOCOLATEY BUILD SUMMARY                          ${cReset}"
Write-Host "${cCyan}${cBold}========================================================================${cReset}"
Write-Host "  Target Version       : v$Version"
Write-Host "  Status               : ${cGreen}SUCCESS${cReset}"
Write-Host "${cCyan}${cBold}========================================================================${cReset}"
Write-Host ""