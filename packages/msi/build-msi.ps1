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
    [string]$Version = "1.0.0",
    [ValidateSet("all", "x64", "arm64")]
    [string]$Arch = "all",
    [switch]$All
)

$ErrorActionPreference = 'Stop'

# Ensure process-level execution policy allows running build commands
try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
} catch { }

# Resolve script directory robustly across PowerShell hosts and invocation modes
$ScriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($PSCommandPath) {
    Split-Path -Parent $PSCommandPath
} elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} elseif ($MyInvocation.MyCommand.Definition) {
    Split-Path -Parent $MyInvocation.MyCommand.Definition
} else {
    (Get-Location).Path
}

# Auto-unblock script and companion files if flagged with Zone.Identifier (downloaded from web/untrusted zone)
try {
    if (Get-Command Unblock-File -ErrorAction SilentlyContinue) {
        if ($PSCommandPath) { Unblock-File -Path $PSCommandPath -ErrorAction SilentlyContinue }
        if ($ScriptDir) {
            Get-ChildItem -Path $ScriptDir -Filter "*.ps1" -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
        }
    }
} catch { }

$RootDir = (Resolve-Path "$ScriptDir\..\..").Path
Push-Location $ScriptDir

# 1. Ensure .NET SDK is accessible
Write-Host "Checking for .NET SDK (Required for WiX v4)..." -ForegroundColor Cyan
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    $dotnetCandidates = @(
        "$env:ProgramFiles\dotnet\dotnet.exe",
        "${env:ProgramFiles(x86)}\dotnet\dotnet.exe",
        "$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe"
    )
    foreach ($dc in $dotnetCandidates) {
        if (Test-Path $dc) {
            $env:PATH = "$(Split-Path $dc);$env:PATH"
            break
        }
    }
}
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host ".NET SDK not found. Automatically bootstrapping user-space .NET SDK..." -ForegroundColor Yellow
    $dotnetInstall = Join-Path $env:TEMP "dotnet-install.ps1"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile $dotnetInstall -UseBasicParsing -ErrorAction Stop
        & $dotnetInstall -Channel LTS -InstallDir "$env:LOCALAPPDATA\Microsoft\dotnet" -Quality GA
        $env:PATH = "$env:LOCALAPPDATA\Microsoft\dotnet;$env:PATH"
    } catch {
        Write-Host "WARNING: Could not automatically bootstrap .NET SDK: $_" -ForegroundColor DarkGray
    }
}
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: .NET SDK is required to build MSIs. Please install it from https://dotnet.microsoft.com/download" -ForegroundColor Red
    exit 1
}

# 2. Ensure WiX Toolset v4 CLI and Util extension are available
Write-Host "Checking for WiX Toolset CLI..." -ForegroundColor Cyan
$dotnetTools = Join-Path $env:USERPROFILE ".dotnet\tools"
if ($env:PATH -split ';' -notcontains $dotnetTools) {
    $env:PATH = "$dotnetTools;$env:PATH"
}
$wixCandidate = Join-Path $dotnetTools "wix.exe"
if (Test-Path $wixCandidate) {
    Unblock-File -Path $wixCandidate -ErrorAction SilentlyContinue
}

function Find-WixDll {
    $store = Join-Path $env:USERPROFILE ".dotnet\tools\.store"
    if (Test-Path $store) {
        $candidate = Get-ChildItem -Path $store -Filter "wix.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($candidate) { return $candidate.FullName }
    }
    return $null
}

$script:wixDll = Find-WixDll
if ((-not (Get-Command wix -ErrorAction SilentlyContinue)) -and (-not $script:wixDll)) {
    Write-Host "Installing WiX v4 globally..." -ForegroundColor Yellow
    dotnet tool install --global wix --version "4.0.6"
    $script:wixDll = Find-WixDll
}

function Invoke-Wix {
    $WixArgs = @($args)
    $escapedArgs = $WixArgs | ForEach-Object {
        if ($_ -match '\s' -and -not ($_ -match '^".*"$')) {
            "`"$_`""
        } else {
            $_
        }
    }

    # Strategy 1: Try native wix.exe
    try {
        if (Get-Command wix -ErrorAction SilentlyContinue) {
            $wixExe = (Get-Command wix).Source
            if ($wixExe) { Unblock-File -Path $wixExe -ErrorAction SilentlyContinue }
            $proc = Start-Process -FilePath "wix" -ArgumentList $escapedArgs -NoNewWindow -Wait -PassThru -ErrorAction Stop
            if ($proc.ExitCode -eq 0) { return 0 }
        }
    } catch { }

    # Strategy 2: Fallback to dotnet exec wix.dll (bypasses Windows Defender Application Control & Smart App Control)
    $resolvedDll = if ($script:wixDll) { $script:wixDll } else { Find-WixDll }
    if ($resolvedDll -and (Test-Path $resolvedDll)) {
        try {
            $dotnetCmd = if (Get-Command dotnet -ErrorAction SilentlyContinue) { (Get-Command dotnet).Source } else { "dotnet" }
            $execArgs = @("exec", "`"$resolvedDll`"") + $escapedArgs
            $proc = Start-Process -FilePath $dotnetCmd -ArgumentList $execArgs -NoNewWindow -Wait -PassThru -ErrorAction Stop
            return $proc.ExitCode
        } catch { }
    }

    # Strategy 3: Try dotnet tool run wix
    try {
        $proc = Start-Process -FilePath "dotnet" -ArgumentList (@("tool", "run", "wix") + $escapedArgs) -NoNewWindow -Wait -PassThru -ErrorAction Stop
        return $proc.ExitCode
    } catch { }

    return 1
}

try {
    Invoke-Wix extension add -g WixToolset.Util.wixext/4.0.6 2>$null | Out-Null
} catch { }

# 3. Extract Profile Code from install.ps1 to bundle with MSI
Write-Host "Extracting PowerShell profile hook from install.ps1..." -ForegroundColor Cyan
$installPs1Content = Get-Content "$RootDir\install.ps1" -Raw
$profileMatch = [regex]::Match($installPs1Content, '(?s)\$profileCode = @''(.*?)''@')
if (-not $profileMatch.Success) {
    Write-Host "Failed to extract profile code from install.ps1" -ForegroundColor Red
    exit 1
}
$profileCode = $profileMatch.Groups[1].Value

# 4. Function to build an MSI for a specific architecture
function Build-MsiPackage {
    param(
        [string]$TargetArch
    )

    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "Building Java Version Manager MSI: v$Version ($TargetArch)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan

    # Generate msi-install-hook.ps1 (injects PowerShell profile hook, Windows Terminal profile & Start Menu shortcut polish)
    $msiInstallHook = @"
`$ErrorActionPreference = 'SilentlyContinue'
`$binDir = `$PSScriptRoot
if (-not `$binDir) { `$binDir = "`$env:LOCALAPPDATA\DiamTek\JVM\bin" }
`$jvmRoot = Split-Path `$binDir -Parent
`$batPath = Join-Path `$binDir 'jvm.bat'
`$iconIco = Join-Path `$jvmRoot 'assets\icon.ico'
`$iconPng = Join-Path `$jvmRoot 'assets\icon.png'

`$profileCode = @'
$profileCode
'@
`$profileCode = `$profileCode.Replace('__FALLBACK_BAT__', `$batPath)

`$userProfile = [Environment]::GetFolderPath('UserProfile')
`$profiles = @(
    `$PROFILE,
    (Join-Path `$userProfile 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path `$userProfile 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1')
) | Select-Object -Unique

`$utf8 = New-Object System.Text.UTF8Encoding(`$true)
foreach (`$p in `$profiles) {
    if ([string]::IsNullOrWhiteSpace(`$p)) { continue }
    `$profileDir = Split-Path `$p
    if (-not (Test-Path `$profileDir)) { New-Item -ItemType Directory -Path `$profileDir -Force | Out-Null }
    `$profContent = ''
    if (Test-Path `$p) { `$profContent = [System.IO.File]::ReadAllText(`$p, [System.Text.Encoding]::UTF8) }

    `$blockPattern = '(?s)# >>> jvm >>>.*?# <<< jvm <<<'
    `$m = [Regex]::Match(`$profContent, `$blockPattern)
    if (`$m.Success) {
        `$profContent = `$profContent.Substring(0, `$m.Index) + `$profileCode + `$profContent.Substring(`$m.Index + `$m.Length)
    } else {
        `$profContent = if ([string]::IsNullOrWhiteSpace(`$profContent)) { `$profileCode } else { "`$profContent`r`n`r`n`$profileCode" }
    }
    [System.IO.File]::WriteAllText(`$p, `$profContent, `$utf8)
}

# Windows Terminal Profile Registration
`$wtProfileAdded = `$false
`$wtSettingsCandidates = @(
    "`$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "`$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "`$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
foreach (`$wtSettings in `$wtSettingsCandidates) {
    if (Test-Path `$wtSettings) {
        try {
            `$wtContent = Get-Content `$wtSettings -Raw -ErrorAction Stop
            `$wtJson = `$wtContent | ConvertFrom-Json
            if (`$wtJson.profiles -and `$wtJson.profiles.list) {
                `$existing = `$wtJson.profiles.list | Where-Object { `$_.guid -eq '{b20650a4-4212-4d64-9edf-744e9285e2be}' -or `$_.name -eq 'Java Version Manager' }
                if (-not `$existing) {
                    `$newProfile = [PSCustomObject]@{
                        commandline       = 'cmd.exe /c "%LOCALAPPDATA%\DiamTek\JVM\bin\jvm.bat"'
                        guid              = '{b20650a4-4212-4d64-9edf-744e9285e2be}'
                        hidden            = `$false
                        icon              = '%LOCALAPPDATA%\DiamTek\JVM\assets\icon.png'
                        name              = 'Java Version Manager'
                        startingDirectory = '%USERPROFILE%'
                        closeOnExit       = 'always'
                    }
                    `$profileList = [System.Collections.Generic.List[object]]@(`$wtJson.profiles.list)
                    `$profileList.Add(`$newProfile)
                    `$wtJson.profiles.list = `$profileList
                    `$newWtContent = `$wtJson | ConvertTo-Json -Depth 32
                    Set-Content `$wtSettings `$newWtContent -Encoding utf8
                } else {
                    `$existing.commandline = 'cmd.exe /c "%LOCALAPPDATA%\DiamTek\JVM\bin\jvm.bat"'
                    `$existing.icon = '%LOCALAPPDATA%\DiamTek\JVM\assets\icon.png'
                    `$existing | Add-Member -NotePropertyName 'closeOnExit' -NotePropertyValue 'always' -Force
                    `$newWtContent = `$wtJson | ConvertTo-Json -Depth 32
                    Set-Content `$wtSettings `$newWtContent -Encoding utf8
                }
                `$wtProfileAdded = `$true
            }
        } catch { }
    }
}

# Polish Start Menu shortcut to launch via Windows Terminal if available
`$wtExe = if (Test-Path "`$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") { "`$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe" } elseif (Get-Command wt.exe -ErrorAction SilentlyContinue) { 'wt.exe' } else { `$null }
`$hasWt = `$wtProfileAdded -and [bool]`$wtExe
if (`$hasWt) {
    `$startMenuPrograms = [Environment]::GetFolderPath('Programs')
    `$lnkPath = Join-Path `$startMenuPrograms 'DiamTek\Java Version Manager.lnk'
    if (Test-Path `$lnkPath) {
        try {
            `$wshell = New-Object -ComObject WScript.Shell
            `$shortcut = `$wshell.CreateShortcut(`$lnkPath)
            `$shortcut.TargetPath = `$wtExe
            `$shortcut.Arguments = '-p "Java Version Manager"'
            if (Test-Path `$iconIco) { `$shortcut.IconLocation = `$iconIco }
            `$shortcut.WorkingDirectory = `$jvmRoot
            `$shortcut.Save()
        } catch { }
    }
}

# Remove any legacy manual uninstall shortcut from Programs\DiamTek
`$legacyUninstallLnk = Join-Path ([Environment]::GetFolderPath('Programs')) 'DiamTek\Uninstall Java Version Manager.lnk'
if (Test-Path `$legacyUninstallLnk) { Remove-Item -Path `$legacyUninstallLnk -Force -ErrorAction SilentlyContinue }

# Clean legacy manual install registry entry to prevent duplicate entries in Settings
Remove-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM' -Recurse -Force -ErrorAction SilentlyContinue
exit 0
"@
    [System.IO.File]::WriteAllText("$ScriptDir\msi-install-hook.ps1", $msiInstallHook, [System.Text.Encoding]::UTF8)

    # Generate msi-uninstall-hook.ps1 (cleans PowerShell hook, Windows Terminal, shortcuts, environment vars & session files)
    $msiUninstallHook = @'
$ErrorActionPreference = 'SilentlyContinue'
Set-Location $env:TEMP

$userProfile = [Environment]::GetFolderPath('UserProfile')
$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$profiles = @(
    $PROFILE,
    (Join-Path $userProfile 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $userProfile 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1')
) | Select-Object -Unique

# 1. PowerShell Profile Hook Removal
$blockPattern = '(?s)# >>> jvm >>>.*?# <<< jvm <<<'
foreach ($p in $profiles) {
    if (Test-Path $p) {
        $profContent = Get-Content $p -Raw -ErrorAction SilentlyContinue
        if ($profContent) {
            $m = [Regex]::Match($profContent, $blockPattern)
            if ($m.Success) {
                $profContent = $profContent.Remove($m.Index, $m.Length).Trim()
                if ([string]::IsNullOrWhiteSpace($profContent)) {
                    Remove-Item $p -Force -ErrorAction SilentlyContinue
                } else {
                    [System.IO.File]::WriteAllText($p, $profContent, [System.Text.Encoding]::UTF8)
                }
            }
        }
    }
}

# 2. Windows Terminal Profile cleanup
$wtSettingsCandidates = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
foreach ($wtSettings in $wtSettingsCandidates) {
    if (Test-Path $wtSettings) {
        try {
            $wtContent = Get-Content $wtSettings -Raw -ErrorAction Stop
            $wtJson = $wtContent | ConvertFrom-Json
            if ($wtJson.profiles -and $wtJson.profiles.list) {
                $filtered = @($wtJson.profiles.list | Where-Object { $_.guid -ne '{b20650a4-4212-4d64-9edf-744e9285e2be}' -and $_.name -ne 'Java Version Manager' })
                if ($filtered.Count -ne $wtJson.profiles.list.Count) {
                    $wtJson.profiles.list = $filtered
                    if ($wtJson.defaultProfile -eq '{b20650a4-4212-4d64-9edf-744e9285e2be}' -and $filtered.Count -gt 0) {
                        $wtJson.defaultProfile = $filtered[0].guid
                    }
                    $newWtContent = $wtJson | ConvertTo-Json -Depth 32
                    Set-Content $wtSettings $newWtContent -Encoding utf8
                }
            }
        } catch { }
    }
}

# 3. Taskbar shortcut cleanup
$taskbarLnk = Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Java Version Manager.lnk"
if (Test-Path $taskbarLnk) {
    Remove-Item -Path $taskbarLnk -Force -ErrorAction SilentlyContinue
}

# 4. Clean up all JVM directories from User PATH
$jvmBin = "$localAppData\DiamTek\JVM\bin"
$currentBin = "$localAppData\DiamTek\JVM\current\bin"
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
    $cleanPath = ($userPath -split ';' | Where-Object {
        $trimmed = $_.Trim().TrimEnd('\')
        $_ -and ($trimmed -ne $jvmBin) -and ($trimmed -ne $currentBin)
    }) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $cleanPath, 'User')
}

# 5. Clean up Environment Variables set by JVM
$vars = @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME')
foreach ($v in $vars) {
    foreach ($scope in @('User', 'Machine')) {
        try {
            if ([Environment]::GetEnvironmentVariable($v, $scope)) {
                [Environment]::SetEnvironmentVariable($v, $null, $scope)
            }
        } catch { }
    }
}

# 6. Broadcast WM_SETTINGCHANGE for environment updates
try {
    if (-not ('Win32.NativeMethods' -as [type])) {
        $sig = '[DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);'
        Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition $sig
    }
    $HWND_BROADCAST = [IntPtr]0xFFFF
    $WM_SETTINGCHANGE = 0x001A
    $result = [UIntPtr]::Zero
    [Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result) | Out-Null
} catch { }

# 7. Temporary session cleanup
Remove-Item -Path "$env:TEMP\.jvm_session_target" -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "jvm_*" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# 8. Candidate tools and caches cleanup (~/.jvm)
$userJvmCandidates = Join-Path $userProfile ".jvm"
if (Test-Path $userJvmCandidates) {
    Remove-Item -LiteralPath $userJvmCandidates -Recurse -Force -ErrorAction SilentlyContinue
}

# 9. Legacy and runtime-generated file cleanup
$jvmDir = "$localAppData\DiamTek\JVM"
$current = Join-Path $jvmDir "current"
if (Test-Path $current) { cmd.exe /c rmdir "$current" 2>$null }
$modeFile = Join-Path $jvmDir "mode.txt"
if (Test-Path $modeFile) { Remove-Item $modeFile -Force -ErrorAction SilentlyContinue }
$legacyJvm = Join-Path $localAppData "JavaVersionManager"
if (Test-Path $legacyJvm) { Remove-Item -LiteralPath $legacyJvm -Recurse -Force -ErrorAction SilentlyContinue }

# 10. Start Menu folder cleanup (removes empty folder or any legacy shortcuts)
$startMenuPrograms = [Environment]::GetFolderPath('Programs')
$diamtekStartMenu = Join-Path $startMenuPrograms 'DiamTek'
if (Test-Path $diamtekStartMenu) {
    Remove-Item -LiteralPath $diamtekStartMenu -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
'@
    [System.IO.File]::WriteAllText("$ScriptDir\msi-uninstall-hook.ps1", $msiUninstallHook, [System.Text.Encoding]::UTF8)

    # Generate WiX v4 XML manifest
    Write-Host "Generating jvm.wxs manifest..." -ForegroundColor Cyan
    $wxsContent = @"
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
  <Package Name="Java Version Manager" Manufacturer="DiamTek" Version="$Version" UpgradeCode="db30058e-1738-46cb-84ec-8c652dc99a22" Scope="perUser">
    <SummaryInformation Description="Java Version Manager (JVM) for Windows" />
    <MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed." AllowSameVersionUpgrades="yes" />
    <MediaTemplate EmbedCab="yes" />
    <Icon Id="AppIcon" SourceFile="..\..\assets\icon.ico" />
    <Property Id="ARPPRODUCTICON" Value="AppIcon" />
    <Property Id="ARPHELPLINK" Value="https://github.com/DiamTek/Java-Version-Manager-Windows/issues" />
    <Property Id="ARPURLINFOABOUT" Value="https://diamtek.github.io/Java-Version-Manager-Windows" />
    <Property Id="ARPNOMODIFY" Value="1" />
    <Property Id="ARPNOREPAIR" Value="1" />

    <StandardDirectory Id="LocalAppDataFolder">
      <Directory Id="DIAMTEK_DIR" Name="DiamTek">
        <Directory Id="JVM_DIR" Name="JVM">
          <Component Id="DocumentationComponent" Guid="e2d271f8-b3ac-4b10-85f0-b98a3e8cc16f">
            <File Id="LicenseFile" Source="..\..\LICENSE" KeyPath="yes" />
            <File Id="ReadmeFile" Source="..\..\README.md" />
            <File Id="UninstallFile" Source="..\..\uninstall.ps1" />
            <RemoveFolder Id="RemoveJvmDir" Directory="JVM_DIR" On="uninstall" />
            <RemoveFolder Id="RemoveDiamtekDir" Directory="DIAMTEK_DIR" On="uninstall" />
          </Component>
          <Directory Id="ASSETS_DIR" Name="assets">
            <Component Id="AssetsComponent" Guid="d8f28b43-9824-4f05-b044-63304df2b13c">
              <File Id="IconIcoFile" Source="..\..\assets\icon.ico" KeyPath="yes" />
              <File Id="IconPngFile" Source="..\..\assets\icon.png" />
              <RemoveFolder Id="RemoveAssetsDir" Directory="ASSETS_DIR" On="uninstall" />
            </Component>
          </Directory>
          <Directory Id="INSTALLFOLDER" Name="bin">
            <Component Id="JvmBatComponent" Guid="c37c2278-f7b5-4bce-b620-df10b78e3423">
              <File Id="JvmBat" Source="..\..\jvm.bat" KeyPath="yes" />
              <Environment Id="UpdatePath" Name="PATH" Action="set" Part="last" System="no" Value="[INSTALLFOLDER]" />
              <RemoveFolder Id="RemoveInstallFolder" Directory="INSTALLFOLDER" On="uninstall" />
            </Component>
            <Component Id="HookScriptsComponent" Guid="ab54a8b7-657c-4dc1-be1e-d4c38d975a5c">
              <File Id="MsiInstallHook" Source="msi-install-hook.ps1" KeyPath="yes" />
              <File Id="MsiUninstallHook" Source="msi-uninstall-hook.ps1" />
            </Component>
          </Directory>
        </Directory>
      </Directory>
    </StandardDirectory>

    <StandardDirectory Id="ProgramMenuFolder">
      <Directory Id="ApplicationProgramsFolder" Name="DiamTek">
        <Component Id="ApplicationShortcut" Guid="41b71457-3f9c-482d-a2f7-7fa15c7e4281">
          <Shortcut Id="ApplicationStartMenuShortcut"
                    Name="Java Version Manager"
                    Description="DiamTek Java Version Manager"
                    Target="[INSTALLFOLDER]jvm.bat"
                    WorkingDirectory="INSTALLFOLDER"
                    Icon="AppIcon" />
          <RemoveFolder Id="CleanUpShortCut" Directory="ApplicationProgramsFolder" On="uninstall" />
          <RegistryValue Root="HKCU" Key="Software\DiamTek\JVM" Name="installed" Type="integer" Value="1" KeyPath="yes" />
        </Component>
      </Directory>
    </StandardDirectory>

    <Feature Id="MainFeature" Title="Java Version Manager" Level="1">
      <ComponentRef Id="DocumentationComponent" />
      <ComponentRef Id="AssetsComponent" />
      <ComponentRef Id="JvmBatComponent" />
      <ComponentRef Id="HookScriptsComponent" />
      <ComponentRef Id="ApplicationShortcut" />
    </Feature>

    <SetProperty Id="RunInstallHook" Value="&quot;[WindowsFolder]System32\WindowsPowerShell\v1.0\powershell.exe&quot; -NoProfile -NonInteractive -ExecutionPolicy Bypass -File &quot;[INSTALLFOLDER]msi-install-hook.ps1&quot;" Sequence="execute" Before="RunInstallHook" Condition="NOT (REMOVE=&quot;ALL&quot;)" />
    <CustomAction Id="RunInstallHook" BinaryRef="Wix4UtilCA_`$(sys.BUILDARCHSHORT)" DllEntry="WixQuietExec" Execute="deferred" Impersonate="yes" Return="check" />

    <SetProperty Id="RunUninstallHook" Value="&quot;[WindowsFolder]System32\WindowsPowerShell\v1.0\powershell.exe&quot; -NoProfile -NonInteractive -ExecutionPolicy Bypass -File &quot;[INSTALLFOLDER]msi-uninstall-hook.ps1&quot;" Sequence="execute" Before="RunUninstallHook" Condition="REMOVE=&quot;ALL&quot; AND NOT UPGRADINGPRODUCTCODE" />
    <CustomAction Id="RunUninstallHook" BinaryRef="Wix4UtilCA_`$(sys.BUILDARCHSHORT)" DllEntry="WixQuietExec" Execute="deferred" Impersonate="yes" Return="ignore" />

    <InstallExecuteSequence>
      <Custom Action="RunInstallHook" After="CreateShortcuts" Condition="NOT (REMOVE=&quot;ALL&quot;)" />
      <Custom Action="RunUninstallHook" Before="RemoveFiles" Condition="REMOVE=&quot;ALL&quot; AND NOT UPGRADINGPRODUCTCODE" />
    </InstallExecuteSequence>

  </Package>
</Wix>
"@
    [System.IO.File]::WriteAllText("$ScriptDir\jvm.wxs", $wxsContent, [System.Text.Encoding]::UTF8)

    # Compile the MSI using WiX v4
    $outputMsi = "$ScriptDir\jvm-windows-$Version-$TargetArch.msi"
    Remove-Item $outputMsi -Force -ErrorAction SilentlyContinue
    Write-Host "Compiling MSI ($TargetArch) using WiX v4..." -ForegroundColor Cyan
    $null = Invoke-Wix build jvm.wxs -arch $TargetArch -ext WixToolset.Util.wixext -o $outputMsi

    # Clean up temporary build artifacts
    Write-Host "Cleaning up build intermediate files..." -ForegroundColor DarkGray
    Remove-Item "$ScriptDir\jvm.wxs" -Force -ErrorAction SilentlyContinue
    Remove-Item "$ScriptDir\jvm.wixobj" -Force -ErrorAction SilentlyContinue
    Remove-Item "$ScriptDir\*.wixpdb" -Force -ErrorAction SilentlyContinue
    Remove-Item "$ScriptDir\*.cab" -Force -ErrorAction SilentlyContinue
    Remove-Item "$ScriptDir\msi-install-hook.ps1" -Force -ErrorAction SilentlyContinue
    Remove-Item "$ScriptDir\msi-uninstall-hook.ps1" -Force -ErrorAction SilentlyContinue
    Remove-Item "$ScriptDir\msi-profile-hook.ps1" -Force -ErrorAction SilentlyContinue

    if (Test-Path $outputMsi) {
        $sizeKB = [math]::Round((Get-Item $outputMsi).Length / 1KB, 1)
        $sha256 = ""
        try {
            if (Get-Command Get-FileHash -ErrorAction SilentlyContinue) {
                $sha256 = (Get-FileHash $outputMsi -Algorithm SHA256).Hash
            } else {
                $shaObj = [System.Security.Cryptography.SHA256]::Create()
                $fileStream = [System.IO.File]::OpenRead($outputMsi)
                $hashBytes = $shaObj.ComputeHash($fileStream)
                $fileStream.Close()
                $sha256 = [System.BitConverter]::ToString($hashBytes).Replace('-', '')
            }
        } catch { }

        $prodCode = "N/A"
        try {
            $wi = New-Object -ComObject WindowsInstaller.Installer
            $db = $wi.OpenDatabase((Resolve-Path $outputMsi).Path, 0)
            $view = $db.OpenView("SELECT Value FROM Property WHERE Property = 'ProductCode'")
            $view.Execute()
            $rec = $view.Fetch()
            if ($rec) { $prodCode = $rec.StringData(1) }
        } catch { }

        Write-Host ""
        Write-Host "  ============================================================" -ForegroundColor DarkGreen
        Write-Host "   [ SUCCESS ] Built Standalone MSI ($TargetArch) Package!     " -ForegroundColor Green
        Write-Host "  ============================================================" -ForegroundColor DarkGreen
        Write-Host "   File:        $outputMsi" -ForegroundColor DarkGray
        Write-Host "   Size:        $sizeKB KB" -ForegroundColor DarkGray
        Write-Host "   SHA-256:     $sha256" -ForegroundColor DarkGray
        Write-Host "   ProductCode: $prodCode" -ForegroundColor DarkGray
        Write-Host "   UpgradeCode: {DB30058E-1738-46CB-84EC-8C652DC99A22}" -ForegroundColor DarkGray
        Write-Host "  ============================================================`n" -ForegroundColor DarkGreen
    } else {
        Write-Host "`n[ ERROR ] MSI build output not found: $outputMsi" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

try {
    if ($All -or $Arch -eq "all") {
        Build-MsiPackage -TargetArch "x64"
        Build-MsiPackage -TargetArch "arm64"
    } else {
        Build-MsiPackage -TargetArch $Arch
    }
} finally {
    Pop-Location
}