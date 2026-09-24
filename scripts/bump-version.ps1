<#
.SYNOPSIS
    Automated version bumper and release coordinator for DiamTek Java Version Manager (Windows).

.DESCRIPTION
    Updates all version strings, build identifiers, package manifests (Winget, Scoop, Chocolatey, MSI),
    synchronizes external Scoop bucket repositories, updates CHANGELOG.md, and coordinates signed Git
    releases with modern terminal UX and pre-flight safety validations.

.PARAMETER Version
    The target semantic version (e.g. "1.0.2", "v1.0.2", "patch", "minor", "major").

.PARAMETER Build
    Optional build identifier (defaults to auto-incrementing yyyyMMdd.NNN from current jvm.bat).

.PARAMETER DryRun
    Previews all changes without modifying any files on disk or running Git operations.

.PARAMETER Commit
    Stages changed manifests and creates GPG/SSH signed commits and tags without prompt.

.PARAMETER Push
    Pushes signed release commit and targeted tag upstream to GitHub (and external bucket).

.PARAMETER Force
    Bypasses dirty working tree warnings, downgrade warnings, and pre-flight confirmation prompts.

.PARAMETER NoSign
    Disables GPG/SSH commit and tag signing (fallback if signing key is not configured).

.PARAMETER NoBucketSync
    Skips synchronizing sibling Scoop bucket repository (..\scoop-bucket).

.EXAMPLE
    .\scripts\bump-version.ps1
    .\scripts\bump-version.ps1 patch -DryRun
    .\scripts\bump-version.ps1 1.0.2 -Commit -Push
    .\scripts\bump-version.ps1 minor -Force
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Version,

    [Parameter(Mandatory = $false)]
    [string]$Build,

    [switch]$DryRun,
    [switch]$Commit,
    [switch]$Push,
    [switch]$Force,
    [switch]$NoSign,
    [switch]$NoBucketSync
)

$ErrorActionPreference = 'Stop'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

if (-not [string]::IsNullOrWhiteSpace($Version)) {
    if ($Version -notmatch '^(patch|minor|major|v?\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?)$' -or $Version -match '\.\.') {
        throw "Security validation failed (CWE-20): Invalid Version parameter '$Version'."
    }
}
if (-not [string]::IsNullOrWhiteSpace($Build)) {
    if ($Build -notmatch '^\d{8}\.\d+$' -or $Build -match '\.\.') {
        throw "Security validation failed (CWE-20): Invalid Build parameter '$Build'."
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Split-Path -Parent $ScriptDir

# Ensure UTF-8 without BOM across all read/write operations (critical for cmd.exe parsing of jvm.bat)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Ensure console displays Unicode box-drawing and ANSI characters accurately
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} catch { }

# Parameter dependency resolution (-Push implies -Commit)
if ($Push.IsPresent -and -not $Commit.IsPresent) {
    $Commit = [switch]::new($true)
}

# --- ANSI Formatting & UI Box-Drawing Helpers ---
$ESC = [char]27
$cReset = "$ESC[0m"
$cBold = "$ESC[1m"
$cCyan = "$ESC[36m"
$cGreen = "$ESC[32m"
$cYellow = "$ESC[33m"
$cRed = "$ESC[31m"
$cGray = "$ESC[90m"
$cWhite = "$ESC[37m"
$cBrightCyan = "$ESC[96m"

function Write-BoxHeader {
    param ([string]$Title)
    $innerLength = 68
    $padTotal = $innerLength - $Title.Length
    $padLeft = [math]::Floor($padTotal / 2)
    $padRight = $padTotal - $padLeft

    Write-Host ""
    Write-Host "$cCyan$cBold╭$('─' * $innerLength)╮$cReset"
    Write-Host "$cCyan$cBold│$cReset$(' ' * $padLeft)$cWhite$cBold$Title$cReset$(' ' * $padRight)$cCyan$cBold│$cReset"
    Write-Host "$cCyan$cBold╰$('─' * $innerLength)╯$cReset"
    Write-Host ""
}

function Write-PropertyTable {
    param ([System.Collections.Specialized.OrderedDictionary]$Rows)
    # Total width: 1 + 1 + 21 + 1 + 1 + 2 + 41 + 1 + 1 = 70 characters
    Write-Host "$cCyan┌───────────────────────┬────────────────────────────────────────────┐$cReset"
    foreach ($key in $Rows.Keys) {
        $val = $Rows[$key]
        $keyPadded = $key.PadRight(21)
        # Strip leading whitespace after any leading ANSI escape codes
        $cleanVal = [regex]::Replace($val, "^((?:\x1B\[[0-9;]*[a-zA-Z])+)\s+", "`$1")
        $cleanVal = [regex]::Replace($cleanVal, '^\s+', '')
        # Strip ANSI codes when calculating visible width of value
        $plainVal = [regex]::Replace($cleanVal, '\x1B\[[0-9;]*[a-zA-Z]', '')
        $valPadLength = [math]::Max(0, 41 - $plainVal.Length)
        $valPadded = $cleanVal + (' ' * $valPadLength)
        Write-Host "$cCyan│$cReset $cBold$keyPadded$cReset $cCyan│$cReset  $valPadded $cCyan│$cReset"
    }
    Write-Host "$cCyan└───────────────────────┴────────────────────────────────────────────┘$cReset"
    Write-Host ""
}

# Native Git invocation helper with strict exit code checking, UTF-8 streams, and Windows argument escaping
function Invoke-Git {
    param (
        [string]$Directory,
        [string[]]$GitArgs,
        [switch]$IgnoreError,
        [switch]$CaptureOutput
    )

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "git"
    $pinfo.WorkingDirectory = $Directory
    $pinfo.RedirectStandardOutput = $CaptureOutput.IsPresent
    $pinfo.RedirectStandardError = $CaptureOutput.IsPresent
    $pinfo.StandardOutputEncoding = $Utf8NoBom
    $pinfo.StandardErrorEncoding = $Utf8NoBom
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true

    # Build argument string using CommandLineToArgvW rules (double trailing backslashes before quotes)
    $argList = [System.Collections.Generic.List[string]]::new()
    foreach ($a in $GitArgs) {
        if ([string]::IsNullOrEmpty($a)) {
            $argList.Add('""')
        } elseif ($a -match '[\s"]') {
            $escaped = [regex]::Replace($a, '(\\*)"', '$1$1\"')
            $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
            $argList.Add('"' + $escaped + '"')
        } else {
            $argList.Add($a)
        }
    }
    $pinfo.Arguments = [string]::Join(' ', $argList)

    $proc = [System.Diagnostics.Process]::Start($pinfo)
    $stdout = if ($CaptureOutput.IsPresent) { $proc.StandardOutput.ReadToEnd() } else { "" }
    $stderr = if ($CaptureOutput.IsPresent) { $proc.StandardError.ReadToEnd() } else { "" }
    $proc.WaitForExit()

    if ($proc.ExitCode -ne 0 -and -not $IgnoreError) {
        $errDetail = if ($CaptureOutput.IsPresent -and -not [string]::IsNullOrWhiteSpace($stderr)) { $stderr.Trim() } else { "Exit code $($proc.ExitCode)" }
        throw "Git command failed in '$Directory': git $($pinfo.Arguments)`n$errDetail"
    }

    if ($CaptureOutput.IsPresent) {
        return $stdout
    }
    return $proc.ExitCode
}

# Local MSI & Security verification test runner
function Invoke-TestRunner {
    $secScript = Join-Path $RepoRoot "tests\Test-JvmSecurity.ps1"
    if (Test-Path $secScript) {
        Write-Host ""
        Write-Host "${cCyan}${cBold}Executing Security & Adversarial Test Suite (Test-JvmSecurity.ps1)...${cReset}"
        try {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $secScript -Detailed
            if ($LASTEXITCODE -ne 0) {
                Write-Host "${cRed}[TEST FAILED] Security test suite reported failures!${cReset}" -ForegroundColor Red
            }
        } catch {
            Write-Host "${cRed}[TEST ERROR]$cReset $_" -ForegroundColor Red
        }
    }

    $testMsiScript = Join-Path $RepoRoot "packages\msi\test-msi.ps1"
    if (Test-Path $testMsiScript) {
        Write-Host ""
        Write-Host "${cCyan}${cBold}Executing Local Verification Suite (test-msi.ps1)...${cReset}"
        try {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $testMsiScript
        } catch {
            Write-Host "${cRed}[TEST ERROR]$cReset $_" -ForegroundColor Red
        }
        Write-Host ""
    } else {
        Write-Host "${cYellow}[WARN]$cReset Test script not found at: '$testMsiScript'"
    }
}

function Get-MsiProductCode {
    param ([string]$MsiFilePath)
    try {
        $wi = New-Object -ComObject WindowsInstaller.Installer
        $db = $wi.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $wi, @($MsiFilePath, 0))
        $view = $db.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $db, @("SELECT Value FROM Property WHERE Property = 'ProductCode'"))
        $view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null)
        $rec = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
        if ($rec) {
            return $rec.GetType().InvokeMember("StringData", "GetProperty", $null, $rec, @(1))
        }
    } catch { }
    return $null
}

# Windows Package Manager (Winget) coordinator
function Invoke-WingetCoordinator {
    param (
        [string]$TargetVersion,
        [switch]$IsDryRun
    )

    Write-Host ""
    Write-Host "$cCyan$cBold╭────────────────────────────────────────────────────────────────────╮$cReset"
    Write-Host "$cCyan$cBold│                  Windows Package Manager (Winget)                  │$cReset"
    Write-Host "$cCyan$cBold╰────────────────────────────────────────────────────────────────────╯$cReset"
    Write-Host ""

    # 1. Manifest validation
    $manifestPath = Join-Path $RepoRoot "packages\winget"
    $manifestValid = $false
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  $cCyan→$cReset Running manifest validation (winget validate)..." -ForegroundColor Gray
        try {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "winget"
            $pinfo.Arguments = "validate --manifest `"$manifestPath`""
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true
            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $proc.WaitForExit()
            if ($proc.ExitCode -eq 0) {
                $manifestValid = $true
                Write-Host "  ${cGreen}[PASS]$cReset Local Winget manifests validated successfully."
            } else {
                Write-Host "  ${cRed}[FAIL]$cReset Winget manifest validation failed (exit code $($proc.ExitCode))." -ForegroundColor Red
            }
        } catch {
            Write-Host "  ${cYellow}[WARN]$cReset Could not execute 'winget validate': $_"
        }
    } else {
        Write-Host "  ${cYellow}[INFO]$cReset 'winget' CLI not found; skipping local manifest validation."
    }

    # 2. Check GitHub Token
    $token = $null
    $tokenDisplay = "Not detected (OAuth fallback)"
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        try {
            $candidate = (& gh auth token 2>$null).Trim()
            if ($candidate) {
                $token = $candidate
                $masked = if ($token.Length -gt 8) { $token.Substring(0, 4) + '****' + $token.Substring($token.Length - 4) } else { '****' }
                $tokenDisplay = "Detected via gh ($masked)"
                Write-Host "  ${cGreen}[PASS]$cReset GitHub token detected via 'gh auth token' ($masked)."
            }
        } catch { }
    }
    if (-not $token) {
        Write-Host "  ${cYellow}[INFO]$cReset No token detected from 'gh auth token'. wingetcreate will use cached token or prompt for OAuth."
    }

    # 3. Check upstream winget repository status
    $isMergedUpstream = $false
    if (Get-Command wingetcreate -ErrorAction SilentlyContinue) {
        Write-Host "  $cCyan→$cReset Checking package status in microsoft/winget-pkgs..." -ForegroundColor Gray
        try {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "wingetcreate"
            $pinfo.Arguments = "show DiamTek.JVM"
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true
            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $proc.WaitForExit()
            if ($proc.ExitCode -eq 0 -and $stdout -notmatch 'not found') {
                $isMergedUpstream = $true
                Write-Host "  ${cGreen}[INFO]$cReset DiamTek.JVM is present upstream in microsoft/winget-pkgs."
            } else {
                Write-Host "  ${cYellow}[INFO]$cReset DiamTek.JVM is not yet merged upstream in microsoft/winget-pkgs."
            }
        } catch {
            Write-Host "  ${cYellow}[WARN]$cReset Could not probe microsoft/winget-pkgs: $_"
        }
    } else {
        Write-Host "  ${cYellow}[WARN]$cReset 'wingetcreate' CLI not found on PATH."
    }

    # Probe for any open pull requests on microsoft/winget-pkgs
    $openPrInfo = $null
    if (-not $isMergedUpstream -and (Get-Command gh -ErrorAction SilentlyContinue)) {
        try {
            $ghPrJson = (& gh pr list --repo microsoft/winget-pkgs --search "DiamTek.JVM in:title" --state open --json number,title,url,state 2>$null)
            if ($ghPrJson) {
                $openPrs = $ghPrJson | ConvertFrom-Json
                if ($openPrs -and $openPrs.Count -gt 0) {
                    $openPrInfo = $openPrs[0]
                }
            }
        } catch { }
    }

    # 4. Resolve installer URLs and command
    $msiUrlX64 = "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/v$TargetVersion/jvm-windows-$TargetVersion-x64.msi"
    $msiUrlArm64 = "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/v$TargetVersion/jvm-windows-$TargetVersion-arm64.msi"

    $displayCmd = $null
    [string[]]$wingetArgs = @()

    if ($isMergedUpstream) {
        $displayCmd = "wingetcreate update DiamTek.JVM -v $TargetVersion -u `"$msiUrlX64`" `"$msiUrlArm64`" --submit"
        $wingetArgs = @("update", "DiamTek.JVM", "-v", $TargetVersion, "-u", $msiUrlX64, $msiUrlArm64, "--submit")
    } else {
        $displayCmd = "wingetcreate submit `"$manifestPath`" --prtitle `"DiamTek.JVM version $TargetVersion`""
        $wingetArgs = @("submit", $manifestPath, "--prtitle", "DiamTek.JVM version $TargetVersion")
    }

    $wingetTable = [ordered]@{
        "Target Version"  = "$cGreen$cBold v$TargetVersion $cReset"
        "Upstream Status" = if ($isMergedUpstream) {
            "$cGreen Merged (Update workflow active)$cReset"
        } elseif ($openPrInfo) {
            "$cYellow In Review (PR #$($openPrInfo.number))$cReset"
        } else {
            "$cYellow Not merged (Initial PR required)$cReset"
        }
        "Local Manifests" = if (Test-Path $manifestPath) { "$cGreen Ready (packages\winget)$cReset" } else { "$cRed Missing$cReset" }
        "Auth Token"      = if ($token) { "$cGreen Configured$cReset" } else { "$cYellow Not detected$cReset" }
    }
    Write-PropertyTable $wingetTable

    if ($openPrInfo) {
        Write-Host "  ${cYellow}[PENDING PR]$cReset An initial PR is currently pending review on microsoft/winget-pkgs:" -ForegroundColor Yellow
        Write-Host "    PR #$($openPrInfo.number): $($openPrInfo.title)" -ForegroundColor Cyan
        Write-Host "    URL: $($openPrInfo.url)" -ForegroundColor DarkGray
        Write-Host "    Wait for Microsoft to merge this PR before submitting new versions." -ForegroundColor DarkGray
        Write-Host ""
    }

    Write-Host "Resolved Winget submission command:" -ForegroundColor Gray
    Write-Host "  $cBrightCyan$displayCmd$cReset"
    Write-Host ""

    if ($IsDryRun) {
        Write-Host "  ${cYellow}[DRY RUN MODE]$cReset Manifests and token verified. Live PR submission is strictly disabled in DryRun."
        if (-not $Force) {
            Write-Host "  ${cCyan}[1]$cReset Return to DryRun menu (safe, no PR created)"
            Write-Host "  ${cCyan}[2]$cReset Print resolved command for manual execution"
            if ($openPrInfo) {
                Write-Host "  ${cCyan}[3]$cReset Open PR #$($openPrInfo.number) in browser"
            }
            Write-Host ""

            $dryWChoice = Read-Host "Select Winget DryRun option (default: 1 [return])"
            if ($dryWChoice -eq '2') {
                Write-Host ""
                Write-Host "Command:" -ForegroundColor Gray
                Write-Host "  $cBrightCyan$displayCmd$cReset"
                Write-Host ""
            } elseif ($dryWChoice -eq '3' -and $openPrInfo) {
                Start-Process $openPrInfo.url
            }
        }
        return
    }

    # Live flow
    if ($openPrInfo) {
        Write-Host "  ${cCyan}[1]$cReset Open PR #$($openPrInfo.number) in browser"
        Write-Host "  ${cCyan}[2]$cReset Print command for manual execution"
        Write-Host "  ${cCyan}[3]$cReset Submit PR anyway (force new PR)"
        Write-Host "  ${cCyan}[4]$cReset Skip Winget submission"
        Write-Host ""

        $wingetChoice = Read-Host "Select Winget option [1-4] (default: 1 [open PR])"
        if ([string]::IsNullOrWhiteSpace($wingetChoice)) { $wingetChoice = '1' }
        if ($wingetChoice -eq '1') {
            Start-Process $openPrInfo.url
            return
        } elseif ($wingetChoice -eq '2') {
            Write-Host "Command: $cBrightCyan$displayCmd$cReset"
            return
        } elseif ($wingetChoice -eq '4') {
            return
        }
        # Choice 3 proceeds below to submit
    } else {
        Write-Host "  ${cCyan}[1]$cReset Submit Winget package to microsoft/winget-pkgs"
        Write-Host "  ${cCyan}[2]$cReset Print command for manual execution"
        Write-Host "  ${cCyan}[3]$cReset Skip Winget submission"
        Write-Host ""

        $wingetChoice = Read-Host "Select Winget option [1-3] (default: 1 [submit])"
        if ([string]::IsNullOrWhiteSpace($wingetChoice)) { $wingetChoice = '1' }
        if ($wingetChoice -eq '2') {
            Write-Host "Command: $cBrightCyan$displayCmd$cReset"
            return
        } elseif ($wingetChoice -eq '3') {
            return
        }
    }

    switch ($wingetChoice) {
        '1' {
            if (-not (Get-Command wingetcreate -ErrorAction SilentlyContinue)) {
                Write-Host "${cYellow}[WARN]$cReset 'wingetcreate' command not found on PATH. Run manually:"
                Write-Host "  $cBrightCyan$displayCmd$cReset"
            } else {
                Write-Host ""
                Write-Host "Verifying release assets are available on GitHub Releases CDN..." -ForegroundColor Yellow
                Write-Host "Probing: $msiUrlX64" -ForegroundColor Gray

                $maxAttempts = 30
                $attempt = 0
                $assetReady = $false

                while ($attempt -lt $maxAttempts -and -not $assetReady) {
                    $attempt++
                    try {
                        $req = [System.Net.WebRequest]::Create($msiUrlX64)
                        $req.Method = "HEAD"
                        $req.Timeout = 10000
                        $res = $req.GetResponse()
                        if ($res.StatusCode -eq [System.Net.HttpStatusCode]::OK) {
                            $assetReady = $true
                            $res.Close()
                            break
                        }
                        $res.Close()
                    } catch { }

                    Write-Host "  [Attempt $attempt/$maxAttempts] Waiting for CDN release assets... (10s)" -ForegroundColor DarkGray
                    Start-Sleep -Seconds 10
                }

                if (-not $assetReady) {
                    Write-Host "${cYellow}[TIMEOUT]$cReset Release assets not detected yet (build may still be running in GitHub Actions)."
                    Write-Host "Run this command once CI finishes:" -ForegroundColor Yellow
                    Write-Host "  $cBrightCyan$displayCmd$cReset"
                    return
                }
                Write-Host "${cGreen}[READY]$cReset Release MSIs verified online!" -ForegroundColor Green

                if (-not $isMergedUpstream) {
                    $installerYaml = Join-Path $manifestPath "DiamTek.JVM.installer.yaml"
                    if (Test-Path $installerYaml) {
                        Write-Host "Downloading release MSIs to compute exact SHA256 and ProductCode..." -ForegroundColor Cyan
                        $tempX64 = Join-Path $env:TEMP "jvm-$TargetVersion-x64.msi"
                        $tempArm64 = Join-Path $env:TEMP "jvm-$TargetVersion-arm64.msi"
                        try {
                            Invoke-WebRequest -Uri $msiUrlX64 -OutFile $tempX64 -UseBasicParsing
                            Invoke-WebRequest -Uri $msiUrlArm64 -OutFile $tempArm64 -UseBasicParsing

                            $hashX64 = (Get-FileHash -Path $tempX64 -Algorithm SHA256).Hash.ToUpper()
                            $hashArm64 = (Get-FileHash -Path $tempArm64 -Algorithm SHA256).Hash.ToUpper()
                            $pcX64 = Get-MsiProductCode $tempX64
                            $pcArm64 = Get-MsiProductCode $tempArm64

                            if ($hashX64 -and $hashArm64) {
                                $yamlText = [System.IO.File]::ReadAllText($installerYaml, [System.Text.Encoding]::UTF8)
                                if ($yamlText -match '(?s)(Architecture:\s*x64.*?)(Architecture:\s*arm64|\z)') {
                                    $x64Block = $matches[1]
                                    $newX64Block = [regex]::Replace($x64Block, 'InstallerSha256:\s*\S+', "InstallerSha256: $hashX64")
                                    if ($pcX64) { $newX64Block = [regex]::Replace($newX64Block, 'ProductCode:\s*[''"][^''"]*[''"]', "ProductCode: '$pcX64'") }
                                    $yamlText = $yamlText.Replace($x64Block, $newX64Block)
                                }
                                if ($yamlText -match '(?s)(Architecture:\s*arm64.*?)(\z)') {
                                    $arm64Block = $matches[1]
                                    $newArm64Block = [regex]::Replace($arm64Block, 'InstallerSha256:\s*\S+', "InstallerSha256: $hashArm64")
                                    if ($pcArm64) { $newArm64Block = [regex]::Replace($newArm64Block, 'ProductCode:\s*[''"][^''"]*[''"]', "ProductCode: '$pcArm64'") }
                                    $yamlText = $yamlText.Replace($arm64Block, $newArm64Block)
                                }
                                [System.IO.File]::WriteAllText($installerYaml, $yamlText, $Utf8NoBom)
                                Write-Host "${cGreen}[UPDATED]$cReset Synchronized DiamTek.JVM.installer.yaml with online MSI hashes and ProductCodes."
                                $chocoInstallPath = Join-Path $RepoRoot "packages\choco\tools\chocolateyInstall.ps1"
                                if (Test-Path $chocoInstallPath) {
                                    $ciContent = [System.IO.File]::ReadAllText($chocoInstallPath, [System.Text.Encoding]::UTF8)
                                    $ciContent = [regex]::Replace($ciContent, "(?m)^(\`$checksum64\s*=\s*')[^']*(')", "`${1}$hashX64`${2}")
                                    [System.IO.File]::WriteAllText($chocoInstallPath, $ciContent, $Utf8NoBom)
                                    Write-Host "${cGreen}[UPDATED]$cReset Synchronized chocolateyInstall.ps1 with online x64 MSI hash ($hashX64)."
                                }
                            }
                        } catch {
                            Write-Host "${cYellow}[WARN]$cReset Could not auto-download MSIs to update hashes: $_"
                        } finally {
                            Remove-Item $tempX64, $tempArm64 -Force -ErrorAction SilentlyContinue
                        }
                    }
                }

                try {
                    if ($token) {
                        $env:WINGET_CREATE_GITHUB_TOKEN = $token
                        $env:GITHUB_TOKEN = $token
                    }
                    Write-Host "Executing Winget submission..." -ForegroundColor Cyan
                    & wingetcreate @wingetArgs
                } finally {
                    if ($token) {
                        $env:WINGET_CREATE_GITHUB_TOKEN = $null
                        $env:GITHUB_TOKEN = $null
                    }
                }
            }
        }
        '2' {
            Write-Host ""
            Write-Host "Command:" -ForegroundColor Yellow
            Write-Host "  $cBrightCyan$displayCmd$cReset"
            Write-Host ""
        }
        default {
            Write-Host "Winget submission skipped." -ForegroundColor Gray
        }
    }
}

# Scoop bucket coordinator
function Invoke-ScoopCoordinator {
    param (
        [string]$TargetVersion,
        [switch]$IsDryRun
    )

    Write-Host ""
    Write-Host "$cCyan$cBold╭────────────────────────────────────────────────────────────────────╮$cReset"
    Write-Host "$cCyan$cBold│                       Scoop Bucket Coordinator                     │$cReset"
    Write-Host "$cCyan$cBold╰────────────────────────────────────────────────────────────────────╯$cReset"
    Write-Host ""

    $internalScoop = Join-Path $RepoRoot "packages\scoop\jvm.json"
    $externalBucketManifest = Join-Path (Split-Path -Parent $RepoRoot) "scoop-bucket\bucket\jvm.json"
    $bucketPresent = Test-Path $externalBucketManifest
    $ghInstalled = [bool](Get-Command gh -ErrorAction SilentlyContinue)

    $scoopTable = [ordered]@{
        "Target Version"    = "$cGreen$cBold v$TargetVersion $cReset"
        "Internal Manifest" = if (Test-Path $internalScoop) { "$cGreen Ready (packages\scoop\jvm.json)$cReset" } else { "$cRed Missing$cReset" }
        "External Bucket"   = if ($bucketPresent) { "$cGreen Ready (..\scoop-bucket)$cReset" } else { "$cGray Not found$cReset" }
        "Excavator Action"  = if ($ghInstalled) { "$cGreen Available (DiamTek/scoop-bucket)$cReset" } else { "$cYellow gh CLI not found$cReset" }
    }
    Write-PropertyTable $scoopTable

    if ($IsDryRun) {
        Write-Host "  ${cYellow}[DRY RUN MODE]$cReset Scoop bucket synchronization is strictly disabled in DryRun."
        if (-not $Force) {
            Write-Host "  ${cCyan}[1]$cReset Return to DryRun menu"
            Write-Host "  ${cCyan}[2]$cReset Print Excavator dispatch command"
            Write-Host ""
            $choice = Read-Host "Select Scoop DryRun option [1-2] (default: 1 [return])"
            if ($choice -eq '2') {
                Write-Host ""
                Write-Host "Excavator command:" -ForegroundColor Gray
                Write-Host "  $cBrightCyan gh workflow run Excavator --repo DiamTek/scoop-bucket $cReset"
                Write-Host ""
            }
        }
        return
    }

    Write-Host "  ${cCyan}[1]$cReset Trigger Excavator on DiamTek/scoop-bucket (Recommended)"
    Write-Host "  ${cCyan}[2]$cReset Wait for SHA256SUMS.txt on CDN, sync local hashes, and push"
    Write-Host "  ${cCyan}[3]$cReset Return to menu / skip"
    Write-Host ""

    $choice = Read-Host "Select Scoop action [1-3] (default: 1 [trigger Excavator])"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '1' }

    switch ($choice) {
        '1' {
            if ($ghInstalled) {
                Write-Host "Dispatching Excavator workflow on DiamTek/scoop-bucket..." -ForegroundColor Cyan
                & gh workflow run Excavator --repo DiamTek/scoop-bucket
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "${cGreen}[DISPATCHED]$cReset Excavator workflow triggered. Scoop will auto-update bucket/jvm.json with verified checksums."
                } else {
                    Write-Host "${cYellow}[WARN]$cReset Failed to dispatch Excavator workflow."
                }
            } else {
                Write-Host "${cYellow}[WARN]$cReset GitHub CLI ('gh') is not installed."
            }
        }
        '2' {
            $shaUrl = "https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/v$TargetVersion/SHA256SUMS.txt"
            Write-Host "Waiting for release checksums on CDN..." -ForegroundColor Yellow
            Write-Host "Probing: $shaUrl" -ForegroundColor Gray

            $maxAttempts = 30
            $attempt = 0
            $shaText = $null

            while ($attempt -lt $maxAttempts -and -not $shaText) {
                $attempt++
                try {
                    $req = [System.Net.WebRequest]::Create($shaUrl)
                    $req.Timeout = 5000
                    $res = $req.GetResponse()
                    $sr = New-Object System.IO.StreamReader($res.GetResponseStream())
                    $shaText = $sr.ReadToEnd()
                    $sr.Close()
                    $res.Close()
                    break
                } catch { }
                Write-Host "  [Attempt $attempt/$maxAttempts] Waiting for SHA256SUMS.txt... (10s)" -ForegroundColor DarkGray
                Start-Sleep -Seconds 10
            }

            if ($shaText) {
                $portableZipHash = $null
                foreach ($line in ($shaText -split "`r?`n")) {
                    if ($line -match "^([0-9a-fA-F]{64})\s+jvm-windows-$([regex]::Escape($TargetVersion))-portable\.zip$") {
                        $portableZipHash = $matches[1].ToLower()
                        break
                    }
                }

                if ($portableZipHash) {
                    Write-Host "${cGreen}[FOUND]$cReset Portable zip SHA256: $portableZipHash"

                    if (Test-Path $internalScoop) {
                        $c = [System.IO.File]::ReadAllText($internalScoop, $Utf8NoBom)
                        $c = [regex]::Replace($c, '("hash":\s*")[^"]*(")', "`${1}$portableZipHash`${2}")
                        [System.IO.File]::WriteAllText($internalScoop, $c, $Utf8NoBom)
                        Write-Host "  ${cGreen}[OK]$cReset Updated packages\scoop\jvm.json"
                    }

                    if ($bucketPresent) {
                        $c = [System.IO.File]::ReadAllText($externalBucketManifest, $Utf8NoBom)
                        $c = [regex]::Replace($c, '("version":\s*")[^"]*(")', "`${1}$TargetVersion`${2}")
                        $c = [regex]::Replace($c, '(?<=releases/download/v)\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?', $TargetVersion)
                        $c = [regex]::Replace($c, '(?<=jvm-windows-)\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?', $TargetVersion)
                        $c = [regex]::Replace($c, '("hash":\s*")[^"]*(")', "`${1}$portableZipHash`${2}")
                        [System.IO.File]::WriteAllText($externalBucketManifest, $c, $Utf8NoBom)
                        Write-Host "  ${cGreen}[OK]$cReset Updated ..\scoop-bucket\bucket\jvm.json"

                        $bucketDir = Split-Path -Parent (Split-Path -Parent $externalBucketManifest)
                        $bBranch = (Invoke-Git -Directory $bucketDir -GitArgs @("rev-parse", "--abbrev-ref", "HEAD") -CaptureOutput).Trim()
                        Invoke-Git -Directory $bucketDir -GitArgs @("add", "bucket/jvm.json") | Out-Null
                        $signArgs = if ($NoSign) { @("commit", "-m") } else { @("commit", "-S", "-m") }
                        Invoke-Git -Directory $bucketDir -GitArgs ($signArgs + @("feat(jvm): update to version $TargetVersion with verified hash")) | Out-Null
                        Invoke-Git -Directory $bucketDir -GitArgs @("push", "origin", $bBranch) | Out-Null
                        Write-Host "${cGreen}[PUSHED]$cReset Committed and pushed to DiamTek/scoop-bucket."
                    }
                } else {
                    Write-Host "${cYellow}[WARN]$cReset Could not find jvm-windows-$TargetVersion-portable.zip in SHA256SUMS.txt."
                }
            } else {
                Write-Host "${cYellow}[TIMEOUT]$cReset Checksums not available yet. Run Excavator later."
            }
        }
        default {
            Write-Host "Scoop coordination skipped." -ForegroundColor Gray
        }
    }
}

# Chocolatey release coordinator
function Invoke-ChocoCoordinator {
    param (
        [string]$TargetVersion,
        [switch]$IsDryRun
    )

    Write-Host ""
    Write-Host "$cCyan$cBold╭────────────────────────────────────────────────────────────────────╮$cReset"
    Write-Host "$cCyan$cBold│                     Chocolatey Release Manager                     │$cReset"
    Write-Host "$cCyan$cBold╰────────────────────────────────────────────────────────────────────╯$cReset"
    Write-Host ""

    if (-not (Get-Command choco -ErrorAction SilentlyContinue) -and (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe")) {
        $env:PATH = "C:\ProgramData\chocolatey\bin;$env:PATH"
    }
    $chocoInstalled = [bool](Get-Command choco -ErrorAction SilentlyContinue)
    $nuspecPath = Join-Path $RepoRoot "packages\choco\jvm.nuspec"
    $pkgDir = Join-Path $RepoRoot "packages\choco"

    # API key detection
    $apiKeyEnv = if ($env:CHOCOLATEY_API_KEY) {
        $env:CHOCOLATEY_API_KEY
    } elseif ($env:CHOCO_API_KEY) {
        $env:CHOCO_API_KEY
    } else {
        $null
    }

    $apiKeyConfigured = $false
    $apiKeySource = $null

    if ($apiKeyEnv) {
        $apiKeyConfigured = $true
        $apiKeySource = "env:CHOCOLATEY_API_KEY"
    } elseif ($chocoInstalled) {
        try {
            $apiKeyOut = (& choco apikey 2>&1) | Out-String
            if ($apiKeyOut -match 'https://push\.chocolatey\.org/') {
                $apiKeyConfigured = $true
                $apiKeySource = "choco apikey"
            }
        } catch { }
    }

    $chocoTable = [ordered]@{
        "Target Version"  = "$cGreen$cBold v$TargetVersion $cReset"
        "Choco CLI"       = if ($chocoInstalled) { "$cGreen Installed$cReset" } else { "$cYellow Not installed / not in PATH$cReset" }
        "Nuspec File"     = if (Test-Path $nuspecPath) { "$cGreen Ready (packages\choco\jvm.nuspec)$cReset" } else { "$cRed Missing$cReset" }
        "API Key Status"  = if ($apiKeyConfigured) { "$cGreen Configured ($apiKeySource)$cReset" } else { "$cYellow Not detected$cReset" }
    }
    Write-PropertyTable $chocoTable

    if ($IsDryRun) {
        Write-Host "  ${cYellow}[DRY RUN MODE]$cReset Package building & publishing is strictly disabled in DryRun."
        Write-Host ""
        if (-not $Force) {
            Write-Host "  Press Enter to return to DryRun menu..." -ForegroundColor Gray
            $null = Read-Host
        }
        return
    }

    if (-not $chocoInstalled) {
        Write-Host "${cYellow}[NOTE]$cReset 'choco' CLI is not found on your system."
        Write-Host "  • Manifest files in 'packages\choco\' are synchronized to v$TargetVersion." -ForegroundColor Gray
        Write-Host "  • To install Chocolatey CLI: https://chocolatey.org/install" -ForegroundColor Gray
        Write-Host "    Or run in PowerShell (as Administrator):" -ForegroundColor DarkGray
        Write-Host "      Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  • Chocolatey API Key setup options:" -ForegroundColor Gray
        Write-Host "    Option 1: Stored encrypted (Recommended once choco is installed):" -ForegroundColor Cyan
        Write-Host "      choco apikey --key <YOUR_API_KEY> --source https://push.chocolatey.org/" -ForegroundColor White
        Write-Host "    Option 2: User Environment Variable:" -ForegroundColor Cyan
        Write-Host "      [Environment]::SetEnvironmentVariable('CHOCOLATEY_API_KEY', '<YOUR_API_KEY>', 'User')" -ForegroundColor White
        Write-Host ""
        return
    }

    if (-not $apiKeyConfigured) {
        Write-Host "${cYellow}[API KEY NEEDED]$cReset Chocolatey push requires an API key from https://community.chocolatey.org/account" -ForegroundColor Yellow
        Write-Host "  You can configure it via:"
        Write-Host "    1. choco apikey --key <YOUR_API_KEY> --source https://push.chocolatey.org/" -ForegroundColor Cyan
        Write-Host "    2. `$env:CHOCOLATEY_API_KEY = '<YOUR_API_KEY>'" -ForegroundColor Cyan
        Write-Host ""
    }

    Write-Host "  ${cCyan}[1]$cReset Build & pack package (choco pack packages\choco\jvm.nuspec)"
    Write-Host "  ${cCyan}[2]$cReset Pack & Push package to community.chocolatey.org"
    Write-Host "  ${cCyan}[3]$cReset Configure Chocolatey API key"
    Write-Host "  ${cCyan}[4]$cReset Return to menu"
    Write-Host ""

    $chocoAction = Read-Host "Select Chocolatey action [1-4] (default: 4 [return])"
    switch ($chocoAction) {
        '1' {
            Write-Host "Packing Chocolatey package..." -ForegroundColor Cyan
            & choco pack $nuspecPath --outputdirectory $pkgDir
        }
        '2' {
            Write-Host "Packing Chocolatey package..." -ForegroundColor Cyan
            & choco pack $nuspecPath --outputdirectory $pkgDir
            if ($LASTEXITCODE -eq 0) {
                $nupkgFile = Join-Path $pkgDir "jvm-windows.$TargetVersion.nupkg"
                if (Test-Path $nupkgFile) {
                    Write-Host "Pushing $nupkgFile to community.chocolatey.org..." -ForegroundColor Cyan
                    if ($apiKeyEnv) {
                        & choco push $nupkgFile --source https://push.chocolatey.org/ --api-key $apiKeyEnv
                    } else {
                        & choco push $nupkgFile --source https://push.chocolatey.org/
                    }
                }
            }
        }
        '3' {
            $keyInput = Read-Host "Enter your Chocolatey API key"
            if (-not [string]::IsNullOrWhiteSpace($keyInput)) {
                & choco apikey --key $keyInput.Trim() --source https://push.chocolatey.org/
                Write-Host "${cGreen}[SAVED]$cReset Chocolatey API key registered successfully."
            }
        }
        default {
            # Return
        }
    }
}

# 1. Helper to determine current repository version and build from jvm.bat
function Get-CurrentMetadata {
    $jvmBat = Join-Path $RepoRoot "jvm.bat"
    if (-not (Test-Path $jvmBat)) {
        Write-Error "Core batch engine not found at: '$jvmBat'. Cannot read current version and build."
        exit 1
    }

    $ver = $null
    $bld = $null

    $jvmContent = [System.IO.File]::ReadAllText($jvmBat, $Utf8NoBom)
    if ($jvmContent -match '(?m)^set\s+("?)JVM_VERSION=([^"\r\n]+)') {
        $ver = $matches[2].Trim()
    }
    if ($jvmContent -match '(?m)^set\s+("?)JVM_BUILD=([^"\r\n]+)') {
        $bld = $matches[2].Trim()
    }

    if ([string]::IsNullOrWhiteSpace($ver) -or [string]::IsNullOrWhiteSpace($bld)) {
        Write-Error "Failed to parse JVM_VERSION or JVM_BUILD from '$jvmBat'."
        exit 1
    }

    return [PSCustomObject]@{
        Version = $ver
        Build   = $bld
    }
}

$currentMeta = Get-CurrentMetadata
$currentVersion = $currentMeta.Version
$currentBuild = $currentMeta.Build

# 2. Helper to compute next semver version
function Get-NextVersion {
    param (
        [string]$Current,
        [string]$BumpType
    )
    if ($Current -match '^(\d+)\.(\d+)\.(\d+)') {
        [int]$major = $matches[1]
        [int]$minor = $matches[2]
        [int]$patch = $matches[3]

        switch ($BumpType.ToLowerInvariant()) {
            'major' { return "$($major + 1).0.0" }
            'minor' { return "$major.$($minor + 1).0" }
            'patch' { return "$major.$minor.$($patch + 1)" }
        }
    }
    return $null
}

# 3. Helper to auto-calculate next build identifier (strictly monotonically increasing sequence)
function Get-NextBuild {
    param (
        [string]$CurrentBuild
    )
    $todayDateStr = Get-Date -Format "yyyyMMdd"
    if ($CurrentBuild -match '^(\d{8})\.(\d+)$') {
        [int]$prevSeq = $matches[2]
        # Build sequence number can NEVER go down; strictly increment
        $nextSeq = $prevSeq + 1
        return "$todayDateStr.$nextSeq"
    }

    Write-Error "Invalid JVM_BUILD format: '$CurrentBuild'. Expected 'yyyyMMdd.NNN' (e.g. 20260916.111). Refusing to guess or reset sequence."
    exit 1
}

$calculatedBuild = Get-NextBuild $currentBuild

# 4. Interactive version selection if not passed
if ([string]::IsNullOrWhiteSpace($Version)) {
    $nextPatch = Get-NextVersion $currentVersion "patch"
    $nextMinor = Get-NextVersion $currentVersion "minor"
    $nextMajor = Get-NextVersion $currentVersion "major"

    Write-Host ""
    Write-Host "Current Detected Version: " -NoNewline -ForegroundColor Yellow
    Write-Host "v$currentVersion (Build $currentBuild)" -ForegroundColor White
    Write-Host "  [1] Patch bump   -> " -NoNewline -ForegroundColor Cyan
    Write-Host "v$nextPatch" -ForegroundColor Green
    Write-Host "  [2] Minor bump   -> " -NoNewline -ForegroundColor Cyan
    Write-Host "v$nextMinor" -ForegroundColor Green
    Write-Host "  [3] Major bump   -> " -NoNewline -ForegroundColor Cyan
    Write-Host "v$nextMajor" -ForegroundColor Green
    Write-Host "  [4] Custom version" -ForegroundColor Cyan
    Write-Host ""

    $choice = Read-Host "Select option [1-4] or enter version (default: 1 [v$nextPatch])"
    switch ($choice) {
        '2' { $Version = $nextMinor }
        '3' { $Version = $nextMajor }
        '4' { $Version = Read-Host "Enter custom semantic version" }
        default {
            if ($choice -match '^\d+\.\d+\.\d+') {
                $Version = $choice
            } else {
                $Version = $nextPatch
            }
        }
    }
} elseif ($Version.ToLowerInvariant() -in @('patch', 'minor', 'major')) {
    $computed = Get-NextVersion $currentVersion $Version
    if ($computed) {
        $Version = $computed
    }
}

# Sanitize version string (strip leading 'v')
$cleanVersion = $Version.Trim().TrimStart('v').TrimStart('V')
if ($cleanVersion -notmatch '^\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?$') {
    Write-Error "Invalid semantic version format: '$Version'. Expected format: X.Y.Z (e.g. 1.0.2)"
    exit 1
}

# 4b. Ask before bumping build (never automatic unless -Build parameter was explicitly passed)
if ([string]::IsNullOrWhiteSpace($Build)) {
    if ([Environment]::UserInteractive -and -not $Force) {
        Write-Host ""
        Write-Host "Current Build: " -NoNewline -ForegroundColor Yellow
        Write-Host "$currentBuild" -ForegroundColor White
        Write-Host "  [1] Bump build   -> " -NoNewline -ForegroundColor Cyan
        Write-Host "$calculatedBuild " -NoNewline -ForegroundColor Green
        Write-Host "(next monotonic build)" -ForegroundColor DarkGray
        Write-Host "  [2] Keep build   -> " -NoNewline -ForegroundColor Cyan
        Write-Host "$currentBuild " -NoNewline -ForegroundColor White
        Write-Host "(no build bump)" -ForegroundColor DarkGray
        Write-Host "  [3] Custom build -> " -NoNewline -ForegroundColor Cyan
        Write-Host "Enter manual build string" -ForegroundColor DarkGray
        Write-Host ""
        $buildChoice = Read-Host "Select build option [1-3] (default: 1 [bump to $calculatedBuild])"
        switch ($buildChoice) {
            '2' { $Build = $currentBuild }
            '3' { $Build = (Read-Host "Enter custom build identifier (e.g. $calculatedBuild)").Trim() }
            default { $Build = $calculatedBuild }
        }
    } else {
        $Build = $calculatedBuild
    }
} else {
    $Build = $Build.Trim()
}

if ($Build -notmatch '^\d{8}\.\d+$') {
    Write-Error "Invalid build identifier '$Build'. Build must strictly follow the 'yyyyMMdd.NNN' format (e.g. '20260918.113')."
    exit 1
}
$todayDate = Get-Date -Format "yyyy-MM-dd"

# 5. Version & Build Downgrade & Redundancy Safety
# 5a. Build sequence check (build sequence can NEVER go down)
if ($Build -match '^\d{8}\.(\d+)$' -and $currentBuild -match '^\d{8}\.(\d+)$') {
    [int]$currBuildSeq = $matches[1]
    $null = $Build -match '^\d{8}\.(\d+)$'
    [int]$newBuildSeq = $matches[1]

    if ($newBuildSeq -lt $currBuildSeq -and -not $Force) {
        Write-Error "Build downgrade rejected: Target build '$Build' (seq $newBuildSeq) is less than current build '$currentBuild' (seq $currBuildSeq). Build sequence numbers must never decrease. Use -Force to bypass."
        exit 1
    }
}

# 5b. Semantic version check
if ($cleanVersion -eq $currentVersion -and -not $Force) {
    Write-Host "${cYellow}[WARN]$cReset Target version '$cleanVersion' is identical to the current repository version."
    if ([Environment]::UserInteractive) {
        $proceedSame = Read-Host "Are you sure you want to re-apply the current version? [y/N]"
        if ($proceedSame -notmatch '^(y|yes)$') {
            Write-Host "${cRed}[ABORT]$cReset Aborted by user."
            exit 0
        }
    }
} else {
    try {
        $currParts = $currentVersion -split '[-+]' | Select-Object -First 1
        $currV = [version]$currParts
        $cleanParts = $cleanVersion -split '[-+]' | Select-Object -First 1
        $newV = [version]$cleanParts
        if ($newV -lt $currV -and -not $Force) {
            Write-Host "${cYellow}[WARN]$cReset Target version '$cleanVersion' is lower than current version '$currentVersion' (Downgrade detected)."
            if ([Environment]::UserInteractive) {
                $proceedDown = Read-Host "Are you sure you want to proceed with a version downgrade? [y/N]"
                if ($proceedDown -notmatch '^(y|yes)$') {
                    Write-Host "${cRed}[ABORT]$cReset Aborted by user."
                    exit 0
                }
            } else {
                Write-Error "Downgrade detected from '$currentVersion' to '$cleanVersion'. Use -Force to bypass."
                exit 1
            }
        }
    } catch { }
}

# Helper to extract GitHub compare URL
$gitRemoteUrl = $null
try {
    $remoteOut = (Invoke-Git -Directory $RepoRoot -GitArgs @("config", "--get", "remote.origin.url") -CaptureOutput -IgnoreError).Trim()
    if ($remoteOut -match 'github\.com[:/]([^/]+)/([^/.]+?)(\.git)?$') {
        $gitRemoteUrl = "https://github.com/$($matches[1])/$($matches[2])"
    }
} catch { }

# Compare link markdown
$compareLink = $null
if ($gitRemoteUrl -and $currentVersion -ne $cleanVersion) {
    $compareLink = "[$currentVersion...$cleanVersion]($gitRemoteUrl/compare/v$currentVersion...v$cleanVersion)"
}

# 5c. Inspect CHANGELOG.md for existing entry for target version, or auto-generate from Git history
$changelogFile = Join-Path $RepoRoot "docs\CHANGELOG.md"
$detectedChangelogBody = $null
$changelogSource = "New template"

if (Test-Path $changelogFile) {
    $clRaw = [System.IO.File]::ReadAllText($changelogFile, $Utf8NoBom)
    # Check if a section for ## [$cleanVersion] or ## [v$cleanVersion] already exists and captures everything up to the next older version header
    $escapedVer = [regex]::Escape($cleanVersion)
    $sectionPattern = "(?ms)^##\s+\[v?${escapedVer}\][^\r\n]*\r?\n(.*?)(?=(^##\s+\[)|\z)"
    $m = [regex]::Match($clRaw, $sectionPattern)
    if ($m.Success) {
        $detectedChangelogBody = $m.Groups[1].Value.Trim()
        $changelogSource = "Found existing in docs\CHANGELOG.md"
    }
}

# If no entry already in CHANGELOG.md, attempt to generate release notes from git commits since last tag
if ([string]::IsNullOrWhiteSpace($detectedChangelogBody)) {
    try {
        $lastTag = (Invoke-Git -Directory $RepoRoot -GitArgs @("describe", "--tags", "--abbrev=0") -CaptureOutput -IgnoreError).Trim()
        $logRange = if ($lastTag) { "$lastTag..HEAD" } else { "-n 20" }
        $gitLogs = (Invoke-Git -Directory $RepoRoot -GitArgs @("log", $logRange, "--pretty=format:%s") -CaptureOutput -IgnoreError).Trim() -split "\r?\n"

        if ($gitLogs.Count -gt 0 -and $gitLogs[0] -ne "") {
            $feats = [System.Collections.Generic.List[string]]::new()
            $fixes = [System.Collections.Generic.List[string]]::new()
            $packaging = [System.Collections.Generic.List[string]]::new()
            $cli = [System.Collections.Generic.List[string]]::new()
            $core = [System.Collections.Generic.List[string]]::new()
            $fixes = [System.Collections.Generic.List[string]]::new()
            $docs = [System.Collections.Generic.List[string]]::new()
            $others = [System.Collections.Generic.List[string]]::new()

            foreach ($line in $gitLogs) {
                $trimmed = $line.Trim()
                if (-not $trimmed) { continue }
                if ($trimmed -match '^([a-zA-Z]+)(\((.*?)\))?:\s*(.+)$') {
                    $type = $matches[1].ToLowerInvariant()
                    $rawScope = if ($matches[3]) { $matches[3].Trim() } else { "" }
                    $subject = $matches[4].Trim()

                    # Format scope with title casing
                    $scopeTitle = if ($rawScope) {
                        (Get-Culture).TextInfo.ToTitleCase($rawScope.ToLowerInvariant())
                    } else {
                        ""
                    }
                    $bullet = if ($scopeTitle) { "- **$scopeTitle**: $subject" } else { "- $subject" }

                    if ($rawScope -in @('msi', 'choco', 'winget', 'scoop', 'dist', 'release', 'pkg', 'packages') -or $type -in @('build', 'ci')) {
                        $packaging.Add($bullet)
                    } elseif ($rawScope -in @('cli', 'cmd', 'channel', 'update', 'args', 'flag', 'flags')) {
                        $cli.Add($bullet)
                    } elseif ($rawScope -in @('engine', 'core', 'batch', 'ps', 'powershell', 'crypto', 'hash')) {
                        $core.Add($bullet)
                    } elseif ($type -eq 'fix') {
                        $fixes.Add($bullet)
                    } elseif ($type -eq 'docs') {
                        $docs.Add($bullet)
                    } elseif ($type -eq 'feat') {
                        $core.Add($bullet)
                    } else {
                        $others.Add($bullet)
                    }
                } else {
                    $others.Add("- $trimmed")
                }
            }

            $sb = [System.Text.StringBuilder]::new()
            if ($packaging.Count -gt 0) {
                [void]$sb.AppendLine("### Packaging & Distribution")
                foreach ($p in $packaging) { [void]$sb.AppendLine($p) }
                [void]$sb.AppendLine("")
            }
            if ($cli.Count -gt 0) {
                [void]$sb.AppendLine("### CLI & Update Channels")
                foreach ($c in $cli) { [void]$sb.AppendLine($c) }
                [void]$sb.AppendLine("")
            }
            if ($core.Count -gt 0) {
                [void]$sb.AppendLine("### Core Engine & PowerShell 7 Resilience")
                foreach ($co in $core) { [void]$sb.AppendLine($co) }
                [void]$sb.AppendLine("")
            }
            if ($fixes.Count -gt 0) {
                [void]$sb.AppendLine("### Bug Fixes & System Stability")
                foreach ($f in $fixes) { [void]$sb.AppendLine($f) }
                [void]$sb.AppendLine("")
            }
            if ($docs.Count -gt 0) {
                [void]$sb.AppendLine("### Documentation")
                foreach ($d in $docs) { [void]$sb.AppendLine($d) }
                [void]$sb.AppendLine("")
            }
            if ($others.Count -gt 0) {
                [void]$sb.AppendLine("### Other Changes")
                foreach ($o in $others) { [void]$sb.AppendLine($o) }
                [void]$sb.AppendLine("")
            }

            $detectedChangelogBody = $sb.ToString().Trim()
            $changelogSource = "Auto-generated from Git history ($logRange)"
        }
    } catch { }
}

# Helper to render changelog preview in a clean 68-char Unicode box with word-wrapping
function Show-ChangelogPreview {
    param(
        [string]$VersionStr,
        [string]$BodyStr,
        [string]$Source,
        [string]$DiffUrl
    )
    $innerLength = 68
    Write-Host ""
    $badge = " CHANGELOG: v$VersionStr "
    $padHeader = [math]::Max(0, $innerLength - $badge.Length)
    Write-Host "$cCyan┌$cBold$badge$cReset$cCyan$('─' * $padHeader)┐$cReset"
    
    # Source row
    $srcText = " Source: $Source"
    $padSrc = [math]::Max(0, $innerLength - $srcText.Length)
    Write-Host "$cCyan│$cReset$cGray$srcText$(' ' * $padSrc)$cReset$cCyan│$cReset"

    # Compare URL row (clean display with full URL wrapping without truncating)
    if ($DiffUrl) {
        $compareLabel = " Compare: v$currentVersion...v$cleanVersion"
        $padLabel = [math]::Max(0, $innerLength - $compareLabel.Length)
        Write-Host "$cCyan│$cReset$cBrightCyan$compareLabel$(' ' * $padLabel)$cReset$cCyan│$cReset"
        
        $rawUrl = if ($DiffUrl -match '\((https://[^\)]+)\)') { $matches[1] } else { $DiffUrl }
        $indentUrl = "   $rawUrl"
        $maxUrlWidth = $innerLength - 2

        # Split URL cleanly into chunks of max $maxUrlWidth characters
        $urlRemainder = $indentUrl
        $isFirstChunk = $true
        while ($urlRemainder.Length -gt 0) {
            $chunkLen = [math]::Min($maxUrlWidth, $urlRemainder.Length)
            $chunk = $urlRemainder.Substring(0, $chunkLen)
            $urlRemainder = $urlRemainder.Substring($chunkLen)
            if (-not [string]::IsNullOrWhiteSpace($urlRemainder)) {
                $urlRemainder = "     " + $urlRemainder
            }
            $padChunk = [math]::Max(0, $innerLength - $chunk.Length)
            if ($isFirstChunk) {
                Write-Host "$cCyan│$cReset$cGray$chunk$(' ' * $padChunk)$cReset$cCyan│$cReset"
                $isFirstChunk = $false
            } else {
                Write-Host "$cCyan│$cReset$cBrightCyan$chunk$(' ' * $padChunk)$cReset$cCyan│$cReset"
            }
        }
    }

    Write-Host "$cCyan├$('─' * $innerLength)┤$cReset"

    if ([string]::IsNullOrWhiteSpace($BodyStr)) {
        $emptyText = " (No notes detected - empty template will be generated)"
        $padEmpty = [math]::Max(0, $innerLength - $emptyText.Length)
        Write-Host "$cCyan│$cReset$cGray$emptyText$(' ' * $padEmpty)$cReset$cCyan│$cReset"
    } else {
        $rawLines = $BodyStr -split "\r?\n"
        $maxBoxLines = 24
        $boxLineCount = 0

        foreach ($rawL in $rawLines) {
            if ($boxLineCount -ge $maxBoxLines) {
                $moreText = " ... more lines truncated (press 'c' in post-bump menu to view)"
                $padMore = [math]::Max(0, $innerLength - $moreText.Length)
                Write-Host "$cCyan│$cReset$cYellow$moreText$(' ' * $padMore)$cReset$cCyan│$cReset"
                break
            }

            $trimmed = $rawL.TrimEnd()
            if ([string]::IsNullOrWhiteSpace($trimmed)) {
                $pad = $innerLength
                Write-Host "$cCyan│$cReset$(' ' * $pad)$cCyan│$cReset"
                $boxLineCount++
                continue
            }

            # Determine bullet indentation
            $isBullet = $trimmed -match '^(\s*-\s+)(.*)$'
            $indent = if ($isBullet) { "   " } else { " " }
            $linePrefix = " "

            # Word-wrap long lines to fit within $innerLength - 2 characters
            $maxTextWidth = $innerLength - 2
            $words = $trimmed -split '\s+'
            $currentLine = ""

            foreach ($word in $words) {
                $candidate = if ($currentLine) { "$currentLine $word" } else { "$linePrefix$word" }
                if ($candidate.Length -le $maxTextWidth) {
                    $currentLine = $candidate
                } else {
                    if ($currentLine) {
                        $pad = [math]::Max(0, $innerLength - $currentLine.Length)
                        Write-Host "$cCyan│$cReset$currentLine$(' ' * $pad)$cCyan│$cReset"
                        $boxLineCount++
                        if ($boxLineCount -ge $maxBoxLines) { break }
                    }
                    $currentLine = "$indent$word"
                }
            }

            if ($boxLineCount -lt $maxBoxLines -and $currentLine) {
                $pad = [math]::Max(0, $innerLength - $currentLine.Length)
                Write-Host "$cCyan│$cReset$currentLine$(' ' * $pad)$cCyan│$cReset"
                $boxLineCount++
            }
        }
    }
    Write-Host "$cCyan└$('─' * $innerLength)┘$cReset"
}

# Display changelog preview
Show-ChangelogPreview -VersionStr $cleanVersion -BodyStr $detectedChangelogBody -Source $changelogSource -DiffUrl $compareLink

# 6. Resolve Active Branch and check for detached HEAD
$activeBranch = (Invoke-Git -Directory $RepoRoot -GitArgs @("rev-parse", "--abbrev-ref", "HEAD") -CaptureOutput).Trim()
if ($activeBranch -eq "HEAD") {
    Write-Error "Repository is in a detached HEAD state. Please switch to a release branch before running bump."
    exit 1
}

if ($activeBranch -ne "main" -and -not $Force) {
    Write-Host "${cYellow}[WARN]$cReset Current active branch is '$activeBranch', not 'main'."
    if ([Environment]::UserInteractive) {
        $proceedBranch = Read-Host "Are you sure you want to release from '$activeBranch'? [y/N]"
        if ($proceedBranch -notmatch '^(y|yes)$') {
            Write-Host "${cRed}[ABORT]$cReset Aborted by user."
            exit 0
        }
    }
}

# 7. Pre-flight Git Tag Collision Check (v$cleanVersion and $cleanVersion)
$localTagExists = (Invoke-Git -Directory $RepoRoot -GitArgs @("tag", "-l", "v$cleanVersion", "$cleanVersion") -CaptureOutput).Trim()
if (-not [string]::IsNullOrWhiteSpace($localTagExists)) {
    Write-Error "Tag collision: Local tag '$localTagExists' already exists in $RepoRoot. Release aborted."
    exit 1
}

# Verify remote repository accessibility and check tags / upstream sync on origin
$remotes = (Invoke-Git -Directory $RepoRoot -GitArgs @("remote") -CaptureOutput -IgnoreError).Trim()
if ($remotes -match '(?m)^origin$') {
    try {
        $remoteTagCheck = Invoke-Git -Directory $RepoRoot -GitArgs @("ls-remote", "--tags", "origin", "refs/tags/v$cleanVersion", "refs/tags/$cleanVersion") -CaptureOutput
        if (-not [string]::IsNullOrWhiteSpace($remoteTagCheck)) {
            Write-Error "Tag collision: Remote tag 'v$cleanVersion' already exists on origin. Release aborted."
            exit 1
        }

        # Upstream Sync Check (check if local branch is behind origin)
        Invoke-Git -Directory $RepoRoot -GitArgs @("fetch", "origin", "--", $activeBranch, "--quiet") | Out-Null
        $behindCount = (Invoke-Git -Directory $RepoRoot -GitArgs @("rev-list", "HEAD..origin/$activeBranch", "--count") -CaptureOutput).Trim()
        if ($behindCount -and [int]$behindCount -gt 0 -and -not $Force) {
            Write-Error "Local branch '$activeBranch' is $behindCount commit(s) behind origin/$activeBranch. Please run 'git pull' before releasing (use -Force to bypass)."
            exit 1
        }
    } catch {
        Write-Host "  ${cGray}[NOTE] Could not query remote origin (offline or no access). Continuing with local checks.$cReset"
    }
}

# 8. Dirty Working Tree Protection
$uncommitted = (Invoke-Git -Directory $RepoRoot -GitArgs @("status", "--porcelain") -CaptureOutput).Trim()
if (-not [string]::IsNullOrWhiteSpace($uncommitted) -and -not $DryRun -and -not $Force) {
    Write-Host ""
    Write-Host "${cYellow}[WARN] Uncommitted changes detected in working tree before release:$cReset"
    $uncommitted -split "`r?`n" | ForEach-Object { Write-Host "    $cYellow$_$cReset" }
    Write-Host ""
    if ([Environment]::UserInteractive) {
        $confirmDirty = Read-Host "Continue and bundle these changes into the release? [y/N]"
        if ($confirmDirty -notmatch '^(y|yes)$') {
            Write-Host "${cRed}[ABORT]$cReset Aborted by user to protect uncommitted work."
            exit 0
        }
    } else {
        Write-Error "Working directory is dirty. Use -Force to bypass."
        exit 1
    }
}

# 9. Cryptographic Signing Verification (Mandatory for official releases)
$signKey = (Invoke-Git -Directory $RepoRoot -GitArgs @("config", "--get", "user.signingkey") -CaptureOutput -IgnoreError).Trim()
$gpgFormat = (Invoke-Git -Directory $RepoRoot -GitArgs @("config", "--get", "gpg.format") -CaptureOutput -IgnoreError).Trim()

if (-not $NoSign) {
    if ([string]::IsNullOrWhiteSpace($signKey)) {
        Write-Error "Signing key required: 'user.signingkey' is not configured in git. All commits and release tags must be signed. (Use -NoSign only for unsigned testing)."
        exit 1
    }

    # Verify public key file existence if path is specified
    if ($signKey -match '[\\/]' -and -not (Test-Path $signKey)) {
        Write-Error "Signing key file not found on disk at: '$signKey'."
        exit 1
    }

    $signingKeyDisplay = Split-Path -Leaf $signKey
    $signingConfigured = $true
} else {
    Write-Host "${cYellow}[WARN] -NoSign switch active. Commits and tags will NOT be signed.$cReset"
    $signingKeyDisplay = "Unsigned (-NoSign)"
    $signingConfigured = $false
}

# Scoop bucket presence check
$externalBucketManifest = Join-Path (Split-Path -Parent $RepoRoot) "scoop-bucket\bucket\jvm.json"
$bucketPresent = Test-Path $externalBucketManifest
$bucketDisplay = if ($NoBucketSync) { "$cGray Disabled (-NoBucketSync) $cReset" } elseif ($bucketPresent) { "$cGreen Ready (..\scoop-bucket) $cReset" } else { "$cGray Not Found (Skipped) $cReset" }

# 10. Display Pre-Flight Table UI
Write-BoxHeader "DiamTek JVM Release Coordinator"

$tableData = [ordered]@{
    "Current Version" = "$cGray v$currentVersion $cReset"
    "Target Version"  = "$cGreen$cBold v$cleanVersion $cReset"
    "Current Build"   = "$cGray $currentBuild $cReset"
    "Target Build"    = "$cYellow$cBold $Build $cReset"
    "Active Branch"   = "$cCyan $activeBranch $cReset"
    "GPG/SSH Signing" = if ($NoSign) { "$cGray Disabled (-NoSign) $cReset" } elseif ($signingConfigured) { "$cGreen Active ($signingKeyDisplay) $cReset" } else { "$cGray Default $cReset" }
    "External Scoop"  = $bucketDisplay
    "Execution Mode"  = if ($DryRun) { "$cYellow$cBold Dry Run (Preview Only) $cReset" } else { "$cGreen$cBold Live Modification $cReset" }
}
Write-PropertyTable $tableData

# Pre-flight modification prompt
if (-not $DryRun -and [Environment]::UserInteractive -and -not $Force) {
    $confirm = Read-Host "Proceed with bumping all manifests to v$cleanVersion ($Build)? [Y/n]"
    if ($confirm -match '^(n|no)$') {
        Write-Host "${cRed}[ABORT]$cReset Aborted by user."
        exit 0
    }
}

$filesUpdated = 0

function Update-FileContent {
    param (
        [string]$Path,
        [scriptblock]$Transform,
        [string]$StepName
    )

    $fullPath = if ([System.IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $RepoRoot $Path }
    $displayPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        $parentDir = Split-Path -Parent $RepoRoot
        if ($Path.StartsWith($parentDir, [System.StringComparison]::OrdinalIgnoreCase)) {
            ".." + $Path.Substring($parentDir.Length)
        } else {
            $Path
        }
    } else {
        $Path
    }

    if (-not (Test-Path $fullPath)) {
        Write-Host "  ${cGray}[ SKIP ]$cReset $displayPath ($StepName - not found)"
        return
    }

    $rawContent = [System.IO.File]::ReadAllText($fullPath, $Utf8NoBom)
    $newContent = & $Transform $rawContent

    if ($rawContent -ne $newContent) {
        if (-not $DryRun) {
            [System.IO.File]::WriteAllText($fullPath, $newContent, $Utf8NoBom)
        }
        Write-Host "  ${cGreen}[  OK  ]$cReset $displayPath $cGray($StepName)$cReset"
        $script:filesUpdated++
    } else {
        Write-Host "  ${cGray}[  --  ]$cReset $displayPath $cGray(up to date)$cReset"
    }
}

Write-Host "${cCyan}${cBold}Applying Manifest Updates:${cReset}"

# --- 1. Core Batch Engine (jvm.bat) ---
Update-FileContent "jvm.bat" {
    param($content)
    $c = [regex]::Replace($content, '(?m)^(set\s+("?)JVM_VERSION=)[^"\r\n]*(\2)', "`${1}$cleanVersion`${3}")
    $c = [regex]::Replace($c, '(?m)^(set\s+("?)JVM_BUILD=)[^"\r\n]*(\2)', "`${1}$Build`${3}")
    [regex]::Replace($c, '(\$remVerStr\s*=\s*'')[^'']*('')', "`${1}$cleanVersion`${2}")
} -StepName "Core Engine"

# --- 1b. Installer Script (install.ps1) ---
Update-FileContent "install.ps1" {
    param($content)
    [regex]::Replace($content, '(\$displayVer\s*=\s*")[^"]*(")', "`${1}$cleanVersion`${2}")
} -StepName "Installer Script"

# --- 2. Chocolatey Manifest & Scripts ---
Update-FileContent "packages\choco\jvm.nuspec" {
    param($content)
    [regex]::Replace($content, '(<version>)[^<]*(</version>)', "`${1}$cleanVersion`${2}")
} -StepName "Chocolatey Spec"

Update-FileContent "packages\choco\build-choco.ps1" {
    param($content)
    [regex]::Replace($content, '(\$Version\s*=\s*")[^"]*(")', "`${1}$cleanVersion`${2}")
} -StepName "Chocolatey Build"

Update-FileContent "packages\choco\tools\chocolateyInstall.ps1" {
    param($content)
    $res = [regex]::Replace($content, "(?m)^(\`$packageVersion\s*=\s*')[^']*(')", "`${1}$cleanVersion`${2}")
    $localMsiX64 = Join-Path $RepoRoot "packages\msi\jvm-windows-$cleanVersion-x64.msi"
    if (Test-Path $localMsiX64) {
        $localHash = (Get-FileHash -Path $localMsiX64 -Algorithm SHA256).Hash.ToUpper()
        $res = [regex]::Replace($res, "(?m)^(\`$checksum64\s*=\s*')[^']*(')", "`${1}$localHash`${2}")
    }
    $res
} -StepName "Chocolatey Install"

Update-FileContent "packages\choco\tools\chocolateyUninstall.ps1" {
    param($content)
    [regex]::Replace($content, '(?<=Java-Version-Manager-Windows/v)\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?', $cleanVersion)
} -StepName "Chocolatey Uninstall"

# --- 3. MSI WiX Build, Test & Source Manifests ---
Update-FileContent "packages\msi\build-msi.ps1" {
    param($content)
    [regex]::Replace($content, '(\$Version\s*=\s*")[^"]*(")', "`${1}$cleanVersion`${2}")
} -StepName "MSI Build"

Update-FileContent "packages\msi\test-msi.ps1" {
    param($content)
    [regex]::Replace($content, '(\$expectedVersion\s*=\s*")[^"]*(")', "`${1}$cleanVersion`${2}")
} -StepName "MSI Test"

# WiX product version strictly permits numeric major.minor.build[.revision]
$msiVersion = if ($cleanVersion -match '^(\d+\.\d+\.\d+)') { $matches[1] } else { $cleanVersion }

$wixTransform = {
    param($content)
    $c = [regex]::Replace($content, '(?i)(Version=")\d+\.\d+\.\d+(\.\d+)?(")', "`${1}$msiVersion`${3}")
    [regex]::Replace($c, '(?i)(<\?define\s+(?:ProductVersion|Version)\s*=\s*")[^"]*(")', "`${1}$msiVersion`${2}")
}

if (Test-Path (Join-Path $RepoRoot "packages\msi\Product.wxs")) {
    Update-FileContent "packages\msi\Product.wxs" $wixTransform -StepName "WiX Product XML"
}
if (Test-Path (Join-Path $RepoRoot "packages\msi\jvm.wxs")) {
    Update-FileContent "packages\msi\jvm.wxs" $wixTransform -StepName "WiX Manifest XML"
}

# --- 4. Scoop Package Manifest ---
Update-FileContent "packages\scoop\jvm.json" {
    param($content)
    $c = [regex]::Replace($content, '("version":\s*")[^"]*(")', "`${1}$cleanVersion`${2}")
    $c = [regex]::Replace($c, '(?<=releases/download/v)\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?', $cleanVersion)
    [regex]::Replace($c, '(?<=jvm-windows-)\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?', $cleanVersion)
} -StepName "Scoop Internal"

# --- 5. Winget Package Manifests ---
Update-FileContent "packages\winget\DiamTek.JVM.yaml" {
    param($content)
    [regex]::Replace($content, '(?m)^(PackageVersion:\s*)\S+', "`${1}$cleanVersion")
} -StepName "Winget Version"

Update-FileContent "packages\winget\DiamTek.JVM.locale.en-US.yaml" {
    param($content)
    $c = [regex]::Replace($content, '(?m)^(PackageVersion:\s*)\S+', "`${1}$cleanVersion")
    [regex]::Replace($c, '(?m)^(ReleaseDate:\s*)\S+', "`${1}$todayDate")
} -StepName "Winget Locale"

Update-FileContent "packages\winget\DiamTek.JVM.installer.yaml" {
    param($content)
    $c = [regex]::Replace($content, '(?m)^(PackageVersion:\s*)\S+', "`${1}$cleanVersion")
    $c = [regex]::Replace($c, '(?m)^(ReleaseDate:\s*)\S+', "`${1}$todayDate")
    $c = [regex]::Replace($c, '(?<=releases/download/v)\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?', $cleanVersion)
    [regex]::Replace($c, '(?<=jvm-windows-)\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?', $cleanVersion)
} -StepName "Winget Installer"

# --- 6. GitHub Release Workflow ---
Update-FileContent ".github\workflows\release.yml" {
    param($content)
    [regex]::Replace($content, '(default:\s*[''"])\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?([''"])', "`${1}$cleanVersion`${3}")
} -StepName "Release Workflow"

# --- 7. CHANGELOG.md Entry with Chronological Placement & Comparison Link ---
Update-FileContent "docs\CHANGELOG.md" {
    param($content)
    if ($content -notmatch [regex]::Escape("## [$cleanVersion]")) {
        $isCrlf = $content.Contains("`r`n")
        $nl = if ($isCrlf) { "`r`n" } else { "`n" }

        # Build release content using auto-detected or auto-generated release notes
        $entryContent = if (-not [string]::IsNullOrWhiteSpace($detectedChangelogBody)) {
            $detectedChangelogBody
        } else {
            @"
<!-- Summarize highlights here -->

### Packaging & Distribution
- 

### CLI & Update Channels
- 

### Core Engine
- 

### Bug Fixes & System Stability
- 
"@
        }

        # Build full release section matching official GitHub release format:
        # ## [version] - date
        # (intro highlights)
        # (categories)
        # **Full Changelog**: https://github.com/.../compare/v0.0.0...v0.0.0
        $compareFooter = if ($gitRemoteUrl -and $currentVersion -ne $cleanVersion) {
            "${nl}**Full Changelog**: $gitRemoteUrl/compare/v$currentVersion...v$cleanVersion"
        } else {
            ""
        }

        $template = @"
## [$cleanVersion] - $todayDate

$entryContent$compareFooter

"@
        $template = [regex]::Replace($template, "\r?\n", $nl)

        # Strategy 1: Preceding first numeric release header (preserves [Unreleased] section at top)
        $firstNumericHeader = [regex]::Match($content, '(?m)^##\s+\[\d+')
        if ($firstNumericHeader.Success) {
            return $content.Insert($firstNumericHeader.Index, $template)
        }

        # Strategy 2: If [Unreleased] exists without numeric releases, insert below [Unreleased] section
        $unreleasedMatch = [regex]::Match($content, '(?ms)^##\s+\[Unreleased\].*?(?=(^##\s+\[)|\z)')
        if ($unreleasedMatch.Success) {
            $insertPos = $unreleasedMatch.Index + $unreleasedMatch.Length
            return $content.Insert($insertPos, "$nl$template")
        }

        # Strategy 3: Preceding any other release header
        $anyHeader = [regex]::Match($content, '(?m)^##\s+\[')
        if ($anyHeader.Success) {
            return $content.Insert($anyHeader.Index, $template)
        }

        # Strategy 4: Standard semantic versioning anchor
        $anchor = "Semantic Versioning.$nl$nl"
        $idx = $content.IndexOf($anchor)
        if ($idx -ge 0) {
            $insertPos = $idx + $anchor.Length
            return $content.Insert($insertPos, $template)
        }

        # Strategy 5: Append if no markers found
        Write-Host "  ${cYellow}[WARN]$cReset Could not find anchor in docs\CHANGELOG.md; appending entry."
        return "$content$nl$template"
    } else {
        # Entry already exists in CHANGELOG.md; ensure Full Changelog compare link is present
        if ($gitRemoteUrl -and $currentVersion -ne $cleanVersion) {
            $fullCompareUrl = "$gitRemoteUrl/compare/v$currentVersion...v$cleanVersion"
            if ($content -notmatch [regex]::Escape($fullCompareUrl)) {
                $isCrlf = $content.Contains("`r`n")
                $nl = if ($isCrlf) { "`r`n" } else { "`n" }
                # Find end of this version's block (right before next ## [ or end of file)
                $escapedVer = [regex]::Escape($cleanVersion)
                $secMatch = [regex]::Match($content, "(?ms)^##\s+\[v?${escapedVer}\][^\r\n]*\r?\n(.*?)(?=(^##\s+\[)|\z)")
                if ($secMatch.Success) {
                    $insertPoint = $secMatch.Groups[1].Index + $secMatch.Groups[1].Length
                    $footerToInsert = "${nl}${nl}**Full Changelog**: $fullCompareUrl"
                    return $content.Insert($insertPoint, $footerToInsert)
                }
            }
        }
        return $content
    }
} -StepName "Changelog Entry"

# --- 8. README.md Version History ---
Update-FileContent "README.md" {
    param($content)
    $c = [regex]::Replace($content, '(?m)^\*\s+\*\*v\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?\s+\(Latest\):\*\*', {
        param($m)
        $m.Value -replace '\s+\(Latest\)', ''
    })
    $targetTag = "* **v$cleanVersion"
    if ($c -notmatch [regex]::Escape($targetTag)) {
        $vhAnchor = "## 📜 Version History`r`n`r`n"
        $isCrlf = $c.Contains("`r`n")
        if (-not $isCrlf) { $vhAnchor = "## 📜 Version History`n`n" }
        $idx = $c.IndexOf($vhAnchor)
        if ($idx -ge 0) {
            $summaryLine = if ($detectedChangelogBody) {
                ($detectedChangelogBody -split "`r?`n" | Where-Object { $_.Trim() -and $_ -notmatch '^#' } | Select-Object -First 1)
            } else {
                "Maintenance, stability, and distribution update."
            }
            if (-not $summaryLine) { $summaryLine = "Maintenance, stability, and distribution update." }
            $nl = if ($isCrlf) { "`r`n" } else { "`n" }
            $newEntry = "* **v$cleanVersion (Latest):** $summaryLine$nl"
            $c = $c.Insert($idx + $vhAnchor.Length, $newEntry)
        }
    }
    return $c
} -StepName "README Version History"

# --- 9. Documentation Guides (INSTALLATION, FAQ, SECURITY) ---
Update-FileContent "docs\INSTALLATION.md" {
    param($content)
    $c = [regex]::Replace($content, 'jvm-windows-\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?-(x64|arm64|portable)', "jvm-windows-$cleanVersion-`${2}")
    [regex]::Replace($c, '(?<=jvm-windows-)\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?(?=\.nupkg)', $cleanVersion)
} -StepName "Installation Guide"

Update-FileContent "docs\FAQ.md" {
    param($content)
    [regex]::Replace($content, 'jvm-windows-\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?-(x64|arm64|portable)', "jvm-windows-$cleanVersion-`${2}")
} -StepName "FAQ Guide"

Update-FileContent "docs\SECURITY.md" {
    param($content)
    [regex]::Replace($content, 'jvm-windows-\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?-(x64|arm64|portable)', "jvm-windows-$cleanVersion-`${2}")
} -StepName "Security Guide"

Write-Host ""
if ($DryRun) {
    $dryText = "[DRY RUN COMPLETE] $filesUpdated manifest file(s) would be updated."
    $padRightDry = [math]::Max(0, 68 - $dryText.Length - 1)
    Write-Host "$cYellow$cBold╭$('─' * 68)╮$cReset"
    Write-Host "$cYellow$cBold│$cReset $dryText$(' ' * $padRightDry)$cYellow$cBold│$cReset"
    Write-Host "$cYellow$cBold╰$('─' * 68)╯$cReset"
    Write-Host ""

    if ([Environment]::UserInteractive -and -not $Force) {
        while ($true) {
            Write-Host "${cCyan}${cBold}Dry Run Verification & Testing Options:${cReset}"
            Write-Host "  ${cCyan}[W]$cReset Test Winget validation & submission workflow (w / winget)"
            Write-Host "  ${cCyan}[C]$cReset Test Chocolatey packaging & API key configuration (c / choco)"
            Write-Host "  ${cCyan}[S]$cReset Test Scoop bucket coordination (s / scoop)"
            Write-Host "  ${cCyan}[T]$cReset Run local MSI & engine test suite (t / test)"
            Write-Host "  ${cCyan}[Q]$cReset Exit Dry Run (Enter / q / exit)"
            Write-Host ""

            $dryAction = Read-Host "Select option [W, C, S, T, Q] (default: Q [exit])"
            if ([string]::IsNullOrWhiteSpace($dryAction)) { $dryAction = 'q' }

            switch ($dryAction.ToLowerInvariant()) {
                { $_ -in @('w', 'winget') } {
                    Invoke-WingetCoordinator -TargetVersion $cleanVersion -IsDryRun
                }
                { $_ -in @('c', 'choco') } {
                    Invoke-ChocoCoordinator -TargetVersion $cleanVersion -IsDryRun
                }
                { $_ -in @('s', 'scoop') } {
                    Invoke-ScoopCoordinator -TargetVersion $cleanVersion -IsDryRun
                }
                { $_ -in @('t', 'test') } {
                    Write-Host "${cYellow}[NOTE]$cReset Running the test suite performs live installation, verification, and uninstallation of the MSI package."
                    $runTest = Read-Host "Proceed with running the test suite? [y/N]"
                    if ($runTest -match '^(y|yes)$') {
                        Invoke-TestRunner
                    } else {
                        Write-Host "Test execution skipped." -ForegroundColor Yellow
                    }
                }
                { $_ -in @('q', 'quit', 'exit') } {
                    Write-Host ""
                    Write-Host "Exiting dry run." -ForegroundColor Yellow
                    exit 0
                }
                default {
                    Write-Host "Unknown option '$dryAction'. Please choose [W, C, S, T, Q]." -ForegroundColor DarkYellow
                }
            }
            Write-Host ""
        }
    } else {
        exit 0
    }
}

$succText = "[SUCCESS] Updated $filesUpdated file(s) to v$cleanVersion (Build $Build)"
$padRightSucc = [math]::Max(0, 68 - $succText.Length - 1)
Write-Host "$cGreen$cBold╭$('─' * 68)╮$cReset"
Write-Host "$cGreen$cBold│$cReset $succText$(' ' * $padRightSucc)$cGreen$cBold│$cReset"
Write-Host "$cGreen$cBold╰$('─' * 68)╯$cReset"
Write-Host ""

# Staging review & Git Release Flow
$doCommit = $Commit.IsPresent
$doPush = $Push.IsPresent

if (-not $doCommit -and [Environment]::UserInteractive) {
    while ($true) {
        Write-Host "${cCyan}${cBold}Modified Repository Working Tree:${cReset}"
        $summary = Invoke-Git -Directory $RepoRoot -GitArgs @("status", "-s") -CaptureOutput
        if ([string]::IsNullOrWhiteSpace($summary)) {
            Write-Host "  $cGray(No modified files in working tree)$cReset"
        } else {
            $summary -split "`r?`n" | ForEach-Object { Write-Host "    $cWhite$_$cReset" }
        }
        Write-Host ""

        Write-Host "  ${cCyan}[1]$cReset Stage and create $(if (-not $NoSign) { 'signed ' } else { '' })commit & tag (Enter / 1 / y)"
        Write-Host "  ${cCyan}[2]$cReset View full git diff (d / 2)"
        Write-Host "  ${cCyan}[3]$cReset Open docs\CHANGELOG.md in editor (e / c / 3)"
        Write-Host "  ${cCyan}[W]$cReset Launch Winget package coordinator (w / winget)"
        Write-Host "  ${cCyan}[C]$cReset Launch Chocolatey release manager (c / choco)"
        Write-Host "  ${cCyan}[S]$cReset Launch Scoop bucket coordinator (s / scoop)"
        Write-Host "  ${cCyan}[T]$cReset Run local MSI & engine test suite (t / test)"
        Write-Host "  ${cCyan}[R]$cReset Revert all changes (r / git restore .)"
        Write-Host "  ${cCyan}[4]$cReset Exit and keep changes (q / 4)"
        Write-Host ""

        $action = Read-Host "Select action [1-4, W, C, S, T, R] (default: 1 [commit & tag])"
        if ([string]::IsNullOrWhiteSpace($action)) { $action = '1' }

        switch ($action.ToLowerInvariant()) {
            { $_ -in @('2', 'd', 'diff') } {
                Write-Host ""
                git -C $RepoRoot diff
                Write-Host ""
            }
            { $_ -in @('3', 'e', 'c', 'changelog', 'edit') } {
                $clPath = Join-Path $RepoRoot "docs\CHANGELOG.md"
                if (Get-Command code -ErrorAction SilentlyContinue) {
                    Start-Process "code" -ArgumentList "`"$clPath`""
                } else {
                    Start-Process "notepad.exe" -ArgumentList "`"$clPath`""
                }
            }
            { $_ -in @('w', 'winget') } {
                Invoke-WingetCoordinator -TargetVersion $cleanVersion
                Write-Host ""
            }
            { $_ -in @('c', 'choco', 'chocolatey') } {
                Invoke-ChocoCoordinator -TargetVersion $cleanVersion
                Write-Host ""
            }
            { $_ -in @('s', 'scoop') } {
                Invoke-ScoopCoordinator -TargetVersion $cleanVersion
                Write-Host ""
            }
            { $_ -in @('t', 'test') } {
                Invoke-TestRunner
                Write-Host ""
            }
            { $_ -in @('r', 'revert') } {
                $confirmRev = Read-Host "Are you sure you want to discard all changes? [y/N]"
                if ($confirmRev -match '^(y|yes)$') {
                    Write-Host "Reverting changes in main repository..." -ForegroundColor Yellow
                    Invoke-Git -Directory $RepoRoot -GitArgs @("restore", ".") | Out-Null
                    Invoke-Git -Directory $RepoRoot -GitArgs @("clean", "-fd") | Out-Null

                    if ($bucketRepoRoot -and (Test-Path (Join-Path $bucketRepoRoot ".git"))) {
                        Write-Host "Reverting changes in scoop-bucket..." -ForegroundColor Yellow
                        Invoke-Git -Directory $bucketRepoRoot -GitArgs @("restore", "bucket/jvm.json") | Out-Null
                    }
                    Write-Host "${cGreen}[REVERT COMPLETE]$cReset Working trees restored to clean state."
                    exit 0
                }
            }
            { $_ -in @('1', 'y', 'yes', 'commit') } {
                $doCommit = $true
                $promptPush = Read-Host "Push commit and tag upstream to origin/$activeBranch? [y/N]"
                if ($promptPush -match '^(y|yes)$') {
                    $doPush = $true
                }
                break
            }
            { $_ -in @('4', 'q', 'quit', 'exit', 'n', 'no') } {
                Write-Host "Exiting without committing. Manifest changes are preserved on disk." -ForegroundColor Yellow
                break
            }
            default {
                Write-Host "Unknown option '$action'. Please choose [1-4, W, C, S, T, R]." -ForegroundColor DarkYellow
            }
        }
    }
}

if ($doCommit) {
    Write-Host ""
    Write-Host "${cCyan}${cBold}Executing Git Release Flow...${cReset}"

    $signArgsCommit = if ($NoSign) { @("commit", "-m") } else { @("commit", "-S", "-m") }
    $signArgsTag = if ($NoSign) { @("tag", "-a", "-m") } else { @("tag", "-s", "-m") }

    # 1. Main repo commit & tag
    Write-Host "  $cCyan→$cReset Staging updated files in $RepoRoot..." -ForegroundColor Gray
    $null = Invoke-Git -Directory $RepoRoot -GitArgs @("add", "-A")

    # Verify staged changes exist to prevent 'nothing to commit' exit code 1
    $stagedChanges = (Invoke-Git -Directory $RepoRoot -GitArgs @("diff", "--cached", "--name-only") -CaptureOutput).Trim()
    if (-not [string]::IsNullOrWhiteSpace($stagedChanges)) {
        Write-Host "  $cCyan→$cReset Creating $(if ($NoSign) { 'commit' } else { 'signed commit' })..." -ForegroundColor Gray
        $commitMessage = "chore(release): bump version to $cleanVersion"
        $null = Invoke-Git -Directory $RepoRoot -GitArgs ($signArgsCommit + @($commitMessage))
    } else {
        Write-Host "  ${cYellow}[NOTE]$cReset No staged changes detected in $RepoRoot; skipping commit creation."
    }

    Write-Host "  $cCyan→$cReset Creating $(if ($NoSign) { 'tag' } else { 'signed tag' }) v$cleanVersion..." -ForegroundColor Gray
    $originUrl = try { (Invoke-Git -Directory $RepoRoot -GitArgs @("config", "--get", "remote.origin.url") -CaptureOutput).Trim() } catch { "" }
    $repoWebUrl = "https://github.com/DiamTek/Java-Version-Manager-Windows"
    if ($originUrl -match 'github\.com[:/]([^/]+)/([^/\.]+)') {
        $repoWebUrl = "https://github.com/$($matches[1])/$($matches[2])"
    }
    $tagAnnotation = if ($compareLink) {
        "v$cleanVersion`n`nCompare: $repoWebUrl/compare/v$currentVersion...v$cleanVersion"
    } else {
        "v$cleanVersion"
    }
    $null = Invoke-Git -Directory $RepoRoot -GitArgs ($signArgsTag + @($tagAnnotation, "v$cleanVersion"))

    # 2. Targeted Push Upstream
    if ($doPush) {
        Write-Host "  $cCyan→$cReset Pushing main repository (origin $activeBranch and tag v$cleanVersion)..." -ForegroundColor Gray
        $null = Invoke-Git -Directory $RepoRoot -GitArgs @("push", "origin", "--", $activeBranch, "refs/tags/v$cleanVersion")
    }

    Write-Host ""
    Write-Host "$cGreen${cBold}[GIT FLOW COMPLETE] Version v$cleanVersion (Build $Build) released successfully.$cReset"

    # 3. Post-Release Package Manager Automation Flow (Winget, Chocolatey, Scoop)
    if ($doPush) {
        Invoke-WingetCoordinator -TargetVersion $cleanVersion
        Invoke-ChocoCoordinator -TargetVersion $cleanVersion
        Invoke-ScoopCoordinator -TargetVersion $cleanVersion
    }
} else {
    Write-Host "${cCyan}${cBold}Next steps to release manually:${cReset}"
    Write-Host "  1. Review: git diff"
    Write-Host "  2. Commit: git commit -S -m `"chore(release): bump version to $cleanVersion`""
    Write-Host "  3. Tag:    git tag -s -m `"v$cleanVersion`" v$cleanVersion"
    Write-Host "  4. Push:   git push origin $activeBranch refs/tags/v$cleanVersion"
}
Write-Host ""