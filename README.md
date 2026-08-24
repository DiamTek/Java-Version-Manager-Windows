# Java Version Manager (JVM)

A lightweight, high-performance, color-coded Windows Batch utility designed to dynamically discover, switch, download, update, and clean up Java Development Kit (JDK) environments without system bloat.

## 🚀 Features

* **Dynamic Vendor Architecture:** Menus are dynamically grouped and filtered by vendor (Oracle, Adoptium, GraalVM) to keep your workspace clean and organized.
* **Intelligent Background Sorting:** Features a built-in, stable bubble-sort algorithm that organizes all discovered JDKs by their major version in descending order, ensuring your newest installations are always at the top of the list.
* **Semantic Target Routing:** Speak to the tool in human terms. Automatically jump to or install the latest available JDK using targets like `jvm latest` or `jvm lts`.
* **Directory-based Auto-Switching:** Instantly switch to a project's required JDK version by simply running `jvm` inside any directory containing a `.java-version` file. The tool parses the file and seamlessly swaps your environment in the background.
* **Global Command & Shell Hooks:** Features a built-in Settings menu that dynamically injects the `jvm` command into your system PATH, and can optionally install a native PowerShell Profile Hook to enable true, isolated `--session` support across multiple terminal tabs.
* **Advanced CLI Quick-Switching:** Supports intelligent argument parsing to bypass the UI entirely. Quick-switching implicitly prioritizes Oracle > Adoptium > GraalVM for conflict resolution, which can be overridden on the fly with the `--vendor` flag.
* **Oracle JDK Auto-Downloader:** Connects directly to official Oracle infrastructure via a transparent, isolated PowerShell instance to pull down and extract modern JDK versions (17, 21, 25, 26, etc.).
* **Enterprise-Grade Security:** Enforces strict SHA256 checksum verification across all remote download pathways using native `.NET` Cryptography APIs. Validates payload integrity against official Oracle signature mirrors before extraction, protecting against MITM attacks or corrupted binaries.
* **Intelligent Update Checker:** Queries official Oracle servers via high-speed HTTP `HEAD` requests to compare remote build dates against your local `release` file metadata. Automatically downloads, hot-swaps directories, and patches environment variables in-place if a newer build is found.
* **Dynamic Environment Switching:** Atomically updates `JAVA_HOME` and your user/system `PATH` globally while cleanly updating the environment variables of your active terminal session without spawning double paths.
* **The "Phantom Path" Killer:** Actively hunts down and scrubs rogue, hardcoded Oracle shortcuts (e.g., `Common Files\Oracle\Java\javapath`) that installers forcefully inject into the front of your `PATH`, ensuring `JAVA_HOME` is always respected.
* **Instant Menu Navigation:** Uses a smart `NEEDS_RESCAN` caching architecture to guarantee zero-latency navigation when moving back and forth between interactive submenus.

## 📋 Prerequisites

* **OS:** Windows 10 or Windows 11
* **Privileges:** Administrator rights are required to modify system-level environment variables and registry strings. (The script will automatically request elevation via an optimized UAC pop-up if launched unprivileged).

## 🛠️ Usage

1. Launch `jvm.bat` to open the interactive menu, or run it from any terminal.
2. Navigate to **Settings (Global Command & Setup)** to install the `jvm` global command.
3. Once installed globally, you can use the following commands from anywhere:

### ⚡ Quick-Switching (CLI)
Instantly update your `JAVA_HOME` and system PATH without opening menus. Priority defaults to Oracle > Adoptium > GraalVM for duplicate versions.
* `jvm 21` — Switch to JDK 21 (Globally).
* `jvm 21 --session` — Switch to JDK 21 *locally* for the current terminal only (requires the PowerShell Profile hook to be installed).
* `jvm 21 --vendor adoptium` — Override priority and explicitly switch to Adoptium's JDK 21.
* `jvm latest` — Dynamically switch to the absolute highest installed JDK version.
* `jvm lts` — Dynamically switch to the highest installed LTS version.
* `jvm` — If run inside a directory containing a `.java-version` file, it will silently parse it and auto-switch to that version locally for the current terminal only. If no `.java-version` file exists, it opens the main interactive terminal UI menu.
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
* `jvm link` / `jvm unlink` — Injects or removes the `jvm` global command from your system PATH.

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

* **v0.6.0 (Latest):** Massive architecture overhaul. Introduced dynamic Vendor grouping (Oracle, Adoptium, GraalVM) across all menus. Built an optimized, strictly in-memory Bubble Sort algorithm to organize JDKs by newest version. Added `.java-version` directory-based auto-switching (defaults to session-mode isolation) with an explicit `--global` CLI override flag. Implemented enterprise-grade SHA256 checksum verification for all JDK downloads using native `.NET` Cryptography APIs to protect against corrupted payloads. Added semantic CLI routing (`jvm latest`, `jvm lts`) and flag overrides (`--vendor`, `--latest`, `-y`). Improved navigation speed via a smart caching `NEEDS_RESCAN` architecture. Fixed UAC elevation deadlocks, character-encoding path bugs for user profiles, and critical engine parsing bugs that corrupted paths containing exclamation marks (`!`).
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