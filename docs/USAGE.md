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
- [Cryptographic Provenance Verification (jvm verify)](#cryptographic-provenance-verification)
- [Transactional Installations (jvm transaction)](#transactional-installations)
- [IDE & Build Tool Integration](#ide--build-tool-integration)
- [Bring Your Own JDK (jvm link)](#bring-your-own-jdk-byo-jdk)
- [Global Environment Management](#global-environment-management)
- [Diagnostic Health Audit & Self-Healing (jvm doctor)](#diagnostic-health-audit)
- [Unified Configuration Engine (jvm config)](#unified-configuration-engine)
- [Project Toolchains (.jvm.toml / .jvmrc & jvm project)](#project-toolchain-configuration)
- [Environment Diff Inspection (jvm env --diff)](#environment-diff-inspection)
- [Content-Addressed Artifact Cache & Bundling (jvm cache)](#content-addressed-artifact-cache--bundling)
- [Remote Search Engine & Catalog Queries (jvm search & jvm list-remote)](#remote-search-engine--catalog-queries)
- [Compatibility & Release Differences (jvm info & jvm compare)](#compatibility--release-differences)
- [Security-Aware Update Channel (jvm update --security)](#security-aware-update-channel)
- [Explorer Directory Navigation (jvm open / jvm home)](#explorer-directory-navigation)
- [PowerShell Profile Hook (jvm hook)](#powershell-profile-hook)
- [Machine-Readable JSON & Offline Modes (--json / --offline)](#machine-readable-json--offline-modes)
- [Environment Resolution Graph (jvm why)](#environment-resolution-graph)
- [Deep Candidate Analysis (jvm explain)](#deep-candidate-analysis)
- [Guided Onboarding & Tutorial (jvm welcome / jvm tutorial)](#guided-onboarding--tutorial)
- [Smart Contextual Execution & Toolchain Conflict Detection (jvm run)](#smart-contextual-execution)
- [Script-Friendly Single Values (--short / --numeric / --bin / jvm vendor)](#script-friendly-single-values)
- [Cache Telemetry & Deduplication (jvm cache stats / dedupe)](#cache-telemetry--deduplication)
- [Diagnostic Environment Report & Support Bundles (jvm report / support / doctor --report)](#diagnostic-environment-report--support-bundles)
- [Self-Update History & Rollback (jvm self-update --history / --rollback)](#self-update-history--rollback)
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
| `jvm lock --check` | Project | Audits `.jvm.lock` manifest for JSON schema integrity, platform support, and configuration drift. |
| `jvm lock --diff` | Project | Compares `.jvm.lock` definitions against the active environment in a structured table. |
| `jvm lock --update` | Project | Queries upstream vendor APIs to refresh checksums and metadata in `.jvm.lock`. |
| `jvm verify [version/all]` | Audit | Audits cryptographic provenance, HTTPS transport, host trust, SHA-256 digests, and Authenticode signatures (distinguishes verified, unavailable, and failed states). |
| `jvm transaction show` | System | Displays atomic transaction log table with status flags (`COMMITTED`, `ROLLED_BACK`, `IN_PROGRESS`). |
| `jvm transaction rollback <id>` | System | Atomically rolls back an interrupted installation, restoring pre-state directory junctions, target artifacts, and locks (`jvm txn rollback`). |
| `jvm install <tool> [version]` | User | Installs ecosystem tool (omitting version defaults to `latest`; e.g., `jvm install maven`, `jvm install gradle 8.9`; accepts `-y`). |
| `jvm <tool> <version>` | User | Switches active ecosystem tool version (e.g., `jvm kotlin 2.0.20`, `jvm maven 3.9.6`). |
| `jvm update <version>` | Machine | Checks for and applies vendor patches to a specific installed JDK (e.g., `jvm update 21`). |
| `jvm update <version> --security` | Machine | Restricts automatic patch updates strictly to explicit CVE security releases. |
| `jvm update --all [--vendor <name>]` | Machine | Silently checks and patches all installed JDKs and tools to latest releases. |
| `jvm cache [list/size/stats/dedupe/clean/prune]` | Maintenance | Inspects inventory, telemetry (`stats`), de-duplicates blobs (`dedupe`), or purges CAS store. |
| `jvm cache export [--bundle <path>]` | Bundling | Bundles central artifact cache into an offline `.jvmcache` zip container. |
| `jvm cache import <bundle-path>` | Bundling | Safely extracts and validates offline cache bundle into CAS (Zip Slip & SHA-256 verified). |
| `jvm search [candidate] <query>` | Remote | Queries upstream vendor release catalogs (e.g., `jvm search 21`, `jvm search gradle 8`, `--json`). |
| `jvm list-remote [candidate]` | Remote | Displays available remote releases with exact vendor build tags and LTS designations. |
| `jvm info [version]` | Inspection | Outputs architecture, VM type, release date, LTS status, and CVE security classification. |
| `jvm compare <v1> <v2>` | Inspection | Compares release differences, multi-LTS milestone JEP chains (8->11->17->21->25), and bytecode specs. |
| `jvm uninstall` | Interactive | Opens interactive JDK uninstaller selection list (marks `[ACTIVE]` runtime, includes Cancel option; supports `--vendor` filter; aliases: `jvm rm`, `jvm remove`). |
| `jvm uninstall <version> [--vendor <name>]` | Machine | Uninstalls a specific installed JDK (aliases: `jvm rm <version>`, `jvm remove <version>`). |
| `jvm uninstall <tool> [version]` | User | Uninstalls an ecosystem tool (auto-detects single installed version, or prompts with interactive menu if multiple). |
| `jvm list` | Inspection | Lists all installed JDKs, vendors, paths, and ecosystem build tools (alias: `jvm ls`). |
| `jvm current` | Inspection | Displays comprehensive status card: active JDK, mode, junction target, and tools (aliases: `jvm status`, `jvm info`, `jvm whoami`, `jvm env`). |
| `jvm which [candidate]` | Inspection | Prints absolute filesystem path to active `java.exe` or ecosystem binary (alias: `jvm path`). |
| `jvm doctor` | Diagnostic | Deep system health audit: permissions, junctions, registry sync, PATH shadowing, and hooks (alias: `jvm check`). |
| `jvm hook [install/remove/status]` | Shell | Manage PowerShell profile auto-sync wrapper hook (`install`, `setup`, `status`, `check`, `remove`). |
| `jvm open [candidate]` | Navigation | Opens active candidate, JDK, or storage root in Windows File Explorer (alias: `jvm home`). |
| `jvm clean` | Maintenance | Safely purges temporary download caches and extraction artifacts to reclaim disk space (alias: `jvm prune`). |
| `jvm clear` | System | Purges `JAVA_HOME` and cleanly removes JVM directory junctions from PATH. |
| `jvm project` | Project | Inspects root `.jvm.toml` / `.jvmrc` toolchain readiness, locks, and component readiness. |
| `jvm config [get/set/reset]` | User | Unified configuration engine managing persistent global defaults (`config.json`). |
| `jvm env [--diff]` | Inspection | Displays active environment or inspects shell delta against persistent registry baselines. |
| `jvm doctor [--fix] [--dry-run]` | Diagnostic | Deep diagnostic health audit with automated self-healing repairs for orphaned junctions and shadowed paths. |
| `jvm doctor --report` | Diagnostic | Automatically runs pre-flight audit and packages report, logs, and configs into `jvm-issue-bundle.zip`. |
| `jvm why` | Inspection | Explains active Java resolution via 7-tier decision graph (`SESSION`, `.java-version`, `.jvm.toml`, lockfile, config, junction, system PATH). |
| `jvm explain <candidate>` | Inspection | Deep 7-layer architectural inspection of candidate runtime (type, storage, junction, env bindings, DACL, lockfile, CAS provenance). |
| `jvm welcome` (or `jvm tutorial`) | Guided | Runs built-in interactive tour through architecture, workflows, candidate management, and security guarantees. |
| `jvm run <task> [args...]` | Contextual | Smart contextual execution: detects build system (`mvnw`, `gradlew`, Maven, Gradle) and audits toolchain version compatibility before dispatching task. |
| `jvm vendor [--short]` | Inspection | Displays active JDK vendor distribution name (passing `--short` emits lowercase identifier, e.g. `adoptium`). |
| `jvm current --short` | Scripting | Emits bare version string (e.g. `21.0.2` or `21`) without headers or ANSI styling for shell prompts and CI scripts. |
| `jvm current --numeric` | Scripting | Emits raw integer major version number (e.g. `21`) for build matrices. |
| `jvm current --bin` | Scripting | Emits absolute filesystem path to active `java.exe` binary. |
| `jvm cache stats` (or `--stats`) | Maintenance | Displays Content-Addressed Storage telemetry table: blob counts, disk footprints, and retention policies. |
| `jvm cache dedupe` | Maintenance | Scans CAS artifact store for duplicate binaries and reclaims redundant storage space. |
| `jvm report` | Diagnostic | Generates a comprehensive, redacted diagnostic environment report (`jvm-report.txt`). |
| `jvm support` | Support | Generates a complete diagnostic support bundle (`jvm-support-bundle.zip`) for troubleshooting. |
| `jvm self-update --history` | Tool | Displays history table of all stored backup versions of `jvm.bat` with timestamps and paths. |
| `jvm self-update --rollback` | Tool | Atomically restores the previous working version of `jvm.bat` from backup with integrity verification. |
| `jvm link [path] [name]` | Custom | Registers an external custom JDK (or lists all registered links with target paths if run without arguments). |
| `jvm unlink <name>` | Custom | Unregisters a custom linked JDK from the manager. |
| `jvm version` | Tool | Displays current JVM version, build number, and checks GitHub for updates (`--version`, `-v`). |
| `jvm channel [stable/nightly]` | Tool | Displays or switches the update channel between `Stable` (official releases) and `Nightly` (main branch). |
| `jvm self-update` | Tool | Automatically downloads and atomic-swaps `jvm.bat` to the latest release. |
| `jvm self-uninstall` | System | Triggers deep UAC-elevated system uninstaller (`uninstall.ps1`, `jvm uninstall-self`). |
| `jvm <command> --offline` | Flag | Air-gapped / offline execution mode: strictly blocks network calls and executes local commands safely. |
| `jvm <command> --dry-run` | Flag | Simulates mutating operations (`uninstall`, `clean`, `clear`, `update --all`, `self-update`, `doctor --fix`) without modifying filesystem or registry. |
| `jvm <command> --quiet` (or `-q`) | Flag | Suppresses decorative headers, banners, and progress telemetry for clean scripting. |
| `jvm <command> --verbose` | Flag | Emits verbose diagnostic output, subshell telemetry, and network resolution logs. |
| `jvm auto-switch` (or `--auto-switch`) | Hook / Shell | Triggers directory-level auto-switch evaluation for `.java-version`, `.sdkmanrc`, and `.jvm.toml`. |
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
| `jvm <Tab>` / `jvm.bat <Tab>` / `.\jvm.bat <Tab>` | Subcommands, candidates, & global flags | `list`, `ls`, `install`, `uninstall`, `rm`, `use`, `pin`, `current`, `doctor`, `clean`, `channel`, `lock`, `config`, `project`, `cache`, `search`, `compare`, `list-remote`, `why`, `explain`, `welcome`, `tutorial`, `run`, `vendor`, `report`, `support`, `auto-switch`, `java`, `maven`, `gradle`, etc. |
| `jvm channel <Tab>` / `jvm --channel <Tab>` | Delivery update channel targets | `stable`, `nightly` |
| `jvm open <Tab>` | Known filesystem navigation targets | `home`, `dir`, `bin`, `config`, `cache`, `downloads`, `backup`, `backups`, `links` |
| `jvm hook <Tab>` | Profile hook lifecycle management actions | `install`, `status`, `check`, `remove`, `uninstall` |
| `jvm --vendor <Tab>` | Certified JDK upstream distribution vendors | `adoptium`, `temurin`, `oracle`, `corretto`, `zulu`, `microsoft`, `graalvm`, `liberica`, `bellsoft`, `semeru`, `ibm`, `openj9`, `sapmachine`, `sap`, `mandrel`, `dragonwell`, `alibaba`, `kona`, `tencent` |
| `jvm use <Tab>` | Dynamically discovered installed versions | Scans `%LOCALAPPDATA%\JavaVersionManager\links` and `%USERPROFILE%\.jdks` in real-time |
| `jvm pin <Tab>` | Dynamically discovered installed versions | Autocompletes installed JDK version tags for `.java-version` creation |
| `jvm uninstall <Tab>` | Installed JDKs and candidates | Autocompletes installed version tags for targeted uninstallation |
| `jvm --<Tab>` | CLI flag overrides | `--vendor`, `--symlink`, `--registry`, `--legacy`, `--session`, `--global`, `--skip-checksum`, `--no-verify`, `--latest`, `--yes`, `-y`, `--no-color`, `--offline`, `--json`, `--no-lock`, `--locked`, `-l`, `--check`, `--diff`, `--update`, `--fix`, `--dry-run`, `--quiet`, `-q`, `--verbose`, `--auto-switch`, `--channel`, `--nightly`, `--stable`, `--security`, `--bundle`, `--mirror`, `--version`, `--help`, `--short`, `--numeric`, `--bin`, `--stats`, `--rollback`, `--history`, `--report` |

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

# 3. Audit lockfile integrity and platform compatibility
jvm lock --check

# 4. Compare locked tool versions against active environment
jvm lock --diff

# 5. Check upstream vendors for updates to locked tools
jvm lock --update

# 6. Headless installation of locked tools across CI/CD or new machines
jvm install --locked
# Shorthand alias:
jvm install -l
```

### The `.jvm.lock` Schema (Schema v2)
When generated, `.jvm.lock` is written in UTF-8 without BOM using atomic staged writes (`.stage.<guid>.tmp` -> `.jvm.lock`) to eliminate partial-write race conditions (`CWE-362`):

```json
{
  "$schema": "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/schemas/jvm.lock.json",
  "schema": 2,
  "lockfile_version": 1,
  "platform": "windows-x64",
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

<a id="cryptographic-provenance-verification"></a>
## 🔐 Cryptographic Provenance Verification (`jvm verify`)

Audit the local integrity and cryptographic chain of trust for any installed runtime or ecosystem tool:

```powershell
# Audit active Java runtime
jvm verify

# Audit a specific installed JDK version
jvm verify 21

# Audit an ecosystem tool
jvm verify maven

# Audit all installed runtimes and candidates
jvm verify all

# Machine-readable provenance audit as pure JSON
jvm verify --json
```

The verification checklist evaluates 6 criteria with explicit status reporting:
1. `[OK]` **Artifact exists:** Binary or JAR present on disk.
2. `[OK]` **HTTPS verified:** Payload downloaded via encrypted TLS 1.2/1.3 transport.
3. `[OK]` **Host trusted:** Origin matched against `Test-TrustedJvmUri` domain whitelist.
4. `[OK]` **SHA-256 verified:** Byte-for-byte integrity verified against release checksums.
5. `[OK]` / `[⚠]` **Signature status:** Verified Authenticode signature, or flagged as unavailable if unsigned.
6. `[OK]` / `[⚠]` **Provenance status:** Cryptographically attested build provenance (SLSA/in-toto), or flagged as unavailable if vendor attestation is not published.

---

<a id="transactional-installations"></a>
## 🔄 Transactional Installations (`jvm transaction`)

DiamTek JVM operates as a crash-safe state machine across downloads, extractions, and activations (`VM-TXN-XXXXXXXXXXXX`). Transactions remain `IN_PROGRESS` through candidate activation and only reach `COMMITTED` once the final runtime verification succeeds:

```powershell
# Display active or recent transaction state
jvm transaction show
# Alias:
jvm txn show

# Rollback an aborted or interrupted transaction
jvm transaction rollback <transaction-id>
# Aliases:
# jvm txn rollback <transaction-id>
# jvm rollback <transaction-id>
# jvm rb <transaction-id>
```

- **Pre-State Capture:** Journals capture `staged_path`, `target_path`, `backup_path`, `junction_path`, and `prev_junction` prior to any disk mutation.
- **Mid-Flight Crash Recovery:** If a process crashes or is killed during activation or replacement, `jvm transaction rollback <id>` restores the original directory junction and cleans up staged artifacts.
- **Delayed Backup Garbage-Collection:** Existing installation backups are retained until after the transaction is fully committed.

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
#### 🩺 Diagnostic Health Audit & Self-Healing (`jvm doctor`)
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

**Automated Safe Self-Healing (`--fix` & `--dry-run`):**
When issues are found, `jvm doctor` can automatically heal broken junctions and purge PATH shadows:
```powershell
# Preview repairs without touching disk or registry
jvm doctor --fix --dry-run

# Run automated safe repairs
jvm doctor --fix
```

**Exit Codes for Automated Health Checks:**
- `0`: All diagnostic health checks passed with zero conflicts.
- `1`: One or more warnings or misconfigurations detected.

---

<a id="unified-configuration-engine"></a>
## ⚙️ Unified Configuration Engine (`jvm config`)

DiamTek JVM manages persistent user configuration settings in `%LOCALAPPDATA%\DiamTek\JVM\config.json`. This eliminates the need to specify command-line flags on every run:

```powershell
# List all active configuration key-value pairs
jvm config

# Query a specific setting value
jvm config get timeout
jvm config get default_vendor

# Update a setting
jvm config set default_vendor corretto
jvm config set timeout 30
jvm config set telemetry false

# Reset configuration to factory defaults
jvm config reset
```

### Configurable Keys Reference
| Key | Type | Default | Description |
|---|---|---|---|
| `default_vendor` | String | `adoptium` | Default upstream JDK vendor used when `--vendor` is omitted. |
| `mode` | String | `symlink` | Default switching mode (`symlink` or `direct`). |
| `channel` | String | `stable` | Default update channel (`stable` or `nightly`). |
| `auto_update_check` | Boolean | `true` | Enables background update availability checks. |
| `auto_switch` | Boolean | `true` | Enables directory-level auto-switching (`.jvm.toml` / `.java-version`). |
| `color` | Boolean | `true` | Enables ANSI color escape sequences in output. |
| `telemetry` | Boolean | `false` | Controls telemetry collection. |
| `cache_size` | String | `2GB` | Maximum target cache boundary for package archives. |
| `retries` | Integer | `3` | Maximum network retry attempts for package downloads. |
| `timeout` | Integer | `15` | Default HTTP request timeout in seconds. |
| `mirror` | String | `""` | Custom URL for routing remote artifact downloads. |

---

<a id="project-toolchain-configuration"></a>
## 📁 Project Toolchains (.jvm.toml / .jvmrc & jvm project)

In addition to `.java-version` files, JVM supports multi-tool project configuration files (`.jvm.toml` and `.jvmrc`).

### Example Configuration (`.jvm.toml` / `.jvmrc`)
```toml
[java]
version = "21"
vendor = "adoptium"

[maven]
version = "3.9.11"

[gradle]
version = "8.10.2"
```

### Inspecting Project Readiness
Run `jvm project` inside any project root to inspect toolchain versions and verify readiness:
```cmd
jvm project
```

**Output:**
```text
[  INFO  ] Project Configuration: C:\Projects\demo\.jvm.toml
============================================================
  {TOOL}          {REQUESTED}      {RESOLVED/STATUS}
------------------------------------------------------------
  java           21               READY
  maven          3.9.11           READY
  gradle         8.10.2           READY
============================================================
```

When you enter a directory containing `.jvm.toml` or `.jvmrc`, JVM automatically switches the session environment for your tools across both PowerShell and Command Prompt.

---

<a id="environment-diff-inspection"></a>
## 🔍 Environment Diff Inspection (jvm env --diff)

Inspect live process overrides against system registry baselines without changing state:

```cmd
jvm env --diff
```

**Output:**
```text
Environment Changes ──────────────────────────────────────────
  JAVA_HOME  - C:\Program Files\Java\jdk-17
             + C:\Users\User\AppData\Local\DiamTek\JVM\current
  PATH       - C:\Program Files\Java\jdk-17\bin
             + C:\Users\User\AppData\Local\DiamTek\JVM\current\bin
------------------------------------------------------------
```

---

<a id="automated-doctor-self-healing"></a>
## 🩹 Automated Doctor Self-Healing (jvm doctor --fix)

Repair broken directory junctions and purge stale PATH shadows automatically:

```cmd
# Preview pending repairs without modifying the system:
jvm doctor --fix --dry-run

# Execute automated safe repairs:
jvm doctor --fix
```

### Repair Actions Performed
1. **Orphaned Directory Junctions:** If `%LOCALAPPDATA%\DiamTek\JVM\current` points to a missing JDK directory, `--fix` removes the broken reparse point.
2. **PATH Shadow Remediation:** If legacy Oracle `javapath` entries precede JVM in your PATH, `--fix` purges them.

---

<a id="content-addressed-artifact-cache--bundling"></a>
## 📦 Content-Addressed Artifact Cache & Bundling (`jvm cache`)

DiamTek JVM indexes all downloads inside a Content-Addressed Storage (CAS) layout at `%LOCALAPPDATA%\DiamTek\JVM\cache\` (`sha256\xx\xxxx...`):

```powershell
# List cached artifacts and disk footprint
jvm cache list

# Measure total cache size on disk
jvm cache size

# View detailed cache telemetry and storage policy compliance
jvm cache stats

# Identify and de-duplicate redundant download blobs
jvm cache dedupe

# Prune unreferenced cache blobs older than 30 days
jvm cache prune

# Purge the local artifact cache
jvm cache clean

# Bundle local cache for air-gapped transport
jvm cache export --bundle .\build-cache.jvmcache

# Import and validate an offline cache bundle
jvm cache import .\build-cache.jvmcache
```

When importing cache bundles (`jvm cache import`), JVM enforces rigorous security verification:
- **Zip Slip & Path Traversal Containment (`CWE-22`):** Validates entry destinations to ensure all files remain strictly bounded within the target cache directory.
- **Reparse Point Rejection (`CWE-59`):** Rejects symlinks and directory junctions within the bundle and ensures target locations are physical directories.
- **CAS Cryptographic Validation (`CWE-494`):** Re-computes and verifies SHA-256 hashes of all payloads destined for the `sha256/` content-addressed store.
- **Concurrency & Fail-Safe Rollback (`CWE-362` / `CWE-460`):** Coordinates across processes via `state.lock` with atomic rollback and cleanup if extraction fails or is aborted.

When operating with `--offline`, `jvm install <version> --offline` bypasses remote network calls and provisions runtimes directly from this CAS repository.

---

<a id="remote-search-engine--catalog-queries"></a>
## 🔎 Remote Search Engine & Catalog Queries (`jvm search` & `jvm list-remote`)

Query upstream vendor distribution repositories without opening a web browser:

```powershell
# Shorthand version search (defaults candidate to java)
jvm search 21

# Search across Adoptium releases
jvm search java 25

# Query specific vendors (adoptium, zulu, sapmachine)
jvm search java 21 --vendor zulu

# Search ecosystem tool candidate releases
jvm search gradle 8
jvm search maven 3.9

# Emit machine-readable JSON for scripting and automation
jvm search java 21 --json

# List remote releases with exact build tags and LTS markers
jvm list-remote java
```

The search engine respects custom mirrors configured via `jvm config set mirror <url>` while enforcing strict checksum verification.

---

<a id="compatibility--release-differences"></a>
## ⚖️ Compatibility & Release Differences (`jvm info` & `jvm compare`)

Inspect release metadata and evaluate feature deltas between major Java platform specifications:

```powershell
# Inspect active or specified JDK release metadata
jvm info
jvm info 21

# Compare feature sets and JEP differences between adjacent releases
jvm compare 17 21
jvm compare 21 25

# Chained multi-LTS milestone comparison across major platform leaps
jvm compare 8 21
```

`jvm info` displays architecture, Virtual Machine implementation, release date, LTS status, and security patch classification. `jvm compare` outputs a structured comparison highlighting introduced JEPs, API enhancements, finalized language features, chained multi-LTS milestone progressions (`8 -> 11 -> 17 -> 21 -> 25`), and Java classfile format bytecode specifications (e.g., classfile versions 52 through 69).

---

<a id="security-aware-update-channel"></a>
## 🛡️ Security-Aware Update Channel (`jvm update --security`)

Restrict automated update routines strictly to explicit CVE security patches (Critical Patch Updates), ignoring standard maintenance builds:

```powershell
# Update only if a newer build represents an active security patch
jvm update 21 --security

# Apply to all installed runtimes in automation pipelines
jvm update --all --security
```

When no CVE security update is detected, JVM informs the caller and safely bypasses installation without modifying the system environment.

---

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

### 4. Dry-Run Simulation Mode (`--dry-run`)
Executes mutating commands in read-only simulation mode. Inspects resolution targets, checks files, and reports the actions that would be executed without touching the filesystem, directory junctions, or registry:
```powershell
# Preview candidate uninstallation without removing files:
jvm uninstall 21 --vendor adoptium --dry-run
jvm uninstall maven 3.9.9 --dry-run

# Preview cache and temporary artifact purging:
jvm clean --dry-run

# Preview environment variable clearing:
jvm clear --dry-run

# Preview batch updates across all runtimes:
jvm update --all --dry-run

# Preview diagnostic self-healing repairs:
jvm doctor --fix --dry-run
```

### 5. Quiet / Silent Automation Mode (`--quiet` / `-q`)
Designed for non-interactive scripts and CI runners. Suppresses decorative ASCII banners, welcome headers, and progress spinners. Essential status information, errors, and process exit codes are cleanly emitted:
```powershell
# Quietly activate a JDK version:
jvm 21 -q

# Quietly query path or list:
jvm which java --quiet
```

### 6. Verbose Diagnostics Mode (`--verbose`)
Enables comprehensive telemetry and diagnostic logging across the engine. Emits download URLs, HTTP request headers, range resume offsets, SHA-256 verification stages, subshell environment deltas, and timing phases:
```powershell
jvm install 21 --vendor adoptium --verbose
jvm verify 21 --verbose
```

### 7. Contextual Actionable Errors Subsystem
Every error emitted by DiamTek JVM follows a standardized, 4-part actionable template designed to eliminate guesswork:
- **Title (`[ ERROR ]`)**: Clear description of what failed.
- **Reason (`[ REASON ]`)**: Technical root cause explaining why the failure occurred.
- **State Impact (`[ STATE ]`)**: Explicit confirmation of filesystem and environment impact (e.g., *"No files were modified. Active candidate environment remains untouched."*).
- **Remediation (`[ REMEDY ]`)**: Concrete, actionable CLI commands to resolve the issue.

```text
[ ERROR  ] Candidate 'maven' version '4.0.0-alpha' is not installed!
[ REASON ] The candidate folder could not be located in %LOCALAPPDATA%\DiamTek\JVM\candidates\maven\4.0.0-alpha.
[ STATE  ] No files were modified. Active candidate environment remains untouched.
[ REMEDY ] Run 'jvm list maven' to view installed versions, or run 'jvm install maven 4.0.0-alpha' to install it.
```

When `--json` is supplied, errors are automatically serialized into structured JSON:
```json
{
  "status": "error",
  "code": 3,
  "error": {
    "title": "Candidate 'maven' version '4.0.0-alpha' is not installed!",
    "reason": "The candidate folder could not be located in %LOCALAPPDATA%\\DiamTek\\JVM\\candidates\\maven\\4.0.0-alpha.",
    "state": "No files were modified. Active candidate environment remains untouched.",
    "remedy": "Run 'jvm list maven' to view installed versions, or run 'jvm install maven 4.0.0-alpha' to install it."
  }
}
```

<a id="environment-resolution-graph"></a>
## 🧭 Environment Resolution Graph (`jvm why`)

Ever wonder why a specific Java runtime is active in your terminal? `jvm why` inspects the entire 7-tier precedence hierarchy in real-time, pinpointing the exact origin and rule that selected the active JDK:

```cmd
jvm why
```

### Precedence Resolution Hierarchy
1. **Tier 1 (CLI / Session Override):** Ephemeral environment variable override in the active shell session (`.jvm_session_target_*`).
2. **Tier 2 (Directory `.java-version`):** Nearest parent directory containing a `.java-version` specification.
3. **Tier 3 (Directory `.sdkmanrc`):** Nearest parent directory containing a `.sdkmanrc` SDKMAN! configuration file.
4. **Tier 4 (Project `.jvm.toml` / `.jvmrc`):** Nearest root project descriptor specifying JDK requirements.
5. **Tier 5 (Reproducible `.jvm.lock`):** Cryptographic lockfile pinning candidate, vendor, and checksum.
6. **Tier 6 (Global Config / Junction):** User default selection configured in `config.json` or active NTFS junction link (`%LOCALAPPDATA%\DiamTek\JVM\current`).
7. **Tier 7 (System PATH Fallback):** Legacy registry or global Windows `PATH` fallback.

```text
================================================================================
 JVM Environment Resolution Explainer (7-Tier Graph)
================================================================================
 Active Java Version: 21.0.2 (Adoptium)
 Active Binary:        C:\Users\username\AppData\Local\DiamTek\JVM\current\bin\java.exe
 Mode:                 Symlink Junction Mode

 Precedence Hierarchy Check:
   [MATCH] Tier 2: Directory .java-version file detected in C:\Projects\my-app (pin: 21)
   [SKIP ] Tier 1: Ephemeral subshell session override (not set)
   [PASS ] Tier 3: Directory .sdkmanrc file
   [PASS ] Tier 4: Project .jvm.toml configuration
   [PASS ] Tier 5: Project .jvm.lock manifest
   [PASS ] Tier 6: User global default (config.json)
   [PASS ] Tier 7: System PATH fallback
================================================================================
 Resolution Reason: Directory level .java-version pinned version '21' took precedence.
```

---

<a id="deep-candidate-analysis"></a>
## 🔬 Deep Candidate Analysis (`jvm explain`)

Perform deep 7-layer architectural inspection across any installed candidate runtime or ecosystem tool:

```powershell
jvm explain java
jvm explain maven
jvm explain gradle
```

### 7-Layer Architectural Inspection
1. **Layer 1 - Candidate Identity:** Candidate name, runtime classification, and candidate type.
2. **Layer 2 - Storage Hierarchy:** On-disk storage location and installed version count.
3. **Layer 3 - Junction Link Status:** Reparse point target path and link integrity status.
4. **Layer 4 - Shell Bindings:** Associated environment variables (`JAVA_HOME`, `M2_HOME`, `GRADLE_HOME`) and resolved binary paths.
5. **Layer 5 - Security DACL Integrity:** NT Authority, System, Administrator, and User Access Control List (DACL) verification (`CWE-276`).
6. **Layer 6 - Lockfile & Manifest Status:** Current directory `.jvm.lock` and `.jvm.toml` presence.
7. **Layer 7 - Provenance & Checksum Record:** Verified Content-Addressed Storage (CAS) artifact digests in `%LOCALAPPDATA%\DiamTek\JVM\cache\sha256\`.

---

<a id="guided-onboarding--tutorial"></a>
## 🎓 Guided Onboarding & Interactive Tutorial (`jvm welcome` / `jvm tutorial`)

New to DiamTek JVM or setting up a developer workstation? Launch the built-in interactive tutorial and onboarding guide:

```cmd
jvm welcome
# Or:
jvm tutorial
```

The guided tour walks developers through:
1. **Architecture & Modes:** Explains Symlink Junction Mode (UAC-Free) vs. Legacy Registry Mode.
2. **Essential Commands:** Quick switches (`jvm 21`), directory pins (`jvm pin 21`), and ecosystem tools (`jvm install maven`).
3. **Security Standards:** Cryptographic Authenticode validation, SHA-256 CAS deduplication, and privilege isolation.
4. **Directory Transparency:** Exact paths where binaries, links, caches, and configuration are persisted.

*Note: On fresh installations, the onboarding banner appears automatically until the environment is initialized (`.initialized`).*

---

<a id="smart-contextual-execution"></a>
## ⚡ Smart Contextual Execution & Toolchain Conflict Detection (`jvm run`)

Streamline your build tasks without remembering which wrapper script or build tool is configured in the current project:

```cmd
jvm run build
jvm run test
jvm run compile
```

### Contextual Runner Dispatch Matrix
`jvm run` inspects the project directory and dispatches execution through the optimal tool:
- **`mvnw.cmd` / `mvnw.bat`:** If Maven Wrapper is present, delegates to wrapper with arguments.
- **`gradlew.bat` / `gradlew.cmd`:** If Gradle Wrapper is present, delegates to wrapper.
- **`pom.xml`:** If Apache Maven descriptor is found, invokes installed `mvn`.
- **`build.gradle` / `build.gradle.kts`:** If Gradle buildscript is found, invokes installed `gradle`.
- **Custom / Raw Commands:** If none match, directly invokes the command in the active JVM environment.

### Proactive Toolchain Conflict Detection
Before dispatching builds, `jvm run` audits your toolchain for version incompatibilities:
- **Gradle Wrapper vs. Java Matrix:** Warns if an older Gradle wrapper (e.g. `< 8.5`) is executed against Java 21+, or `< 9.0` against Java 25+.
- **Maven Compiler Target Audit:** Inspects `pom.xml` for `<maven.compiler.target>` or `<java.version>` and alerts you if the target version exceeds the active Java runtime.

---

<a id="script-friendly-single-values"></a>
## 🏎️ Script-Friendly Single Values (`--short`, `--numeric`, `--bin`, `jvm vendor`)

Integrate DiamTek JVM directly into starship prompt widgets, PowerShell profile statuslines, bash/zsh prompts, and CI/CD matrix generators without complex regex parsing:

```powershell
# 1. Concise version string (e.g., '21.0.2' or '21')
jvm current --short

# 2. Raw integer major version number (e.g., '21')
jvm current --numeric

# 3. Absolute path to active java.exe binary
jvm current --bin

# 4. Active vendor distribution name (e.g., 'Adoptium' or 'adoptium')
jvm vendor
jvm vendor --short
```

**Prompt Statusline Integration Example (PowerShell `$PROFILE`):**
```powershell
function prompt {
    $ver = jvm current --short
    $vendor = jvm vendor --short
    "[$vendor $ver] PS $pwd> "
}
```

---

<a id="cache-telemetry--deduplication"></a>
## 📊 Cache Telemetry & Deduplication (`jvm cache stats` & `jvm cache dedupe`)

Gain full visibility into your local Content-Addressed Storage (CAS) footprint and eliminate duplicate JDK binaries across candidate installations:

```powershell
# Detailed CAS storage telemetry table
jvm cache stats
# Or:
jvm cache --stats

# Content-addressed duplicate scanner & space reclamation
jvm cache dedupe
```

`jvm cache stats` outputs a clean aligned table itemizing blob count, disk usage, and retention policies across SHA-256 artifacts, JDK archives, Maven, Gradle, and Kotlin tool distributions. `jvm cache dedupe` computes cryptographic hashes across cached artifacts, identifying identical files and optimizing storage.

---

<a id="diagnostic-environment-report--support-bundles"></a>
## 🩺 Diagnostic Environment Report & Support Bundles (`jvm report`, `jvm doctor --report`, `jvm support`)

When troubleshooting complex workstation issues or submitting bug reports on GitHub, generate complete, sanitized diagnostic packages with a single command:

```powershell
# 1. Generate sanitized, redacted plain text diagnostic report
jvm report
# -> Outputs: jvm-report.txt (usernames, tokens, and secrets automatically redacted)

# 2. Run doctor audit and generate complete issue bundle
jvm doctor --report
# -> Outputs: jvm-issue-bundle.zip containing report, configs, and ownership manifests

# 3. Comprehensive support bundle generator
jvm support
# -> Outputs: jvm-support-bundle.zip with doctor telemetry, environment report, and config
```

### Security & Privacy Protections
All diagnostic report generators enforce strict information redaction (`CWE-209` / `CWE-532`):
- User account paths (`%USERNAME%`) in `PATH` are replaced with `[REDACTED_USER]`.
- Sensitive environment variables containing tokens, passwords, keys, or secret credentials are wiped from output manifests.

---

<a id="self-update-history--rollback"></a>
## ⏪ Self-Update History & Rollback (`jvm self-update --history` & `--rollback`)

Update with total peace of mind. Every time `jvm self-update` updates the core executable, the previous version is backed up with timestamped metadata:

```powershell
# 1. View all historical engine updates and backups
jvm self-update --history

# 2. Roll back immediately to the previous working build
jvm self-update --rollback
```

### Rollback Guarantees
- **Integrity Pre-Verification:** Before rolling back, `jvm self-update --rollback` validates the backup file for EOF markers (`rem END OF SCRIPT`) to prevent restoring truncated or corrupt binaries.
- **Single-Step Recovery:** Automatically restores `%LOCALAPPDATA%\DiamTek\JVM\bin\jvm.bat` from the most recent valid backup.

---

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
All DiamTek JVM subcommands strictly propagate deterministic, standardized semantic exit codes across batch scope boundaries (`CWE-252` / `CWE-754` / `CWE-755`), enabling robust error detection in CI/CD pipelines, DevOps orchestration, and wrapper scripts:

| Exit Code | Classification | Technical Meaning | Typical Context & Cause |
|:---------:|----------------|-------------------|--------------------------|
| `0` | **Success** | Clean completion | Operation completed successfully with zero errors. |
| `1` | **Generic Failure** | General error | Unhandled system exception, generic failure, or interactive prompt abort. |
| `2` | **Bad Syntax / Arguments** | Invalid CLI invocation | Unrecognized subcommand, invalid flag combination, or malformed syntax. |
| `3` | **Target Not Found** | Missing runtime or tool | Requested JDK version, candidate tool, or target path is not installed or found. |
| `4` | **Network / Download Failure** | Remote transport error | Network unreachable, DNS failure, HTTP 404/5xx, or transfer timeout. |
| `5` | **Integrity / Checksum Failure** | Cryptographic verification failed | SHA-256 hash mismatch, corrupt payload, or Authenticode signature failure. |
| `6` | **Permission / Privilege Failure** | Access denied | Insufficient permissions or missing Administrator elevation for HKLM operations. |
| `7` | **State Lock Timeout** | Mutex lock contention | Mutual exclusion lock (`state.lock`) acquisition timed out after maximum retry window. |
| `8` | **Offline Mode Restriction** | Network policy violation | Network-dependent operation blocked because `--offline` mode is active. |
| `9` | **Configuration Error** | Malformed settings | Schema or parsing validation failure in `config.json`, `.jvm.lock`, or `.jvm.toml`. |
| `10` | **Rollback Occurred** | Transaction compensation | Atomic transaction aborted mid-operation and all staged changes were safely rolled back. |
| `1602` | **User Canceled** | Operation canceled by user | Windows Installer (MSI) wizard was canceled by the user. |
| `1603` | **Fatal System Error** | Windows Installer fatal error | MSI engine encountered an unrecoverable system or file-lock error. |

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