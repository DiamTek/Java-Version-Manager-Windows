<h1 align="center">Usage Guide</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md)

</div>


---

The Java Version Manager for Windows is designed to accommodate both casual developers and hardcore CI/CD engineers. It acts as both a visually guided **Interactive TUI (Terminal User Interface)** and a deeply powerful, highly-configurable **Headless CLI**.

This document outlines every command, flag override, and semantic route available in the engine.

### 🔍 Quick Jump
- [Interactive UI Mode](#interactive-ui-mode)
- [Command Reference Cheat Sheet](#command-reference-cheat-sheet)
- [Quick-Switching (CLI)](#quick-switching-cli)
- [Ephemeral Command Execution (jvm exec / jvm run)](#ephemeral-command-execution)
- [Headless Installations](#headless-installations)
- [Universal Candidate Engine (Ecosystem Tools)](#universal-candidate-engine-ecosystem-tools)
- [Updates & Uninstalls](#updates--uninstalls)
- [Directory-Based Auto-Switching (.java-version & .sdkmanrc)](#directory-based-auto-switching)
- [Project Version Pinning (jvm pin / jvm local)](#project-version-pinning)
- [IDE & Build Tool Integration](#ide--build-tool-integration)
- [Bring Your Own JDK (jvm link)](#bring-your-own-jdk-byo-jdk)
- [Global Environment Management](#global-environment-management)
- [Diagnostic Health Audit (jvm doctor)](#diagnostic-health-audit)
- [Explorer Directory Navigation (jvm open / jvm home)](#explorer-directory-navigation)
- [PowerShell Profile Hook (jvm hook)](#powershell-profile-hook)

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
| `jvm use <version>` | Global | Switches to specified JDK version (SDKMAN/nvm compatible alias). |
| `jvm default <version>` | Global | Sets default JDK version globally (SDKMAN alias). |
| `jvm <version> --session` | Session | Switches JDK for the current terminal only without touching the Windows Registry. |
| `jvm <version> --vendor <name>` | Global | Switches JDK with explicit vendor selection (e.g., `adoptium`, `oracle`, `corretto`). |
| `jvm <version> --symlink` | Global | Forces switch using Symlink Mode (NTFS Directory Junction, UAC-Free). |
| `jvm <version> --legacy` | Machine | Forces switch using Registry Mode (writes to `HKLM`, requests UAC elevation). |
| `jvm latest` | Global | Resolves and switches to the highest installed JDK version on your machine. |
| `jvm lts` | Global | Resolves and switches to the highest installed LTS version (e.g., 21, 17, 11). |
| `jvm pin [version]` | Project | Locks or inspects directory-level `.java-version` (`jvm local`). |
| `jvm exec <ver> [--] <cmd>` | Subshell | Executes command in ephemeral isolated JDK subshell without changing system state (`jvm run`). |
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
| `jvm current` | Inspection | Displays comprehensive status card: active JDK, switching mode, junction target, and tools (`jvm status`). |
| `jvm which [candidate]` | Inspection | Prints absolute filesystem path to active `java.exe` or ecosystem binary (`jvm path`). |
| `jvm doctor` | Diagnostic | Deep system health audit: permissions, junctions, registry sync, PATH shadowing, and hooks. |
| `jvm hook [install/remove]` | Shell | Manage PowerShell profile auto-sync wrapper hook (status, install, remove). |
| `jvm open [candidate]` | Navigation | Opens active candidate, JDK, or storage root in Windows File Explorer (`jvm home`). |
| `jvm clean` | Maintenance | Safely purges temporary download caches and extraction artifacts to reclaim disk space. |
| `jvm clear` | System | Purges `JAVA_HOME` and cleanly removes JVM directory junctions from PATH. |
| `jvm link <path> <name>` | Custom | Registers an external or custom JDK (BYO-JDK / GraalVM) into the manager. |
| `jvm unlink <name>` | Custom | Unregisters a custom linked JDK from the manager. |
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
*(Note: This feature requires the PowerShell Profile hook to be installed via `jvm hook` or the Settings menu).*

### SDKMAN! & NVM Migration Aliases (`jvm use` / `jvm default`)
Developers migrating from Unix environments (SDKMAN!, nvm, fnm) can use their existing muscle memory directly without learning new syntax:
```cmd
:: Switch active JDK globally (identical to jvm 21)
jvm use 21

:: Set default JDK globally (identical to jvm 21)
jvm default 21

:: Switch locally for current terminal session only (SDKMAN 'sdk use' semantics)
jvm use 21 --session
```

> **Note on `jvm use` vs `jvm default`:** In SDKMAN!, `sdk use` applies strictly to the current shell while `sdk default` alters the global symlink. In DiamTek JVM, standard switches (`jvm 21`, `jvm use 21`, `jvm default 21`) switch the active JDK globally via the Directory Junction (matching the Windows `nvm-windows` convention). To isolate a switch to the current terminal only, simply pass `--session` (`jvm use 21 --session`).

---

<a id="ephemeral-command-execution"></a>
## 🚀 Ephemeral Command Execution (`jvm exec` / `jvm run`)

Sometimes you need to run a single build, compile a test class, or invoke a diagnostic utility against a specific JDK **without** modifying your active environment, altering Directory Junctions, or changing the Windows Registry.

DiamTek JVM provides high-speed ephemeral execution via `jvm exec` (or `jvm run`):
```cmd
:: Execute a command with JDK 21 in an isolated subshell
jvm exec 21 -- java -version

:: Double-dash is optional for standard commands
jvm run 17 mvn clean test

:: Execute build tools against semantic targets
jvm exec lts -- gradle build
jvm exec latest -- java -jar target/app.jar
```

### How Ephemeral Execution Works:
1. Resolves the requested version (e.g. `21`, `17.0.10`, `latest`, `lts`, or vendor name) from your installed JDK inventory.
2. Spawns an isolated child subshell with local `JAVA_HOME` pointing directly to the target JDK and prepends its `bin\` folder to the local `PATH`.
3. Executes your command with 100% of its original arguments intact.
4. Leaves the active Directory Junction (`%LOCALAPPDATA%\DiamTek\JVM\current`), Windows Registry, and all other terminal windows completely untouched.
5. Captures and propagates the child process's exact exit code back to the caller (ensuring CI/CD pipelines fail accurately on build errors).

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

<a id="project-version-pinning"></a>
### 📌 Project Version Pinning (`jvm pin` / `jvm local`)
Instead of manually creating and editing `.java-version` files by hand, you can use the `jvm pin` command (or `jvm local`) to lock the required JDK version for your repository or view the current directory lock:

```cmd
:: Pin Java 21 to the current directory (.java-version)
jvm pin 21

:: Pin with explicit vendor or architecture flags
jvm pin 21 --vendor adoptium
jvm pin 17 --legacy

:: Inspect the current directory's pinned version
jvm pin
# Alias: jvm local
```

When you or a teammate runs `jvm` inside that directory, JVM immediately activates the pinned version with True Session Isolation.

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

### Inspection & Status Commands

#### Comprehensive Status Overview (`jvm current` / `jvm status`)
Displays a complete diagnostic dashboard detailing your active Java runtime, vendor metadata, `JAVA_HOME`, binary location, switching mode, directory junction pointer, and all active ecosystem build tools:
```cmd
jvm current
# Alias: jvm status
```

**Example Output:**
```text
[  INFO  ] Current JVM Environment Status:
============================================================
 Java Configuration:
   - Version:       Eclipse Adoptium 21.0.12.1
   - JAVA_HOME:     C:\Users\<User>\AppData\Local\DiamTek\JVM\current
   - Binary:        C:\Users\<User>\AppData\Local\DiamTek\JVM\current\bin\java.exe
   - Mode:          [Symlink Mode] (User Junction, UAC Free)
   - Junction:      C:\Users\<User>\AppData\Local\DiamTek\JVM\current -> C:\Program Files\Java\jdk-21.0.12.1+1

 Ecosystem Tools:
   - maven:         3.9.6 [ACTIVE]
   - gradle:        8.5 [ACTIVE]
============================================================
```

#### Binary Path Resolution (`jvm which` / `jvm path`)
Prints the clean absolute filesystem path of the resolved `java.exe` or candidate tool directly to `stdout`. Perfect for scripting, build automation, CI/CD runners, and IDE configurations:
```cmd
:: Resolve active Java binary
jvm which

:: Resolve specific ecosystem build tool binaries
jvm which maven
jvm which gradle
jvm which kotlin
```

**Using `jvm which` in Scripts:**

* **In PowerShell:**
  ```powershell
  $javaBin = (jvm which)
  & $javaBin -version
  ```

* **In Command Prompt (Batch):**
  ```cmd
  for /f "delims=" %%i in ('jvm which') do set "JAVA_BIN=%%i"
  "!JAVA_BIN!" -version
  ```

* **Exit Codes for CI/CD Automation:**
  * `0`: Binary successfully located and returned.
  * `1`: Candidate is not installed or active (error details sent to `stderr`).

#### Installed JDK & Candidate Inventory (`jvm list`)
Lists all installed JDKs (version, vendor, filesystem path), highlighting the currently active one with `[ACTIVE]`. Ecosystem tools and their active versions are listed at the bottom:
```cmd
jvm list
```

#### PATH Precedence Diagnostics (`where.exe java`)
Inspect which `java.exe` binary Windows is actively executing in order of PATH precedence:
```cmd
where.exe java
# In PowerShell: (Get-Command java -All).Source
```
*(If an old Oracle `javapath` appears above `%LOCALAPPDATA%\DiamTek\JVM\current\bin`, run `jvm clear` to purge rogue paths, then re-activate with `jvm <version>`).*

<a id="diagnostic-health-audit"></a>
#### 🩺 Diagnostic Health Audit (`jvm doctor`)
Runs a comprehensive, automated 7-point health check across your entire Windows operating system and JVM installation environment:
```cmd
jvm doctor
```

**What `jvm doctor` Verifies:**
1. **Storage Root Accessibility:** Verifies that `%LOCALAPPDATA%\DiamTek\JVM` exists and has unrestricted read/write permissions.
2. **Architecture Mode & Junction Integrity:** Validates whether Symlink Mode or Registry Mode is active. For Symlink Mode, checks that `%LOCALAPPDATA%\DiamTek\JVM\current` exists, points to a valid target directory, and contains a working `bin\java.exe`.
3. **Registry Synchronization:** Queries both User (`HKCU\Environment`) and Machine (`HKLM\...`) registries to verify `JAVA_HOME` configuration consistency.
4. **PATH Precedence & Shadowing:** Evaluates `where.exe java` to detect rogue paths (such as legacy Oracle `javapath` or `System32\java.exe`) that might intercept `java` commands before JVM.
5. **PowerShell Profile Hook:** Inspects `$PROFILE` across Windows PowerShell (5.1) and PowerShell Core (7+) for the active `# >>> jvm >>>` hook.
6. **Hardware CPU Architecture:** Confirms native architecture detection (`x64` vs `ARM64`).
7. **JDK Inventory Count:** Scans and counts all locally discovered and managed JDK distributions.

**Exit Codes for Automated Health Checks:**
- `0`: All diagnostic health checks passed with zero conflicts.
- `1`: One or more warnings or misconfigurations detected.

<a id="explorer-directory-navigation"></a>
#### 📂 Explorer Directory Navigation (`jvm open` / `jvm home`)
Instantly open any JVM candidate directory or storage root in Windows File Explorer without manually typing or searching long paths:
```cmd
:: Open active JDK directory in File Explorer
jvm open

:: Open specific candidate tool directory
jvm open maven
jvm open gradle
jvm open kotlin

:: Open specific JDK installation by version number
jvm open 21

:: Jump to the JVM root storage directory
jvm open root
# Or: jvm home
```

### System & Cache Maintenance

#### Cache & Artifact Pruning (`jvm clean`)
Safely purges temporary installation archives, failed download caches, and orphaned extraction artifacts to reclaim disk space:
```cmd
jvm clean
```
* **What it cleans:**
  * `%TEMP%\jdk_*_download.zip` and `.tar.gz` installer archives.
  * Stale `%TEMP%\jdk_*_extract` extraction workspaces.
  * Intermediate `%TEMP%\jvm_dl_*.ps1` PowerShell downloaders.
  * Orphaned `%LOCALAPPDATA%\DiamTek\JVM\candidates\*\temp_*` directories.
* **Safety Guarantee:** `jvm clean` is completely non-destructive. It never modifies your active JDKs, candidate tools, directory junctions, or Windows Registry settings.

#### Environment Slate Wipe (`jvm clear`)
Instantly wipes `JAVA_HOME` and cleanly removes JVM directory junctions and legacy Oracle `javapath` entries from your PATH:
```cmd
jvm clear
```
* **Automated Safety Backup:** Before executing destructive registry scrubs, `jvm clear` automatically exports a timestamped `.reg` backup of both User (`HKCU`) and Machine (`HKLM`) environment registries to `%TEMP%`.

<a id="powershell-profile-hook"></a>
#### PowerShell Profile Hook (`jvm hook`)
Manage the lightweight PowerShell `$PROFILE` auto-sync wrapper function across Windows PowerShell 5.1 and PowerShell 7+ without opening the interactive Settings menu:
```cmd
:: Install or update PowerShell profile hook
jvm hook
# Or: jvm hook install

:: Check profile hook status across all detected PowerShell profiles
jvm hook status

:: Remove PowerShell profile hook
jvm hook remove
```
* **Seamless Terminal Synchronization:** Once installed, whenever you switch JDKs via `jvm <version>`, the wrapper automatically synchronizes `$env:JAVA_HOME` and `$env:Path` in the active terminal session without requiring you to restart your PowerShell window or launch a new subshell.

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