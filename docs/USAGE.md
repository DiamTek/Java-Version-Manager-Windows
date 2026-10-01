<h1 align="center">Usage Guide</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md) &nbsp;•&nbsp; [🛡️ Security](SECURITY.md) &nbsp;•&nbsp; [🤝 Contributing](CONTRIBUTING.md) &nbsp;•&nbsp; [💬 Support](SUPPORT.md)

</div>


---

The Java Version Manager for Windows is designed to accommodate both casual developers and hardcore CI/CD engineers. It acts as both a visually guided **Interactive TUI (Terminal User Interface)** and a deeply powerful, highly-configurable **Headless CLI**.

This document outlines every command, flag override, and semantic route available in the engine.

### 🔍 Quick Jump
- [Interactive UI Mode](#interactive-ui-mode)
- [Command Reference Cheat Sheet](#command-reference-cheat-sheet)
- [PowerShell Dynamic Tab-Completion](#powershell-dynamic-tab-completion)
- [CLI Ergonomics & Shorthand Aliases](#cli-ergonomics--shorthand-aliases)
- [Quick-Switching (CLI)](#quick-switching-cli)
- [Ephemeral Command Execution (jvm exec / jvm run)](#ephemeral-command-execution)
- [Headless Installations](#headless-installations)
- [Universal Candidate Engine (Ecosystem Tools)](#universal-candidate-engine-ecosystem-tools)
- [Updates & Uninstalls](#updates--uninstalls)
- [Dual Update Channels (Stable vs Nightly)](#update-channels-stable-vs-nightly)
- [Directory-Based Auto-Switching (.java-version & .sdkmanrc)](#directory-based-auto-switching)
- [Project Version Pinning (jvm pin / jvm local)](#project-version-pinning)
- [Reproducible Lockfiles (.jvm.lock & jvm install --locked)](#reproducible-lockfiles)
- [IDE & Build Tool Integration](#ide--build-tool-integration)
- [Bring Your Own JDK (jvm link)](#bring-your-own-jdk-byo-jdk)
- [Global Environment Management](#global-environment-management)
- [Diagnostic Health Audit (jvm doctor)](#diagnostic-health-audit)
- [Explorer Directory Navigation (jvm open / jvm home)](#explorer-directory-navigation)
- [PowerShell Profile Hook (jvm hook)](#powershell-profile-hook)
- [Machine-Readable JSON & Offline Modes (--json / --offline)](#machine-readable-json--offline-modes)
- [Common Workflow Recipes](#common-workflow-recipes)
- [CI/CD Automation Recipes](#cicd-integration-recipes)

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
| `jvm <version> --legacy` | Machine | Forces switch using Registry Mode (writes to `HKLM`, requests UAC elevation; alias: `--registry`). |
| `jvm latest` | Global | Resolves and switches to the highest installed JDK version on your machine. |
| `jvm lts` | Global | Resolves and switches to the highest installed LTS version (e.g., 21, 17, 11). |
| `jvm pin [version]` | Project | Locks or inspects directory-level `.java-version` (`jvm local`). |
| `jvm exec <ver> [--] <cmd>` | Subshell | Executes command in ephemeral isolated JDK subshell without changing system state (`jvm run`). |
| `jvm --global` | Global | Forces directory-based auto-switching (`.java-version`) to write globally to registry. |
| `jvm install` | Interactive | Opens the interactive JDK / tool installation wizard. |
| `jvm install <ver> [--vendor <name>]` | Machine | Downloads and installs specified JDK (e.g., `jvm install 21 --vendor adoptium`). |
| `jvm install lts [--latest]` | Machine | Installs an LTS JDK (prompts for supported versions: 17, 21, 25; passing `--latest` locks onto newest). |
| `jvm install <ver> -y` | Machine | Automated headless install with aggressive safety warning bypass for CI/CD. |
| `jvm install <ver> --skip-checksum` | Machine | Bypasses checksum verification if vendor hash mirror is unreachable. |
| `jvm install --locked` (or `-l`) | Machine / User | Installs and activates exact versions & dependencies pinned in repository `.jvm.lock` with strict checksum verification. |
| `jvm lock [candidate] [version]` | Project | Generates or updates reproducible `.jvm.lock` manifest recording candidate, vendor, arch, exact URL, and cryptographic digest. |
| `jvm install <tool> [version]` | User | Installs ecosystem tool (omitting version defaults to `latest`; e.g., `jvm install maven`, `jvm install gradle 8.9`; accepts `-y`). |
| `jvm <tool> <version>` | User | Switches active ecosystem tool version (e.g., `jvm kotlin 2.0.20`, `jvm maven 3.9.6`). |
| `jvm update <version>` | Machine | Checks for and applies vendor patches to a specific installed JDK (e.g., `jvm update 21`). |
| `jvm update --all [--vendor <name>]` | Machine | Silently checks and patches all installed JDKs and tools to latest releases. |
| `jvm uninstall` | Interactive | Opens interactive JDK uninstaller selection list (marks `[ACTIVE]` runtime, includes Cancel option; supports `--vendor` filter; aliases: `jvm rm`, `jvm remove`). |
| `jvm uninstall <version> [--vendor <name>]` | Machine | Uninstalls a specific installed JDK (aliases: `jvm rm <version>`, `jvm remove <version>`). |
| `jvm uninstall <tool> [version]` | User | Uninstalls an ecosystem tool (auto-detects single installed version, or prompts with interactive menu if multiple). |
| `jvm list` | Inspection | Lists all installed JDKs, vendors, paths, and ecosystem build tools (alias: `jvm ls`). |
| `jvm current` | Inspection | Displays comprehensive status card: active JDK, mode, junction target, and tools (aliases: `jvm status`, `jvm info`, `jvm whoami`, `jvm env`). |
| `jvm which [candidate]` | Inspection | Prints absolute filesystem path to active `java.exe` or ecosystem binary (alias: `jvm path`). |
| `jvm doctor` | Diagnostic | Deep system health audit: permissions, junctions, registry sync, PATH shadowing, and hooks (alias: `jvm check`). |
| `jvm hook [install/remove]` | Shell | Manage PowerShell profile auto-sync wrapper hook (`install`, `setup`, `status`, `check`, `remove`). |
| `jvm open [candidate]` | Navigation | Opens active candidate, JDK, or storage root in Windows File Explorer (alias: `jvm home`). |
| `jvm clean` | Maintenance | Safely purges temporary download caches and extraction artifacts to reclaim disk space (alias: `jvm prune`). |
| `jvm clear` | System | Purges `JAVA_HOME` and cleanly removes JVM directory junctions from PATH. |
| `jvm link [path] [name]` | Custom | Registers an external custom JDK (or lists all registered links with target paths if run without arguments). |
| `jvm unlink <name>` | Custom | Unregisters a custom linked JDK from the manager. |
| `jvm version` | Tool | Displays current JVM version, build number, and checks GitHub for updates (`--version`, `-v`). |
| `jvm channel [stable/nightly]` | Tool | Displays or switches the update channel between `Stable` (official releases) and `Nightly` (main branch). |
| `jvm self-update` | Tool | Automatically downloads and atomic-swaps `jvm.bat` to the latest release. |
| `jvm self-uninstall` | System | Triggers deep UAC-elevated system uninstaller (`uninstall.ps1`, `jvm uninstall-self`). |
| `jvm <command> --offline` | Flag | Air-gapped / offline execution mode: strictly blocks network calls and executes local commands safely. |
| `jvm <command> --json` | Flag | Outputs structured machine-readable JSON (`jvm current --json`, `jvm which --json`, `jvm list --json`). |
| `jvm <command> --no-lock` | Flag | Bypasses atomic mutex state lock acquisition (`state.lock`) in emergency recovery (UNSAFE for concurrent operations). |
| `jvm <command> --no-color` | Flag | Suppresses ANSI color codes for clean redirection and CI/CD logs (also honors `NO_COLOR` env). |
| `jvm --help` | Help | Displays formatted in-terminal command manual and flag reference (`-h`, `/?`). |

*Note: Running bare `jvm` launches the interactive dashboard to access visual Updater and Uninstaller sub-menus.*

---

<a id="powershell-dynamic-tab-completion"></a>
## ⌨️ PowerShell Dynamic Tab-Completion

DiamTek JVM provides native, intelligent tab-completion for both **Windows PowerShell 5.1** and modern cross-platform **PowerShell 7+ (`pwsh`)**. Powered by the .NET runtime's native `Register-ArgumentCompleter` engine, it requires zero external modules, third-party packages, or slow subprocesses.

When you install or activate the PowerShell profile hook (`jvm hook` or via `install.ps1`), dynamic tab completion is automatically embedded inside your `$PROFILE`.

### Autocompletion Capabilities Matrix

| Input Context | Tab Behavior | Autocompleted Values |
|---------------|--------------|----------------------|
| `jvm <Tab>` / `jvm.bat <Tab>` / `.\jvm.bat <Tab>` | Subcommands, candidates, & global flags | `list`, `ls`, `install`, `uninstall`, `rm`, `use`, `pin`, `current`, `doctor`, `clean`, `channel`, `java`, `maven`, `gradle`, etc. |
| `jvm channel <Tab>` / `jvm --channel <Tab>` | Delivery update channel targets | `stable`, `nightly` |
| `jvm open <Tab>` | Known filesystem navigation targets | `home`, `dir`, `bin`, `config`, `cache`, `downloads`, `backup`, `backups`, `links` |
| `jvm hook <Tab>` | Profile hook lifecycle management actions | `install`, `status`, `check`, `remove`, `uninstall` |
| `jvm --vendor <Tab>` | Certified JDK upstream distribution vendors | `adoptium`, `temurin`, `oracle`, `corretto`, `zulu`, `microsoft`, `graalvm`, `liberica`, `bellsoft`, `semeru`, `ibm`, `openj9` |
| `jvm use <Tab>` | Dynamically discovered installed versions | Scans `%LOCALAPPDATA%\JavaVersionManager\links` and `%USERPROFILE%\.jdks` in real-time |
| `jvm pin <Tab>` | Dynamically discovered installed versions | Autocompletes installed JDK version tags for `.java-version` creation |
| `jvm uninstall <Tab>` | Installed JDKs and candidates | Autocompletes installed version tags for targeted uninstallation |
| `jvm --<Tab>` | CLI flag overrides | `--vendor`, `--symlink`, `--registry`, `--legacy`, `--session`, `--global`, `--skip-checksum`, `--no-verify`, `--latest`, `--yes`, `-y`, `--no-color`, `--offline`, `--json`, `--no-lock`, `--channel`, `--nightly`, `--stable`, `--version`, `--help` |

### Interactive Tab Session Examples

```powershell
# 1. Autocompleting commands by prefix across all invocation styles
jvm ins<Tab>                  # Expands to: jvm install
jvm.bat ins<Tab>              # Expands to: jvm.bat install
.\jvm.bat ins<Tab>            # Expands to: .\jvm.bat install

# 2. Cycling through installed JDK versions without typing them manually
jvm use <Tab>                 # Cycles through: 21, 17, 11, 8, java, maven, gradle...

# 3. Filtering by vendor (all 12 distributions supported)
jvm install 21 --ven<Tab>     # Expands to: jvm install 21 --vendor
jvm install 21 --vendor <Tab> # Cycles: adoptium, temurin, oracle, corretto, zulu, microsoft, graalvm, liberica, bellsoft, semeru, ibm, openj9, sapmachine, sap, mandrel, redhat, dragonwell, alibaba, kona, tencent

# 4. Opening specific application data directories
jvm open do<Tab>              # Expands to: jvm open downloads
```

### Enabling and Verifying Tab-Completion
If tab-completion is not active in your current PowerShell session, simply run:
```powershell
jvm hook
```
This inspects all standard PowerShell profile locations (`WindowsPowerShell\Microsoft.PowerShell_profile.ps1` and `PowerShell\Microsoft.PowerShell_profile.ps1`) and injects the completion handler registered simultaneously for `jvm`, `jvm.bat`, and `.\jvm.bat`. Open a new terminal tab or run `. $PROFILE` to start using dynamic completion immediately.

---

<a id="cli-ergonomics--shorthand-aliases"></a>
## 🏎️ CLI Ergonomics & Shorthand Aliases

To maximize developer velocity and eliminate muscle-memory friction when switching between Linux, macOS, and Windows environments, DiamTek JVM includes built-in ergonomic aliases for all primary operations.

### Muscle-Memory Alias Mapping

| Shorthand Alias | Canonical Command | Ecosystem Origin | Functional Description |
|-----------------|-------------------|------------------|------------------------|
| `jvm ls` | `jvm list` | Unix / Linux / `ls` | Lists all installed JDKs, vendors, paths, and ecosystem build tools. |
| `jvm rm <ver>` | `jvm uninstall <ver>` | Unix / Docker / Git | Uninstalls a specific installed JDK (e.g., `jvm rm 21`) or candidate tool. |
| `jvm remove <ver>` | `jvm uninstall <ver>` | Package Managers | Uninstalls a specific installed JDK (e.g., `jvm remove 17`). |
| `jvm info` | `jvm current` | Homebrew / Scoop | Displays active JDK, switching mode, junction target, and tools status card. |
| `jvm whoami` | `jvm current` | POSIX / Linux | Identity query displaying which Java binary and version currently owns the shell. |
| `jvm check` | `jvm doctor` | Rust `cargo check` | Runs full pre-flight diagnostic health audit and conflict scanner. |
| `jvm prune` | `jvm clean` | Docker / Git `prune` | Safely purges temporary download caches and extraction artifacts. |
| `jvm path` | `jvm which` | Windows CLI | Prints absolute filesystem path to active `java.exe` or candidate tool. |
| `jvm home` | `jvm open` | SDKMAN! / macOS | Opens candidate installation directory or storage root in File Explorer. |
| `jvm local [ver]` | `jvm pin [ver]` | pyenv / rbenv / asdf | Locks directory-level `.java-version` file for automated project switching. |
| `jvm run <ver> <cmd>` | `jvm exec <ver> <cmd>`| npm / Cargo | Executes command in ephemeral isolated JDK subshell without altering global state. |
| `jvm status` | `jvm current` | Git / systemd | Displays full environment card. |

All aliases support the full spectrum of CLI flags (`--session`, `--symlink`, `--vendor`, `--no-color`, `-y`).

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
```powershell
jvm latest
jvm lts
```

> [!NOTE]
> **Recognized LTS Releases:** For offline local switching, `jvm lts` evaluates installed JDKs against recognized Long-Term Support releases: **8, 11, 17, 21, 25, 29**. For automated remote installations, Java 17 is the oldest installable LTS release due to upstream vendor distribution constraints (older releases like Java 8 and 11 can be integrated via `jvm link`). Run `jvm install lts` to select from installable LTS versions, or `jvm install lts --latest` to automatically lock onto the newest available LTS.

### Architecture & Priority Overrides
You can chain flags to bypass prompts or override your global Settings for a single command.

Override the vendor prompt to silently select Adoptium:
```powershell
jvm 21 --vendor adoptium
```
Force the engine to use **Symlink Mode** (UAC-Free Directory Junctions) for this specific switch, ignoring your saved default architecture:
```powershell
jvm 21 --symlink
```
Force the engine to use **Legacy Registry Mode** (Requests Administrator UAC elevation) for this specific switch:
```powershell
jvm 21 --legacy
# Alias: jvm 21 --registry
```
Semantic routing combined with a vendor override (switches to the newest installed Amazon Corretto LTS version):
```powershell
jvm lts --vendor corretto
```

### 🏷️ Recognized Vendor Reference Table

When multiple distributions of the same major version are installed, JVM prompts for your preference. You can bypass the prompt by passing `--vendor <name>`:

| `--vendor` Value | Display Name | Distribution / Packaging |
|-----------------|--------------|--------------------------|
| `oracle` | Oracle JDK | Official Oracle JDK |
| `adoptium` | Eclipse Temurin | OpenJDK (Eclipse Adoptium) |
| `corretto` | Amazon Corretto | OpenJDK (Amazon Corretto) |
| `graalvm` | GraalVM CE | Oracle GraalVM Community Edition |
| `zulu` | Azul Zulu | OpenJDK (Azul Systems) |
| `microsoft` | Microsoft Build | OpenJDK (Microsoft Build of OpenJDK) |
| `liberica` | BellSoft Liberica | OpenJDK (BellSoft Liberica / FX) |
| `semeru` | IBM Semeru | IBM Semeru Runtime (Eclipse OpenJ9) |
| `sapmachine` | SAP SapMachine | OpenJDK (SAP SE) |
| `mandrel` | Red Hat Mandrel | Downstream GraalVM Native Image (Red Hat) |
| `dragonwell` | Alibaba Dragonwell | OpenJDK (Alibaba Cloud) |
| `kona` | Tencent Kona | OpenJDK (Tencent) |
| `custom` | Custom | Locally linked JDKs via `jvm link` |

### True Session Isolation
If you only want to change the Java version for your *current* terminal window (without permanently altering your global Windows Registry or affecting background services), use the session flag:
```cmd
jvm 21 --session
```
*(Note: This feature requires the PowerShell Profile hook to be installed via `jvm hook` or the Settings menu).*

### SDKMAN! & NVM Migration Aliases (`jvm use` / `jvm default`)
Developers migrating from Unix environments (SDKMAN!, nvm, fnm) can use their existing muscle memory directly without learning new syntax:
```powershell
# Switch active JDK globally (identical to jvm 21)
jvm use 21

# Set default JDK globally (identical to jvm 21)
jvm default 21

# Switch locally for current terminal session only (SDKMAN 'sdk use' semantics)
jvm use 21 --session
```

> **Note on `jvm use` vs `jvm default`:** In SDKMAN!, `sdk use` applies strictly to the current shell while `sdk default` alters the global symlink. In DiamTek JVM, standard switches (`jvm 21`, `jvm use 21`, `jvm default 21`) switch the active JDK globally via the Directory Junction (matching the Windows `nvm-windows` convention). To isolate a switch to the current terminal only, simply pass `--session` (`jvm use 21 --session`).

---

<a id="ephemeral-command-execution"></a>
## 🚀 Ephemeral Command Execution (`jvm exec` / `jvm run`)

Sometimes you need to run a single build, compile a test class, or invoke a diagnostic utility against a specific JDK **without** modifying your active environment, altering Directory Junctions, or changing the Windows Registry.

DiamTek JVM provides high-speed ephemeral execution via `jvm exec` (or `jvm run`):
```powershell
# Execute a command with JDK 21 in an isolated subshell
jvm exec 21 -- java -version

# Double-dash is optional for standard commands
jvm run 17 mvn clean test

# Execute build tools against semantic targets
jvm exec lts -- gradle build
jvm exec latest -- java -jar target/app.jar
```

### How Ephemeral Execution Works:
1. Resolves the requested version (e.g. `21`, `17.0.10`, `latest`, `lts`, or vendor name) from your installed JDK inventory. If an exact major version or folder name match is not found, JVM performs an intelligent case-insensitive substring match across all installed JDK directory paths.
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

### Supported JDK Distribution Vendors (12 Native Upstream Ecosystems)

DiamTek JVM connects directly to official upstream vendor APIs to resolve, download, verify, and extract verified production JDKs. You can specify any of the 12 supported distributions using `--vendor <name>`:

| Vendor Identifier | Canonical Name | Upstream Source / Engine | Primary Strengths & Use Cases | Example Installation |
|---|---|---|---|---|
| `oracle` | Oracle OpenJDK | Oracle Corporation (HotSpot) | Reference OpenJDK implementation, newest feature releases. | `jvm install 21 --vendor oracle` |
| `adoptium` / `temurin` | Eclipse Temurin | Eclipse Foundation (HotSpot) | General purpose, industry-standard LTS enterprise builds. | `jvm install 21 --vendor adoptium` |
| `graalvm` | GraalVM CE | Oracle Labs (SubstrateVM) | Ahead-Of-Time (AOT) compilation, native executable binaries. | `jvm install 21 --vendor graalvm` |
| `corretto` | Amazon Corretto | Amazon Web Services (HotSpot) | Production-grade AWS environments, multi-platform reliability. | `jvm install 21 --vendor corretto` |
| `zulu` | Azul Zulu | Azul Systems (HotSpot) | Certified TCK compliance, legacy Java 8/11/17 compatibility. | `jvm install 21 --vendor zulu` |
| `microsoft` / `ms` | Microsoft OpenJDK | Microsoft (HotSpot) | Azure-optimized cloud workloads, Windows native architecture. | `jvm install 21 --vendor microsoft` |
| `liberica` / `bellsoft`| BellSoft Liberica | BellSoft (HotSpot / FX) | Spring Boot default base image, standard HotSpot with full TCK verification, JavaFX / LibericaFX support, compact lightweight footprints. | `jvm install 21 --vendor liberica` |
| `semeru` / `ibm` / `openj9` | IBM Semeru Runtimes | IBM (Eclipse OpenJ9) | Eclipse OpenJ9 virtual machine, drastically lower memory footprint (up to 50% less RAM), rapid container startup times, dynamic AOT. | `jvm install 21 --vendor semeru` |
| `sapmachine` / `sap` | SAP SapMachine | SAP SE (HotSpot) | Enterprise SAP workloads, mission-critical production environments, zero-rate-limit releases API. | `jvm install 21 --vendor sapmachine` |
| `mandrel` / `redhat` | Red Hat Mandrel | Red Hat (SubstrateVM) | Downstream GraalVM CE distribution specialized for Quarkus native compilation and microservices. | `jvm install 21 --vendor mandrel` |
| `dragonwell` / `alibaba` | Alibaba Dragonwell | Alibaba Cloud (HotSpot) | High-throughput e-commerce scale, JWarmup, Wisp coroutines, elastic heap management. | `jvm install 21 --vendor dragonwell` |
| `kona` / `tencent` | Tencent Kona | Tencent (HotSpot) | Large-scale cloud architectures, high concurrency, distributed computing, MD5/SHA256 verified builds. | `jvm install 21 --vendor kona` |

---

<a id="universal-candidate-engine-ecosystem-tools"></a>
## 📦 Ecosystem Build Tools (SDKMAN! Parity)

JVM supports downloading, switching, and managing modern build tools natively alongside Java. You can manage these via the command line or through the interactive **Ecosystem Management** sub-menu. Supported candidates include `maven`, `gradle`, `kotlin`, `scala`, `groovy`, `ant`, `sbt`, `jbang`, `quarkus`, `spring`, and `micronaut` (`mn`).

Install the absolute newest version of Maven directly from Apache (omitting the version defaults to `latest`):
```powershell
jvm install maven
# Or explicitly:
jvm install maven latest
```
Install a specific legacy version of Gradle headless without overwrite prompts:
```powershell
jvm install gradle 8.9 -y
```
> [!NOTE]
> **First-Install Auto-Activation & Version Prompts:** Omitting the version argument for any ecosystem install command (e.g., `jvm install scala` or `jvm install kotlin`) automatically defaults to `latest`. The first time you install any ecosystem candidate tool on your workstation, JVM automatically activates it as your current version immediately without requiring a secondary switch command. If an existing version is already installed, JVM interactively prompts: `Would you like to activate <Tool> <Version> now? (y/N): `.

> [!NOTE]
> **Automated Checksum & GitHub API Digest Discovery:** Every downloaded tool archive is cryptographically verified against SHA-256 or SHA-512 hashes before extraction. For distributions hosted on GitHub Releases that do not provide standalone `.sha256` files (such as Micronaut), JVM queries the official GitHub Releases REST API for the release asset's cryptographic `digest` (`sha256:<hex>`) through SSRF-guarded channels (`CWE-918` / `CWE-601`). If a candidate lacks both a checksum file and an API digest, interactive UI mode prompts `Do you want to continue installation without checksum verification? (y/N)`.

Instantly switch your active `KOTLIN_HOME` (and system PATH) to the specified version:
```powershell
jvm kotlin 2.0.20
# Or dynamically switch to the highest locally installed release:
jvm maven latest
```

**Double-Dash Candidate Flags (Scripting Precision):**
In shell scripts and automated tasks, you can also specify the target candidate using double-dash prefix flags (`--java`, `--maven`, `--gradle`, `--kotlin`, `--scala`, `--groovy`, `--ant`, `--sbt`, `--jbang`, `--quarkus`, `--spring`, `--micronaut`, `--mn`):
```powershell
jvm --maven 3.9.6
jvm --gradle 8.5
jvm --quarkus 3.15.1
```

Safely uninstall a specific tool and cleanly scrub its environment variables from your registry:
```powershell
# Uninstall by explicit version:
jvm uninstall groovy 4.0.23

# Or omit the version for smart auto-detection:
jvm uninstall scala
```

> [!NOTE]
> **Smart Uninstall Auto-Detection:** When running `jvm uninstall <tool>` without a version argument, JVM automatically inspects your installed versions. If exactly **one** version is installed, it selects and uninstalls it immediately. If **multiple** versions are detected, JVM presents an interactive numbered selection menu so you can choose which version to remove.

> [!TIP]
> **Zero-Quota Rate Limit Resilience & `GITHUB_TOKEN`:** When discovering latest releases for ecosystem tools backed by GitHub (Maven, Kotlin, Scala, Quarkus, Micronaut), JVM queries the GitHub Releases API. If unauthenticated IP limits (60 requests/hour) are reached, JVM automatically engages a zero-quota **HTTP 302 redirect fallback** against GitHub web releases to resolve the latest tag without failing. (Gradle, Groovy, Ant, and sbt resolve via independent endpoints at `services.gradle.org`, `archive.apache.org`, and `api.sdkman.io`). If you are running high-frequency automation in CI/CD and wish to bypass all rate-limiting entirely, set `$env:GITHUB_TOKEN`:
> ```powershell
> $env:GITHUB_TOKEN = "ghp_your_personal_access_token"
> ```

---

<a id="updates--uninstalls"></a>
## 🔄 Updates & Uninstalls

### Updating Tools
Update a specific installed JDK to its latest vendor patch release:
```cmd
jvm update 21
```
Update a specific ecosystem build tool directly:
```cmd
jvm update maven
# Or candidate-first:
jvm ant update
jvm quarkus update
```
**Bulk Updating:** Silently check and automatically patch *all* installed JDKs and Ecosystem Tools (Maven, Gradle, Ant, Quarkus, etc.) to their absolute newest releases:
```cmd
jvm update --all
```
Silently check and automatically patch *only* your installed Oracle JDKs:
```cmd
jvm update --all --vendor oracle
```

> [!NOTE]
> **Interactive Updater Menu:** When invoked from the CLI, `jvm update` requires a version target (e.g. `21`) or `--all`. To open the interactive, vendor-sorted visual Updater menu, launch `jvm` without arguments and navigate to **JDK Menu** (`1`) -> **Check for JDK Updates** (`5`).

### Uninstalling Tools
Headless uninstallation for JDK 21. If multiple vendors are found for the same version, it safely pauses to ask you which vendor you want to remove:
```cmd
jvm uninstall 21
```
100% headless uninstallation specifically targeting the Oracle vendor (bypasses all prompts):
```cmd
jvm uninstall 21 --vendor oracle
```
Interactive uninstallation: Omitting the version argument displays a numbered list of all currently installed JDKs, their filesystem paths, active status indicators (`[ACTIVE]`), and a Cancel option:
```cmd
jvm uninstall
```
Filter the interactive uninstallation list by vendor:
```cmd
jvm uninstall --vendor semeru
```
Uninstall a specific ecosystem build tool:
```cmd
jvm uninstall maven 3.9.6
```

> [!NOTE]
> **Interactive Uninstaller Menus & Version Selection:** When uninstalling JDKs via CLI (`jvm uninstall`), you can specify an explicit version (`jvm uninstall 21`) or omit it entirely to trigger the interactive selection prompt. The prompt displays each installed JDK, marks the active runtime, and includes a safe `Cancel` option (as well as Ctrl+C alignment guards). For ecosystem tools (`jvm uninstall <tool>`), omitting the version triggers smart auto-detection (auto-uninstalling if only one version is installed, or rendering an interactive selection menu if multiple versions exist). To open the full visual JDK uninstaller dashboard, launch `jvm` without arguments and navigate to **JDK Menu** (`1`) -> **Uninstall JDKs** (`4`).

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

#### SDKMAN! Vendor Suffix Mapping Table

When reading a `.sdkmanrc` file, JVM dynamically translates Unix SDKMAN! vendor tags to native Windows distributions:

| `.sdkmanrc` Suffix | Target Distribution | Resolved JVM Vendor | Example Entry |
|---|---|---|---|
| `-tem` | Eclipse Temurin | `adoptium` | `java=21.0.2-tem` |
| `-amzn` | Amazon Corretto | `corretto` | `java=17.0.10-amzn` |
| `-graal` / `-graalce` | GraalVM CE | `graalvm` | `java=21.0.2-graal` |
| `-zulu` | Azul Zulu | `zulu` | `java=17.0.10-zulu` |
| `-ms` / `-msft` | Microsoft OpenJDK | `microsoft` | `java=21.0.2-ms` |
| `-librca` / `-nik` | BellSoft Liberica | `liberica` | `java=21.0.2-librca` |
| `-sem` / `-semeru` | IBM Semeru (OpenJ9) | `semeru` | `java=21.0.2-sem` |
| `-sapm` | SAP SapMachine | `sapmachine` | `java=21.0.2-sapm` |
| `-mandrel` | Red Hat Mandrel | `mandrel` | `java=21.0.2-mandrel` |
| `-dragonwell` / `-alb` | Alibaba Dragonwell | `dragonwell` | `java=21.0.2-dragonwell` |
| `-kona` | Tencent Kona | `kona` | `java=21.0.2-kona` |
| *(bare number)* | Standard OpenJDK / Oracle | `oracle` / any installed | `java=21` |


<a id="project-version-pinning"></a>
### 📌 Project Version Pinning (`jvm pin` / `jvm local`)
Instead of manually creating and editing `.java-version` files by hand, you can use the `jvm pin` command (or `jvm local`) to lock the required JDK version for your repository or view the current directory lock:

```powershell
# Pin Java 21 to the current directory (.java-version)
jvm pin 21

# Pin with explicit vendor or architecture flags
jvm pin 21 --vendor adoptium
jvm pin 17 --legacy

# Inspect the current directory's pinned version
jvm pin
# Alias: jvm local
```

When you or a teammate runs `jvm` inside that directory, JVM immediately activates the pinned version with True Session Isolation.

---

<a id="reproducible-lockfiles"></a>
## 🔒 Reproducible Lockfiles (`.jvm.lock` & `jvm install --locked`)

While `.java-version` and `.sdkmanrc` pin semantic versions, production systems, enterprise teams, and deterministic CI/CD environments often require **100% byte-for-byte reproducibility** across developer laptops and build machines.

Similar to `package-lock.json`, `Cargo.lock`, or `mise.lock`, DiamTek JVM introduces native support for **`.jvm.lock`** files:

```powershell
# 1. Lock the active Java version into .jvm.lock
jvm lock 21 --vendor adoptium

# 2. Lock ecosystem build tools into the same project lockfile
jvm lock maven 3.9.9
jvm lock gradle 8.10.2

# 3. Headless installation of locked tools across CI/CD or new machines
jvm install --locked
# Shorthand alias:
jvm install -l
```

### The `.jvm.lock` Schema
When generated, `.jvm.lock` is written in UTF-8 without BOM using atomic staged writes (`.stage.<guid>.tmp` -> `.jvm.lock`) to eliminate partial-write race conditions (`CWE-362`):

```json
{
  "lockfile_version": 1,
  "generated_at": "2026-10-01T04:59:27Z",
  "tools": {
    "java": {
      "version": "21",
      "arch": "x64",
      "url": "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jdk_x64_windows_hotspot_21.0.12.1_1.zip",
      "checksum_type": "sha256",
      "checksum": "f9d6e191ab098c0d416e7d588a24420a8621cd2f4720dab2459b8b7b2d2d8b4e",
      "vendor": "adoptium"
    },
    "maven": {
      "version": "3.9.9",
      "arch": "all",
      "url": "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.9/apache-maven-3.9.9-bin.zip",
      "checksum_type": "sha512",
      "checksum": "8beac8d11ef208f1e2a8df0682b9448a9a363d2ad13ca74af43705549e72e74c9378823bf689287801cbbfc2f6ea9596201d19ccacfdfb682ee8a2ff4c4418ba"
    }
  }
}
```

### Security & Operational Guarantees
- **Hierarchical Directory Discovery:** When executed from a nested subdirectory (e.g. `src/main/java`), `jvm install --locked` automatically ascends the directory tree to locate the nearest ancestor `.jvm.lock`.
- **Cryptographic Enforcement (`CWE-494` / `CWE-354`):** Downloads are rigorously evaluated against the recorded checksum before extraction. If a hash mismatch occurs (indicating payload tampering or CDN corruption), installation aborts immediately with exit code `1` and purges all temporary files.
- **Symlink & Reparse Point Defenses (`CWE-59`):** Refuses to write to or read from symlinked `.jvm.lock` files or directories posing as lockfiles.
- **Selective Installation:** You can install all locked tools at once (`jvm install --locked`) or target a specific candidate (`jvm install --locked maven`).
- **Offline Idempotency:** If the exact version and vendor are already present locally, `jvm install --locked` activates them immediately without making outbound network requests.

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

### Eclipse IDE
1. Open **Window** → **Preferences** → **Java** → **Installed JREs**.
2. Click **Add...** → **Standard VM** → **Next**.
3. Set **JRE home** to:
   ```text
   %LOCALAPPDATA%\DiamTek\JVM\current
   ```
4. Name the entry **"JVM Current"** and check the box to set it as your workspace default. All Eclipse projects inheriting the workspace default will dynamically follow `jvm <version>` switches.

### Android Studio
1. Open **File** → **Settings** (or **Preferences**) → **Build, Execution, Deployment** → **Build Tools** → **Gradle**.
2. Under **Gradle JDK**, open the dropdown and select **Add JDK...**
3. Browse to `%LOCALAPPDATA%\DiamTek\JVM\current` and name it **"JVM Current"**.

### JetBrains Toolbox
If you manage your JetBrains IDEs or JDKs using JetBrains Toolbox, Toolbox stores runtimes inside `%USERPROFILE%\.jdks`. DiamTek JVM automatically scans this folder upon startup. All Toolbox-downloaded JDKs appear in `jvm list` and can be switched into directly with `jvm <version>`.

---

<a id="global-environment-management"></a>
## 🧹 Global Environment Management

### Inspection & Status Commands

#### Comprehensive Status Overview (`jvm current` / `jvm status` / `jvm env`)
Displays a complete diagnostic dashboard detailing your active Java runtime, vendor metadata, `JAVA_HOME`, binary location, switching mode, directory junction pointer, and all active ecosystem build tools:
```powershell
jvm current
# Aliases: jvm status, jvm env
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
   - Channel:       [Stable] (Official Releases)

 Ecosystem Tools:
   - maven:         3.9.6 [ACTIVE]
   - gradle:        8.5 [ACTIVE]
============================================================
```

> [!TIP]
> **Status Card Color Hierarchy:** In ANSI-capable terminals, JVM color-codes critical state information: `[Symlink Mode]` and the directory junction target path are highlighted in **green** (or `[Registry Mode]` in **red**), active update channels are tagged (`[Stable]` in **green**, `[Nightly]` in **purple**), and active ecosystem tools are marked with a green `[ACTIVE]` badge.

#### Binary Path Resolution (`jvm which` / `jvm path`)
Prints the clean absolute filesystem path of the resolved `java.exe` or candidate tool directly to `stdout`. Perfect for scripting, build automation, CI/CD runners, and IDE configurations:
```powershell
# Resolve active Java binary
jvm which

# Resolve specific ecosystem build tool binaries
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
```powershell
where.exe java
# In PowerShell: (Get-Command java -All).Source
```
*(If an old Oracle `javapath` appears above `%LOCALAPPDATA%\DiamTek\JVM\current\bin`, run `jvm clear` to purge rogue paths, then re-activate with `jvm <version>`).*

#### Machine-Readable Structured Telemetry (`--json`)
Emits pure, schema-compliant JSON directly to `stdout` with complete suppression of ANSI escape sequences, status badges, and ASCII rules:
```powershell
# Query environment state as JSON
jvm current --json

# Query binary path as JSON
jvm which java --json

# Run diagnostic health check as JSON
jvm doctor --json

# List installed runtimes as a JSON array
jvm list --json
```

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
```powershell
# Open active JDK directory in File Explorer
jvm open

# Open specific candidate tool directory
jvm open maven
jvm open gradle
jvm open kotlin

# Open the candidates base directory (%LOCALAPPDATA%\DiamTek\JVM\candidates)
jvm open candidates

# Open specific JDK installation by version number or folder name
jvm open 21

# Open internal directories (binaries, downloads, backups, custom links)
jvm open bin
jvm open downloads
jvm open backups
jvm open links

# Open active JDK junction directory
jvm open current
# Aliases: jvm open java

# Jump to the JVM root AppData directory (%LOCALAPPDATA%\DiamTek\JVM)
jvm open root
# Aliases: jvm open appdata, jvm open home, jvm home
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
  * Transient script artifacts: `%TEMP%\jvm_dl_*.ps1`, `%TEMP%\jvm_install_*.ps1`, `%TEMP%\jvm_updater_*.bat`, `%TEMP%\jvm_uninstall_*.bat`, and `%TEMP%\jvm_uninstall_*.ps1`.
  * Staged candidate temporary directories: `%LOCALAPPDATA%\DiamTek\JVM\candidates\*\temp_*`.
  * Temporary download staging files: `%LOCALAPPDATA%\DiamTek\JVM\downloads\*`.
  * Ephemeral session cache targets: `%LOCALAPPDATA%\DiamTek\JVM\temp\.jvm_session_target_*`.
* **Safety Guarantee:** `jvm clean` is completely non-destructive. It never modifies your active JDKs, candidate tools, directory junctions, or Windows Registry settings.

#### Environment Slate Wipe (`jvm clear`)
Instantly wipes `JAVA_HOME` and cleanly removes JVM directory junctions and legacy Oracle `javapath` entries from your PATH:
```powershell
# Interactive wipe (prompts for confirmation)
jvm clear

# Headless / CI/CD wipe (bypasses prompt)
jvm clear -y
```
* **Automated Safety Backup:** Before executing destructive registry scrubs, `jvm clear` automatically exports a timestamped `.reg` backup of both User (`HKCU`) and Machine (`HKLM`) environment registries to `%LOCALAPPDATA%\DiamTek\JVM\backups\`.
* **Restoring from Registry Backup:** If you ever need to roll back a clear operation, open `%LOCALAPPDATA%\DiamTek\JVM\backups` in File Explorer (or run `explorer.exe "$env:LOCALAPPDATA\DiamTek\JVM\backups"`), locate `sys_env_<date>_<time>.reg` and `usr_env_<date>_<time>.reg`, and double-click to re-import your previous registry state.

<a id="powershell-profile-hook"></a>
#### PowerShell Profile Hook (`jvm hook`)
Manage the lightweight PowerShell `$PROFILE` auto-sync wrapper function across Windows PowerShell 5.1 and PowerShell 7+ without opening the interactive Settings menu:
```powershell
# Install or update PowerShell profile hook
jvm hook install
# Aliases: jvm hook, jvm hook setup

# Check profile hook status across all detected PowerShell profiles
jvm hook status
# Alias: jvm hook check

# Remove PowerShell profile hook
jvm hook remove
# Alias: jvm hook uninstall
```
* **Seamless Terminal Synchronization:** Once installed, whenever you switch JDKs via `jvm <version>`, the wrapper automatically synchronizes `$env:JAVA_HOME` and `$env:Path` in the active terminal session without requiring you to restart your PowerShell window or launch a new subshell.

<a id="bring-your-own-jdk-byo-jdk"></a>
### Bring Your Own JDK (BYO-JDK)
Manually link an existing, custom JDK directory (or GraalVM native image) into the manager. Linked JDKs automatically integrate into the interactive UI under the "Custom (Local Links)" category:
```powershell
# List all registered custom JDK links, targets, and integrity status:
jvm link

# Link a custom JDK directory into the manager:
jvm link C:\my-custom-jdk my-jdk

# Remove a custom linked JDK:
jvm unlink my-jdk
```
> [!NOTE]
> Custom links are stored as NTFS directory junctions in `%LOCALAPPDATA%\JavaVersionManager\links`. If a linked JDK directory is later deleted or moved, running `jvm link` detects the missing `bin\java.exe` and marks it with a red `[BROKEN]` status indicator.

### Self-Updating
Display your current `jvm.bat` semantic version and build number, and compare it against GitHub to check for engine updates:
```powershell
jvm version
# Aliases: jvm --version, jvm -v
```

Automatically download, cryptographically verify, and atomic-swap the core `jvm.bat` script if a newer version is available:
```powershell
jvm self-update
# Or bypass confirmation prompt for automated CI/maintenance scripts:
jvm self-update -y
# Alias: jvm self-update --yes
```

> **Security & Downgrade Protection:**
> * **SHA-256 Verification:** On the `[Stable]` channel, JVM verifies `install.ps1` and `jvm.bat` against official `SHA256SUMS.txt` digests before execution. Any checksum mismatch immediately halts the update.
> * **Ahead-of-Remote Safety:** If you are running an unreleased development build or local changes ahead of remote (`main` on Nightly or GitHub releases on Stable), JVM warns you with `[ INFO ]` and refuses to downgrade your installation.
> * **Rate-Limit Safe:** Non-blocking fallback architecture automatically handles GitHub unauthenticated API rate limits (60 req/hr) via web redirects and Fastly CDN endpoints.

<a id="update-channels-stable-vs-nightly"></a>
### Update Channels (Stable vs Nightly)
Inspect or toggle the active update channel. The `Stable` (green) channel targets verified, tagged GitHub releases, while the `Nightly` (purple) channel delivers cutting-edge builds directly from the tip of the `main` branch:

| Channel | Badge Color | Target | Verification Model | Recommended For |
| :--- | :--- | :--- | :--- | :--- |
| **🟢 `[Stable]`** | Green | `releases/latest` (Git Tag) | Strict SHA-256 vs `SHA256SUMS.txt` | Primary workstations, production, enterprise |
| **🟣 `[Nightly]`** | Bright Purple | `main` branch (`HEAD`) | Commit SHA & SHA-256 audit log | Contributors, beta testers, previewing new features |

```powershell
# View active update channel, description, and available options:
jvm channel

# Switch to the stable official releases channel (Recommended):
jvm channel stable

# Switch to the cutting-edge nightly channel:
jvm channel nightly

# One-off command channel overrides (without altering saved settings):
jvm self-update nightly
jvm self-update stable
jvm self-update --nightly
jvm self-update --stable
jvm self-update --channel nightly
jvm self-update -c nightly

# Command alias:
jvm update self
```
*Tip: You can also toggle the update channel interactively via Option 4 in the interactive **Settings Menu** (`jvm` -> `Settings`).*

### Self-Uninstallation
Launch the deep uninstallation process directly from the CLI to wipe JVM, environment variables, AppData caches, and installed tools:
```powershell
jvm self-uninstall
# Alias: jvm uninstall-self
```
*(Tip: You can also launch the deep uninstaller from the interactive TUI via Settings (`3`) -> Option 6 (`Uninstall JVM Completely`)).*

### Help & Command Reference
Display the full command-line reference, arguments, and flag overrides directly in your terminal:
```powershell
jvm --help
# Or: jvm help, jvm -h, jvm /?
```

---

<a id="machine-readable-json--offline-modes"></a>
## ⚙️ Machine-Readable JSON & Offline Modes

### 1. JSON Automation Contract (`--json`)
Designed for IDE plugins, custom statusline generators, and orchestration tools. Emits pure JSON to `stdout` without decorative text:
```powershell
jvm current --json
jvm which java --json
jvm list --json
jvm doctor --json
```

### 2. Offline & Air-Gapped Execution Mode (`--offline`)
Enforces a fail-closed network policy. All mutating commands (`install`, `update`, `self-update`) abort with exit code `1` if network access is attempted:
```powershell
# Fails closed immediately without network timeouts:
jvm install 21 --offline

# Read-only commands continue to execute locally:
jvm current --offline
jvm which java --offline
jvm doctor --offline
```

### 3. Emergency State Lock Override (`--no-lock`)
Bypasses the concurrency mutex lock (`%LOCALAPPDATA%\DiamTek\JVM\state.lock`) during emergency recovery scenarios. **Notice:** This flag is unsafe for concurrent operations as it disables mutual exclusion:
```powershell
jvm clean --no-lock
```

<a id="common-workflow-recipes"></a>
## 💡 Common Developer Workflow Recipes

### 1. Setting Up a Fresh Developer Workstation
Install the latest long-term support JDK and build tools in seconds without clicking through web portals:
```powershell
# Install latest LTS JDK (e.g. Adoptium OpenJDK 21) headless
jvm install lts --latest --vendor adoptium -y

# Activate it globally
jvm lts

# Install primary build tools
jvm install maven latest -y
jvm install gradle latest -y

# Verify complete environment health
jvm doctor
```

### 2. Switching Between Multiple Projects
When switching from an older Java 11 / 17 legacy monolith to a Java 21 microservice:
```powershell
# Move into project directory
cd C:\Projects\service-order

# Lock project to Java 21 with Adoptium
jvm pin 21 --vendor adoptium

# Any team member entering this directory simply runs:
jvm
# -> Automatically reads .java-version and activates JDK 21 for that session!
```

### 3. Ephemeral Testing Across Multiple JDKs
Verify that tests pass under multiple JDK versions without modifying global workstation state:
```powershell
# Run Maven test suite against JDK 17
jvm exec 17 -- mvn test

# Run the exact same suite against JDK 21
jvm exec 21 -- mvn test
```

### 4. Auditing and Pruning Workstation Disk Space
Keep your machine clean after major releases or batch updates:
```powershell
# Check for outdated packages and patch them
jvm update --all

# Prune intermediate downloads and cached installers
jvm clean

# Run health diagnostics
jvm doctor
```

---

<a id="cicd-integration-recipes"></a>
## 🤖 CI/CD Automation Recipes

Because DiamTek JVM is 100% native Windows with zero Bash or WSL dependencies, it integrates cleanly into Windows CI runners (such as GitHub Actions `windows-latest` or Azure DevOps pipelines).

### GitHub Actions Workflow Example
```yaml
name: Windows Build & Verification

on: [push, pull_request]

jobs:
  build:
    runs-on: windows-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Install DiamTek JVM
        shell: pwsh
        run: |
          Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/install.ps1" -OutFile "$env:TEMP\install.ps1"
          & "$env:TEMP\install.ps1" -Silent

      - name: Pre-Flight Environment Health Check
        shell: cmd
        run: |
          jvm doctor
          if %ERRORLEVEL% NEQ 0 exit /b 1

      - name: Headless Toolchain Provisioning
        shell: cmd
        run: |
          jvm install 21 --vendor adoptium -y
          jvm 21
          jvm install maven latest -y

      - name: Matrix Test Execution via Ephemeral Subshell
        shell: cmd
        run: |
          jvm exec 21 -- mvn test
```

### Exporting `JAVA_HOME` into Pipeline Output in PowerShell
```powershell
# Query exact java binary path using jvm which
$JavaBin = jvm which
$JavaHome = Split-Path -Parent (Split-Path -Parent $JavaBin)

# Expose to subsequent GitHub Actions steps
Write-Output "JAVA_HOME=$JavaHome" | Out-File -FilePath $env:GITHUB_ENV -Append
Write-Output "Resolved JAVA_HOME to: $JavaHome"
```

### Checking Process Exit Codes in Automation Scripts
All DiamTek JVM subcommands (`clean`, `which`, `doctor`, `open`, `exec`, `hook`, `clear`, `channel`, `pin`, `install`, `uninstall`, `use`) strictly propagate deterministic exit codes across batch scope boundaries (`CWE-252` / `CWE-754`):
- `0`: Operation succeeded cleanly.
- `1`: Operation aborted, target not found, syntax error, or validation failure.
- `1602`: Operation canceled by user.
- `1603`: Fatal system error.

**PowerShell Automation:**
```powershell
# jvm which returns 0 on success, 1 if binary not installed
$javaBin = jvm which java
if ($LASTEXITCODE -ne 0) {
    Write-Error "java binary not found under active JVM environment!"
    exit 1
}

# jvm doctor returns 0 for clean health, 1 if warnings/conflicts detected
jvm doctor
if ($LASTEXITCODE -ne 0) {
    Write-Error "Pre-flight JVM environment audit failed with warnings!"
    exit 1
}
```

**Command Prompt / Batch Automation:**
```cmd
jvm which mvn >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Apache Maven is not installed or active!
    exit /b 1
)
```

### ANSI Color Suppression in CI Logs & File Redirection (`NO_COLOR`)
Modern CI/CD runners (GitHub Actions, Azure DevOps, GitLab CI, Jenkins) and automated parsing scripts require clean text output without ANSI terminal color codes (like `ESC[92m`).

DiamTek JVM adheres strictly to the cross-tool [NO_COLOR specification](https://no-color.org). When the `NO_COLOR` environment variable is present and non-empty (or when the `--no-color` CLI flag is used), all ANSI formatting is completely disabled:

```powershell
# Option 1: Global CI environment variable in GitHub Actions / Azure Pipelines
env:
  NO_COLOR: "1"

# Option 2: Headless command-line flag override
jvm list --no-color

# Option 3: Redirecting clean output to a file without escape sequence pollution
jvm list --no-color > installed-jdks.txt
```

### Automating Per-Directory Environment Reloads (`jvm env`)
In headless automation scripts or local development flows that traverse multiple repositories, you can instantly refresh the terminal's `JAVA_HOME` and `PATH` to match the current directory's `.java-version` or `.sdkmanrc` by running:
```powershell
jvm env
```
This inspects the active directory tree and applies the pinned version to the current process without opening interactive dialogs or requiring administrator elevation.

---

[← Back to Documentation Overview](../README.md#documentation)