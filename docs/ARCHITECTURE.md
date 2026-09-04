# Architecture & Technical Implementation

This project is a zero-dependency, lightweight, native Windows implementation designed to bypass the traditional complexities of virtualized bash scripts (like SDKMAN!) on Windows operating systems.

## The Core Mechanism: Directory Junctions
Instead of constantly appending and pruning your Windows `PATH` variable to point to different JDK folders (which quickly leads to the 1024-character `PATH` limit and environment variable bloat), the manager maintains a single **Directory Junction** (`mklink /J`) at:

`%LOCALAPPDATA%\DiamTek\JVM\current`

Your system `PATH` only ever needs to contain `%LOCALAPPDATA%\DiamTek\JVM\current\bin`. When you switch Java versions, the manager simply tears down the old junction and repoints it to the target JDK directory. This provides `O(1)` symlink resolution for the OS.

## Deep OS Environment Management
To ensure deep OS integration without requiring users to download external binaries (like `setx` augmentations), the tool relies on inline PowerShell execution invoked seamlessly via `cmd.exe`.

### Global/Machine State (`HKLM`)
- Updates to the global `PATH` and `JAVA_HOME` are performed natively using the .NET framework bridging in PowerShell: 
  `[Environment]::SetEnvironmentVariable('JAVA_HOME', $target, 'Machine')`
- The script detects if it is running in standard user space. If required, it dynamically generates an elevated PowerShell script (`jvm_elevate_XXXX.ps1`) in `%TEMP%` and executes it via `Start-Process -Verb RunAs`.

### Session State Isolation
- Updating the Windows Registry does **not** update the live, running terminal session. To solve this, the script dynamically evaluates the environment block within the execution boundary.
- **Dynamic Filtering:** Instead of using batch string substitution (`!PATH:string=!`), which is vulnerable to quote-collisions and delayed expansion parsing bugs, the manager pipes the variable manipulation to PowerShell using the `-not` operator against `$env:PATH`. This guarantees 100% accurate string evaluation and prevents the accidental deletion of unrelated paths (e.g., pruning `JAVA_HOME_Backup` while searching for `JAVA_HOME`).

## Ecosystem Routing (Universal Candidate Engine)
Like SDKMAN!, this tool intercepts commands for popular Java tools (Maven, Gradle, Kotlin, Scala, Groovy). The CLI acts as a universal router:
1. It intercepts the `jvm install <candidate> <version>` command.
2. It executes a PowerShell `Invoke-RestMethod` to the respective API (Adoptium, GitHub Releases, Azul, etc.) to securely resolve the download URL and SHA-256 checksums.
3. The payloads are extracted via `Expand-Archive` and isolated in `%LOCALAPPDATA%\DiamTek\JVM\<candidate>`.
4. Specific `<CANDIDATE>_HOME` variables are injected into the registry, mapping the ecosystem completely identically to native Java.