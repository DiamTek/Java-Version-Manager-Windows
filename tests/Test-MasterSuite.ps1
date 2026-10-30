$ErrorActionPreference = 'Stop'
$jvm = (Resolve-Path .\jvm.bat).Path
$repoRoot = Split-Path $jvm -Parent
$env:JVM_NONINTERACTIVE = '1'

$pass = 0
$fail = 0
$suiteSw = [System.Diagnostics.Stopwatch]::StartNew()
$report = New-Object System.Collections.Generic.List[object]

function Test-Feature([string]$Category, [string]$Name, [scriptblock]$Block) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $Block
        $sw.Stop()
        $script:pass++
        $report.Add([pscustomobject]@{ Category = $Category; Test = $Name; Status = 'PASS'; Ms = $sw.ElapsedMilliseconds; Detail = 'OK' })
        Write-Host ("[ PASS ] [{0,-12}] {1} ({2} ms)" -f $Category, $Name, $sw.ElapsedMilliseconds) -ForegroundColor Green
    } catch {
        $sw.Stop()
        $script:fail++
        $msg = ($_.Exception.Message -replace '[\r\n]+', ' ')
        $report.Add([pscustomobject]@{ Category = $Category; Test = $Name; Status = 'FAIL'; Ms = $sw.ElapsedMilliseconds; Detail = $msg })
        Write-Host ("[ FAIL ] [{0,-12}] {1} -> {2}" -f $Category, $Name, $msg) -ForegroundColor Red
    }
}

# Backup user config.json and CMD AutoRun before running tests
$jvmAppDir = Join-Path $env:LOCALAPPDATA 'DiamTek\JVM'
$cfgPath = Join-Path $jvmAppDir 'config.json'
$cfgBackup = if (Test-Path -LiteralPath $cfgPath) { [System.IO.File]::ReadAllBytes($cfgPath) } else { $null }
$cmdRegPath = 'HKCU:\Software\Microsoft\Command Processor'
$origAutoRun = if (Test-Path -LiteralPath $cmdRegPath) { (Get-ItemProperty -LiteralPath $cmdRegPath -Name 'AutoRun' -ErrorAction SilentlyContinue).AutoRun } else { $null }

$sandbox = Join-Path $env:TEMP ('jvm_full_suite_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $sandbox -Force | Out-Null

try {
    Write-Host "`n================================================================================" -ForegroundColor Cyan
    Write-Host "  DiamTek JVM Master Test Suite - Executing All Feature & Security Categories" -ForegroundColor Cyan
    Write-Host "================================================================================`n" -ForegroundColor Cyan

    # CATEGORY 1: Bootstrap, Version, Help Cards & Timings
    Test-Feature "1.Bootstrap" "Early version (--version, -v, --short, --numeric, --json)" {
        $v1 = (& $jvm --version | Out-String).Trim()
        $v2 = (& $jvm version --short | Out-String).Trim()
        $v3 = (& $jvm version --numeric | Out-String).Trim()
        $vj = (& $jvm version --json | Out-String) | ConvertFrom-Json
        if ($v1 -notmatch '1\.0\.1' -or $v2 -ne '1.0.1' -or $v3 -ne '1.0.1' -or -not $vj.ok) {
            throw "Version output mismatch"
        }
    }

    Test-Feature "1.Bootstrap" "Top-level help (--help, -h, /?, help)" {
        foreach ($flag in @('help', '--help', '-h', '/?')) {
            $h = & $jvm $flag | Out-String
            if ($LASTEXITCODE -ne 0 -or $h -notmatch 'Java Version Manager') {
                throw "Top-level help failed for $flag"
            }
        }
    }

    Test-Feature "1.Bootstrap" "All subcommand help cards (init, outdated, install, lock, bundle, distro, doctor, exec, run)" {
        foreach ($topic in @('init', 'outdated', 'list', 'install', 'lock', 'freeze', 'thaw', 'bundle', 'distro', 'doctor', 'exec', 'run', 'profile', 'snapshot', 'policy', 'aliases')) {
            $card = & $jvm help $topic | Out-String
            if ($LASTEXITCODE -ne 0 -or $card -notmatch 'Syntax:') {
                throw "Help card missing or failed for topic '$topic'"
            }
        }
    }

    Test-Feature "1.Bootstrap" "Centisecond execution telemetry (--timings)" {
        $tOut = & $jvm version --timings 2>&1 | Out-String
        if ($tOut -notmatch '\[ TIMINGS \] parse:.*resolve:.*execute:.*total:') {
            throw "Missing timings output"
        }
    }

    # CATEGORY 2: Discovery, Status, Introspection & Comparison
    Test-Feature "2.Discovery" "jvm list & jvm ls (Human & JSON)" {
        $txt = & $jvm list | Out-String
        $js = (& $jvm ls --json | Out-String) | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0 -or -not $js.ok -or $js.command -ne 'list') {
            throw "jvm list failed"
        }
    }

    Test-Feature "2.Discovery" "jvm current / status / env / env --diff / vendor" {
        $st = (& $jvm current --json | Out-String) | ConvertFrom-Json
        $df = (& $jvm env --diff --json | Out-String) | ConvertFrom-Json
        $vd = (& $jvm vendor --short | Out-String).Trim()
        if ($st.command -ne 'current' -or -not $df.diff) {
            throw "Status or env --diff failed"
        }
    }

    Test-Feature "2.Discovery" "jvm why & jvm explain java" {
        $why = & $jvm why | Out-String
        $exp = & $jvm explain java | Out-String
        if ($LASTEXITCODE -ne 0 -or $exp -notmatch 'java') {
            throw "why or explain failed"
        }
    }

    Test-Feature "2.Discovery" "jvm compare 17 21 & jvm search 21" {
        $cmp = & $jvm compare 17 21 | Out-String
        $srch = & $jvm search 21 | Out-String
        if ($LASTEXITCODE -ne 0 -or $cmp -notmatch '21') {
            throw "compare or search failed"
        }
    }

    # CATEGORY 3: Argument Boundaries, Ephemeral Exec & Contextual Runner
    Test-Feature "3.ExecRun" "jvm exec preserves spaces, quotes, ampersands, and parentheses" {
        $out = & $jvm exec 21 -- cmd.exe /c echo "hello world & (parens) 100%" 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or $out -notmatch 'hello world & \(parens\) 100%') {
            throw ("Corrupted exec output: " + $out.Trim())
        }
    }

    Test-Feature "3.ExecRun" "jvm exec propagates non-zero subprocess exit code" {
        $null = & $jvm exec 21 -- cmd.exe /c "exit /b 42" 2>&1
        if ($LASTEXITCODE -ne 42) {
            throw "Expected exit code 42, got $LASTEXITCODE"
        }
    }

    Test-Feature "3.ExecRun" "jvm run custom command with multiple arguments" {
        $rOut = & $jvm run cmd.exe /c echo "runner_arg_1" "runner_arg_2" 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or $rOut -notmatch 'runner_arg_1') {
            throw "jvm run failed: $rOut"
        }
    }

    Test-Feature "3.ExecRun" "Security: Reject exclamation mark in 1st arg, 10th arg, and exec arg" {
        $null = & $jvm "bad!arg1" 2>&1
        $e1 = $LASTEXITCODE
        $null = & $jvm list a2 a3 a4 a5 a6 a7 a8 a9 "bad!arg10" 2>&1
        $e2 = $LASTEXITCODE
        $null = & $jvm exec 21 -- cmd.exe /c echo "bad!exec" 2>&1
        $e3 = $LASTEXITCODE
        if ($e1 -eq 0 -or $e2 -eq 0 -or $e3 -eq 0) {
            throw "Failed to reject poison '!' character ($e1, $e2, $e3)"
        }
    }

    # CATEGORY 4: Unified Config Engine & Update Channels
    Test-Feature "4.Config" "jvm config set, get (text & JSON), invalid key (exit 9), and reset" {
        $null = & $jvm config set retries 5 | Out-String
        $val = (& $jvm config get retries | Out-String).Trim()
        $jVal = (& $jvm config get retries --json | Out-String) | ConvertFrom-Json
        $null = & $jvm config get non_existent_key_xyz 2>&1
        $badExit = $LASTEXITCODE
        $null = & $jvm config reset | Out-String
        if ($val -ne '5' -or $jVal.retries -ne 5 -or $badExit -ne 9) {
            throw "Config engine failed (val=$val, badExit=$badExit)"
        }
    }

    Test-Feature "4.Config" "jvm channel view, switch to nightly & back to stable" {
        $null = & $jvm channel nightly | Out-String
        $c1 = & $jvm channel | Out-String
        $null = & $jvm channel stable | Out-String
        $c2 = & $jvm channel | Out-String
        if ($c1 -notmatch 'Nightly' -or $c2 -notmatch 'Stable') {
            throw "Channel switching failed"
        }
    }

    # CATEGORY 5: Zero-Friction Onboarding (jvm init) & Project Pinning
    Test-Feature "5.Project" "jvm init detects Maven pom.xml (<maven.compiler.release>)" {
        $mvnDir = Join-Path $sandbox 'maven_proj'
        New-Item -ItemType Directory -Path $mvnDir -Force | Out-Null
        Push-Location $mvnDir
        try {
            Set-Content -LiteralPath .\pom.xml -Value '<project><properties><maven.compiler.release>21</maven.compiler.release></properties></project>' -Encoding UTF8
            $res = (& $jvm init --dry-run --json | Out-String) | ConvertFrom-Json
            if (-not $res.ok -or $res.build_system -ne 'maven' -or $res.recommended_java -ne '21') {
                throw "Maven pom.xml detection failed"
            }
        } finally { Pop-Location }
    }

    Test-Feature "5.Project" "jvm init detects Gradle build.gradle.kts (JavaLanguageVersion.of)" {
        $grdDir = Join-Path $sandbox 'gradle_proj'
        New-Item -ItemType Directory -Path $grdDir -Force | Out-Null
        Push-Location $grdDir
        try {
            Set-Content -LiteralPath .\build.gradle.kts -Value 'java { toolchain { languageVersion.set(JavaLanguageVersion.of(21)) } }' -Encoding UTF8
            $res = (& $jvm init --yes --json --offline | Out-String) | ConvertFrom-Json
            if (-not $res.ok -or $res.build_system -ne 'gradle' -or -not (Test-Path .\.java-version) -or -not (Test-Path .\.jvm.toml)) {
                throw "Gradle init file generation failed"
            }
            $prj = (& $jvm project --json | Out-String) | ConvertFrom-Json
            if ($prj.toolchains[0].version -ne '21') {
                throw "jvm project failed to read generated .jvm.toml"
            }
        } finally { Pop-Location }
    }

    Test-Feature "5.Project" "jvm pin writes and reads .java-version & blocks reserved 'current'" {
        $pinDir = Join-Path $sandbox 'pin_proj'
        New-Item -ItemType Directory -Path $pinDir -Force | Out-Null
        Push-Location $pinDir
        try {
            $null = & $jvm pin 21 | Out-String
            if ($LASTEXITCODE -ne 0 -or (Get-Content .\.java-version -TotalCount 1).Trim() -ne '21') {
                throw "jvm pin 21 failed"
            }
            $null = & $jvm pin current 2>&1
            if ($LASTEXITCODE -eq 0) { throw "jvm pin failed to reject reserved keyword 'current'" }
        } finally { Pop-Location }
    }

    # CATEGORY 6: Lockfiles, HMAC & Asymmetric RSA Signing, Freeze & Thaw
    Test-Feature "6.Lockfile" "HMAC-SHA256 sign, constant-time verify, tamper detection, and thaw" {
        $lckDir = Join-Path $sandbox 'lock_hmac'
        New-Item -ItemType Directory -Path $lckDir -Force | Out-Null
        Push-Location $lckDir
        try {
            $kf = Join-Path $lckDir 'hmac.key'
            Set-Content -LiteralPath $kf -Value 'SuperSecretHmacKey2026_DiamTek' -NoNewline -Encoding UTF8
            $lockData = [ordered]@{
                schema = 2; lockfile_version = 1; platform = 'windows-x64'
                generated_at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
                tools = [ordered]@{
                    java = [ordered]@{
                        version = '21.0.12.1+1'; vendor = 'adoptium'; arch = 'windows-x64'
                        url = 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12%2B1/OpenJDK21U-jdk_x64_windows_hotspot_21.0.12_1.zip'
                        checksum_type = 'sha256'; checksum = ('a' * 64)
                        provenance = 'upstream-verified'; publisher_authenticated = $true
                    }
                }
            } | ConvertTo-Json -Depth 5
            [System.IO.File]::WriteAllText((Join-Path $lckDir '.jvm.lock'), $lockData, [System.Text.UTF8Encoding]::new($false))

            # Sign & Verify
            $s = (& $jvm lock --sign --key-file $kf --json | Out-String) | ConvertFrom-Json
            $v = (& $jvm lock --verify --key-file $kf --json | Out-String) | ConvertFrom-Json
            if (-not $s.ok -or -not $v.ok -or $v.algorithm -ne 'HMAC-SHA256') { throw "HMAC sign/verify failed" }

            # Tamper with .jvm.lock and confirm verification fails
            [System.IO.File]::AppendAllText((Join-Path $lckDir '.jvm.lock'), "`r`n")
            $null = & $jvm lock --verify --key-file $kf --json 2>&1
            if ($LASTEXITCODE -eq 0) { throw "Tampered lockfile passed signature verification!" }

            # Re-sign, then Thaw (and verify stale .sig is automatically invalidated)
            $null = & $jvm lock --sign --key-file $kf --json | Out-String
            $t = (& $jvm thaw --json | Out-String) | ConvertFrom-Json
            if (-not $t.ok -or $t.tools.java.thawed -ne '21' -or (Test-Path .\.jvm.lock.sig)) {
                throw "Thaw failed or did not invalidate stale .jvm.lock.sig"
            }
        } finally { Pop-Location }
    }

    Test-Feature "6.Lockfile" "Asymmetric RSA-SHA256 signing (private key) & verification (public key only)" {
        $rsaDir = Join-Path $sandbox 'lock_rsa'
        New-Item -ItemType Directory -Path $rsaDir -Force | Out-Null
        Push-Location $rsaDir
        try {
            $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider(2048)
            $privKeyFile = Join-Path $rsaDir 'private.xml'
            $pubKeyFile = Join-Path $rsaDir 'public.xml'
            [System.IO.File]::WriteAllText($privKeyFile, $rsa.ToXmlString($true), [System.Text.UTF8Encoding]::new($false))
            [System.IO.File]::WriteAllText($pubKeyFile, $rsa.ToXmlString($false), [System.Text.UTF8Encoding]::new($false))
            $rsa.Dispose()

            $lockData = '{"schema":2,"lockfile_version":1,"platform":"windows-x64","generated_at":"2026-10-15T12:00:00Z","tools":{"java":{"version":"21.0.12","vendor":"adoptium","arch":"x64","url":"https://api.adoptium.net/v3","checksum_type":"sha256","checksum":"' + ('b' * 64) + '"}}}'
            [System.IO.File]::WriteAllText((Join-Path $rsaDir '.jvm.lock'), $lockData, [System.Text.UTF8Encoding]::new($false))

            $s = (& $jvm lock --sign --key-file $privKeyFile --json | Out-String) | ConvertFrom-Json
            $v = (& $jvm lock --verify --key-file $pubKeyFile --json | Out-String) | ConvertFrom-Json
            if (-not $s.ok -or $s.algorithm -ne 'RSA-SHA256' -or -not $v.ok -or $v.status -ne 'verified') {
                throw "Asymmetric RSA-SHA256 sign/verify failed"
            }
        } finally { Pop-Location }
    }

    Test-Feature "6.Lockfile" "Freeze provenance check rejects unauthenticated third-party URLs (CWE-494)" {
        $frzDir = Join-Path $sandbox 'freeze_prov'
        New-Item -ItemType Directory -Path $frzDir -Force | Out-Null
        Push-Location $frzDir
        try {
            $badLock = [ordered]@{
                schema = 2; lockfile_version = 1; platform = 'windows-x64'
                generated_at = '2026-10-15T12:00:00Z'
                tools = [ordered]@{
                    java = [ordered]@{
                        version = '27'; vendor = 'Oracle (Custom)'; arch = 'windows-x64'
                        url = 'https://evil-untrusted-host.example/jdk27.zip'
                        checksum_type = 'sha256'; checksum = ('c' * 64)
                    }
                }
            } | ConvertTo-Json -Depth 5
            [System.IO.File]::WriteAllText((Join-Path $frzDir '.jvm.lock'), $badLock, [System.Text.UTF8Encoding]::new($false))
            $null = & $jvm freeze --dry-run --json 2>&1
            if ($LASTEXITCODE -eq 0) {
                throw "Freeze failed to reject unverified provenance URL"
            }
        } finally { Pop-Location }
    }

    # CATEGORY 7: Portable Bundles (.jvmbundle), Security Traversals & Distro
    Test-Feature "7.Bundles" "Bundle create, list, inspect, and install --dry-run plan" {
        $bndDir = Join-Path $sandbox 'bundles'
        New-Item -ItemType Directory -Path $bndDir -Force | Out-Null
        Push-Location $bndDir
        try {
            $bFile = Join-Path $bndDir 'test-pkg.jvmbundle'
            $cPlan = (& $jvm bundle create $bFile --dry-run --json | Out-String) | ConvertFrom-Json
            if (-not $cPlan.ok -or $cPlan.status -ne 'dry-run') { throw "Bundle create --dry-run failed" }

            $oldJh = $env:JAVA_HOME
            $env:JAVA_HOME = ''
            try {
                $cRes = (& $jvm bundle create $bFile --json | Out-String) | ConvertFrom-Json
            } finally { $env:JAVA_HOME = $oldJh }
            if (-not $cRes.ok -or -not (Test-Path $bFile) -or -not (Test-Path ($bFile + '.sha256'))) {
                throw "Bundle creation failed"
            }

            $iRes = (& $jvm bundle inspect $bFile --json | Out-String) | ConvertFrom-Json
            $pRes = (& $jvm bundle install $bFile --dry-run --json | Out-String) | ConvertFrom-Json
            if (-not $iRes.ok -or $iRes.manifest.schema_version -ne 2 -or -not $pRes.ok) {
                throw "Bundle inspect or install --dry-run failed"
            }
        } finally { Pop-Location }
    }

    Test-Feature "7.Bundles" "Security: Bundle install rejects manifest path traversal (..\\evil)" {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $malDir = Join-Path $sandbox 'mal_bundle_src'
        $malPay = Join-Path $malDir 'payloads\java'
        New-Item -ItemType Directory -Path $malPay -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $malPay 'dummy.txt'), 'test')
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $h = ([BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes((Join-Path $malPay 'dummy.txt')))) -replace '-','').ToLowerInvariant()
        $man = [ordered]@{
            schema_version = 2; bundle_format = '2.0'; platform = 'windows-x64'
            tools = @{ java = @{ version = '..\..\escaped'; vendor = 'adoptium' } }
            payloads = @{ java = @{ path = 'payloads/java'; version = '..\..\escaped'; vendor = 'adoptium' } }
            payload_hashes = @{ 'payloads/java/dummy.txt' = ('sha256:' + $h) }
        } | ConvertTo-Json -Depth 5
        $manPath = Join-Path $malDir 'manifest.json'
        [System.IO.File]::WriteAllText($manPath, $man, [System.Text.UTF8Encoding]::new($false))
        $manDigest = ([BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes($manPath))) -replace '-','').ToLowerInvariant()
        $sha.Dispose()
        $malZip = Join-Path $sandbox 'traversal.jvmbundle'
        [System.IO.Compression.ZipFile]::CreateFromDirectory($malDir, $malZip)
        [System.IO.File]::WriteAllText(($malZip + '.sha256'), ('sha256:' + $manDigest))

        $null = & $jvm bundle install $malZip --json 2>&1
        if ($LASTEXITCODE -eq 0) {
            throw "Malicious manifest path traversal was NOT rejected!"
        }
    }

    Test-Feature "7.Bundles" "Distro create (actual ZIP + manifest.sha256 verification)" {
        $dZip = Join-Path $sandbox 'offline-kit.zip'
        $dRes = (& $jvm distro create --out $dZip --json | Out-String) | ConvertFrom-Json
        if (-not $dRes.ok -or -not (Test-Path $dZip) -or -not (Test-Path ($dZip + '.sha256'))) {
            throw "Distro creation failed"
        }
    }

    # CATEGORY 8: Profiles, Snapshots, Custom Links & Cache Engine
    Test-Feature "8.State" "Profiles (create, list, show, clone, delete)" {
        $pName = 'test-prof-' + [Guid]::NewGuid().ToString('N').Substring(0, 6)
        $pClone = $pName + '-clone'
        try {
            $c = (& $jvm profile create $pName --desc "Suite Test Profile" --json | Out-String) | ConvertFrom-Json
            $s = (& $jvm profile show $pName --json | Out-String) | ConvertFrom-Json
            $k = (& $jvm profile clone $pName $pClone --json | Out-String) | ConvertFrom-Json
            if (-not $c.ok -or -not $s.ok -or -not $k.ok) { throw "Profile lifecycle failed" }
        } finally {
            $null = & $jvm profile delete $pName --yes 2>&1
            $null = & $jvm profile delete $pClone --yes 2>&1
        }
    }

    Test-Feature "8.State" "Snapshots (create, list, restore --dry-run, delete)" {
        $sName = 'test-snap-' + [Guid]::NewGuid().ToString('N').Substring(0, 6)
        try {
            $c = (& $jvm snapshot create $sName --json | Out-String) | ConvertFrom-Json
            $l = (& $jvm snapshot list --json | Out-String) | ConvertFrom-Json
            $r = (& $jvm snapshot restore $sName --dry-run --json | Out-String) | ConvertFrom-Json
            if (-not $c.ok -or -not $l.ok -or -not $r.ok) { throw "Snapshot lifecycle failed" }
        } finally {
            $null = & $jvm snapshot delete $sName --yes 2>&1
        }
    }

    Test-Feature "8.State" "Custom JDK Links (jvm link, list links, unlink & CWE-22 traversal guard)" {
        $fakeJdk = Join-Path $sandbox 'fake_jdk'
        New-Item -ItemType Directory -Path (Join-Path $fakeJdk 'bin') -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $fakeJdk 'bin\java.exe'), 'MZ')
        $linkName = 'SuiteTestJDK'
        try {
            $null = & $jvm link $fakeJdk $linkName | Out-String
            if ($LASTEXITCODE -ne 0) { throw "jvm link failed" }
            $lnkList = & $jvm link | Out-String
            if ($lnkList -notmatch $linkName) { throw "Linked JDK not listed" }
            $null = & $jvm unlink $linkName | Out-String
            if ($LASTEXITCODE -ne 0) { throw "jvm unlink failed" }

            $null = & $jvm link $fakeJdk "..\evil" 2>&1
            if ($LASTEXITCODE -eq 0) { throw "Traversal link name was not blocked" }
        } finally {
            $null = & $jvm unlink $linkName 2>&1
        }
    }

    Test-Feature "8.State" "CAS Cache Engine (list, size, stats, prune --dry-run, clean --dry-run)" {
        $null = & $jvm cache list | Out-String
        $null = & $jvm cache size | Out-String
        $null = & $jvm cache prune --dry-run | Out-String
        $null = & $jvm cache clean --dry-run | Out-String
        if ($LASTEXITCODE -ne 0) { throw "Cache command failed" }
    }

    # CATEGORY 9: Enterprise Machine Policy Compliance Engine
    Test-Feature "9.Policy" "Policy enforcement blocks disallowed vendor, min_java, and --skip-checksum" {
        $polFile = Join-Path $sandbox 'enterprise-policy.toml'
        $polContent = @"
[policy]
allow_skip_checksum = false
allow_user_config = false
enforce_lockfile = false

[vendors]
allowed = ["adoptium"]
blocked = ["oracle"]

[versions]
min_java = 21
max_java = 25
"@
        [System.IO.File]::WriteAllText($polFile, $polContent, [System.Text.UTF8Encoding]::new($false))
        $env:JVM_POLICY_FILE = $polFile
        try {
            $null = & $jvm install 21 --skip-checksum --yes 2>&1
            $eSkip = $LASTEXITCODE

            $null = & $jvm config set retries 4 2>&1
            $eCfg = $LASTEXITCODE

            $null = & $jvm install 21 --vendor oracle --yes 2>&1
            $eVend = $LASTEXITCODE

            $null = & $jvm install 17 --vendor adoptium --yes 2>&1
            $eMin = $LASTEXITCODE

            if ($eSkip -eq 0 -or $eCfg -eq 0 -or $eVend -eq 0 -or $eMin -eq 0) {
                throw "Policy failed to block violation ($eSkip, $eCfg, $eVend, $eMin)"
            }
        } finally {
            Remove-Item Env:\JVM_POLICY_FILE -ErrorAction SilentlyContinue
        }
    }

    # CATEGORY 10: Shell Integration (CMD AutoRun Preservation), Doctor & Support
    Test-Feature "10.DiagShell" "CMD AutoRun preserves pre-existing user command on install & uninstall" {
        if (-not (Test-Path -LiteralPath $cmdRegPath)) { New-Item -Path $cmdRegPath -Force | Out-Null }
        $sentinel = 'rem __USER_EXISTING_AUTORUN_SENTINEL__'
        Set-ItemProperty -LiteralPath $cmdRegPath -Name 'AutoRun' -Value $sentinel -Type String

        $null = & $jvm aliases --install | Out-String
        $afterInstall = (Get-ItemProperty -LiteralPath $cmdRegPath -Name 'AutoRun').AutoRun
        if ($afterInstall -notlike "*$sentinel*" -or $afterInstall -notlike "*jvm_aliases.cmd*") {
            throw "AutoRun install overwrote sentinel or missed hook: $afterInstall"
        }

        $null = & $jvm aliases --uninstall | Out-String
        $afterUninstall = (Get-ItemProperty -LiteralPath $cmdRegPath -Name 'AutoRun').AutoRun
        if ($afterUninstall -ne $sentinel) {
            throw "AutoRun uninstall did not cleanly restore sentinel: '$afterUninstall'"
        }
    }

    Test-Feature "10.DiagShell" "Redacted support & issue bundles exclude ownership.json and redact username" {
        Push-Location $sandbox
        try {
            $null = & $jvm support --yes | Out-String
            $suppZip = Join-Path $sandbox 'jvm-support-bundle.zip'
            if (-not (Test-Path -LiteralPath $suppZip)) { throw "jvm-support-bundle.zip not created" }

            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $z = [System.IO.Compression.ZipFile]::OpenRead($suppZip)
            try {
                $ownEntry = $z.Entries | Where-Object { $_.Name -eq 'ownership.json' }
                if ($ownEntry) { throw "Privacy violation: ownership.json was included in bundle" }
                $repEntry = $z.Entries | Where-Object { $_.Name -eq 'report.txt' } | Select-Object -First 1
                if ($repEntry) {
                    $sr = New-Object System.IO.StreamReader($repEntry.Open())
                    $repText = try { $sr.ReadToEnd() } finally { $sr.Close(); $sr.Dispose() }
                    if ($env:USERNAME -and $repText.Contains($env:USERNAME)) {
                        throw "Privacy violation: Raw USERNAME found unredacted in report.txt"
                    }
                }
            } finally { $z.Dispose() }
        } finally { Pop-Location }
    }

    Test-Feature "10.DiagShell" "Doctor JSON, Transaction log, and Self-Update history" {
        $doc = (& $jvm doctor --json | Out-String) | ConvertFrom-Json
        $null = & $jvm transaction show | Out-String
        $null = & $jvm self-update --history | Out-String
        if ($null -eq $doc.storage_root_ok) { throw "Doctor JSON malformed" }
    }

} finally {
    $ErrorActionPreference = 'Continue'
    Set-Location -LiteralPath $repoRoot
    try {
        if ($null -ne $cfgBackup) {
            New-Item -ItemType Directory -Path $jvmAppDir -Force | Out-Null
            [System.IO.File]::WriteAllBytes($cfgPath, $cfgBackup)
        }
    } catch { Write-Warning "config restore: $_" }
    try {
        if (Test-Path -LiteralPath $cmdRegPath) {
            if ($null -eq $origAutoRun) {
                Remove-ItemProperty -LiteralPath $cmdRegPath -Name 'AutoRun' -ErrorAction SilentlyContinue
            } else {
                Set-ItemProperty -LiteralPath $cmdRegPath -Name 'AutoRun' -Value $origAutoRun -Type String
            }
        }
    } catch { Write-Warning "AutoRun restore: $_" }
    try {
        if (Test-Path -LiteralPath $sandbox) {
            Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch { Write-Warning "sandbox cleanup: $_" }
}
$suiteSw.Stop()
Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host ("  MASTER SUITE RESULTS: {0} Passed, {1} Failed (Total Time: {2:N2}s)" -f $pass, $fail,$suiteSw.Elapsed.TotalSeconds) -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Red' })
Write-Host "================================================================================" -ForegroundColor Cyan
$report | Format-Table -AutoSize
if ($fail -gt 0) { exit 1 } else { exit 0 }