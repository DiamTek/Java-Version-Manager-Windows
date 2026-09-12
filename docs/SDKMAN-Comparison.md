<h1 align="center">Comparison with SDKMAN!</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md) &nbsp;•&nbsp; [🛡️ Security](SECURITY.md) &nbsp;•&nbsp; [🤝 Contributing](CONTRIBUTING.md) &nbsp;•&nbsp; [💬 Support](SUPPORT.md)

</div>


---

[SDKMAN!](https://sdkman.io/) is the industry standard for managing Java versions and ecosystem tools. However, for native Windows users, it presents strict architectural challenges.

### The Problem with SDKMAN! on Windows
SDKMAN! is a collection of POSIX-compliant Bash scripts. To run it on Windows, developers must install heavy compatibility layers like Windows Subsystem for Linux (WSL), MSYS2, or Git Bash. While this works well for Linux-first workflows, it causes severe friction for native Windows developers:
1. **IDE Disconnect:** JDKs installed *inside* WSL are not easily accessible by native Windows IDEs (like IntelliJ or VS Code) without setting up complex remote-bridge configurations.
2. **I/O Performance:** Crossing the OS boundary between WSL and the native Windows filesystem (`/mnt/c/`) causes notoriously slow read/write speeds, increasing build times for Maven and Gradle.
3. **Environment Variables:** SDKMAN! updates `.bashrc`, which Windows `cmd.exe` and background services completely ignore.

### The Native Windows Alternative
This Java Version Manager (`jvm.bat`) solves this by operating directly on the Windows Registry, native NTFS Directory Junctions, and pure CMD/PowerShell environments.

| Feature | SDKMAN! (on Windows) | Java Version Manager (Native) |
|---------|----------------------|--------------------------------|
| **Runtime** | Bash / `curl` / `zip` | Native Batch / PowerShell / `.NET` |
| **Dependencies** | WSL, Cygwin, or Git Bash | **None** (Works out-of-the-box) |
| **Supported Shells** | Bash / Zsh only (inside compatibility layer) | **CMD, Windows PowerShell, PS Core, Windows Terminal** |
| **I/O Speed** | Slower (Virtualization boundary) | **Maximum** (Native NTFS) |
| **Integration** | `.bash_profile` / `.zshrc` | Windows Registry (`JAVA_HOME`, `PATH`) |
| **Switching Engine** | POSIX Symlinks (requires Developer Mode) | **Dual Engine:** UAC-Free NTFS Junctions & Registry Mode |
| **Switching Syntax** | Verbose candidate slugs (`sdk use java 21.0.2-tem`) | **1-Word Shorthand** (`jvm 21`, `jvm lts`, `jvm latest`) |
| **Live Broadcasting** | Shell-only (requires `source` or restart) | **Win32 `WM_SETTINGCHANGE` + Live In-Memory Hot Patch** |
| **IDE Support** | Requires WSL bridges | **100% Native** (IntelliJ, Eclipse, VS Code) |
| **Windows Services & GUI**| Inaccessible to Windows services | **Full System Visibility** (Jenkins, SonarQube, Task Scheduler, Start Menu) |
| **Project File Support** | `.sdkmanrc` only | **Dual Support:** `.java-version` & Auto **`.sdkmanrc` Translation** |
| **Local JDK Discovery** | Cannot scan Windows folders | **Automatic Local Discovery** (scans `Program Files` for existing JDKs) |
| **Offline Operation** | May lag on remote API latency | **Zero-Ping Local Switching** (100% offline, instant) |
| **Pre-Change Safety** | None (overwrites shell files) | **Automated Registry Backups** (exports `.reg` to `%TEMP%`) |
| **User Interface** | CLI Only (Manual typing) | **Interactive TUI** & Headless CLI |
| **Archive Extraction** | Requires external `zip` / `tar` binaries | **Native `.NET System.IO.Compression`** |
| **Security Validation** | Basic (`curl` downloads) | **Strict `.NET` SHA256/SHA512 Cryptography** |
| **CPU Architecture** | Manual configuration | **Native x64 / ARM64 Auto-Detection** |
| **Bulk Maintenance** | Manual, tool-by-tool | **1-Click Bulk Updater** (`jvm update --all`) |
| **OS Conflict Handling**| Passive | **Active Phantom-Path Scrubbing** |
| **Status & Binary Inspection**| `sdk current` (POSIX shell string) | **`jvm current` & `jvm which`** (Full status card + binary resolver) |
| **Cache & Slate Cleaning**| `sdk flush` (basic temp deletion) | **`jvm clean` & `jvm clear`** (Deep cache purge & registry slate wipe) |
| **Ephemeral Subshell Runner** | None (must switch shell and restore) | **`jvm exec <ver> [--] <cmd>` / `jvm run`** (zero global changes, accurate exit codes) |
| **Diagnostic Health Audit** | None | **`jvm doctor`** (7-point deep conflict, junction, & shadowing analysis) |
| **Project Pinning CLI** | Manual `.sdkmanrc` editing | **`jvm pin [ver]` / `jvm local`** (instant lock writing & display) |
| **Migration Muscle Memory**| `sdk use` / `sdk default` | **`jvm use` / `jvm default`** (1:1 transparent compatible aliases) |
| **File Explorer Jump** | Manual path navigation | **`jvm open [candidate]` / `jvm home`** (Instant GUI explorer jump) |
| **Shell Wrapper Hook** | Manual `source` line in `.bashrc`/`.zshrc` | **`jvm hook`** (Automated install, status, and removal for PS 5.1 & PS 7+) |
| **Enterprise Proxies** | Manual `http_proxy` env exports | **Native Windows WinINet & Corporate Certificate Store** |
| **Windows Packaging** | Unofficial / None | **Winget, Scoop, Chocolatey, & Native MSI** |
| **Enterprise Privileges**| Requires WSL/Bash setup | **Zero-Admin / 0 UAC** (Runs on locked-down corporate laptops) |
| **Corporate Fleet Rollout**| None (Manual shell curl) | **Silent Intune, MECM & GPO MSI** (`msiexec /qn`) |
| **Uninstallation** | Manual script deletion | **Deep UAC Uninstaller & Windows Settings Integration** |

---

## Ecosystem Parity
You don't need SDKMAN! just to get Maven or Gradle on Windows. This tool features a built-in **Universal Candidate Engine** that provides 1:1 ecosystem parity with SDKMAN!. It natively downloads, extracts, and routes modern JVM build tools directly from Apache and GitHub APIs.
* Supported natively: **Maven, Gradle, Kotlin, Scala, Groovy**.

## Cross-Platform Harmony (`.sdkmanrc` Hijacking)
The biggest hurdle for Windows developers is collaborating on repositories maintained by Mac/Linux developers who commit a `.sdkmanrc` file to the root of the project.

This tool completely eliminates that friction. It features a native **`.sdkmanrc` parser** that dynamically "hijacks" SDKMAN! workflows:
1. When you run `jvm` in a folder with a `.sdkmanrc` file, it reads the exact versions requested by the Linux team.
2. It translates SDKMAN! vendor strings (e.g., `17-tem` or `21-amzn`) into their native Windows equivalents (Adoptium, Corretto).
3. It instantly isolates the exact requested JDK, Maven, and Gradle versions into your *current* terminal session.

You get 100% perfect environment synchronization with your Linux teammates, without ever installing a Linux subsystem on your Windows machine.

---

## ⚡ Ergonomic Switching (Shorthand vs Slugs)
In SDKMAN!, switching versions requires knowing and typing the exact candidate slug:
```bash
# SDKMAN! (POSIX syntax)
sdk use java 21.0.2-tem
sdk default java 17.0.10-amzn
```
If you forget the vendor suffix or patch release, you are forced to run `sdk list java`, search through hundreds of lines, and copy-paste the exact string.

DiamTek JVM provides **1-Word Shorthand Ergonomics** alongside transparent SDKMAN! aliases:
```powershell
# DiamTek JVM (Native Windows shorthand)
jvm 21
jvm lts
jvm latest

# SDKMAN! / NVM Migration Aliases (supported 1:1)
jvm use 21
jvm default 21

# Session-isolated switch (matching SDKMAN 'sdk use' semantics)
jvm use 21 --session
```

> **Note on `jvm use` vs `jvm default`:** In SDKMAN!, `sdk use` applies strictly to the current shell while `sdk default` changes the global symlink. In DiamTek JVM, standard switches (`jvm 21`, `jvm use 21`, `jvm default 21`) switch the active JDK globally via the Directory Junction to match the Windows `nvm-windows` convention. To get SDKMAN's session-isolated behavior, simply pass `--session` (`jvm use 21 --session`).

JVM automatically inspects your installed versions and routes to the best installed candidate. If you have multiple distributions installed for the same major version (e.g., both Oracle JDK 21 and Eclipse Temurin 21), JVM pauses and displays an interactive prompt asking you to pick your preferred vendor—or you can override it directly via `--vendor` (e.g., `jvm 21 --vendor adoptium`).

---

## 🚀 Ephemeral Subshell Runner vs Manual SDK Toggling (`jvm exec`)
In SDKMAN!, running a one-off build or test against a different JDK requires switching your current shell (`sdk use java 17...`), executing the build, and then manually switching back (`sdk use java 21...`). If the build crashes or you forget to revert, your shell remains stuck on the wrong Java version.

DiamTek JVM provides native, one-line ephemeral execution:
```powershell
# Runs in an ephemeral child subshell with zero global changes
jvm exec 17 -- mvn clean test
# Alias: jvm run 17 mvn clean test
```
- **Zero Global Side Effects:** Leaves your active Directory Junction (`current`), global Windows Registry, and other terminal windows completely untouched.
- **Strict Exit Code Fidelity:** Captures and propagates the child process's exact exit code (`0` or non-zero) back to the calling shell, ensuring CI/CD and automation runners fail accurately when builds break.

---

## 🩺 Proactive Health Audits vs Silent Breakages (`jvm doctor`)
Windows developers frequently face silent environment breaks caused by rogue MSI installers, broken directory junctions, or mismatched User/Machine registries. SDKMAN! has no diagnostic command to analyze underlying OS health or identify why a tool is malfunctioning.

DiamTek JVM includes `jvm doctor`—an automated 7-point health auditor:
```powershell
jvm doctor
```
- Audits AppData local storage permissions.
- Verifies Directory Junction integrity and `bin\java.exe` target reachability.
- Synchronizes User (`HKCU`) and Machine (`HKLM`) registry states.
- Scans `where.exe java` for legacy Oracle `javapath` and `System32` shadowing.
- Verifies PowerShell `$PROFILE` hook status.
- Returns standard exit code `0` on clean health or `1` on warnings, making it an ideal pre-flight check for enterprise deployment scripts.

---

## 📌 Instant Project Pinning (`jvm pin` / `jvm local`)
In SDKMAN!, locking a project to a specific runtime requires manually writing or updating a `.sdkmanrc` file by hand.

DiamTek JVM provides dedicated CLI commands for project pinning:
```powershell
# Lock project to JDK 21 (.java-version)
jvm pin 21

# Lock with vendor flags
jvm pin 21 --vendor adoptium

# Inspect active project pin
jvm pin
# Alias: jvm local
```
Whenever a developer runs `jvm` inside that directory, JVM automatically reads the `.java-version` file and locks the terminal session to that version without touching the global registry.

---

## 📂 Direct Windows File Explorer Navigation (`jvm open` / `jvm home`)
Finding where a JDK or build tool is physically stored on disk in Windows usually requires traversing hidden `AppData` directories or system folders.

With DiamTek JVM, you can jump directly to any installed runtime or candidate folder in Windows File Explorer:
```powershell
# Open active JDK directory in File Explorer
jvm open

# Open specific tool candidate folder
jvm open maven
jvm open gradle

# Open the JVM storage root
jvm open root
# Alias: jvm home
```

---

## ⚡ Automated Shell Hook Management (`jvm hook` vs POSIX `source`)
In SDKMAN!, integrating with developer shells requires manually maintaining a `source "$HOME/.sdkman/bin/sdkman-init.sh"` block inside `.bashrc` or `.zshrc`. If that initialization script becomes corrupted, debugging it requires manual text editing.

DiamTek JVM provides dedicated, one-command shell hook lifecycle management:
```powershell
# Install or update the auto-sync wrapper hook in PowerShell profiles
jvm hook install

# Check hook status across Windows PowerShell 5.1 and PowerShell 7+
jvm hook status

# Cleanly remove the wrapper hook without touching other profile settings
jvm hook remove
```
- **Automated Multi-Shell Discovery:** Automatically detects and manages both Windows PowerShell (5.1) and modern PowerShell Core (7+) profiles across standard and OneDrive-redirected Documents folders.
- **In-Memory Session Sync:** Whenever you switch JDKs (`jvm 21`), the hook dynamically updates `$env:JAVA_HOME` and `$env:Path` in-memory across the active shell session without restarting your terminal window.

---

## 🔍 Native Inspection & Binary Resolution (`jvm current` & `jvm which`)
When configuring Windows IDEs (IntelliJ IDEA, Eclipse, VS Code), native scripts, or CI/CD pipelines, you need to know where the actual Windows executable is located. Under WSL or Git Bash, `which java` returns a virtualized Linux path (`/home/user/.sdkman/candidates/java/current/bin/java`) that Windows applications cannot resolve without conversion bridges like `wslpath -w`.

DiamTek JVM provides native Windows inspection tools:
* **`jvm current` (or `jvm status`):** Displays a comprehensive overview card detailing the active JDK version, vendor, `JAVA_HOME`, resolved executable, switching mode (`[Symlink Mode]` vs `[Registry Mode]`), junction link, and active ecosystem tools (Maven, Gradle, Kotlin).
* **`jvm which [candidate]` (or `jvm path`):** Prints the absolute Windows filesystem path to the active binary directly to `stdout`. Works seamlessly for Java (`jvm which`) and ecosystem build tools (`jvm which maven`, `jvm which gradle`). Ideal for automation scripts and IDE path configurations:
  ```powershell
  # PowerShell automation
  $javaExe = (jvm which)
  & $javaExe -version
  ```

---

## 🧹 Dual Maintenance: Cache Pruning (`jvm clean`) vs Slate Reset (`jvm clear`)
Managing development environments requires both disk space hygiene and environment sanitization. In SDKMAN!, cache cleanup is limited to `sdk flush`, while de-activating an environment requires manually editing `.bashrc` and deleting symlinks.

DiamTek JVM cleanly decouples these two maintenance workflows:
1. **`jvm clean` (Disk Cache Pruner):** Safely sweeps `%TEMP%` and `%LOCALAPPDATA%\DiamTek\JVM` to purge orphaned `.zip` and `.tar.gz` downloads, temporary extraction trees, and obsolete updater scripts. It calculates and reports the exact number of files deleted and megabytes reclaimed without touching active JDKs or settings.
2. **`jvm clear` (Environment Slate Wipe):** Performs a deep system reset. It removes `JAVA_HOME`, scrubs rogue Oracle `javapath` entries and broken junctions from both User and Machine `PATH`, and restores a clean baseline. To ensure complete safety, `jvm clear` automatically exports a timestamped `.reg` registry backup to `%TEMP%` before executing.

---

## 🛡️ Zero-Risk Backups & 100% Offline Execution
* **Pre-Change Safety:** Unlike POSIX shell scripts that directly overwrite `.bashrc` or `.zshrc`, DiamTek JVM automatically creates a timestamped `.reg` backup in `%TEMP%` before making destructive registry modifications or clearing paths. If you ever need to roll back, simply double-click the `.reg` file to restore your previous environment state.
* **Zero-Ping Local Switching:** SDKMAN! can occasionally lag or stall on poor network connections when running version queries against remote servers. DiamTek JVM executes local version switches 100% offline with zero network latency, making it completely reliable in air-gapped corporate environments, remote locations, and on planes.

---

[← Back to Documentation Overview](../README.md#documentation)