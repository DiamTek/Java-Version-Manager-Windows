$ErrorActionPreference = 'Stop'
Write-Host "[ ACTION ] Installing DiamTek Java Version Manager..." -ForegroundColor Cyan

# Create a clean, dedicated bin folder for the executable under LocalAppData
$installDir = "$env:LOCALAPPDATA\DiamTek\JVM\bin"
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
$batPath = Join-Path $installDir "jvm.bat"

Write-Host "           Fetching latest release..."
$url = "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/jvm.bat"
$content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content

Write-Host "           Sanitizing code format..."
# Scrub hidden HTML spaces and force strict Windows CRLF line endings
$content = $content.Replace([char]160, ' ') -replace "(?<!`r)`n", "`r`n"
[IO.File]::WriteAllText($batPath, $content, (New-Object System.Text.UTF8Encoding $false))

Write-Host "           Configuring User PATH..."
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($null -eq $userPath) { $userPath = "" }

if ($userPath -notmatch [regex]::Escape($installDir)) {
    $cleanPath = $userPath.TrimEnd(';')
    $newPath = ("$cleanPath;$installDir").TrimStart(';')
    
    # Safely write as ExpandString to prevent corrupting user variables
    [Microsoft.Win32.Registry]::SetValue("HKEY_CURRENT_USER\Environment", "Path", $newPath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
    
    # Broadcast WM_SETTINGCHANGE so terminal instantly picks it up
    $code = '[DllImport("user32.dll")] public static extern bool SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam, int fuFlags, int uTimeout, out IntPtr lpdwResult);'
    Add-Type -MemberDefinition $code -Name NativeMethods -Namespace Win32
    [Win32.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [IntPtr]0, 'Environment', 2, 5000, [ref][IntPtr]::Zero) | Out-Null
}

Write-Host "`n[   OK   ] Installation Complete!" -ForegroundColor Green
Write-Host "           Open a new terminal and type 'jvm' to start.`n"