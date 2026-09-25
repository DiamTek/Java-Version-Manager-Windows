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

$ErrorActionPreference = 'Stop'

function Test-HasReparsePointInLineage([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $curr = $Path
    while (-not [string]::IsNullOrWhiteSpace($curr)) {
        try {
            if (Test-Path -LiteralPath $curr) {
                $item = Get-Item -LiteralPath $curr -Force -ErrorAction Stop
                if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    return $true
                }
            }
        } catch { }
        $parent = Split-Path -Path $curr -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $curr) { break }
        $curr = $parent
    }
    return $false
}

$sys32 = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
$psExe = Join-Path $sys32 "WindowsPowerShell\v1.0\powershell.exe"
$msiExec = Join-Path $sys32 "msiexec.exe"

$uninstallerPath = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) "DiamTek\JVM\uninstall.ps1"
if (Test-Path -LiteralPath $uninstallerPath) {
    if (Test-HasReparsePointInLineage $uninstallerPath) {
        throw "Security violation (CWE-59): NTFS reparse point or symlink detected on uninstaller lineage '$uninstallerPath'. Aborting."
    }
}

$packageName = 'jvm-windows'
Write-Host "Uninstalling JVM via Chocolatey package manager..."

# Validate registered MSI ProductCode GUIDs if present before invoking Chocolatey MSI uninstall
if (Get-Command Get-AppInstallLocation -ErrorAction SilentlyContinue) {
    try {
        [array]$keys = Get-UninstallRegistryKey -SoftwareName "Java Version Manager*" -ErrorAction SilentlyContinue
        foreach ($key in $keys) {
            if ($key.PSChildName -and $key.PSChildName -match '^\{[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}\}$') {
                $packageArgs = @{
                    packageName    = $packageName
                    fileType       = 'MSI'
                    silentArgs     = "$($key.PSChildName) /qn /norestart"
                    validExitCodes = @(0, 3010)
                }
                Uninstall-ChocolateyPackage @packageArgs
                return
            }
        }
    } catch { }
}

$packageArgs = @{
    packageName    = $packageName
    fileType       = 'MSI'
    silentArgs     = "/qn /norestart"
    validExitCodes = @(0, 3010)
}

Uninstall-ChocolateyPackage @packageArgs