# Comparison with SDKMAN!

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
| **I/O Speed** | Slower (Virtualization boundary) | **Maximum** (Native NTFS) |
| **Integration** | `.bash_profile` / `.zshrc` | Windows Registry (`JAVA_HOME`, `PATH`) |
| **IDE Support** | Requires WSL bridges | **100% Native** (IntelliJ, Eclipse, VS Code) |
| **User Interface** | CLI Only (Manual typing) | **Interactive TUI** & Headless CLI |
| **System Injection**| Shell-only | **Global Registry Hot-Swapping** |
| **Security Validation**| Basic (`curl` downloads) | **Strict `.NET` SHA256/SHA512 Cryptography** |
| **CPU Architecture**| Manual configuration | **Native x64 / ARM64 Auto-Detection** |
| **Bulk Maintenance**| Manual, tool-by-tool | **1-Click Bulk Updater** (`jvm update --all`) |
| **OS Conflict Handling**| Passive | **Active Phantom-Path Scrubbing** |

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