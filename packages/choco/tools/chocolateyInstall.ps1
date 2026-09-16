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

$packageName = 'jvm-windows'
# Always download official Stable release installer, never unreleased main commits
$releaseUrl = "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/latest/download/install.ps1"
$scriptContent = $null
try {
    $scriptContent = (Invoke-WebRequest -Uri $releaseUrl -UseBasicParsing -TimeoutSec 10).Content
} catch {
    try {
        $tagUrl = "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/v1.0.1/install.ps1"
        $scriptContent = (Invoke-WebRequest -Uri $tagUrl -UseBasicParsing -TimeoutSec 10).Content
    } catch { }
}

if (-not $scriptContent) {
    throw "Failed to download official Stable release installer for $packageName from GitHub Releases."
}

& ([scriptblock]::Create($scriptContent)) -Channel "Stable" -Quiet