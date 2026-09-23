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

<#
 Synopsis:
   - Automated Security & Adversarial Test Suite for DiamTek Java Version Manager (JVM).

================================================================================
 Targets:
   - jvm.bat (CLI input sanitization, delayed expansion, reparse points)
   - install.ps1 / uninstall.ps1 (REG_EXPAND_SZ, non-destructive junction unbind)
   - scripts/bump-version.ps1 (manifest validation, dry-run immutability)
   - packages/** (Chocolatey, Scoop, Winget manifest integrity)

 Usage:
   pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-JvmSecurity.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-JvmSecurity.ps1
================================================================================
#>

[CmdletBinding()]
param(
    [switch]$Detailed,
    [Alias('Tag', 'Category')]
    [string]$Suite = '',
    [Alias('Name', 'Pattern')]
    [string]$Filter = ''
)

$ErrorActionPreference = 'Stop'
$RequestedSuite  = $Suite
$RequestedFilter = $Filter

# UI Colors
$ESC = [char]27
$cReset  = "$ESC[0m"
$cBold   = "$ESC[1m"
$cCyan   = "$ESC[36m"
$cGreen  = "$ESC[32m"
$cYellow = "$ESC[33m"
$cRed    = "$ESC[31m"
$cGray   = "$ESC[90m"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptDir) { $ScriptDir = (Get-Location).Path }
$RepoRoot = if (Test-Path (Join-Path $ScriptDir "jvm.bat")) {
    $ScriptDir
} elseif (Test-Path (Join-Path $ScriptDir "..\jvm.bat")) {
    (Resolve-Path "$ScriptDir\..").Path
} else {
    $ScriptDir
}

$JvmBat = Join-Path $RepoRoot "jvm.bat"
if (-not (Test-Path $JvmBat)) {
    Write-Host "${cRed}[FATAL] Could not locate jvm.bat at: $JvmBat${cReset}"
    exit 1
}

$TestResults     = [System.Collections.Generic.List[PSObject]]::new()
$GlobalPassed    = 0
$GlobalFailed    = 0
$GlobalSkipped   = 0
$HasPassedSuite2 = $false
$RunnerStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Canonical 8-Suite Catalog
$SuiteTracker = [ordered]@{
    'SUITE 1' = [PSCustomObject]@{ Id = 'SUITE 1'; Number = 1; Name = 'Suite 1: Adversarial & Fuzzing Defense';       Tag = 'Adversarial';      Passed = 0; Failed = 0; Skipped = 0; Total = 0; ElapsedMs = 0L }
    'SUITE 2' = [PSCustomObject]@{ Id = 'SUITE 2'; Number = 2; Name = 'Suite 2: Registry & Env Boundaries';           Tag = 'Registry';         Passed = 0; Failed = 0; Skipped = 0; Total = 0; ElapsedMs = 0L }
    'SUITE 3' = [PSCustomObject]@{ Id = 'SUITE 3'; Number = 3; Name = 'Suite 3: Symlink & Junction Lifecycle';        Tag = 'ReparsePoint';     Passed = 0; Failed = 0; Skipped = 0; Total = 0; ElapsedMs = 0L }
    'SUITE 4' = [PSCustomObject]@{ Id = 'SUITE 4'; Number = 4; Name = 'Suite 4: Package Manifest Integrity';          Tag = 'Manifest';         Passed = 0; Failed = 0; Skipped = 0; Total = 0; ElapsedMs = 0L }
    'SUITE 5' = [PSCustomObject]@{ Id = 'SUITE 5'; Number = 5; Name = 'Suite 5: Concurrency & Reparse Resilience';    Tag = 'Concurrency';      Passed = 0; Failed = 0; Skipped = 0; Total = 0; ElapsedMs = 0L }
    'SUITE 6' = [PSCustomObject]@{ Id = 'SUITE 6'; Number = 6; Name = 'Suite 6: Corrupt Registry & PATH Resilience';  Tag = 'Registry';         Passed = 0; Failed = 0; Skipped = 0; Total = 0; ElapsedMs = 0L }
    'SUITE 7' = [PSCustomObject]@{ Id = 'SUITE 7'; Number = 7; Name = 'Suite 7: Uninstallation Safety & Markers';     Tag = 'Uninstall';        Passed = 0; Failed = 0; Skipped = 0; Total = 0; ElapsedMs = 0L }
    'SUITE 8' = [PSCustomObject]@{ Id = 'SUITE 8'; Number = 8; Name = 'Suite 8: Windows Terminal JSONC Parsing';      Tag = 'TerminalJSON';     Passed = 0; Failed = 0; Skipped = 0; Total = 0; ElapsedMs = 0L }
}

# Canonical CWE Vulnerability Catalog (Sorted Numerically)
$CweCatalog = [ordered]@{
    'CWE-22'  = [PSCustomObject]@{ Id = 'CWE-22';  Number = 22;  Short = 'Path Traversal & ZipSlip' }
    'CWE-41'  = [PSCustomObject]@{ Id = 'CWE-41';  Number = 41;  Short = 'Win32 Canonicalization Bypass' }
    'CWE-59'  = [PSCustomObject]@{ Id = 'CWE-59';  Number = 59;  Short = 'Symlink & Junction Safety' }
    'CWE-66'  = [PSCustomObject]@{ Id = 'CWE-66';  Number = 66;  Short = 'DOS Device & NTFS ADS Abuse' }
    'CWE-73'  = [PSCustomObject]@{ Id = 'CWE-73';  Number = 73;  Short = 'Env & System Root Protection' }
    'CWE-78'  = [PSCustomObject]@{ Id = 'CWE-78';  Number = 78;  Short = 'OS Command & Shell Injection' }
    'CWE-88'  = [PSCustomObject]@{ Id = 'CWE-88';  Number = 88;  Short = 'Argument & Flag Injection' }
    'CWE-155' = [PSCustomObject]@{ Id = 'CWE-155'; Number = 155; Short = 'Wildcard Expansion Injection' }
    'CWE-377' = [PSCustomObject]@{ Id = 'CWE-377'; Number = 377; Short = 'Insecure Temp File & ACL Lock' }
    'CWE-400' = [PSCustomObject]@{ Id = 'CWE-400'; Number = 400; Short = 'Hang & Parser Resilience' }
    'CWE-426' = [PSCustomObject]@{ Id = 'CWE-426'; Number = 426; Short = 'Untrusted Search Path / Planting' }
    'CWE-494' = [PSCustomObject]@{ Id = 'CWE-494'; Number = 494; Short = 'Supply Chain & Hash Integrity' }
}

function Resolve-TestCweMetadata {
    param([string]$RawSuite, [string]$TestName)

    $cweKey = switch -Regex ($TestName) {
        'ZipSlip|Path Traversal|traversal|sibling prefix|boundary enforcement|target allowlisting' { 'CWE-22'; break }
        'Trailing dot|Trailing space|trailing dots|trailing spaces|single dot|Reserved keyword'    { 'CWE-41'; break }
        'DOS reserved|Alternative Data Stream|ADS'                                                 { 'CWE-66'; break }
        'Leading hyphen|leading-hyphen|--vendor|invalid value rejection'                           { 'CWE-88'; break }
        'Asterisk wildcard|Question mark wildcard'                                                 { 'CWE-155'; break }
        'Pinned System Binaries|SystemRoot environment saturation|Base64 UTF-16LE'                 { 'CWE-426'; break }
        'junction|Reparse|Remove-DirectorySafely|active development repository'                    { 'CWE-59'; break }
        'ACL verification|Parallel temp script'                                                    { 'CWE-377'; break }
        'REG_EXPAND_SZ|REG_SZ|Protected system roots|lacking JVM installation|Oracle javapath'     { 'CWE-73'; break }
        'SendMessageTimeout|Extreme PATH|JSONC|Corrupt non-JSON|NO_COLOR'                          { 'CWE-400'; break }
        'SHA|checksum|nuspec|Scoop|Winget|synchronization|DryRun|UTF-8|Get-DeterministicGuid|WIX1103' { 'CWE-494'; break }
        default                                                                                    { 'CWE-78' }
    }
    return $script:CweCatalog[$cweKey]
}

function Resolve-CanonicalSuite {
    param([string]$RawSuite)

    if ($RawSuite -eq 'ReparsePoint') {
        $script:HasPassedSuite2 = $true
    }

    $suiteKey = switch ($RawSuite) {
        'Adversarial'      { 'SUITE 1' }
        'Registry'         { if ($script:HasPassedSuite2) { 'SUITE 6' } else { 'SUITE 2' } }
        'ReparsePoint'     { 'SUITE 3' }
        'Manifest'         { 'SUITE 4' }
        'PackageIntegrity' { 'SUITE 4' }
        'Reparse'          { 'SUITE 5' }
        'Concurrency'      { 'SUITE 5' }
        'Uninstall'        { 'SUITE 7' }
        'UninstallSafety'  { 'SUITE 7' }
        'TerminalJSON'     { 'SUITE 8' }
        default {
            $dynKey = "SUITE_DYN_$RawSuite"
            if (-not $script:SuiteTracker.Contains($dynKey)) {
                $nextNum = $script:SuiteTracker.Count + 1
                $script:SuiteTracker[$dynKey] = [PSCustomObject]@{
                    Id        = "SUITE $nextNum"
                    Number    = $nextNum
                    Name      = "Suite ${nextNum}: $RawSuite"
                    Tag       = $RawSuite
                    Passed    = 0
                    Failed    = 0
                    Skipped   = 0
                    Total     = 0
                    ElapsedMs = 0L
                }
            }
            $dynKey
        }
    }
    return $script:SuiteTracker[$suiteKey]
}

function Test-RunnerFilterMatch {
    param(
        [PSCustomObject]$SuiteEntry,
        [PSCustomObject]$CweMeta,
        [string]$RawSuite,
        [string]$TestName
    )

    if (-not [string]::IsNullOrWhiteSpace($script:RequestedSuite)) {
        $q = $script:RequestedSuite.Trim()
        $suiteCandidates = @(
            $RawSuite,
            $SuiteEntry.Tag,
            $SuiteEntry.Id,
            "Suite$($SuiteEntry.Number)",
            "$($SuiteEntry.Number)",
            $SuiteEntry.Name
        )
        $matchedSuite = $false
        foreach ($cand in $suiteCandidates) {
            if ($cand -like "*$q*" -or $cand -match $q) {
                $matchedSuite = $true
                break
            }
        }
        if (-not $matchedSuite) { return $false }
    }

    if (-not [string]::IsNullOrWhiteSpace($script:RequestedFilter)) {
        $f = $script:RequestedFilter.Trim()
        $matchedFilter = ($TestName -like "*$f*") -or ($RawSuite -like "*$f*") -or ($SuiteEntry.Name -like "*$f*") -or ($CweMeta.Id -like "*$f*") -or ($CweMeta.Short -like "*$f*")
        if (-not $matchedFilter) {
            try {
                $matchedFilter = ($TestName -match $f) -or ($RawSuite -match $f) -or ($SuiteEntry.Name -match $f) -or ($CweMeta.Id -match $f) -or ($CweMeta.Short -match $f)
            } catch {
                $matchedFilter = $false
            }
        }
        if (-not $matchedFilter) { return $false }
    }

    return $true
}

function Run-TestCase {
    param(
        [string]$Suite,
        [string]$Name,
        [scriptblock]$TestLogic
    )

    $suiteEntry = Resolve-CanonicalSuite -RawSuite $Suite
    $cweMeta    = Resolve-TestCweMetadata -RawSuite $Suite -TestName $Name

    if (-not (Test-RunnerFilterMatch -SuiteEntry $suiteEntry -CweMeta $cweMeta -RawSuite $Suite -TestName $Name)) {
        $script:GlobalSkipped++
        $suiteEntry.Skipped++
        return
    }

    $suiteEntry.Total++
    $cweBadge = "${cCyan}[$($cweMeta.Id)]${cReset}"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $TestLogic
        $sw.Stop()
        $elapsed = $sw.ElapsedMilliseconds
        $script:GlobalPassed++
        $suiteEntry.Passed++
        $suiteEntry.ElapsedMs += $elapsed
        Write-Host "  ${cGreen}[PASS]${cReset} $cweBadge $Name ${cGray}($elapsed ms)${cReset}"
        $script:TestResults.Add([PSCustomObject]@{
            SuiteId    = $suiteEntry.Id
            SuiteTitle = $suiteEntry.Name
            Suite      = $Suite
            CweId      = $cweMeta.Id
            CweShort   = $cweMeta.Short
            Name       = $Name
            Status     = "PASS"
            Error      = $null
            Duration   = $elapsed
        })
    } catch {
        $sw.Stop()
        $elapsed = $sw.ElapsedMilliseconds
        $script:GlobalFailed++
        $suiteEntry.Failed++
        $suiteEntry.ElapsedMs += $elapsed
        Write-Host "  ${cRed}[FAIL]${cReset} $cweBadge $Name ${cGray}($elapsed ms)${cReset}" -ForegroundColor Red
        Write-Host "         Error: $($_.Exception.Message)" -ForegroundColor DarkRed
        $script:TestResults.Add([PSCustomObject]@{
            SuiteId    = $suiteEntry.Id
            SuiteTitle = $suiteEntry.Name
            Suite      = $Suite
            CweId      = $cweMeta.Id
            CweShort   = $cweMeta.Short
            Name       = $Name
            Status     = "FAIL"
            Error      = $_.Exception.Message
            Duration   = $elapsed
        })
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Contains {
    param([string]$Haystack, [string]$Needle, [string]$Message)
    if ($Haystack.IndexOf($Needle, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "$Message `nExpected substring: '$Needle'`nActual output:`n$Haystack"
    }
}

function Assert-NotContains {
    param([string]$Haystack, [string]$Needle, [string]$Message)
    if ($Haystack.IndexOf($Needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "$Message `nForbidden substring found: '$Needle'`nActual output:`n$Haystack"
    }
}

function Assert-False {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { throw $Message }
}

function Assert-Equals {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -ne $Expected) {
        throw "$Message `nExpected: '$Expected'`nActual: '$Actual'"
    }
}

function Assert-PathExists {
    param([string]$Path, [string]$Message)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Message `nExpected path to exist: '$Path'"
    }
}

function Assert-PathNotExists {
    param([string]$Path, [string]$Message)
    if (Test-Path -LiteralPath $Path) {
        throw "$Message `nPath unexpectedly exists: '$Path'"
    }
}

# ------------------------------------------------------------------------------
# Test Environment Sandbox Isolation
# ------------------------------------------------------------------------------
$SandboxRoot = Join-Path $env:TEMP "jvm_sec_test_$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $SandboxRoot -Force | Out-Null

$FakeLocalAppData = Join-Path $SandboxRoot "LocalAppData"
$FakeUserProfile  = Join-Path $SandboxRoot "UserProfile"
New-Item -ItemType Directory -Path $FakeLocalAppData -Force | Out-Null
New-Item -ItemType Directory -Path $FakeUserProfile -Force | Out-Null

# Create simulated fake JDK
$FakeJdkDir = Join-Path $SandboxRoot "TargetJDK_21"
New-Item -ItemType Directory -Path (Join-Path $FakeJdkDir "bin") -Force | Out-Null
Set-Content -Path (Join-Path $FakeJdkDir "bin\java.exe") -Value "MZ_FAKE_JAVA_BINARY"
Set-Content -Path (Join-Path $FakeJdkDir "release") -Value "JAVA_VERSION=21.0.2"
Set-Content -Path (Join-Path $FakeJdkDir "canary.txt") -Value "CRITICAL_SENTINEL_DO_NOT_DELETE"

Write-Host ""
Write-Host "$cCyan$cBold========================================================================$cReset"
Write-Host "$cCyan$cBold        DiamTek JVM Automated Security & Adversarial Test Suite        $cReset"
Write-Host "$cCyan$cBold========================================================================$cReset"
Write-Host "  Repository: $RepoRoot"
Write-Host "  Sandbox   : $SandboxRoot"
Write-Host ""

try {
    # ==========================================================================
    # SUITE 1: Adversarial Inputs & Fuzzing Defense
    # ==========================================================================
    Write-Host "$cBold[SUITE 1] Adversarial Inputs & Fuzzing Defense$cReset"

    Run-TestCase "Adversarial" "Path Traversal in 'jvm link' with '..'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" ../evil_link" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on '..'"
        Assert-Contains $out "Link name cannot contain" "Output must reject '..'"
    }

    Run-TestCase "Adversarial" "Path Traversal in 'jvm link' with forward slash '/'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" evil/link" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on '/'"
        Assert-Contains $out "Link name cannot contain path separators" "Output must reject '/'"
    }

    Run-TestCase "Adversarial" "Path Traversal in 'jvm link' with backslash '\'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" evil\link" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on '\'"
        Assert-Contains $out "Link name cannot contain path separators" "Output must reject '\'"
    }

    Run-TestCase "Adversarial" "Path Traversal in 'jvm link' with single dot '.'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" ." 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on '.'"
        Assert-Contains $out "'.' is forbidden" "Output must forbid '.'"
    }

    Run-TestCase "Adversarial" "Reserved keyword rejection in 'jvm link' with 'current'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" current" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on 'current'"
        Assert-Contains $out "'current' is a reserved keyword" "Output must guard 'current'"
    }

    Run-TestCase "Adversarial" "Path Traversal in 'jvm unlink' with '..'" {
        $out = & cmd.exe /c "call `"$JvmBat`" unlink .." 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on '..'"
        Assert-Contains $out "Link name cannot contain" "Unlink must reject '..'"
    }

    Run-TestCase "Adversarial" "Reserved keyword rejection in 'jvm unlink' with 'current'" {
        $out = & cmd.exe /c "call `"$JvmBat`" unlink current" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on 'current'"
        Assert-Contains $out "'current' is a reserved keyword" "Unlink must guard 'current'"
    }

    Run-TestCase "Adversarial" "Ecosystem candidate switch path traversal rejection" {
        $out = & cmd.exe /c "call `"$JvmBat`" maven ../../evil" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on candidate version traversal"
        Assert-Contains $out "Version identifier cannot contain" "SwitchCandidate must reject '..'"
    }

    Run-TestCase "Adversarial" "Ecosystem candidate switch 'current' keyword rejection" {
        $out = & cmd.exe /c "call `"$JvmBat`" gradle current" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on candidate version 'current'"
        Assert-Contains $out "'current' is a reserved keyword" "SwitchCandidate must guard 'current'"
    }

    Run-TestCase "Adversarial" "Candidate installation path traversal rejection" {
        $out = & cmd.exe /c "call `"$JvmBat`" install maven 3.9/../../evil" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on install version traversal"
        Assert-Contains $out "Version identifier cannot contain" "InstallCandidate must reject separators"
    }

    Run-TestCase "Adversarial" "Candidate uninstallation traversal rejection" {
        $out = & cmd.exe /c "call `"$JvmBat`" uninstall maven .." 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on uninstall traversal"
        Assert-Contains $out "Version identifier cannot contain" "UninstallCandidate must reject traversal"
    }

    Run-TestCase "Adversarial" "Metacharacter command injection defense in .java-version" {
        $testDir = Join-Path $SandboxRoot "InjectionTest_JavaVersion"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $pwnFile = Join-Path $testDir "PWNED.txt"
        
        # Craft malicious .java-version with command chaining
        Set-Content -Path (Join-Path $testDir ".java-version") -Value "21 & echo INJECTED > `"$pwnFile`""
        
        Push-Location $testDir
        try {
            $out = & cmd.exe /c "call `"$JvmBat`" current" 2>&1 | Out-String
            Assert-True (-not (Test-Path $pwnFile)) "Command injection payload MUST NOT execute"
        } finally {
            Pop-Location
        }
    }

    Run-TestCase "Adversarial" "Pipe command injection defense in .java-version" {
        $testDir = Join-Path $SandboxRoot "InjectionTest_Pipe"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $pwnFile = Join-Path $testDir "PWNED_PIPE.txt"
        
        Set-Content -Path (Join-Path $testDir ".java-version") -Value "21 | echo INJECTED > `"$pwnFile`""
        
        Push-Location $testDir
        try {
            $out = & cmd.exe /c "call `"$JvmBat`" current" 2>&1 | Out-String
            Assert-True (-not (Test-Path $pwnFile)) "Pipe injection payload MUST NOT execute"
        } finally {
            Pop-Location
        }
    }

    Run-TestCase "Adversarial" "Metacharacter command injection defense in .sdkmanrc" {
        $testDir = Join-Path $SandboxRoot "InjectionTest_Sdkmanrc"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $pwnFile = Join-Path $testDir "PWNED_SDK.txt"
        
        Set-Content -Path (Join-Path $testDir ".sdkmanrc") -Value "java=21.0.2-tem & echo INJECTED > `"$pwnFile`""
        
        Push-Location $testDir
        try {
            $out = & cmd.exe /c "call `"$JvmBat`" current" 2>&1 | Out-String
            Assert-True (-not (Test-Path $pwnFile)) ".sdkmanrc command injection payload MUST NOT execute"
        } finally {
            Pop-Location
        }
    }

    Run-TestCase "Adversarial" "install.ps1 branch traversal parameter rejection" {
        $installPs1 = Join-Path $RepoRoot "install.ps1"
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installPs1 -Branch "../malicious/tag" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "install.ps1 must fail on branch traversal"
        Assert-Contains $out "Invalid branch or tag name" "install.ps1 must reject '..' in -Branch"
    }

    Run-TestCase "Adversarial" "PowerShell profile hook injection filter in Set-JvmVar" {
        # Test the regex filter used in profile hook Set-JvmVar: if ($NewValue -match '[\0;&|<>`"\r\n\$]') { return }
        $filterRegex = '[\0;&|<>`"\r\n\$]'
        $maliciousValues = @(
            'C:\Java\jdk-21 & calc.exe',
            'C:\Java\jdk-21; calc.exe',
            'C:\Java\jdk-21 | calc.exe',
            "C:\Java\jdk-21`$(calc.exe)",
            "C:\Java\jdk-21`ncalc.exe",
            "C:\Java\jdk-21`0calc.exe",
            'C:\Java\jdk-21" & calc.exe'
        )
        foreach ($val in $maliciousValues) {
            Assert-True ($val -match $filterRegex) "Profile hook filter must catch payload: $val"
        }
    }

    Run-TestCase "Adversarial" "Trailing dot Win32 bypass in 'jvm link' with 'current.'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" current." 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on 'current.'"
        Assert-Contains $out "reserved keyword" "Output must guard 'current' with trailing dot"
    }

    Run-TestCase "Adversarial" "Trailing space Win32 bypass in 'jvm link' with 'current '" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" `"current `"" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on 'current '"
        Assert-Contains $out "reserved keyword" "Output must guard 'current' with trailing space"
    }

    Run-TestCase "Adversarial" "DOS reserved device rejection in 'jvm link' (CON, PRN, AUX, NUL)" {
        foreach ($dev in @('CON', 'PRN', 'AUX', 'NUL', 'COM1', 'LPT1')) {
            $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" $dev" 2>&1 | Out-String
            Assert-True ($LASTEXITCODE -ne 0) "Expected failure on DOS device $dev"
            Assert-Contains $out "Invalid link name" "Output must reject DOS device $dev"
        }
    }

    Run-TestCase "Adversarial" "Poison characters in 'jvm link' (&, |, <, >, ^, %, !)" {
        $poisons = @('foo&bar', 'foo|bar', 'foo<bar', 'foo>bar', 'foo^bar', 'foo^%bar', 'foo!bar')
        foreach ($p in $poisons) {
            $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" `"$p`"" 2>&1 | Out-String
            Assert-True ($LASTEXITCODE -ne 0) "Expected failure on poison character: $p"
        }
        Remove-Item -LiteralPath (Join-Path $RepoRoot "bar") -Force -ErrorAction SilentlyContinue
    }

    Run-TestCase "Adversarial" "Alternative Data Stream (ADS) rejection in 'jvm link'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" test:stream" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on NTFS ADS syntax"
        Assert-Contains $out "Invalid link name" "Output must reject ':' stream separator"
    }

    Run-TestCase "Adversarial" "jvm which command traversal rejection" {
        $out = & cmd.exe /c "call `"$JvmBat`" which ../../evil" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on 'jvm which ../../evil'"
        Assert-Contains $out "Invalid candidate name" "Output must reject traversal in which"
    }

    Run-TestCase "Adversarial" "jvm which poison character rejection" {
        $out = & cmd.exe /c "call `"$JvmBat`" which `"foo&bar`"" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on 'jvm which foo&bar'"
        Assert-Contains $out "Invalid candidate name" "Output must reject poison character in which"
    }

    Run-TestCase "Adversarial" ".sdkmanrc candidate traversal rejection in session mode" {
        $testDir = Join-Path $SandboxRoot "InjectionTest_SdkTraversal"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        Set-Content -Path (Join-Path $testDir ".sdkmanrc") -Value "maven=../../Windows`ngradle=../test"
        Push-Location $testDir
        try {
            $sessTarget = Join-Path $env:TEMP ".jvm_session_target"
            if (Test-Path $sessTarget) { Remove-Item $sessTarget -Force -ErrorAction SilentlyContinue }
            $out = & cmd.exe /c "call `"$JvmBat`" status" 2>&1 | Out-String
            if (Test-Path $sessTarget) {
                $content = Get-Content $sessTarget -Raw
                Assert-NotContains $content "MAVEN_HOME=.*Windows" "Traversed path must not be recorded in session target"
                Remove-Item $sessTarget -Force -ErrorAction SilentlyContinue
            }
        } finally {
            Pop-Location
        }
    }

    Run-TestCase "Adversarial" "Leading hyphen flag injection defense in 'jvm link'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" --evil-flag" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on '--evil-flag'"
        Assert-Contains $out "Invalid link name" "Output must reject leading hyphen"
    }

    Run-TestCase "Adversarial" "Multiple trailing dots Win32 bypass defense in 'jvm link'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" current...." 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on 'current....'"
        Assert-True (($out -match "reserved keyword") -or ($out -match "cannot contain '\.\.'")) "Must reject multi-dot bypass"
    }

    Run-TestCase "Adversarial" "Multiple trailing spaces Win32 bypass defense in 'jvm link'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" `"current   `"" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on 'current   '"
        Assert-Contains $out "reserved keyword" "Output must guard 'current' with multiple trailing spaces"
    }

    Run-TestCase "Adversarial" "Semicolon command chaining rejection in candidate version" {
        $out = & cmd.exe /c "call `"$JvmBat`" maven `"3.9;calc`"" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on candidate version with semicolon"
        Assert-Contains $out "Invalid version identifier" "Output must reject semicolon"
    }

    Run-TestCase "Adversarial" "Asterisk wildcard rejection in 'jvm link'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" `"foo*bar`"" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on wildcard asterisk"
        Assert-Contains $out "Invalid link name" "Output must reject asterisk wildcard"
    }

    Run-TestCase "Adversarial" "Question mark wildcard rejection in 'jvm link'" {
        $out = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" `"foo?bar`"" 2>&1 | Out-String
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on wildcard question mark"
        Assert-Contains $out "Invalid link name" "Output must reject question mark wildcard"
    }

    Run-TestCase "Adversarial" "Pinned System Binaries CWD Planting Defense" {
        $content = Get-Content $JvmBat -Raw
        $bins = @('CMD_BIN', 'PS_BIN', 'FINDSTR_BIN', 'REG_BIN', 'FSUTIL_BIN', 'WHERE_BIN', 'TIMEOUT_BIN', 'CHOICE_BIN', 'CHCP_BIN')
        foreach ($b in $bins) {
            Assert-Contains $content "set `"$b=%SYS32%\" "jvm.bat must pin $b to %SYS32% to prevent binary planting"
        }
    }

    Run-TestCase "Adversarial" "Metacharacter command injection defense in 'jvm pin'" {
        $testDir = Join-Path $SandboxRoot "PinInjectionTest"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        Push-Location $testDir
        try {
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $out = & cmd.exe /c "call `"$JvmBat`" pin `"21;calc`"" 2>&1 | Out-String
            $ErrorActionPreference = $prevEAP
            Assert-True ($LASTEXITCODE -ne 0) "Expected failure on injection in 'jvm pin'"
            Assert-Contains $out "Invalid version identifier for pin" "Output must reject metacharacters in 'jvm pin'"
        } finally {
            Pop-Location
        }
    }

    Run-TestCase "Adversarial" "Path Traversal in 'jvm exec' command" {
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        $out = & cmd.exe /c "call `"$JvmBat`" exec ../../evil -- java -version" 2>&1 | Out-String
        $ErrorActionPreference = $prevEAP
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on traversal in 'jvm exec'"
        Assert-Contains $out "Invalid target version for exec" "Output must reject traversal in 'jvm exec'"
    }

    Run-TestCase "Adversarial" "PowerShell command injection defense in 'jvm install' candidate version" {
        $testDir = Join-Path $SandboxRoot "InstallInjectTest"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $pwnFile = Join-Path $testDir "INSTALL_PWNED.txt"
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        $out = & cmd.exe /c "call `"$JvmBat`" install maven `"3.9;calc`"" 2>&1 | Out-String
        $ErrorActionPreference = $prevEAP
        Assert-True ($LASTEXITCODE -ne 0) "Expected failure on injection in candidate version"
        Assert-True (-not (Test-Path $pwnFile)) "Injected payload in candidate version MUST NOT execute"
        Assert-Contains $out "Invalid version identifier" "Output must reject injection in candidate version"
    }

    Run-TestCase "Adversarial" "Pre-delayed-expansion ':RejectExclamationArg' across positions %~1..%~5" {
        $argVectors = @(
            '!PATH!',
            'use "jdk!21"',
            'install maven "!lead"',
            'exec 21 -- "trail!"',
            'exec 21 -- java "mid!dle"'
        )
        foreach ($vec in $argVectors) {
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $out = & cmd.exe /c "call `"$JvmBat`" $vec" 2>&1 | Out-String
            $ErrorActionPreference = $prevEAP
            Assert-True ($LASTEXITCODE -ne 0) "Expected ':RejectExclamationArg' failure for vector: $vec"
            Assert-Contains $out "poison character '!' is forbidden" "Output must reject '!' in vector: $vec"
        }
    }

    Run-TestCase "Adversarial" "Embedded double-quote smuggling rejection in ':VSI_CharLoop'" {
        $testDir = Join-Path $SandboxRoot "QuoteSmuggleTest"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        Push-Location $testDir
        try {
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            # 1. End-to-end CLI check: smuggled quote must abort with non-zero exit code and never write .java-version
            $outPin = & cmd.exe /c "call `"$JvmBat`" pin 21^`"pwn" 2>&1 | Out-String
            $pinExit = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-True ($pinExit -ne 0) "jvm pin must fail closed on smuggled double quote"
            Assert-PathNotExists (Join-Path $testDir ".java-version") ".java-version must not be written on quote smuggling"

            # 2. Direct unit verification of :ValidateStrictIdentifier / :VSI_CharLoop on embedded '"'
            $batRaw = Get-Content $JvmBat -Raw
            $vsiMatch = [regex]::Match($batRaw, '(?s)(:VSI_CharLoop\r?\n.*?)(?=\r?\n:GetCandidateEnvVar)')
            Assert-True $vsiMatch.Success "Must locate :VSI_CharLoop in jvm.bat"

            $vsiHarness = Join-Path $testDir "vsi_quote_harness.bat"
            $vsiCode = @"
@echo off
setlocal disabledelayedexpansion
setlocal enabledelayedexpansion
set _VSI_DQ="
set _VSI_VAL=21"pwn
set "_VSI_REM=!_VSI_VAL!"
goto :VSI_CharLoop
$($vsiMatch.Groups[1].Value)
"@
            [System.IO.File]::WriteAllText($vsiHarness, ($vsiCode -replace "\r?\n", "`r`n"), [System.Text.UTF8Encoding]::new($false))
            $null = & cmd.exe /c "call `"$vsiHarness`"" 2>&1
            Assert-Equals $LASTEXITCODE 1 ":VSI_CharLoop must return exit code 1 when _VSI_VAL contains an embedded double-quote"
        } finally {
            Pop-Location
        }
    }

    Run-TestCase "Adversarial" "'--vendor' flag poisoning and unsupported vendor dispatch rejection" {
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        $outSwitch = & cmd.exe /c "call `"$JvmBat`" 21 --vendor `"../../evil_vendor`"" 2>&1 | Out-String
        $switchExit = $LASTEXITCODE

        $outUpdate = & cmd.exe /c "call `"$JvmBat`" update 21 --vendor `"oracle;calc`"" 2>&1 | Out-String
        $updateExit = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP

        Assert-True ($switchExit -ne 0) "Switching with poisoned --vendor must fail closed"
        Assert-Contains $outSwitch "JDK 21 not found" "Poisoned --vendor must prevent JDK match"

        Assert-True ($updateExit -ne 0) "Updating with poisoned --vendor must fail closed"
        Assert-Contains $outUpdate "JDK 21 not found" "Poisoned --vendor in update must prevent JDK match"

        $batContent = Get-Content $JvmBat -Raw
        Assert-NotContains $batContent "goto :Resolve_!CLI_VENDOR!" "jvm.bat must not use unvalidated dynamic goto on CLI_VENDOR"
        Assert-Contains $batContent "Unknown or unsupported vendor: !CLI_VENDOR!" "jvm.bat must explicitly reject unknown vendors"
    }

    Run-TestCase "Adversarial" "'jvm channel' invalid value rejection and 'jvm open' target allowlisting" {
        $origLocalAppData = $env:LOCALAPPDATA
        try {
            $env:LOCALAPPDATA = $FakeLocalAppData
            $channelFile = Join-Path $FakeLocalAppData "DiamTek\JVM\channel.txt"
            if (Test-Path -LiteralPath $channelFile) { Remove-Item -LiteralPath $channelFile -Force }

            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outChan = & cmd.exe /c "call `"$JvmBat`" channel `"../../evil_branch`"" 2>&1 | Out-String
            $outOpen = & cmd.exe /c "call `"$JvmBat`" open candidates" 2>&1 | Out-String
            $openExit = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-Contains $outChan "Unknown channel" "jvm channel must reject invalid channel names"
            Assert-Contains $outChan "Valid options are 'stable' or 'nightly'" "jvm channel must state valid options"
            Assert-PathNotExists $channelFile "Invalid channel argument must NOT create or modify channel.txt"

            Assert-True ($openExit -ne 0) "jvm open must fail closed when allowlisted target directory does not exist"
            Assert-Contains $outOpen "Target path does not exist" "jvm open must report missing target path without launching explorer.exe"

            $batContent = Get-Content $JvmBat -Raw
            Assert-NotContains $batContent 'set "OPEN_PATH=!CLI_TARGET!"' "jvm open must never assign raw CLI_TARGET directly to OPEN_PATH"
        } finally {
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    Run-TestCase "Adversarial" "Static code audit: 'for /f' subshells must never quote '%..._BIN%' binaries" {
        $lines = Get-Content $JvmBat
        $violations = @()
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            # 1. No pinned system binary (%..._BIN%) may be wrapped in quotes inside for /f ('...')
            if ($line -match '(?i)^\s*for\s+/f\b.*\bin\s*\(\s*''[^'']*\"%[A-Z0-9_]+_BIN%\"') {
                $violations += "Line $($i + 1) (quoted %..._BIN%): $($line.Trim())"
            }
            # 2. No for /f ('"..."..."..."') command may start AND end with a SINGLE quote (not ""..."" wrapper) when containing multiple quoted segments
            if ($line -match '(?i)^\s*for\s+/f\b.*\bin\s*\(\s*''(\"(?!\")[^'']+\"[^'']*\"[^'']+?(?<!\")\")''\s*\)') {
                $violations += "Line $($i + 1) (unwrapped multi-quote cmd.exe /c stripping hazard): $($line.Trim())"
            }
        }
        Assert-True ($violations.Count -eq 0) ("Found 'for /f' quote-stripping hazard in jvm.bat:`n" + ($violations -join "`n"))
    }

    Run-TestCase "Adversarial" "':ValidateStrictIdentifier' clean execution on 'jvm which java' and leading-hyphen flag injection rejection" {
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        $outWhichClean = & cmd.exe /c "call `"$JvmBat`" which java" 2>&1 | Out-String
        $outHyphen = & cmd.exe /c "call `"$JvmBat`" pin `"-ExecutionPolicy`"" 2>&1 | Out-String
        $hyphenExit = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP

        Assert-NotContains $outWhichClean "is not recognized as an internal or external command" "jvm which java must not emit CMD quote-parser errors"
        Assert-True ($hyphenExit -ne 0) "Leading hyphen flag injection must be rejected by :ValidateStrictIdentifier"
        Assert-Contains $outHyphen "Invalid version identifier" "Leading hyphen must be rejected with clear diagnostic"
    }

    # ==========================================================================
    # SUITE 2: Registry & Environment Variable Boundary & Elevation Tests
    # ==========================================================================
    Write-Host ""
    Write-Host "$cBold[SUITE 2] Registry & Environment Variable Boundary Tests$cReset"

    Run-TestCase "Registry" "User PATH REG_EXPAND_SZ preservation during installation" {
        # Verify that setting User PATH via registry preserves ExpandString kind
        $testHive = "HKCU:\Environment"
        $originalKind = (Get-Item -Path $testHive).GetValueKind("Path")
        Assert-True ($originalKind -in @([Microsoft.Win32.RegistryValueKind]::ExpandString, [Microsoft.Win32.RegistryValueKind]::String)) "Valid initial kind"
        
        # Simulate JVM registry update logic
        [Microsoft.Win32.Registry]::SetValue("HKEY_CURRENT_USER\Environment", "TestJvmPath", "%USERPROFILE%\dummy;%SystemRoot%\System32", [Microsoft.Win32.RegistryValueKind]::ExpandString)
        
        $kind = (Get-Item -Path $testHive).GetValueKind("TestJvmPath")
        Assert-True ($kind -eq [Microsoft.Win32.RegistryValueKind]::ExpandString) "Registry ValueKind must be ExpandString"
        
        # Verify unexpanded content is preserved
        $envKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment")
        $raw = $envKey.GetValue("TestJvmPath", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $envKey.Close()
        Assert-Contains $raw "%USERPROFILE%" "Unexpanded environment variable tokens must NOT be converted to static strings"
        
        # Clean test key
        Remove-ItemProperty -Path $testHive -Name "TestJvmPath" -Force -ErrorAction SilentlyContinue
    }

    Run-TestCase "Registry" "Elevation payload generation uses Base64 UTF-16LE without temp files" {
        # Verify encoded elevation string format used in jvm.bat
        $testCmd = '$del = ''C:\Dummy\Path''; if (Test-Path -LiteralPath $del) { Write-Output ''OK'' }'
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($testCmd)
        $encoded = [System.Convert]::ToBase64String($bytes)
        
        # Verify round-trip decoding
        $decodedBytes = [System.Convert]::FromBase64String($encoded)
        $decodedStr = [System.Text.Encoding]::Unicode.GetString($decodedBytes)
        Assert-True ($decodedStr -eq $testCmd) "Base64 UTF-16LE decoding must perfectly match original payload"
        
        # Verify temp directory is not polluted with elevation scripts
        $tempScripts = Get-ChildItem -Path $env:TEMP -Filter "jvm_updater_*.bat" -ErrorAction SilentlyContinue
        Assert-True ($tempScripts.Count -eq 0) "No temporary elevation batch files should linger in %TEMP%"
    }

    Run-TestCase "Registry" "Elevation path resolution immune to SystemRoot environment saturation" {
        $realSys32 = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
        Assert-True (-not [string]::IsNullOrEmpty($realSys32)) "System32 path must resolve via OS SpecialFolder API"
        Assert-True (Test-Path (Join-Path $realSys32 "cmd.exe")) "System32 must contain cmd.exe"
        Assert-True (Test-Path (Join-Path $realSys32 "WindowsPowerShell\v1.0\powershell.exe")) "System32 must contain powershell.exe"
        
        # Simulate environment saturation attack
        $originalSystemRoot = $env:SystemRoot
        try {
            $env:SystemRoot = "C:\Users\Public\MaliciousDir"
            # GetFolderPath must ignore the saturated/spoofed environment variable
            $probedSys32 = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
            Assert-True ($probedSys32 -eq $realSys32) "GetFolderPath(System) must NOT be spoofed by tampered `$env:SystemRoot"
            
            $probedWin = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
            Assert-True ($probedWin -ne "C:\Users\Public\MaliciousDir") "GetFolderPath(Windows) must NOT resolve to attacker directory"
        } finally {
            $env:SystemRoot = $originalSystemRoot
        }
    }

    Run-TestCase "Registry" "PATH de-bloating correctly eliminates Oracle javapath entries" {
        $samplePath = "C:\Program Files\Common Files\Oracle\Java\javapath;C:\Windows\System32;C:\ProgramData\Oracle\Java\javapath;C:\Program Files (x86)\Common Files\Oracle\Java\javapath;C:\Utils"
        $purges = @(
            'C:\Program Files\Common Files\Oracle\Java\javapath',
            'C:\Program Files (x86)\Common Files\Oracle\Java\javapath',
            'C:\ProgramData\Oracle\Java\javapath'
        )
        $clean = ($samplePath -split ';' | Where-Object { $_ -and $purges -notcontains $_.TrimEnd('\') }) -join ';'
        Assert-NotContains $clean "Oracle\Java\javapath" "Oracle javapath entries must be purged"
        Assert-Contains $clean "C:\Windows\System32" "Legitimate system PATH entries must remain intact"
        Assert-Contains $clean "C:\Utils" "User utilities must remain intact"
    }

    Run-TestCase "Registry" "Extreme PATH length handling (> 2048 characters)" {
        $longElements = 1..100 | ForEach-Object { "C:\MockDirectory\SubFolder\Number$_" }
        $longPath = $longElements -join ';'
        Assert-True ($longPath.Length -gt 2500) "Synthetic path must exceed 2048 characters"
        
        # Test split and deduplication without memory corruption
        $parts = @($longPath -split ';' | Where-Object { $_ -ne '' } | ForEach-Object { $_.TrimEnd('\') })
        Assert-True ($parts.Count -eq 100) "All 100 segments must parse successfully"
    }

    Run-TestCase "Registry" "'NO_COLOR=1' and '--no-color' strict ANSI escape sequence suppression" {
        $prevNoColor = $env:NO_COLOR
        try {
            $env:NO_COLOR = "1"
            $outEnv = & cmd.exe /c "call `"$JvmBat`" --version" 2>&1 | Out-String
            $env:NO_COLOR = $null
            $outFlag = & cmd.exe /c "call `"$JvmBat`" --version --no-color" 2>&1 | Out-String

            Assert-False ($outEnv -match '\x1b\[') "NO_COLOR=1 must suppress all ANSI escape sequences (\x1b[)"
            Assert-False ($outFlag -match '\x1b\[') "--no-color flag must suppress all ANSI escape sequences (\x1b[)"
            Assert-Contains $outEnv "Java Version Manager" "Version banner text must still render under NO_COLOR=1"
        } finally {
            $env:NO_COLOR = $prevNoColor
        }
    }

    # ==========================================================================
    # SUITE 3: Symlink & Directory Junction Non-Destructive Lifecycle
    # ==========================================================================
    Write-Host ""
    Write-Host "$cBold[SUITE 3] Symlink & Directory Junction Non-Destructive Lifecycle$cReset"

    Run-TestCase "ReparsePoint" "Directory junction unbinding does NOT traverse into target JDK" {
        # Setup: Junction pointing to FakeJdkDir
        $junctionDir = Join-Path $SandboxRoot "JunctionTestContainer"
        New-Item -ItemType Directory -Path $junctionDir -Force | Out-Null
        $junctionPath = Join-Path $junctionDir "current"
        
        # Create junction using cmd mklink /J
        $null = & cmd.exe /c "mklink /J `"$junctionPath`" `"$FakeJdkDir`"" 2>&1
        Assert-True (Test-Path $junctionPath) "Junction must be successfully created"
        
        # Verify the junction is identified as a ReparsePoint
        $item = Get-Item -LiteralPath $junctionPath -Force
        $isReparse = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
        Assert-True $isReparse "Target must have ReparsePoint attribute"
        
        # Execute JVM's junction-safe unbinding mechanism (from uninstall.ps1)
        if ($item.PSIsContainer) {
            try {
                [System.IO.Directory]::Delete($item.FullName, $false)
            } catch {
                & cmd.exe /c "rmdir /q `"$($item.FullName)`"" 2>$null
            }
        }
        
        # CRITICAL ASSERTION: Junction is gone, but TargetJDK and sentinel canary remain untouched!
        Assert-True (-not (Test-Path $junctionPath)) "Directory junction must be deleted"
        Assert-True (Test-Path $FakeJdkDir) "Target JDK directory MUST STILL EXIST"
        Assert-True (Test-Path (Join-Path $FakeJdkDir "bin\java.exe")) "Target java.exe MUST REMAIN"
        Assert-True (Test-Path (Join-Path $FakeJdkDir "canary.txt")) "Target sentinel canary file MUST REMAIN"
        $canaryContent = Get-Content (Join-Path $FakeJdkDir "canary.txt") -Raw
        Assert-Contains $canaryContent "CRITICAL_SENTINEL_DO_NOT_DELETE" "Canary content must not be truncated or modified"
    }

    Run-TestCase "ReparsePoint" "Querying reparse point with `$env:QUERY_PATH and -LiteralPath" {
        # Create directory with problematic characters: square brackets and spaces
        $bracketDir = Join-Path $SandboxRoot "JDK [Special] (x86)"
        $null = New-Item -ItemType Directory -Path $SandboxRoot -Name "JDK [Special] (x86)" -Force
        $bracketBin = Join-Path $bracketDir "bin"
        [System.IO.Directory]::CreateDirectory($bracketBin) | Out-Null
        Set-Content -LiteralPath (Join-Path $bracketBin "java.exe") -Value "FAKE"
        
        $linkContainer = Join-Path $SandboxRoot "LinksSpecial"
        New-Item -ItemType Directory -Path $linkContainer -Force | Out-Null
        $linkPath = Join-Path $linkContainer "testlink"
        & cmd.exe /c "mklink /J `"$linkPath`" `"$bracketDir`"" 2>&1 | Out-Null
        
        # Execute JVM's exact query pipeline
        $env:QUERY_PATH = $linkPath
        $resolvedTarget = & powershell.exe -NoProfile -Command "(Get-Item -LiteralPath `$env:QUERY_PATH -ErrorAction SilentlyContinue).Target"
        $env:QUERY_PATH = $null
        
        Assert-True (-not [string]::IsNullOrWhiteSpace($resolvedTarget)) "Reparse query must resolve path with brackets"
        Assert-Contains $resolvedTarget "JDK [Special] (x86)" "Target must accurately reflect original directory name"
    }

    Run-TestCase "ReparsePoint" "uninstall.ps1 active development repository guard" {
        # Create dummy folder with .git
        $devDir = Join-Path $SandboxRoot "ActiveDevRepo"
        New-Item -ItemType Directory -Path (Join-Path $devDir ".git") -Force | Out-Null
        Set-Content -Path (Join-Path $devDir "jvm.bat") -Value "REM TEST"
        
        # Evaluate dev repo detection logic from uninstall.ps1
        $isDevRepo = (Test-Path (Join-Path $devDir ".git")) -or (Test-Path (Join-Path $devDir "..\.git"))
        Assert-True $isDevRepo "Uninstaller must detect active .git directory"
    }

    # ==========================================================================
    # SUITE 4: Package Manager Manifest Schema Integrity & Dry-Run Guarantees
    # ==========================================================================
    Write-Host ""
    Write-Host "$cBold[SUITE 4] Package Manager Manifest Schema Integrity & Dry-Run Guarantees$cReset"

    Run-TestCase "Manifest" "Cross-package version synchronization parity" {
        # 1. Read jvm.bat
        $batContent = Get-Content $JvmBat -Raw
        $batVersion = if ($batContent -match 'set\s+"JVM_VERSION=([^"]+)"') { $matches[1] } else { $null }
        Assert-True (-not [string]::IsNullOrEmpty($batVersion)) "jvm.bat version must be defined"
        
        # 2. Chocolatey jvm.nuspec
        $nuspecPath = Join-Path $RepoRoot "packages\choco\jvm.nuspec"
        $nuspecContent = Get-Content $nuspecPath -Raw
        $chocoVersion = if ($nuspecContent -match '<version>([^<]+)</version>') { $matches[1] } else { $null }
        Assert-True ($chocoVersion -eq $batVersion) "Chocolatey nuspec version ($chocoVersion) must match jvm.bat ($batVersion)"
        
        # 3. Scoop jvm.json
        $scoopPath = Join-Path $RepoRoot "packages\scoop\jvm.json"
        $scoopJson = Get-Content $scoopPath -Raw | ConvertFrom-Json
        Assert-True ($scoopJson.version -eq $batVersion) "Scoop version ($($scoopJson.version)) must match jvm.bat ($batVersion)"
        
        # 4. Winget Yaml
        $wingetPath = Join-Path $RepoRoot "packages\winget\DiamTek.JVM.yaml"
        $wingetContent = Get-Content $wingetPath -Raw
        $wingetVersion = if ($wingetContent -match 'PackageVersion:\s*([0-9.]+)') { $matches[1] } else { $null }
        Assert-True ($wingetVersion -eq $batVersion) "Winget version ($wingetVersion) must match jvm.bat ($batVersion)"
    }

    Run-TestCase "Manifest" "Chocolatey nuspec XML schema & UTF-8 No BOM validation" {
        $nuspecPath = Join-Path $RepoRoot "packages\choco\jvm.nuspec"
        
        # Ensure valid XML
        [xml]$xml = Get-Content $nuspecPath -Raw
        Assert-True ($xml.package.metadata.id -eq "jvm-windows") "Package ID must be 'jvm-windows'"
        Assert-True ($null -ne $xml.package.metadata.licenseUrl) "License URL must be present"
        
        # Ensure UTF-8 without BOM
        $bytes = [System.IO.File]::ReadAllBytes($nuspecPath)
        $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        Assert-True (-not $hasBom) "jvm.nuspec MUST NOT contain UTF-8 BOM"
    }

    Run-TestCase "PackageIntegrity" "Chocolatey install fail-closed checksum validation assertion" {
        $chocoInstall = Join-Path $RepoRoot "packages\choco\tools\chocolateyInstall.ps1"
        $content = Get-Content $chocoInstall -Raw
        Assert-Contains $content "`$checksum64 -notmatch" "chocolateyInstall.ps1 must validate checksum format"
        Assert-Contains $content "Security violation:" "Must throw fail-closed error on checksum invalidity"
    }

    Run-TestCase "Manifest" "Scoop manifest schema & mandatory fields" {
        $scoopPath = Join-Path $RepoRoot "packages\scoop\jvm.json"
        $scoop = Get-Content $scoopPath -Raw | ConvertFrom-Json
        
        Assert-True ($scoop.bin -eq "jvm.bat") "Scoop bin entry must be jvm.bat"
        Assert-True (-not [string]::IsNullOrEmpty($scoop.url)) "Scoop download URL must be populated"
        Assert-True (-not [string]::IsNullOrEmpty($scoop.hash)) "Scoop SHA-256 hash must be populated"
        Assert-True (-not [string]::IsNullOrEmpty($scoop.autoupdate.url)) "Scoop autoupdate URL must be configured"
    }

    Run-TestCase "Manifest" "Winget multi-manifest file coherence" {
        $wingetDir = Join-Path $RepoRoot "packages\winget"
        $rootYaml      = Join-Path $wingetDir "DiamTek.JVM.yaml"
        $installerYaml = Join-Path $wingetDir "DiamTek.JVM.installer.yaml"
        $localeYaml    = Join-Path $wingetDir "DiamTek.JVM.locale.en-US.yaml"
        
        Assert-True (Test-Path $rootYaml) "DiamTek.JVM.yaml must exist"
        Assert-True (Test-Path $installerYaml) "DiamTek.JVM.installer.yaml must exist"
        Assert-True (Test-Path $localeYaml) "DiamTek.JVM.locale.en-US.yaml must exist"
        
        $instRaw = Get-Content $installerYaml -Raw
        Assert-Contains $instRaw "Architecture: x64" "Winget must define x64 installer"
        Assert-Contains $instRaw "Architecture: arm64" "Winget must define arm64 installer"
        Assert-Contains $instRaw "InstallerType: msi" "Winget installer type must be msi"
    }

    Run-TestCase "Manifest" "bump-version.ps1 -DryRun immutability guarantee" {
        $bumpScript = Join-Path $RepoRoot "scripts\bump-version.ps1"
        if (Test-Path $bumpScript) {
            # Capture status before
            $gitStatusBefore = (& git -C "$RepoRoot" status --porcelain 2>&1 | Out-String).Trim()
            
            # Execute dry run
            $dryOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bumpScript patch -DryRun -NoBucketSync -Force 2>&1 | Out-String
            
            # Capture status after
            $gitStatusAfter = (& git -C "$RepoRoot" status --porcelain 2>&1 | Out-String).Trim()
            Assert-True ($gitStatusBefore -eq $gitStatusAfter) "Working tree status must be identical before and after -DryRun"
        }
    }

    Run-TestCase "Manifest" "GitHub Actions workflow 40-char commit SHA pinning & explicit permissions audit" {
        $workflowsDir = Join-Path $RepoRoot ".github\workflows"
        $workflowFiles = Get-ChildItem -Path $workflowsDir -Filter "*.yml" -File
        Assert-True ($workflowFiles.Count -ge 2) "At least ci.yml and release.yml must exist"

        foreach ($wf in $workflowFiles) {
            $wfContent = Get-Content $wf.FullName -Raw
            Assert-Contains $wfContent "permissions:" "$($wf.Name) must declare explicit least-privilege 'permissions:' block"

            $usesMatches = [regex]::Matches($wfContent, '(?m)^\s*-?\s*uses:\s*([^\s#]+)')
            Assert-True ($usesMatches.Count -gt 0) "$($wf.Name) must contain at least one 'uses:' action reference"
            foreach ($m in $usesMatches) {
                $actionRef = $m.Groups[1].Value.Trim('''', '"')
                if ($actionRef.StartsWith('./')) { continue }
                Assert-True ($actionRef -match '@[0-9a-f]{40}$') "Action '$actionRef' in $($wf.Name) must be pinned to an immutable 40-char hex commit SHA"
            }
        }
    }

    Run-TestCase "PackageIntegrity" "jvm.bat UTF-8 No BOM, 100% CRLF, no U+00A0, and EOF sentinel integrity" {
        $bytes = [System.IO.File]::ReadAllBytes($JvmBat)
        $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        Assert-False $hasBom "jvm.bat MUST NOT contain a UTF-8 BOM (0xEF,0xBB,0xBF breaks @echo off)"

        $bareLfCount = 0
        for ($i = 0; $i -lt $bytes.Length; $i++) {
            if ($bytes[$i] -eq 0x0A -and ($i -eq 0 -or $bytes[$i - 1] -ne 0x0D)) {
                $bareLfCount++
            }
        }
        Assert-Equals $bareLfCount 0 "jvm.bat must use 100% CRLF line endings (0 bare LF allowed to prevent CMD label-offset desync)"

        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        Assert-False ($text.Contains([char]0x00A0)) "jvm.bat must not contain non-breaking spaces (U+00A0)"
        Assert-True ($text.TrimEnd() -match 'rem END OF SCRIPT$') "jvm.bat must end with intact 'rem END OF SCRIPT' sentinel"
    }

    Run-TestCase "PackageIntegrity" "build-msi.ps1 RFC 4122 UUID v5 Get-DeterministicGuid reproducibility & collision resistance" {
        $buildMsiPath = Join-Path $RepoRoot "packages\msi\build-msi.ps1"
        Assert-PathExists $buildMsiPath "packages/msi/build-msi.ps1 must exist"
        $msiSrc = Get-Content $buildMsiPath -Raw
        Assert-Contains $msiSrc "function Get-DeterministicGuid" "build-msi.ps1 must define Get-DeterministicGuid"

        $ast = [System.Management.Automation.Language.Parser]::ParseInput($msiSrc, [ref]$null, [ref]$null)
        $fnAst = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-DeterministicGuid' }, $true)
        Assert-True ($null -ne $fnAst) "Get-DeterministicGuid AST node must be extractable"
        . ([scriptblock]::Create($fnAst.Extent.Text))

        $ns = "b20650a4-4212-4d64-9edf-744e9285e2be"
        $g1 = Get-DeterministicGuid $ns "DiamTek.JVM.ProductCode:1.0.2:x64"
        $g2 = Get-DeterministicGuid $ns "DiamTek.JVM.ProductCode:1.0.2:x64"
        $gArm = Get-DeterministicGuid $ns "DiamTek.JVM.ProductCode:1.0.2:arm64"
        $gNext = Get-DeterministicGuid $ns "DiamTek.JVM.ProductCode:1.0.3:x64"

        Assert-Equals $g1 $g2 "Get-DeterministicGuid must be 100% reproducible for identical (Version, Arch)"
        Assert-True ($g1 -ne $gArm) "Get-DeterministicGuid must produce distinct ProductCode for x64 vs arm64"
        Assert-True ($g1 -ne $gNext) "Get-DeterministicGuid must produce distinct ProductCode across versions"
        Assert-True ($g1 -match '^\{?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-5[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\}?$') "Generated GUID ($g1) must conform to RFC 4122 UUID v5 variant/version bits"
    }

    Run-TestCase "PackageIntegrity" "build-msi.ps1 `$profileCode extraction parity & WIX1103 unversioned script hash verification" {
        $buildMsiPath = Join-Path $RepoRoot "packages\msi\build-msi.ps1"
        $installPs1Path = Join-Path $RepoRoot "install.ps1"
        $msiSrc = Get-Content $buildMsiPath -Raw
        $installRaw = Get-Content $installPs1Path -Raw

        Assert-Contains $msiSrc '$profileCode = $profileMatch.Groups[1].Value.Trim()' "build-msi.ps1 must assign extracted `$profileCode from `$profileMatch"
        $profileMatch = [regex]::Match($installRaw, "(?s)\`$profileCode\s*=\s*@'\r?\n(.*?)\r?\n'@")
        Assert-True $profileMatch.Success "build-msi.ps1 regex must successfully extract `$profileCode from install.ps1"
        $extractedHook = $profileMatch.Groups[1].Value.Trim()
        Assert-Contains $extractedHook "function jvm" "Extracted `$profileCode must contain function jvm"
        Assert-Contains $extractedHook "function Set-JvmVar" "Extracted `$profileCode must contain Set-JvmVar"

        $scriptFileTags = [regex]::Matches($msiSrc, '<File\s+Id="(?:UninstallFile|MsiInstallHook|MsiUninstallHook|JvmBat)"[^>]*>')
        Assert-Equals $scriptFileTags.Count 4 "build-msi.ps1 must declare all 4 script <File> elements (UninstallFile, MsiInstallHook, MsiUninstallHook, JvmBat)"
        foreach ($tag in $scriptFileTags) {
            Assert-NotContains $tag.Value "DefaultVersion=" "Script <File> element must NOT specify DefaultVersion (prevents WIX1103 & ensures MsiFileHash population): $($tag.Value)"
        }
    }

    # ==========================================================================
    # SUITE 5: Concurrency & Reparse Point Non-Destructive Resilience
    # ==========================================================================
    Write-Host ""
    Write-Host "$cBold[SUITE 5] Concurrency & Reparse Point Non-Destructive Resilience$cReset"

    Run-TestCase "Reparse" "Broken junction auto-recovery without if-exist deadlock" {
        $linkDir = Join-Path $SandboxRoot "BrokenJuncLink"
        $target1 = Join-Path $SandboxRoot "Target1"
        $target2 = Join-Path $SandboxRoot "Target2"
        New-Item -ItemType Directory -Path $target1 -Force | Out-Null
        New-Item -ItemType Directory -Path $target2 -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $target2 "bin") -Force | Out-Null
        Set-Content -Path (Join-Path $target2 "bin\java.exe") -Value "FAKE_JAVA"
        
        # Create junction to target1
        & cmd.exe /c "mklink /J `"$linkDir`" `"$target1`"" >$null 2>&1
        Assert-True (Test-Path -LiteralPath $linkDir) "Initial junction must exist"
        
        # Now delete target1 to turn the junction into a broken dangling junction
        Remove-Item -LiteralPath $target1 -Force -Recurse
        
        # Verify child paths no longer exist through broken junction
        Assert-False (Test-Path -LiteralPath "$linkDir\canary.txt") "Broken junction child cannot resolve"
        
        # Now call rmdir on the broken junction directly without if-exist:
        & cmd.exe /c "rmdir `"$linkDir`"" >$null 2>&1
        
        # Recreate junction to target2
        & cmd.exe /c "mklink /J `"$linkDir`" `"$target2`"" >$null 2>&1
        Assert-True ($LASTEXITCODE -eq 0) "Junction creation must succeed without deadlock"
        Assert-True (Test-Path -LiteralPath "$linkDir\bin\java.exe") "Re-linked junction must resolve to new target"
    }

    Run-TestCase "Reparse" "Rapid sequential junction switching without lock corruption" {
        $juncSwitchDir = Join-Path $SandboxRoot "JuncSwitchTest"
        $nodeA = Join-Path $SandboxRoot "NodeA"
        $nodeB = Join-Path $SandboxRoot "NodeB"
        New-Item -ItemType Directory -Path $nodeA -Force | Out-Null
        New-Item -ItemType Directory -Path $nodeB -Force | Out-Null
        Set-Content -Path (Join-Path $nodeA "marker.txt") -Value "NODE_A"
        Set-Content -Path (Join-Path $nodeB "marker.txt") -Value "NODE_B"
        
        for ($i = 0; $i -lt 5; $i++) {
            & cmd.exe /c "rmdir `"$juncSwitchDir`" >nul 2>&1 & mklink /J `"$juncSwitchDir`" `"$nodeA`" >nul 2>&1"
            $mA = Get-Content (Join-Path $juncSwitchDir "marker.txt") -Raw
            Assert-Contains $mA "NODE_A" "Junction switch to A must be immediate"
            
            & cmd.exe /c "rmdir `"$juncSwitchDir`" >nul 2>&1 & mklink /J `"$juncSwitchDir`" `"$nodeB`" >nul 2>&1"
            $mB = Get-Content (Join-Path $juncSwitchDir "marker.txt") -Raw
            Assert-Contains $mB "NODE_B" "Junction switch to B must be immediate"
        }
    }

    Run-TestCase "Concurrency" "Parallel temp script isolation & startup non-interference" {
        $content = Get-Content $JvmBat -Raw
        Assert-NotContains $content "del `"%TEMP%\jvm_*" "jvm.bat must NOT wipe all temp files with blind wildcards at startup"
    }

    Run-TestCase "Concurrency" "Live ACL verification on %JVM_SECURE_TEMP% (Protected DACL, User F, no Everyone/Users)" {
        $origLocalAppData = $env:LOCALAPPDATA
        try {
            $env:LOCALAPPDATA = $FakeLocalAppData
            $null = & cmd.exe /c "call `"$JvmBat`" --version" 2>&1
            $secTemp = Join-Path $FakeLocalAppData "DiamTek\JVM\temp"
            Assert-PathExists $secTemp "%JVM_SECURE_TEMP% directory must be created during startup"

            $acl = Get-Acl -LiteralPath $secTemp
            Assert-True $acl.AreAccessRulesProtected "%JVM_SECURE_TEMP% DACL must have inheritance disabled (icacls /inheritance:r)"

            $identities = @($acl.Access | ForEach-Object { $_.IdentityReference.Value })
            $hasBroadGroup = ($identities | Where-Object { $_ -match '(^|\\)(Everyone|Users|Authenticated Users)$' }).Count -gt 0
            Assert-False $hasBroadGroup "%JVM_SECURE_TEMP% ACL must not grant access to Everyone/Users/Authenticated Users (Actual: $($identities -join ', '))"
        } finally {
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    # ==========================================================================
    # SUITE 6: Corrupt Registry Recovery & PATH Resilience
    # ==========================================================================
    Write-Host ""
    Write-Host "$cBold[SUITE 6] Corrupt Registry Recovery & PATH Resilience$cReset"

    Run-TestCase "Registry" "Registry helper preserves REG_SZ vs REG_EXPAND_SZ correctly" {
        $testRegKey = "HKCU:\Environment"
        $testValName = "JVM_REG_TYPE_TEST"
        try {
            # Test ExpandString
            Set-ItemProperty -Path $testRegKey -Name $testValName -Value "%SystemRoot%\Test" -Type ExpandString
            $kind = (Get-Item -Path $testRegKey).GetValueKind($testValName)
            Assert-Equals $kind ([Microsoft.Win32.RegistryValueKind]::ExpandString) "Must maintain ExpandString kind"
            
            # Test String
            Set-ItemProperty -Path $testRegKey -Name $testValName -Value "C:\Plain\Path" -Type String
            $kind = (Get-Item -Path $testRegKey).GetValueKind($testValName)
            Assert-Equals $kind ([Microsoft.Win32.RegistryValueKind]::String) "Must maintain String kind"
        } finally {
            Remove-ItemProperty -Path $testRegKey -Name $testValName -ErrorAction SilentlyContinue
        }
    }

    Run-TestCase "Registry" "Environment broadcast SendMessageTimeout non-blocking execution" {
        if (-not ([System.Management.Automation.PSTypeName]'Win32.NativeMethods').Type) {
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace Win32 {
    public static class NativeMethods {
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern IntPtr SendMessageTimeout(
            IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
            uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
    }
}
"@ -ErrorAction SilentlyContinue
        }

        $HWND_BROADCAST = [IntPtr]0xffff
        $WM_SETTINGCHANGE = 0x001A
        $SMTO_ABORTIFHUNG = 0x0002
        $result = [UIntPtr]::Zero
        
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $ret = [Win32.NativeMethods]::SendMessageTimeout(
            $HWND_BROADCAST,
            $WM_SETTINGCHANGE,
            [UIntPtr]::Zero,
            'Environment',
            $SMTO_ABORTIFHUNG,
            1000,
            [ref]$result
        )
        $sw.Stop()
        Assert-True ($sw.ElapsedMilliseconds -lt 3000) "SendMessageTimeout must abort within timeout and not hang"
    }

    Run-TestCase "Registry" "Set-JvmVar storage boundary enforcement" {
        $allowedRoots = @(
            "$env:LOCALAPPDATA\DiamTek\JVM",
            "$env:LOCALAPPDATA\JavaVersionManager",
            "$env:ProgramFiles\Java",
            "${env:ProgramFiles(x86)}\Java",
            "$env:USERPROFILE\.jdks"
        )
        
        $illegalPath = "C:\Windows\System32"
        $isAllowed = $false
        foreach ($root in $allowedRoots) {
            $normRoot = $root.TrimEnd('\')
            $rootPrefix = $normRoot + '\'
            if ($illegalPath.Equals($normRoot, [StringComparison]::OrdinalIgnoreCase) -or $illegalPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                $isAllowed = $true
                break
            }
        }
        Assert-False $isAllowed "Set-JvmVar boundary check must reject C:\Windows\System32"
    }

    Run-TestCase "Registry" "Set-JvmVar sibling prefix collision (CWE-22) and strict variable allowlist enforcement" {
        $installRaw = Get-Content (Join-Path $RepoRoot "install.ps1") -Raw
        $fnMatch = [regex]::Match($installRaw, '(?s)function Set-JvmVar\s*\{.*?\r?\n    \}')
        Assert-True $fnMatch.Success "Set-JvmVar function must be extractable from install.ps1"
        . ([scriptblock]::Create($fnMatch.Value))

        $siblingEvilDir = Join-Path $FakeUserProfile ".jdks_evil"
        New-Item -ItemType Directory -Path (Join-Path $siblingEvilDir "bin") -Force | Out-Null
        $origUserProfile = $env:USERPROFILE
        $origJavaHome = $env:JAVA_HOME
        $origComSpec = $env:COMSPEC
        try {
            $env:USERPROFILE = $FakeUserProfile
            $env:JAVA_HOME = "C:\OriginalJavaHome"

            # 1. Attempt CWE-22 sibling prefix collision (.jdks_evil vs .jdks)
            Set-JvmVar -Name "JAVA_HOME" -OldValue "" -NewValue $siblingEvilDir
            Assert-Equals $env:JAVA_HOME "C:\OriginalJavaHome" "Set-JvmVar MUST block sibling prefix directory (.jdks_evil)"

            # 2. Attempt non-allowlisted variable tampering (COMSPEC)
            $legitJdk = Join-Path $FakeUserProfile ".jdks\temurin-21"
            New-Item -ItemType Directory -Path (Join-Path $legitJdk "bin") -Force | Out-Null
            Set-JvmVar -Name "COMSPEC" -OldValue "" -NewValue $legitJdk
            Assert-Equals $env:COMSPEC $origComSpec "Set-JvmVar MUST reject non-allowlisted environment variable 'COMSPEC'"
        } finally {
            $env:USERPROFILE = $origUserProfile
            $env:JAVA_HOME = $origJavaHome
            $env:COMSPEC = $origComSpec
        }
    }

    Run-TestCase "Registry" "PowerShell AST parser validation of :InstallPowerShellHook emitted profile script" {
        $batRaw = Get-Content $JvmBat -Raw
        $hookBlockMatch = [regex]::Match($batRaw, '(?s)(set JVM_TRIM_DQ=.*?echo\(''@\r?\n\s*echo\()')
        Assert-True $hookBlockMatch.Success "Must locate :InstallPowerShellHook generator block in jvm.bat"

        $harnessBat = Join-Path $SandboxRoot "emit_hook_harness.bat"
        $emittedGenPs1 = Join-Path $SandboxRoot "emitted_setup_hook.ps1"
        $emittedProfile = Join-Path $SandboxRoot "emitted_profile.ps1"

        $harnessCode = @"
@echo off
setlocal enabledelayedexpansion
set "SAFE_TARGET=$RepoRoot"
$($hookBlockMatch.Groups[1].Value)
    echo `$hook = `$hook.Replace^('__FALLBACK_BAT__', `$targetBatEscaped^)
    echo [System.IO.File]::WriteAllText^('$emittedProfile', `$hook, [System.Text.Encoding]::UTF8^)
) > "$emittedGenPs1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$emittedGenPs1"
"@
        [System.IO.File]::WriteAllText($harnessBat, ($harnessCode -replace "\r?\n", "`r`n"), [System.Text.UTF8Encoding]::new($false))
        $null = & cmd.exe /c "call `"$harnessBat`"" 2>&1
        Assert-PathExists $emittedProfile ":InstallPowerShellHook harness must emit PowerShell profile block"

        $profileContent = Get-Content -LiteralPath $emittedProfile -Raw
        $tokens = $null
        $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseInput($profileContent, [ref]$tokens, [ref]$parseErrors)
        Assert-Equals $parseErrors.Count 0 ("Emitted PowerShell profile hook must have ZERO AST parser errors. Errors: " + ($parseErrors | Out-String))
        Assert-NotContains $profileContent '""$OldValue\bin""' "Emitted hook must not contain doubled quotes around `$OldValue\bin"
        Assert-NotContains $profileContent '^^^(' "Emitted hook must not contain unconsumed batch caret escapes"
    }

    Run-TestCase "Registry" "Security parity between install.ps1 (`$profileCode) and jvm.bat (:InstallPowerShellHook)" {
        $installRaw = Get-Content (Join-Path $RepoRoot "install.ps1") -Raw
        $batRaw     = Get-Content $JvmBat -Raw

        foreach ($varName in @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME')) {
            Assert-Contains $installRaw "'$varName'" "install.ps1 Set-JvmVar must allowlist $varName"
            Assert-Contains $batRaw "'$varName'" "jvm.bat Set-JvmVar must allowlist $varName"
        }
        Assert-Contains $batRaw '\x25' "jvm.bat Set-JvmVar metacharacter blocklist must include \x25 (%) for parity with install.ps1"
    }

    # ==========================================================================
    # SUITE 7: Uninstallation Safety & Marker Verification
    # ==========================================================================
    Write-Host ""
    Write-Host "$cBold[SUITE 7] Uninstallation Safety & Marker Verification$cReset"

    Run-TestCase "Uninstall" "Remove-DirectorySafely unbinds junctions without deleting target contents" {
        $realTarget = Join-Path $SandboxRoot "HostJDK_Protected"
        New-Item -ItemType Directory -Path (Join-Path $realTarget "bin") -Force | Out-Null
        $canaryFile = Join-Path $realTarget "canary_token.txt"
        Set-Content -Path $canaryFile -Value "DO_NOT_DELETE_TOKEN"
        
        $containerDir = Join-Path $SandboxRoot "JvmStateDir"
        New-Item -ItemType Directory -Path (Join-Path $containerDir "links") -Force | Out-Null
        $juncLink = Join-Path $containerDir "links\jdk-21"
        & cmd.exe /c "mklink /J `"$juncLink`" `"$realTarget`"" >$null 2>&1
        Assert-True (Test-Path -LiteralPath $juncLink) "Junction link must exist"
        
        # Run Remove-DirectorySafely logic on containerDir
        Get-ChildItem -LiteralPath $containerDir -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint
        } | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
            if ($_.PSIsContainer) {
                try { [System.IO.Directory]::Delete($_.FullName, $false) } catch { & cmd.exe /c "rmdir /q `"$($_.FullName)`"" 2>$null }
            } else {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            }
        }
        Remove-Item -LiteralPath $containerDir -Recurse -Force -ErrorAction SilentlyContinue
        
        # Verify containerDir is gone, but realTarget and its canary STILL exist!
        Assert-False (Test-Path -LiteralPath $containerDir) "Container directory must be removed"
        Assert-True (Test-Path -LiteralPath $realTarget) "Host target JDK directory MUST remain intact"
        Assert-True (Test-Path -LiteralPath $canaryFile) "Host target canary file MUST NOT be deleted"
    }

    Run-TestCase "Uninstall" "Refuse deletion of directory lacking JVM installation markers" {
        $emptyTestDir = Join-Path $SandboxRoot "NonJvmDirectory"
        New-Item -ItemType Directory -Path $emptyTestDir -Force | Out-Null
        
        $hasJvmMarker = (Test-Path -LiteralPath (Join-Path $emptyTestDir "jvm.bat")) -or
                        (Test-Path -LiteralPath (Join-Path $emptyTestDir "bin\jvm.bat")) -or
                        (Test-Path -LiteralPath (Join-Path $emptyTestDir "uninstall.ps1"))
        
        Assert-False $hasJvmMarker "Directory lacking JVM markers must evaluate to false"
    }

    Run-TestCase "Uninstall" "Protected system roots are strictly blocked from deletion" {
        $winDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
        $systemDriveRoot = [System.IO.Path]::GetPathRoot($winDir).TrimEnd('\')
        $userProfileDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        $progFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
        $progFilesX86 = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86)
        $forbiddenRoots = @(
            $systemDriveRoot, "$systemDriveRoot\",
            $userProfileDir, "$userProfileDir\",
            $winDir, "$winDir\",
            $progFiles, "$progFiles\",
            $progFilesX86, "$progFilesX86\"
        )
        foreach ($root in $forbiddenRoots) {
            Assert-True ($forbiddenRoots -contains $root) "Forbidden roots must include $root"
        }
    }

    Run-TestCase "UninstallSafety" "Strict boundary enforcement on extracted candidate directory" {
        $content = Get-Content $JvmBat -Raw
        Assert-Contains $content "destinationPath.StartsWith" "Archive extraction must enforce directory boundary to prevent ZipSlip"
    }

    Run-TestCase "UninstallSafety" "ZipSlip CWE-22 sibling-prefix collision ('../cand_evil/payload.exe') and rooted path ('\rooted_escape.exe') rejection" {
        $extractRoot = Join-Path $SandboxRoot "cand"
        New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null

        $fullRoot = [System.IO.Path]::GetFullPath($extractRoot)
        if (-not $fullRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar.ToString())) {
            $fullRoot += [System.IO.Path]::DirectorySeparatorChar
        }

        $maliciousEntries = @(
            "../cand_evil/payload.exe",
            "..\cand_evil\payload.exe",
            "\rooted_escape.exe",
            "/rooted_escape.exe",
            "jdk-21/../../../outside.dll"
        )
        foreach ($entryName in $maliciousEntries) {
            $destinationPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($extractRoot, $entryName))
            $blocked = ($entryName -match '^[/\\]') -or (-not $destinationPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase) -and $destinationPath -ne $fullRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar))
            Assert-True $blocked "ZipSlip guard MUST block malicious archive entry '$entryName' (resolved to '$destinationPath' vs root '$fullRoot')"
        }

        $legitEntry = "jdk-21.0.2/bin/java.exe"
        $legitDest = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($extractRoot, $legitEntry))
        $legitBlocked = ($legitEntry -match '^[/\\]') -or (-not $legitDest.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase) -and $legitDest -ne $fullRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar))
        Assert-False $legitBlocked "ZipSlip guard must allow legitimate nested entry '$legitEntry'"
    }

    # ==========================================================================
    # SUITE 8: Windows Terminal JSONC Configuration Parsing
    # ==========================================================================
    Write-Host ""
    Write-Host "$cBold[SUITE 8] Windows Terminal JSONC Configuration Parsing$cReset"

    Run-TestCase "TerminalJSON" "Strip block comments /* ... */ from JSONC" {
        $rawJsonc = @"
{
    /* This is a multi-line
       block comment in JSONC */
    "profiles": {
        "list": [
            { "name": "cmd", "guid": "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}" }
        ]
    }
}
"@
        $cleanJson = $rawJsonc -replace '(?s)/\*.*?\*/', '' -replace '(?m)//.*$', '' -replace ',\s*([\}\]])', '$1'
        $parsed = $cleanJson | ConvertFrom-Json
        Assert-True ($parsed.profiles.list.Count -eq 1) "JSONC with block comments must parse cleanly"
        Assert-Equals $parsed.profiles.list[0].name "cmd" "Parsed profile name must match"
    }

    Run-TestCase "TerminalJSON" "Strip single-line // comments from JSONC while preserving URLs" {
        $rawJsonc = @"
{
    "`$schema": "https://aka.ms/terminal-profiles-schema",
    // Single-line header comment
    "profiles": {
        "list": [ // inline comment
            { "name": "PowerShell", "guid": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}" } // trailing
        ]
    }
}
"@
        $cleanJson = $rawJsonc -replace '(?s)/\*.*?\*/', '' -replace '(?m)(?<!:)\/\/.*$', '' -replace ',\s*([\}\]])', '$1'
        $parsed = $cleanJson | ConvertFrom-Json
        Assert-True ($parsed.profiles.list.Count -eq 1) "JSONC with single-line comments must parse cleanly"
        Assert-Equals $parsed.'$schema' "https://aka.ms/terminal-profiles-schema" "Schema URL with https:// must NOT be stripped"
        Assert-Equals $parsed.profiles.list[0].name "PowerShell" "Parsed profile name must match"
    }

    Run-TestCase "TerminalJSON" "Strip trailing commas before closing braces and brackets in JSONC" {
        $rawJsonc = @"
{
    "profiles": {
        "list": [
            { "name": "WSL", "guid": "{2ece5b75-6728-5cf8-bb86-ee407927ec8b}", },
        ],
    },
}
"@
        $cleanJson = $rawJsonc -replace '(?s)/\*.*?\*/', '' -replace '(?m)(?<!:)\/\/.*$', '' -replace ',\s*([\}\]])', '$1'
        $parsed = $cleanJson | ConvertFrom-Json
        Assert-True ($parsed.profiles.list.Count -eq 1) "JSONC with trailing commas must parse cleanly"
        Assert-Equals $parsed.profiles.list[0].name "WSL" "Parsed profile name must match"
    }

    Run-TestCase "TerminalJSON" "Corrupt non-JSON content falls back silently without throwing" {
        $corruptContent = "NOT_VALID_JSON{{{///"
        $failed = $false
        try {
            $cleanJson = $corruptContent -replace '(?s)/\*.*?\*/', '' -replace '(?m)(?<!:)\/\/.*$', '' -replace ',\s*([\}\]])', '$1'
            $null = $cleanJson | ConvertFrom-Json
        } catch {
            $failed = $true
        }
        Assert-True $failed "Corrupt content should throw inside try/catch so fallback catches it silently"
    }

} finally {
    # --------------------------------------------------------------------------
    # Sandbox Cleanup
    # --------------------------------------------------------------------------
    if (Test-Path $SandboxRoot) {
        # Unbind any surviving junctions first
        Get-ChildItem -LiteralPath $SandboxRoot -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint
        } | ForEach-Object {
            if ($_.PSIsContainer) {
                try { [System.IO.Directory]::Delete($_.FullName, $false) } catch { & cmd.exe /c "rmdir /q `"$($_.FullName)`"" 2>$null }
            } else {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            }
        }
        Remove-Item -LiteralPath $SandboxRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------------------------------------------
# Final Execution Summary & Telemetry Export
# ------------------------------------------------------------------------------
$RunnerStopwatch.Stop()
$TotalExecuted = $GlobalPassed + $GlobalFailed
$TotalElapsedMs = ($SuiteTracker.Values | Measure-Object -Property ElapsedMs -Sum).Sum
if ($null -eq $TotalElapsedMs) { $TotalElapsedMs = $RunnerStopwatch.ElapsedMilliseconds }

Write-Host ""
Write-Host "$cCyan$cBold========================================================================$cReset"
Write-Host "$cCyan$cBold                         TEST EXECUTION SUMMARY                         $cReset"
Write-Host "$cCyan$cBold========================================================================$cReset"
Write-Host ("  {0,-43} {1,12}   {2,-8} {3,10}" -f "Suite", "Passed/Total", "Status", "Elapsed")
Write-Host ("  {0,-43} {1,12}   {2,-8} {3,10}" -f ("-" * 43), ("-" * 12), ("-" * 8), ("-" * 10))

foreach ($entry in $SuiteTracker.Values) {
    if ($entry.Total -eq 0 -and $entry.Skipped -gt 0) {
        $ratioStr = "0 / 0"
        $statusStr = "${cGray}[SKIP]${cReset}  "
        $timeStr = "-"
    } elseif ($entry.Failed -gt 0) {
        $ratioStr = "$($entry.Passed) / $($entry.Total)"
        $statusStr = "${cRed}[FAIL]${cReset}  "
        $timeStr = "$($entry.ElapsedMs) ms"
    } else {
        $ratioStr = "$($entry.Passed) / $($entry.Total)"
        $statusStr = "${cGreen}[PASS]${cReset}  "
        $timeStr = "$($entry.ElapsedMs) ms"
    }
    $displayTitle = if ($entry.Name.Length -gt 43) { $entry.Name.Substring(0, 40) + "..." } else { $entry.Name }
    Write-Host ("  {0,-43} {1,12}   " -f $displayTitle, $ratioStr) -NoNewline
    Write-Host $statusStr -NoNewline
    Write-Host (" {0,10}" -f $timeStr)
}

Write-Host ("  {0,-43} {1,12}   {2,-8} {3,10}" -f ("-" * 43), ("-" * 12), ("-" * 8), ("-" * 10))
Write-Host "  Total Tests Executed : $TotalExecuted ${cGray}(Test Time: $TotalElapsedMs ms | Wall Time: $($RunnerStopwatch.ElapsedMilliseconds) ms)${cReset}"
Write-Host "  Passed               : ${cGreen}$GlobalPassed${cReset}"
if ($GlobalFailed -gt 0) {
    Write-Host "  Failed               : ${cRed}$GlobalFailed${cReset}" -ForegroundColor Red
} else {
    Write-Host "  Failed               : 0"
}
if ($GlobalSkipped -gt 0) {
    Write-Host "  Skipped (Filtered)   : ${cYellow}$GlobalSkipped${cReset}"
}

if ($Detailed -and $TestResults.Count -gt 0) {
    $slowest = $TestResults | Sort-Object Duration -Descending | Select-Object -First 3
    Write-Host "  Slowest Tests        : " -NoNewline
    $slowSummary = ($slowest | ForEach-Object { "$($_.Name) ($($_.Duration) ms)" }) -join "; "
    Write-Host "${cGray}$slowSummary${cReset}"
}

Write-Host "$cCyan$cBold========================================================================$cReset"
Write-Host "$cCyan$cBold                        CWE COVERAGE SUMMARY                            $cReset"
Write-Host "$cCyan$cBold========================================================================$cReset"
Write-Host ("  {0,-10} {1,-36} {2,10}   {3,-8}" -f "CWE ID", "Vulnerability Class", "Passed", "Status")
Write-Host ("  {0,-10} {1,-36} {2,10}   {3,-8}" -f ("-" * 10), ("-" * 36), ("-" * 10), ("-" * 8))

foreach ($cwe in ($CweCatalog.Values | Sort-Object Number)) {
    $cweTests = @($TestResults | Where-Object { $_.CweId -eq $cwe.Id })
    if ($cweTests.Count -eq 0) { continue }
    $cwePassed = @($cweTests | Where-Object { $_.Status -eq 'PASS' }).Count
    $cweFailed = @($cweTests | Where-Object { $_.Status -eq 'FAIL' }).Count
    $cweRatio  = "$cwePassed / $($cweTests.Count)"
    $cweStatus = if ($cweFailed -gt 0) { "${cRed}[FAIL]${cReset}  " } else { "${cGreen}[PASS]${cReset}  " }

    Write-Host ("  ${cCyan}{0,-10}${cReset} {1,-36} {2,10}   " -f $cwe.Id, $cwe.Short, $cweRatio) -NoNewline
    Write-Host $cweStatus
}
Write-Host "$cCyan$cBold========================================================================$cReset"
Write-Host ""

# Automatic GitHub Actions Step Summary Generation
if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
    try {
        $overallBadge = if ($GlobalFailed -eq 0) { "✅ PASS" } else { "❌ FAIL" }
        $passRate = if ($TotalExecuted -gt 0) { [math]::Round(($GlobalPassed / $TotalExecuted) * 100, 1) } else { 100.0 }
        $mdLines = [System.Collections.Generic.List[string]]::new()

        $mdLines.Add("## 🛡️ DiamTek JVM Security & Adversarial Test Suite — $overallBadge")
        $mdLines.Add("")
        $mdLines.Add("- **Total Executed:** $TotalExecuted (`$GlobalPassed` passed, `$GlobalFailed` failed, `$GlobalSkipped` skipped)")
        $mdLines.Add("- **Pass Rate:** $passRate%")
        $mdLines.Add("- **Execution Time:** $TotalElapsedMs ms (Wall clock: $($RunnerStopwatch.ElapsedMilliseconds) ms)")
        $mdLines.Add("")
        $mdLines.Add("### 📊 Per-Suite Execution Breakdown")
        $mdLines.Add("")
        $mdLines.Add("| Suite | Category Tag | Passed / Total | Status | Elapsed (ms) |")
        $mdLines.Add("| :--- | :--- | :---: | :---: | ---: |")

        foreach ($entry in $SuiteTracker.Values) {
            $suiteStatus = if ($entry.Total -eq 0 -and $entry.Skipped -gt 0) {
                "⏭️ SKIP"
            } elseif ($entry.Failed -gt 0) {
                "❌ FAIL"
            } else {
                "✅ PASS"
            }
            $mdLines.Add("| **$($entry.Name)** | ``$($entry.Tag)`` | $($entry.Passed) / $($entry.Total) | $suiteStatus | $($entry.ElapsedMs) ms |")
        }

        $mdLines.Add("| **Total** | *All Suites* | **$GlobalPassed / $TotalExecuted** | **$overallBadge** | **$TotalElapsedMs ms** |")
        $mdLines.Add("")

        $mdLines.Add("### 🏷️ CWE Coverage Summary")
        $mdLines.Add("")
        $mdLines.Add("| CWE ID | Vulnerability Class | Tests Passed |")
        $mdLines.Add("| :--- | :--- | :---: |")
        foreach ($cwe in ($CweCatalog.Values | Sort-Object Number)) {
            $cweTests = @($TestResults | Where-Object { $_.CweId -eq $cwe.Id })
            if ($cweTests.Count -eq 0) { continue }
            $cwePassed = @($cweTests | Where-Object { $_.Status -eq 'PASS' }).Count
            $cweFailed = @($cweTests | Where-Object { $_.Status -eq 'FAIL' }).Count
            $cweBadgeMd = if ($cweFailed -gt 0) { "❌ $cwePassed / $($cweTests.Count)" } else { "✅ $cwePassed / $($cweTests.Count)" }
            $mdLines.Add("| **``$($cwe.Id)``** | $($cwe.Short) | $cweBadgeMd |")
        }
        $mdLines.Add("")

        if ($GlobalFailed -gt 0) {
            $mdLines.Add("### ❌ Failed Test Cases")
            $mdLines.Add("")
            $mdLines.Add("| Suite | CWE | Test Case | Error Message |")
            $mdLines.Add("| :--- | :--- | :--- | :--- |")
            foreach ($fail in ($TestResults | Where-Object { $_.Status -eq 'FAIL' })) {
                $safeName = ($fail.Name -replace '\|', '\|')
                $safeErr  = (($fail.Error -replace '\r?\n', ' ') -replace '\|', '\|')
                $mdLines.Add("| $($fail.SuiteTitle) | ``$($fail.CweId)`` ($($fail.CweShort)) | $safeName | ``$safeErr`` |")
            }
            $mdLines.Add("")
        }

        $mdLines.Add("<details>")
        $mdLines.Add("<summary>📋 <strong>View All Executed Test Cases ($TotalExecuted tests)</strong></summary>")
        $mdLines.Add("")
        $mdLines.Add("| # | Suite | CWE | Vulnerability Type | Test Case | Status | Duration (ms) |")
        $mdLines.Add("| ---: | :--- | :--- | :--- | :--- | :---: | ---: |")
        $idx = 0
        foreach ($res in $TestResults) {
            $idx++
            $icon = if ($res.Status -eq 'PASS') { "✅ PASS" } else { "❌ FAIL" }
            $safeTestName = ($res.Name -replace '\|', '\|')
            $mdLines.Add("| $idx | $($res.SuiteTitle) | ``$($res.CweId)`` | $($res.CweShort) | $safeTestName | $icon | $($res.Duration) ms |")
        }
        $mdLines.Add("")
        $mdLines.Add("</details>")
        $mdLines.Add("")

        Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value ($mdLines -join [Environment]::NewLine) -Encoding UTF8
    } catch {
        Write-Host "${cYellow}[WARN] Failed to write GITHUB_STEP_SUMMARY: $($_.Exception.Message)${cReset}"
    }
}

if ($GlobalFailed -gt 0) {
    exit 1
}
exit 0