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

# Enforce UAC / Administrator Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ ACTION ] Requesting Administrator privileges to completely remove JVM globally..." -ForegroundColor Yellow
    try {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File "$PSCommandPath"" -Verb RunAs -Wait
        exit
    } catch {
        Write-Host "[ ERROR  ] Uninstallation requires Administrator privileges to clean the Machine Registry." -ForegroundColor Red
        exit 1
    }
}

Write-Host "
============================================================"
Write-Host "         Java Version Manager - Uninstaller"
Write-Host "============================================================
"

Write-Host "[ ACTION ] Removing JVM from system PATH..." -ForegroundColor Cyan
$jvmBin = "$env:LOCALAPPDATA\DiamTek\JVM\bin"

# Remove from User PATH
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
    $cleanUser = ($userPath -split ';' | Where-Object { $_ -and $_ -ne $jvmBin }) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $cleanUser, 'User')
}

# Remove from Machine PATH
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
if ($machinePath) {
    $cleanMachine = ($machinePath -split ';' | Where-Object { $_ -and $_ -ne $jvmBin }) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $cleanMachine, 'Machine')
}

Write-Host "[ ACTION ] Removing PowerShell Profile Hook..." -ForegroundColor Cyan
# In an elevated context, $PROFILE points to the Admin profile. We need to target the actual user who invoked it if possible, 
# but in PowerShell 5.1 running as admin on a local account, $PROFILE might be the same. 
# To be safe, we also try to clean the standard user's profile path explicitly if different.
$profiles = @($PROFILE)
$userProfileDir = [Environment]::GetFolderPath('UserProfile')
$stdProfile = Join-Path $userProfileDir "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
if ($profiles -notcontains $stdProfile) { $profiles += $stdProfile }

foreach ($p in $profiles) {
    if (Test-Path $p) {
        $profContent = Get-Content $p -ErrorAction SilentlyContinue | Out-String
        $blockPattern = '(?s)# >>> jvm >>>.*?# <<< jvm <<<'
        $m = [Regex]::Match($profContent, $blockPattern)
        if ($m.Success) {
            $profContent = $profContent.Remove($m.Index, $m.Length).Trim()
            if ([string]::IsNullOrWhiteSpace($profContent)) {
                Remove-Item $p -Force
            } else {
                Set-Content -Path $p -Value $profContent
            }
            Write-Host "[   OK   ] Profile hook removed from: $p" -ForegroundColor Green
        }
    }
}

Write-Host "
[ ACTION ] Cleaning up Environment Variables..." -ForegroundColor Cyan
$vars = @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME')
$removedVars = 0
foreach ($v in $vars) {
    foreach ($scope in @('User', 'Machine')) {
        $val = [Environment]::GetEnvironmentVariable($v, $scope)
        if ($val) {
            [Environment]::SetEnvironmentVariable($v, $null, $scope)
            $removedVars++
        }
    }
}
Write-Host "[   OK   ] Removed $removedVars environment variables globally." -ForegroundColor Green

Write-Host "
============================================================"
$confirmAppdata = Read-Host "Do you want to completely delete the JVM AppData folder?
This permanently deletes JVM settings and Ecosystem tools (Maven, Gradle, etc.) (y/N)"
if ($confirmAppdata -match '^y') {
    Write-Host "[ ACTION ] Deleting $env:LOCALAPPDATA\DiamTek\JVM..." -ForegroundColor Cyan
    if (Test-Path "$env:LOCALAPPDATA\DiamTek\JVM") {
        Remove-Item "$env:LOCALAPPDATA\DiamTek\JVM" -Recurse -Force
        Write-Host "[   OK   ] AppData folder deleted." -ForegroundColor Green
    } else {
        Write-Host "[   OK   ] AppData folder already missing." -ForegroundColor Green
    }
}

Write-Host "
============================================================"
Write-Host "[ WARNING] JVM installs JDKs into 'C:\Program Files\Java'." -ForegroundColor Yellow
$confirmJava = Read-Host "Do you want to PERMANENTLY DELETE 'C:\Program Files\Java' and ALL installed JDKs? (y/N)"
if ($confirmJava -match '^y') {
    if (Test-Path "C:\Program Files\Java") {
        Write-Host "[ ACTION ] Deleting C:\Program Files\Java..." -ForegroundColor Cyan
        Remove-Item "C:\Program Files\Java" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[   OK   ] JDK installation directory deleted." -ForegroundColor Green
    } else {
        Write-Host "[  INFO  ] The directory 'C:\Program Files\Java' does not exist." -ForegroundColor Yellow
    }
}

Write-Host "
============================================================"
Write-Host "[   OK   ] Uninstallation Complete." -ForegroundColor Green
Write-Host "           Please close and restart all terminals for environment changes to take effect.
"
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')