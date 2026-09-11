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
- [How do I verify or manually configure the PowerShell Profile Hook?](#how-do-i-verify-or-manually-configure-the-powershell-profile-hook)
- [Does this require Administrator (UAC) privileges?](#does-this-require-administrator-uac-privileges)
- [How does it change the version globally without messing up my path?](#how-does-it-change-the-version-globally-without-messing-up-my-path)
- [Can I use this in a CI/CD pipeline (like GitHub Actions)?](#can-i-use-this-in-a-cicd-pipeline-like-github-actions)
- [Does it support custom JDKs or private binaries?](#does-it-support-custom-jdks-or-private-binaries)
- [Where are my JDKs and tools actually installed?](#where-are-my-jdks-and-tools-actually-installed)
- [How does Windows Terminal and Taskbar integration work?](#how-does-windows-terminal-and-taskbar-integration-work)
- [How do I completely uninstall it?](#how-do-i-completely-uninstall-it)
- [Why does Windows PowerShell say a script is not digitally signed or blocked?](#why-does-windows-powershell-say-a-script-is-not-digitally-signed-or-blocked)
- [Does the MSI test suite test real system integration or just file creation?](#does-the-msi-test-suite-test-real-system-integration-or-just-file-creation)
- [How do I cryptographically verify the authenticity and provenance of release binaries?](#how-do-i-cryptographically-verify-the-authenticity-and-provenance-of-release-binaries)
- [What process exit codes does the CLI and installer return for CI/CD scripting?](#what-process-exit-codes-does-the-cli-and-installer-return-for-cicd-scripting)

---

### Why use this over SDKMAN! on Windows?
SDKMAN! is an incredible tool, but it is fundamentally built for Unix architectures (bash). Running it on Windows requires layers of virtualization like Windows Subsystem for Linux (WSL), Git Bash, or Cygwin. This Java Version Manager is built **100% natively** for Windows Command Prompt (`cmd.exe`) and PowerShell. It requires zero dependencies and directly manipulates the Windows Registry.

### Why isn't `java` recognized immediately after I switch versions?
In most cases, it is recognized immediately! 
- **PowerShell (with Profile Hook):** The installer injects the `Set-JvmVar` hook into your PowerShell `$PROFILE`. When you switch versions with `jvm`, environment variables (`JAVA_HOME`, `Path`, toolchains) are dynamically injected into the active session memory on the fly without restarting.
- **Command Prompt (CMD):** In default **Symlink Mode**, your `PATH` points to the directory junction (`%LOCALAPPDATA%\DiamTek\JVM\current\bin`). The moment the junction target changes, all open CMD terminals resolve the new `java` binary immediately.
- **IDE Terminals & Background Daemons:** If an application (such as an open VS Code window, IntelliJ instance, or build daemon) cached the environment variables in its own process block before the switch, restarting that terminal or reload the IDE window will ensure the updated variables are picked up.

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

### Does it support custom JDKs or private binaries?
Yes! You can use `jvm link <path> [name]` to register any custom or private JDK into the manager. It will integrate seamlessly into the dynamic menus and CLI routing.

### Where are my JDKs and tools actually installed?
By default, auto-downloaded JDKs are installed to `C:\Program Files\Java\<vendor-jdk>`, and ecosystem tools (Maven, Gradle, Kotlin, Scala, Groovy) are securely stored and cached in `%LOCALAPPDATA%\DiamTek\JVM\candidates\<tool>`.

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
When you download `.ps1` scripts or zip files through a browser, Windows tags them with a `Zone.Identifier` NTFS stream (`ZoneId=3` - Internet). Under the default `RemoteSigned` policy, PowerShell verifies digital signatures before running remote scripts. Open-source scripts without a commercial certificate will be blocked.

You can unblock files in two ways:
1. **PowerShell:** Run `Unblock-File .\packages\msi\test-msi.ps1`.
2. **File Explorer:** Right-click the `.ps1` file -> **Properties** -> check **Unblock** at the bottom -> click **OK**.
Alternatively, run with execution policy bypass:
`powershell -NoProfile -ExecutionPolicy Bypass -File .\packages\msi\test-msi.ps1`

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

---

[← Back to Documentation Overview](../README.md#📚-documentation)