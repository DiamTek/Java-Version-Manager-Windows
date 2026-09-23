<h1 align="center">Changelog</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md) &nbsp;•&nbsp; [🛡️ Security](SECURITY.md) &nbsp;•&nbsp; [🤝 Contributing](CONTRIBUTING.md) &nbsp;•&nbsp; [💬 Support](SUPPORT.md)

</div>


---

All notable changes to the Java Version Manager for Windows will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to Semantic Versioning.

## [1.0.2] - 2026-09-23

This release delivers an exhaustive defensive security hardening overhaul across the entire JVM runtime engine, UAC elevation boundaries, CI/CD pipelines, and package manifests, accompanied by a comprehensive 78-test automated adversarial security test suite.

### Security & Defensive Hardening
- **Complete Adversarial Input Sanitization (`:ValidateStrictIdentifier` & `:RejectExclamationArg`)**: Engineered a centralized, multi-stage sanitization pipeline in `jvm.bat` that validates all external inputs across `link`, `unlink`, `which`, `pin`, `exec`, candidate version switches, candidate installation, uninstallation, and configuration parsing:
  - *Pre-Delayed-Expansion Exclamation Guard (`:RejectExclamationArg`)*: Inspects raw CLI parameters (`%~1`..`%~5`) under `setlocal disabledelayedexpansion` prior to `setlocal enabledelayedexpansion`, preventing `cmd.exe` from silently stripping unpaired `!` characters (`foo!bar` -> `foobar`) during Phase 2 parser expansion.
  - *Win32 Trailing Space & Dot Canonicalization Bypass*: Proactively strips trailing spaces and trailing dots (`.` and ` `) before reserved keyword evaluation, completely neutralizing Win32 filesystem canonicalization bypass attacks that attempted to target or overwrite `current` (e.g., `current.`, `current `, `current....`, `current   `).
  - *NTFS Alternate Data Stream (ADS) Neutralization*: Detects and strips colon stream delimiters (`:`), thwarting hidden NTFS Alternate Data Stream execution vectors (e.g., `test:stream`).
  - *Directory Traversal & Keyword Protection*: Enforces strict rejection of directory traversal sequences (`..`, `/`, `\`), single-dot aliases (`.`), leading hyphen flag injection (`--evil-flag`), and reserved keywords (`current`).
  - *Poison Character & Quote-Smuggling Neutralization*: Neutralizes dangerous `cmd.exe` command chaining, embedded double-quote smuggling (`set _VSI_DQ="` / `if "!_VSI_CH!"=="!_VSI_DQ!"`), and poison characters (`&`, `|`, `<`, `>`, `^`, `;`, `"`, `*`, `?`) via pure-batch character loop inspection (`:VSI_CharLoop`) and internal substitution checks without spawning subshells or piping untrusted input.
  - *DOS Reserved Device Rejection*: Blocks legacy DOS 8.3 reserved hardware device names (`CON`, `PRN`, `AUX`, `NUL`, `COM1-9`, `LPT1-9`).
- **System32 Binary Pinning & CWD Planting Immunity (`CWE-426` / `CWE-427`)**:
  - Pinned all external Windows system binaries (`reg.exe`, `findstr.exe`, `where.exe`, `choice.exe`, `timeout.exe`, `fsutil.exe`, `powershell.exe`, `chcp.com`, `icacls.exe`, `explorer.exe`) to `%SYS32%` (`%..._BIN%`) and enforced `NoDefaultCurrentDirectoryInExePath=1`, completely preventing current-working-directory (CWD) binary planting and `PATH` search-order hijacking when invoking `jvm` inside untrusted repositories.
  - Hardened all 60+ `for /f ('%..._BIN% ...')` command loops (including `!CURR_JAVA_BIN!` version detection) to preserve inner argument quoting around `-Command "..."` and registry queries without `cmd.exe /c` outer-quote stripping.
- **ACL-Locked Isolated Temp Workspace (`:EnsureSecureTemp` — `CWE-377` / `CWE-378`)**:
  - Migrated temporary helper scripts and `.jvm_session_target` files out of world-writable shared `%TEMP%` into an ACL-locked per-user workspace (`%LOCALAPPDATA%\DiamTek\JVM\temp`) hardened via `icacls /inheritance:r /grant:r "%USERNAME%:(OI)(CI)F"`.
  - Replaced predictable `%RANDOM%` temporary filenames and blind startup `del "%TEMP%\jvm_*"` wipes with cryptographically random filenames (`[System.IO.Path]::GetRandomFileName()`), guaranteeing parallel terminal session isolation without cross-instance interference.
- **Strict ZipSlip & Sibling-Prefix Collision Defense (`CWE-22`)**:
  - Enforced canonical destination boundary checks (`$destinationPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)`) with mandatory trailing directory separators (`\`) and explicit rooted-entry rejection (`$entry.FullName -match '^[/\\]'`) during ZIP archive extraction in `:ExecuteSharedDownloader`, blocking both `../` escapes and sibling prefix collisions (`../cand_evil/payload.exe`).
  - Hardened `$allowedRoots` validation in `Set-JvmVar` (`install.ps1` and `jvm.bat`) to enforce trailing directory separators (`$normRoot + '\'`), preventing sibling directories (`C:\Program Files\Java_evil` or `.jdks_evil`) from bypassing storage boundary checks.
- **Non-Destructive Directory Junction Unbinding (`Remove-DirectorySafely`)**: Re-architected junction cleanup routines across `uninstall.ps1`, `packages/msi/build-msi.ps1`, and runtime maintenance:
  - *Target JDK Deletion Prevention*: Resolved a critical directory traversal hazard where standard recursive deletions (`Remove-Item -Recurse` in Windows PowerShell 5.1) traversed NTFS directory junctions into target directories, inadvertently deleting linked host JDKs. Introduced `Remove-DirectorySafely` to sort reparse points bottom-up by path length and cleanly unbind junctions via `[System.IO.Directory]::Delete($_.FullName, $false)` and native `rmdir /q` before container folders are deleted.
  - *Broken Junction Auto-Recovery*: Hardened `jvm.bat` and ecosystem switchers to issue direct `rmdir` calls without `if exist` guards, resolving silent switch deadlocks where broken or dangling junctions (whose target directories were deleted or moved) failed `if exist` checks and could not be re-linked.
  - *Filesystem Root & Canary Protection*: Added strict safeguards forbidding deletion of system/user roots (`C:\`, `%USERPROFILE%`, `%SystemRoot%`, `%ProgramFiles%`), requiring active JVM installation markers (`jvm.bat`, `uninstall.ps1`), and detecting active `.git` development repositories to prevent accidental source code loss.
- **Process Elevation Hardening (Base64 UTF-16LE & System32 SpecialFolder Isolation)**: Overhauled administrative UAC elevation routines (`Start-Process powershell -Verb RunAs`) across `jvm.bat`, `install.ps1`, `uninstall.ps1`, and `build-msi.ps1`:
  - *In-Memory Encoded Command Execution*: Dynamically encodes all elevated command payloads into Base64 UTF-16LE strings passed via `-EncodedCommand`, completely eliminating argument breakout vulnerabilities, parameter splitting on quotes or spaces, and temporary batch/PowerShell runner scripts in `%TEMP%` (mitigating TOCTOU race conditions).
  - *System32 SpecialFolder Working Directory & Binary Isolation*: Pinned all elevated process invocations and working directories to native Win32 `[Environment]::GetFolderPath([Environment+SpecialFolder]::System)`. By querying the Win32 Known Folder API directly rather than resolving `$env:SystemRoot` or `%SystemRoot%` from the process environment block, this completely immunizes process elevation boundaries against user-level environment variable saturation/spoofing attacks and eliminates CWE-426 binary search order hijacking.
- **User & System PATH `REG_EXPAND_SZ` Preservation & Boundary Auditing**: Hardened environment variable manipulation across `install.ps1`, `uninstall.ps1`, and `jvm.bat`:
  - *Dynamic ExpandString Preservation*: Audits registry value kinds using `Microsoft.Win32.RegistryKey.GetValueKind('Path')`, enforcing `[Microsoft.Win32.RegistryValueKind]::ExpandString` across both User (`HKCU\Environment`) and Machine (`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`) scopes. Guarantees that system variables (`%SystemRoot%`, `%USERPROFILE%`, `%LOCALAPPDATA%`) are preserved and never collapsed into static `REG_SZ` strings.
  - *Combined PATH Boundary Guards (2048 / 8191 Characters)*: Dynamically calculates the combined length of User PATH and Machine PATH. Aborts modification immediately if combined length exceeds the 8191-character Windows environment block limit to prevent silent environment corruption, and emits an actionable warning if length exceeds 2048 characters to alert users of potential legacy Win32 application truncation.
  - *Deduplication & Slashing Hygiene*: Automatically strips redundant quotes, trims whitespace, normalizes trailing slashes, and purges legacy phantom Oracle `javapath` entries.
- **Non-Blocking `SendMessageTimeout` Environment Broadcasts**: Overhauled Windows setting change broadcasts (`WM_SETTINGCHANGE`) using native Win32 P/Invoke `SendMessageTimeout` (`HWND_BROADCAST = 0xFFFF`, `WM_SETTINGCHANGE = 0x001A`, `SMTO_ABORTIFHUNG = 0x0002`) with a strict 3000ms-5000ms timeout window. Guarantees that environment broadcasts notify running shells without hanging or deadlocking the terminal when third-party applications fail to process messages.
- **Package Manager, MSI & CI/CD Supply Chain Hardening**:
  - *Immutable GitHub Actions SHA Pinning*: Pinned all GitHub Actions in `.github/workflows/ci.yml` and `.github/workflows/release.yml` (`actions/checkout`, `actions/setup-dotnet`, `actions/attest-build-provenance`, `softprops/action-gh-release`, `actions/upload-artifact`) to verified 40-character commit SHAs and added `Test-JvmSecurity.ps1 -Detailed` as a mandatory pre-build CI/release gate.
  - *Deterministic MSI `ProductCode` & Unversioned Script Hashing*: Added deterministic RFC 4122 UUID v5 `ProductCode` generation (`Get-DeterministicGuid`) in `packages/msi/build-msi.ps1`, configured dual-purpose per-user/per-machine installation scope (`ALLUSERS=2`, `MSIINSTALLPERUSER=1`), and omitted `DefaultVersion` on `.bat`/`.ps1` `<File>` elements so WiX v4 populates `MsiFileHash` entries with zero `WIX1103` warnings.
  - *Chocolatey Fail-Closed MSI Verification*: Migrated Chocolatey package scripts (`packages/choco/tools/chocolateyInstall.ps1` and `chocolateyUninstall.ps1`) to pre-compiled `.msi` distribution with a fail-closed 64-character SHA-256 checksum assertion (`$checksum64 -notmatch '^[A-Fa-f0-9]{64}$'`) and automatic hash synchronization in `build-choco.ps1` and `scripts/bump-version.ps1`.
  - *Release Pre-Flight Verification & Dry-Run Immutability*: Added `--dry-run` verification to `scripts/bump-version.ps1`, guaranteeing zero working tree changes during validation runs, and validated nuspec XML schemas with UTF-8 No BOM encoding and TLS 1.2+ transport security enforcement.
- **78-Test Automated Security & Adversarial Fuzzing Suite (`tests/Test-JvmSecurity.ps1`)**: Engineered an exhaustive, standalone 78-test automated security test suite with `-Suite` / `-Filter` targeted filtering, per-suite timing telemetry tables, and automatic GitHub Actions Step Summary (`$env:GITHUB_STEP_SUMMARY`) Markdown reporting covering 8 defensive suites with a 100% pass rate:
  1. *Adversarial Inputs & Fuzzing Defense (40 tests)*: Path traversal (`..`, `/`, `\`), single dot (`.`), `current` keyword guard, command injection in `.java-version`/`.sdkmanrc`, branch traversal in `install.ps1`, profile hook injection filtering, Win32 trailing dot/space bypasses (`current.`, `current `), DOS reserved devices (`CON`, `PRN`, `AUX`, `NUL`), poison characters (`&`, `|`, `<`, `>`, `^`, `%`, `!`), pre-delayed-expansion `:RejectExclamationArg` across `%~1`..`%~5`, embedded double-quote smuggling in `:VSI_CharLoop`, `--vendor` flag poisoning, `jvm channel` / `jvm open` allowlisting, static `for /f` quote-stripping code audit, ADS streams (`:`), candidate traversal in `which`, leading hyphens (`--evil-flag`), multiple trailing dots/spaces, semicolon chaining, wildcards (`*`, `?`), `%SYS32%` CWD binary planting defense, `jvm pin` metacharacter injection, `jvm exec` path traversal, and `jvm install` candidate version injection.
  2. *Registry & Environment Variable Boundary Tests (6 tests)*: User PATH `REG_EXPAND_SZ` preservation, Base64 UTF-16LE elevation payload integrity, elevation path resolution immunity to SystemRoot environment saturation, Oracle `javapath` de-bloating, extreme PATH lengths (>2048 characters), and `NO_COLOR=1` / `--no-color` strict ANSI escape sequence suppression.
  3. *Reparse Point & Directory Junction Lifecycle (3 tests)*: Non-destructive junction unbinding canary validation, bracket-safe reparse querying with `-LiteralPath` and `$env:QUERY_PATH`, and active dev repo `.git` guards.
  4. *Package Manager Manifest Schema Integrity & Dry-Run Guarantees (10 tests)*: Cross-package version synchronization across Scoop, Chocolatey, Winget, and `jvm.bat`; nuspec XML validation and UTF-8 No BOM checks; Chocolatey fail-closed SHA-256 checksum assertion; Scoop manifest schema; Winget multi-manifest coherence; `bump-version.ps1 -DryRun` working tree immutability; GitHub Actions 40-char SHA pinning & permissions audit; `jvm.bat` UTF-8 No BOM / 100% CRLF / EOF sentinel verification; `build-msi.ps1` RFC 4122 UUID v5 `Get-DeterministicGuid` collision resistance; and `$profileCode` extraction & `WIX1103` script hash verification.
  5. *Concurrency & Reparse Point Non-Destructive Resilience (4 tests)*: Broken/dangling junction auto-recovery without deadlock, rapid sequential junction switching, parallel temp script isolation without startup interference, and live ACL verification on `%JVM_SECURE_TEMP%` (`AreAccessRulesProtected`, no `Everyone`/`Users`).
  6. *Corrupt Registry Recovery & PATH Resilience (6 tests)*: `REG_SZ` vs `REG_EXPAND_SZ` type enforcement, non-blocking `SendMessageTimeout` execution, `Set-JvmVar` storage boundary enforcement, `Set-JvmVar` CWE-22 sibling prefix collision (`.jdks_evil`) & strict variable allowlist (`COMSPEC` rejection), PowerShell AST parser validation of `:InstallPowerShellHook` emitted profile script, and security parity between `install.ps1` and `jvm.bat`.
  7. *Uninstallation Safety & Marker Verification (5 tests)*: `Remove-DirectorySafely` target canary retention, refusal of uninstaller execution on directories lacking JVM markers, system root deletion blocking, strict ZipSlip boundary enforcement on extracted candidate directories, and ZipSlip CWE-22 sibling-prefix collision (`../cand_evil/payload.exe`) & rooted entry (`\rooted_escape.exe`) rejection.
  8. *Windows Terminal JSONC Configuration Parsing (4 tests)*: Block comment `/* ... */` stripping, single-line `//` comment stripping, trailing comma elimination, and graceful silent fallback on corrupted configuration files.

## [1.0.1] - 2026-09-16

This release delivers critical stability and reliability enhancements for the installer pipeline, CLI channel switching, uninstallation handoff, and multi-architecture Winget package distribution.

### Packaging & Distribution
- **Multi-File Winget Manifests (Dual-Architecture)**: Migrated Windows Package Manager (Winget) manifests into the standard multi-file format (`DiamTek.JVM.yaml`, `DiamTek.JVM.installer.yaml`, `DiamTek.JVM.locale.en-US.yaml`) introducing full native `arm64` architecture alongside `x64`.
- **Manifest Synchronization**: Synchronized release versioning and installer endpoints across Scoop (`packages/scoop/jvm.json`), Chocolatey (`packages/choco/jvm.nuspec`), and Winget manifests.

### CLI & Update Channels
- **CLI Channel Overrides (`UPDATE_CHANNEL_OVERRIDE`)**: Engineered the channel override engine to preserve command-line flags (`--channel`, `-c`, `--nightly`, `--stable`) across subshell transitions and menu rescan loops without being overwritten by persistent `channel.txt`.
- **Positional Channel Syntax**: Added support for positional update channel arguments during self-update (e.g., `jvm self-update nightly`, `jvm self-update stable`).
- **Command Aliases**: Added `jvm update self` alias routing directly to the self-update engine.
- **Nightly Hash Display Guard**: Guarded SHA-256 substring formatting against empty string references when evaluating unreleased development builds.

### Core Engine & PowerShell 7 Resilience
- **Pure .NET Cryptographic Fallback (`Get-FileSha256`)**: Introduced native fallback to `[System.Security.Cryptography.SHA256]` in `install.ps1` and `jvm.bat`, resolving `CommandNotFoundException` when `Get-FileHash` is missing in minimal, locked-down, or constrained PowerShell 5.1 environments.
- **PowerShell 7 Byte-Stream Decoding**: Resolved a critical issue in PowerShell 7 where `Invoke-RestMethod` and `Invoke-WebRequest` return raw byte arrays instead of strings, ensuring reliable UTF-8 decoding and preventing checksum validation failures.
- **Strict Windows CRLF Normalization**: Enforced explicit Windows CRLF (`\r\n`) line ending normalization during batch file downloads, preventing `cmd.exe` label offset drift and syntax errors (`'f' is not recognized`, `'cho' is not recognized`).
- **In-Memory Script Execution Guard**: Hardened `install.ps1` against `$null` path evaluations when executed directly in-memory via `irm ... | iex`.

### Bug Fixes & System Stability
- **Uninstaller Temp File Retention**: Excluded active uninstaller runner scripts (`*uninstall*`) from `%TEMP%` cleanup in `uninstall.ps1`, preventing premature deletion of the running script during uninstallation.
- **Atomic Uninstaller Handoff & Clean Process Termination**: Eliminated intermediate batch runner files and obsolete subroutine stack popping in `jvm.bat`. Routed uninstallation execution through an atomic, in-memory compound command with direct process exit (`& exit`), completely eliminating post-uninstallation `The batch file cannot be found.` errors and `The system cannot find the path specified.` directory rescan attempts on deleted installations.
- **MSI PATH Precedence & Sanitization**: Hardened MSI installer environment routines to accurately detect, sanitize, and prepend JVM directory paths without duplicating existing PATH entries.

## [1.0.0] - 2026-09-16

This milestone 1.0.0 release marks the official general availability of the DiamTek Java Version Manager for Windows. It features a massive architectural overhaul of the entire engine, adding comprehensive ecosystem support, native automation integrations, full package manager distribution, and solving multiple Windows-specific system limitations.

### Distribution & Packaging
- **Windows Terminal Profile Integration**: Automatically registers a dedicated "Java Version Manager" profile in Windows Terminal `settings.json` (Release, Preview, and Unpackaged) pointing to high-res `icon.png`, with `closeOnExit: always` and `cmd.exe /c` execution lifecycle so terminal tabs close cleanly upon exiting the JVM menu.
- **Start Menu & Taskbar Launchers**: Generates Start Menu application shortcuts and dynamically synchronizes existing pinned taskbar shortcuts to launch the registered Windows Terminal profile when available, with a graceful `cmd.exe /c` fallback for classic console hosts.
- **Dynamic File Size Estimation**: Dynamically calculates recursive disk footprint across `%LOCALAPPDATA%\DiamTek\JVM` and `%USERPROFILE%\.jvm`, enforcing a 1,024 KB floor in `EstimatedSize` registry key so Windows 11 Installed Apps displays accurate application sizes (1.00 MB+) instead of suppressing file size.
- **Comprehensive Lifecycle Uninstallation**: Deepened `uninstall.ps1` to scrub Windows Terminal profiles, reset `defaultProfile` if targeted, remove pinned taskbar shortcuts, and eliminate temporary `.jvm_session_target` and `jvm_*` artifacts.
- **Official Branding Suite**: Integrated high-resolution 768x768 ARGB source branding (`assets/icon.png`) and multi-resolution ICO (`assets/icon.ico`) with vertical baseline anchoring and 89% optical fill across installers, registry entries, and package manifests.
- **Package Manager Ecosystem**: Full manifest support for Scoop (`jvm.json`), Chocolatey (`jvm.nuspec`, `chocolateyInstall.ps1`, `chocolateyUninstall.ps1`), Winget (`DiamTek.JVM.yaml`), and an automated WiX Toolset v4 MSI build pipeline (`build-msi.ps1`).
- **Automated Chocolatey Packaging (`build-choco.ps1`)**: Introduced `packages/choco/build-choco.ps1` to automatically synchronize `jvm.nuspec` metadata and versioning directly from `jvm.bat`, validate XML schema and UTF-8 encoding, and pack Chocolatey distribution packages (`.nupkg`) in CI/CD.
- **Flat Release Staging Architecture & SLSA Attestation**: Engineered a flat staging pipeline (`dist/`) in `.github/workflows/release.yml` preventing nested subfolder artifacts in release zips, generating unified `dist/SHA256SUMS.txt` digests, and generating cryptographically verifiable Sigstore SLSA build provenance attestations across all release assets (`dist/*`) via `actions/attest-build-provenance@v2`.
- **Standalone WiX v4 Dual-Architecture MSI Pipeline**: Engineered an automated standalone WiX Toolset v4 build pipeline (`packages/msi/build-msi.ps1`) compiling self-contained, single-file Windows Installers for both `x64` and `arm64` (`$Arch = "all"` by default). Utilizes `<MediaTemplate EmbedCab="yes" />` for embedded cabinet `#cab1.cab` packaging (~900 KB) with `<MajorUpgrade>` downgrade prevention.
- **Autonomous Standalone MSI Compiler**: Hardened `packages/msi/build-msi.ps1` with multi-tier candidate path resolution, autonomous GitHub source bootstrapping into `%TEMP%` when executed outside the repository (e.g., from `Downloads`), automatic export of `DOTNET_ROOT` / `DOTNET_ROOT_X64` so WiX CLI apphosts resolve the .NET runtime across all environments, XML-escaped absolute asset injection into `jvm.wxs`, and explicit COM database handle release to prevent file-lock conflicts.
- **Automated 21-Point MSI Verification Suite**: Developed an end-to-end automated verification script (`packages/msi/test-msi.ps1`) checking quiet installation (`msiexec /qn`), binary layout, CLI `bin/` directory hygiene (hook isolation), Start Menu application and uninstaller shortcuts indexed in Windows Search, registry integrity, PATH persistence, PowerShell profile integration and tab-completer channel flags, update channel initialization (`channel.txt`), Windows Terminal profile injection, CLI sanity subshell execution, quiet uninstallation, and zero-residual filesystem hygiene with exit codes tailored for CI/CD pipelines and GitHub Actions build provenance attestations (`actions/attest-build-provenance`).
- **Deep UAC Uninstaller Engine**: Introduced `uninstall.ps1` with automatic UAC administrator privilege escalation to completely scrub JVM, PATH entries, environment variables, AppData Ecosystem caches, and installed JDKs.
- **Uninstaller Directory Lock Staging**: Uninstaller stages its script to `%TEMP%` and pivots CMD working directory to `%TEMP%` before execution, releasing file and directory handles so the parent JVM directory can be fully wiped without file locks.
- **Uninstaller External Handoff Runner & Zero-Frame Decoupling**: Engineered an external uninstaller handoff runner (`%TEMP%\jvm_uninstall_<rand>.bat`) with a dedicated parameter-expansion subroutine (`:ChainUninstallerRunner`) and direct `goto` transitions. By eliminating compound loop blocks and unrolling all active `cmd.exe` subroutine call frames before invoking the external runner, `jvm.bat` is completely decoupled from disk before the uninstallation wipe executes, eliminating post-deletion file seek errors (`The system cannot find the path specified.`) and guaranteeing clean exit codes back to the host shell prompt.
- **Conditional JDK Directory Wipe Prompt**: Uninstaller only prompts to delete `C:\Program Files\Java` if the directory actually exists on the filesystem, remaining completely silent when no JDK directory is present.
- **Single-Destination Target Architecture**: Synchronized `TargetDir` handling so updating standalone or custom installations writes directly to the target location without creating duplicate parallel `%LOCALAPPDATA%` installations.
- **Resilient Companion Asset Retrieval**: Hardened `LICENSE`, `README.md`, and `uninstall.ps1` fetching with per-file exception boundaries, automatic `HEAD` CDN fallback, and safe path comparisons, eliminating false-positive warnings and `Resolve-Path` exceptions.
- **Windows Integration**: Automatically registers JVM into Windows Settings / Installed apps (`HKCU:\...\Uninstall\DiamTek.JVM`) with native uninstallation support and creates a Start Menu uninstaller shortcut.
- **Terminal & CLI Uninstaller**: Added a full system wipe option in the interactive Settings menu and CLI support via `jvm self-uninstall`.

### Architecture & Core Engines
- **Enterprise Storage Migration**: Migrated the entire storage architecture from the user profile (`%USERPROFILE%\.jvm`) to `%LOCALAPPDATA%\DiamTek\JVM` for strict enterprise-grade path compliance.
- **Directory Junction Architecture**: Completely migrated the core routing architecture to use native Windows Directory Junctions (`%LOCALAPPDATA%\DiamTek\JVM\current`). This enables 100% UAC-free, instantaneous version switching that dynamically syncs across all open terminal windows.
- **Dual-Architecture Engine**: Built a Dual-Architecture toggle allowing users to seamlessly swap between the new "Symlink Mode" and the legacy "Registry Mode" directly from the Settings Menu.
- **PowerShell Registry Wrappers**: Re-engineered the legacy Registry Mode to utilize background PowerShell wrappers. This fixes a major historical bug where switching versions would fail silently for non-Admin standard users.
- **Universal Candidate Engine**: Built a universal payload engine capable of downloading, extracting, and symlinking binaries natively, powering both JDK installations and ecosystem tools.
- **Smart Caching**: Improved script navigation and execution speed via a smart caching `NEEDS_RESCAN` architecture that prevents redundant local directory polling.
- **ARM64 Native Support**: Added ARM64/AArch64 hardware auto-detection, dynamically routing all vendor API queries to architecture-specific download endpoints.

### Ecosystem & Third-Party Integrations
- **BellSoft Liberica JDK**: Full native downstream integration for BellSoft Liberica across Java 8, 11, 17, 21, and latest STS releases on both x64 and ARM64. Features automated release discovery via the official BellSoft API (`https://api.bell-sw.com/v1/liberica/releases`) and SHA1 cryptographic checksum validation.
- **IBM Semeru Runtime (OpenJ9)**: Integrated IBM Semeru certified OpenJDK binaries powered by Eclipse OpenJ9 across Java 8, 11, 17, and 21 for Windows x64. Features GitHub API asset resolution and SHA256 integrity verification, offering substantial cloud memory footprint reductions and rapid JIT startup optimizations.
- **JVM Ecosystem Parity**: Natively support the broader JVM Ecosystem (Maven, Gradle, Kotlin, Scala, Groovy) with dynamic APIs for downloading, extracting, and routing toolchains. Version arguments default to `latest` on install (e.g., `jvm install scala`), uninstallation supports smart auto-detection (auto-removing single installed versions or providing an interactive numbered menu if multiple exist), and GitHub-backed candidate resolvers (Maven, Kotlin, Scala) feature automatic zero-quota HTTP 302 redirect fallback when API rate limits are encountered.
- **Interactive Ecosystem Auto-Updater**: Engineered a vendor-selection menu that checks individual tools (or all at once) against GitHub/Apache APIs to resolve the absolute latest releases, and seamlessly prompts to upgrade out-of-date binaries.
- **`.java-version` Auto-Switching**: Added directory-based auto-switching using `.java-version` files. Defaults to True Session Isolation (only changes the current terminal) with an explicit `--global` CLI override flag. Support added for passing full CLI flags directly inside the `.java-version` file.
- **`.sdkmanrc` Hijack Protocol**: Built a native `.sdkmanrc` parser to dynamically hijack cross-platform SDKMAN workflows, providing seamless cross-compatibility for Windows developers working on Linux-first teams. Expanded translations to dynamically parse SDKMAN vendor identifiers for Liberica (`librca`, `nik`, `liberica`) and Semeru (`sem`, `semeru`).

### Security, Validation & Integrity
- **Zip-Slip Archive Traversal Containment**: Hardened `:ExecuteSharedDownloader` against directory traversal vulnerabilities by verifying that every extracted entry resolves strictly within the designated target root directory, blocking malicious or malformed archives before any files can be written to disk.
- **BellSoft Liberica Cryptographic Verification**: Formally documented BellSoft's upstream distribution policy of publishing SHA1 checksums and ensured cryptographic parity through native `.NET` verification.
- **.NET Cryptography SHA Validation**: Implemented enterprise-grade SHA256 checksum verification for all JDK downloads using native `.NET` Cryptography APIs to protect against corrupted payloads. Added dynamic SHA256/SHA512 validation with automatic SHA1 fallback for older legacy endpoints (like Maven).
- **One-Liner Installation Script**: Introduced a bulletproof one-liner installation script (`install.ps1`) for frictionless setup and automatic code sanitization across environments.
- **Self-Updater Sentinel Guard**: Added a `rem END OF SCRIPT` sentinel integrity check to the self-updater to automatically reject truncated or corrupted payload downloads.
- **1024-Character PATH Fix**: Fixed the notorious Windows `setx` 1024-character PATH truncation bug by completely replacing all environment variable updates with infinite-length `.NET` API calls.
- **Redundant Registry Backups**: The `jvm clear` and uninstallation commands now automatically backup both `HKCU` and `HKLM` environment registry keys to `%LOCALAPPDATA%\DiamTek\JVM\backups\` before executing destructive scrubs.
- **Offline-Aware Error Handling**: Added structured error handling across all network operations with clean `[ ERROR ]` / `[ DETAIL ]` outputs instead of raw exception dumps.

### CLI Automation & Parsing
- **Dual Update Channel Engine (Stable vs Nightly)**: Introduced update channel management via `jvm channel [stable|nightly]`, flag overrides (`--channel`, `--nightly`, `--stable`), and an interactive toggle in the Settings Menu. The Stable channel queries official tagged releases (`releases/latest`) marked green `[Stable]`, while the Nightly channel delivers cutting-edge builds from `main` marked purple `[Nightly]`. Features enterprise-grade cryptographic SHA-256 integrity verification against release `SHA256SUMS.txt` digests, ahead-of-remote safety checks that prevent downgrading unreleased local builds on either channel, full comparison of both Semantic Version and Build Number (`v!JVM_VERSION! (Build !JVM_BUILD!)`), and automatic rate-limit safe fallback architecture (via Fastly raw endpoints and GitHub web redirects) to ensure update queries never fail with HTTP 403.
- **PowerShell Profile Hook Activation Hint**: Added an immediate contextual hint (`Run '. $PROFILE' or restart your terminal`) upon configuring the profile hook to activate dynamic completions immediately.
- **Multi-Invocation PowerShell Tab Completion**: Expanded argument completer registration from `jvm` alone to `@('jvm', 'jvm.bat', '.\jvm.bat')`, enabling seamless tab completion whether invoking globally via PATH or locally via `./jvm.bat`. Complete support added for `channel`, `stable`, `nightly`, and channel flags.
- **CLI Ergonomics & Developer Aliases**: Added industry-standard CLI aliases across all command surfaces: `jvm ls` (mapped to `jvm list`), `jvm info` and `jvm whoami` (mapped to `jvm current`), `jvm check` (mapped to `jvm doctor`), and `jvm prune` (mapped to `jvm clean`).
- **NO_COLOR Standard Compliance**: Full compliance with the [NO_COLOR](https://no-color.org) specification (`NO_COLOR=1` or `NO_COLOR=true`) and added an explicit `--no-color` CLI flag across all subcommands to suppress ANSI color escape sequences in CI/CD pipelines and automated log aggregators.
- **Native CLI Help Engine**: Built-in formatted help screen (`jvm help`, `jvm --help`, `jvm -h`, `jvm /?`) displaying the full command suite, arguments, ecosystem switches, maintenance utilities, flag overrides, and an expanded 8-vendor support matrix.
- **Deep Uninstaller Command**: Added `jvm self-uninstall` to invoke the UAC-elevated deep uninstallation pipeline directly from any terminal.
- **Semantic CLI Routing & Interactive LTS Selection**: Added robust semantic routing commands (`jvm latest`, `jvm lts`) and powerful flag overrides (`--symlink`, `--legacy`, `--vendor`, `--latest`, `-y`). Running `jvm install lts` presents an interactive version selection menu offering supported LTS versions (17, 21, 25), with the `--latest` flag automatically locking onto the newest LTS release, and enforces an upstream Java 17 distribution floor.
- **Semantic Self-Updater Engine**: Built a seamless self-updater engine (`jvm version`, `jvm self-update`) that securely compares build numbers using the native `.NET` `[version]` class before automatically downloading and atomic-swaps the core script.
- **External Process Handoff Engine**: Self-update now decouples from `jvm.bat` by chaining execution into an external runner (`%TEMP%\jvm_updater_*.bat`) without `call`. This allows `cmd.exe` to close `jvm.bat`'s file handle immediately, eliminating mid-stream byte-offset corruption, `'file' is not recognized` syntax errors, and duplicate installer invocation loops.
- **Dynamic GitHub CDN Cache Bypass**: Resolves the exact commit SHA of `main` via the GitHub API to bypass the 5-minute Fastly/Varnish edge caching on `raw.githubusercontent.com`, ensuring newly published releases are immediately discovered and fetched without propagation delays.
- **Dynamic Feature Resolvers**: Built a dynamic `FetchLatestVersions` resolver that queries the Adoptium API at runtime to establish the true latest feature release and LTS version numbers, eliminating hardcoded version constants.
- **Self-Contained Update Checkers**: Re-engineered the `UpdateChecker` as a fully self-contained inline PowerShell script generated at runtime for all six vendors, removing all external `.ps1` file dependencies.
- **Status & Diagnostic Dashboard (`jvm current` / `jvm status` / `jvm env`)**: Built a real-time diagnostic dashboard querying active Java vendor, version, `JAVA_HOME`, `java.exe` binary path, architecture switching mode (`[Symlink Mode]` in green vs `[Registry Mode]` in red), directory junction target highlighted in green, active update channel badge (`[Stable]` in green vs `[Nightly]` in purple), and active JVM ecosystem candidates (`maven`, `gradle`, `kotlin`, etc.).
- **Raw Binary Path Resolution (`jvm which` / `jvm path`)**: Added a high-speed CLI binary resolver printing the clean absolute filesystem path of `java.exe` or ecosystem candidate binaries directly to `stdout` (with exit code `0` on success and exit code `1` with error details on `stderr`), tailored for automation scripts, IDE configurations, and CI/CD pipelines.
- **Automated System Health Diagnostics (`jvm doctor`)**: Introduced an automated 7-point deep health check evaluating storage root access and permissions, architecture switching mode, directory junction pointer and `bin\java.exe` target reachability, User vs Machine `JAVA_HOME` synchronization, `where.exe java` PATH precedence and rogue Oracle shadowing, and PowerShell `$PROFILE` hook status.
- **Ephemeral One-Off Subshell Runner (`jvm exec` / `jvm run`)**: Engineered an ephemeral subshell runner that executes commands against any installed JDK in an isolated process context with local `%JAVA_HOME%` and `%PATH%` without altering the active Directory Junction, system environment, or Windows Registry, preserving and propagating the exact exit code back to the caller.
- **Project Version Pinning (`jvm pin` / `jvm local`)**: Added automated creation and inspection of `.java-version` files directly from the CLI, supporting inline vendor and architecture flags (`jvm pin 21 --vendor adoptium`).
- **File Explorer Directory Jump (`jvm open` / `jvm home`)**: Added instant Windows File Explorer navigation targeting active JDKs, candidate ecosystem tools (`maven`, `gradle`, `kotlin`), specific version folders, or the `%LOCALAPPDATA%\DiamTek\JVM` storage root.
- **SDKMAN! & NVM Transparent Aliases (`jvm use` / `jvm default`)**: Added 1:1 transparent compatible aliases (`jvm use`, `jvm default`) to accommodate developers migrating from Unix-based version managers.
- **Safe Cache Maintenance (`jvm clean`)**: Added a dedicated disk cache pruner that safely sweeps installer archives (`%TEMP%\jdk_*_download.*`), extraction trees (`%TEMP%\jdk_*_extract`), temporary downloaders (`%TEMP%\jvm_dl_*.ps1`), AppData downloads (`%LOCALAPPDATA%\DiamTek\JVM\downloads\*`), and orphaned candidate temp folders (`temp_*`), reporting freed megabytes and file counts without touching installed runtimes or registry configurations.
- **PowerShell Profile Hook Management (`jvm hook`)**: Added dedicated CLI commands (`jvm hook`, `jvm hook status`, `jvm hook remove`) and decoupled the PowerShell profile auto-sync hook from the global User PATH configuration in the Settings Menu with `chcp 65001` UTF-8 code page enforcement to eliminate diacritic path distortion in user profiles, providing separate `[INSTALLED]` / `[NOT INSTALLED]` indicators for both.

### UI & Developer Experience
- **Unified Sub-Hubs**: Consolidated the Main Menu into two unified "JDK Management" and "Ecosystem Management" sub-hubs, each mirroring the identical "Switch Active" / "Version Management" layout.
- **Consistent Layouts**: Enforced consistent, unified UI layouts (`--- Manage by Vendor/Tool ---` and `--- Actions ---`) across all JDK and Ecosystem menus.
- **In-Memory Bubble Sort**: Built an optimized, strictly in-memory Bubble Sort algorithm to organize JDKs visually by newest version in the UI.
- **Vendor Grouping**: Introduced dynamic Vendor grouping across all 8 supported upstream distributions (Oracle, Adoptium, GraalVM, Corretto, Zulu, Microsoft, Liberica, Semeru) across all interactive menus.
- **Code Page Preservation**: Added native terminal code page preservation and restoration to seamlessly handle UTF-8 rendering (like the `©` symbol) without permanently corrupting the user's host environment.
- **Animated ANSI Progress Bar**: Added a real-time, 30-character animated ANSI progress bar to `install.ps1` with percentage indicators tracking environment initialization, release resolution, core engine fetch, encoding sanitization, companion assets, user PATH configuration, profile hook registration, and shortcut integration.
- **Zero-Flicker Background Requests**: Configured `$ProgressPreference = 'SilentlyContinue'` across all PowerShell hooks, inline web requests, and candidate resolvers, completely suppressing the top blue/cyan progress bar that previously flashed during silent background network queries.
- **Progress Bar Enhancements**: Overhauled the Self-Updater to utilize the Universal Candidate Downloader engine to grant it native ANSI progress bars. Restored native extraction progress bars and forced a final 100% frame to fix a rounding edge case.
- **UI Tag Formatting**: Aligned all UI tags to a strict 10-character padded format (`[   OK   ]`, `[ ACTIVE ]`, etc.) for perfect visual alignment.

### Documentation & Enterprise Knowledge Base
- **Enterprise Documentation Portal**: Authored a complete suite of six dedicated technical guides (`INSTALLATION.md`, `USAGE.md`, `ARCHITECTURE.md`, `FAQ.md`, `SDKMAN-Comparison.md`, and `CHANGELOG.md`) providing exhaustive coverage of all engine features, CLI commands, and system integration points.
- **Architectural Diagrams**: Designed three comprehensive Mermaid visual flowcharts illustrating Directory Junction resolution, Dual-Architecture switching internals, and the automated WiX Toolset v4 multi-stage CI/CD compilation pipeline.
- **IDE & Build System Integration**: Documented full configuration workflows for IntelliJ IDEA, Visual Studio Code (Language Server runtime), Gradle (`gradle.properties`), and Apache Maven (`toolchains.xml`), leveraging the stable `%LOCALAPPDATA%\DiamTek\JVM\current` junction to bypass IDE project re-indexing upon version switches.
- **Enterprise IT & Deployment Automation**: Added enterprise endpoint management specifications for Microsoft Intune, MECM (SCCM), and Active Directory Group Policy (GPO), including silent parameters (`/qn`), detection rules (`ProductCode`, Registry, File system), and process exit codes (`0`, `1`, `1602`, `1603`, `3010`).
- **Enterprise Readiness & Zero-Admin Corporate Strategy**: Documented the four pillars of corporate adoption in `README.md`, `docs/INSTALLATION.md`, and `docs/FAQ.md`: standard-user zero-admin installation for locked-down corporate laptops (0 UAC prompts, 0 IT tickets), mixed-OS cross-platform engineering team onboarding via `.sdkmanrc`, silent Intune/MECM fleet rollout, and SecOps/EDR compliance hygiene.
- **Comprehensive Troubleshooting & Diagnostics**: Documented PATH precedence shadowing diagnosis (`where.exe java`), rogue legacy path cleanup via `jvm clear`, corporate proxy/VPN configurations, Windows Root CA trust, Windows Defender SmartScreen guidance, and Zone.Identifier PowerShell script unblocking (`Unblock-File`).
- **Connected Navigation Architecture**: Integrated uniform breadcrumb navigation headers, contextual Quick Jump table of contents, and bidirectional cross-links across all documentation pages.
- **GitHub Pages Optimization**: Tailored Jekyll Cayman theme configuration (`_config.yml`), ensuring responsive layouts, cross-domain link rewriting, and asset packaging across both GitHub web and GitHub Pages portals.
- **Open-Source Governance Suite**: Published standard community health files, including `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, structured issue templates, and a pull request template.

### Bug Fixes & System Stability
- **Zero-File UAC Elevation (LPE / TOCTOU Hardening)**: Replaced all temporary `.bat` and `.ps1` elevation payloads in `%TEMP%` (`ADMIN_BAT` and `ELEVATE_SCRIPT`) with direct, in-memory parameterized process execution (`Start-Process powershell -Verb RunAs ...`), completely eliminating Time-of-Check to Time-of-Use race conditions and Local Privilege Escalation vectors.
- **Strict Integrity Verification Decoupling**: Separated prompt confirmation (`-y` / `--yes`) from integrity verification; introduced `--skip-checksum` (alias `--no-verify`) so automated CI/CD scripts never silently proceed without checksum verification when hash endpoints are unavailable.
- **Repository Configuration Sanitization**: Hardened `.java-version` and `.sdkmanrc` parsing with strict metacharacter filtering (`| findstr /v "[&|<>]"`), neutralizing shell command injection vectors from untrusted repositories.
- **Inline PowerShell Delimiter Escaping**: Hardened all path interpolations in inline elevated PowerShell scripts with single-quote escaping (`:'=''`), eliminating syntax errors and command breaks on paths containing apostrophes or single quotes.
- **MSI Tooling Autonomous 4-Tier Resolution & .NET Bootstrapping**: Enhanced `test-msi.ps1` and `build-msi.ps1` with automatic Zone.Identifier unblocking (`Unblock-File`), process-scoped ExecutionPolicy bypass (`Set-ExecutionPolicy -Scope Process Bypass`), robust path resolution (`$PSScriptRoot` / `$PSCommandPath`), user-space `.NET` SDK bootstrapping (`dotnet-install.ps1`), GitHub release downloading, and remote source extraction. This enables `test-msi.ps1` to run autonomously on any clean machine—even with no prior repository, build scripts, or .NET tools installed.
- **WixQuietExec Path Resolution**: Hardcoded `[WindowsFolder]System32\WindowsPowerShell\v1.0\powershell.exe` in WiX custom actions to resolve `WixQuietExec` error `0x80070002` ("file not found") occurring because Windows Installer service deferred execution does not inherit the standard shell PATH.
- **MSI CustomAction Shortcut Race Condition**: Rescheduled MSI install hook execution sequence to `After="CreateShortcuts"` (sequence 4501) rather than `After="InstallFiles"` (sequence 4002), guaranteeing the Start Menu `.lnk` file is present on disk before PowerShell attempts to polish it with Windows Terminal integration.
- **MSI Uninstaller File Lock Race**: Eliminated asynchronous background directory deletion routines (`cmd.exe /c timeout ... rmdir`) from MSI uninstallation hooks, delegating filesystem removal exclusively to standard Windows Installer actions and preventing Windows Installer Error 2318 (`File does not exist: icon.png`).
- **Keystroke Interception on Updater Handoff**: Resolved a bug where the first user keystroke in `jvm.bat` was ignored after returning from a self-update. This was caused by a background `start /b timeout` deletion thread competing for the console input buffer. Completely eliminated the background thread, allowing the interactive menu to respond instantaneously on the first keystroke while handling cleanup safely at batch startup.
- **Direct Target Directory Updates**: Removed repository directory redirection heuristics (`$isDevRepo`) in `install.ps1`, ensuring custom locations, standalone copies, and cloned workspaces update their running `jvm.bat` directly instead of silently redirecting into `%LOCALAPPDATA%`.
- **Commit SHA Handoff Forwarding**: Forwarded the dynamically resolved GitHub commit SHA (`-Branch "!REMOTE_REF!"`) from `jvm.bat` to `install.ps1` to eliminate duplicate API calls, bypass Fastly CDN edge caching on `HEAD`/`main`, and guarantee newly installed scripts immediately reflect the latest build version.
- **Live Terminal Memory Collapse**: Resolved a critical bug where running the uninstallation or switch commands could completely destroy all native Windows commands (`findstr`, `choice`) in the active session. This occurred because the previous path-scrubber relied on batch string substitution (`!PATH:string=!`), which suffered catastrophic quote-collisions when evaluating complex paths containing double quotes or undefined variables. Completely replaced all batch substitution with safe, native PowerShell `-not` array evaluations.
- **UTF-8 BOM Interpretation**: Fixed critical Windows `cmd.exe` UTF-8 BOM interpretation bugs and UNIX (LF) line-ending crashes (the `cho` bug) by enforcing explicit CRLF encoding during downloads.
- **Double-Quote `PATH` Encapsulation**: Hardened all `for /f` variable export loops with double-quote encapsulation to prevent `cmd.exe` from misinterpreting `PATH` strings containing embedded quotes as file lists.
- **Exclamation Mark Corruption**: Fixed delayed expansion parsing bugs that corrupted custom paths containing exclamation marks (`!`).
- **Oracle Update Crash**: Fixed Oracle update checks crashing with `'$' is not recognized` by switching the PowerShell payload to pipe-safe string concatenation.
- **Forward Compatibility**: Replaced deprecated `wmic` environment queries with direct `reg query` calls for guaranteed forward compatibility with Windows 11.
- **Variable Slicing Errors**: Hardened the Global Command installer and resolved subshell variable slicing errors.
- **Cross-Architecture Registry Conflicts**: Fixed conflicts between User and Machine environment variables causing ghost path artifacts.
- **UAC Deadlocks**: Fixed edge-case UAC elevation deadlocks during global registry writes.
- **Directory Protection**: Added a conditional `rmdir` guard to prevent extracted files from being destroyed if a junction move failure occurs.
- **Navigation State Leaks**: Patched a variable state-leak during cross-menu navigation and stabilized the back-navigation structural loop across all interactive UI hubs.

## [0.5.0] - 2026-08-20

### Added
- **Global Command Installer**: Built a new Global Command Installer to dynamically inject the JVM directory into the Windows User PATH.
- **CLI Quick-Switching**: Introduced CLI Quick-Switching (`jvm <version>`) for silent, background Java swapping directly from the terminal.
- **Visual Countdown**: Replaced standard script pauses with an interruptible visual auto-close countdown loop.

### Changed
- **UAC Elevation Refactor**: Refactored the UAC elevation block to hardcode `powershell.exe` absolute paths, preventing crashes from corrupted environment variables.
- **UI Polish**: Polished UI aesthetics with strict ANSI color hierarchy and muted absolute file paths.

## [0.4.0] - 2026-08-19

### Added
- **Dynamic Scanner**: Re-engineered the JDK discovery engine to dynamically scan developer toolkits (Scoop, Gradle, IntelliJ).
- **Fast Parsing**: Replaced hardcoded loops with fast release file parsing for instantaneous version resolution.
- **Sub-menu Architecture**: Completely overhauled the UI architecture with robust sub-menu navigation and input validation.

### Changed
- **ANSI Enhancements**: Polished ANSI padding, visual alignments, and nested log formatting across all menus.

### Fixed
- **Variable Scope Crashes**: Fixed critical variable scope bugs that caused silent crashes during path switching.

## [0.3.0] - 2026-08-19

### Changed
- **Relicensed to AGPL-3.0**: Relicensed the project from the MIT License to the GNU Affero General Public License v3.0 (AGPL-3.0).
- **Documentation Updates**: Added standard LICENSE file containing the full AGPL-3.0 text and updated `README.md` and `jvm.bat` file headers to reflect the new licensing and copyright.

## [0.2.0] - 2026-06-01

### Added
- **Update Checker**: Added Update Checker that compares local metadata against Oracle servers.
- **Bulk Updates**: Added Update All capability to bulk-scan and patch all installed JDKs.
- **Automated Hot-swapping**: Automated hot-swapping handles downloading, folder swapping, and `JAVA_HOME` patching.
- **Safe Versioning**: Added safe versioning logic to prevent accidental downgrades.

## [0.1.1] - 2026-05-17

### Changed
- **UI Adjustment**: Rename "Exit without changes" menu item to "Exit".

### Fixed
- **PATH Corruption Bug**: Fix PATH corruption causing silent crashes after version switch.
- **Expansion Buffer**: Add local delayed-expansion buffer to safely rebuild session PATH.
- **System Variable Drops**: Prevent `choice` command failure from dropped system variables.

## [0.1.0] - 2026-05-17

### Added
- **Initial Release**: First stable release of the Java Version Manager for Windows.

---

[← Back to Documentation Overview](../README.md#documentation)