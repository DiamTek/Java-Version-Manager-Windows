# Usage Guide

<p align="center" markdown="1">
  [🏠 Overview](../README.md) &nbsp;•&nbsp;
  [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp;
  [📖 Usage](USAGE.md) &nbsp;•&nbsp;
  [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp;
  [❓ FAQ](FAQ.md) &nbsp;•&nbsp;
  [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp;
  [📜 Changelog](CHANGELOG.md)
</p>

---

The Java Version Manager for Windows is designed to accommodate both casual developers and hardcore CI/CD engineers. It acts as both a visually guided **Interactive TUI (Terminal User Interface)** and a deeply powerful, highly-configurable **Headless CLI**.

This document outlines every command, flag override, and semantic route available in the engine.

### 🔍 Quick Jump
- [Interactive UI Mode](#interactive-ui-mode)
- [Command Reference Cheat Sheet](#command-reference-cheat-sheet)
- [Quick-Switching (CLI)](#quick-switching-cli)
- [Headless Installations](#headless-installations)
- [Universal Candidate Engine (Ecosystem Tools)](#universal-candidate-engine-ecosystem-tools)
- [Updates & Uninstalls](#updates--uninstalls)
- [Directory-Based Auto-Switching (.java-version & .sdkmanrc)](#directory-based-auto-switching)
- [IDE & Build Tool Integration](#ide--build-tool-integration)
- [Bring Your Own JDK (jvm link)](#bring-your-own-jdk-byo-jdk)
- [Global Environment Management](#global-environment-management)

---

<a id="interactive-ui-mode"></a>
## 🖥️ Interactive UI Mode

For the easiest, most visually appealing experience, you can rely entirely on the interactive menus.

To launch the main hub, simply run the tool from any terminal without arguments:
```cmd
jvm
```
You can also launch it directly from:
- **Windows Terminal**: Click the `+` dropdown menu and select **Java Version Manager**.
- **Start Menu**: Search for **Java Version Manager** and press Enter.
- **Taskbar**: Click the pinned DiamTek JVM icon.

From here, you can visually explore installed JDKs, fetch new versions, manage ecosystem tools, and change global settings. Exiting the menu automatically closes the dedicated terminal tab.

**Initial Setup Note:**
If you have just downloaded the script manually, navigate to **Settings (Global Command & Setup)** (Option `3`) and select **Install Global Command** (Option `1`). Once installed globally, you can use the `jvm` command from anywhere on your system.

<a id="command-reference-cheat-sheet"></a>
## 📋 Command Reference Cheat Sheet

| Command Syntax | Scope | Description |
|----------------|-------|-------------|
| `jvm` | Interactive / Session | Launches interactive menu, or auto-switches if `.java-version` / `.sdkmanrc` is present. |
| `jvm <version>` | Global | Switches to specified JDK version (e.g., `jvm 21`, `jvm 17.0.10`). |
| `jvm <version> --session` | Session | Switches JDK for the current terminal only without touching the Windows Registry. |
| `jvm <version> --vendor <name>` | Global | Switches JDK with explicit vendor selection (e.g., `adoptium`, `oracle`, `corretto`). |
| `jvm <version> --symlink` | Global | Forces switch using Symlink Mode (NTFS Directory Junction, UAC-Free). |
| `jvm <version> --legacy` | Machine | Forces switch using Registry Mode (writes to `HKLM`, requests UAC elevation). |
| `jvm latest` | Global | Resolves and switches to the highest installed JDK version on your machine. |
| `jvm lts` | Global | Resolves and switches to the highest installed LTS version (e.g., 21, 17, 11). |
| `jvm --global` | Global | Forces directory-based auto-switching (`.java-version`) to write globally to registry. |
| `jvm install` | Interactive | Opens the interactive JDK / tool installation wizard. |
| `jvm install <ver> [--vendor <name>]` | Machine | Downloads and installs specified JDK (e.g., `jvm install 21 --vendor adoptium`). |
| `jvm install lts [--latest]` | Machine | Downloads newest LTS JDK release directly from vendor APIs. |
| `jvm install <ver> -y` | Machine | Automated headless install with aggressive safety warning bypass for CI/CD. |
| `jvm install <ver> --skip-checksum` | Machine | Bypasses checksum verification if vendor hash mirror is unreachable. |
| `jvm install <tool> [version]` | User | Installs ecosystem tool (e.g., `jvm install maven latest`, `jvm install gradle 8.9`). |
| `jvm <tool> <version>` | User | Switches active ecosystem tool version (e.g., `jvm kotlin 2.0.20`, `jvm maven 3.9.6`). |
| `jvm update` | Interactive | Opens the vendor-sorted update checker and patch menu. |
| `jvm update --all [--vendor <name>]` | Machine | Silently checks and patches all installed JDKs and tools to latest releases. |
| `jvm uninstall [version]` | Machine | Opens uninstaller menu or uninstalls specified version (e.g., `jvm uninstall 21`). |
| `jvm list` | Inspection | Lists all installed JDKs, vendors, paths, and ecosystem build tools. |
| `jvm env` | Inspection | Prints active `JAVA_HOME` path and directory junction status. |
| `jvm link <path> <name>` | Custom | Registers an external or custom JDK (BYO-JDK / GraalVM) into the manager. |
| `jvm unlink <name>` | Custom | Unregisters a custom linked JDK from the manager. |
| `jvm clear` | System | Purges `JAVA_HOME` and cleanly removes JVM directory junctions from PATH. |
| `jvm version` | Tool | Displays current JVM version, build number, and checks GitHub for updates. |
| `jvm self-update` | Tool | Automatically downloads and atomic-swaps `jvm.bat` to the latest release. |
| `jvm self-uninstall` | System | Triggers deep UAC-elevated system uninstaller (`uninstall.ps1`). |
| `jvm --help` | Help | Displays formatted in-terminal command manual and flag reference (`-h`, `/?`). |

---

<a id="quick-switching-cli"></a>
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

<a id="headless-installations"></a>
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

**Bypassing Checksum Verification (`--skip-checksum` / `--no-verify`)**
If you are operating in an air-gapped environment or a vendor's checksum endpoint is transiently unreachable, pass `--skip-checksum` (or `--no-verify`) to proceed with extraction if the hash cannot be resolved:
```cmd
jvm install 21 --vendor adoptium --skip-checksum
```
*(Note: `--yes` / `-y` only suppresses interactive confirmation prompts and does not disable checksum verification).*

---

<a id="universal-candidate-engine-ecosystem-tools"></a>
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

<a id="updates--uninstalls"></a>
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

<a id="directory-based-auto-switching"></a>
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

<a id="ide--build-tool-integration"></a>
## 🛠️ IDE & Build Tool Integration

Because DiamTek JVM maintains a stable Windows Directory Junction at `%LOCALAPPDATA%\DiamTek\JVM\current`, you can configure modern Windows IDEs and build systems to point directly to this junction. Switching versions via `jvm <version>` dynamically updates your development runtime without re-indexing your IDE projects.

### IntelliJ IDEA
1. Open **File** → **Project Structure** (`Ctrl+Alt+Shift+S`) → **SDKs**.
2. Click **+** → **Add JDK...**
3. Navigate to and select:
   ```text
   %LOCALAPPDATA%\DiamTek\JVM\current
   ```
   *(e.g., `C:\Users\<Username>\AppData\Local\DiamTek\JVM\current`)*
4. Name the SDK **"JVM Current"** and assign it as your Project SDK. Switching versions with `jvm 21` or `jvm 17` dynamically updates IntelliJ's underlying JDK.

### Visual Studio Code (Extension Pack for Java)
In your user or workspace `.vscode/settings.json`, configure the runtime path:
```json
{
  "java.jdt.ls.java.home": "%LOCALAPPDATA%\\DiamTek\\JVM\\current"
}
```

### Gradle
In your user-level `~/.gradle/gradle.properties` or project root `gradle.properties`:
```properties
org.gradle.java.home=%LOCALAPPDATA%/DiamTek/JVM/current
```

### Apache Maven
Maven natively respects the active `JAVA_HOME` environment variable managed by JVM. For explicit toolchain enforcement in `~/.m2/toolchains.xml`:
```xml
<toolchains>
  <toolchain>
    <type>jdk</type>
    <provides>
      <version>current</version>
    </provides>
    <configuration>
      <jdkHome>${env.LOCALAPPDATA}\DiamTek\JVM\current</jdkHome>
    </configuration>
  </toolchain>
</toolchains>
```

---

<a id="global-environment-management"></a>
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
Inspect which `java.exe` binary Windows is actively executing in order of PATH precedence:
```cmd
where.exe java
# In PowerShell: (Get-Command java -All).Source
```
*(If an old Oracle `javapath` appears above `%LOCALAPPDATA%\DiamTek\JVM\current\bin`, run `jvm clear` or use the UI to purge rogue paths, then re-activate with `jvm <version>`).*

### System Scrubbing
Instantly wipe `JAVA_HOME` and purge Java from your Windows PATH entirely:
```cmd
jvm clear
```

<a id="bring-your-own-jdk-byo-jdk"></a>
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

### Self-Uninstallation
Launch the deep uninstallation process directly from the CLI to wipe JVM, environment variables, AppData caches, and installed tools:
```cmd
jvm self-uninstall
```

### Help & Command Reference
Display the full command-line reference, arguments, and flag overrides directly in your terminal:
```cmd
jvm --help
# Or: jvm help, jvm -h, jvm /?
```

---

[← Back to Documentation Overview](../README.md#documentation)