$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "[ ACTION ] Installing DiamTek Java Version Manager..." -ForegroundColor Cyan

# 1. Create a clean, dedicated bin folder
$installDir = "$env:LOCALAPPDATA\DiamTek\JVM\bin"
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
$batPath = Join-Path $installDir "jvm.bat"

Write-Host "           Fetching latest release..."
$url = "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/jvm.bat"
$content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content

# 2. Integrity Check
if ($content.Length -eq 0 -or $content -notmatch "rem END OF SCRIPT") {
    Write-Host "[ ERROR  ] Download failed integrity check. File is empty or truncated." -ForegroundColor Red
    exit 1
}

Write-Host "           Sanitizing code format..."
$content = $content.Replace([char]160, ' ') -replace "(?<!`r)`n", "`r`n"
[IO.File]::WriteAllText($batPath, $content, (New-Object System.Text.UTF8Encoding $false))

# 3. Safe REG_EXPAND_SZ Path Injection
Write-Host "           Configuring User PATH..."

$userPath = ""
$envKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment")
if ($null -ne $envKey) {
    try {
        $raw = $envKey.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if ($null -ne $raw) { $userPath = [string]$raw }
    } finally {
        $envKey.Close()
    }
}

$pathArray = $userPath -split ';' | Where-Object { $_ -ne '' }
if ($installDir -notin $pathArray) {
    $newPath = ($pathArray + $installDir) -join ';'
    [Microsoft.Win32.Registry]::SetValue("HKEY_CURRENT_USER\Environment", "Path", $newPath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
    
    # Broadcast WM_SETTINGCHANGE
    $code = '[DllImport("user32.dll")] public static extern bool SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam, int fuFlags, int uTimeout, out IntPtr lpdwResult);'
    Add-Type -MemberDefinition $code -Name NativeMethods -Namespace Win32
    [Win32.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [IntPtr]0, 'Environment', 2, 5000, [ref][IntPtr]::Zero) | Out-Null
}

# 4. Install PowerShell Profile Hook natively
Write-Host "           Configuring PowerShell Profile..."
$profileCode = @'
# >>> jvm >>>
function jvm {
    & '__JVM_BAT__' @args

    function Set-JvmVar {
        param([string]$Name, [string]$OldValue, [string]$NewValue)

        if ($OldValue) { $OldValue = $OldValue.TrimEnd('\') }
        if ($NewValue) { $NewValue = $NewValue.TrimEnd('\') }

        [Environment]::SetEnvironmentVariable($Name, $NewValue, 'Process')

        $parts = $env:Path -split ';' | Where-Object { $_ -ne '' }
        if (-not [string]::IsNullOrWhiteSpace($OldValue)) {
            $parts = $parts | Where-Object { $_.TrimEnd('\') -ne "$OldValue\bin" }
        }
        if (-not [string]::IsNullOrWhiteSpace($NewValue)) {
            $parts = $parts | Where-Object { $_.TrimEnd('\') -ne "$NewValue\bin" }
            $parts = @("$NewValue\bin") + $parts
        }
        $env:Path = $parts -join ';'
    }

    $sessionFile = "$env:TEMP\.jvm_session_target"
    if (Test-Path $sessionFile) {
        foreach ($line in (Get-Content $sessionFile)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            if ($line -match '^([^=]+)=(.*)$') {
                $key = $matches[1]
                $val = $matches[2]
            } else {
                $key = 'JAVA_HOME'
                $val = $line
            }
            $old = [Environment]::GetEnvironmentVariable($key, 'Process')
            Set-JvmVar -Name $key -OldValue $old -NewValue $val
        }
        Remove-Item $sessionFile -Force
    } else {
        foreach ($v in @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME')) {
            $old = [Environment]::GetEnvironmentVariable($v, 'Process')
            $new = [Environment]::GetEnvironmentVariable($v, 'User')
            if ([string]::IsNullOrEmpty($new)) {
                $new = [Environment]::GetEnvironmentVariable($v, 'Machine')
            }
            if ($old -eq $new) { continue }
            Set-JvmVar -Name $v -OldValue $old -NewValue $new
        }
    }
}
# <<< jvm <<<
'@

$profileCode = $profileCode.Replace('__JVM_BAT__', $batPath)

$p = $PROFILE
if (!(Test-Path $p)) { New-Item -Type File -Path $p -Force | Out-Null }
$profContent = Get-Content $p -ErrorAction SilentlyContinue | Out-String

$blockPattern = '(?s)# >>> jvm >>>.*?# <<< jvm <<<'
if ($profContent -notmatch '# >>> jvm >>>') {
    Add-Content -Path $p -Value "`n$profileCode`n"
} else {
    $m = [Regex]::Match($profContent, $blockPattern)
    if ($m.Success) {
        $profContent = $profContent.Remove($m.Index, $m.Length).Insert($m.Index, $profileCode)
        Set-Content -Path $p -Value $profContent -NoNewline
    }
}

Write-Host "`n[   OK   ] Installation Complete!" -ForegroundColor Green
Write-Host "           Open a new terminal and type 'jvm' to start.`n"