<h1 align="center">Comparison with SDKMAN!</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md)

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
| **Live Broadcasting** | Shell-only (requires `source` or restart) | **Win32 `WM_SETTINGCHANGE` + Live In-Memory Hot Patch** |
| **IDE Support** | Requires WSL bridges | **100% Native** (IntelliJ, Eclipse, VS Code) |
| **Windows Services & GUI**| Inaccessible to Windows services | **Full System Visibility** (Jenkins, SonarQube, Task Scheduler, Start Menu) |
| **Project File Support** | `.sdkmanrc` only | **Dual Support:** `.jvmrc` & Auto **`.sdkmanrc` Translation** |
| **User Interface** | CLI Only (Manual typing) | **Interactive TUI** & Headless CLI |
| **Archive Extraction** | Requires external `zip` / `tar` binaries | **Native `.NET System.IO.Compression`** |
| **Security Validation** | Basic (`curl` downloads) | **Strict `.NET` SHA256/SHA512 Cryptography** |
| **CPU Architecture** | Manual configuration | **Native x64 / ARM64 Auto-Detection** |
| **Bulk Maintenance** | Manual, tool-by-tool | **1-Click Bulk Updater** (`jvm update --all`) |
| **OS Conflict Handling**| Passive | **Active Phantom-Path Scrubbing** |
| **Environment De-activation**| Manual `.bashrc` editing (no de-activate command) | **1-Click Deep Slate Wipe** (`jvm clear`) |
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

[← Back to Documentation Overview](../README.md#documentation)