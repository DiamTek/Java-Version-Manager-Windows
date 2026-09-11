# Changelog

<p align="center">
  <a href="../README.md">🏠 Overview</a> &nbsp;•&nbsp;
  <a href="INSTALLATION.md">📦 Installation</a> &nbsp;•&nbsp;
  <a href="USAGE.md">📖 Usage</a> &nbsp;•&nbsp;
  <a href="ARCHITECTURE.md">🏗️ Architecture</a> &nbsp;•&nbsp;
  <a href="FAQ.md">❓ FAQ</a> &nbsp;•&nbsp;
  <a href="SDKMAN-Comparison.md">⚖️ SDKMAN! Comparison</a> &nbsp;•&nbsp;
  <a href="CHANGELOG.md">📜 Changelog</a>
</p>

---

All notable changes to the Java Version Manager for Windows will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to Semantic Versioning.

## [1.0.0] - 2026-09-09

This milestone 1.0.0 release marks the official general availability of the DiamTek Java Version Manager for Windows. It features a massive architectural overhaul of the entire engine, adding comprehensive ecosystem support, native automation integrations, full package manager distribution, and solving multiple Windows-specific system limitations.

### Distribution & Packaging
- **Windows Terminal Profile Integration**: Automatically registers a dedicated "Java Version Manager" profile in Windows Terminal `settings.json` (Release, Preview, and Unpackaged) pointing to high-res `icon.png`, with `closeOnExit: always` and `cmd.exe /c` execution lifecycle so terminal tabs close cleanly upon exiting the JVM menu.
- **Start Menu & Taskbar Launchers**: Generates Start Menu application shortcuts and dynamically synchronizes existing pinned taskbar shortcuts to launch the registered Windows Terminal profile when available, with a graceful `cmd.exe /c` fallback for classic console hosts.
- **Dynamic File Size Estimation**: Dynamically calculates recursive disk footprint across `%LOCALAPPDATA%\DiamTek\JVM` and `%USERPROFILE%\.jvm`, enforcing a 1,024 KB floor in `EstimatedSize` registry key so Windows 11 Installed Apps displays accurate application sizes (1.00 MB+) instead of suppressing file size.
- **Comprehensive Lifecycle Uninstallation**: Deepened `uninstall.ps1` to scrub Windows Terminal profiles, reset `defaultProfile` if targeted, remove pinned taskbar shortcuts, and eliminate temporary `.jvm_session_target` and `jvm_*` artifacts.
- **Official Branding Suite**: Integrated high-resolution 768x768 ARGB source branding (`assets/icon.png`) and multi-resolution ICO (`assets/icon.ico`) with vertical baseline anchoring and 89% optical fill across installers, registry entries, and package manifests.
- **Package Manager Ecosystem**: Full manifest support for Scoop (`jvm.json`), Chocolatey (`jvm.nuspec`, `chocolateyInstall.ps1`, `chocolateyUninstall.ps1`), Winget (`DiamTek.JVM.yaml`), and an automated WiX Toolset v4 MSI build pipeline (`build-msi.ps1`).
- **Standalone WiX v4 Dual-Architecture MSI Pipeline**: Engineered an automated standalone WiX Toolset v4 build pipeline (`packages/msi/build-msi.ps1`) compiling self-contained, single-file Windows Installers for both `x64` and `arm64` (`$Arch = "all"` by default). Utilizes `<MediaTemplate EmbedCab="yes" />` for embedded cabinet `#cab1.cab` packaging (~900 KB) with `<MajorUpgrade>` downgrade prevention.
- **Autonomous Standalone MSI Compiler**: Hardened `packages/msi/build-msi.ps1` with multi-tier candidate path resolution, autonomous GitHub source bootstrapping into `%TEMP%` when executed outside the repository (e.g., from `Downloads`), automatic export of `DOTNET_ROOT` / `DOTNET_ROOT_X64` so WiX CLI apphosts resolve the .NET runtime across all environments, XML-escaped absolute asset injection into `jvm.wxs`, and explicit COM database handle release to prevent file-lock conflicts.
- **Automated 18-Point MSI Verification Suite**: Developed an end-to-end automated verification script (`packages/msi/test-msi.ps1`) checking quiet installation (`msiexec /qn`), binary layout, CLI `bin/` directory hygiene (hook isolation), Start Menu application and uninstaller shortcuts indexed in Windows Search, registry integrity, PATH persistence, Windows Terminal profile injection, CLI sanity subshell execution, quiet uninstallation, and zero-residual filesystem hygiene with exit codes tailored for CI/CD pipelines and GitHub Actions build provenance attestations (`actions/attest-build-provenance`).
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
- **JVM Ecosystem Parity**: Natively support the broader JVM Ecosystem (Maven, Gradle, Kotlin, Scala, Groovy) with dynamic APIs for downloading, extracting, and routing toolchains.
- **Interactive Ecosystem Auto-Updater**: Engineered a vendor-selection menu that checks individual tools (or all at once) against GitHub/Apache APIs to resolve the absolute latest releases, and seamlessly prompts to upgrade out-of-date binaries.
- **`.java-version` Auto-Switching**: Added directory-based auto-switching using `.java-version` files. Defaults to True Session Isolation (only changes the current terminal) with an explicit `--global` CLI override flag. Support added for passing full CLI flags directly inside the `.java-version` file.
- **`.sdkmanrc` Hijack Protocol**: Built a native `.sdkmanrc` parser to dynamically hijack cross-platform SDKMAN workflows, providing seamless cross-compatibility for Windows developers working on Linux-first teams.

### Security, Validation & Integrity
- **`.NET` Cryptography SHA Validation**: Implemented enterprise-grade SHA256 checksum verification for all JDK downloads using native `.NET` Cryptography APIs to protect against corrupted payloads. Added dynamic SHA256/SHA512 validation with automatic SHA1 fallback for older legacy endpoints (like Maven).
- **One-Liner Installation Script**: Introduced a bulletproof one-liner installation script (`install.ps1`) for frictionless setup and automatic code sanitization across environments.
- **Self-Updater Sentinel Guard**: Added a `rem END OF SCRIPT` sentinel integrity check to the self-updater to automatically reject truncated or corrupted payload downloads.
- **1024-Character PATH Fix**: Fixed the notorious Windows `setx` 1024-character PATH truncation bug by completely replacing all environment variable updates with infinite-length `.NET` API calls.
- **Redundant Registry Backups**: The `jvm clear` and uninstallation commands now automatically backup both `HKCU` and `HKLM` environment registry keys to `%TEMP%` before executing destructive scrubs.
- **Offline-Aware Error Handling**: Added structured error handling across all network operations with clean `[ ERROR ]` / `[ DETAIL ]` outputs instead of raw exception dumps.

### CLI Automation & Parsing
- **Native CLI Help Engine**: Built-in formatted help screen (`jvm help`, `jvm --help`, `jvm -h`, `jvm /?`) displaying the full command suite, arguments, ecosystem switches, maintenance utilities, and flag overrides.
- **Deep Uninstaller Command**: Added `jvm self-uninstall` to invoke the UAC-elevated deep uninstallation pipeline directly from any terminal.
- **Semantic CLI Routing**: Added robust semantic routing commands (`jvm latest`, `jvm lts`) and powerful flag overrides (`--symlink`, `--legacy`, `--vendor`, `--latest`, `-y`).
- **Semantic Self-Updater Engine**: Built a seamless self-updater engine (`jvm version`, `jvm self-update`) that securely compares build numbers using the native `.NET` `[version]` class before automatically downloading and atomic-swapping the core script.
- **External Process Handoff Engine**: Self-update now decouples from `jvm.bat` by chaining execution into an external runner (`%TEMP%\jvm_updater_*.bat`) without `call`. This allows `cmd.exe` to close `jvm.bat`'s file handle immediately, eliminating mid-stream byte-offset corruption, `'file' is not recognized` syntax errors, and duplicate installer invocation loops.
- **Dynamic GitHub CDN Cache Bypass**: Resolves the exact commit SHA of `main` via the GitHub API to bypass the 5-minute Fastly/Varnish edge caching on `raw.githubusercontent.com`, ensuring newly published releases are immediately discovered and fetched without propagation delays.
- **Dynamic Feature Resolvers**: Built a dynamic `FetchLatestVersions` resolver that queries the Adoptium API at runtime to establish the true latest feature release and LTS version numbers, eliminating hardcoded version constants.
- **Self-Contained Update Checkers**: Re-engineered the `UpdateChecker` as a fully self-contained inline PowerShell script generated at runtime for all six vendors, removing all external `.ps1` file dependencies.

### UI & Developer Experience
- **Unified Sub-Hubs**: Consolidated the Main Menu into two unified "JDK Management" and "Ecosystem Management" sub-hubs, each mirroring the identical "Switch Active" / "Version Management" layout.
- **Consistent Layouts**: Enforced consistent, unified UI layouts (`--- Manage by Vendor/Tool ---` and `--- Actions ---`) across all JDK and Ecosystem menus.
- **In-Memory Bubble Sort**: Built an optimized, strictly in-memory Bubble Sort algorithm to organize JDKs visually by newest version in the UI.
- **Vendor Grouping**: Introduced dynamic Vendor grouping (Oracle, Adoptium, GraalVM, Corretto, Zulu, Microsoft) across all interactive menus.
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
- **Comprehensive Troubleshooting & Diagnostics**: Documented PATH precedence shadowing diagnosis (`where.exe java`), rogue legacy path cleanup via `jvm clear`, corporate proxy/VPN configurations, Windows Root CA trust, Windows Defender SmartScreen guidance, and Zone.Identifier PowerShell script unblocking (`Unblock-File`).
- **Connected Navigation Architecture**: Integrated uniform breadcrumb navigation headers, contextual Quick Jump table of contents, and bidirectional cross-links across all documentation pages.
- **GitHub Pages Optimization**: Tailored Jekyll Cayman theme configuration (`_config.yml`), ensuring responsive layouts, cross-domain link rewriting, and asset packaging across both GitHub web and GitHub Pages portals.
- **Open-Source Governance Suite**: Published standard community health files, including `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, structured issue templates, and a pull request template.

### Bug Fixes & System Stability
- **Zero-File UAC Elevation (LPE / TOCTOU Hardening)**: Replaced all temporary `.bat` and `.ps1` elevation payloads in `%TEMP%` (`ADMIN_BAT` and `ELEVATE_SCRIPT`) with direct, in-memory parameterized process execution (`Start-Process powershell -Verb RunAs ...`), completely eliminating Time-of-Check to Time-of-Use race conditions and Local Privilege Escalation vectors.
- **Strict Integrity Verification Decoupling**: Separated prompt confirmation (`-y` / `--yes`) from integrity verification; introduced `--skip-checksum` (alias `--no-verify`) so automated CI/CD scripts never silently proceed without checksum verification when hash endpoints are unavailable.
- **Repository Configuration Sanitization**: Hardened `.java-version` and `.sdkmanrc` parsing with strict metacharacter filtering (`| findstr /v "[&|<>]"`), neutralizing shell command injection vectors from untrusted repositories.
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

## [0.4.0] - 2026-08-20

### Added
- **Dynamic Scanner**: Re-engineered the JDK discovery engine to dynamically scan developer toolkits (Scoop, Gradle, IntelliJ).
- **Fast Parsing**: Replaced hardcoded loops with fast release file parsing for instantaneous version resolution.
- **Sub-menu Architecture**: Completely overhauled the UI architecture with robust sub-menu navigation and input validation.

### Changed
- **ANSI Enhancements**: Polished ANSI padding, visual alignments, and nested log formatting across all menus.

### Fixed
- **Variable Scope Crashes**: Fixed critical variable scope bugs that caused silent crashes during path switching.

## [0.3.0] - 2026-08-20

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

[← Back to Documentation Overview](../README.md#📚-documentation)