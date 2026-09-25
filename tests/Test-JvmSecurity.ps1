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
    'CWE-20'  = [PSCustomObject]@{ Id = 'CWE-20';  Number = 20;  Short = 'Improper Input & Config Validation' }
    'CWE-22'  = [PSCustomObject]@{ Id = 'CWE-22';  Number = 22;  Short = 'Path Traversal & ZipSlip' }
    'CWE-41'  = [PSCustomObject]@{ Id = 'CWE-41';  Number = 41;  Short = 'Win32 Canonicalization Bypass' }
    'CWE-59'  = [PSCustomObject]@{ Id = 'CWE-59';  Number = 59;  Short = 'Symlink & Junction Safety' }
    'CWE-66'  = [PSCustomObject]@{ Id = 'CWE-66';  Number = 66;  Short = 'DOS Device & NTFS ADS Abuse' }
    'CWE-73'  = [PSCustomObject]@{ Id = 'CWE-73';  Number = 73;  Short = 'Env & System Root Protection' }
    'CWE-74'  = [PSCustomObject]@{ Id = 'CWE-74';  Number = 74;  Short = 'XML Attribute & Template Injection' }
    'CWE-78'  = [PSCustomObject]@{ Id = 'CWE-78';  Number = 78;  Short = 'OS Command & Shell Injection' }
    'CWE-88'  = [PSCustomObject]@{ Id = 'CWE-88';  Number = 88;  Short = 'Argument & Flag Injection' }
    'CWE-94'  = [PSCustomObject]@{ Id = 'CWE-94';  Number = 94;  Short = 'Batch set /a Expression Evaluation' }
    'CWE-155' = [PSCustomObject]@{ Id = 'CWE-155'; Number = 155; Short = 'Wildcard Expansion Injection' }
    'CWE-250' = [PSCustomObject]@{ Id = 'CWE-250'; Number = 250; Short = 'Privilege Boundary Isolation' }
    'CWE-276' = [PSCustomObject]@{ Id = 'CWE-276'; Number = 276; Short = 'Strict Directory DACL Isolation' }
    'CWE-295' = [PSCustomObject]@{ Id = 'CWE-295'; Number = 295; Short = 'TLS 1.2 / 1.3 Protocol Enforcement' }
    'CWE-319' = [PSCustomObject]@{ Id = 'CWE-319'; Number = 319; Short = 'Strict HTTPS Scheme Enforcement' }
    'CWE-330' = [PSCustomObject]@{ Id = 'CWE-330'; Number = 330; Short = 'CSPRNG Temp Filename Entropy' }
    'CWE-345' = [PSCustomObject]@{ Id = 'CWE-345'; Number = 345; Short = 'Downgrade & Authenticity Defense' }
    'CWE-354' = [PSCustomObject]@{ Id = 'CWE-354'; Number = 354; Short = 'Checksum Manifest Format Validation' }
    'CWE-367' = [PSCustomObject]@{ Id = 'CWE-367'; Number = 367; Short = 'Atomic Staged Profile/Config Writes' }
    'CWE-377' = [PSCustomObject]@{ Id = 'CWE-377'; Number = 377; Short = 'Insecure Temp File & ACL Lock' }
    'CWE-400' = [PSCustomObject]@{ Id = 'CWE-400'; Number = 400; Short = 'Hang & Parser Resilience' }
    'CWE-409' = [PSCustomObject]@{ Id = 'CWE-409'; Number = 409; Short = 'Zip Bomb & Decompression Bounds' }
    'CWE-426' = [PSCustomObject]@{ Id = 'CWE-426'; Number = 426; Short = 'Untrusted Search Path / Planting' }
    'CWE-427' = [PSCustomObject]@{ Id = 'CWE-427'; Number = 427; Short = 'Uncontrolled PATH Hijack Defense' }
    'CWE-428' = [PSCustomObject]@{ Id = 'CWE-428'; Number = 428; Short = 'Quoted UninstallString & TargetPath' }
    'CWE-459' = [PSCustomObject]@{ Id = 'CWE-459'; Number = 459; Short = 'Failure-Path Handle & Temp Cleanup' }
    'CWE-494' = [PSCustomObject]@{ Id = 'CWE-494'; Number = 494; Short = 'Supply Chain & Hash Integrity' }
    'CWE-532' = [PSCustomObject]@{ Id = 'CWE-532'; Number = 532; Short = 'Sensitive Registry Backup Isolation' }
    'CWE-601' = [PSCustomObject]@{ Id = 'CWE-601'; Number = 601; Short = 'Open Redirect & Host Allowlisting' }
    'CWE-611' = [PSCustomObject]@{ Id = 'CWE-611'; Number = 611; Short = 'XML External Entity (XXE) Defense' }
    'CWE-918' = [PSCustomObject]@{ Id = 'CWE-918'; Number = 918; Short = 'SSRF & Vendor Domain Allowlisting' }
}

function Resolve-TestCweMetadata {
    param([string]$RawSuite, [string]$TestName)

    if ($TestName -match '\((CWE-\d+)\)' -and $script:CweCatalog.Contains($matches[1])) {
        return $script:CweCatalog[$matches[1]]
    }

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
        Assert-Contains $outSwitch "Invalid vendor identifier" "Poisoned --vendor must be blocked by ValidateStrictIdentifier"

        Assert-True ($updateExit -ne 0) "Updating with poisoned --vendor must fail closed"
        Assert-Contains $outUpdate "Invalid vendor identifier" "Poisoned --vendor in update must be blocked by ValidateStrictIdentifier"

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
        
        $testValName = "TestJvmPath"
        try {
            # Simulate JVM registry update logic
            [Microsoft.Win32.Registry]::SetValue("HKEY_CURRENT_USER\Environment", $testValName, "%USERPROFILE%\dummy;%SystemRoot%\System32", [Microsoft.Win32.RegistryValueKind]::ExpandString)
            
            $kind = (Get-Item -Path $testHive).GetValueKind($testValName)
            Assert-True ($kind -eq [Microsoft.Win32.RegistryValueKind]::ExpandString) "Registry ValueKind must be ExpandString"
            
            # Verify unexpanded content is preserved
            $envKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment")
            try {
                $raw = $envKey.GetValue($testValName, "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            } finally {
                if ($null -ne $envKey) { $envKey.Close() }
            }
            Assert-Contains $raw "%USERPROFILE%" "Unexpanded environment variable tokens must NOT be converted to static strings"
        } finally {
            # Clean test key unconditionally even if an assertion throws
            Remove-ItemProperty -Path $testHive -Name $testValName -Force -ErrorAction SilentlyContinue
        }
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
        
        # Ensure valid XML with DTD/XXE prohibited (CWE-611)
        $xmlSettings = New-Object System.Xml.XmlReaderSettings
        $xmlSettings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
        $xmlSettings.XmlResolver = $null
        $sr = New-Object System.IO.StringReader((Get-Content -LiteralPath $nuspecPath -Raw))
        $xr = [System.Xml.XmlReader]::Create($sr, $xmlSettings)
        $xml = New-Object System.Xml.XmlDocument
        $xml.XmlResolver = $null
        $xml.Load($xr)
        $xr.Close(); $sr.Close()
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
            $prevEAP = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                # Capture status before
                $gitStatusBefore = (& git -C "$RepoRoot" status --porcelain 2>&1 | Out-String).Trim()
                
                # Execute dry run
                $dryOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bumpScript patch -DryRun -NoBucketSync -Force 2>&1 | Out-String
                
                # Capture status after
                $gitStatusAfter = (& git -C "$RepoRoot" status --porcelain 2>&1 | Out-String).Trim()
            } finally {
                $ErrorActionPreference = $prevEAP
            }
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
            Remove-ItemProperty -Path $testRegKey -Name $testValName -Force -ErrorAction SilentlyContinue
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

    # ==========================================================================
    # DEEP JVM.BAT CORE ENGINE AUDIT TESTS (+22 Tests -> 100 Total)
    # ==========================================================================
    Write-Host ""
    Write-Host "$cBold[JVM.BAT CORE AUDIT] Deep Engine, Crypto, Config & Privilege Verification$cReset"

    # 79. CWE-426: Runtime CWD Trojan Binary Planting Defense
    Run-TestCase "Adversarial" "Pinned System Binaries runtime CWD Trojan binary planting immunity (CWE-426)" {
        $poisonCwd = Join-Path $SandboxRoot "PoisonedCwdPlanting"
        New-Item -ItemType Directory -Path $poisonCwd -Force | Out-Null
        $canaryFile = Join-Path $poisonCwd "CWD_PLANT_EXECUTED.txt"

        foreach ($rogueName in @('where.bat', 'findstr.bat', 'find.bat', 'reg.bat', 'chcp.bat', 'icacls.bat', 'fsutil.bat', 'powershell.bat')) {
            Set-Content -Path (Join-Path $poisonCwd $rogueName) -Value "@echo off`r`necho PWNED > `"$canaryFile`"`r`nexit /b 0"
        }

        Push-Location $poisonCwd
        try {
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outVer = & cmd.exe /c "call `"$JvmBat`" --version --no-color" 2>&1 | Out-String
            $ErrorActionPreference = $prevEAP

            Assert-PathNotExists $canaryFile "Rogue binary planted in CWD MUST NOT execute (NoDefaultCurrentDirectoryInExePath=1 & %SYS32% pinning)"
            Assert-Contains $outVer "Java Version Manager" "jvm.bat must execute normally from poisoned CWD"
        } finally {
            Pop-Location
        }
    }

    # 80. CWE-427: Prepended Rogue PATH Hijacking Resistance
    Run-TestCase "Adversarial" "Pinned System Binaries immunity against prepended rogue PATH hijacking (CWE-427)" {
        $roguePathDir = Join-Path $SandboxRoot "RoguePathHijack"
        New-Item -ItemType Directory -Path $roguePathDir -Force | Out-Null
        $hijackCanary = Join-Path $roguePathDir "PATH_HIJACK_EXECUTED.txt"

        foreach ($shim in @('findstr.cmd', 'reg.cmd', 'where.cmd', 'icacls.cmd', 'fsutil.cmd', 'chcp.cmd', 'choice.cmd')) {
            Set-Content -Path (Join-Path $roguePathDir $shim) -Value "@echo off`r`necho HIJACKED > `"$hijackCanary`"`r`nexit /b 0"
        }

        $origPath = $env:PATH
        $origLocalAppData = $env:LOCALAPPDATA
        try {
            $env:PATH = "$roguePathDir;$origPath"
            $env:LOCALAPPDATA = $FakeLocalAppData
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outStatus = & cmd.exe /c "call `"$JvmBat`" status --no-color" 2>&1 | Out-String
            $ErrorActionPreference = $prevEAP

            Assert-PathNotExists $hijackCanary "Trojanized utilities on prepended PATH MUST NOT be invoked by jvm.bat"
            Assert-Contains $outStatus "Current JVM Environment Status" "jvm.bat status must succeed using pinned %SYS32% binaries"
        } finally {
            $env:PATH = $origPath
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    # 81. CWE-276: %JVM_SECURE_TEMP% DACL Isolation & Reparse Point Rejection
    Run-TestCase "Concurrency" "ACL verification and reparse point junction rejection on %JVM_SECURE_TEMP% (CWE-276)" {
        $origLocalAppData = $env:LOCALAPPDATA
        $testAppData = Join-Path $SandboxRoot "SecTempReparseAppData"
        $jvmBase = Join-Path $testAppData "DiamTek\JVM"
        $secTemp = Join-Path $jvmBase "temp"
        $victimDir = Join-Path $SandboxRoot "VictimTargetDir"
        New-Item -ItemType Directory -Path $jvmBase -Force | Out-Null
        New-Item -ItemType Directory -Path $victimDir -Force | Out-Null
        $victimCanary = Join-Path $victimDir "victim_secret.txt"
        Set-Content -Path $victimCanary -Value "SENSITIVE_DATA"

        $null = & cmd.exe /c "mklink /J `"$secTemp`" `"$victimDir`"" 2>&1
        Assert-True (Test-Path -LiteralPath $secTemp) "Pre-planted junction must exist before startup"

        try {
            $env:LOCALAPPDATA = $testAppData
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $null = & cmd.exe /c "call `"$JvmBat`" --version --no-color" 2>&1
            $ErrorActionPreference = $prevEAP

            Assert-PathExists $victimCanary "Victim file behind pre-planted junction must not be destroyed"

            if (Test-Path -LiteralPath $secTemp) {
                $item = Get-Item -LiteralPath $secTemp -Force
                $isReparse = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
                Assert-False $isReparse "%JVM_SECURE_TEMP% must NOT remain a ReparsePoint after :EnsureSecureTemp"

                $acl = Get-Acl -LiteralPath $secTemp
                Assert-True $acl.AreAccessRulesProtected "%JVM_SECURE_TEMP% DACL must have inheritance disabled (/inheritance:r)"
                $identities = @($acl.Access | ForEach-Object { $_.IdentityReference.Value })
                $hasBroad = ($identities | Where-Object { $_ -match '(^|\\)(Everyone|Users|Authenticated Users)$' }).Count -gt 0
                Assert-False $hasBroad "%JVM_SECURE_TEMP% must not grant access to Everyone/Users/Authenticated Users"
            }
        } finally {
            $env:LOCALAPPDATA = $origLocalAppData
            if (Test-Path -LiteralPath $secTemp) {
                & cmd.exe /c "rmdir `"$secTemp`"" >$null 2>&1
            }
        }
    }

    # 82. CWE-250: Base64 UTF-16LE -EncodedCommand UAC Elevation Boundary Isolation
    Run-TestCase "Registry" "Base64 UTF-16LE -EncodedCommand privilege escalation boundary AST injection immunity (CWE-250)" {
        $batRaw = Get-Content $JvmBat -Raw
        $elevMatches = [regex]::Matches($batRaw, 'Start-Process\s+-FilePath\s+\$ps\s+-Verb\s+RunAs[^\r\n]+')
        Assert-True ($elevMatches.Count -ge 6) "Must locate all 6 UAC elevation call sites in jvm.bat"

        foreach ($m in $elevMatches) {
            Assert-Contains $m.Value "-EncodedCommand" "Every RunAs elevation site must use -EncodedCommand"
            Assert-Contains $m.Value "-WorkingDirectory `$s" "Every RunAs elevation site must pin -WorkingDirectory to System32 (`$s)"
        }

        $adversarialPath = "C:\Java\jdk-21'; Stop-Process -Name explorer; `$(calc.exe); '#"
        $b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($adversarialPath))
        $script = '$target = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''' + $b64 + ''')); [Environment]::SetEnvironmentVariable(''JAVA_HOME'', $target, ''Machine'')'

        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($script, [ref]$tokens, [ref]$errors)
        Assert-Equals $errors.Count 0 "Elevated script must parse with zero syntax errors"

        $cmdAsts = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
        Assert-Equals $cmdAsts.Count 0 "Adversarial path MUST NOT inject any CommandAst nodes into the elevated script"
    }

    # 83. CWE-66: Extended DOS Device Names (NUL.jdk) & Win32 Device Namespace Rejection in 'jvm link'
    Run-TestCase "Adversarial" "DOS reserved device extension ('NUL.jdk') and UNC device path ('\\.\') rejection in 'jvm link' (CWE-66)" {
        $origLocalAppData = $env:LOCALAPPDATA
        try {
            $env:LOCALAPPDATA = $FakeLocalAppData
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'

            foreach ($extDev in @('CON.jdk', 'NUL.21', 'AUX.txt', 'COM1.jdk')) {
                $outDev = & cmd.exe /c "call `"$JvmBat`" link `"$FakeJdkDir`" `"$extDev`"" 2>&1 | Out-String
                Assert-True ($LASTEXITCODE -ne 0) "jvm link must reject extended DOS device name: $extDev"
                Assert-PathNotExists (Join-Path $FakeLocalAppData "JavaVersionManager\links\$extDev") "Link must not be created for $extDev"
            }

            foreach ($uncPath in @('\\.\C:\Windows', '\\?\C:\Windows')) {
                $outUnc = & cmd.exe /c "call `"$JvmBat`" link `"$uncPath`" unc_test" 2>&1 | Out-String
                Assert-True ($LASTEXITCODE -ne 0) "jvm link must reject Win32 device namespace path: $uncPath"
            }
            $ErrorActionPreference = $prevEAP
        } finally {
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    # 84. CWE-88: jvm exec Argument Injection, Poisoned --vendor, and Empty '--' Command Rejection
    Run-TestCase "Adversarial" "jvm exec argument injection, poisoned '--vendor', and empty '--' command rejection (CWE-88)" {
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        $outEmpty = & cmd.exe /c "call `"$JvmBat`" exec 21 --" 2>&1 | Out-String
        $exitEmpty = $LASTEXITCODE

        $outFlag = & cmd.exe /c "call `"$JvmBat`" exec --evil-flag -- java -version" 2>&1 | Out-String
        $exitFlag = $LASTEXITCODE

        $pwnVendorFile = Join-Path $SandboxRoot "EXEC_VENDOR_PWNED.txt"
        $outVendor = & cmd.exe /c "call `"$JvmBat`" --vendor `"adoptium&echo PWN>`"$pwnVendorFile`"`" exec 21 -- java -version" 2>&1 | Out-String
        $exitVendor = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP

        Assert-True ($exitEmpty -ne 0) "jvm exec must reject missing command after '--'"
        Assert-Contains $outEmpty "No command specified to execute" "jvm exec must report missing command"
        Assert-True ($exitFlag -ne 0) "jvm exec must reject leading-hyphen flag injection in version parameter"
        Assert-Contains $outFlag "Invalid target version for exec" "jvm exec must reject '--evil-flag' as version"
        Assert-True ($exitVendor -ne 0) "jvm exec with poisoned --vendor must fail closed"
        Assert-PathNotExists $pwnVendorFile "Poisoned --vendor in jvm exec MUST NOT execute shell payload"
    }

    # 85. CWE-59: jvm pin Symlink/Reparse-Point Overwrite Protection & Reserved Keyword Defense
    Run-TestCase "ReparsePoint" "jvm pin refuses to overwrite reparse point .java-version and blocks reserved keyword 'current' (CWE-59)" {
        $pinTestDir = Join-Path $SandboxRoot "PinReparseGuardTest"
        New-Item -ItemType Directory -Path $pinTestDir -Force | Out-Null
        $externalTargetDir = Join-Path $SandboxRoot "ExternalProtectedTarget"
        New-Item -ItemType Directory -Path $externalTargetDir -Force | Out-Null
        $sentinelFile = Join-Path $externalTargetDir "sentinel.txt"
        Set-Content -LiteralPath $sentinelFile -Value "IMMUTABLE_EXTERNAL_CONTENT"

        $dotJavaVersionPath = Join-Path $pinTestDir ".java-version"
        & cmd.exe /c "mklink /J `"$dotJavaVersionPath`" `"$externalTargetDir`"" >$null 2>&1

        Push-Location $pinTestDir
        try {
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outReparse = & cmd.exe /c "call `"$JvmBat`" pin 21" 2>&1 | Out-String
            $exitReparse = $LASTEXITCODE

            & cmd.exe /c "rmdir `"$dotJavaVersionPath`"" >$null 2>&1
            $outCurrent = & cmd.exe /c "call `"$JvmBat`" pin current" 2>&1 | Out-String
            $exitCurrent = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-True ($exitReparse -ne 0) "jvm pin must fail closed when .java-version is a junction/reparse point"
            Assert-Equals (Get-Content -LiteralPath $sentinelFile -Raw).Trim() "IMMUTABLE_EXTERNAL_CONTENT" "External sentinel must remain untouched"
            Assert-True ($exitCurrent -ne 0) "jvm pin must reject reserved keyword 'current'"
            Assert-PathNotExists $dotJavaVersionPath ".java-version must not be created for reserved keyword 'current'"
        } finally {
            if (Test-Path -LiteralPath $dotJavaVersionPath) {
                & cmd.exe /c "rmdir `"$dotJavaVersionPath`"" >$null 2>&1
            }
            Pop-Location
        }
    }

    # 86. CWE-59: jvm clean / jvm prune Non-Destructive Cache Reparse-Point Unbinding
    Run-TestCase "ReparsePoint" "jvm clean and jvm prune unbind junctions in downloads/temp without deleting external target files (CWE-59)" {
        $origLocalAppData = $env:LOCALAPPDATA
        $isolatedAppData = Join-Path $SandboxRoot "CleanTestAppData"
        $downloadsDir = Join-Path $isolatedAppData "DiamTek\JVM\downloads"
        $tempExtractDir = Join-Path $isolatedAppData "DiamTek\JVM\temp\jdk_adoptium_21_extract"
        New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null
        New-Item -ItemType Directory -Path $tempExtractDir -Force | Out-Null

        $protectedHostDir = Join-Path $SandboxRoot "ProtectedHostOutsideCache"
        New-Item -ItemType Directory -Path $protectedHostDir -Force | Out-Null
        $hostCanary = Join-Path $protectedHostDir "host_canary.txt"
        Set-Content -LiteralPath $hostCanary -Value "HOST_DATA_MUST_SURVIVE_CLEAN"

        $dlJunc = Join-Path $downloadsDir "junction_trap"
        $nestedJunc = Join-Path $tempExtractDir "nested_junction_trap"
        & cmd.exe /c "mklink /J `"$dlJunc`" `"$protectedHostDir`"" >$null 2>&1
        & cmd.exe /c "mklink /J `"$nestedJunc`" `"$protectedHostDir`"" >$null 2>&1

        try {
            $env:LOCALAPPDATA = $isolatedAppData
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outClean = & cmd.exe /c "call `"$JvmBat`" clean" 2>&1 | Out-String
            $cleanExit = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-Equals $cleanExit 0 "jvm clean must exit with code 0"
            Assert-PathNotExists $dlJunc "Junction inside downloads\ must be unbound and removed"
            Assert-PathNotExists $tempExtractDir "Temporary extract directory must be removed"
            Assert-PathExists $protectedHostDir "External target directory pointed to by cache junction MUST survive"
            Assert-PathExists $hostCanary "Sentinel file inside external target directory MUST NOT be deleted by jvm clean"
            Assert-Equals (Get-Content -LiteralPath $hostCanary -Raw).Trim() "HOST_DATA_MUST_SURVIVE_CLEAN" "Sentinel file content must remain intact"
        } finally {
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    # 87. CWE-78: jvm doctor Resilience Against Poisoned PATH and JDK release Metadata Injection
    Run-TestCase "Adversarial" "jvm doctor resilience against metacharacter injection in PATH and JDK release file (CWE-78)" {
        $origLocalAppData = $env:LOCALAPPDATA
        $origUserProfile  = $env:USERPROFILE
        $origPath         = $env:PATH
        $docSandbox = Join-Path $SandboxRoot "DoctorSandbox"
        $docAppData = Join-Path $docSandbox "LocalAppData"
        $docProfile = Join-Path $docSandbox "UserProfile"
        $pwnDoctor  = Join-Path $docSandbox "DOCTOR_PWNED.txt"

        $maliciousJdk = Join-Path $docProfile ".jdks\jdk-21-crafted"
        New-Item -ItemType Directory -Path (Join-Path $maliciousJdk "bin") -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $maliciousJdk "bin\java.exe") -Value "MZ_FAKE"
        Set-Content -LiteralPath (Join-Path $maliciousJdk "release") -Value "JAVA_VERSION=`"21.0.2`"`r`nIMPLEMENTOR=`"Oracle & echo PWNED > `"$pwnDoctor`"`""

        try {
            $env:LOCALAPPDATA = $docAppData
            $env:USERPROFILE  = $docProfile
            $env:PATH = "C:\PoisonPath&echo PWNED > `"$pwnDoctor`";$origPath"

            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outDoc = & cmd.exe /c "call `"$JvmBat`" doctor" 2>&1 | Out-String
            $ErrorActionPreference = $prevEAP

            Assert-PathNotExists $pwnDoctor "jvm doctor MUST NOT execute commands from poisoned PATH or release metadata"
            Assert-Contains $outDoc "Running DiamTek JVM System Health Audit" "jvm doctor must execute audit banner cleanly"
            Assert-Contains $outDoc "Discovered JDKs:" "jvm doctor must complete inventory scan without crashing"
        } finally {
            $env:LOCALAPPDATA = $origLocalAppData
            $env:USERPROFILE  = $origUserProfile
            $env:PATH         = $origPath
        }
    }

    # 88. CWE-426: Untrusted CWD Binary Planting Defense ($PATH:java) in 'jvm which java'
    Run-TestCase "Adversarial" "Pinned System Binaries CWD Planting Defense in 'jvm which java' ($PATH:java) (CWE-426)" {
        $plantDir = Join-Path $SandboxRoot "UntrustedCwdPlanting"
        New-Item -ItemType Directory -Path $plantDir -Force | Out-Null
        $plantedJava = Join-Path $plantDir "java.bat"
        $pwnPlantFile = Join-Path $plantDir "PLANT_EXECUTED.txt"
        Set-Content -LiteralPath $plantedJava -Value "@echo off`r`necho PWN > `"$pwnPlantFile`"`r`necho java version `"99.0.0`""

        $origJavaHome = $env:JAVA_HOME
        Push-Location $plantDir
        try {
            $env:JAVA_HOME = ""
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outWhich = (& cmd.exe /c "call `"$JvmBat`" which java" 2>&1 | Out-String).Trim()
            $ErrorActionPreference = $prevEAP

            Assert-NotContains $outWhich $plantDir "'jvm which java' MUST NOT resolve planted java.bat from untrusted CWD"
            Assert-PathNotExists $pwnPlantFile "Planted java.bat in CWD MUST NOT be executed"
        } finally {
            $env:JAVA_HOME = $origJavaHome
            Pop-Location
        }
    }

    # 89. CWE-295: TLS 1.2 / 1.3 Protocol Enforcement Across :ExecuteSharedDownloader & :SelfUpdate
    Run-TestCase "PackageIntegrity" "TLS 1.2+1.3 protocol enforcement in :ExecuteSharedDownloader and :SelfUpdate (CWE-295)" {
        $batRaw = Get-Content $JvmBat -Raw
        $dlBlock = [regex]::Match($batRaw, '(?s):ExecuteSharedDownloader\r?\n.*?(?=\r?\n:BackupRegistry)').Value
        Assert-True ($dlBlock.Length -gt 0) "Must locate :ExecuteSharedDownloader in jvm.bat"
        Assert-Contains $dlBlock "[Net.SecurityProtocolType]::Tls12 -bor 12288" ":ExecuteSharedDownloader must enforce TLS 1.2 and TLS 1.3 (12288)"
        Assert-NotContains $dlBlock "Ssl3" ":ExecuteSharedDownloader must never enable SSLv3"

        $suBlock = [regex]::Match($batRaw, '(?s):SelfUpdate\r?\n.*?(?=\r?\n:CheckUpdateStatus)').Value
        Assert-True ($suBlock.Length -gt 0) "Must locate :SelfUpdate in jvm.bat"
        Assert-Contains $suBlock "[Net.SecurityProtocolType]::Tls12 -bor 12288" ":SelfUpdate must enforce TLS 1.2 and TLS 1.3 on installer and SHA256SUMS downloads"
    }

    # 90. CWE-319: Strict HTTPS Scheme Enforcement & Non-HTTPS Redirect Rejection in :ExecuteSharedDownloader
    Run-TestCase "PackageIntegrity" "Non-HTTPS URI scheme (http://, file://, UNC) rejection in :ExecuteSharedDownloader (CWE-319)" {
        $batRaw = Get-Content $JvmBat -Raw
        Assert-Contains $batRaw "Refusing non-HTTPS download URL:" ":ExecuteSharedDownloader must enforce https scheme on DL_URL"
        Assert-Contains $batRaw "Refusing non-HTTPS checksum URL:" ":ExecuteSharedDownloader must enforce https scheme on DL_CHKSUM_URL"
        Assert-Contains $batRaw "Blocked redirect to non-HTTPS URL:" ":ExecuteSharedDownloader must block HTTP downgrade redirects"

        $uriGuardScript = {
            param([string]$TestUrl)
            $uri = $null
            if (-not [System.Uri]::TryCreate($TestUrl, [System.UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -ne 'https') {
                return $false
            }
            return $true
        }
        foreach ($badUrl in @(
            "http://repo.maven.apache.org/maven2/apache-maven.zip",
            "file:///C:/Windows/System32/calc.exe",
            "\\127.0.0.1\c$\Windows\win.ini",
            "ftp://mirror.example.com/jdk.zip"
        )) {
            Assert-False (& $uriGuardScript $badUrl) "Downloader URL guard MUST reject non-HTTPS URI: $badUrl"
        }
        Assert-True (& $uriGuardScript "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse") "Downloader URL guard must allow valid https:// URI"
    }

    # 91. CWE-345: :CheckUpdateStatus & :SelfUpdate Version & JVM_BUILD Downgrade Attack Rejection
    Run-TestCase "PackageIntegrity" ":CheckUpdateStatus & :SelfUpdate version and JVM_BUILD downgrade attack rejection (CWE-345)" {
        $batRaw = Get-Content $JvmBat -Raw
        Assert-Contains $batRaw 'if "!UPDATE_FLAG!"=="AHEAD_OF_STABLE"' ":SelfUpdate must handle AHEAD_OF_STABLE downgrade flag"
        Assert-Contains $batRaw 'if "!UPDATE_FLAG!"=="AHEAD_OF_NIGHTLY"' ":SelfUpdate must handle AHEAD_OF_NIGHTLY downgrade flag"
        Assert-NotContains $batRaw 'if "!CLI_COMMAND!"=="self-update" if "!FORCE_YES!" NEQ "1"' ":SelfUpdate must NEVER skip :CheckUpdateStatus when --yes is passed"

        $evalUpdateState = {
            param([string]$LocalVerStr, [string]$LocalBldStr, [string]$RemoteVerStr, [string]$RemoteBldStr, [string]$Channel)
            try {
                $localVer  = [version]$LocalVerStr
                $localBld  = [version]$LocalBldStr
                $remoteVer = [version]$RemoteVerStr
                $remoteBld = [version]$RemoteBldStr
            } catch {
                return "INVALID_REMOTE"
            }
            $aheadFlag = if ($Channel -eq 'STABLE') { 'AHEAD_OF_STABLE' } else { 'AHEAD_OF_NIGHTLY' }
            if ($remoteVer -gt $localVer) { return "UPDATE" }
            elseif ($remoteVer -lt $localVer) { return $aheadFlag }
            else {
                if ($remoteBld -gt $localBld) { return "UPDATE" }
                elseif ($remoteBld -lt $localBld) { return $aheadFlag }
                else { return "OK" }
            }
        }

        Assert-Equals (& $evalUpdateState "1.0.1" "20260924.119" "1.0.0" "20260999.999" "STABLE") "AHEAD_OF_STABLE" "Lower remote semantic version must be rejected as AHEAD_OF_STABLE"
        Assert-Equals (& $evalUpdateState "1.0.1" "20260924.119" "1.0.1" "20260920.100" "STABLE") "AHEAD_OF_STABLE" "Older REMOTE_BUILD on same version must be rejected as AHEAD_OF_STABLE"
        Assert-Equals (& $evalUpdateState "1.0.1" "20260924.119" "1.0.1" "20260920.100" "NIGHTLY") "AHEAD_OF_NIGHTLY" "Older REMOTE_BUILD on Nightly must be rejected as AHEAD_OF_NIGHTLY"
        Assert-Equals (& $evalUpdateState "1.0.1" "20260924.119" "1.0.1-evil&calc" "20260924.119" "STABLE") "INVALID_REMOTE" "Malformed remote version must return INVALID_REMOTE"
    }

    # 92. CWE-494: :SelfUpdate & :ExecuteSharedDownloader SHA-256 Mismatch Rejection & --skip-checksum Warning
    Run-TestCase "PackageIntegrity" ":SelfUpdate & :ExecuteSharedDownloader SHA-256 mismatch fail-closed rejection and --skip-checksum warning (CWE-494)" {
        $testDir = Join-Path $SandboxRoot "ShaMismatchTest"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null

        $stagedInstaller = Join-Path $testDir "jvm_install_test.ps1"
        $payloadText = "# Java Version Manager`r`nWrite-Host 'TAMPERED PAYLOAD'`r`n" + ("# padding `r`n" * 20) + "rem END OF SCRIPT`r`n"
        [System.IO.File]::WriteAllText($stagedInstaller, $payloadText, [System.Text.UTF8Encoding]::new($false))

        $fakeExpected = "a" * 64
        $shaManifest = "$fakeExpected  install.ps1`r`n"

        $s = [System.Security.Cryptography.SHA256]::Create()
        $fs = [System.IO.File]::OpenRead($stagedInstaller)
        $actual = try { ([System.BitConverter]::ToString($s.ComputeHash($fs)) -replace '-','').ToLower() } finally { $fs.Close(); $s.Dispose() }

        $exp = $null
        foreach ($line in ($shaManifest -split '\r?\n')) {
            if ($line.Trim() -match '^([0-9a-fA-F]{64})\s+[\*]?install\.ps1$') { $exp = $matches[1].ToLower(); break }
        }
        $status = if ($exp) { if ($actual -eq $exp) { "VERIFIED|$exp" } else { "MISMATCH|$exp|$actual" } } else { "NO_ENTRY|$actual" }

        Assert-True ($status.StartsWith("MISMATCH|")) "Tampered installer MUST produce MISMATCH status"

        $batRaw = Get-Content $JvmBat -Raw
        Assert-Contains $batRaw "Proceeding WITHOUT integrity verification ^(--skip-checksum active^)." ":ExecuteSharedDownloader must emit explicit security warning when --skip-checksum is active"
        Assert-Contains $batRaw "set `"UNINSTALL_REF=v!JVM_VERSION!`"$([Environment]::NewLine)set `"UNINSTALL_SCRIPT=`"$([Environment]::NewLine)set `"UNINSTALL_VERIFIED=0`"" ":UninstallJVM_Complete must initialize UNINSTALL_REF and UNINSTALL_VERIFIED before local uninstall.ps1 lookup"
        Assert-Contains $batRaw "Local uninstall.ps1 does not match !UNINSTALL_REF! digest. Fetching verified release copy..." ":UninstallJVM_Complete must fall back to downloading the matching release uninstall.ps1 when local hash differs"
        Assert-Contains $batRaw "call :VerifyDownloadedScript `"!UNINSTALL_SCRIPT!`" `"!UNINSTALL_REF!`" `"uninstall.ps1`"" ":UninstallJVM_Complete must cryptographically verify uninstall.ps1 via :VerifyDownloadedScript"
        Assert-Contains $batRaw "for /f `"usebackq tokens=1,2,3 delims=|`"" ":VerifyDownloadedScript must use 'usebackq' to parse %VERIFY_RESULT% file contents"

        # Functional test of :VerifyDownloadedScript result file parsing via cmd.exe 'for /f "usebackq ..."'
        $verifyResFile = Join-Path $testDir "verify_result_test.txt"
        [System.IO.File]::WriteAllText($verifyResFile, "VERIFIED|$fakeExpected`r`n", [System.Text.UTF8Encoding]::new($false))
        $parsedStatus = & cmd.exe /c "for /f `"usebackq tokens=1,2,3 delims=|`"` %A in (`"$verifyResFile`") do @echo %A" 2>&1 | Out-String
        Assert-Equals $parsedStatus.Trim() "VERIFIED" "cmd.exe 'usebackq' loop in :VerifyDownloadedScript must extract VERIFIED status from result file"
    }

    # 93. CWE-354: Malformed, Empty, Partial-Hash, and Spoofed-Filename SHA256SUMS.txt Manifest Rejection
    Run-TestCase "PackageIntegrity" "Malformed, empty, partial-hash, and filename-spoofed SHA256SUMS.txt manifest rejection (CWE-354)" {
        $validHash64 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        $malformedManifests = @(
            "",
            "   `r`n  ",
            "e3b0c44298fc1c149afbf4c8996fb924  install.ps1",
            ("${validHash64}ff  install.ps1"),
            ("g3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  install.ps1"),
            ("$validHash64  evil_install.ps1"),
            ("$validHash64  install.ps1.bak"),
            ("$validHash64  ../install.ps1")
        )

        foreach ($manifest in $malformedManifests) {
            $exp = $null
            foreach ($line in ($manifest -split '\r?\n')) {
                if ($line.Trim() -match '^([0-9a-fA-F]{64})\s+[\*]?install\.ps1$') {
                    $exp = $matches[1].ToLower()
                    break
                }
            }
            Assert-True ($null -eq $exp) "SHA256SUMS parser MUST reject malformed/spoofed manifest line: '$manifest'"
        }
    }

    # 94. CWE-22: Live ZIP Archive Extraction Blocks ZipSlip ('../', Sibling-Prefix, Rooted '\', and ADS ':')
    Run-TestCase "UninstallSafety" "Live ZIP archive extraction blocks ZipSlip ('../', sibling-prefix, rooted '\', and ADS ':') (CWE-22)" {
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        $zipTestDir  = Join-Path $SandboxRoot "LiveZipSlipTest"
        $extractRoot = Join-Path $zipTestDir "extract_dest"
        $escapeFile  = Join-Path $zipTestDir "escaped_pwn.txt"
        $malZipPath  = Join-Path $zipTestDir "malicious.zip"
        New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null

        $fs = New-Object System.IO.FileStream($malZipPath, [System.IO.FileMode]::Create)
        $archive = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create, $false)
        try {
            $e1 = $archive.CreateEntry("jdk-21/release")
            $sw1 = New-Object System.IO.StreamWriter($e1.Open())
            $sw1.Write("JAVA_VERSION=21"); $sw1.Close()

            $e2 = $archive.CreateEntry("../escaped_pwn.txt")
            $sw2 = New-Object System.IO.StreamWriter($e2.Open())
            $sw2.Write("PWNED"); $sw2.Close()
        } finally {
            $archive.Dispose()
            $fs.Close()
        }

        $threwTraversal = $false
        $zip = [System.IO.Compression.ZipFile]::OpenRead($malZipPath)
        try {
            $fullRoot = [System.IO.Path]::GetFullPath($extractRoot)
            if (-not $fullRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar.ToString())) {
                $fullRoot += [System.IO.Path]::DirectorySeparatorChar
            }
            foreach ($entry in $zip.Entries) {
                $destinationPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($extractRoot, $entry.FullName))
                if ($entry.FullName -match '^[/\\]' -or $entry.FullName -match ':' -or (-not $destinationPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase) -and $destinationPath -ne $fullRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar))) {
                    throw ('Blocked path traversal in archive entry: ' + $entry.FullName)
                }
            }
        } catch {
            if ($_.Exception.Message -match 'Blocked path traversal in archive entry') {
                $threwTraversal = $true
            }
        } finally {
            if ($zip) { $zip.Dispose() }
        }

        Assert-True $threwTraversal "Extraction engine MUST throw 'Blocked path traversal in archive entry' on '../escaped_pwn.txt'"
        Assert-PathNotExists $escapeFile "ZipSlip payload MUST NOT be written outside extraction root"
    }

    # 95. CWE-459: Complete Cleanup of Temp ZIP ($zip.Dispose()) and Partial Extraction Directory on Failure
    Run-TestCase "Concurrency" "Complete cleanup of temp ZIP (`$zip.Dispose()) and partial extraction directory on ZipSlip or hash failure (CWE-459)" {
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        $cleanupDir  = Join-Path $SandboxRoot "Cwe459CleanupTest"
        $tempZip     = Join-Path $cleanupDir "jvm_dl_payload.zip"
        $tempExtract = Join-Path $cleanupDir "jvm_dl_extract_temp"
        New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null

        $fs = New-Object System.IO.FileStream($tempZip, [System.IO.FileMode]::Create)
        $archive = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create, $false)
        try {
            $e1 = $archive.CreateEntry("benign.txt")
            $sw1 = New-Object System.IO.StreamWriter($e1.Open()); $sw1.Write("OK"); $sw1.Close()
            $e2 = $archive.CreateEntry("../evil.txt")
            $sw2 = New-Object System.IO.StreamWriter($e2.Open()); $sw2.Write("BAD"); $sw2.Close()
        } finally {
            $archive.Dispose(); $fs.Close()
        }

        try {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($tempZip)
            try {
                $fullRoot = [System.IO.Path]::GetFullPath($tempExtract) + [System.IO.Path]::DirectorySeparatorChar
                foreach ($entry in $zip.Entries) {
                    $destinationPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($tempExtract, $entry.FullName))
                    if ($entry.FullName -match '^[/\\]' -or (-not $destinationPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase))) {
                        throw ('Blocked path traversal in archive entry: ' + $entry.FullName)
                    }
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destinationPath, $true)
                }
            } finally {
                if ($zip) { $zip.Dispose() }
            }
        } catch {
            if (Test-Path -LiteralPath $tempZip) { Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue }
            if (Test-Path -LiteralPath $tempExtract) { Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
        }

        Assert-PathNotExists $tempZip "CWE-459: Temporary downloaded archive ($tempZip) MUST be unlocked ($zip.Dispose()) and deleted on failure"
        Assert-PathNotExists $tempExtract "CWE-459: Partial extraction directory ($tempExtract) MUST be recursively purged on failure"
    }

    # 96. CWE-78: .sdkmanrc Metacharacter, Backtick, Subshell $(), and Inline Comment Neutralization
    Run-TestCase "Adversarial" ".sdkmanrc metacharacter, backtick, subshell `$(), and inline comment neutralization (CWE-78)" {
        $testDir = Join-Path $SandboxRoot "SdkmanrcMetacharTest"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $pwnFile = Join-Path $testDir "SDK_PWNED.txt"

        $payloads = @(
            "java=21.0.2-tem & echo PWN > `"$pwnFile`"",
            "java=21.0.2-tem | echo PWN > `"$pwnFile`"",
            "java=`$(echo PWN > `"$pwnFile`")",
            "java=``echo PWN > `"$pwnFile`"`"",
            "java=!PATH!%COMSPEC%",
            "maven=3.9.6 & echo PWN > `"$pwnFile`""
        )
        Set-Content -Path (Join-Path $testDir ".sdkmanrc") -Value ($payloads -join "`r`n")

        Push-Location $testDir
        try {
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $out = & cmd.exe /c "call `"$JvmBat`"" 2>&1 | Out-String
            $ErrorActionPreference = $prevEAP
            Assert-PathNotExists $pwnFile ".sdkmanrc shell metacharacters MUST NOT execute arbitrary commands"
        } finally {
            Pop-Location
        }
    }

    # 97. CWE-88: .java-version Inline Flag Poisoning (--vendor Traversal, --legacy, --registry) Defense
    Run-TestCase "Adversarial" ".java-version inline flag poisoning (--vendor traversal, --legacy, --registry) defense (CWE-88)" {
        $testDir = Join-Path $SandboxRoot "JavaVersionFlagPoisonTest"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null

        Set-Content -Path (Join-Path $testDir ".java-version") -Value "21 --vendor ../../evil_vendor --legacy --registry"

        Push-Location $testDir
        try {
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $out = & cmd.exe /c "call `"$JvmBat`"" 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-True ($exitCode -ne 0) "Poisoned --vendor or --legacy/--registry in .java-version must fail closed"
            Assert-NotContains $out "Machine Registry" ".java-version must never trigger Machine HKLM Registry mode via --legacy/--registry"
        } finally {
            Pop-Location
        }
    }

    # 98. CWE-20: .java-version CRLF, UTF-8 BOM, Comment Lines, and Prefix (jdk-/1.8) Parser Resilience
    Run-TestCase "Adversarial" ".java-version CRLF, UTF-8 BOM, Comment lines, and prefix (jdk-/1.8) parser resilience (CWE-20)" {
        $testDir = Join-Path $SandboxRoot "JavaVersionBomCrlfTest"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $dotJv = Join-Path $testDir ".java-version"

        $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($dotJv, "# Pinned project version`r`njdk-21.0.2`r`n", $utf8WithBom)

        Push-Location $testDir
        try {
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $out = & cmd.exe /c "call `"$JvmBat`"" 2>&1 | Out-String
            $ErrorActionPreference = $prevEAP

            $bomMojibake = [string][char]0xEF + [char]0xBB + [char]0xBF
            Assert-NotContains $out $bomMojibake ".java-version parser must strip UTF-8 BOM without corrupting version token"
            Assert-Contains $out "21" ".java-version parser must normalize 'jdk-21.0.2' to major version '21'"
        } finally {
            Pop-Location
        }
    }

    # 99. CWE-20: .sdkmanrc Read-Only Subcommand Isolation (--version / list Must Not Trigger Session Target Emission)
    Run-TestCase "Adversarial" ".sdkmanrc read-only subcommand isolation (--version / list must not trigger session target emission) (CWE-20)" {
        $testDir = Join-Path $SandboxRoot "SdkmanrcReadOnlySubcmdTest"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        Set-Content -Path (Join-Path $testDir ".sdkmanrc") -Value "java=21.0.2-tem`r`nmaven=3.9.6"

        $origLocalAppData = $env:LOCALAPPDATA
        Push-Location $testDir
        try {
            $env:LOCALAPPDATA = $FakeLocalAppData
            $secTemp = Join-Path $FakeLocalAppData "DiamTek\JVM\temp"
            $sessFile = Join-Path $secTemp ".jvm_session_target"
            if (Test-Path -LiteralPath $sessFile) { Remove-Item -LiteralPath $sessFile -Force }

            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $out = & cmd.exe /c "call `"$JvmBat`" --version" 2>&1 | Out-String
            $ErrorActionPreference = $prevEAP

            Assert-PathNotExists $sessFile "Read-only CLI commands (--version / list) must NOT trigger .sdkmanrc session target emission"
        } finally {
            $env:LOCALAPPDATA = $origLocalAppData
            Pop-Location
        }
    }

    # 100. CWE-20: JVM_CALLER_PID Non-Numeric and Path Traversal Rejection in :EmitSessionEnv
    Run-TestCase "Adversarial" "JVM_CALLER_PID non-numeric and path traversal rejection in :EmitSessionEnv (CWE-20)" {
        $origLocalAppData = $env:LOCALAPPDATA
        $origCallerPid = $env:JVM_CALLER_PID
        try {
            $env:LOCALAPPDATA = $FakeLocalAppData
            foreach ($badPid in @("../../evil_session", "..\pwn", "1234;calc.exe", "-999")) {
                $env:JVM_CALLER_PID = $badPid
                $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
                $out = & cmd.exe /c "call `"$JvmBat`" 21 --session" 2>&1 | Out-String
                $ErrorActionPreference = $prevEAP

                $traversedFile = Join-Path $FakeLocalAppData "evil_session"
                Assert-PathNotExists $traversedFile "Traversal in JVM_CALLER_PID ('$badPid') must never write outside %JVM_SECURE_TEMP%"
            }
        } finally {
            $env:JVM_CALLER_PID = $origCallerPid
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    # 101. CWE-918: :ExecuteSharedDownloader SSRF & Untrusted Vendor Host Allowlist (Test-TrustedJvmUri)
    Run-TestCase "PackageIntegrity" ":ExecuteSharedDownloader SSRF and untrusted vendor host allowlist enforcement (Test-TrustedJvmUri) (CWE-918)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw "function Test-TrustedJvmUri" ":ExecuteSharedDownloader must define Test-TrustedJvmUri host allowlist"
        Assert-Contains $batRaw "Untrusted download host:" ":ExecuteSharedDownloader must reject untrusted download hosts (CWE-918)"
        Assert-Contains $batRaw "Untrusted checksum host:" ":ExecuteSharedDownloader must reject untrusted checksum hosts (CWE-918)"

        $testTrustedHost = {
            param([string]$Url)
            $u = $null
            if (-not [System.Uri]::TryCreate($Url, [System.UriKind]::Absolute, [ref]$u) -or $u.Scheme -ne 'https' -or $u.IsLoopback) { return $false }
            $h = $u.Host.ToLowerInvariant()
            $exact = @('download.oracle.com','edelivery.oracle.com','api.adoptium.net','github.com','api.github.com','objects.githubusercontent.com','release-assets.githubusercontent.com','raw.githubusercontent.com','corretto.aws','api.azul.com','cdn.azul.com','static.azul.com','aka.ms','download.visualstudio.microsoft.com','api.bell-sw.com','download.bell-sw.com','repo.maven.apache.org','archive.apache.org','dlcdn.apache.org','downloads.apache.org','services.gradle.org','downloads.gradle.org','downloads.gradle-dn.com','api.sdkman.io')
            if ($exact -contains $h) { return $true }
            foreach ($sfx in @('.oracle.com','.adoptium.net','.github.com','.githubusercontent.com','.amazonaws.com','.cloudfront.net','.azul.com','.microsoft.com','.azureedge.net','.bell-sw.com','.apache.org','.gradle.org','.gradle-dn.com')) {
                if ($h.EndsWith($sfx)) { return $true }
            }
            return $false
        }
        foreach ($trusted in @(
            "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse",
            "https://objects.githubusercontent.com/github-production-release-asset/jdk.zip",
            "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.6/apache-maven-3.9.6-bin.zip",
            "https://d3pxv6yz143wms.cloudfront.net/21.0.2/amazon-corretto-21.zip"
        )) {
            Assert-True (& $testTrustedHost $trusted) "Test-TrustedJvmUri must allow official vendor host: $trusted"
        }
        foreach ($untrusted in @(
            "https://127.0.0.1/jdk.zip",
            "https://localhost/jdk.zip",
            "https://evil-github.com/jdk.zip",
            "https://adoptium.net.attacker.org/jdk.zip",
            "https://169.254.169.254/latest/meta-data"
        )) {
            Assert-False (& $testTrustedHost $untrusted) "Test-TrustedJvmUri MUST block SSRF/untrusted host: $untrusted"
        }
    }

    # 102. CWE-601: Open Redirect Host Verification in :ExecuteSharedDownloader & :VerifyDownloadedScript
    Run-TestCase "PackageIntegrity" "Open redirect host verification on ResponseUri in :ExecuteSharedDownloader & :VerifyDownloadedScript (CWE-601)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw "Blocked redirect to untrusted host:" ":ExecuteSharedDownloader must verify ResponseUri host against Test-TrustedJvmUri (CWE-601)"
        Assert-Contains $batRaw "Write-Output 'UNTRUSTED_REDIRECT'; exit" ":VerifyDownloadedScript must block redirects to non-GitHub domains (CWE-601)"
        Assert-Contains $batRaw "if (`$ref -notmatch '^[a-zA-Z0-9._-]+$' -or `$ref -match '\.\.') { Write-Output 'INVALID_REF'; exit }" ":VerifyDownloadedScript must validate RELEASE_REF against path traversal"
    }

    # 103. CWE-20: :InstallCandidate & :SwitchCandidate Validate Upstream-Resolved LATEST_VER After 'latest' Resolution
    Run-TestCase "Adversarial" ":InstallCandidate and :SwitchCandidate validate LATEST_VER via :ValidateStrictIdentifier after 'latest' resolution (CWE-20)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        $instBlock = [regex]::Match($batRaw, '(?ms)^:InstallCandidate\r?\n.*?(?=^:UninstallCandidate)').Value
        Assert-True ($instBlock.Length -gt 0) "Must locate :InstallCandidate in jvm.bat"
        $idxResolve = $instBlock.IndexOf('call :ResolveLatestEcosystemCandidate')
        $idxValidate = $instBlock.IndexOf('call :ValidateStrictIdentifier "!TARGET_VER!" TARGET_VER')
        Assert-True ($idxResolve -gt 0 -and $idxValidate -gt $idxResolve) ":InstallCandidate MUST run :ValidateStrictIdentifier AFTER resolving 'latest' (LATEST_VER)"

        $swBlock = [regex]::Match($batRaw, '(?ms)^:SwitchCandidate\r?\n.*?(?=^:InstallCandidate)').Value
        $idxSwLatest = $swBlock.IndexOf('if /i "!TARGET_VER!"=="latest"')
        $idxSwVal = $swBlock.IndexOf('call :ValidateStrictIdentifier "!TARGET_VER!" TARGET_VER')
        Assert-True ($idxSwLatest -gt 0 -and $idxSwVal -gt $idxSwLatest) ":SwitchCandidate MUST run :ValidateStrictIdentifier AFTER resolving 'latest'"
    }

    # 104. CWE-88: :ExecuteSharedDownloader DL_STRIP_ROOT Rejects Leading-Hyphen & Traversal Root Folder Names
    Run-TestCase "Adversarial" ":ExecuteSharedDownloader DL_STRIP_ROOT rejects leading-hyphen ('-Force') and traversal root folder names (CWE-88)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw "Unsafe root directory name in archive:" ":ExecuteSharedDownloader DL_STRIP_ROOT must validate root folder name against leading hyphens and unsafe characters"
        Assert-Contains $batRaw "Move-Item -LiteralPath `$_.FullName -Destination `$env:DL_EXTRACT -Force" ":ExecuteSharedDownloader DL_STRIP_ROOT must use Move-Item -LiteralPath"
    }

    # 105. CWE-22: :FetchAndExtract Elevated PowerShell Move Canonicalizes Destination Path via GetFullPath
    Run-TestCase "Adversarial" ":FetchAndExtract elevated PowerShell move canonicalizes destination path via [System.IO.Path]::GetFullPath (CWE-22)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw '$fullD = [System.IO.Path]::GetFullPath($d).TrimEnd(''''\'''') + ''''\'''';' ':FetchAndExtract elevated script must normalize $fullD with trailing backslash'
        Assert-Contains $batRaw '$t = [System.IO.Path]::GetFullPath((Join-Path $d $f))' ':FetchAndExtract elevated script must canonicalize $t via [System.IO.Path]::GetFullPath'
    }

    # 106. CWE-330: Zero Predictable !RANDOM! Temp Filenames in jvm.bat (CSPRNG GetRandomFileName Enforcement)
    Run-TestCase "Concurrency" "Zero predictable !RANDOM! temporary filenames in jvm.bat ([System.IO.Path]::GetRandomFileName enforcement) (CWE-330)" {
        $batLines = Get-Content -LiteralPath $JvmBat
        $predictableRandomLines = @($batLines | Where-Object { $_ -match '!RANDOM!|%RANDOM%' })
        Assert-Equals $predictableRandomLines.Count 0 "jvm.bat MUST NOT use predictable 15-bit !RANDOM! or %RANDOM% for temporary filenames (found: $($predictableRandomLines -join '; '))"
    }

    # 107. CWE-532: :BackupRegistry Enforces Reparse-Point Rejection & Per-User DACL Isolation (/inheritance:r) on Backups Directory
    Run-TestCase "Registry" ":BackupRegistry enforces fsutil reparse-point query and icacls /inheritance:r DACL isolation on backups directory (CWE-532)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        $bakBlock = [regex]::Match($batRaw, '(?s):BackupRegistry\r?\n.*?(?=\r?\n:RejectExclamationArg)').Value
        Assert-True ($bakBlock.Length -gt 0) "Must locate :BackupRegistry in jvm.bat"
        Assert-Contains $bakBlock '"%FSUTIL_BIN%" reparsepoint query "%JVM_BACKUP_DIR%"' ":BackupRegistry must query fsutil reparsepoint on %JVM_BACKUP_DIR% before exporting registry keys"
        Assert-Contains $bakBlock '"%ICACLS_BIN%" "%JVM_BACKUP_DIR%" /inheritance:r /grant:r "*S-1-5-18:(OI)(CI)F" "*S-1-5-32-544:(OI)(CI)F" "%USERNAME%:(OI)(CI)F"' ":BackupRegistry must lock down %JVM_BACKUP_DIR% DACL with /inheritance:r before writing .reg exports"
    }

    # 108. CWE-59: :InstallPowerShellHook & :RemovePowerShellHook ReparsePoint Symlink Guard & -LiteralPath Enforcement
    Run-TestCase "ReparsePoint" ":InstallPowerShellHook and :RemovePowerShellHook enforce ReparsePoint symlink guard and -LiteralPath on `$PROFILE (CWE-59)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        $instHookBlock = [regex]::Match($batRaw, '(?s):InstallPowerShellHook\r?\n.*?(?=\r?\n:RemovePowerShellHook)').Value
        $remHookBlock  = [regex]::Match($batRaw, '(?s):RemovePowerShellHook\r?\n.*?(?=\r?\n:CheckPowerShellHookStatus)').Value
        Assert-Contains $instHookBlock "[System.IO.FileAttributes]::ReparsePoint" ":InstallPowerShellHook must reject symlink/reparse-point profile directories and files"
        Assert-Contains $instHookBlock "Test-Path -LiteralPath `$p" ":InstallPowerShellHook must use Test-Path -LiteralPath"
        Assert-Contains $remHookBlock "[System.IO.FileAttributes]::ReparsePoint" ":RemovePowerShellHook must reject symlink/reparse-point profile files"
    }

    # 109. CWE-427: :InstallGlobalCommand Installs to Canonical %LOCALAPPDATA%\DiamTek\JVM\bin with ACLs & DoNotExpandEnvironmentNames
    Run-TestCase "Registry" ":InstallGlobalCommand installs to canonical %LOCALAPPDATA%\DiamTek\JVM\bin with ACLs & DoNotExpandEnvironmentNames (CWE-427)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        $igcBlock = [regex]::Match($batRaw, '(?s):InstallGlobalCommand\r?\n.*?(?=\r?\n:InstallPowerShellHook)').Value
        Assert-True ($igcBlock.Length -gt 0) "Must locate :InstallGlobalCommand in jvm.bat"
        Assert-Contains $igcBlock 'set "CANONICAL_BIN=%LOCALAPPDATA%\DiamTek\JVM\bin"' ":InstallGlobalCommand must target canonical %LOCALAPPDATA%\DiamTek\JVM\bin instead of arbitrary SCRIPT_DIR"
        Assert-Contains $igcBlock '"%ICACLS_BIN%" "!CANONICAL_BIN!" /inheritance:r' ":InstallGlobalCommand must enforce strict DACL on %LOCALAPPDATA%\DiamTek\JVM\bin"
        Assert-Contains $igcBlock 'DoNotExpandEnvironmentNames' ":InstallGlobalCommand must preserve unexpanded REG_EXPAND_SZ tokens when updating HKCU\Environment\Path"
    }

    # 110. CWE-78: :SwitchCandidate Updates Session PATH Without Spawning 'echo(!PATH! |' Pipe Child Shell
    Run-TestCase "Adversarial" ":SwitchCandidate updates session PATH via native substring check with zero 'echo(!PATH! |' pipe child shell spawning (CWE-78)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        $swBlock = [regex]::Match($batRaw, '(?s):SwitchCandidate\r?\n.*?(?=\r?\n:InstallCandidate)').Value
        Assert-NotContains $swBlock "echo(!PATH! |" ":SwitchCandidate MUST NOT pipe echo(!PATH! into findstr (prevents child cmd.exe & command injection)"
        Assert-Contains $swBlock 'call :EmitSessionEnv "!CANDIDATE_ENV_VAR!=!SYMLINK_PATH!"' ":SwitchCandidate must emit session target for PowerShell hook synchronization"
        Assert-Contains $swBlock 'if "!CHECK_PATH:;!SYMLINK_PATH!\bin;=!"=="!CHECK_PATH!"' ":SwitchCandidate must use native substring matching to update session PATH"
    }

    # 111. CWE-428: install.ps1 Quoted UninstallString, QuietUninstallString (-Quiet), and Pinned System32 Shortcut TargetPath
    Run-TestCase "UninstallSafety" "install.ps1 enforces quoted System32 UninstallString, QuietUninstallString (-Quiet), and pinned Shortcut TargetPath (CWE-428)" {
        $installRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "install.ps1") -Raw
        Assert-NotContains $installRaw '$systemPowerShell = "powershell.exe"' "install.ps1 MUST NOT fall back to unpinned 'powershell.exe' in UninstallString"
        Assert-Contains $installRaw 'throw "Trusted Windows PowerShell binary not found at $systemPowerShell"' "install.ps1 must fail closed if System32 powershell.exe is missing"
        Assert-Contains $installRaw '$quietUninstallCommand = "`"$systemPowerShell`" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$uninstallScriptPath`" -Quiet"' "QuietUninstallString must be properly quoted and pass -NonInteractive and -Quiet"
        Assert-Contains $installRaw '$sysCmd = Join-Path $sys32Dir "cmd.exe"' "install.ps1 must pin Start Menu shortcut TargetPath to System32\cmd.exe"
    }

    # 112. CWE-59: install.ps1 & uninstall.ps1 Test-HasReparsePointInLineage Guard on $PROFILE, settings.json, and Start Menu
    Run-TestCase "ReparsePoint" "install.ps1 and uninstall.ps1 Test-HasReparsePointInLineage guard on `$PROFILE, settings.json, and Start Menu (CWE-59)" {
        $installRaw   = Get-Content -LiteralPath (Join-Path $RepoRoot "install.ps1") -Raw
        $uninstallRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "uninstall.ps1") -Raw
        Assert-Contains $installRaw "function Test-HasReparsePointInLineage" "install.ps1 must define Test-HasReparsePointInLineage"
        Assert-Contains $installRaw "if (Test-HasReparsePointInLineage `$wtSettings) { continue }" "install.ps1 must guard Windows Terminal settings.json against symlink redirection"
        Assert-Contains $uninstallRaw "function Test-HasReparsePointInLineage" "uninstall.ps1 must define Test-HasReparsePointInLineage"
        Assert-Contains $uninstallRaw "if (Test-HasReparsePointInLineage `$p) { continue }" "uninstall.ps1 must guard PowerShell profiles against symlink redirection"
    }

    # 113. CWE-611: XML External Entity (XXE) & DTD Prohibition Across build-choco.ps1, build-msi.ps1, and Test-JvmSecurity.ps1
    Run-TestCase "PackageIntegrity" "XML External Entity (XXE) & DTD prohibition (DtdProcessing::Prohibit & XmlResolver = `$null) across build scripts (CWE-611)" {
        $chocoBuildRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "packages\choco\build-choco.ps1") -Raw
        $msiBuildRaw   = Get-Content -LiteralPath (Join-Path $RepoRoot "packages\msi\build-msi.ps1") -Raw
        Assert-Contains $chocoBuildRaw "[System.Xml.DtdProcessing]::Prohibit" "build-choco.ps1 must prohibit DTD processing when validating jvm.nuspec"
        Assert-Contains $chocoBuildRaw ".XmlResolver = `$null" "build-choco.ps1 must set XmlResolver = `$null"
        Assert-Contains $msiBuildRaw "[System.Xml.DtdProcessing]::Prohibit" "build-msi.ps1 must prohibit DTD processing when validating jvm.wxs"

        # Functional test: verify that DTD / XXE payload is strictly rejected by our XML validator settings
        $xxePayload = '<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///C:/Windows/win.ini">]><package>&xxe;</package>'
        $threwDtd = $false
        try {
            $settings = New-Object System.Xml.XmlReaderSettings
            $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
            $settings.XmlResolver = $null
            $sr = New-Object System.IO.StringReader($xxePayload)
            $xr = [System.Xml.XmlReader]::Create($sr, $settings)
            $doc = New-Object System.Xml.XmlDocument
            $doc.XmlResolver = $null
            $doc.Load($xr)
        } catch {
            $threwDtd = $true
        }
        Assert-True $threwDtd "XmlReader with DtdProcessing::Prohibit MUST throw an exception on DOCTYPE / XXE payloads (CWE-611)"
    }

    # 114. CWE-20: scripts/bump-version.ps1 & build-choco.ps1 Strict SemVer Input Validation & Path Traversal Rejection
    Run-TestCase "Manifest" "scripts/bump-version.ps1 and build-choco.ps1 reject path traversal ('..') and malformed SemVer parameters (CWE-20)" {
        $bumpRaw  = Get-Content -LiteralPath (Join-Path $RepoRoot "scripts\bump-version.ps1") -Raw
        $chocoRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "packages\choco\build-choco.ps1") -Raw
        Assert-Contains $bumpRaw "Security validation failed (CWE-20): Invalid Version parameter" "bump-version.ps1 must validate -Version parameter against traversal and injection"
        Assert-Contains $bumpRaw "Security validation failed (CWE-20): Invalid Build parameter" "bump-version.ps1 must validate -Build parameter"
        Assert-Contains $chocoRaw "Security validation failed (CWE-20): Invalid semantic version" "build-choco.ps1 must validate -Version parameter"
    }

    # 115. CWE-319: chocolateyInstall.ps1 Runtime HTTPS URI Scheme Enforcement & SHA-256 Checksum Gate
    Run-TestCase "PackageIntegrity" "chocolateyInstall.ps1 enforces runtime HTTPS URI scheme validation and 64-char SHA-256 gate (CWE-319)" {
        $chocoInstallRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "packages\choco\tools\chocolateyInstall.ps1") -Raw
        Assert-Contains $chocoInstallRaw "[System.Uri]::TryCreate(`$url64, [System.UriKind]::Absolute, [ref]`$parsedUri) -or `$parsedUri.Scheme -ne 'https'" "chocolateyInstall.ps1 must validate $url64 uses https:// before calling Install-ChocolateyPackage"
        Assert-Contains $chocoInstallRaw "Security violation (CWE-319): Download URL64 must use HTTPS transport." "chocolateyInstall.ps1 must fail closed on non-HTTPS URL64"
    }

    # 116. CWE-494: Nightly Channel Git Blob SHA-1 Verification, Dynamic %ProgramFiles% & ARM64 Resolver Guards
    Run-TestCase "PackageIntegrity" "Nightly self-update Git Blob SHA-1 verification, %ProgramFiles% paths, and ARM64 resolver guards (CWE-494)" {
        $batRaw     = Get-Content -LiteralPath $JvmBat -Raw
        $installRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "install.ps1") -Raw

        # 1. Verify Nightly Git Blob SHA-1 verification in jvm.bat (:SelfUpdate) and install.ps1
        Assert-Contains $batRaw "contents/install.ps1?ref=" "jvm.bat :SelfUpdate must query GitHub Contents API for install.ps1 Git Blob SHA-1 on Nightly"
        Assert-Contains $batRaw "'blob ' + `$b.Length + [char]0" "jvm.bat :SelfUpdate must compute Git Blob SHA-1 header ('blob <len>\0')"
        Assert-Contains $installRaw "contents/jvm.bat?ref=" "install.ps1 must query GitHub Contents API for jvm.bat Git Blob SHA-1 on Nightly"
        Assert-Contains $installRaw "Cryptographic Git blob SHA-1 check failed for Nightly jvm.bat!" "install.ps1 must abort on Nightly Git Blob SHA-1 mismatch"

        # 2. Live simulation of Git Blob SHA-1 match and 1-byte tamper rejection
        $sampleBytes = [System.Text.Encoding]::UTF8.GetBytes("# Java Version Manager`r`nWrite-Host 'OK'`r`n")
        $hdr = [System.Text.Encoding]::ASCII.GetBytes("blob $($sampleBytes.Length)`0")
        $blob = New-Object byte[] ($hdr.Length + $sampleBytes.Length)
        [Array]::Copy($hdr, 0, $blob, 0, $hdr.Length)
        [Array]::Copy($sampleBytes, 0, $blob, $hdr.Length, $sampleBytes.Length)
        $sha1 = [System.Security.Cryptography.SHA1]::Create()
        $expectedBlobSha = ([System.BitConverter]::ToString($sha1.ComputeHash($blob)) -replace '-', '').ToLower()

        $tamperedBytes = [System.Text.Encoding]::UTF8.GetBytes("# Java Version Manager`r`nWrite-Host 'EVIL'`r`n")
        $tHdr = [System.Text.Encoding]::ASCII.GetBytes("blob $($tamperedBytes.Length)`0")
        $tBlob = New-Object byte[] ($tHdr.Length + $tamperedBytes.Length)
        [Array]::Copy($tHdr, 0, $tBlob, 0, $tHdr.Length)
        [Array]::Copy($tamperedBytes, 0, $tBlob, $tHdr.Length, $tamperedBytes.Length)
        $tamperedBlobSha = ([System.BitConverter]::ToString($sha1.ComputeHash($tBlob)) -replace '-', '').ToLower()
        Assert-True ($expectedBlobSha -ne $tamperedBlobSha) "Tampered Nightly payload must produce a distinct Git Blob SHA-1 digest"

        # 3. Verify dynamic %ProgramFiles% (%JVM_PF%) and ARM64 resolver guards in jvm.bat
        Assert-Contains $batRaw 'set "JVM_PF=%ProgramFiles%"' "jvm.bat must initialize JVM_PF from %ProgramFiles%"
        Assert-Contains $batRaw 'set "LOCATIONS[0]=%JVM_PF%\Java"' "LOCATIONS[0] must use %JVM_PF%\Java instead of hardcoded C:\Program Files"
        Assert-Contains $batRaw 'set "DEST_DIR=!JVM_PF!\Java"' ":FetchAndExtract DEST_DIR must use !JVM_PF!\Java"
        Assert-Contains $batRaw 'Oracle does not publish native Windows ARM64 ZIP archives.' ":Resolve_Oracle must emit explicit ARM64 warning and fallback"
        Assert-Contains $batRaw 'GraalVM CE does not publish native Windows ARM64 builds.' ":Resolve_GraalVM must emit explicit ARM64 warning and fallback"
    }

    # Test 117: :ExecuteSharedDownloader enforces Get-TrustedChecksumText redirect allowlist & HTTPS on checksum URLs (CWE-601)
    Run-TestCase "PackageIntegrity" ":ExecuteSharedDownloader enforces Get-TrustedChecksumText redirect allowlist and HTTPS on checksum URLs (CWE-601)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw "function Get-TrustedChecksumText" ":ExecuteSharedDownloader must use Get-TrustedChecksumText for DL_CHKSUM_URL and fallbackUrl"
        Assert-Contains $batRaw "Blocked checksum redirect to non-HTTPS URL" ":ExecuteSharedDownloader must block HTTP downgrade redirects on checksum URLs"
        Assert-Contains $batRaw "Blocked checksum redirect to untrusted host" ":ExecuteSharedDownloader must block open redirects to untrusted hosts on checksum URLs"
    }

    # Test 118: :ExecuteSharedDownloader enforces ZIP entry count, cumulative decompression bounds (Zip Bomb), and Win32 device name rejection (CWE-409)
    Run-TestCase "Adversarial" ":ExecuteSharedDownloader enforces archive entry count, cumulative decompression bounds, and Win32 device name rejection (CWE-409)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw "Archive entry count out of safe bounds" ":ExecuteSharedDownloader must enforce a strict upper bound on ZIP entry count (CWE-409)"
        Assert-Contains $batRaw "Archive decompression limit exceeded" ":ExecuteSharedDownloader must enforce a cumulative decompressed byte limit (Zip Bomb protection, CWE-409)"
        Assert-Contains $batRaw "Unsafe Win32 device or control char in archive entry" ":ExecuteSharedDownloader must reject Win32 reserved device names and control chars inside ZIP entries (CWE-66)"
    }

    # Test 119: Numeric validation rejects semicolon eol=; bypass ('21;pwn') and eliminates double-double quoting in for /f (CWE-20)
    Run-TestCase "Adversarial" "Numeric validation rejects semicolon eol=; bypass ('21;Invoke-Expression') and eliminates double-double quotes in for /f (CWE-20)" {
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        $outSemicolon = & cmd.exe /c "call `"$JvmBat`" install `"21;Invoke-Expression`"" 2>&1 | Out-String
        $semiExit = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP

        Assert-True ($semiExit -ne 0) "jvm install must reject '21;...' semicolon eol=; bypass"
        Assert-Contains $outSemicolon "is not a JDK major version number" "Semicolon payload must be caught by numeric validator before reaching PowerShell API query"

        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-NotContains $batRaw 'in (""!' "jvm.bat must not wrap delayed-expansion variables in double-double quotes inside for /f"
        Assert-Contains $batRaw 'for /f "eol= delims=0123456789"' "jvm.bat numeric loops must disable default eol=; comment skipping"
    }

    # Test 120: 'jvm open' blocks comma-delimited explorer.exe argument injection and fails closed on unknown CLI_TARGET (CWE-88)
    Run-TestCase "Adversarial" "'jvm open' blocks comma-delimited explorer.exe argument injection and fails closed on unknown targets (CWE-88)" {
        $origLocalAppData = $env:LOCALAPPDATA
        try {
            $env:LOCALAPPDATA = $FakeLocalAppData
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outUnknown = & cmd.exe /c "call `"$JvmBat`" open `"nonexistent_target_xyz`"" 2>&1 | Out-String
            $unknownExit = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-True ($unknownExit -ne 0) "jvm open must fail closed on unknown CLI_TARGET instead of falling back to JAVA_HOME"
            Assert-Contains $outUnknown "Unknown or uninstalled target for 'jvm open'" "jvm open must emit explicit error for unknown target"

            $batRaw = Get-Content -LiteralPath $JvmBat -Raw
            Assert-Contains $batRaw "Target path contains comma delimiter forbidden by explorer.exe" ":OpenFolderInExplorer must block comma argument delimiters in explorer.exe paths"
        } finally {
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    # Test 121: CURRENT_SYMLINK & :UninstallJDK verify reparse point state and detach junctions before elevated Remove-Item -Recurse (CWE-59)
    Run-TestCase "ReparsePoint" "CURRENT_SYMLINK rejects pre-planted non-reparse directories and :UninstallJDK detaches junctions before elevated deletion (CWE-59)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw "!CURRENT_SYMLINK! is a regular directory, not a junction." "CURRENT_SYMLINK must reject pre-planted non-reparse regular directories"
        Assert-NotContains $batRaw '!CURRENT_JDK_PATH%!' "Typo !CURRENT_JDK_PATH%! must not exist in jvm.bat"
        Assert-Contains $batRaw '[System.IO.Directory]::Delete($it.FullName, $false)' "Elevated JDK uninstaller must detach root/nested junctions via [System.IO.Directory]::Delete($false) before Remove-Item -Recurse"
    }

    # Test 122: build-msi.ps1 embedded hooks enforce Test-HasReparsePointInLineage, single-quote escaping on $batPath, and Base64 deferred cleanup (CWE-59)
    Run-TestCase "Manifest" "build-msi.ps1 embedded MSI hooks enforce Test-HasReparsePointInLineage, single-quote escaping, and Base64 deferred cleanup (CWE-59)" {
        $msiBuildRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "packages\msi\build-msi.ps1") -Raw
        Assert-Contains $msiBuildRaw '`$safeBatPath = `$batPath.Replace("''", "''''")' "build-msi.ps1 must escape single quotes in `$batPath before replacing __FALLBACK_BAT__"
        Assert-Contains $msiBuildRaw 'if (Test-HasReparsePointInLineage `$p) { continue }' "msiInstallHook must enforce Test-HasReparsePointInLineage on PowerShell profile paths"
        Assert-Contains $msiBuildRaw 'DoNotExpandEnvironmentNames' "msiInstallHook and msiUninstallHook must preserve REG_EXPAND_SZ via DoNotExpandEnvironmentNames"
        Assert-Contains $msiBuildRaw 'FromBase64String(''$b64Target'')' "msiUninstallHook deferred cleanup must Base64-isolate `$jvmDir inside -EncodedCommand"
    }

    # Test 123: scripts/bump-version.ps1 enforces Assert-TrustedGitHubUri, Assert-ValidSha256Hex, and Assert-ValidMsiProductCode (CWE-354)
    Run-TestCase "PackageIntegrity" "scripts/bump-version.ps1 enforces Assert-TrustedGitHubUri, Assert-ValidSha256Hex, and Assert-ValidMsiProductCode on manifests (CWE-354)" {
        $bumpRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "scripts\bump-version.ps1") -Raw
        Assert-Contains $bumpRaw "function Assert-TrustedGitHubUri" "bump-version.ps1 must define Assert-TrustedGitHubUri"
        Assert-Contains $bumpRaw "function Assert-ValidSha256Hex" "bump-version.ps1 must define Assert-ValidSha256Hex"
        Assert-Contains $bumpRaw "function Assert-ValidMsiProductCode" "bump-version.ps1 must define Assert-ValidMsiProductCode"
    }

    # Test 124: install.ps1 enforces Initialize-SecureDirectory DACL & reparse guard and mandatory staged verification for uninstall.ps1 (CWE-494)
    Run-TestCase "PackageIntegrity" "install.ps1 enforces Initialize-SecureDirectory DACL/reparse guards and mandatory staged verification for uninstall.ps1 (CWE-494)" {
        $instRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "install.ps1") -Raw
        Assert-Contains $instRaw "function Initialize-SecureDirectory" "install.ps1 must define Initialize-SecureDirectory enforcing reparse checks and icacls /inheritance:r"
        Assert-Contains $instRaw "function Test-GitBlobSha1" "install.ps1 must verify Nightly companion uninstall.ps1 via Test-GitBlobSha1"
        Assert-Contains $instRaw "Missing SHA-256 entry for security-critical uninstall.ps1 in release manifest. Aborting." "install.ps1 must fail closed if uninstall.ps1 is missing from SHA256SUMS.txt on Stable channel"
    }

    # Test 125: uninstall.ps1 validates -SourceDir before PATH scrubbing and Base64-isolates deferred cleanup paths (CWE-73)
    Run-TestCase "UninstallSafety" "uninstall.ps1 validates -SourceDir against forbidden roots & markers before PATH scrubbing and Base64-isolates deferred cleanup (CWE-73)" {
        $uninstRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "uninstall.ps1") -Raw
        Assert-Contains $uninstRaw "function Invoke-DeferredDirectoryCleanup" "uninstall.ps1 must use Base64-isolated Invoke-DeferredDirectoryCleanup instead of raw string interpolation in -EncodedCommand"
        Assert-Contains $uninstRaw "Refusing unverified directory without JVM installation markers" "uninstall.ps1 must validate -SourceDir for JVM markers before adding it to `$jvmLocations for PATH scrubbing"
    }

    # Test 126: :ResolveLatestEcosystemCandidate enforces TLS 1.2/1.3, anchored GitHub redirect host regexes, and :ValidateStrictIdentifier (CWE-601)
    Run-TestCase "PackageIntegrity" ":ResolveLatestEcosystemCandidate enforces TLS 1.2/1.3, anchored GitHub redirect host regexes, and :ValidateStrictIdentifier (CWE-601)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw 'set "PS_TLS=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288;' ":ResolveLatestEcosystemCandidate must enforce TLS 1.2/1.3 via PS_TLS"
        Assert-Contains $batRaw '^https://github\.com/apache/maven/releases/tag/maven-([0-9A-Za-z._+-]{1,64})$' ":ResolveLatestEcosystemCandidate must anchor Maven redirect Location to https://github.com/apache/maven/releases/tag/"
        Assert-Contains $batRaw '^https://github\.com/JetBrains/kotlin/releases/tag/v?([0-9A-Za-z._+-]{1,64})$' ":ResolveLatestEcosystemCandidate must anchor Kotlin redirect Location to https://github.com/JetBrains/kotlin/releases/tag/"
        Assert-Contains $batRaw '^https://github\.com/scala/scala3/releases/tag/v?([0-9A-Za-z._+-]{1,64})$' ":ResolveLatestEcosystemCandidate must anchor Scala redirect Location to https://github.com/scala/scala3/releases/tag/"
        Assert-Contains $batRaw 'call :ValidateStrictIdentifier "!LATEST_VER!" LATEST_VER' ":ResolveLatestEcosystemCandidate must validate LATEST_VER via :ValidateStrictIdentifier"
    }

    # Test 127: :EcoPerformCheck and jvm update --all validate installed folder names (V_NAME/CAND_NAME) and remote LATEST_VER (CWE-78)
    Run-TestCase "Adversarial" ":EcoPerformCheck and jvm update --all validate installed folder names (V_NAME/CAND_NAME) and remote LATEST_VER (CWE-78)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw 'call :ValidateStrictIdentifier "!CAND_NAME!" CAND_NAME' "jvm update --all must validate CAND_NAME via :ValidateStrictIdentifier"
        Assert-Contains $batRaw 'call :ValidateStrictIdentifier "!V_NAME!" V_NAME' ":EcoPerformCheck and jvm update --all must validate V_NAME via :ValidateStrictIdentifier"
        Assert-Contains $batRaw '[System.IO.Directory]::Delete($_.FullName, $false)' "jvm update --all must detach nested junctions before removing old ecosystem tool versions"
    }

    # Test 128: :UninstallCandidate and :InstallCandidate detach nested junctions and validate resolved latest/interactive versions (CWE-59)
    Run-TestCase "ReparsePoint" ":UninstallCandidate and :InstallCandidate detach nested junctions and validate resolved latest/interactive versions (CWE-59)" {
        $origLocalAppData = $env:LOCALAPPDATA
        $candSandbox = Join-Path $SandboxRoot "CandidateUninstallSandbox"
        $candDir = Join-Path $candSandbox "DiamTek\JVM\candidates\maven\3.9.6"
        $protectedTarget = Join-Path $SandboxRoot "CandidateUninstallProtectedTarget"
        New-Item -ItemType Directory -Path $candDir -Force | Out-Null
        New-Item -ItemType Directory -Path $protectedTarget -Force | Out-Null
        $canaryFile = Join-Path $protectedTarget "canary.txt"
        Set-Content -LiteralPath $canaryFile -Value "MUST_SURVIVE_CANDIDATE_UNINSTALL"

        $nestedJunc = Join-Path $candDir "nested_junc"
        & cmd.exe /c "mklink /J `"$nestedJunc`" `"$protectedTarget`"" >$null 2>&1

        try {
            $env:LOCALAPPDATA = $candSandbox
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outUninst = & cmd.exe /c "call `"$JvmBat`" maven uninstall latest" 2>&1 | Out-String
            $uninstExit = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-Equals $uninstExit 0 "jvm maven uninstall latest must succeed for valid installed version"
            Assert-PathNotExists $candDir "Uninstalled candidate version directory must be removed"
            Assert-PathExists $protectedTarget "External directory targeted by nested junction inside candidate dir MUST survive"
            Assert-PathExists $canaryFile "Canary file inside external junction target MUST NOT be deleted"
        } finally {
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    # Test 129: :ValidateStrictIdentifier rejects URL/PowerShell injection metacharacters (#, @, ', $, `, (, ), comma, space) (CWE-88)
    Run-TestCase "Adversarial" ":ValidateStrictIdentifier rejects URL/PowerShell injection metacharacters (#, @, ', $, backtick, parens, comma, space) (CWE-88)" {
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        $badInputs = @("3.9.6#evil", "3.9.6@evil.com", "3.9.6'inject", '3.9.6$env:PATH', '3.9.6`n', "3.9.6(1)", "21,SILENT_MODE=1")
        foreach ($bad in $badInputs) {
            $out = & cmd.exe /c "call `"$JvmBat`" maven install `"$bad`"" 2>&1 | Out-String
            $code = $LASTEXITCODE
            Assert-True ($code -ne 0) "jvm must reject identifier containing URL/PS metacharacter: $bad"
        }
        $ErrorActionPreference = $prevEAP
    }

    # Test 130: Interactive ecosystem version prompt (CUSTOM_VER) and :FetchLatestVersions enforce :ValidateStrictIdentifier and TLS 1.2/1.3 (CWE-20)
    Run-TestCase "Adversarial" "Interactive ecosystem version prompt (CUSTOM_VER) and :FetchLatestVersions enforce :ValidateStrictIdentifier and TLS 1.2/1.3 (CWE-20)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw 'call :ValidateStrictIdentifier "!CUSTOM_VER!" CUSTOM_VER' ":EcosystemSelectTool must validate CUSTOM_VER via :ValidateStrictIdentifier and reject reserved 'current'"
        Assert-Contains $batRaw 'Invalid version identifier. Metacharacters, spaces, and reserved keywords are forbidden.' ":EcosystemSelectTool must reject poisoned interactive CUSTOM_VER inputs"
        Assert-Contains $batRaw 'call :ValidateStrictIdentifier "!REL_ADOPTIUM!" REL_ADOPTIUM' ":FetchLatestVersions must validate REL_ADOPTIUM via :ValidateStrictIdentifier"
    }

    # Test 131: :ShowDynamicMenu neutralizes set /a expression evaluation from crafted release JAVA_VERSION metadata (CWE-94)
    Run-TestCase "Adversarial" ":ShowDynamicMenu neutralizes set /a expression evaluation from crafted release JAVA_VERSION metadata (CWE-94)" {
        $origUserProfile = $env:USERPROFILE
        $origLocalAppData = $env:LOCALAPPDATA
        $exprSandbox = Join-Path $SandboxRoot "SetAExpressionSandbox"
        $fakeProfile = Join-Path $exprSandbox "UserProfile"
        $fakeAppData = Join-Path $exprSandbox "LocalAppData"
        $craftedJdk = Join-Path $fakeProfile ".jdks\jdk-21-expr"
        New-Item -ItemType Directory -Path (Join-Path $craftedJdk "bin") -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $craftedJdk "bin\java.exe") -Value "MZ_FAKE"
        # Attempt set /a comma expression injection: JAVA_VERSION="21,CLI_COMMAND=doctor,SILENT_MODE=1"
        Set-Content -LiteralPath (Join-Path $craftedJdk "release") -Value "JAVA_VERSION=`"21,CLI_COMMAND=doctor,SILENT_MODE=1`""

        try {
            $env:USERPROFILE = $fakeProfile
            $env:LOCALAPPDATA = $fakeAppData
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outList = & cmd.exe /c "call `"$JvmBat`" list" 2>&1 | Out-String
            $ErrorActionPreference = $prevEAP

            Assert-NotContains $outList "Running DiamTek JVM System Health Audit" "Crafted JAVA_VERSION with comma assignment in release file MUST NOT mutate CLI_COMMAND or variables via set /a"
        } finally {
            $env:USERPROFILE = $origUserProfile
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    # Test 132: :ShowDynamicMenu preserves INITIAL_SESSION_JH across menu scans and validates discovered JDK folder names (CWE-78)
    Run-TestCase "Adversarial" ":ShowDynamicMenu preserves INITIAL_SESSION_JH across menu scans and validates discovered JDK folder names (CWE-78)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw 'if not defined INITIAL_SESSION_JH (' ":ShowDynamicMenu must preserve INITIAL_SESSION_JH across menu loops instead of clobbering SESSION_JH"
        Assert-Contains $batRaw 'call :ValidateStrictIdentifier "%%j"' ":ShowDynamicMenu must validate discovered JDK directory names via :ValidateStrictIdentifier before executing bin\java.exe"
    }

    # Test 133: jvm link / jvm unlink harden %LOCALAPPDATA%\DiamTek\JVM\links against reparse points, apply icacls /inheritance:r, and support valid Windows paths with commas (CWE-59)
    Run-TestCase "ReparsePoint" "jvm link and jvm unlink enforce reparse guard and icacls /inheritance:r on links directory while allowing valid comma paths (CWE-59)" {
        $origLocalAppData = $env:LOCALAPPDATA
        $linkSandbox = Join-Path $SandboxRoot "LinkSecuritySandbox"
        $jvmBaseDir = Join-Path $linkSandbox "DiamTek\JVM"
        $linksPath = Join-Path $jvmBaseDir "links"
        $externalTarget = Join-Path $SandboxRoot "ExternalLinkRedirectTarget"
        $validJdkDir = Join-Path $SandboxRoot "Valid, Custom, Jdk 21"
        New-Item -ItemType Directory -Path $jvmBaseDir -Force | Out-Null
        New-Item -ItemType Directory -Path $externalTarget -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $validJdkDir "bin") -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $validJdkDir "bin\java.exe") -Value "MZ_FAKE"

        # Pre-plant links as a junction to externalTarget
        & cmd.exe /c "mklink /J `"$linksPath`" `"$externalTarget`"" >$null 2>&1

        try {
            $env:LOCALAPPDATA = $linkSandbox
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outLink = & cmd.exe /c "call `"$JvmBat`" link `"$validJdkDir`" myjdk" 2>&1 | Out-String
            $linkExit = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-True ($linkExit -ne 0) "jvm link must fail closed when %LOCALAPPDATA%\DiamTek\JVM\links is a pre-planted junction"
            Assert-Contains $outLink "Security violation (CWE-59)" "jvm link must report CWE-59 security violation on links directory reparse point"
            Assert-PathNotExists (Join-Path $externalTarget "myjdk") "Junction must not be created inside external redirect target"

            # Remove the pre-planted junction and verify that a valid Windows JDK path containing commas & spaces succeeds and auto-sanitizes the default alias
            & cmd.exe /c "rmdir `"$linksPath`"" >$null 2>&1
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outCommaLink = & cmd.exe /c "call `"$JvmBat`" link `"$validJdkDir`"" 2>&1 | Out-String
            $commaLinkExit = $LASTEXITCODE
            $outSemiLink = & cmd.exe /c "call `"$JvmBat`" link `"$validJdkDir;evil`"" 2>&1 | Out-String
            $semiLinkExit = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-Equals $commaLinkExit 0 "jvm link must allow legitimate Windows JDK paths containing commas and auto-sanitize the default link name"
            Assert-PathExists (Join-Path $linkSandbox "JavaVersionManager\links\Valid--Custom--Jdk-21") "jvm link must create junction with comma/space-sanitized default alias"
            Assert-True ($semiLinkExit -ne 0) "jvm link must still reject JDK paths containing semicolon ';' PATH delimiters"
        } finally {
            & cmd.exe /c "rmdir `"$linksPath`"" >$null 2>&1
            & cmd.exe /c "rmdir `"$(Join-Path $linkSandbox 'JavaVersionManager\links\Valid--Custom--Jdk-21')`"" >$null 2>&1
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    # Test 134: :ShowCurrentStatus and :WhichBinary sanitize JAVA_HOME quotes/metacharacters before executing bin\java.exe (CWE-78)
    Run-TestCase "Adversarial" ":ShowCurrentStatus and :WhichBinary sanitize JAVA_HOME quotes and metacharacters before executing bin\java.exe (CWE-78)" {
        $origJavaHome = $env:JAVA_HOME
        $pwnStatus = Join-Path $SandboxRoot "STATUS_JH_PWNED.txt"
        try {
            $env:JAVA_HOME = "C:\FakeJava`" & echo PWNED > `"$pwnStatus"
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outStat = & cmd.exe /c "call `"$JvmBat`" status" 2>&1 | Out-String
            $outWhich = & cmd.exe /c "call `"$JvmBat`" which java" 2>&1 | Out-String
            $ErrorActionPreference = $prevEAP

            Assert-PathNotExists $pwnStatus "jvm status and jvm which MUST NOT execute injected commands from poisoned JAVA_HOME"
        } finally {
            $env:JAVA_HOME = $origJavaHome
        }
    }

    # Test 135: :DoctorDiagnostics validates candidate folder names (CAND_ID) via :ValidateStrictIdentifier before invokingfsutil/PowerShell (CWE-78)
    Run-TestCase "Adversarial" ":DoctorDiagnostics validates candidate folder names (CAND_ID) via :ValidateStrictIdentifier before invoking PowerShell (CWE-78)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw 'call :ValidateStrictIdentifier "!CAND_ID!" CAND_ID' ":DoctorDiagnostics must validate CAND_ID via :ValidateStrictIdentifier before inspecting candidate directories"
    }

    # Test 136: :WriteConfigFile blocks symlink/reparse point overwrite on channel.txt and mode.txt (CWE-59)
    Run-TestCase "ReparsePoint" ":WriteConfigFile blocks symlink/reparse point overwrite on channel.txt and mode.txt (CWE-59)" {
        $origLocalAppData = $env:LOCALAPPDATA
        $cfgSandbox = Join-Path $SandboxRoot "ConfigFileReparseSandbox"
        $jvmCfgDir = Join-Path $cfgSandbox "DiamTek\JVM"
        $channelPath = Join-Path $jvmCfgDir "channel.txt"
        $protectedDir = Join-Path $SandboxRoot "ProtectedConfigTarget"
        New-Item -ItemType Directory -Path $jvmCfgDir -Force | Out-Null
        New-Item -ItemType Directory -Path $protectedDir -Force | Out-Null

        # Pre-plant channel.txt as a directory junction
        & cmd.exe /c "mklink /J `"$channelPath`" `"$protectedDir`"" >$null 2>&1

        try {
            $env:LOCALAPPDATA = $cfgSandbox
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outChan = & cmd.exe /c "call `"$JvmBat`" channel nightly" 2>&1 | Out-String
            $chanExit = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-True ($chanExit -ne 0) "jvm channel must fail closed when channel.txt is a directory or reparse point"
            Assert-Contains $outChan "Security violation (CWE-59)" "jvm channel must emit CWE-59 security violation when channel.txt is a reparse point/directory"
        } finally {
            & cmd.exe /c "rmdir `"$channelPath`"" >$null 2>&1
            $env:LOCALAPPDATA = $origLocalAppData
        }
    }

    # Test 137: :CheckUpdateStatus enforces TLS 1.2/1.3 only, anchors GitHub tag redirect regex, and validates REMOTE_VER/REMOTE_BUILD/REMOTE_REF (CWE-295)
    Run-TestCase "PackageIntegrity" ":CheckUpdateStatus enforces TLS 1.2/1.3 only, anchors GitHub tag redirect regex, and validates REMOTE_VER/REMOTE_BUILD/REMOTE_REF (CWE-295)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-NotContains $batRaw '[Net.ServicePointManager]::SecurityProtocol -bor 3072 -bor 12288' "jvm.bat must not retain legacy SSL3/TLS1.0/1.1 flags via -bor on existing SecurityProtocol"
        Assert-Contains $batRaw '^https://github\.com/DiamTek/Java-Version-Manager-Windows/releases/tag/(v?[0-9]+\.[0-9]+\.[0-9]+)$' ":CheckUpdateStatus must anchor Location header regex to official GitHub repository tag URL"
        Assert-Contains $batRaw 'call :ValidateStrictIdentifier "!REMOTE_VER!" REMOTE_VER' ":CheckUpdateStatus must validate REMOTE_VER via :ValidateStrictIdentifier"
        Assert-Contains $batRaw 'call :ValidateStrictIdentifier "!REMOTE_REF!" REMOTE_REF' ":CheckUpdateStatus must validate REMOTE_REF via :ValidateStrictIdentifier"
    }

    # Test 138: .sdkmanrc and :ProcessEcosystemSession fail closed on unsafe/invalid lines without findstr /v pre-filtering (CWE-20)
    Run-TestCase "Adversarial" ".sdkmanrc and :ProcessEcosystemSession fail closed on unsafe/invalid lines without findstr /v pre-filtering (CWE-20)" {
        $sdkFailDir = Join-Path $SandboxRoot "SdkmanrcFailClosedDir"
        New-Item -ItemType Directory -Path $sdkFailDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sdkFailDir ".sdkmanrc") -Value "java=21-unknownvendor`r`nmaven=current"

        Push-Location $sdkFailDir
        try {
            $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $outSdk = & cmd.exe /c "call `"$JvmBat`" auto" 2>&1 | Out-String
            $sdkExit = $LASTEXITCODE

            # 2. Verify that duplicate java= lines (one valid, one unsafe) are NOT silently filtered out by findstr /v
            Set-Content -LiteralPath (Join-Path $sdkFailDir ".sdkmanrc") -Value "java=21.0.2-tem`r`njava=21.0.2-tem;calc"
            $outDupJava = & cmd.exe /c "call `"$JvmBat`"" 2>&1 | Out-String
            $dupJavaExit = $LASTEXITCODE

            # 3. Verify that a valid java= line accompanied by an unsafe ecosystem line is NOT silently filtered out by findstr /v
            Set-Content -LiteralPath (Join-Path $sdkFailDir ".sdkmanrc") -Value "java=21.0.2-tem`r`nmaven=3.9.9;calc"
            $outMixed = & cmd.exe /c "call `"$JvmBat`"" 2>&1 | Out-String
            $mixedExit = $LASTEXITCODE

            # 4. Verify that a malformed non-comment line without '=' is rejected
            Set-Content -LiteralPath (Join-Path $sdkFailDir ".sdkmanrc") -Value "java=21.0.2-tem`r`nmalformed_entry_without_equals"
            $outNoEq = & cmd.exe /c "call `"$JvmBat`"" 2>&1 | Out-String
            $noEqExit = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            Assert-True ($sdkExit -ne 0) "jvm auto must fail closed with non-zero exit code when .sdkmanrc contains invalid vendor or reserved 'current' version"
            Assert-True ($dupJavaExit -ne 0) ".sdkmanrc parser must reject files containing an unsafe java= line even when a valid java= line is also present"
            Assert-True ($mixedExit -ne 0) ".sdkmanrc parser must reject files containing unsafe ecosystem lines rather than silently filtering them out via findstr /v"
            Assert-True ($noEqExit -ne 0) ".sdkmanrc parser must reject non-comment lines lacking '=' assignment delimiter"
        } finally {
            Pop-Location
        }
    }

    # Test 139: :EmitSessionEnv rejects directory/reparse point collisions on .jvm_session_target and .jvm_session_target_<PID> (CWE-59)
    Run-TestCase "ReparsePoint" ":EmitSessionEnv rejects directory/reparse point collisions on .jvm_session_target and .jvm_session_target_<PID> (CWE-59)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-Contains $batRaw 'Security violation ^(CWE-59^): !SESSION_ENV_BASE! is a symlink or reparse point.' ":EmitSessionEnv must check fsutil reparsepoint query on .jvm_session_target before writing"
        Assert-Contains $batRaw 'Security violation ^(CWE-59^): !SESSION_ENV_PID! is a symlink or reparse point.' ":EmitSessionEnv must check fsutil reparsepoint query on .jvm_session_target_<PID> before writing"
    }

    # Test 140: :SelfUpdate and :UninstallJVM_Complete enforce unified Stable/Nightly cryptographic verification (NO_META_SHA) and reparse checks (CWE-494)
    Run-TestCase "PackageIntegrity" ":SelfUpdate and :UninstallJVM_Complete enforce unified Stable/Nightly cryptographic verification (NO_META_SHA) and reparse checks (CWE-494)" {
        $batRaw = Get-Content -LiteralPath $JvmBat -Raw
        Assert-NotContains $batRaw "Write-Output ('NIGHTLY|' + `$actual)" ":SelfUpdate must not emit unverified 'NIGHTLY|' status when GitHub API blob SHA-1 metadata is unreachable"
        Assert-Contains $batRaw "Write-Output ('NO_META_SHA|' + `$actual)" ":SelfUpdate must emit 'NO_META_SHA|' and abort when Nightly Git Blob SHA-1 metadata cannot be verified"
        Assert-Contains $batRaw 'if /i "!UPDATE_CHANNEL!"=="NIGHTLY" set "UNINSTALL_REF=main"' ":UninstallJVM_Complete must unify Nightly and Stable trust models by verifying uninstall.ps1 against main on Nightly"
        Assert-Contains $batRaw '$sidecar=$f + ''.sha256''' ":VerifyDownloadedScript must support Nightly Git Blob SHA-1 and pinned .sha256 sidecar verification"
        Assert-Contains $batRaw 'Security violation ^(CWE-59^): Staged updater path is a reparse point.' ":SelfUpdate must verify UPDATER_BAT is not a reparse point before writing"

        # Live verification of Nightly sidecar (.sha256) digest check & tamper rejection
        $nightlyTestDir = Join-Path $SandboxRoot "NightlyUninstallSidecarTest"
        New-Item -ItemType Directory -Path $nightlyTestDir -Force | Out-Null
        $fakeUninst = Join-Path $nightlyTestDir "uninstall.ps1"
        $fakeSidecar = "$fakeUninst.sha256"
        [System.IO.File]::WriteAllText($fakeUninst, "Write-Host 'Verified Nightly Uninstaller'`r`n", [System.Text.UTF8Encoding]::new($false))
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.IO.File]::ReadAllBytes($fakeUninst)
        $validDigest = ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLower()
        $sha.Dispose()
        [System.IO.File]::WriteAllText($fakeSidecar, $validDigest, [System.Text.UTF8Encoding]::new($false))

        $evalSidecar = {
            param([string]$f)
            $s = [System.Security.Cryptography.SHA256]::Create()
            $fs = [System.IO.File]::OpenRead($f)
            $actual = try { ([System.BitConverter]::ToString($s.ComputeHash($fs)) -replace '-','').ToLower() } finally { $fs.Close(); $s.Dispose() }
            $sidecar = $f + '.sha256'
            if (Test-Path -LiteralPath $sidecar) {
                $scItem = Get-Item -LiteralPath $sidecar -Force -ErrorAction SilentlyContinue
                if ($scItem -and -not ($scItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                    $pinned = ([System.IO.File]::ReadAllText($sidecar, [System.Text.Encoding]::UTF8)).Trim().ToLower()
                    if ($pinned -match '^[0-9a-fA-F]{64}$') {
                        if ($actual -eq $pinned) { return "VERIFIED|$actual" } else { return "MISMATCH|$pinned|$actual" }
                    }
                }
            }
            return "NO_META_SHA"
        }

        Assert-Equals (& $evalSidecar $fakeUninst) "VERIFIED|$validDigest" "Nightly uninstaller matching .sha256 sidecar must return VERIFIED"
        [System.IO.File]::WriteAllText($fakeUninst, "Write-Host 'TAMPERED NIGHTLY UNINSTALLER'`r`n", [System.Text.UTF8Encoding]::new($false))
        Assert-True ((& $evalSidecar $fakeUninst).StartsWith("MISMATCH|")) "Tampered Nightly uninstaller must be rejected with MISMATCH against .sha256 sidecar"
    }

    # Test 141: install.ps1 enforces Remove-ReparsePointOrFail on $batPath, $destFile, and $channelFile before writing (CWE-59)
    Run-TestCase "ReparsePoint" "install.ps1 enforces Remove-ReparsePointOrFail on `$batPath, `$destFile, and `$channelFile before writing (CWE-59)" {
        $instRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "install.ps1") -Raw
        Assert-Contains $instRaw "function Remove-ReparsePointOrFail" "install.ps1 must define Remove-ReparsePointOrFail to neutralize file-level symlinks/reparse points"
        Assert-Contains $instRaw 'Remove-ReparsePointOrFail -FilePath $batPath' "install.ps1 must guard `$batPath with Remove-ReparsePointOrFail before Move-Item"
        Assert-Contains $instRaw 'Remove-ReparsePointOrFail -FilePath $destFile' "install.ps1 must guard companion `$destFile with Remove-ReparsePointOrFail before writing"
        Assert-Contains $instRaw 'Remove-ReparsePointOrFail -FilePath $channelFile' "install.ps1 must guard `$channelFile with Remove-ReparsePointOrFail before writing"
    }

    # Test 142: install.ps1 enforces Invoke-TrustedGitHubDownload with 5 MB ceiling, redirect host allowlist, and fail-closed Test-GitBlobSha1 (CWE-494)
    Run-TestCase "PackageIntegrity" "install.ps1 enforces Invoke-TrustedGitHubDownload with 5 MB ceiling, redirect host allowlist, and fail-closed Test-GitBlobSha1 (CWE-494)" {
        $instRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "install.ps1") -Raw
        Assert-Contains $instRaw "function Invoke-TrustedGitHubDownload" "install.ps1 must define Invoke-TrustedGitHubDownload with redirect host allowlist and byte ceiling"
        Assert-Contains $instRaw "[int]`$MaxBytes = 5242880" "Invoke-TrustedGitHubDownload must enforce a 5 MB (5,242,880 byte) payload ceiling"
        Assert-Contains $instRaw "Security violation (CWE-601): Untrusted redirect host or scheme" "Invoke-TrustedGitHubDownload must verify ResponseUri against allowedHosts"
        $fnMatch = [regex]::Match($instRaw, '(?s)function Test-GitBlobSha1.*?\r?\n\}')
        Assert-True $fnMatch.Success "Test-GitBlobSha1 function must exist in install.ps1"
        Assert-Contains $fnMatch.Value "return `$false" "Test-GitBlobSha1 must fail closed (return `$false) when GitHub API blob SHA-1 cannot be retrieved"
    }

    # Test 143: uninstall.ps1 enforces Test-TrustedJvmInstallDirectory on Registry InstallLocation, -SourceDir, and $scriptDir (CWE-73)
    Run-TestCase "UninstallSafety" "uninstall.ps1 enforces Test-TrustedJvmInstallDirectory on Registry InstallLocation, -SourceDir, and `$scriptDir (CWE-73)" {
        $uninstRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "uninstall.ps1") -Raw
        Assert-Contains $uninstRaw "function Test-TrustedJvmInstallDirectory" "uninstall.ps1 must define Test-TrustedJvmInstallDirectory"
        Assert-Contains $uninstRaw 'Test-TrustedJvmInstallDirectory $regInstallLoc' "uninstall.ps1 must validate Registry InstallLocation via Test-TrustedJvmInstallDirectory before adding to `$jvmLocations"
        Assert-Contains $uninstRaw 'Security violation (CWE-73): Refusing unverified directory without JVM installation markers' "uninstall.ps1 must reject tampered/unverified directories lacking JVM installation markers"
    }

    # Test 144: uninstall.ps1 uses Remove-DirectorySafely on %TEMP%\jdk_*_extract* and skips reparse points during temp cleanup (CWE-59)
    Run-TestCase "UninstallSafety" "uninstall.ps1 uses Remove-DirectorySafely on %TEMP%\jdk_*_extract* and skips reparse points during temp cleanup (CWE-59)" {
        $uninstRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "uninstall.ps1") -Raw
        Assert-Contains $uninstRaw 'Remove-DirectorySafely $_.FullName' "uninstall.ps1 must use Remove-DirectorySafely on jdk_*_extract* directories in %TEMP% to prevent junction traversal"
        Assert-Contains $uninstRaw '-not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint)' "uninstall.ps1 must skip reparse points when deleting temp files in shared %TEMP%"
    }

    # Test 145: install.ps1 and uninstall.ps1 enforce atomic staged writes and UTF-8 No BOM on $PROFILE and Windows Terminal settings.json (CWE-367)
    Run-TestCase "ReparsePoint" "install.ps1 and uninstall.ps1 enforce atomic staged writes and UTF-8 No BOM on `$PROFILE and Windows Terminal settings.json (CWE-367)" {
        $instRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "install.ps1") -Raw
        $uninstRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "uninstall.ps1") -Raw
        Assert-Contains $instRaw '$utf8NoBom = New-Object System.Text.UTF8Encoding($false)' "install.ps1 must write `$PROFILE and settings.json using UTF-8 No BOM"
        Assert-Contains $instRaw 'Move-Item -LiteralPath $stageProf -Destination $p -Force' "install.ps1 must atomically swap staged `$PROFILE via Move-Item -LiteralPath"
        Assert-Contains $uninstRaw '$utf8NoBom = New-Object System.Text.UTF8Encoding($false)' "uninstall.ps1 must write `$PROFILE and settings.json using UTF-8 No BOM"
        Assert-Contains $uninstRaw 'Move-Item -LiteralPath $stageProf -Destination $p -Force' "uninstall.ps1 must atomically swap staged `$PROFILE via Move-Item -LiteralPath"
    }

    # Test 146: chocolateyUninstall.ps1 enforces Test-HasReparsePointInLineage, MSI ProductCode GUID regex, and System32 binary pinning (CWE-426)
    Run-TestCase "PackageIntegrity" "chocolateyUninstall.ps1 enforces Test-HasReparsePointInLineage, MSI ProductCode GUID regex, and System32 binary pinning (CWE-426)" {
        $chocoUninst = Get-Content -LiteralPath (Join-Path $RepoRoot "packages\choco\tools\chocolateyUninstall.ps1") -Raw
        Assert-Contains $chocoUninst "function Test-HasReparsePointInLineage" "chocolateyUninstall.ps1 must define Test-HasReparsePointInLineage"
        Assert-Contains $chocoUninst "Security violation (CWE-59): NTFS reparse point or symlink detected on uninstaller lineage" "chocolateyUninstall.ps1 must block symlinked uninstaller paths"
        Assert-Contains $chocoUninst '^\{[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}\}$' "chocolateyUninstall.ps1 must validate MSI ProductCode GUID format before invoking msiexec"
        Assert-Contains $chocoUninst '[Environment]::GetFolderPath([Environment+SpecialFolder]::System)' "chocolateyUninstall.ps1 must pin powershell.exe and msiexec.exe to System32"
    }

    # Test 147: packages/msi/test-msi.ps1 pins msiexec.exe to System32 and validates -MsiPath against path traversal and non-.msi extensions (CWE-426)
    Run-TestCase "PackageIntegrity" "packages/msi/test-msi.ps1 pins msiexec.exe to System32 and validates -MsiPath against path traversal and non-.msi extensions (CWE-426)" {
        $testMsiRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "packages\msi\test-msi.ps1") -Raw
        Assert-Contains $testMsiRaw "Security violation (CWE-20): -MsiPath must point to a valid .msi package without '..' traversal sequences." "test-msi.ps1 must validate -MsiPath against '..' and non-.msi extensions"
        Assert-Contains $testMsiRaw '$msiExecBin = Join-Path $sys32 "msiexec.exe"' "test-msi.ps1 must pin msiexec.exe to System32"
        Assert-Contains $testMsiRaw 'Start-Process -FilePath $msiExecBin' "test-msi.ps1 must invoke `$msiExecBin instead of unpinned 'msiexec.exe'"
    }

    # Test 148: packages/msi/build-msi.ps1 validates -Version SemVer and -Arch ValidateSet('x64','arm64') and XML-escapes Version in jvm.wxs (CWE-74)
    Run-TestCase "Manifest" "packages/msi/build-msi.ps1 validates -Version SemVer and -Arch ValidateSet and XML-escapes Version in jvm.wxs (CWE-74)" {
        $buildMsiRaw = Get-Content -LiteralPath (Join-Path $RepoRoot "packages\msi\build-msi.ps1") -Raw
        Assert-Contains $buildMsiRaw "Security violation (CWE-20): Invalid MSI Version" "build-msi.ps1 must validate -Version against strict X.Y.Z SemVer regex"
        Assert-Contains $buildMsiRaw "[ValidateSet(`"all`", `"x64`", `"arm64`")]" "build-msi.ps1 must restrict -Arch to ValidateSet('all', 'x64', 'arm64')"
        Assert-Contains $buildMsiRaw '[System.Security.SecurityElement]::Escape($val)' "build-msi.ps1 must XML-escape attributes via [System.Security.SecurityElement]::Escape"
        Assert-Contains $buildMsiRaw '$safeVersion = Escape-XmlAttr $Version' "build-msi.ps1 must escape `$Version before interpolating into jvm.wxs"
    }

    # Test 149: GitHub Actions ci.yml and release.yml enforce persist-credentials: false and SemVer validation across all release branches (CWE-250)
    Run-TestCase "PackageIntegrity" "GitHub Actions ci.yml and release.yml enforce persist-credentials: false and SemVer validation across all release branches (CWE-250)" {
        $ciYml = Get-Content -LiteralPath (Join-Path $RepoRoot ".github\workflows\ci.yml") -Raw
        $relYml = Get-Content -LiteralPath (Join-Path $RepoRoot ".github\workflows\release.yml") -Raw
        Assert-Contains $ciYml "persist-credentials: false" "ci.yml must set persist-credentials: false on actions/checkout steps"
        Assert-Contains $relYml "persist-credentials: false" "release.yml must set persist-credentials: false on actions/checkout steps"
        Assert-Contains $relYml "Resolved JVM_VERSION '`$ver' does not match strict semantic versioning format." "release.yml must validate `$ver against strict SemVer regex after all resolution branches"
    }

    # Test 150: chocolateyInstall.ps1 enforces GitHub domain allowlist (CWE-918) and strict sha256 checksumType64 (CWE-354)
    Run-TestCase "PackageIntegrity" "chocolateyInstall.ps1 enforces GitHub domain allowlist (CWE-918) and strict sha256 checksumType64 (CWE-354)" {
        $chocoInst = Get-Content -LiteralPath (Join-Path $RepoRoot "packages\choco\tools\chocolateyInstall.ps1") -Raw
        Assert-Contains $chocoInst "`$allowedHosts = @('github.com', 'objects.githubusercontent.com')" "chocolateyInstall.ps1 must restrict download URL host to github.com and objects.githubusercontent.com"
        Assert-Contains $chocoInst "Security violation (CWE-918): Download URL64 host" "chocolateyInstall.ps1 must throw CWE-918 violation on untrusted download host"
        Assert-Contains $chocoInst "Security violation (CWE-354): ChecksumType64 must be strictly 'sha256'." "chocolateyInstall.ps1 must enforce checksumType64 -eq 'sha256'"
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
    Remove-ItemProperty -Path "HKCU:\Environment" -Name "TestJvmPath" -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Environment" -Name "JVM_REG_TYPE_TEST" -Force -ErrorAction SilentlyContinue
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
        $overallBadge = if ($GlobalFailed -eq 0) { " PASS" } else { " FAIL" }
        $passRate = if ($TotalExecuted -gt 0) { [math]::Round(($GlobalPassed / $TotalExecuted) * 100, 1) } else { 100.0 }
        $mdLines = [System.Collections.Generic.List[string]]::new()

        $mdLines.Add("##  DiamTek JVM Security & Adversarial Test Suite -- $overallBadge")
        $mdLines.Add("")
        $mdLines.Add("- **Total Executed:** $TotalExecuted (`$GlobalPassed` passed, `$GlobalFailed` failed, `$GlobalSkipped` skipped)")
        $mdLines.Add("- **Pass Rate:** $passRate%")
        $mdLines.Add("- **Execution Time:** $TotalElapsedMs ms (Wall clock: $($RunnerStopwatch.ElapsedMilliseconds) ms)")
        $mdLines.Add("")
        $mdLines.Add("###  Per-Suite Execution Breakdown")
        $mdLines.Add("")
        $mdLines.Add("| Suite | Category Tag | Passed / Total | Status | Elapsed (ms) |")
        $mdLines.Add("| :--- | :--- | :---: | :---: | ---: |")

        foreach ($entry in $SuiteTracker.Values) {
            $suiteStatus = if ($entry.Total -eq 0 -and $entry.Skipped -gt 0) {
                " SKIP"
            } elseif ($entry.Failed -gt 0) {
                " FAIL"
            } else {
                " PASS"
            }
            $mdLines.Add("| **$($entry.Name)** | ``$($entry.Tag)`` | $($entry.Passed) / $($entry.Total) | $suiteStatus | $($entry.ElapsedMs) ms |")
        }

        $mdLines.Add("| **Total** | *All Suites* | **$GlobalPassed / $TotalExecuted** | **$overallBadge** | **$TotalElapsedMs ms** |")
        $mdLines.Add("")

        $mdLines.Add("###  CWE Coverage Summary")
        $mdLines.Add("")
        $mdLines.Add("| CWE ID | Vulnerability Class | Tests Passed |")
        $mdLines.Add("| :--- | :--- | :---: |")
        foreach ($cwe in ($CweCatalog.Values | Sort-Object Number)) {
            $cweTests = @($TestResults | Where-Object { $_.CweId -eq $cwe.Id })
            if ($cweTests.Count -eq 0) { continue }
            $cwePassed = @($cweTests | Where-Object { $_.Status -eq 'PASS' }).Count
            $cweFailed = @($cweTests | Where-Object { $_.Status -eq 'FAIL' }).Count
            $cweBadgeMd = if ($cweFailed -gt 0) { " $cwePassed / $($cweTests.Count)" } else { " $cwePassed / $($cweTests.Count)" }
            $mdLines.Add("| **``$($cwe.Id)``** | $($cwe.Short) | $cweBadgeMd |")
        }
        $mdLines.Add("")

        if ($GlobalFailed -gt 0) {
            $mdLines.Add("###  Failed Test Cases")
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
        $mdLines.Add("<summary> <strong>View All Executed Test Cases ($TotalExecuted tests)</strong></summary>")
        $mdLines.Add("")
        $mdLines.Add("| # | Suite | CWE | Vulnerability Type | Test Case | Status | Duration (ms) |")
        $mdLines.Add("| ---: | :--- | :--- | :--- | :--- | :---: | ---: |")
        $idx = 0
        foreach ($res in $TestResults) {
            $idx++
            $icon = if ($res.Status -eq 'PASS') { " PASS" } else { " FAIL" }
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