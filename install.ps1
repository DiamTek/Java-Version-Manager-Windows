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
if ($content.Length -eq 0 -or $content -notmatch ":: END OF SCRIPT") {
    Write-Host "[ ERROR  ] Download failed integrity check. File is empty or truncated." -ForegroundColor Red
    exit 1
}

Write-Host "           Sanitizing code format..."
$content = $content.Replace([char]160, ' ') -replace "(?<!`r)`n", "`r`n"
[IO.File]::WriteAllText($batPath, $content, (New-Object System.Text.UTF8Encoding $false))

# 3. Safe REG_EXPAND_SZ Path Injection
Write-Host "           Configuring User PATH..."
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($null -eq $userPath) { $userPath = "" }

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
$profileCode = @"
# >>> jvm >>>
function jvm {
    & '$batPath' `$args;
    `$sessionFile = `"`$env:TEMP\.jvm_session_target`";
    if (Test-Path `$sessionFile) {
        `$lines = Get-Content `$sessionFile;
        `$newPaths = @();
        foreach (`$line in `$lines) {
            if (`$line -match '^([^=]+)=(.*)$') {
                `$key = `$matches[1]; `$val = `$matches[2];
                [Environment]::SetEnvironmentVariable(`$key, `$val, 'Process');
                `$newPaths += `"`$val\bin`";
            } elseif (![string]::IsNullOrWhiteSpace(`$line)) {
                `$env:JAVA_HOME = `$line;
                `$newPaths += `"`$line\bin`";
            }
        }
        if (`$newPaths.Count -gt 0) { `$env:Path = (`$newPaths -join ';') + ';' + `$env:Path; }
        Remove-Item `$sessionFile -Force;
    } else {
        `$vars = @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME');
        foreach (`$v in `$vars) {
            `$val = [System.Environment]::GetEnvironmentVariable(`$v, 'User');
            if ([string]::IsNullOrEmpty(`$val)) { `$val = [System.Environment]::GetEnvironmentVariable(`$v, 'Machine'); }
            [Environment]::SetEnvironmentVariable(`$v, `$val, 'Process');
        }
        `$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User');
    }
}
# <<< jvm <<<
"@

$p = $PROFILE
if (!(Test-Path $p)) { New-Item -Type File -Path $p -Force | Out-Null }
$profContent = Get-Content $p -ErrorAction SilentlyContinue | Out-String

if ($profContent -notmatch '# >>> jvm >>>') {
    Add-Content -Path $p -Value "`n$profileCode`n"
} else {
    $profContent = $profContent -replace '(?s)# >>> jvm >>>.*?# <<< jvm <<<', $profileCode
    Set-Content -Path $p -Value $profContent
}

Write-Host "`n[   OK   ] Installation Complete!" -ForegroundColor Green
Write-Host "           Open a new terminal and type 'jvm' to start.`n"