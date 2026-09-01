$ErrorActionPreference = 'Stop'
Write-Host "[ ACTION ] Installing Java Version Manager..." -ForegroundColor Cyan

# Create a clean, dedicated bin folder for the executable
$installDir = "$env:USERPROFILE\.jvm\bin"
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
if ($userPath -notmatch [regex]::Escape($installDir)) {
    $cleanPath = $userPath.TrimEnd(';')
    $newPath = "$cleanPath;$installDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

Write-Host ""
Write-Host "[   OK   ] Installation Complete!" -ForegroundColor Green
Write-Host "           Open a new terminal and type 'jvm' to start."
Write-Host ""