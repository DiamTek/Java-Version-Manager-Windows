# Frequently Asked Questions (FAQ)

<p align="center">
  <a href="../README.md">🏠 Overview</a> &nbsp;•&nbsp;
  <a href="INSTALLATION.md">📦 Installation</a> &nbsp;•&nbsp;
  <a href="USAGE.md">📖 Usage</a> &nbsp;•&nbsp;
  <a href="ARCHITECTURE.md">🏗️ Architecture</a> &nbsp;•&nbsp;
  <a href="FAQ.md">❓ FAQ</a> &nbsp;•&nbsp;
  <a href="SDKMAN-Comparison.md">⚖️ SDKMAN! Comparison</a> &nbsp;•&nbsp;
  <a href="CHANGELOG.md">📜 Changelog</a>
</p>

---

### 🔍 Quick Jump
- [Why use this over SDKMAN! on Windows?](#why-use-this-over-sdkman-on-windows)
- [Why isn't `java` recognized immediately after I switch versions?](#why-isnt-java-recognized-immediately-after-i-switch-versions)
- [Why does `java -version` still show an old version after I switch? (PATH Shadowing)](#why-does-java--version-still-show-an-old-java-version-after-i-switch-path-shadowing)
- [How do I verify or manually configure the PowerShell Profile Hook?](#how-do-i-verify-or-manually-configure-the-powershell-profile-hook)
- [Does this require Administrator (UAC) privileges?](#does-this-require-administrator-uac-privileges)
- [How does it change the version globally without messing up my path?](#how-does-it-change-the-version-globally-without-messing-up-my-path)
- [Can I use this in a CI/CD pipeline (like GitHub Actions)?](#can-i-use-this-in-a-cicd-pipeline-like-github-actions)
- [Can I temporarily run a build with a specific Java version without altering my global environment?](#can-i-temporarily-run-a-build-with-a-specific-java-version-without-altering-my-global-environment)
- [Does it support custom JDKs or private binaries?](#does-it-support-custom-jdks-or-private-binaries)
- [Where are my JDKs and tools actually installed?](#where-are-my-jdks-and-tools-actually-installed)
- [How do I use JVM behind a corporate proxy or enterprise firewall?](#how-do-i-use-jvm-behind-a-corporate-proxy-or-enterprise-firewall)
- [How does Windows Terminal and Taskbar integration work?](#how-does-windows-terminal-and-taskbar-integration-work)
- [How do I completely uninstall it?](#how-do-i-completely-uninstall-it)
- [Why does Windows PowerShell say a script is not digitally signed or blocked?](#why-does-windows-powershell-say-a-script-is-not-digitally-signed-or-blocked)
- [What should I do if Windows Defender SmartScreen warns about an "Unknown Publisher"?](#what-should-i-do-if-windows-defender-smartscreen-warns-about-an-unknown-publisher)
- [Does the MSI test suite test real system integration or just file creation?](#does-the-msi-test-suite-test-real-system-integration-or-just-file-creation)
- [How do I cryptographically verify the authenticity and provenance of release binaries?](#how-do-i-cryptographically-verify-the-authenticity-and-provenance-of-release-binaries)
- [How does JVM protect against local privilege escalation and corrupted downloads?](#how-does-jvm-protect-against-local-privilege-escalation-and-corrupted-downloads)
- [What process exit codes does the CLI and installer return for CI/CD scripting?](#what-process-exit-codes-does-the-cli-and-installer-return-for-cicd-scripting)
- [Can my engineering team adopt JVM on locked-down corporate laptops without IT admin tickets?](#can-my-engineering-team-adopt-jvm-on-locked-down-corporate-laptops-without-it-admin-tickets)
- [How does DiamTek JVM fit into enterprise fleet management (Intune / MECM / GPO)?](#how-does-diamtek-jvm-fit-into-enterprise-fleet-management-intune--mecm--gpo)

---

### Why use this over SDKMAN! on Windows?
SDKMAN! is an incredible tool, but it is fundamentally built for Unix architectures (bash). Running it on Windows requires layers of virtualization like Windows Subsystem for Linux (WSL), Git Bash, or Cygwin. This Java Version Manager is built **100% natively** for Windows Command Prompt (`cmd.exe`) and PowerShell. It requires zero dependencies and directly manipulates the Windows Registry.

### Why isn't `java` recognized immediately after I switch versions?
In most cases, it is recognized immediately! 
- **PowerShell (with Profile Hook):** The installer injects the `Set-JvmVar` hook into your PowerShell `$PROFILE`. When you switch versions with `jvm`, environment variables (`JAVA_HOME`, `Path`, toolchains) are dynamically injected into the active session memory on the fly without restarting.
- **Command Prompt (CMD):** In default **Symlink Mode**, your `PATH` points to the directory junction (`%LOCALAPPDATA%\DiamTek\JVM\current\bin`). The moment the junction target changes, all open CMD terminals resolve the new `java` binary immediately.
- **IDE Terminals & Background Daemons:** If an application (such as an open VS Code window, IntelliJ instance, or build daemon) cached the environment variables in its own process block before the switch, restarting that terminal or reload the IDE window will ensure the updated variables are picked up.

<a id="why-does-java--version-still-show-an-old-java-version-after-i-switch-path-shadowing"></a>
<a id="why-does-java--version-still-show-an-old-version-after-i-switch-path-shadowing"></a>
### Why does `java -version` still show an old Java version after I switch? (PATH Shadowing)
If switching versions with `jvm <version>` completes successfully but typing `java -version` still reports an old version (such as an ancient Oracle JRE or Chocolatey installation), you are experiencing **PATH Shadowing**.

#### 1. Diagnosing Path Precedence
When you run `java`, Windows scans through every folder listed in your system `PATH` from left to right and executes the first `java.exe` it finds. To list every Java binary on your machine in the exact order Windows checks them:

**In Command Prompt:**
```cmd
where.exe java
```

**In PowerShell:**
```powershell
(Get-Command java -All).Source
```

If you see an entry like `C:\Program Files\Common Files\Oracle\Java\javapath\java.exe` or `C:\ProgramData\Oracle\Java\javapath\java.exe` listed **above** `%LOCALAPPDATA%\DiamTek\JVM\current\bin\java.exe`, Windows is intercepting the command before it reaches JVM.

#### 2. Automatic Resolution
- **Purge Rogue Paths with `jvm clear`:** Run `jvm clear` (or in the interactive UI menu, select **Clear Java from Environment Variables**). This automatically scrubs legacy Oracle `javapath` entries (`C:\Program Files\Common Files\Oracle\Java\javapath`, `C:\ProgramData\Oracle\Java\javapath`) and broken symlinks from both your User and System `PATH`. Afterward, run `jvm <version>` (e.g., `jvm 21`) to re-activate your desired JDK cleanly with zero path conflicts.
- **Manual Cleanup:** Open Windows System Properties (`sysdm.cpl` → **Advanced** → **Environment Variables**) and delete any lingering `javapath` entries from the Machine-level **Path** variable.

### How do I verify or manually configure the PowerShell Profile Hook?
DiamTek JVM automatically configures both Windows PowerShell (5.1) and modern PowerShell Core (7+) profiles so that switching versions via `jvm` dynamically updates `JAVA_HOME`, toolpaths, and the active session `$env:Path` in-memory without restarting your shell.

#### 1. Verifying the Hook
To confirm that the hook is present and active in your PowerShell profile:
```powershell
Get-Content $PROFILE -ErrorAction SilentlyContinue | Select-String "jvm"
```
If properly configured, this command outputs the `# >>> jvm >>>` sentinel and the `function jvm { ... }` wrapper definition.

#### 2. Manual Installation or Dotfile Configuration
If your profile was not configured automatically (e.g., if you manage dotfiles across multiple machines via Git or use a custom `$PROFILE` location), you can inject or repair the hook at any time:
- **Interactive Menu:** Run `jvm`, navigate to **Settings** (`3`), and select **Install Global Command & Profile Hook** (`1`).
- **PowerShell:** Run `powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\DiamTek\JVM\install.ps1"`.
- **Manual Setup:** Paste the wrapper function block directly into your `$PROFILE` (`notepad $PROFILE` or `code $PROFILE`):

```powershell
# >>> jvm >>>
function jvm {
    $bat = Get-Command jvm.bat -CommandType Application -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
    if (-not $bat) { $bat = "$env:LOCALAPPDATA\DiamTek\JVM\bin\jvm.bat" }
    & $bat @args

    function Set-JvmVar {
        param([string]$Name, [string]$OldValue, [string]$NewValue)
        if ($OldValue) { $OldValue = $OldValue.TrimEnd('\') }
        if ($NewValue) { $NewValue = $NewValue.TrimEnd('\') }
        [Environment]::SetEnvironmentVariable($Name, $NewValue, 'Process')
        $parts = $env:Path -split ';' | Where-Object { $_ -ne '' }
        if (-not [string]::IsNullOrWhiteSpace($OldValue)) {
            $parts = $parts | Where-Object { $_.TrimEnd('\') -ne "$OldValue\bin" }
        }
        if (-not [string]::IsNullOrWhiteSpace($NewValue)) {
            $parts = $parts | Where-Object { $_.TrimEnd('\') -ne "$NewValue\bin" }
            $parts = @("$NewValue\bin") + $parts
        }
        $env:Path = $parts -join ';'
    }

    $sessionFile = "$env:TEMP\.jvm_session_target"
    if (Test-Path $sessionFile) {
        foreach ($line in (Get-Content $sessionFile)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            if ($line -match '^([^=]+)=(.*)$') {
                $key = $matches[1]; $val = $matches[2]
            } else {
                $key = 'JAVA_HOME'; $val = $line
            }
            $old = [Environment]::GetEnvironmentVariable($key, 'Process')
            Set-JvmVar -Name $key -OldValue $old -NewValue $val
        }
        Remove-Item $sessionFile -Force
    } else {
        foreach ($v in @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME')) {
            $old = [Environment]::GetEnvironmentVariable($v, 'Process')
            $new = [Environment]::GetEnvironmentVariable($v, 'User')
            if ([string]::IsNullOrEmpty($new)) {
                $new = [Environment]::GetEnvironmentVariable($v, 'Machine')
            }
            if ($old -eq $new) { continue }
            Set-JvmVar -Name $v -OldValue $old -NewValue $new
        }
    }
}
# <<< jvm <<<
```

### Does this require Administrator (UAC) privileges?
It depends on which architecture mode you use:
- **Symlink Mode (Default, Recommended):** **100% UAC-Free!** It leverages a Windows Directory Junction (`%LOCALAPPDATA%\DiamTek\JVM\current`). Switching versions updates the junction pointer in user-space, requiring zero administrator privileges or UAC popups.
- **Registry Mode (Legacy):** **Requires Administrator (UAC) Elevation.** This optional mode writes absolute paths directly to the Machine-level Windows Registry (`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`). Every version switch will trigger a UAC prompt to elevate a background PowerShell process. This mode is provided for enterprise applications or legacy classloaders that cannot traverse NTFS Directory Junctions.

*Note: Administrator privileges are also requested when auto-downloading JDKs directly into `C:\Program Files\Java`, scrubbing rogue legacy paths from the Machine registry, or executing the deep system uninstaller (`uninstall.ps1` / `jvm self-uninstall`).*

### How does it change the version globally without messing up my path?
Instead of adding a new folder to your system `PATH` every time you install a JDK, this tool adds one single entry: `%LOCALAPPDATA%\DiamTek\JVM\current\bin`. This is a Directory Junction. When you switch Java versions, the tool just changes where that junction points. Your actual `PATH` variable stays completely clean and bloat-free.

### Can I use this in a CI/CD pipeline (like GitHub Actions)?
Yes! The tool supports headless execution. You can bypass the interactive menu entirely by passing arguments directly, for example: `jvm install java 21` or `jvm 21`.

### Can I temporarily run a build with a specific Java version without altering my global environment?
Yes! DiamTek JVM provides clean options depending on whether you want true per-process isolation or sequential command execution:

1. **True Session Isolation via `.java-version` (Recommended):**
   Place a `.java-version` file in the root of your project directory containing the desired version (e.g., `21`). When you run `jvm` in that directory, it activates Java 21 **only for that active terminal process memory**—leaving the shared NTFS Directory Junction (`%LOCALAPPDATA%\DiamTek\JVM\current`), other open terminals, and your Windows Registry completely untouched.

2. **In-Process Environment Overrides (Subshell):**
   To execute a single build against a specific JDK path without changing any global state:
   - **Command Prompt:**
     ```cmd
     cmd.exe /c "set JAVA_HOME=C:\Program Files\Java\jdk-17&& set PATH=C:\Program Files\Java\jdk-17\bin;%PATH%&& gradlew build"
     ```
   - **PowerShell:**
     ```powershell
     & { $env:JAVA_HOME = "C:\Program Files\Java\jdk-17"; $env:Path = "$env:JAVA_HOME\bin;$env:Path"; ./gradlew build }
     ```

3. **Sequential Execution (`&&`):**
   You can also chain commands sequentially:
   ```cmd
   jvm 17 && gradlew build
   ```
   *(Note: Because `&&` runs two commands in sequence, `jvm 17` first updates your active Directory Junction to JDK 17, and then `gradlew build` runs using that newly activated version).*

### Does it support custom JDKs or private binaries?
Yes! You can use `jvm link <path> [name]` to register any custom or private JDK into the manager. It will integrate seamlessly into the dynamic menus and CLI routing.

### Where are my JDKs and tools actually installed?
By default, auto-downloaded JDKs are installed to `C:\Program Files\Java\<vendor-jdk>`, and ecosystem tools (Maven, Gradle, Kotlin, Scala, Groovy) are securely stored and cached in `%LOCALAPPDATA%\DiamTek\JVM\candidates\<tool>`.

### How do I use JVM behind a corporate proxy or enterprise firewall?
DiamTek JVM's networking leverages native Windows `.NET` APIs, which automatically respect enterprise network configurations:

1. **System WinINet Proxies:**
   If your workstation routes traffic through a corporate PAC file or system proxy (configured in Windows Settings → **Network & Internet** → **Proxy**), JVM automatically inherits and tunnels requests through it without manual setup.

2. **Standard Proxy Environment Variables:**
   For command-line proxy routing, define the standard Windows proxy variables in your terminal:
   ```cmd
   set HTTP_PROXY=http://proxy.company.com:8080
   set HTTPS_PROXY=http://proxy.company.com:8080
   ```
   For authenticated proxies:
   ```cmd
   set HTTPS_PROXY=http://username:password@proxy.company.com:8080
   ```

3. **Corporate Root SSL Certificates (Zscaler, Netskope, Palo Alto):**
   Unlike Unix tools that require manually importing corporate root CAs into custom Java `cacerts` truststores, JVM's internal downloader validates certificates against the native **Windows Trusted Root Certification Authorities** store. Any enterprise root certificate deployed via Group Policy (GPO) or Intune is trusted automatically.

### How does Windows Terminal and Taskbar integration work?
The installer automatically integrates DiamTek JVM into Windows Terminal by registering a dedicated profile in `settings.json`:
- **Custom Branding**: Displays the high-resolution DiamTek JVM icon on the terminal tab, header, and the `+` new tab dropdown menu.
- **Auto-Close on Exit**: Configured to launch `cmd.exe /c "%LOCALAPPDATA%\DiamTek\JVM\bin\jvm.bat"` with `"closeOnExit": "always"`, meaning that exiting the JVM interactive menu automatically closes the terminal tab.
- **Taskbar & Start Menu Shortcuts**: Start Menu and pinned Taskbar shortcuts target the registered Windows Terminal profile when available (with a graceful fallback to `cmd.exe /c`). In Windows 11, tabs opened inside Windows Terminal are hosted within `WindowsTerminal.exe` and group under the Windows Terminal taskbar button by operating system design.

### How do I completely uninstall it?
DiamTek JVM provides a complete, UAC-elevated uninstaller (`uninstall.ps1`) that scrubs all system PATH entries, PowerShell `$PROFILE` hooks, environment variables, ecosystem tool caches, Windows Terminal profiles, pinned taskbar shortcuts, and installed JDKs:
- **Windows Settings:** Open **Settings** -> **Apps** -> **Installed apps** -> **DiamTek Java Version Manager** -> **Uninstall**.
- **Start Menu:** Search for **"Uninstall Java Version Manager"** in Windows and run it.
- **Terminal UI:** Launch `jvm`, navigate to **Settings** (`3`), and choose **Uninstall JVM Completely** (`4`).
- **CLI:** Run `jvm self-uninstall`.
- **PowerShell:** Execute `& "$env:LOCALAPPDATA\DiamTek\JVM\uninstall.ps1"`.
- **Windows Installer (MSI):** Run `msiexec /x jvm-windows-1.0.0-x64.msi /qn`.

### Why does Windows PowerShell say a script is not digitally signed or blocked?
When you download `.ps1` scripts (such as `install.ps1`, `uninstall.ps1`, or test suites) or `.zip` archives through a web browser, Windows Attachment Manager tags them with an NTFS `Zone.Identifier` stream (`ZoneId=3` - Internet). Under the default `RemoteSigned` policy, PowerShell blocks any unverified script before running.

You can unblock the file(s) in three ways:
1. **PowerShell CLI:**
   ```powershell
   # Unblock install.ps1 or uninstall.ps1 directly:
   Unblock-File .\install.ps1
   Unblock-File .\uninstall.ps1

   # Or unblock every script and file in an extracted folder recursively:
   Get-ChildItem -Recurse | Unblock-File
   ```
2. **File Explorer GUI:** Right-click the `.ps1` or `.zip` file → **Properties** → check **Unblock** at the bottom → click **OK**.
3. **ExecutionPolicy Bypass:** Run with temporary session bypass:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```

### What should I do if Windows Defender SmartScreen warns about an "Unknown Publisher"?
When downloading newly released open-source installers (`.msi` or `.ps1`) from GitHub without an expensive commercial EV Code Signing certificate ($500+/year), Windows Defender SmartScreen may display a blue warning banner: *"Windows protected your PC — Microsoft Defender SmartScreen prevented an unrecognized app from starting."*

This is standard Windows behavior for open-source software with newly compiled binaries:
1. Click **More info**.
2. Click **Run anyway**.

All official DiamTek release artifacts are cryptographically attested via GitHub's Sigstore OIDC infrastructure using `actions/attest-build-provenance`. You can independently verify that your downloaded binary was compiled directly by GitHub Actions from the audited open-source repository:
```powershell
gh attestation verify jvm-windows-1.0.0-x64.msi --repo DiamTek/Java-Version-Manager-Windows
```

### Does the MSI test suite test real system integration or just file creation?
It tests the **real, live system integration on your computer**:
- Spawns the Windows Installer service (`msiexec.exe`) to perform a real installation.
- Reads your actual PowerShell `$PROFILE` to confirm the shell hook was injected.
- Reads your actual Windows Terminal `settings.json` to verify profile registration and custom branding.
- Queries the Windows Registry for User `PATH` and uninstaller keys.
- Inspects your Windows Start Menu for application shortcuts.
- Executes `jvm.bat --version` in a real subshell to verify engine startup.
- Triggers `msiexec /x` to verify deep uninstallation and zero-residual cleanup.
By default, the test suite runs silently (`/qn`) for CI automation. To display the Windows Installer progress dialog, pass `-ShowUI`. To keep JVM installed after testing, pass `-KeepInstalled`.

### How do I cryptographically verify the authenticity and provenance of release binaries?
All official release artifacts (`jvm-windows-*.msi`, `jvm-windows-*.zip`, `SHA256SUMS.txt`) are cryptographically attested via GitHub's Sigstore OIDC infrastructure using `actions/attest-build-provenance`. This generates an immutable, tamper-evident record linking the binaries directly to the GitHub Actions runner build and the specific Git commit SHA.

You can verify any downloaded artifact using the official [GitHub CLI (`gh`)](https://cli.github.com/):
```powershell
gh attestation verify jvm-windows-1.0.0-x64.msi --repo DiamTek/Java-Version-Manager-Windows
```
Upon verification, the GitHub CLI outputs:
```text
Loaded digest sha256:... for jvm-windows-1.0.0-x64.msi
The following policy criteria will be enforced:
- Predicate type: https://slsa.dev/provenance/v1
- Source repository: DiamTek/Java-Version-Manager-Windows
✓ Verification succeeded!
```
This guarantees the binary you downloaded was built directly by GitHub Actions from the audited open-source codebase and has not been altered or tampered with.

### How does JVM protect against local privilege escalation and corrupted downloads?
- **Zero-File UAC Elevation:** All administrative operations (such as system-wide registry adjustments or moving JDK files into `C:\Program Files\Java`) execute commands directly in memory via parameterized process calls. JVM never stages temporary batch or PowerShell scripts in `%TEMP%`, completely eliminating Time-of-Check to Time-of-Use (TOCTOU) file race conditions and Local Privilege Escalation (LPE) vectors.
- **Strict Checksum Decoupling:** Remote archive downloads validate SHA256/SHA512 checksums against vendor endpoints before unpacking. Passing `-y` / `--yes` suppresses interactive prompts but **never** bypasses integrity validation; skipping verification requires the explicit `--skip-checksum` (or `--no-verify`) flag.
- **Metacharacter Repository Sanitization:** Configuration files read from workspaces (`.java-version` and `.sdkmanrc`) are strictly sanitized against shell metacharacters (`&`, `|`, `<`, `>`) before batch argument evaluation.

### What process exit codes does the CLI and installer return for CI/CD scripting?
All DiamTek JVM CLI commands, installer scripts, and MSI packages return standard Windows and POSIX process exit codes for deterministic automation in scripts, pipelines, and enterprise management agents:

| Exit Code | Meaning | Context / Resolution |
|:---------:|---------|----------------------|
| `0` | **Success** | The requested command, switch, installation, or test suite completed cleanly. |
| `1` | **General Error / Abort** | Safe abort (user selected `N` or pressed Enter on a confirmation prompt), requested JDK/tool not found, network unreachable, or invalid argument syntax. |
| `1602` | **User Canceled** | Standard Windows Installer code returned when an interactive MSI wizard is canceled by the user. |
| `1603` | **Fatal Error** | Standard Windows Installer error code. Typically indicates another running process is locking a destination directory; inspect verbose log (`msiexec /i ... /l*v log.txt`) for diagnostic details. |
| `3010` | **Reboot Required** | Not emitted by JVM (JVM requires zero system reboots), but universally handled by enterprise deployment tools (Intune / MECM) as a successful installation. |

In PowerShell automation scripts or CI workflows, check `$LASTEXITCODE` directly:
```powershell
jvm 21 --symlink
if ($LASTEXITCODE -ne 0) {
    throw "JVM execution failed with exit code $LASTEXITCODE"
}
```

### Can my engineering team adopt JVM on locked-down corporate laptops without IT admin tickets?
Yes! In locked-down corporate environments, developers rarely have local administrator (`UAC`) privileges. Traditional Java installations and updates write directly to protected system directories (`C:\Program Files\Java`) and machine-level registry hives (`HKLM`), requiring an IT helpdesk ticket and elevated technician credentials for every routine JDK change.

DiamTek JVM was intentionally architected from the ground up to eliminate this enterprise bottleneck:
1. **100% User-Space Storage Footprint:** Installs cleanly into `%LOCALAPPDATA%\DiamTek\JVM` without requiring write permissions to protected operating system locations.
2. **0-UAC Version Switching:** Uses Windows NTFS Directory Junctions (`%LOCALAPPDATA%\DiamTek\JVM\current`). Updating junction pointers in user-space requires **zero administrator privileges and 0 UAC prompts**.
3. **User-Level Environment Injection:** Automatically configures `JAVA_HOME` and system PATH additions inside the Current User (`HKCU`) registry hive and active PowerShell process memory via the PowerShell Profile hook.
4. **Ecosystem Build Tools in User-Space:** Modern build tools (Maven, Gradle, Kotlin, Scala, Groovy) are resolved and symlinked entirely inside `%LOCALAPPDATA%\DiamTek\JVM\candidates`, requiring no elevated permissions.
5. **Pre-Approved Corporate JDK Linking (`jvm link`):** If your corporate security policy prohibits downloading binaries from public mirrors, developers or sysadmins can stage approved JDK builds to any accessible path and register them with `jvm link <path> <name>` with zero administrative overhead.

This allows developers to remain productive and switch JDKs independently while preserving corporate endpoint lockdown compliance.

### How does DiamTek JVM fit into enterprise fleet management (Intune / MECM / GPO)?
DiamTek JVM is packaged as a native, single-file Windows Installer (`.msi`) built with WiX Toolset v4 with a per-user installation scope (`Scope="perUser"`):
- **Silent Distribution:** Enterprise IT administrators can silently deploy the MSI across thousands of endpoints without user interruption:
  ```cmd
  msiexec /i jvm-windows-1.0.0-x64.msi /qn /norestart
  ```
- **Registry-Based Intune Detection Rules:**
  - **Rule Type:** Registry
  - **Key Path:** `HKCU\Software\DiamTek\JVM`
  - **Value Name:** `installed`
  - **Detection Method:** Integer (DWORD) comparison equals `1`
- **File-Based Intune Detection Rules:**
  - **Path:** `%LOCALAPPDATA%\DiamTek\JVM\bin`
  - **File or Folder:** `jvm.bat`
- **Clean Fleet Uninstallation:**
  ```cmd
  msiexec /x jvm-windows-1.0.0-x64.msi /qn /norestart
  ```
- **Zero Reboot Footprint:** Installation, version switches, and uninstallation never require a workstation restart, preventing disruption to active corporate workflows.

---

[← Back to Documentation Overview](../README.md#📚-documentation)