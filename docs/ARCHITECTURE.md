<h1 align="center">Architecture & Technical Implementation</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md)

</div>


---

This project is a zero-dependency, lightweight, native Windows implementation designed to bypass the traditional complexities of virtualized bash scripts (like SDKMAN!) on Windows operating systems.

### 🔍 Quick Jump
- [The Core Mechanism: Directory Junctions](#the-core-mechanism-directory-junctions)
- [Dual-Architecture Core (Symlink Mode vs. Legacy Registry Mode)](#dual-architecture-core-symlink-mode-vs-legacy-registry-mode)
- [PowerShell Native Dynamic Environment Injection](#powershell-native-dynamic-environment-injection)
- [Packaging Architecture & Asset Distribution](#packaging-architecture--asset-distribution)

---

## The Core Mechanism: Directory Junctions
Instead of constantly appending and pruning your Windows `PATH` variable to point to different JDK folders (which quickly leads to the 1024-character `PATH` limit and environment variable bloat), the manager maintains a single **Directory Junction** (`mklink /J`) at:

`%LOCALAPPDATA%\DiamTek\JVM\current`

Your system `PATH` only ever needs to contain `%LOCALAPPDATA%\DiamTek\JVM\current\bin`. When you switch Java versions, the manager simply tears down the old junction and repoints it to the target JDK directory. This provides `O(1)` symlink resolution for the OS.

```mermaid
graph TD
    Shell["Developer Terminal, Shell & IDE Environments<br/>PowerShell • CMD • Windows Terminal • VS Code"]
    Path["Persistent User PATH Environment Entry<br/>%LOCALAPPDATA%\DiamTek\JVM\current\bin"]
    Junction["NTFS Directory Junction Repointing Target<br/>%LOCALAPPDATA%\DiamTek\JVM\current"]
    
    JDK21["Adoptium OpenJDK 21 (Long-Term Support)<br/>C:\Program Files\Java\jdk-21"]
    JDK17["Oracle JDK 17 (Long-Term Support)<br/>C:\Program Files\Java\jdk-17"]
    JDKCustom["Custom Enterprise or GraalVM JDK<br/>C:\Development\graalvm-21"]

    Shell --> Path
    Path --> Junction
    Junction -.->|"Active Switch (O(1))"| JDK21
    Junction -.->|"Alternative Target"| JDK17
    Junction -.->|"BYO-JDK Link"| JDKCustom
```

## Dual-Architecture Core (Symlink Mode vs. Legacy Registry Mode)
The engine provides two distinct switching engines that users can toggle via the Settings menu or CLI flags:

1. **Symlink Mode (Default, UAC-Free):**
   - **Mechanism:** Updates the NTFS Directory Junction pointer (`%LOCALAPPDATA%\DiamTek\JVM\current`) in user-space.
   - **Privileges:** Standard user space (100% UAC-free, zero admin popups).
   - **Compatibility:** Native for 99% of modern tools (Maven, Gradle, IntelliJ IDEA, VS Code, Eclipse).

2. **Registry Mode (Legacy, UAC Required):**
   - **Mechanism:** Directly writes the absolute JDK path to the Machine-level Windows Registry (`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`) and updates the system-wide Machine `PATH`.
   - **Privileges:** **Requires Administrator (UAC) Elevation** on every switch, spawning an elevated background PowerShell worker via `Start-Process -Verb RunAs`.
   - **Compatibility:** 100% unbreakable fallback for legacy enterprise applications, obscure Windows service runners, or ancient classloaders that perform strict canonical path checks and cannot resolve NTFS Directory Junctions.

```mermaid
flowchart TD
    Command["jvm switch / quick-switch command"] --> ModeCheck{"Active Mode?"}
    
    ModeCheck -->|Symlink Mode| TearDown
    ModeCheck -->|Registry Mode| CheckAdmin

    subgraph SymlinkMode["Symlink Mode (Default - UAC-Free)"]
        TearDown["Remove-Item / rmdir current"] --> CreateJunction["New-Item -ItemType Junction<br/>targeting selected JDK"]
        CreateJunction --> UpdateProfile["Invoke PowerShell Set-JvmVar Session Hook<br/>Updates active shell process memory"]
        UpdateProfile --> InstantSuccess["Instant Switch Across All Open Shells (0 UAC)"]
    end
    
    subgraph RegistryMode["Registry Mode (Legacy - UAC Required)"]
        CheckAdmin{"Running as Admin?"}
        CheckAdmin -->|Yes| WriteHKLM["[Environment]::SetEnvironmentVariable<br/>('JAVA_HOME', target, 'Machine')"]
        CheckAdmin -->|No| Elevate["Spawn Start-Process -Verb RunAs<br/>(Triggers Windows UAC Prompt)"]
        Elevate --> WriteHKLM
        WriteHKLM --> Broadcast["Broadcast Win32 SendMessageTimeout API<br/>WM_SETTINGCHANGE: Environment"]
    end
```

## Deep OS Environment Management
To ensure deep OS integration without requiring users to download external binaries (like `setx` augmentations), the tool relies on inline PowerShell execution invoked seamlessly via `cmd.exe`.

### Global/Machine State (`HKLM`)
- Updates to the global `PATH` and `JAVA_HOME` are performed natively using the .NET framework bridging in PowerShell: 
  `[Environment]::SetEnvironmentVariable('JAVA_HOME', $target, 'Machine')`
- The script detects if it is running in standard user space. If required, it invokes an elevated background PowerShell worker via `Start-Process powershell -Verb RunAs -ArgumentList @(...)` with direct, in-memory parameterized command arguments. It never stages temporary scripts in `%TEMP%`, completely eliminating Time-of-Check to Time-of-Use (TOCTOU) race conditions and Local Privilege Escalation vectors.

### Session State Isolation
- Updating the Windows Registry does **not** update the live, running terminal session. To solve this, the script dynamically evaluates the environment block within the execution boundary.
- **Dynamic Filtering:** Instead of using batch string substitution (`!PATH:string=!`), which is vulnerable to quote-collisions and delayed expansion parsing bugs, the manager pipes the variable manipulation to PowerShell using the `-not` operator against `$env:PATH`. This guarantees 100% accurate string evaluation and prevents the accidental deletion of unrelated paths (e.g., pruning `JAVA_HOME_Backup` while searching for `JAVA_HOME`).

## Ecosystem Routing (Universal Candidate Engine)
Like SDKMAN!, this tool intercepts commands for popular Java tools (Maven, Gradle, Kotlin, Scala, Groovy). The CLI acts as a universal router:
1. It intercepts the `jvm install <candidate> <version>` command.
2. It executes a PowerShell `Invoke-RestMethod` to the respective API (Adoptium, GitHub Releases, Azul, etc.) to securely resolve the download URL and SHA-256 checksums.
3. The payloads are extracted via `Expand-Archive` and isolated in `%LOCALAPPDATA%\DiamTek\JVM\candidates\<candidate>`.
4. Specific `<CANDIDATE>_HOME` variables are injected into the registry, mapping the ecosystem completely identically to native Java.

<a id="powershell-native-dynamic-environment-injection"></a>
## Real-Time PowerShell Session Propagation (`Set-JvmVar`)
Because Windows process environments cannot ordinarily be modified by a child batch process, `install.ps1` injects a native PowerShell function hook into `$PROFILE`. 
When `jvm` switches an active tool or JDK:
1. `jvm.bat` writes target environment pairs (`KEY=VALUE`) to `$env:TEMP\.jvm_session_target`.
2. The PowerShell wrapper intercepts the return code and invokes `Set-JvmVar`.
3. `Set-JvmVar` surgically strips the old `\bin` directory from `$env:Path` and prepends the new `\bin` directory directly into the current PowerShell process memory.
4. It updates `$env:JAVA_HOME` (or corresponding tool variables) live, providing instantaneous switching without reopening terminal tabs.

### Decoupled Profile Hook Management (`jvm hook`)
The PowerShell profile wrapper is decoupled from global User `PATH` installation. Developers can manage the hook independently via `jvm hook [install|remove|status]` or via Option 2 in the interactive Settings menu. The hook automatically discovers and synchronizes both Windows PowerShell 5.1 and modern PowerShell 7+ profiles across standard or redirected Documents directories (`[Environment]::GetFolderPath('MyDocuments')`).

## Automated Health Diagnostics & Shadow Detection (`jvm doctor`)
The `jvm doctor` diagnostic engine runs a deterministic 7-point system health audit across:
1. **Storage Root Accessibility:** Verifies `%LOCALAPPDATA%\DiamTek\JVM` exists and has NTFS write permissions.
2. **Directory Junction Target Validity:** Validates that `%LOCALAPPDATA%\DiamTek\JVM\current` points to an active JDK containing `bin\java.exe`.
3. **Registry Synchronization:** Cross-references User (`HKCU`) and Machine (`HKLM`) `JAVA_HOME` variables.
4. **PATH Precedence & Rogue Shadowing:** Scans `where.exe java` to detect legacy Oracle `javapath` or `System32\java.exe` shims overriding JVM in your system PATH.
5. **PowerShell `$PROFILE` Hook:** Audits wrapper function presence across detected PowerShell profiles.
6. **CPU Architecture:** Confirms native architecture matches (`x64` / `ARM64`).
7. **Discovered JDK Distribution Inventory:** Audits recognized runtimes on disk.

## Ephemeral Execution Architecture (`jvm exec` / `jvm run`)
Unlike persistent switching which mutates directory junctions or registries, `jvm exec` / `jvm run` resolves the requested JDK build, spawns an isolated child subshell with local `JAVA_HOME` and prepended `bin\` in `PATH`, invokes the user command, and propagates the child process's exact exit code back to the host shell prompt, leaving global OS state 100% untouched.

## Bulletproof Batch Heredoc Escaping
Windows `cmd.exe` does not natively support Bash-style heredocs (`cat <<EOF`). Embedding multi-line PowerShell scripts inside a batch `( ... ) > script.ps1` redirection block requires careful escaping:
- Redirection operators (`<`, `>`) are escaped as `^<`, `^>`.
- Pipes (`|`) and command separators (`&`) are escaped as `^|`, `^&`.
- Parentheses (`(`, `)`) are escaped as `^(`, `^)` to prevent premature termination of the enclosing batch block.
- Exclamation marks (`!`) are escaped as `^^!` to prevent corruption by CMD's delayed variable expansion engine (`setlocal enabledelayedexpansion`).

## Deep Uninstaller & Windows Integration Architecture
The uninstaller subsystem (`uninstall.ps1`) is designed for 100% total system sanitization:
1. **UAC Escalation:** Uses .NET security principals to check for elevated tokens; if missing, automatically spawns an elevated PowerShell host via `Start-Process -Verb RunAs`.
2. **Registry Integration:** Registers under `HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiamTek.JVM` with native Windows "Installed apps" metadata, dynamic `EstimatedSize` computation (with a 1,024 KB floor for Windows 11 compatibility), and creates a Start Menu uninstaller shortcut in `Start Menu\Programs\DiamTek`.
3. **Dual-Scope Cleanup:** Cleans both `User` and `Machine` environment variables and `PATH` registries, surgically strips the `$PROFILE` hook, deletes the AppData Ecosystem cache, purges Windows Terminal profiles, removes pinned taskbar shortcuts, cleans session files, and prompts to clean `C:\Program Files\Java`.

## Windows Terminal & Shell Integration Architecture
To provide a first-class modern Windows developer experience while strictly maintaining 100% pure Batch & PowerShell code:
1. **Dynamic Profile Injection**: `install.ps1` scans for Windows Terminal configurations across Release, Preview, and Unpackaged locations (`LocalState\settings.json`). It injects a dedicated profile with GUID `{b20650a4-4212-4d64-9edf-744e9285e2be}`, pointing to high-resolution `assets/icon.png`.
2. **Tab Lifecycle Management**: Configured with `cmd.exe /c` and `closeOnExit: always`. When a developer exits the interactive JVM menu (`exit /B 0`), the hosting `cmd.exe` process terminates, signaling Windows Terminal to immediately close the tab.
3. **Shortcut Synchronization**: Creates Start Menu application shortcuts targeting `wt.exe -p "Java Version Manager"` (falling back to `cmd.exe /c` on systems without Windows Terminal). During installation and self-updates, the script automatically searches `%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\` to detect and update existing pinned taskbar shortcuts in place.
4. **AppUserModelID & Taskbar Mechanics**: Windows Terminal is a packaged WinUI app that hardcodes its own process-level AppUserModelID (`Microsoft.WindowsTerminal...`) on all hosting windows. By registering a dedicated profile with native icon and dropdown integration rather than forcing brittle binary wrappers, the utility respects the OS container model while maintaining a zero-binary, 100% script-based repository.

<a id="packaging-architecture--asset-distribution"></a>
## Multi-Channel Packaging Pipelines

```mermaid
graph LR
    Source["Repository Source Code<br/>(jvm.bat & assets)"] --> WixBuild["WiX Toolset v4 Engine<br/>(build-msi.ps1)"]
    WixBuild --> OutputMSI["Standalone Dual-Architecture MSI<br/>x64 & arm64 (Embedded CAB)"]
    OutputMSI --> TestSuite["18-Point Test Suite<br/>(test-msi.ps1)"]
    TestSuite --> Provenance["GitHub Actions SLSA Attestation<br/>Sigstore In-Toto Provenance"]
    Provenance --> Release["Official GitHub Production Release<br/>MSIs, Zips & Checksums"]
    Release --> PM["Windows Package Manager Ecosystem<br/>Winget • Scoop • Chocolatey"]
```

- **Winget:** Native YAML manifest (`packages\winget\DiamTek.JVM.yaml`) declaring installer metadata and portable packaging.
- **Scoop:** JSON manifest (`packages\scoop\jvm.json`) that automates downloading and bootstraps `install.ps1`.
- **Chocolatey:** Package specification (`packages\choco\jvm.nuspec`) with automated `chocolateyInstall.ps1` and `chocolateyUninstall.ps1` scripts.
- **WiX Toolset v4 (MSI):** Automated build script (`packages\msi\build-msi.ps1`) that compiles native, per-user Windows Installers (`.msi`) bundling `jvm.bat`, companion branding assets, `uninstall.ps1`, `LICENSE`, and `README.md`:
  - **Embedded Cabinet Architecture**: Built with `<MediaTemplate EmbedCab="yes" />` to generate an internal `#cab1.cab` data stream inside the `.msi` binary. This produces truly standalone, single-file installers (~900 KB) without loose external `.cab` files, simplifying distribution and offline caching.
  - **Multi-Architecture Support (`x64` & `arm64`)**: Compiles native installers targeting both 64-bit Intel/AMD and ARM64 Windows platforms via WiX v4 `-arch` switches, setting native architecture properties while defaulting to building both (`$Arch = "all"`).
  - **Upgrade & Downgrade Safety**: Configured with `<MajorUpgrade DowngradeErrorMessage="..." Schedule="afterInstallInitialize" />` allowing clean upgrades over prior versions while preventing accidental downgrade conflicts.
  - **Deferred Action Execution Order & Hook Isolation**:
    - **Isolated Hook Architecture**: Internal hook scripts (`msi-install-hook.ps1` and `msi-uninstall-hook.ps1`) reside privately in `%LOCALAPPDATA%\DiamTek\JVM\`, strictly segregating them from the CLI `%LOCALAPPDATA%\DiamTek\JVM\bin\` folder so internal scripts never pollute the user's command line or `PATH`.
    - **Install Hook**: Scheduled `After="CreateShortcuts"` (sequence 4501) rather than `After="InstallFiles"` (sequence 4002). Standard Windows Installer action `CreateShortcuts` generates the Start Menu `.lnk` at sequence 4500; scheduling the hook afterward ensures the shortcut exists before PowerShell attempts to polish it with Windows Terminal (`wt.exe`) profiles and custom arguments.
    - **Path Resolution in `WixQuietExec`**: Standard Windows Installer deferred custom actions run in the Windows Installer service context without inheriting standard shell environment PATHs. Hardcoding `[WindowsFolder]System32\WindowsPowerShell\v1.0\powershell.exe` guarantees deterministic 64-bit PowerShell invocation, completely eliminating `0x80070002` ("file not found") execution errors.
    - **Uninstall Hook**: Scheduled `Before="RemoveFiles"` to ensure PowerShell profile cleanup, Windows Terminal configuration scrubbing, dangling sub-process termination, and environment variable removal occur while the installed components are still present on disk.
    - **Start Menu Uninstaller Shortcut**: Packages an explicit MSI shortcut targeting `[SystemFolder]msiexec.exe /x [ProductCode]` under `Start Menu\Programs\DiamTek`, allowing instant uninstallation discovery via Windows Search ("Uninstall Java Version Manager" and "Uninstall JVM").
    - **Race Condition Elimination**: The MSI uninstaller relies purely on standard Windows Installer actions (`RemoveFile`, `RemoveFolderEx`) for directory teardown, omitting background asynchronous CMD deletions to avoid file-lock race conditions (Windows Installer Error 2318).
  - **Automated Verification Suite (`packages\msi\test-msi.ps1`)**: Implements an automated 18-point synthetic integration suite designed for CI/CD pipelines and GitHub Actions build provenance attestations (`actions/attest-build-provenance`). The suite actively tests live operating system integration (Windows Installer service `msiexec`, binary layout, CLI `bin/` directory hygiene, Start Menu application and uninstaller shortcuts indexed by Windows Search, registry metadata, PATH propagation, Windows Terminal profile injection, CLI sanity subshell execution, clean uninstallation, and zero filesystem residuals). Features an autonomous 4-tier fallback engine (local MSI -> local WiX compiler -> GitHub Release binary -> remote source bootstrap + user-space .NET SDK / WiX CLI toolchain) and supports `-ShowUI` (native progress dialog `/qb`) and `-KeepInstalled` (retaining JVM post-test for direct terminal usage).

---

[← Back to Documentation Overview](../README.md#documentation)