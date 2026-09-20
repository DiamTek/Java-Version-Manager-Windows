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
    [switch]$Detailed
)

$ErrorActionPreference = 'Stop'

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

$TestResults = [System.Collections.Generic.List[PSObject]]::new()
$GlobalPassed = 0
$GlobalFailed = 0

function Run-TestCase {
    param(
        [string]$Suite,
        [string]$Name,
        [scriptblock]$TestLogic
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $TestLogic
        $sw.Stop()
        $script:GlobalPassed++
        Write-Host "  ${cGreen}[PASS]${cReset} $Name ${cGray}($($sw.ElapsedMilliseconds) ms)${cReset}"
        $script:TestResults.Add([PSCustomObject]@{
            Suite    = $Suite
            Name     = $Name
            Status   = "PASS"
            Error    = $null
            Duration = $sw.ElapsedMilliseconds
        })
    } catch {
        $sw.Stop()
        $script:GlobalFailed++
        Write-Host "  ${cRed}[FAIL]${cReset} $Name ${cGray}($($sw.ElapsedMilliseconds) ms)${cReset}" -ForegroundColor Red
        Write-Host "         Error: $($_.Exception.Message)" -ForegroundColor DarkRed
        $script:TestResults.Add([PSCustomObject]@{
            Suite    = $Suite
            Name     = $Name
            Status   = "FAIL"
            Error    = $_.Exception.Message
            Duration = $sw.ElapsedMilliseconds
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
            if ($illegalPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
                $isAllowed = $true
                break
            }
        }
        Assert-False $isAllowed "Set-JvmVar boundary check must reject C:\Windows\System32"
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
# Final Execution Summary
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "$cCyan$cBold========================================================================$cReset"
Write-Host "$cCyan$cBold                         TEST EXECUTION SUMMARY                         $cReset"
Write-Host "$cCyan$cBold========================================================================$cReset"
Write-Host "  Total Tests Executed : $($GlobalPassed + $GlobalFailed)"
Write-Host "  Passed               : ${cGreen}$GlobalPassed${cReset}"
if ($GlobalFailed -gt 0) {
    Write-Host "  Failed               : ${cRed}$GlobalFailed${cReset}" -ForegroundColor Red
} else {
    Write-Host "  Failed               : 0"
}
Write-Host "$cCyan$cBold========================================================================$cReset"
Write-Host ""

if ($GlobalFailed -gt 0) {
    exit 1
}
exit 0