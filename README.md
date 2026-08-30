# Java Version Manager (JVM)

A lightweight, high-performance, color-coded Windows Batch utility designed to dynamically discover, switch, download, update, and clean up Java Development Kit (JDK) environments without system bloat.

## 🚀 Features

* **Dynamic Vendor Architecture:** Menus are dynamically grouped and filtered by vendor (Oracle, Adoptium, GraalVM, Corretto, Zulu, Microsoft) to keep your workspace clean and organized.
* **Intelligent Background Sorting:** Features a built-in, stable bubble-sort algorithm that organizes all discovered JDKs by their major version in descending order, ensuring your newest installations are always at the top of the list.
* **Semantic Target Routing:** Speak to the tool in human terms. Automatically jump to or install the latest available JDK using targets like `jvm latest` or `jvm lts`.
* **Dual-Architecture Core (UAC-Free vs Registry):** Toggle seamlessly between lightning-fast **Symlink Mode** (bypasses UAC completely using a Directory Junction at `%USERPROFILE%\.jvm\current`) and legacy **Registry Mode** (auto-elevating background scripts to update system `HKLM` environment variables) based on your system compatibility needs.
* **Directory-based Auto-Switching:** Instantly switch to a project's required JDK version by simply running `jvm` inside any directory containing a `.java-version` file. The tool parses the file and seamlessly swaps your environment in the background.
* **Global Command & Shell Hooks:** Features a built-in Settings menu that dynamically injects the `jvm` command into your system PATH, and can optionally install a native PowerShell Profile Hook to enable true, isolated `--session` support across multiple terminal tabs.
* **Advanced CLI Quick-Switching:** Supports intelligent argument parsing to bypass the UI entirely. If multiple vendors are installed for the same JDK version, it safely pauses to ask you which vendor you want to switch to, which can be bypassed on the fly with the `--vendor` flag.
* **Multi-Vendor API Auto-Downloader:** Connects directly to official vendor APIs (Oracle, GitHub for GraalVM, Adoptium v3, Azul, etc.) via a transparent, isolated PowerShell instance to dynamically resolve, download, and extract modern JDK versions.
* **Enterprise-Grade Security:** Enforces strict SHA256 checksum verification across all remote download pathways using native `.NET` Cryptography APIs. Validates payload integrity against official vendor signature mirrors before extraction, protecting against MITM attacks or corrupted binaries.
* **Intelligent Update Checker:** Queries official Oracle servers via high-speed HTTP `HEAD` requests to compare remote build dates against your local `release` file metadata. Automatically downloads, hot-swaps directories, and patches environment variables in-place if a newer build is found.
* **Dynamic Environment Switching:** Atomically updates `JAVA_HOME` and your user/system `PATH` globally while cleanly updating the environment variables of your active terminal session without spawning double paths.
* **The "Phantom Path" Killer:** Actively hunts down and scrubs rogue, hardcoded Oracle shortcuts (e.g., `Common Files\Oracle\Java\javapath`) that installers forcefully inject into the front of your `PATH`, ensuring `JAVA_HOME` is always respected.
* **Instant Menu Navigation:** Uses a smart `NEEDS_RESCAN` caching architecture to guarantee zero-latency navigation when moving back and forth between interactive submenus.
* **Built-in Self-Updater:** Run `jvm version` (or `-v`) to trigger the intelligent semantic versioning engine. It securely mathematically compares your local build against the remote GitHub `main` branch (e.g. `20260830.10` > `20260830.2`). If an update is available, `jvm self-update` will atomic-swap the core script in the background and seamlessly bounce you back into the menu.

## 🏗️ Dual-Architecture Core (Symlink vs Legacy)

Windows Directory Junctions (Symlinks) provide a massive speed and workflow improvement because they allow the script to instantly swap your Java version without ever needing Administrator privileges (UAC). By routing your User `PATH` to a single junction (`%USERPROFILE%\.jvm\current`), 99% of modern tools (Gradle, Maven, IDEs) can natively resolve the path entirely in the background.

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

## 📋 Prerequisites

* **OS:** Windows 10 or Windows 11
* **Privileges:** Standard User (UAC bypass is enabled by default via Symlink Architecture). Administrator rights are only requested if you explicitly switch to legacy Registry Mode, or during global system installations.

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
* `jvm install 17 --vendor oracle -y` — (or `--yes`) Aggressively bypasses any remaining interactive safety warnings (like Oracle's legacy version caps) for 100% uninterrupted CI/CD automation.

### 🔄 Updates & Uninstalls
* `jvm update` — Opens the dynamic, vendor-sorted Updater menu UI.
* `jvm update --all` — Silently checks and automatically patches all installed JDKs across all vendors.
* `jvm update --all --vendor oracle` — Silently checks and automatically patches *only* your installed Oracle JDKs (the `--all` flag is optional here).
* `jvm uninstall` — Opens the dynamic, vendor-sorted Uninstaller menu UI.
* `jvm uninstall 21` — Headless uninstallation for JDK 21. If multiple vendors are found for the same version, it safely pauses to ask you which vendor you want to remove.
* `jvm uninstall 21 --vendor oracle` — 100% headless uninstallation specifically targeting the Oracle vendor (bypasses all prompts).

### 🧹 Global Environment Management
* `jvm clear` — Instantly wipes `JAVA_HOME` and purges Java from your PATH.
* `jvm link <path> [name]` — Manually link an existing, custom JDK directory into the manager so you can easily switch to it (e.g., `jvm link C:\my-custom-jdk my-jdk`).
* `jvm unlink <name>` — Removes a custom linked JDK.
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

* **v0.6.0 (Latest):** Massive architecture overhaul. Migrated core architecture to use Directory Junctions (`%USERPROFILE%\.jvm\current`), enabling 100% UAC-free, instantaneous version switching that dynamically syncs across all open terminal windows. Built a Dual-Architecture engine, allowing users to seamlessly toggle between the new Symlink Mode and the legacy Registry Mode directly from the Settings Menu. Re-engineered legacy Registry Mode to utilize background PowerShell wrappers, fixing a major historical bug where switching versions would fail silently for non-Admin users. Introduced dynamic Vendor grouping (Oracle, Adoptium, GraalVM, Corretto, Zulu, Microsoft) across all menus. Built an optimized, strictly in-memory Bubble Sort algorithm to organize JDKs by newest version. Added `.java-version` directory-based auto-switching (defaults to session-mode isolation) with an explicit `--global` CLI override flag, and support for passing full CLI flags (e.g., `--vendor`, `--legacy`) directly inside the file. Implemented enterprise-grade SHA256 checksum verification for all JDK downloads using native `.NET` Cryptography APIs to protect against corrupted payloads. Added semantic CLI routing (`jvm latest`, `jvm lts`) and flag overrides (`--symlink`, `--legacy`, `--vendor`, `--latest`, `-y`). Eliminated hardcoded UI prioritization in favor of interactive vendor-selection prompts. Re-engineered `UpdateChecker` for robust multi-vendor version parsing. Restored native extraction progress bars and stabilized interactive installer UI layout. Improved navigation speed via a smart caching `NEEDS_RESCAN` architecture. Fixed cross-architecture registry conflicts between User and Machine environment variables. Fixed UAC elevation deadlocks, delayed expansion engine parsing bugs affecting the `--global` flag and exclamation marks, character-encoding path bugs for user profiles, and critical bugs that corrupted paths containing exclamation marks (`!`). Built a seamless semantic self-updater engine (`jvm version`, `jvm self-update`) that securely compares build numbers using the native `.NET` `[version]` class before automatically downloading and atomic-swapping the core script.
* **v0.5.0:** Introduced CLI Quick-Switching (`jvm <version>`) for silent background execution. Added Global Command Installer (Settings menu). Overhauled UI with strict ANSI color hierarchy, path muting, and interruptible auto-close countdowns. Hardened UAC elevation and menu scanning against Windows PATH corruption bugs.
* **v0.4.0:** Re-engineered dynamic auto-scanner supporting developer toolkits (Scoop, Gradle, IntelliJ), fast release-file parsing, and a massive architectural UI overhaul for robust sub-menu navigation.
* **v0.3.0:** Relicensed the project to the GNU Affero General Public License v3.0 (AGPL-3.0).
* **v0.2.0:** Added intelligent update checker (via HTTP `HEAD` requests), "Update All" bulk-patching, and automated directory hot-swapping.
* **v0.1.1:** Patched `PATH` variable corruption bugs and improved delayed-expansion safety protocols during active session switching.
* **v0.1.0:** Initial Release.

## 📄 License
Copyright © 2026 DiamTek / Alexéy Shishkin.

This project is licensed under the [GNU Affero General Public License v3.0 (AGPL-3.0)](https://www.gnu.org/licenses/agpl-3.0.html). See the LICENSE file for details.

*Note: Oracle JDK downloads triggered by this tool are subject to the [Oracle No-Fee Terms and Conditions (NFTC)](https://www.oracle.com/downloads/licenses/no-fee-license.html).*