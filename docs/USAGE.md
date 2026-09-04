# Usage Guide

The Java Version Manager for Windows is designed to accommodate both casual developers and hardcore CI/CD engineers. It acts as both a visually guided **Interactive TUI (Terminal User Interface)** and a deeply powerful, highly-configurable **Headless CLI**.

This document outlines every command, flag override, and semantic route available in the engine.

---

## 🖥️ Interactive UI Mode

For the easiest, most visually appealing experience, you can rely entirely on the interactive menus.

To launch the main hub, simply run the tool from any terminal without arguments:
```cmd
jvm
```
From here, you can visually explore installed JDKs, fetch new versions, manage ecosystem tools, and change global settings.

**Initial Setup Note:**
If you have just downloaded the script manually, navigate to **Settings (Global Command & Setup)** (Option `3`) and select **Install Global Command** (Option `1`). Once installed globally, you can use the `jvm` command from anywhere on your system.

---

## ⚡ Quick-Switching (CLI)

You do not need to open the menu to change your active Java version. You can instantly update your `JAVA_HOME` and system `PATH` directly from the command line.

### Basic Switching
Switch to a specific version globally:
```cmd
jvm 21
```
*Note: If there are multiple vendors installed for JDK 21 (e.g., Oracle and Adoptium), the engine will safely pause and prompt you to pick a vendor.*

### Semantic Target Routing
You don't need to memorize exact build numbers. You can speak to the tool semantically, and it will dynamically resolve the highest installed version that matches your request:
```cmd
jvm latest
jvm lts
```

### Architecture & Priority Overrides
You can chain flags to bypass prompts or override your global Settings for a single command.

Override the vendor prompt to silently select Adoptium:
```cmd
jvm 21 --vendor adoptium
```
Force the engine to use **Symlink Mode** (UAC-Free Directory Junctions) for this specific switch, ignoring your saved default architecture:
```cmd
jvm 21 --symlink
```
Force the engine to use **Legacy Registry Mode** (Requests Administrator UAC elevation) for this specific switch:
```cmd
jvm 21 --legacy
```
Semantic routing combined with a vendor override (switches to the newest installed Amazon Corretto LTS version):
```cmd
jvm lts --vendor corretto
```

### True Session Isolation
If you only want to change the Java version for your *current* terminal window (without permanently altering your global Windows Registry or affecting background services), use the session flag:
```cmd
jvm 21 --session
```
*(Note: This feature requires the PowerShell Profile hook to be installed via the Settings menu).*

---

## 📥 Headless Installations

The installation engine supports deep headless automation, allowing you to bypass menus incrementally—perfect for DevOps scripts and automated machine provisioning.

### Interactive Installation
Open the Installation Wizard UI:
```cmd
jvm install
```

### Semi-Automated Installation
Initiate the installation of JDK 21 (the engine will pause to prompt you for your preferred Vendor):
```cmd
jvm install 21
```
Prompts you to pick an LTS version (e.g., 17, 21, 25) and then prompts you for your preferred Vendor:
```cmd
jvm install lts
```
Locks onto the highest available LTS version, but still pauses to ask which Vendor you want:
```cmd
jvm install lts --latest
```

### 100% Fully Automated (CI/CD)
Bypass all prompts to silently download and install Oracle JDK 21:
```cmd
jvm install 21 --vendor oracle
```
Silently resolve, download, and install the absolute newest Oracle LTS version without a single prompt:
```cmd
jvm install lts --latest --vendor oracle
```
**The Aggressive Override (`-y` / `--yes`)**
If you are running in a strict CI/CD pipeline, you can pass `-y` to aggressively bypass any remaining interactive safety warnings (such as Oracle's legacy version caps, or "already installed" overwrite warnings) for 100% uninterrupted automation:
```cmd
jvm install 17 --vendor oracle -y
```

---

## 📦 Ecosystem Build Tools (SDKMAN! Parity)

JVM supports downloading, switching, and managing modern build tools natively alongside Java. You can manage these via the command line or through the interactive **Ecosystem Management** sub-menu.

Install the absolute newest version of Maven directly from Apache:
```cmd
jvm install maven latest
```
Install a specific legacy version of Gradle:
```cmd
jvm install gradle 8.9
```
Instantly switch your active `KOTLIN_HOME` (and system PATH) to the specified version:
```cmd
jvm kotlin 2.0.20
```
Safely uninstall a specific tool and cleanly scrub its environment variables from your registry:
```cmd
jvm uninstall groovy 4.0.23
```

---

## 🔄 Updates & Uninstalls

### Updating Tools
Open the dynamic, vendor-sorted Updater menu UI:
```cmd
jvm update
```
**Bulk Updating:** Silently check and automatically patch *all* installed JDKs and Ecosystem Tools (Maven, Gradle, etc.) to their absolute newest releases:
```cmd
jvm update --all
```
Silently check and automatically patch *only* your installed Oracle JDKs:
```cmd
jvm update --all --vendor oracle
```

### Uninstalling Tools
Open the dynamic, vendor-sorted Uninstaller menu UI:
```cmd
jvm uninstall
```
Headless uninstallation for JDK 21. If multiple vendors are found for the same version, it safely pauses to ask you which vendor you want to remove:
```cmd
jvm uninstall 21
```
100% headless uninstallation specifically targeting the Oracle vendor (bypasses all prompts):
```cmd
jvm uninstall 21 --vendor oracle
```

---

## 📂 Directory-Based Auto-Switching

Instantly configure a project's required environment by simply running the tool inside any directory containing a `.java-version` or SDKMAN `.sdkmanrc` file.

Silently parse the file and auto-switch to that version **locally** for the current terminal only:
```cmd
jvm
```
Parse the file and force the version switch to apply **globally** to your system registry:
```cmd
jvm --global
```

### Syntax: `.java-version`
Your `.java-version` file can specify a standard build number:
```text
21
```
It can also contain advanced inline CLI flags to lock specific vendors or architecture modes on a strict per-project basis. Make sure the version and flags are all on a single line:
```text
21 --vendor adoptium --legacy
```

### Syntax: `.sdkmanrc` (Hijacking)
If you are collaborating with developers on Linux/macOS, this tool natively reads their `.sdkmanrc` files. It dynamically maps SDKMAN vendor strings (like `17-tem` or `21-amzn`) to your native Windows JDKs and isolates all required ecosystem tools for that session.
```properties
java=21-tem
maven=3.9.6
gradle=8.5
kotlin=1.9.22
```

---

## 🧹 Global Environment Management

### Inspection Commands
List all installed JDKs with their version, vendor, and path. The currently active JDK is highlighted with `[ACTIVE]`. (Scroll to the bottom to see installed Ecosystem tools).
```cmd
jvm list
```
Display the exact path your current `JAVA_HOME` environment variable is pointing to:
```cmd
jvm env
```

### System Scrubbing
Instantly wipe `JAVA_HOME` and purge Java from your Windows PATH entirely:
```cmd
jvm clear
```

### Bring Your Own JDK (BYO-JDK)
Manually link an existing, custom JDK directory (or GraalVM native image) into the manager. Linked JDKs automatically integrate into the interactive UI under the "Custom (Local Links)" category:
```cmd
jvm link C:\my-custom-jdk my-jdk
```
Remove a custom linked JDK from the manager:
```cmd
jvm unlink my-jdk
```

### Self-Updating
Display your current `jvm.bat` build number and compare it against the latest release on GitHub to check for engine updates:
```cmd
jvm version
```
Automatically download and atomic-swap the core `jvm.bat` script if a newer version is available on GitHub:
```cmd
jvm self-update
```