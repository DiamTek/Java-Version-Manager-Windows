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
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$packageName = 'jvm-windows'
$packageVersion = '1.0.1'
$url64 = "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/v$packageVersion/jvm-windows-$packageVersion-x64.msi"
$checksum64 = 'C62A9A6CBB9EBA8A2E8585E83F4B538DAD189FEB38FF54D6A40D7F54C1118DF3'

$packageArgs = @{
    packageName    = $packageName
    fileType       = 'MSI'
    url64bit       = $url64
    silentArgs     = "/qn /norestart"
    validExitCodes = @(0, 3010)
    checksum64     = $checksum64
    checksumType64 = 'sha256'
}

Install-ChocolateyPackage @packageArgs