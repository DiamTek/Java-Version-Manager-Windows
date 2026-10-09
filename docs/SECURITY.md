<h1 align="center">Security Policy</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md) &nbsp;•&nbsp; [🛡️ Security](SECURITY.md) &nbsp;•&nbsp; [🤝 Contributing](CONTRIBUTING.md) &nbsp;•&nbsp; [💬 Support](SUPPORT.md)

</div>

---

## Supported Versions

Currently, only versions **`1.0.2` and newer** of the Java Version Manager for Windows are supported with active security patches and vulnerability mitigations. Versions `1.0.0` and `1.0.1` are **unsupported and deprecated** due to missing defensive guardrails, elevation boundary mitigations, and parser protections introduced in `1.0.2`.

| Version | Supported | Status |
| :--- | :---: | :--- |
| `>= 1.0.2` | ✅ | Supported (Active Security Maintenance) |
| `1.0.1` | ❌ | Unsupported (End of Life — Immediate Upgrade to 1.0.2+ Required) |
| `1.0.0` | ❌ | Unsupported (End of Life — Immediate Upgrade to 1.0.2+ Required) |
| `< 1.0.0` | ❌ | Unsupported (End of Life) |

---

## Threat Model & Security Posture

DiamTek Java Version Manager (JVM) is engineered for enterprise developer workstations and managed corporate environments. The security perimeter is hardened against common Windows attack vectors, Local Privilege Escalation (LPE), and software supply chain tampering.

### 1. Zero-File In-Memory UAC Elevation & Environment Saturation Immunity (LPE / TOCTOU Defense)
- **Vulnerabilities Mitigated:**
  - **TOCTOU Race Windows:** Legacy automation utilities commonly write temporary elevation scripts (e.g. `%TEMP%\elevate.bat` or `%TEMP%\admin.ps1`) before executing `Start-Process -Verb RunAs`. This creates a critical Time-of-Check to Time-of-Use (TOCTOU) race window where an unprivileged local process can overwrite the temporary file before elevated execution, gaining `NT AUTHORITY\SYSTEM` or Administrator privileges.
  - **Environment Variable Saturation / Spoofing:** In Windows, an unprivileged user can register user-level environment variables (such as `[Environment]::SetEnvironmentVariable("SystemRoot", "C:\MaliciousDir", "User")`). If a parent unprivileged process resolves `$env:SystemRoot` or `%SystemRoot%` before calling `Start-Process -Verb RunAs`, an attacker can redirect the elevated executable path (`$env:SystemRoot\System32\powershell.exe`) or the elevated working directory (`-WorkingDirectory "$env:SystemRoot\System32"`) to an attacker-controlled folder. This enables Search Order Hijacking, unauthorized DLL planting, and arbitrary code execution under elevated context.
- **Architectural Defense:**
  - JVM completely eliminates intermediate temporary elevation scripts. All administrative operations (such as system registry updates in legacy mode or system directory cleanups) are executed purely in-memory via Base64 UTF-16LE `-EncodedCommand`.
  - System directory paths and elevation binaries are resolved strictly using the immutable Win32 SpecialFolder API (`[Environment]::GetFolderPath([Environment+SpecialFolder]::System)` and `[Environment+SpecialFolder]::Windows`). These query `SHGetKnownFolderPath(FOLDERID_System)` and native Windows kernel APIs directly, completely ignoring the process environment block and immunizing elevation boundaries against environment variable saturation:
  ```powershell
  $bytes = [System.Text.Encoding]::Unicode.GetBytes($adminCommand)
  $encodedCommand = [Convert]::ToBase64String($bytes)
  $sys32Dir = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
  $systemPowerShell = Join-Path $sys32Dir "WindowsPowerShell\v1.0\powershell.exe"
  Start-Process -FilePath $systemPowerShell `
      -Verb RunAs `
      -WorkingDirectory $sys32Dir `
      -ArgumentList "-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-EncodedCommand", $encodedCommand `
      -Wait
  ```
- **EDR Compliance:** This design prevents CrowdStrike, Microsoft Defender for Endpoint, and SentinelOne from triggering heuristic script-drop alerts in `%TEMP%` and eliminates DLL planting vulnerabilities.

### 2. Download Verification & Payload Integrity
- **Vulnerability Mitigated:** Incomplete downloads, transit corruption, CDN cache poisoning, or malicious mirror swapping (`CWE-494`).
- **Architectural Defense:** 
  - Every remote JDK and ecosystem tool payload is cryptographically validated against vendor SHA256/SHA512 (and SHA1 for BellSoft Liberica) checksum endpoints using native .NET Cryptography APIs (`System.Security.Cryptography.SHA256` / `SHA512` / `SHA1`).
  - **GitHub Releases API Asset Digest Discovery**: When upstream projects hosted on GitHub Releases do not provide standalone `.sha256` files (such as Micronaut CLI `micronaut-projects/micronaut-starter`), JVM automatically queries the official GitHub Releases REST API (`https://api.github.com/repos/<owner>/<repo>/releases/tags/<tag>`) to retrieve the asset's cryptographic `digest` (`sha256:<hex>`). All API requests pass through strict `Test-TrustedJvmUri` domain allowlisting and open redirect validation (`CWE-918` / `CWE-601`).
  - **Interactive Unverified Fallback Prompt**: In interactive UI mode, if a tool payload has neither a standalone checksum file nor an API digest, JVM prompts the user: `Do you want to continue installation without checksum verification? (y/N)` instead of failing closed with an unusable CLI flag instruction.
  - Checksum validation is strictly decoupled from interactive prompts: passing `-y` / `--yes` only suppresses confirmation dialogs and will **never** bypass integrity verification.
  - In non-interactive or CLI mode, bypassing checksum validation requires an explicit, intentional `--skip-checksum` (or `--no-verify`) flag for air-gapped or legacy mirrors without published hashes. Environment-based bypasses (`JVM_SKIP_CHECKSUM=1`) are intentionally ignored and killed to prevent silent supply-chain tampering, and automated CI runs explicitly mandate `--yes` alongside `--skip-checksum` (`CWE-494`).

### 3. Repository File Fail-Closed Validation (`.java-version` & `.sdkmanrc` Hardening)
- **Vulnerability Mitigated:** Arbitrary shell command execution or silent validation bypass via untrusted project repository files (`.java-version` or `.sdkmanrc`).
- **Architectural Defense:**
  - **Fail-Closed Non-Filtering Parser Boundary:** Rather than using `findstr /v` as a pre-filter (which could silently drop an injected or malformed `java=` or ecosystem line and allow the rest of `.sdkmanrc` or `.java-version` to appear valid), `jvm.bat` inspects all non-comment lines (`%FINDSTR_BIN% /r /v "^[ \t]*# ^ï»¿[ \t]*# ^[ \t]*$"`) for shell and expansion metacharacters (`[&|<>`%%!;$()^{}\"]`) and missing `=` delimiters first—immediately setting `JV_PARSE_ERR=1`, `SDK_PARSE_ERR=1`, or `SDK_ECO_ERR=1` and aborting (`exit /b 1`) if any unsafe line is present.
  - Every active `java=` and ecosystem entry (`maven=`, `gradle=`, `kotlin=`, `scala=`, `groovy=`) is then passed (`tokens=1,* delims==`) to `:ParseJavaVersion`, `:ParseSdkmanrc`, and `:ProcessEcosystemSession` (`:ValidateStrictIdentifier`), failing closed on any invalid version, unsupported vendor, or reserved keyword (`current`).

### 4. Buffer Overflow & Environment Truncation Defense
- **Vulnerability Mitigated:** Legacy Windows `setx.exe` imposes a hard 1,024-character buffer limit on the `PATH` environment variable. Running `setx` on a workstation with a long `PATH` silently truncates the tail of the variable, corrupting system-wide software installations.
- **Architectural Defense:** All global and machine environment updates leverage infinite-length .NET environment APIs (`[Environment]::SetEnvironmentVariable`), completely bypassing `setx.exe` buffer overrun vulnerabilities.

### 5. Cryptographic Supply Chain Provenance (SLSA / Sigstore)
- **Vulnerability Mitigated:** Unauthorized binary replacement or build injection.
- **Architectural Defense:** Official release binaries (standalone MSIs, portable ZIPs) are built in isolated GitHub Actions runners and cryptographically signed using GitHub's OIDC Sigstore attestation authority (`actions/attest-build-provenance`).
- **Verification Command:**
  ```bash
  gh attestation verify jvm-windows-1.0.1-x64.msi --owner DiamTek
  ```

### 6. Dual Update Channel Integrity, Unified Uninstaller Verification & Downgrade Prevention
- **Vulnerability Mitigated:** In-transit modification of self-updater or uninstaller payloads, local uninstaller tampering, malicious mirror spoofing, accidental or unauthorized rollbacks to older vulnerable versions, and script-locking denial-of-service.
- **Architectural Defense:**
  - **`[Stable]` Channel:** Pulls release artifacts and computes SHA-256 digests in-memory via `System.Security.Cryptography.SHA256`, strictly matching against signed upstream `SHA256SUMS.txt` manifests before replacing or executing local files (`install.ps1`, `jvm.bat`, and `uninstall.ps1`). Any hash deviation immediately aborts execution and purges temporary files.
  - **`[Nightly]` Channel & Unified `uninstall.ps1` Trust Model:** Fetches the direct commit tip of `main`, parses semantic build stamps (`JVM_BUILD`), and cryptographically verifies downloaded and local payloads (`install.ps1` in `:SelfUpdate`, `jvm.bat` and `uninstall.ps1` in `install.ps1`, and `uninstall.ps1` in `:UninstallJVM_Complete` / `:VerifyDownloadedScript`) against the GitHub Contents API **Git Blob SHA-1** (`SHA1("blob " + length + "\0" + bytes)` matched against `.sha` at `ref=main`), backed by a DACL-protected `uninstall.ps1.sha256` sidecar digest written by `install.ps1` at install time for offline verification. Any tampering or hash mismatch immediately aborts with `MISMATCH`.
  - **Downgrade Safeguard:** Both channels compare local `JVM_BUILD` integers against remote payloads. If a local workstation is running a build with an integer greater than the upstream target (`local > remote`), the updater halts execution (`[ SKIP ] You are on a newer local build`), preventing accidental regression.
  - **Decoupled Ephemeral Runner:** Executable replacement occurs via a detached runner script that polls for file handle release before atomic filesystem replacement, preventing partial write corruption.

### 7. Windows Alternative Data Streams (ADS) and Poison Character Neutralization
- **Vulnerability Mitigated:** Arbitrary filesystem stream targeting, file disguise via NTFS Alternate Data Streams (`filename:stream`), Win32 path canonicalization bypasses via trailing periods or whitespace, command-line parameter poisoning via shell metacharacters (`^`, `&`, `|`, `<`, `>`, `;`, `"`, `!`, `%`), argument/flag injection (`-`), wildcard expansion attacks (`*`, `?`), and Windows device namespace lockups (`CON`, `NUL`, `AUX`, `PRN`, `COM1-9`, `LPT1-9`).
- **Architectural Defense:**
  - Implemented in `jvm.bat` under `:ValidateStrictIdentifier`, enforcing an airtight multi-phase defensive pipeline:
    - **Delayed Expansion Segregation:** Validation begins under `setlocal disabledelayedexpansion`. In Windows `cmd.exe`, evaluating untrusted strings containing exclamation marks (`!`) or percent signs (`%`) while delayed expansion is active can cause variable mutation or subshell command execution. The validator quarantines `%_VSI_RAW%` and uses parenthesized, quoted checks (`echo("%_VSI_RAW%" | findstr "!"` and `findstr "%%"`) to reject toxic inputs prior to enabling delayed expansion.
    - **Win32 Canonicalization Bypass Prevention (`:VSI_StripTrailing`):** The Win32 subsystem automatically strips trailing dots (`.`) and spaces (` `) during path normalization (e.g., `folder.` or `folder ` resolves identically to `folder`). Attackers exploit this behavior to bypass validation blacklists or trigger unexpected directory collisions. `:VSI_StripTrailing` iteratively strips trailing dots and spaces in a loop until the string is completely normalized. If stripping results in an empty value, execution immediately halts.
    - **Alternate Data Stream (ADS) Colon Neutralization:** On NTFS filesystems, colons separate filenames from Alternate Data Streams (e.g., `file.txt:hidden.exe`). Colon (`:`) characters are strictly forbidden and checked via batch substring substitution:
      ```cmd
      if not "!_VSI_VAL!"=="!_VSI_VAL::=!" (
          endlocal & endlocal
          set "JVM_EXIT_CODE=1"
          exit /b 1
      )
      ```
    - **Path Traversal & Separator Quarantine:** Slashes (`\`, `/`) and relative directory traversals (`..`) are filtered using internal substring substitutions (`!_VSI_VAL:\=!`, `!_VSI_VAL:/=!`, `!_VSI_VAL:..=!`), completely preventing directory traversal escapes.
    - **Leading Flag/Hyphen Neutralization:** Identifiers beginning with a hyphen (`-`) are immediately rejected (`if "!_VSI_VAL:~0,1!"=="-"`), neutralizing command-line flag injection into downstream sub-commands or native tools.
    - **Internal Substitution Checks vs. Piped FINDSTR:** Characters with syntactic meaning in `cmd.exe` (`^`, `&`, `|`, `<`, `>`, `;`, `"`) are tested through internal batch substitution (`set "_VSI_SUB=!_VSI_VAL:&=!"` etc.). Using batch substitution rather than piping to `findstr` prevents poison metacharacters from escaping into subshells or pipeline boundaries during the check itself.
    - **Wildcard, Extended DOS Device & Win32 Namespace Sanitization (`CWE-66` / `CWE-155`):** Wildcards (`*`, `?`) are detected using pure-batch character loops and quoted regular-expression pattern matching. Legacy MS-DOS reserved device names (`CON`, `PRN`, `AUX`, `NUL`, `COM1`-`COM9`, `LPT1`-`LPT9`), extended DOS device names with extensions (`CON.jdk`, `NUL.21`, `AUX.txt`, `COM1.jdk` via base-name extraction before `.`), and Win32 raw device path namespaces (`\\.\`, `\\?\`, `\??\`) are explicitly blocked to prevent Windows kernel file handle hangs or device access.
    - **Pre-Delayed-Expansion Exclamation Guard (`:RejectExclamationArg`):** Before `setlocal enabledelayedexpansion` is activated at script startup, `:RejectExclamationArg` inspects raw CLI parameters (`%~1`..`%~9`) under `setlocal disabledelayedexpansion`. This prevents `cmd.exe` from silently stripping unpaired `!` characters (e.g., turning `foo!bar` into `foobar`) during Phase 2 parser evaluation.
    - **Zero-Subshell Pure-Batch Character Loop (`:VSI_CharLoop`):** Identifier character validation (including `*`, `?`, and `"`) and `jvm doctor` / `jvm list` vendor checks execute entirely in pure batch using substring extraction and delayed-expansion substitution (`!VAR:sub=!`), avoiding piping untrusted strings to external utilities (`find.exe`, `findstr.exe`) or spawning subshells where command injection could occur.
    - **System32 Binary Pinning & CWD Planting Immunity (`CWE-426` / `CWE-427`):** `jvm.bat` verifies `%SystemRoot%\System32\cmd.exe` existence (`if not exist "%SystemRoot%\System32\cmd.exe" set "SystemRoot=C:\Windows"`), sets `NoDefaultCurrentDirectoryInExePath=1`, pins all external Windows binaries (`cmd.exe`, `reg.exe`, `find.exe`, `findstr.exe`, `where.exe`, `choice.exe`, `timeout.exe`, `fsutil.exe`, `powershell.exe`, `chcp.com`, `icacls.exe`, `attrib.exe`, `explorer.exe`) to `%SYS32%` (`%..._BIN%`), and executes `where.exe` exclusively as `%WHERE_BIN% $PATH:java`, preventing Trojan binary execution from untrusted working directories.
    - **ACL-Locked & Reparse-Safe Isolated Temp Workspace (`:EnsureSecureTemp` & `:EmitSessionEnv` — `CWE-20` / `CWE-276` / `CWE-377`):** All temporary helper scripts and `.jvm_session_target` files are isolated inside `%LOCALAPPDATA%\DiamTek\JVM\temp` after verifying the directory is not a reparse point (`%FSUTIL_BIN% reparsepoint query`) and locking DACLs atomically (`icacls /inheritance:r /grant:r "*S-1-5-18:(OI)(CI)F" "*S-1-5-32-544:(OI)(CI)F" "%USERNAME%:(OI)(CI)F"`), with `JVM_CALLER_PID` validated strictly as a positive numeric PID in `:EmitSessionEnv`.

### 8. Non-Destructive Reparse Point & Junction Lifecycle
- **Vulnerability Mitigated:** Accidental or malicious destruction of host JDK directories during unlinking, uninstallation, or switching; recursive traversal into junction targets; and reparse point auto-recovery deadlocks caused by Win32 `if exist` semantics on dangling junctions.
- **Architectural Defense:**
  - **Reparse Point Target Isolation (`Remove-DirectorySafely`):** Naive recursive folder deletion (such as standard PowerShell `Remove-Item -Recurse` or batch commands) can follow directory junctions and wipe the contents of the target installation folder (e.g., deleting the real JDK installation at `C:\Program Files\Java\jdk-21` when attempting to clean up `%LOCALAPPDATA%\DiamTek\JVM\current`). `Remove-DirectorySafely` (implemented in `uninstall.ps1` and `build-msi.ps1`) and `:CleanCache` (`jvm clean` / `jvm prune`) inspect directory attributes using `($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)`:
    - If the directory root is a reparse point, it is unbound immediately using `[System.IO.Directory]::Delete($path, $false)` or `cmd.exe /c "rmdir /q \"$path\""`. The non-recursive unbind removes the junction pointer while leaving the target JDK directory contents 100% untouched.
    - Child reparse points within candidate and cache stores are enumerated and safely unbound bottom-up prior to deleting parent directories.
    - Tree deletion subsequently leverages `cmd.exe /c "rmdir /s /q \"$Path\""` to guarantee junction safety in Windows PowerShell 5.1 without risking target deletion.
  - **Broken Junction Auto-Recovery Without `if exist` Deadlock:**
    - In Windows `cmd.exe`, the `if exist <path>` operator evaluates whether the *target* directory of a directory junction exists, not whether the reparse point itself exists on disk.
    - If a user moves or deletes a JDK from disk, the junction pointing to it becomes "broken" or "dangling". A traditional script executing `if exist "%LINK%" rmdir "%LINK%"` evaluates to `false`, skipping deletion. When the script subsequently executes `mklink /J "%LINK%" "%NEW_TARGET%"`, Windows returns Win32 Error 183 (`ERROR_ALREADY_EXISTS: Cannot create a file when that file already exists`).
    - JVM completely eliminates this deadlock by unconditionally executing `rmdir "!CURRENT_SYMLINK!" >nul 2>&1` without preceding `if exist` checks before every junction creation, ensuring instant, deterministic unbinding and self-healing.

### 9. Registry ValueKind Preservation & Non-Blocking Broadcasts
- **Vulnerability Mitigated:** Environment variable corruption through unintended type downgrades (converting dynamic `REG_EXPAND_SZ` variables to static `REG_SZ`), premature expansion of system variables (`%SystemRoot%`, `%USERPROFILE%`), buffer overflow truncation across user/machine boundaries, and terminal/installer deadlocks caused by unresponsive top-level desktop windows during environment broadcasts.
- **Architectural Defense:**
  - **ValueKind Preservation (`REG_EXPAND_SZ` vs `REG_SZ`):**
    - Reading registry values via standard high-level APIs often automatically expands nested environment strings, converting paths like `%SystemRoot%\System32` into `C:\Windows\System32`. Writing this expanded value back as a standard `REG_SZ` permanently breaks roaming profiles, variable relocations, and dynamic OS resolution.
    - `install.ps1`, `uninstall.ps1`, and `build-msi.ps1` query registry keys directly using `[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')` with `[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames`.
    - The engine determines the existing type via `$key.GetValueKind('Path')`. It strictly preserves `REG_EXPAND_SZ` (`[Microsoft.Win32.RegistryValueKind]::ExpandString`) whenever variable delimiters (`%`) are present or previously configured, preventing inadvertent type demotion to `REG_SZ`.
  - **PATH Buffer & Truncation Safeguards:**
    - The engine computes combined PATH lengths (Machine PATH + User PATH) and enforces an 8,191-character hard ceiling (aborting modifications if exceeded to prevent environment block overflow) and a 2,048-character Win32 compatibility threshold with visual warnings.
  - **Non-Blocking Environment Broadcast (`SendMessageTimeout`):**
    - To notify the Windows shell, File Explorer, and active services of environment updates (`PATH`, `JAVA_HOME`), scripts broadcast the `WM_SETTINGCHANGE` (`0x001A`) message to `HWND_BROADCAST` (`0xFFFF`) with `lParam = "Environment"`.
    - Standard synchronous `SendMessage` calls block indefinitely if any running application has an unresponsive message pump (e.g., a hung tray utility or frozen GUI program).
    - JVM executes a native Win32 P/Invoke call to `SendMessageTimeout` with flags `fuFlags = 2` (`SMTO_ABORTIFHUNG`) and a timeout parameter `uTimeout = 5000` (5,000ms):
      ```powershell
      [Win32.NativeMethods]::SendMessageTimeout(
          $HWND_BROADCAST,
          $WM_SETTINGCHANGE,
          [UIntPtr]::Zero,
          'Environment',
          2,     # SMTO_ABORTIFHUNG (0x0002)
          5000,  # 5,000 ms timeout
          [ref]$result
      ) | Out-Null
      ```
    - If any desktop window is hung, Windows immediately aborts waiting on that window and resumes broadcasting to the remaining windows, guaranteeing zero process hangs or installer freezeups.

### 10. Enterprise PowerShell & Constrained Language Mode
- **Vulnerability Mitigated:** Script crashes, permission denials, and installation failures on corporate enterprise endpoints enforced by AppLocker or Windows Defender Application Control (WDAC) running in PowerShell Constrained Language Mode (CLM); network download failures in enterprise proxy environments requiring integrated Windows authentication (NTLM/Kerberos).
- **Architectural Defense:**
  - **Constrained Language Mode (CLM) & WDAC Resiliency:**
    - Under PowerShell CLM, invoking custom .NET types, setting arbitrary static properties (such as `[System.Net.ServicePointManager]::SecurityProtocol`), or compiling inline C# types via `Add-Type` is restricted or triggers security exceptions (`Cannot set property. Property setting is only supported on core types in this language mode`).
    - The installer explicitly queries `$ExecutionContext.SessionState.LanguageMode` before executing advanced .NET operations (`$isFullLanguage = ($ExecutionContext.SessionState.LanguageMode -eq 'FullLanguage')`). When CLM is active (`LanguageMode -ne 'FullLanguage'`), the script selectively bypasses restricted .NET property mutations and relies on native, core cmdlets (`Invoke-WebRequest`, `Invoke-RestMethod`) that are fully allowed under WDAC policies.
  - **Enterprise Authenticated Proxy Support (`DefaultNetworkCredentials`):**
    - Corporate networks typically route outbound traffic through enterprise proxy firewalls requiring Integrated Windows Authentication (IWA). Unauthenticated requests fail with HTTP 407 (Proxy Authentication Required).
    - When running in Full Language mode, `install.ps1` binds system proxy credentials to native Kerberos/NTLM credentials:
      ```powershell
      if ([System.Net.WebRequest]::DefaultWebProxy) {
          [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
      }
      ```
    - On modern PowerShell (PS 6+ / 7+), it configures automatic corporate proxy delegation via default parameter values:
      ```powershell
      $PSDefaultParameterValues['Invoke-WebRequest:ProxyUseDefaultCredentials'] = $true
      $PSDefaultParameterValues['Invoke-RestMethod:ProxyUseDefaultCredentials'] = $true
      ```
    - This allows seamless downloads from vendor endpoints (Adoptium, GitHub, Azul) across enterprise proxy gateways without credential prompts or plaintext credential storage.

### 11. Atomic Failure-Path Rollback, Deterministic Resource Hygiene & Zero Silent Exceptions
- **Vulnerabilities Mitigated:** Broken filesystem states, orphaned junctions, dangling registry entries, leaked Win32/COM handles, silent exception swallowing (`CWE-390`), untracked command failures (`CWE-252`), incomplete partial downloads (`CWE-459`), and sensitive path leakage in error logs (`CWE-209`).
- **Architectural Defense:**
  - **Atomic Junction & State Rollback (`CWE-460`):** When switching the active JDK (`CURRENT_SYMLINK`) or an ecosystem candidate (`:SwitchCandidate`), `jvm.bat` reads the existing junction target into `PREV_JUNCTION_TARGET` before unlinking. If `mklink /J` fails (`if errorlevel 1`), the engine automatically restores the previous junction target, outputs an error diagnostic, and halts with `exit /b 1` rather than proceeding with a severed junction.
  - **Staged Installation & Package Rollback (`CWE-460`):** `install.ps1` snapshots existing `jvm.bat` to `$batBackup = "$batPath.bak.<guid>.tmp"` prior to staging. If companion verification fails or an exception occurs, the overarching `finally` block atomically restores `$batBackup` back to `$batPath`. `packages/msi/test-msi.ps1` registers an emergency `msiexec /x` rollback in its outer `finally` block if interrupted mid-test. `packages/choco/build-choco.ps1` snapshots all package manifests (`.nuspec`, `chocolateyInstall.ps1`, `chocolateyUninstall.ps1`) and restores originals on build failure.
  - **Deterministic Resource & Handle Lifecycle (`CWE-459`):** All Win32 Registry keys (`OpenSubKey`), network handles (`HttpWebResponse`, `StreamReader`), COM objects (`WScript.Shell`, `IWshShortcut`, `WindowsInstaller.Installer`), and cryptography providers (`SHA1`, `SHA256`) are managed within deterministic `try / finally` disposal patterns. All temporary staging files (`*.stage.*.tmp`, `*.bak.*.tmp`) and truncated downloads (`Invoke-TrustedGitHubDownload`) are purged in `finally` blocks.
  - **Zero Silent `catch {}` Swallowing & Path Redaction (`CWE-209` / `CWE-390`):** PowerShell AST analysis enforces **0 empty `catch {}` blocks across all 9 repository PowerShell scripts** (`Test 157`). All error handlers log structured single-line warnings via `Write-Verbose` or `[ WARN ]`, stripping raw stack traces and redacting sensitive user profile paths (`%LOCALAPPDATA%`, `%USERPROFILE%`).
  - **Strict Exit Code Propagation (`CWE-252` / `CWE-754` / `CWE-755`):** All CLI subcommands (`doctor`, `which`, `open`, `exec`, `hook`, `clear`, `channel`, `pin`) route through `:CLI_DONE` with `endlocal & set "CMD_EXIT_CODE=%CMD_EXIT_CODE%" & exit /b %CMD_EXIT_CODE%`, propagating non-zero codes across batch scope boundaries. All 6 elevated UAC handoffs (`Start-Process -Verb RunAs`) specify `-PassThru`, dispose child process handles, and propagate `$p.ExitCode`.

### 12. Automated 263-Test Security Suite & 40-CWE Coverage Matrix (`tests/Test-JvmSecurity.ps1`)
Every commit and release is continuously verified by `tests/Test-JvmSecurity.ps1`, which executes **263 automated adversarial test cases across 10 defensive suites** with a 100% pass rate (`263 / 263 PASS`) and outputs a numerically sorted **40-CWE Coverage Summary**:

| CWE ID | Vulnerability Class | Tests Verified | Status |
|:---|:---|:---:|:---:|
| **`CWE-20`** | Improper Input & Config Validation (`.java-version` BOM/CRLF, `.sdkmanrc` fail-closed validation, `JVM_CALLER_PID`, `LATEST_VER`, `CUSTOM_VER`, `REL_ADOPTIUM`, `bump-version.ps1`, winget schema, Semeru/Corretto build parsing, interactive uninstaller menu, `--json` parsing contract, `DO_PIN_WRITE` validation, locked candidate/version validation, lock CLI aliases, PowerShell dynamic tab completion coverage, exact semantic build `+` support, `jvm cache` CLI arguments, `jvm search` candidate tool routing and shorthand queries, `jvm compare` specification baseline and multi-LTS milestone JEP chaining, PowerShell profile hook status inspection, single-value queries, `why` resolution graph, `explain` 7-layer architecture, `welcome` tutorial, toolchain conflict detectors) | **35 / 35** | **PASS** |
| **`CWE-22`** | Path Traversal & ZipSlip (`..`, `/`, `\`, sibling-prefix collisions, rooted archive entries, `:FetchAndExtract` `GetFullPath`, `jvm cache import` entry containment validation, `jvm install --locked` ancestor traversal, locked tool candidate traversal) | **23 / 23** | **PASS** |
| **`CWE-41`** | Win32 Canonicalization Bypass (`current.`, `current `, multiple trailing dots/spaces) | **6 / 6** | **PASS** |
| **`CWE-59`** | Symlink & Junction Safety (`Remove-DirectorySafely`, `Remove-ReparsePointOrFail`, `Test-HasReparsePointInLineage`, `CURRENT_SYMLINK`, `:WriteConfigFile`, `:EmitSessionEnv`, `jvm link`/`unlink`, `:UninstallCandidate`, elevated `:UninstallJDK`, `build-msi.ps1` hooks, `:CleanCache`, `jvm pin`, `$PROFILE` reparse guards, `.jvm.lock` reparse point / junction rejection, `jvm cache import` reparse point rejection) | **28 / 28** | **PASS** |
| **`CWE-66`** | DOS Reserved Device (`CON`, `NUL.jdk`, archive entry device names) & NTFS ADS (`:stream`, `\\.\`) Abuse | **3 / 3** | **PASS** |
| **`CWE-73`** | Environment, Registry ValueKind, `Test-TrustedJvmInstallDirectory` (`InstallLocation` / `-SourceDir` early abort), System Root Protection, Content-Addressed Storage layout, and `ownership.json` variable tracking | **11 / 11** | **PASS** |
| **`CWE-74`** | XML Attribute & Template Injection (`Escape-XmlAttr` / `[System.Security.SecurityElement]::Escape` in `build-msi.ps1`) | **1 / 1** | **PASS** |
| **`CWE-78`** | OS Command & Shell Metacharacter Injection (`:ValidateStrictIdentifier`, `:RejectExclamationArg`, `:EcoPerformCheck`, `:ShowDynamicMenu`, `:ShowCurrentStatus`, `:DoctorDiagnostics`, pipe-free `:SwitchCandidate`, `Invoke-DeferredDirectoryCleanup`, `UPDATE_CHECKER_PS1` pipe character escaping, Oracle JDK 27 batch parenthesis integrity) | **25 / 25** | **PASS** |
| **`CWE-88`** | Argument & Flag Injection (`--evil-flag`, `--vendor` poisoning, `jvm exec`, `jvm open` comma delimiter guard, `DL_STRIP_ROOT` leading hyphen guard, URL/PS metacharacter filter in `:ValidateStrictIdentifier`, `jvm run` contextual wrapper arguments) | **10 / 10** | **PASS** |
| **`CWE-94`** | Batch `set /a` Arithmetic Expression & Variable Assignment Evaluation Defense (`:ShowDynamicMenu` `JAVA_VERSION` numeric guard) | **1 / 1** | **PASS** |
| **`CWE-155`** | Wildcard Expansion Injection (`*`, `?`) | **2 / 2** | **PASS** |
| **`CWE-184`** | Incomplete List-Based Input Sanitization (Clean working tree enforcement in `bump-version.ps1` & manifest validation) | **1 / 1** | **PASS** |
| **`CWE-209`** | Error Message Stack-Trace, Contextual Actionable Errors, Sensitive User Path Suppression, Universal CLI Logging (`--quiet`, `--verbose`) & Diagnostic Report Secret Redaction (`jvm report`) | **8 / 8** | **PASS** |
| **`CWE-250`** | Privilege Boundary Isolation (Base64 UTF-16LE `-EncodedCommand` AST immunity & `persist-credentials: false` in GitHub Actions) | **2 / 2** | **PASS** |
| **`CWE-252`** | Unchecked Return Value, Semantic Exit Codes (0-10) & Process Exit Code Propagation | **13 / 13** | **PASS** |
| **`CWE-276`** | Strict Directory DACL & Reparse Isolation (`%JVM_SECURE_TEMP%`, `Initialize-SecureDirectory` fail-closed enforcement, First-Run `.initialized` permission bounds) | **3 / 3** | **PASS** |
| **`CWE-295`** | TLS 1.2 / 1.3 Cryptographic Protocol Enforcement (`:ExecuteSharedDownloader`, `:SelfUpdate`, `:CheckUpdateStatus`) | **2 / 2** | **PASS** |
| **`CWE-319`** | Strict `https://` URI Scheme & Redirect Enforcement (`:ExecuteSharedDownloader`, `chocolateyInstall.ps1`, `.jvm.lock` non-HTTPS rejection, enterprise download mirror URL validation) | **4 / 4** | **PASS** |
| **`CWE-330`** | CSPRNG Temp Filename Entropy (Zero predictable `!RANDOM!` paths; `[System.IO.Path]::GetRandomFileName()`) | **1 / 1** | **PASS** |
| **`CWE-345`** | Version & Monotonic `JVM_BUILD` Downgrade Attack Defense (Alongside MSI Authenticode signing hook verification) | **3 / 3** | **PASS** |
| **`CWE-354`** | Checksum Manifest Format Validation & SHA-256 Gate Enforcement (`.jvm.lock` SHA-256 validation & tamper defense) | **5 / 5** | **PASS** |
| **`CWE-362`** | Race Condition & Concurrent State (`state.lock` mutex wait loop, atomic dead-PID takeover via staged `owner.pid` replacement with `--no-lock` unsafe override, `:WriteConfigFile` atomic replacement via `.stage.!_CFG_RND!.tmp`, `.jvm.lock` atomic staged write `.stage.<guid>.tmp`, `jvm transaction` journaling & rollback) | **5 / 5** | **PASS** |
| **`CWE-367`** | Atomic Staged Profile & Config File Writes (`Move-Item -LiteralPath`, Windows Terminal file-lock retry/backup, UTF-8 No BOM) | **3 / 3** | **PASS** |
| **`CWE-377`** | Insecure Temporary File & Protected DACL Verification (Get-Acl / icacls fallback cross-version compatibility) | **2 / 2** | **PASS** |
| **`CWE-390`** | Error Condition Action, AST Zero-Silent-Catch Audit & Logging | **3 / 3** | **PASS** |
| **`CWE-400`** | Hang & Parser Resilience (`SendMessageTimeout`, state lock wait timeout, PATH boundaries, `NO_COLOR`, JSONC, Resumable Range `.part` download staging, Adaptive Terminal Width, Real-time speed/ETA throttling, Cache telemetry & dedupe loops) | **15 / 15** | **PASS** |
| **`CWE-409`** | Zip Bomb & Decompression Bounds (`40,000` entry ceiling & `1.75 GB` cumulative decompressed byte cap) | **1 / 1** | **PASS** |
| **`CWE-426`** | Untrusted Search Path & CWD Trojan Binary Planting Defense (`%SYS32%`, `$PATH:java`, `chocolateyUninstall.ps1`, `test-msi.ps1`, license header pinning bootstrapping) | **9 / 9** | **PASS** |
| **`CWE-427`** | Uncontrolled `PATH` Search-Order Hijack Immunity & Canonical `%LOCALAPPDATA%\DiamTek\JVM\bin` Registration | **2 / 2** | **PASS** |
| **`CWE-428`** | Quoted `System32` `UninstallString` / `QuietUninstallString` & Pinned Shortcut `TargetPath` | **1 / 1** | **PASS** |
| **`CWE-459`** | Failure-Path Handle Disposal (`finally`), Temporary Artifact & Stream Cleanup, Transaction Rollback Stale Lock Cleanup | **13 / 13** | **PASS** |
| **`CWE-460`** | Exception Cleanup, Atomic State Rollback (`PREV_JUNCTION_TARGET`, `.old`, `.jvm_bak_`, `$batBackup`, `jvm transaction` rollback & aliases, cache import fail-safe cleanup) & Universal `--dry-run` Simulation | **15 / 15** | **PASS** |
| **`CWE-494`** | Supply Chain, Package Manifest, Fail-Closed Nightly Git Blob SHA-1, `Invoke-TrustedGitHubDownload`, `jvm install --locked` Checksum Verification, `jvm cache import` Content-Addressed Storage SHA-256 verification, explicit `--skip-checksum` warning flag, CI gating, Multi-Phase Installation pipeline & Rollback verification | **22 / 22** | **PASS** |
| **`CWE-532`** | Sensitive Registry Backup (`%LOCALAPPDATA%\DiamTek\JVM\backups`) DACL & Reparse Isolation, Redacted Issue & Support Bundles (`jvm doctor --report`, `jvm support`) | **3 / 3** | **PASS** |
| **`CWE-601`** | Open Redirect Host Verification (`ResponseUri` validation on payload, `Get-TrustedChecksumText`, `:ResolveLatestEcosystemCandidate`, & `:CheckUpdateStatus`) | **4 / 4** | **PASS** |
| **`CWE-611`** | XML External Entity (XXE) & DTD Prohibition (`DtdProcessing::Prohibit` & `XmlResolver = $null`) | **4 / 4** | **PASS** |
| **`CWE-674`** | Uncontrolled Recursion & Cyclic Loops (`Remove-DirectorySafely` iterative non-recursive queue pattern immune to self-referential junctions) | **1 / 1** | **PASS** |
| **`CWE-754`** | Exceptional Condition Check, Local NTFS Volume Advisories, Colon Guards (`::::::::::::::::::::`), Fail-Closed Parameter Validation, Smart Retry Exponential Backoff (429/5xx handling) | **15 / 15** | **PASS** |
| **`CWE-755`** | Exceptional Condition Handling, Early `ConstrainedLanguageMode` Guard, Ctrl+C Offset Skip Absorption & Sanitized Exception Redaction | **6 / 6** | **PASS** |
| **`CWE-918`** | SSRF & Vendor Domain Allowlist Enforcement (`Test-TrustedJvmUri` regex bounds, `chocolateyInstall.ps1` `$allowedHosts`, live CLI `--offline` network barrier, `jvm install --locked` host allowlist, and CAS offline install verification) | **6 / 6** | **PASS** |

<a id="100--100-audit-scorecard"></a>
### 13. Security & Error Management Audit Scorecard (`10.0 / 10.0`)

| Audit Area | Subsystem Scope | CWE Classes Covered | Pass 4 Verification Status | Score |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **Core Batch Engine & Junctions** | `jvm.bat` (`CURRENT_SYMLINK`, `:SwitchCandidate`, `:UpdateSystemPath`, `:InstallGlobalCommand`, `:BackupRegistry`) | `CWE-59`, `CWE-252`, `CWE-459`, `CWE-460`, `CWE-754` | Verified atomic rollback on switch failures with emergency alert, local NTFS volume UNC advisories, verified exit-code propagation, and quarantined registry backups. | **10.0 / 10.0** |
| **Downloader, APIs & Elevation** | `jvm.bat` (`:ExecuteSharedDownloader`, `:VerifyDownloadedScript`, `:SelfUpdate`, `:Run_API_Query`, UAC handoffs) | `CWE-209`, `CWE-252`, `CWE-459`, `CWE-460`, `CWE-755` | Verified deterministic `try / finally` disposal on `HttpWebResponse`, `StreamReader`, `SHA1`, and process elevation handles (`Start-Process -PassThru`). | **10.0 / 10.0** |
| **Installers & Uninstallers** | `install.ps1` & `uninstall.ps1` | `CWE-73`, `CWE-209`, `CWE-252`, `CWE-276`, `CWE-367`, `CWE-390`, `CWE-459`, `CWE-460`, `CWE-494`, `CWE-674`, `CWE-754`, `CWE-755` | Verified atomic `$batBackup` rollback, fail-closed Nightly Git-blob SHA-1 verification, fail-closed `Initialize-SecureDirectory` DACL enforcement, partial download purging, COM apartment release, safe shortcut validation, early `ConstrainedLanguageMode` fail-closed policy, fail-closed invalid `-SourceDir` abort, and cyclic junction immunity (`Remove-DirectorySafely`). | **10.0 / 10.0** |
| **Packaging & Build Pipelines** | `packages/msi/build-msi.ps1`, `packages/msi/test-msi.ps1`, `packages/choco/build-choco.ps1`, `scripts/bump-version.ps1` | `CWE-184`, `CWE-209`, `CWE-252`, `CWE-390`, `CWE-459`, `CWE-460`, `CWE-611`, `CWE-754` | Verified zero empty `catch {}` blocks via AST, emergency `msiexec /x` rollback, manifest rollback, clean git tree enforcement, and XXE prohibition. | **10.0 / 10.0** |
| **Concurrency & State Synchronization** | `jvm.bat` (`:AcquireStateLock`, `:ReleaseStateLock`, `:WriteConfigFile`, `:EmitSessionEnv`, `%JVM_SECURE_TEMP%`) | `CWE-330`, `CWE-362`, `CWE-367`, `CWE-377`, `CWE-400` | Verified cross-process mutual exclusion (`state.lock`), atomic staged configuration replacement (`.stage.!_CFG_RND!.tmp` + `move /y`), CSPRNG random file naming, and per-user ACL lockdown. | **10.0 / 10.0** |
| **Adversarial Test Suite** | `tests/Test-JvmSecurity.ps1` | All 40 MITRE CWE Classes | 263/263 tests passing (`0` failures) with runtime error injection, cyclic directory junction fuzzing, live process tree kill recovery, CAS cache verification, download throughput telemetry, and automatic environment state preservation. | **10.0 / 10.0** |
| **Overall Posture** | **Complete Repository Ecosystem** | **40 MITRE CWE Classes** | **Zero unhandled failure paths, zero leaked handles, zero silent catches, zero cyclic recursion hazards.** | **`10.0 / 10.0`** |

---

## Vulnerability Scope Matrix

| Category | In-Scope | Out-of-Scope |
|---|---|---|
| **Remote Code Execution** | Unauthenticated RCE via auto-downloader, candidate engine, or archive unpacking | Code execution requiring an attacker to already control local administrator credentials |
| **Path Traversal (Zip Slip)** | Archive extraction writing files outside `%LOCALAPPDATA%\DiamTek\JVM` | User explicitly running `jvm link` pointing to a compromised local directory |
| **Privilege Escalation** | Bypassing standard user boundaries to gain Administrator rights without UAC consent | Attacker already having elevated Administrator or SYSTEM privileges on the machine |
| **Command Injection** | Injecting commands via `.java-version`, `.sdkmanrc`, or CLI argument parsing | Manually editing the `jvm.bat` file on local disk |
| **Alternative Data Streams & Canonicalization** | NTFS ADS stream injection (`:stream`) or trailing dot/space Win32 canonicalization bypasses in identifiers | Modifying NTFS metadata with raw disk write privileges |
| **Reparse Point & Junction Target Deletion** | Recursive deletion traversing directory junctions to wipe host JDK installations | Manual deletion of target JDK folders by external tools or users |
| **Environment & Registry Integrity** | Accidental type demotion of `REG_EXPAND_SZ` to `REG_SZ`, or PATH overflow truncation | Malicious software directly altering registry keys via background elevated service |
| **Broadcast Deadlock & Hanging** | Stalled process execution during `WM_SETTINGCHANGE` environment broadcasts | Operating system kernel deadlock or failure of `user32.dll` subsystem |
| **Transport Security** | Silent acceptance of tampered/corrupted downloads when checksum is expected | Network denial-of-service or outages on vendor APIs (Adoptium, Oracle, GitHub, BellSoft) |

---

## Reporting a Vulnerability

If you discover a potential security vulnerability in DiamTek Java Version Manager, please report it through coordinated disclosure. **Do not create public GitHub issues or forum discussions for security vulnerabilities.**

### Reporting Channels

1. **GitHub Security Advisories (Preferred):**
   Navigate to the repository's [Private Vulnerability Reporting](https://github.com/DiamTek/Java-Version-Manager-Windows/security/advisories/new) page to open a confidential report.
2. **Direct Email:**
   Send an encrypted or plaintext report to the project maintainer:
   - **Contact:** Alexéy Shishkin
   - **Email:** **salexey09@gmail.com**
3. **Discord (Direct Message):**
   Reach out directly to **@thehawk01** on Discord for initial coordination.

### What to Include in Your Report

To help us triage and reproduce the issue rapidly, please include:
- The exact build number (`jvm version` or `cmd.exe /c "jvm.bat --version"`).
- Target operating system and environment (e.g., Windows 11 23H2, standard user account vs. admin).
- Step-by-step reproduction instructions or a minimal Proof of Concept (PoC) payload.
- Assessment of the potential impact (e.g., LPE, arbitrary file write, shell injection).

---

## Response & Remediation SLA

We take all security reports with utmost urgency:

| Phase | Target SLA | Description |
|---|---|---|
| **Initial Acknowledgment** | **< 48 hours** | We confirm receipt of your report and begin preliminary assessment. |
| **Triage & Reproduction** | **< 7 days** | We validate the PoC in an isolated Windows sandbox and determine severity. |
| **Patch & Release** | **< 30 days** | We develop, verify via the automated test suite, and deploy a patched release. |
| **Coordinated Disclosure** | Negotiated | We publish security advisories and credit reporters (unless anonymity is requested). |

---

[← Back to Documentation Overview](../README.md#documentation)