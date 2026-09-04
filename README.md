# Java Version Manager (JVM)

A lightweight, high-performance, color-coded Windows command-line utility designed to dynamically discover, download, and switch Java Development Kits (JDKs) and the entire JVM Ecosystem (Maven, Gradle, Kotlin, Scala, Groovy) with native SDKMAN! parity.

## 📥 Installation

Open Windows PowerShell (no Administrator privileges required) and paste the following one-liner:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/install.ps1" -OutFile "$env:TEMP\install.ps1"; & "$env:TEMP\install.ps1"
```
*This instantly downloads the core engine, provisions `%LOCALAPPDATA%\DiamTek\JVM`, and updates your PowerShell Profile so the `jvm` command is available everywhere.*

## 🚀 Features

* **Zero Dependencies (100% Native Windows):** Unlike SDKMAN or similar Unix-ports that require heavy POSIX subsystems (WSL, MSYS2, Git Bash, `curl`, `zip`), this utility is built entirely on native Windows APIs. It leverages pure Batch and embedded `.NET` Framework endpoints for networking, zip extraction, and SHA256 cryptography to run instantly out-of-the-box on any Windows 10/11 machine.
* **Full JVM Ecosystem Support (SDKMAN Parity):** Move beyond just Java! This tool features a powerful, UAC-free Universal Candidate Engine that natively resolves, downloads, and symlinks modern JVM build tools. Install and switch between **Maven**, **Gradle**, **Kotlin**, **Scala**, and **Groovy** instantly (`jvm install maven latest`, `jvm gradle 8.5`) — all without adding any heavy dependencies.
* **Dynamic Vendor Architecture:** Menus are dynamically grouped and filtered by vendor (Oracle, Adoptium, GraalVM, Corretto, Zulu, Microsoft) to keep your workspace clean and organized.
* **Intelligent Background Sorting:** Features a built-in, stable bubble-sort algorithm that organizes all discovered JDKs by their major version in descending order, ensuring your newest installations are always at the top of the list.
* **Semantic Target Routing:** Speak to the tool in human terms. Automatically jump to or install the latest available JDK using targets like `jvm latest` or `jvm lts`. The engine queries the Adoptium API at runtime to dynamically resolve the true latest feature release and LTS version numbers, so you never have to hardcode them.
* **ARM64 / AArch64 Auto-Detection:** Automatically detects your CPU architecture at startup (`x64` vs `ARM64`) and routes all vendor API queries to the correct architecture-specific download endpoint. Zero configuration needed — it just works on both Intel/AMD and ARM Windows machines.
* **Dual-Architecture Core (UAC-Free vs Registry):** Toggle seamlessly between lightning-fast **Symlink Mode** (bypasses UAC completely using a Directory Junction at `%LOCALAPPDATA%\DiamTek\JVM\current`) and legacy **Registry Mode** (auto-elevating background scripts to update system `HKLM` environment variables) based on your system compatibility needs.
* **Directory-based Auto-Switching (`.java-version` & `.sdkmanrc`):** Instantly configure a project's required environment by simply running `jvm` inside any directory containing a `.java-version` or SDKMAN `.sdkmanrc` file. The tool parses the file and seamlessly swaps your environment in the background with **True Session Isolation** (doesn't pollute your global Windows Registry). 
  * **`.java-version`** is strictly for JDKs, but our engine is incredibly advanced: it natively supports parsing full CLI flags directly from the file (e.g., `21 --vendor adoptium --legacy`), allowing you to lock specific vendors or architecture modes on a strict per-project basis.
  * **`.sdkmanrc`** natively supports the **entire JVM Ecosystem**! If you're collaborating with SDKMAN users on macOS/Linux, JVM will happily hijack their `.sdkmanrc` files on Windows, mapping their JDK vendor strings (`-tem`, `-amzn`, etc.) directly to your native JDKs, *and* automatically isolating and activating the project's exact required versions of Maven, Gradle, Kotlin, Scala, and Groovy for that specific terminal session.
* **Interactive Ecosystem Auto-Updater:** Engineered with a dynamic, vendor-sorted Updater menu that displays your active versions across JDKs and Ecosystem tools, queries GitHub/Apache APIs to resolve the absolute latest stable releases in real-time, and seamlessly prompts to upgrade any out-of-date binaries.
* **Global Command & Shell Hooks:** Features a built-in Settings menu that dynamically injects the `jvm` command into your system PATH, and can optionally install a native PowerShell Profile Hook to enable true, isolated `--session` support across multiple terminal tabs.
* **Advanced CLI Quick-Switching:** Supports intelligent argument parsing to bypass the UI entirely. If multiple vendors are installed for the same JDK version, it safely pauses to ask you which vendor you want to switch to, which can be bypassed on the fly with the `--vendor` flag.
* **Multi-Vendor API Auto-Downloader:** Connects directly to official vendor APIs (Oracle, GitHub for GraalVM, Adoptium v3, Azul, etc.) via a transparent, isolated PowerShell instance to dynamically resolve, download, and extract modern JDK versions.
* **Enterprise-Grade Security:** Enforces strict SHA256 checksum verification across all remote download pathways using native `.NET` Cryptography APIs. Validates payload integrity against official vendor signature mirrors before extraction, protecting against MITM attacks or corrupted binaries.
* **Inline Multi-Vendor Update Checker:** Dynamically generates and executes a self-contained PowerShell update script at runtime to query all six vendor APIs (Oracle, Adoptium, GraalVM, Corretto, Zulu, Microsoft) for newer builds. Compares `SEMANTIC_VERSION` and `JAVA_VERSION` strings from the local `release` file against live API responses, with automatic `-LTS` suffix normalization for Adoptium. Oracle uses a legacy `HEAD`-request date comparison against `download.oracle.com` for maximum reliability.
* **Offline-Aware Error Handling:** All network operations (downloads, update checks, API queries) are wrapped in structured error boundaries. If you are offline or an API is unreachable, the tool displays a clean `[ ERROR ] Network connection failed. You appear to be offline.` message with a `[ DETAIL ]` trace instead of crashing with raw exception dumps.
* **Dynamic Environment Switching:** Atomically updates `JAVA_HOME` and your user/system `PATH` globally while cleanly updating the environment variables of your active terminal session without spawning double paths.
* **The "Phantom Path" Killer:** Unlike other version managers that passively append to your PATH (which Windows often ignores if a hardcoded shortcut exists), JVM actively hunts down and scrubs rogue, hardcoded Oracle shortcuts (e.g., `Common Files\Oracle\Java\javapath`) that MSIs forcefully inject into the front of your `PATH`, ensuring your selected `JAVA_HOME` is always respected.
* **Bring Your Own JDK (BYO-JDK):** Have a custom JDK build or a GraalVM native-image compiler installed manually? Use `jvm link <path> [name]` to register it, and it will instantly integrate into the dynamic UI and CLI routing alongside your auto-downloaded JDKs.
* **Instant Menu Navigation:** Uses a smart `NEEDS_RESCAN` caching architecture to guarantee zero-latency navigation when moving back and forth between interactive submenus.
* **Built-in Self-Updater with Integrity Verification:** Run `jvm version` (or `-v`) to trigger the intelligent semantic versioning engine. If an update is available, `jvm self-update` securely downloads it using the Universal Downloader (with native ANSI progress bars), validates a `rem END OF SCRIPT` integrity sentinel, sanitizes UNIX line-endings (LF) and UTF-8 BOM byte leaks to prevent cmd.exe parsing crashes, and atomic-swaps the core script.
* **Native Code Page Preservation:** Built for professional environments. The tool temporarily leverages code page `65001` to perfectly render extended UTF-8 ANSI graphics and UI elements, but strictly records and restores your host's original code page upon exit, guaranteeing your terminal's character rendering is never permanently altered by a session.
* **Headless CI/CD Automation:** Every command is engineered with zero-prompt bypass flags. Run complex installations like `jvm install lts --latest --vendor oracle` or `jvm uninstall 21 --vendor adoptium` to bypass all interactive menus for frictionless integration into CI/CD pipelines, DevOps scripts, or automated machine provisioning workflows.

## 🏗️ Dual-Architecture Core (Symlink vs Legacy)

Windows Directory Junctions (Symlinks) provide a massive speed and workflow improvement because they allow the script to instantly swap your Java version without ever needing Administrator privileges (UAC). By routing your User `PATH` to a single junction (`%LOCALAPPDATA%\DiamTek\JVM\current`), 99% of modern tools (Gradle, Maven, IDEs) can natively resolve the path entirely in the background.

However, some ultra-legacy enterprise Java applications or obscure classloaders perform strict canonical path resolution that can occasionally fail to traverse Windows Directory Junctions. To ensure 100% unbreakable compatibility for all workflows, we built a **Dual-Architecture Core**.

By navigating to the **Settings** menu, users can freely toggle between:
* **[Symlink Mode]**: The default, blazing-fast, UAC-Free approach that dynamically updates a junction pointer in your user directory.
* **[Registry Mode]**: The classic, battle-tested legacy approach. The script generates an elevated background wrapper to forcefully update the system's absolute `HKLM` paths in the Windows Registry (requires a UAC prompt on switch).

> [!WARNING]
> **Architecture Conflicts:** Windows evaluates Machine (`HKLM`) paths before User (`HKCU`) paths. If you use Registry Mode (which writes to the Machine level) and later switch back to Symlink Mode (which writes to the User level), the old Machine path would normally stubbornly override your new Symlink! To prevent this, toggling back to Symlink Mode inside the Settings Menu will now automatically scrub the legacy Machine pollution for you. (Note: If you manually bypass the menu using `--legacy` and `--symlink` CLI flags and experience an override, simply run `jvm clear` to wipe the slate).

You can even override your global setting dynamically on a per-command basis using the `--symlink` or `--legacy` CLI flags (e.g., `jvm 21 --legacy`).

## ⚡ Extreme Performance & Safety

Despite being nearly 100 KB in size, the `jvm.bat` engine is mathematically optimized to bypass the notorious bottlenecks and memory leaks of standard Windows Batch scripts:
* **Zero Label-Scanning Latency:** Standard scripts suffer severe performance penalties when using `call :label` for high-frequency loops (because `cmd.exe` searches the file linearly from top to bottom). Our heaviest logic, such as the multi-vendor Semantic Bubble Sort algorithm, is written as a strictly in-memory inline array swapper, ensuring instantaneous sorting regardless of file size.
* **Leak-Proof `SETLOCAL` Boundaries:** We completely sidestepped the dreaded `Maximum setlocal recursion level reached` crash. Every single utility function explicitly pops its scope boundary back to the system using terminal `exit /b` unwinds, guaranteeing zero memory leaks across thousands of loop iterations.
* **Bulletproof Escape Boundaries:** We utilize hexadecimal parsing and dedicated PowerShell payloads (`$null`) to ensure that `cmd.exe` never accidentally swallows caret characters (`^`), exclamation marks (`!`), or spaces when resolving UAC-elevated registry wrappers in the background.
* **Quote-Safe PATH Export:** All `for /f` loops that transfer variables across `setlocal`/`endlocal` boundaries use a double-quote encapsulation strategy (`""!VAR!""` with `%%~A` stripping) to guarantee safe handling of `PATH` strings containing embedded double-quotes — a common Windows scenario that normally causes `cmd.exe` to misinterpret path segments as filenames.

## 📋 Prerequisites

* **OS:** Windows 10 or Windows 11
* **Privileges:** Standard User (UAC bypass is enabled by default via Symlink Architecture). Administrator rights are only requested if you explicitly switch to legacy Registry Mode, or during global system installations.


## 📚 Documentation

For deep technical details, CI/CD automation, and advanced usage, refer to the official documentation:
* [**Usage Guide**](docs/USAGE.md) - Semantic routing, `.java-version` isolation, BYO-JDK, and Ecosystem commands.
* [**Architecture**](docs/ARCHITECTURE.md) - Technical deep-dive into Directory Junctions and PowerShell Native execution.
* [**SDKMAN! Comparison**](docs/SDKMAN-Comparison.md) - Why this is the premier native alternative to SDKMAN! for Windows.
* [**FAQ**](docs/FAQ.md) - Common questions about UAC, global routing, and Windows Registry bridging.
* [**Changelog**](docs/CHANGELOG.md) - Detailed release history.

## 🛠️ Usage

1. Launch `jvm.bat` to open the interactive menu, or run it from any terminal.
2. Navigate to **Settings (Global Command & Setup)** to install the `jvm` global command.
3. Once installed globally, you can use the following commands from anywhere:

### ⚡ Quick-Switching (CLI)
Instantly update your `JAVA_HOME` and system PATH without opening menus. If there are duplicates, you will be prompted to pick a vendor.
* `jvm 21` — Switch to JDK 21 (Globally).
* `jvm 21 --session` — Switch to JDK 21 *locally* for the current terminal only (requires the PowerShell Profile hook to be installed).
* `jvm 21 --symlink` — Force the switch to use Symlink Mode (UAC-Free) for this command, ignoring your saved defaults.
* `jvm 21 --legacy` — Force the switch to use legacy Registry Mode (requests UAC) for this command, ignoring your saved defaults.
* `jvm 21 --vendor adoptium` — Override priority and explicitly switch to Adoptium's JDK 21.
* `jvm latest` — Dynamically switch to the absolute highest installed JDK version.
* `jvm lts` — Dynamically switch to the highest installed LTS version.
* `jvm` — If run inside a directory containing a `.java-version` file, it will silently parse it and auto-switch to that version locally for the current terminal only. If no `.java-version` file exists, it opens the main interactive terminal UI menu. *(Note: Your `.java-version` file can also contain CLI flags, such as `21 --vendor adoptium --legacy`. Make sure the version and flags are all on a single line. Architecture flags like `--legacy` will only take effect if you run `jvm --global`).*
* `jvm --global` — Parses the `.java-version` file and forces the version switch to apply globally to your system registry.

### 📥 Installations
* `jvm install` — Opens the fully interactive Installation Wizard UI.
* `jvm install 21` — Initiates the installation of JDK 21 (pauses to prompt you for your preferred Vendor).
* `jvm install 21 --vendor oracle` — Bypasses all prompts to silently download and install Oracle JDK 21.
* `jvm install lts` — Prompts you to pick an LTS version (e.g., 17, 21, 25) and then prompts you for your preferred Vendor before installing.
* `jvm install lts --latest` — Skips the version prompt (locks onto the highest available LTS) but still pauses to prompt you for a Vendor.
* `jvm install lts --latest --vendor oracle` — 100% automated headless installation of the absolute newest Oracle LTS version (bypasses all menus).
* `jvm install 17 --vendor oracle -y` — (or `--yes`) Aggressively bypasses any remaining interactive safety warnings (like Oracle's legacy version caps or "already installed" warnings) for 100% uninterrupted CI/CD automation.

### 📦 Ecosystem Build Tools (SDKMAN Parity)
JVM supports downloading, switching, and managing tools natively alongside Java. You can manage these via the command line or through the interactive **Ecosystem Management** sub-menu (Option 2 in the main UI).
* `jvm install maven latest` — Installs the absolute newest version of Maven directly from Apache.
* `jvm install gradle 8.9` — Installs a specific version of Gradle.
* `jvm kotlin 2.0.20` — Instantly switches your active `KOTLIN_HOME` (and PATH) to the specified version.
* `jvm list` — Scroll to the bottom of the list to see your installed Ecosystem tools and their currently `[ACTIVE]` versions.
* `jvm uninstall groovy 4.0.23` — Safely uninstalls the specified tool and cleanly scrubs its environment variables.

### 🔄 Updates & Uninstalls
* `jvm update` — Opens the dynamic, vendor-sorted Updater menu UI.
* `jvm update --all` — Silently checks and automatically patches all installed JDKs and Ecosystem Tools (Maven, Gradle, etc.) to their absolute newest releases.
* `jvm update --all --vendor oracle` — Silently checks and automatically patches *only* your installed Oracle JDKs (the `--all` flag is optional here).
* `jvm uninstall` — Opens the dynamic, vendor-sorted Uninstaller menu UI.
* `jvm uninstall 21` — Headless uninstallation for JDK 21. If multiple vendors are found for the same version, it safely pauses to ask you which vendor you want to remove.
* `jvm uninstall 21 --vendor oracle` — 100% headless uninstallation specifically targeting the Oracle vendor (bypasses all prompts).

### 🧹 Global Environment Management
* `jvm list` — Lists all installed JDKs with their version, vendor, path, and highlights the currently `[ACTIVE]` one.
* `jvm env` — Displays the current `JAVA_HOME` environment variable.
* `jvm clear` — Instantly wipes `JAVA_HOME` and purges Java from your PATH.
* `jvm link <path> [name]` — Manually link an existing, custom JDK directory into the manager so you can easily switch to it (e.g., `jvm link C:\my-custom-jdk my-jdk`). Linked JDKs automatically integrate into the interactive UI under the "Custom (Local Links)" vendor category.
* `jvm unlink <name>` — Removes a custom linked JDK.
* `jvm version` — Displays your current `jvm.bat` build number and compares it against the latest release on GitHub to check for updates.
* `jvm self-update` — Automatically downloads and atomic-swaps the core `jvm.bat` script if a newer version is available on GitHub.
* `jvm <semantic-alias>` — Switch to a JDK using intelligent aliases instead of exact version numbers. Examples:
  * `jvm latest` (Switches to the absolute newest JDK installed)
  * `jvm lts` (Switches to the newest Long-Term Support version installed)
  * `jvm 21` (Switches to the newest minor build of Java 21)
  * `jvm lts --vendor corretto` (Switches to the newest Amazon Corretto LTS version)

## 🎨 Interface Guide

The utility uses native ANSI terminal color formatting to protect system stability:
* 🔹 **Cyan `[ ACTION ]` / `[  INFO  ]`** — Indicates system operations, network lookups, and diagnostic information. Version numbers are highlighted in cyan for rapid scanning.
* 🔸 **Yellow `[ WARNING ]` / `[ UPDATE ]`** — Points out non-critical issues, available patches, or destructive prompts.
* 🔺 **Red `[ ERROR  ]`** — Warns of network failures, blocked file permissions, or locked folders.
* 🔹 **Green `[ACTIVE]` / `[   OK   ]`** — Highlights the JDK entry currently actively powering your terminal environment, or signifies a successful operation.
* ◽ **Gray** — Mutes absolute file paths to reduce terminal clutter.

## 🛡️ Safety Defaults

To prevent catastrophic accidental deletions on local filesystems, all critical prompts obey standard developer conventions:
* The uninstaller and update prompts use a strict `(y/N)` validation. 
* Pressing **Enter** or typing anything other than an explicit `Y`/`y` acts as an immediate safe abort.
* Custom loops trap premature `Ctrl+C` commands gracefully, and auto-close countdowns can be interrupted with any keystroke.

## 📜 Version History

* **v0.6.0 (Latest):** Migrated the entire storage architecture from the user profile to %LOCALAPPDATA%\DiamTek\JVM for enterprise-grade path compliance. Introduced a bulletproof one-liner installation script (install.ps1) for frictionless setup and automatic code sanitization. Overhauled the Self-Updater to utilize the Universal Candidate Downloader engine, granting it native ANSI progress bars. Fixed critical Windows cmd.exe UTF-8 BOM interpretation bugs and UNIX (LF) line-ending crashes (the cho bug) by enforcing explicit CRLF encoding during downloads. Added native terminal code page preservation and restoration to seamlessly handle UTF-8 rendering without corrupting the user's host environment. Hardened the Global Command installer, resolved subshell variable slicing errors, and patched multiple path-parsing faults and update-checker hangs for maximum stability.  Massive architecture overhaul. Migrated core architecture to use Directory Junctions (`%LOCALAPPDATA%\DiamTek\JVM\current`), enabling 100% UAC-free, instantaneous version switching that dynamically syncs across all open terminal windows. Built a Dual-Architecture engine, allowing users to seamlessly toggle between the new Symlink Mode and the legacy Registry Mode directly from the Settings Menu. Re-engineered legacy Registry Mode to utilize background PowerShell wrappers, fixing a major historical bug where switching versions would fail silently for non-Admin users. Introduced dynamic Vendor grouping (Oracle, Adoptium, GraalVM, Corretto, Zulu, Microsoft) across all menus. Built an optimized, strictly in-memory Bubble Sort algorithm to organize JDKs by newest version. Added `.java-version` and `.sdkmanrc` directory-based auto-switching (defaults to session-mode isolation) with an explicit `--global` CLI override flag, support for passing full CLI flags directly inside `.java-version`, and a native `.sdkmanrc` parser to dynamically hijack cross-platform SDKMAN workflows with True Session Isolation across all ecosystem tools. Built a Universal Candidate Engine to natively support the JVM Ecosystem (Maven, Gradle, Kotlin, Scala, Groovy), downloading, extracting, and symlinking binaries with inline progress bars and dynamic SHA256/SHA512 validation (with automatic SHA1 fallback for older Maven legacy endpoints). Consolidated the Main Menu into two unified "JDK Management" and "Ecosystem Management" sub-hubs, each mirroring the same "Switch Active" / "Version Management" architecture. Engineered an interactive Ecosystem Auto-Updater with a vendor-selection menu that displays active versions, lets the user check individual tools or all at once, resolves the absolute latest releases from GitHub/Apache APIs, and seamlessly prompts to upgrade out-of-date binaries. Replaced duplicated code in UpdateJDKs and UninstallJDK with a shared generic vendor menu builder for massive code reduction. Enforced consistent, unified UI layouts (`--- Manage by Vendor/Tool ---` and `--- Actions ---`) across all JDK and Ecosystem menus. Fixed the notorious Windows `setx` 1024-character PATH truncation bug by completely replacing all environment variable updates with infinite-length `.NET` API calls. Implemented enterprise-grade SHA256 checksum verification for all JDK downloads using native `.NET` Cryptography APIs to protect against corrupted payloads. Added semantic CLI routing (`jvm latest`, `jvm lts`) and flag overrides (`--symlink`, `--legacy`, `--vendor`, `--latest`, `-y`). Added ARM64/AArch64 hardware auto-detection, routing all vendor API queries to architecture-specific download endpoints. Built a dynamic `FetchLatestVersions` resolver that queries the Adoptium API at runtime to resolve the true latest feature release and LTS version numbers, eliminating hardcoded version constants. Re-engineered the `UpdateChecker` as a fully self-contained inline PowerShell script generated at runtime for all six vendors, removing all external `.ps1` file dependencies. Added structured offline-aware error handling across all network operations with clean `[ ERROR ]` / `[ DETAIL ]` output instead of raw exception dumps. Eliminated hardcoded UI prioritization in favor of interactive vendor-selection prompts. Restored native extraction progress bars (with a forced final 100% frame to fix a rounding edge case) and stabilized interactive installer UI layout. Improved navigation speed via a smart caching `NEEDS_RESCAN` architecture. Fixed cross-architecture registry conflicts between User and Machine environment variables. Fixed UAC elevation deadlocks, delayed expansion engine parsing bugs affecting the `--global` flag and exclamation marks, character-encoding path bugs for user profiles, and critical bugs that corrupted paths containing exclamation marks (`!`). Fixed Oracle update checks crashing with `'$' is not recognized` by switching the PowerShell payload to pipe-safe string concatenation. Replaced deprecated `wmic` environment queries with direct `reg query` calls for forward compatibility with Windows 11. Hardened all `for /f` variable export loops with double-quote encapsulation to prevent `cmd.exe` from misinterpreting `PATH` strings containing embedded quotes as file lists. Added conditional `rmdir` guard to prevent extracted files from being destroyed on move failure. Added a `rem END OF SCRIPT` sentinel integrity check to the self-updater to reject truncated or corrupted downloads. Aligned all UI tags to a strict 10-character padded format. Built a seamless semantic self-updater engine (`jvm version`, `jvm self-update`) that securely compares build numbers using the native `.NET` `[version]` class before automatically downloading and atomic-swapping the core script. Patched a variable state-leak during cross-menu navigation and stabilized the back-navigation structural loop across all interactive UI hubs.
* **v0.5.0:** Introduced CLI Quick-Switching (`jvm <version>`) for silent background execution. Added Global Command Installer (Settings menu). Overhauled UI with strict ANSI color hierarchy, path muting, and interruptible auto-close countdowns. Hardened UAC elevation and menu scanning against Windows PATH corruption bugs.
* **v0.4.0:** Re-engineered dynamic auto-scanner supporting developer toolkits (Scoop, Gradle, IntelliJ), fast release-file parsing, and a massive architectural UI overhaul for robust sub-menu navigation.
* **v0.3.0:** Relicensed the project to the GNU Affero General Public License v3.0 (AGPL-3.0).
* **v0.2.0:** Added intelligent update checker (via HTTP `HEAD` requests), "Update All" bulk-patching, and automated directory hot-swapping.
* **v0.1.1:** Patched `PATH` variable corruption bugs and improved delayed-expansion safety protocols during active session switching.
* **v0.1.0:** Initial Release.

## 📄 License
Copyright (c) 2026 DiamTek / Alexéy Shishkin.

This project is licensed under the [GNU Affero General Public License v3.0 (AGPL-3.0)](https://www.gnu.org/licenses/agpl-3.0.html). See the LICENSE file for details.

*Note: Oracle JDK downloads triggered by this tool are subject to the [Oracle No-Fee Terms and Conditions (NFTC)](https://www.oracle.com/downloads/licenses/no-fee-license.html).*