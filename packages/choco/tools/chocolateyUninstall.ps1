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

$ErrorActionPreference = 'SilentlyContinue'

$packageName = 'jvm-windows'
Write-Host "Uninstalling JVM via the official uninstall script..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$uninstallScript = "$env:LOCALAPPDATA\DiamTek\JVM\uninstall.ps1"
if (Test-Path $uninstallScript) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $uninstallScript -Quiet
} else {
    $script = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/uninstall.ps1" -UseBasicParsing).Content
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $script -Quiet
}