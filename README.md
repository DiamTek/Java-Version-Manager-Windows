# Java Version Manager (JVM)

A lightweight, high-performance, color-coded Windows Batch utility designed to dynamically discover, switch, download, update, and clean up Java Development Kit (JDK) environments without system bloat.

## 🚀 Features

* **Dynamic JDK Scanning:** Automatically discovers installed JDK instances across multiple common system directories (`C:\Program Files\Java`, `C:\Java`, etc.) and builds a smart menu on the fly. No hardcoded versions.
* **Oracle JDK Auto-Downloader:** Connects directly to official Oracle infrastructure via a transparent, isolated PowerShell instance to pull down and extract any modern major JDK version (17, 21, 25, 26, etc.).
* **Intelligent Update Checker:** Queries official Oracle servers via high-speed HTTP `HEAD` requests to compare remote build dates against your local `release` file metadata. Automatically downloads, hot-swaps directories, and patches environment variables in-place if a newer build is found.
* **Dynamic Environment Switching:** Atomically updates `JAVA_HOME` and your user/system `PATH` globally while cleanly updating the environment variables of your active terminal session without spawning double paths.
* **The "Phantom Path" Killer:** Actively hunts down and scrubs rogue, hardcoded Oracle shortcuts (e.g., `Common Files\Oracle\Java\javapath`) that installers forcefully inject into the front of your `PATH`, ensuring `JAVA_HOME` is always respected.
* **Surgical Uninstaller:** Safely terminates lingering background `java.exe`/`javaw.exe` processes, deletes the target directory, and scrubs any traces of that specific version from your registry and environment tables.
* **Optimized Elevation & Interface:** Features an instantaneous, high-reliability `net session` Admin privilege check with zero UAC folder drift. Built using high-performance, instant-response key interception (`choice.exe`) and ANSI color coding.

## 📋 Prerequisites

* **OS:** Windows 10 or Windows 11
* **Privileges:** Administrator rights are required to modify system-level environment variables and registry strings. (The script will automatically request elevation via a optimized UAC pop-up if launched unprivileged).

## 🛠️ Usage

1. Copy the script code into a file named `jvm.bat` or `manager.bat`.
2. Right-click the file and select **Run as administrator** (or simply launch it normally and accept the UAC prompt).
3. Interact with the menu using your number keys:
   * **Numbers `1` through `X`:** Instantly sets your active `JAVA_HOME` to that directory.
   * **Latest JDK Shortcut:** Quickly fast-forwards your system configuration to the highest version number found on your machine.
   * **Check for Updates:** Bulk-scans all installed JDKs (or an individual version) against Oracle's servers to automatically fetch and install the latest security patches and minor builds.
   * **Download/Install:** Installs a brand new major version directly from Oracle to `C:\Program Files\Java`.
   * **Uninstall:** Safely and completely removes a JDK environment and scrubs lingering system paths.

## 🎨 Interface Guide

The utility uses native ANSI terminal color formatting to protect system stability:
* 🔹 **Cyan `[ ACTION ]` / `[  INFO  ]`** — Indicates system operations, network lookups, and diagnostic information.
* 🔸 **Yellow `[ WARNING ]` / `[ UPDATE ]`** — Points out non-critical issues, available patches, or destructive prompts.
* 🔺 **Red `[ ERROR  ]`** — Warns of network failures, blocked file permissions, or locked folders.
* 🔹 **Green `[ACTIVE]` / `[   OK   ]`** — Highlights the JDK entry currently actively powering your terminal environment, or signifies a successful operation.

## 🛡️ Safety Defaults

To prevent catastrophic accidental deletions on local filesystems, all critical prompts obey standard developer conventions:
* The uninstaller and update prompts use a strict `(y/N)` validation. 
* Pressing **Enter** or typing anything other than an explicit `Y`/`y` acts as an immediate safe abort.
* Custom loops trap premature `Ctrl+C` commands gracefully without throwing broken system syntax messages or dropping terminal sessions.

## 📜 Version History

* **v0.3.0 (Latest):** Relicensed the project to the GNU Affero General Public License v3.0 (AGPL-3.0).
* **v0.2.0:** Added intelligent update checker (via HTTP `HEAD` requests), "Update All" bulk-patching, and automated directory hot-swapping.
* **v0.1.1:** Patched `PATH` variable corruption bugs and improved delayed-expansion safety protocols during active session switching.
* **v0.1.0:** Initial Release (Dynamic scanning, Oracle downloader, Phantom Path cleaner, and surgical uninstaller).

## 📄 License
Copyright © 2026 DiamTek / Alexéy Shishkin.

This project is licensed under the [GNU Affero General Public License v3.0 (AGPL-3.0)](https://www.gnu.org/licenses/agpl-3.0.html). See the LICENSE file for details.

*Note: Oracle JDK downloads triggered by this tool are subject to the [Oracle No-Fee Terms and Conditions (NFTC)](https://www.oracle.com/downloads/licenses/no-fee-license.html).*