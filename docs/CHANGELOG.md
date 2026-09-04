# Changelog

All notable changes to the Java Version Manager for Windows will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to Semantic Versioning.

## [0.6.0] - 2026-09-XX

This release represents a massive architectural overhaul of the entire engine, adding comprehensive ecosystem support, native automation integrations, and solving multiple Windows-specific system limitations.

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
- **Semantic CLI Routing**: Added robust semantic routing commands (`jvm latest`, `jvm lts`) and powerful flag overrides (`--symlink`, `--legacy`, `--vendor`, `--latest`, `-y`).
- **Semantic Self-Updater Engine**: Built a seamless self-updater engine (`jvm version`, `jvm self-update`) that securely compares build numbers using the native `.NET` `[version]` class before automatically downloading and atomic-swapping the core script.
- **Dynamic Feature Resolvers**: Built a dynamic `FetchLatestVersions` resolver that queries the Adoptium API at runtime to establish the true latest feature release and LTS version numbers, eliminating hardcoded version constants.
- **Self-Contained Update Checkers**: Re-engineered the `UpdateChecker` as a fully self-contained inline PowerShell script generated at runtime for all six vendors, removing all external `.ps1` file dependencies.

### UI & Developer Experience
- **Unified Sub-Hubs**: Consolidated the Main Menu into two unified "JDK Management" and "Ecosystem Management" sub-hubs, each mirroring the identical "Switch Active" / "Version Management" layout.
- **Consistent Layouts**: Enforced consistent, unified UI layouts (`--- Manage by Vendor/Tool ---` and `--- Actions ---`) across all JDK and Ecosystem menus.
- **In-Memory Bubble Sort**: Built an optimized, strictly in-memory Bubble Sort algorithm to organize JDKs visually by newest version in the UI.
- **Vendor Grouping**: Introduced dynamic Vendor grouping (Oracle, Adoptium, GraalVM, Corretto, Zulu, Microsoft) across all interactive menus.
- **Code Page Preservation**: Added native terminal code page preservation and restoration to seamlessly handle UTF-8 rendering (like the `©` symbol) without permanently corrupting the user's host environment.
- **Progress Bar Enhancements**: Overhauled the Self-Updater to utilize the Universal Candidate Downloader engine to grant it native ANSI progress bars. Restored native extraction progress bars and forced a final 100% frame to fix a rounding edge case.
- **UI Tag Formatting**: Aligned all UI tags to a strict 10-character padded format (`[   OK   ]`, `[ ACTIVE ]`, etc.) for perfect visual alignment.

### Bug Fixes & System Stability
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