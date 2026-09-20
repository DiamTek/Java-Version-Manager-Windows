<h1 align="center">Frequently Asked Questions (FAQ)</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md) &nbsp;•&nbsp; [🛡️ Security](SECURITY.md) &nbsp;•&nbsp; [🤝 Contributing](CONTRIBUTING.md) &nbsp;•&nbsp; [💬 Support](SUPPORT.md)

</div>


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
- [How do I check my current active Java version and environment status?](#how-do-i-check-my-current-active-java-version-and-environment-status)
- [How do I find the exact executable path of java or build tools for my IDE/scripts?](#how-do-i-find-the-exact-executable-path-of-java-or-build-tools-for-my-idescripts)
- [How do I free up disk space from downloaded JDK installers? (jvm clean vs jvm clear)](#how-do-i-free-up-disk-space-from-downloaded-jdk-installers-jvm-clean-vs-jvm-clear)
- [What is `jvm doctor` and how does it diagnose system conflicts?](#what-is-jvm-doctor-and-how-does-it-diagnose-system-conflicts)
- [How do I pin or lock a Java version for my project? (`jvm pin` / `jvm local`)](#how-do-i-pin-or-lock-a-java-version-for-my-project-jvm-pin--jvm-local)
- [How do I jump directly to active tool folders in File Explorer? (`jvm open` / `jvm home`)](#how-do-i-jump-directly-to-active-tool-folders-in-file-explorer-jvm-open--jvm-home)
- [Are SDKMAN! commands like `sdk use` supported? (`jvm use` / `jvm default`)](#are-sdkman-commands-like-sdk-use-supported-jvm-use--jvm-default)
- [Why does Windows PowerShell say a script is not digitally signed or blocked?](#why-does-windows-powershell-say-a-script-is-not-digitally-signed-or-blocked)
- [What should I do if Windows Defender SmartScreen warns about an "Unknown Publisher"?](#what-should-i-do-if-windows-defender-smartscreen-warns-about-an-unknown-publisher)
- [Does the MSI test suite test real system integration or just file creation?](#does-the-msi-test-suite-test-real-system-integration-or-just-file-creation)
- [How do I cryptographically verify the authenticity and provenance of release binaries?](#how-do-i-cryptographically-verify-the-authenticity-and-provenance-of-release-binaries)
- [How does JVM protect against local privilege escalation and corrupted downloads?](#how-does-jvm-protect-against-local-privilege-escalation-and-corrupted-downloads)
- [What process exit codes does the CLI and installer return for CI/CD scripting?](#what-process-exit-codes-does-the-cli-and-installer-return-for-cicd-scripting)
- [Can my engineering team adopt JVM on locked-down corporate laptops without IT admin tickets?](#can-my-engineering-team-adopt-jvm-on-locked-down-corporate-laptops-without-it-admin-tickets)
- [How does DiamTek JVM fit into enterprise fleet management (Intune / MECM / GPO)?](#how-does-diamtek-jvm-fit-into-enterprise-fleet-management-intune--mecm--gpo)
- [What is the PowerShell Profile hook and how do I manage it? (`jvm hook`)](#what-is-the-powershell-profile-hook-and-how-do-i-manage-it-jvm-hook)
- [How do I enable and use dynamic Tab-Completion in PowerShell?](#how-do-i-enable-and-use-dynamic-tab-completion-in-powershell)
- [How do I use JVM in CI/CD pipelines without ANSI color code artifacts? (NO_COLOR)](#how-do-i-use-jvm-in-cicd-pipelines-without-ansi-color-code-artifacts-no_color)
- [What shorthand CLI aliases does JVM support? (jvm ls, jvm rm, jvm info)](#what-shorthand-cli-aliases-does-jvm-support-jvm-ls-jvm-rm-jvm-info)
- [How do I automatically switch Java versions when navigating into a project directory? (cd auto-switching)](#how-do-i-automatically-switch-java-versions-when-navigating-into-a-project-directory-cd-auto-switching)
- [Which JDK vendors are supported, and how do BellSoft Liberica and IBM Semeru differ?](#which-jdk-vendors-are-supported-and-how-do-bellsoft-liberica-and-ibm-semeru-differ)
- [How do update channels work, and how do I switch between Stable and Nightly?](#how-do-update-channels-work-and-how-do-i-switch-between-stable-and-nightly)
- [How does JVM handle corporate proxies and NTLM/Kerberos authentication?](#how-does-jvm-handle-corporate-proxies-and-ntlmkerberos-authentication)
- [Is JVM compatible with PowerShell Constrained Language Mode (CLM) and AppLocker/WDAC?](#is-jvm-compatible-with-powershell-constrained-language-mode-clm-and-applockerwdac)
- [How does JVM switch Java versions without administrative privileges or symlink permissions?](#how-does-jvm-switch-java-versions-without-administrative-privileges-or-symlink-permissions)
- [How does JVM protect my system PATH and environment variables from corruption?](#how-does-jvm-protect-my-system-path-and-environment-variables-from-corruption)
- [What happens during uninstallation? Are my installed JDKs deleted?](#what-happens-during-uninstallation-are-my-installed-jdks-deleted)
- [How can I run the automated security test suite locally?](#how-can-i-run-the-automated-security-test-suite-locally)

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
To check profile hook status across all detected PowerShell profiles (Windows PowerShell 5.1 and PowerShell 7+):
```cmd
jvm hook status
```
*(You can also run `jvm doctor` to audit the hook alongside your overall system health).* In PowerShell, you can also query `$PROFILE` directly:
```powershell
Get-Content $PROFILE -ErrorAction SilentlyContinue | Select-String "jvm"
```
If properly configured, this command outputs the `# >>> jvm >>>` sentinel and the `function jvm { ... }` wrapper definition.

#### 2. Manual Installation or Dotfile Configuration
If your profile was not configured automatically (e.g., if you manage dotfiles across multiple machines via Git or use a custom `$PROFILE` location), you can inject or repair the hook at any time:
- **CLI Command:** Run `jvm hook` (or `jvm hook install`). You can also inspect with `jvm hook status` or cleanly remove it with `jvm hook remove`.
- **Interactive Menu:** Run `jvm`, navigate to **Settings** (`3`), and select **PowerShell Profile Hook** (`2`).
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
Yes! The tool supports headless execution. You can bypass the interactive menu entirely by passing arguments directly, for example: `jvm install 21 -y` or `jvm 21`.

### Can I temporarily run a build with a specific Java version without altering my global environment?
Yes! DiamTek JVM provides clean options depending on whether you want one-off ephemeral execution, directory pinning, or session isolation:

1. **Ephemeral One-Off Subshell Runner (`jvm exec` / `jvm run` — Recommended):**
   Execute any build or command directly in an isolated child subshell with zero impact on your global environment, active Directory Junction (`current`), or other open terminal windows:
   ```powershell
   jvm exec 17 -- gradlew build
   # Or without double-dash:
   jvm run 21 mvn clean package
   ```
   The child subshell runs with `%JAVA_HOME%` and `%PATH%` configured specifically for the requested JDK, executes your command with full argument fidelity, and returns the command's exact exit code directly to the host shell.

2. **True Session Isolation via `.java-version` (`jvm pin`):**
   Lock the project to a specific JDK using `jvm pin <version>`. When you run `jvm` in that directory, it activates the pinned Java version **only for that active terminal process memory**—leaving the shared NTFS Directory Junction (`%LOCALAPPDATA%\DiamTek\JVM\current`), other open terminals, and your Windows Registry completely untouched.

3. **In-Process Environment Overrides (Manual Subshell):**
   To execute a single build against a specific JDK path manually:
   - **Command Prompt:**
     ```cmd
     cmd.exe /c "set JAVA_HOME=C:\Program Files\Java\jdk-17&& set PATH=C:\Program Files\Java\jdk-17\bin;%PATH%&& gradlew build"
     ```
   - **PowerShell:**
     ```powershell
     & { $env:JAVA_HOME = "C:\Program Files\Java\jdk-17"; $env:Path = "$env:JAVA_HOME\bin;$env:Path"; ./gradlew build }
     ```

4. **Sequential Execution (`&&`):**
   You can also chain commands sequentially:
   ```cmd
   jvm 17 && gradlew build
   ```
   *(Note: Because `&&` runs two commands in sequence, `jvm 17` first updates your active Directory Junction to JDK 17 globally, and then `gradlew build` runs using that newly activated version).*

### Does it support custom JDKs or private binaries?
Yes! You can use `jvm link <path> [name]` to register any custom or private JDK into the manager. It will integrate seamlessly into the dynamic menus and CLI routing.

To view an inventory of all currently linked custom JDKs (including junction targets and integrity status), run:
```powershell
jvm link
```

### Where are my JDKs and tools actually installed?
By default, auto-downloaded JDKs are installed to `C:\Program Files\Java\<vendor-jdk>`, and ecosystem tools (Maven, Gradle, Kotlin, Scala, Groovy) are securely stored and cached in `%LOCALAPPDATA%\DiamTek\JVM\candidates\<tool>`. Custom Bring Your Own JDKs (`jvm link`) are cataloged as directory junctions in `%LOCALAPPDATA%\JavaVersionManager\links`. Additionally, JVM automatically scans and discovers pre-existing JDKs in `C:\Java`, `%USERPROFILE%\.jdks` (IntelliJ IDEA), `%USERPROFILE%\.gradle\jdks` (Gradle toolchains), and `%USERPROFILE%\scoop\apps\*` (Scoop).

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

4. **GitHub API Rate Limiting & Zero-Quota Redirect Fallback (`GITHUB_TOKEN`):**
   When discovering latest releases for GitHub-backed ecosystem candidates (Maven, Kotlin, Scala), JVM queries the GitHub Releases API. GitHub restricts unauthenticated API queries to 60 requests/hour per public IP address.
   
   To eliminate disruption, JVM incorporates an automatic **HTTP 302 redirect fallback** against `releases/latest`: if the API rate limit is reached, JVM automatically sniffs the redirection target to extract the release tag with zero API quota consumption (`[ WARNING] GitHub API Rate Limit reached. Trying redirect fallback...`). (Gradle and Groovy resolve independently via `services.gradle.org` and `api.sdkman.io`).
   
   If you operate in high-throughput CI/CD pipelines or restricted network environments where you want to bypass rate limits entirely, set your personal GitHub token:
   ```powershell
   $env:GITHUB_TOKEN = "ghp_your_personal_access_token"
   ```
   Or in Command Prompt:
   ```cmd
   set GITHUB_TOKEN=ghp_your_personal_access_token
   ```

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
- **Windows Installer (MSI):** Run `msiexec /x jvm-windows-1.0.1-x64.msi /qn`.

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
gh attestation verify jvm-windows-1.0.1-x64.msi --repo DiamTek/Java-Version-Manager-Windows
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
gh attestation verify jvm-windows-1.0.1-x64.msi --repo DiamTek/Java-Version-Manager-Windows
```
Upon verification, the GitHub CLI outputs:
```text
Loaded digest sha256:... for jvm-windows-1.0.1-x64.msi
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

<a id="how-does-diamtek-jvm-fit-into-enterprise-fleet-management-intune--mecm--gpo"></a>
### How does DiamTek JVM fit into enterprise fleet management (Intune / MECM / GPO)?
DiamTek JVM is packaged as a native, single-file Windows Installer (`.msi`) built with WiX Toolset v4 with a per-user installation scope (`Scope="perUser"`):
- **Silent Distribution:** Enterprise IT administrators can silently deploy the MSI across thousands of endpoints without user interruption:
  ```cmd
  msiexec /i jvm-windows-1.0.1-x64.msi /qn /norestart
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
  msiexec /x jvm-windows-1.0.1-x64.msi /qn /norestart
  ```
- **Zero Reboot Footprint:** Installation, version switches, and uninstallation never require a workstation restart, preventing disruption to active corporate workflows.

<a id="how-do-i-check-my-current-active-java-version-and-environment-status"></a>
### How do I check my current active Java version and environment status?
Run `jvm current` (or aliases `jvm env`, `jvm status`, `jvm info`, `jvm whoami`) from any CMD, PowerShell, or Windows Terminal window:
```cmd
jvm env
```
This prints a structured, ANSI color-coded dashboard displaying:
1. **Java Version & Vendor:** Exact distribution name and version number (e.g., `Eclipse Adoptium 21.0.12.1`).
2. **`JAVA_HOME` Path:** The directory currently designated as your active Java home.
3. **Executable Binary:** The absolute path to the active `java.exe` binary.
4. **Switching Mode:** Indicates whether you are running in `[Symlink Mode]` (highlighted in green, User Junction, UAC Free) or `[Registry Mode]` (highlighted in red, Machine HKLM).
5. **Junction Link:** The real-time target pointed to by `%LOCALAPPDATA%\DiamTek\JVM\current`, highlighted in green (or yellow if inactive).
6. **Update Channel:** The active delivery channel badge: `[Stable]` (green, official releases) or `[Nightly]` (purple, cutting-edge `main` branch).
7. **Ecosystem Build Tools:** Live status of installed tools such as Maven, Gradle, and Kotlin with green `[ACTIVE]` indicators.

<a id="how-do-i-find-the-exact-executable-path-of-java-or-build-tools-for-my-idescripts"></a>
### How do I find the exact executable path of java or build tools for my IDE/scripts?
Run `jvm which` (or its alias `jvm path`) to print the resolved executable path directly to `stdout`:
```powershell
# Resolve active Java executable
jvm which

# Resolve specific ecosystem build tool binaries
jvm which maven
jvm which gradle
jvm which kotlin
```
Because `jvm which` prints only the raw path and returns standard exit codes (`0` on success, `1` on error), it is ideal for scripting:
```powershell
# PowerShell automation
$javaPath = (jvm which)
& $javaPath -version
```

<a id="how-do-i-free-up-disk-space-from-downloaded-jdk-installers-jvm-clean-vs-jvm-clear"></a>
<a id="what-is-the-difference-between-jvm-clean-and-jvm-clear"></a>
### How do I free up disk space from downloaded JDK installers? (jvm clean vs jvm clear)
Modern Java Development Kit (JDK) distributions (Adoptium Temurin, Oracle JDK, Amazon Corretto, Azul Zulu, Microsoft Build of OpenJDK, GraalVM) and JVM ecosystem build tools (Apache Maven, Gradle, Kotlin, Scala, Apache Groovy) range from 150 MB to over 450 MB per archive. Over time, frequent version updates and multi-vendor experimentation can leave gigabytes of compressed installer archives, intermediate extraction workspaces, and temporary staging artifacts cluttering your Windows workstation.

DiamTek Java Version Manager cleanly bifurcates maintenance workflows into two specialized, purpose-built commands: **`jvm clean`** (for non-destructive filesystem cache and disk space reclamation) and **`jvm clear`** (for environment variable resets, PATH shadowing remediation, and registry slate sanitization).

---

#### 1. `jvm clean` — Disk Cache Pruner & Storage Reclamation
Use `jvm clean` whenever you want to reclaim local disk space without modifying active Java runtimes, ecosystem tool configurations, or environment settings. When you install or update JDKs and build tools, JVM downloads compressed `.zip` or `.tar.gz` archives, extracts them into intermediate staging workspaces, verifies SHA256/SHA512 checksums, and deploys the runtimes into their permanent locations (`C:\Program Files\Java` or `%LOCALAPPDATA%\DiamTek\JVM\candidates`).

Running `jvm clean` executes a thorough, automated garbage-collection sweep across all temporary directories:

```cmd
jvm clean
```

##### 🧹 Complete Artifact Purge Scope:
* **Temporary Installer Archives:** Purges all cached `.zip` and `.tar.gz` downloads in `%TEMP%\jdk_*_download.*`.
* **Intermediate Extraction Workspaces:** Recursively removes orphaned `%TEMP%\jdk_*_extract` extraction directory trees left behind from completed or interrupted unpack operations.
* **Transient Helper Scripts:** Sweeps temporary PowerShell download runners and handoff batch scripts (`%TEMP%\jvm_dl_*.ps1`, `%TEMP%\jvm_install_*.ps1`, `%TEMP%\jvm_updater_*.bat`, `%TEMP%\jvm_uninstall_*.bat`, `%TEMP%\jvm_uninstall_*.ps1`).
* **Candidate Tool Download Cache:** Empties `%LOCALAPPDATA%\DiamTek\JVM\downloads\*` where candidate tool zip payloads are staged during installation.
* **Candidate Staging Directories:** Cleans transient extraction workspaces in `%LOCALAPPDATA%\DiamTek\JVM\candidates\*\temp_*`.
* **Process Communication Files:** Removes stale `%TEMP%\.jvm_session_target` process session exchange files.

##### 🛡️ Safety & Non-Destructive Guarantee:
* **100% Non-Destructive:** `jvm clean` never deletes installed JDK runtimes (`C:\Program Files\Java`), never removes registered ecosystem tools (`%LOCALAPPDATA%\DiamTek\JVM\candidates`), never breaks active Directory Junctions (`%LOCALAPPDATA%\DiamTek\JVM\current`), and never alters your Windows Registry (`PATH`, `JAVA_HOME`).
* **Live Storage Reclamation Reporting:** Dynamically calculates and displays the exact number of files deleted and total megabytes (MB) of storage reclaimed on disk.

---

#### 2. `jvm clear` — Environment Variable & Registry Slate Reset
Use `jvm clear` when you need to completely de-activate Java from your system environment or troubleshoot stubborn configuration conflicts, such as rogue installers overriding your selected version:

```cmd
jvm clear
```

##### 🎯 Key Problems Solved: PATH Shadowing & Ghost Registries:
* **Phantom Oracle Path Elimination:** Legacy MSI installers from Oracle Java frequently inject hardcoded shortcut directories into the front of the Machine `PATH` (such as `C:\Program Files\Common Files\Oracle\Java\javapath` or `C:\ProgramData\Oracle\Java\javapath`). Because Windows evaluates Machine paths before User environment variables, `java -version` can remain stuck on an obsolete JRE even after switching versions in JVM. `jvm clear` actively hunts down and scrubs these rogue Oracle paths from both Machine and User registries.
* **Directory Junction Teardown:** Cleanly removes the `%LOCALAPPDATA%\DiamTek\JVM\current\bin` directory junction from your User and System `PATH`.
* **JAVA_HOME Unsetting:** Completely unbinds and wipes `JAVA_HOME` across both User (`HKCU\Environment`) and Machine (`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`) scopes.
* **Clean Baseline Reset:** After executing `jvm clear`, running `jvm <version>` (e.g., `jvm 21`) reinstates a pristine, conflict-free environment where your chosen JDK holds 100% priority.

---

#### 📊 Architectural Comparison: `jvm clean` vs `jvm clear`

| Feature / Attribute | `jvm clean` (Disk Cache Pruner) | `jvm clear` (Environment Slate Wipe) |
|---|---|---|
| **Primary Objective** | Reclaim local disk space from cached archives | Reset Java environment variables and fix PATH shadowing |
| **Filesystem Action** | Deletes temporary `.zip`, `.tar.gz`, extract trees, and helper scripts | Tears down directory junction and removes phantom shortcuts |
| **Registry Action** | **None** (zero registry modifications) | Purges `JAVA_HOME`, scrubs `PATH`, removes rogue Oracle entries |
| **Installed JDKs Impact** | **Untouched** (all runtimes in `Program Files` and AppData remain safe) | **Untouched** (runtimes remain on disk, but environment bindings are cleared) |
| **Ecosystem Tools Impact** | Purges download cache only; installed versions remain intact | Clears active session variables; tool directories remain intact |
| **Privileges Required** | Standard User (zero UAC elevation required) | Standard User for User PATH; requests UAC only if cleaning Machine registry |
| **Automated Backup** | Not required (only temporary cache files deleted) | **Automatic timestamped `.reg` export** to AppData before changes |
| **Reversibility** | Files deleted; archives re-downloaded if needed | **100% reversible** via one-click `.reg` import or running `jvm <version>` |
| **When to Run** | Routine maintenance, after large installations, or low disk space | When `java -version` reports the wrong version, or resetting environment |

---

#### 💾 Automated Safety Backups & Rollback Walkthrough
To guarantee total peace of mind before executing any destructive registry modifications, `jvm clear` automatically exports full timestamped `.reg` backup files before touching a single environment variable:

* **Backup Destination:** `%LOCALAPPDATA%\DiamTek\JVM\backups\`
* **Machine Registry Snapshot:** `sys_env_<date>_<time>.reg` (Backs up `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`)
* **User Registry Snapshot:** `usr_env_<date>_<time>.reg` (Backs up `HKCU\Environment`)

##### How to Restore Your Environment from Backup:
If you ever need to restore your workstation's previous environment state after running `jvm clear`:

1. **Via Windows File Explorer (GUI):**
   - Press **Win + R**, paste `%LOCALAPPDATA%\DiamTek\JVM\backups`, and hit **Enter** (or run `explorer.exe "$env:LOCALAPPDATA\DiamTek\JVM\backups"` from PowerShell).
   - Locate the generated `.reg` files matching the date and time of your operation.
   - Double-click `usr_env_<date>_<time>.reg` (and `sys_env_<date>_<time>.reg` if Machine variables were altered).
   - Click **Yes** when Windows Registry Editor prompts to merge the keys, then restart your terminal.

2. **Via Command Prompt (CMD):**
   ```cmd
   reg import "%LOCALAPPDATA%\DiamTek\JVM\backups\usr_env_<date>_<time>.reg"
   reg import "%LOCALAPPDATA%\DiamTek\JVM\backups\sys_env_<date>_<time>.reg"
   ```

3. **Via PowerShell:**
   ```powershell
   reg import "$env:LOCALAPPDATA\DiamTek\JVM\backups\usr_env_<date>_<time>.reg"
   reg import "$env:LOCALAPPDATA\DiamTek\JVM\backups\sys_env_<date>_<time>.reg"
   ```

<a id="what-is-jvm-doctor-and-how-does-it-diagnose-system-conflicts"></a>
### What is `jvm doctor` and how does it diagnose system conflicts?
`jvm doctor` is an automated, all-in-one system diagnostic audit command. It performs a comprehensive 7-point health check to detect configuration errors, corrupted directory junctions, and environment shadowing before they cause build failures:

```cmd
jvm doctor
```

It analyzes:
1. **Storage Root Accessibility:** Verifies that `%LOCALAPPDATA%\DiamTek\JVM` exists and is writable.
2. **Architecture Mode & Junction Integrity:** Checks if Symlink Mode is active and validates that `%LOCALAPPDATA%\DiamTek\JVM\current` points to a valid JDK directory containing `bin\java.exe`.
3. **Registry Synchronization:** Checks both User (`HKCU\Environment`) and Machine (`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`) registries for `JAVA_HOME`.
4. **PATH Precedence & Shadowing:** Runs `where.exe java` to detect rogue Oracle `javapath` or `System32\java.exe` shims overriding JVM in your system `PATH`.
5. **PowerShell Profile Hook:** Checks whether the `# >>> jvm >>>` function wrapper is present in `$PROFILE`.
6. **CPU Architecture:** Confirms native architecture matches (`x64` or `ARM64`).
7. **Discovered JDK Inventory:** Reports the total number of installed and recognized JDKs.

If any warnings or errors are found, `jvm doctor` returns process exit code `1` and offers actionable remediation steps (e.g. running `jvm clear`). If everything is clean, it returns exit code `0`.

<a id="how-do-i-pin-or-lock-a-java-version-for-my-project-jvm-pin--jvm-local"></a>
### How do I pin or lock a Java version for my project? (`jvm pin` / `jvm local`)
You can lock your repository to a specific JDK version using the `jvm pin` (or `jvm local`) command:

```powershell
# Lock the current project directory to JDK 21
jvm pin 21

# Pin with specific vendor and architecture flags
jvm pin 21 --vendor adoptium
jvm pin 17 --legacy

# Check the current directory's pinned version
jvm pin
# Alias: jvm local
```

Running `jvm pin <version>` writes a standard `.java-version` file directly in your current directory. When any developer runs `jvm` inside that directory, DiamTek JVM reads the file and activates that version locally with True Session Isolation (without modifying the global Windows Registry).

<a id="how-do-i-jump-directly-to-active-tool-folders-in-file-explorer-jvm-open--jvm-home"></a>
### How do I jump directly to active tool folders in File Explorer? (`jvm open` / `jvm home`)
Instead of manually navigating through hidden `%LOCALAPPDATA%` folders or deep `Program Files` directories, use `jvm open` to launch Windows File Explorer directly targeting your tools:

```powershell
# Open active JDK directory
jvm open

# Open specific candidate tool directory
jvm open maven
jvm open gradle
jvm open kotlin

# Open a specific JDK installation by version
jvm open 21

# Open the JVM root storage folder (%LOCALAPPDATA%\DiamTek\JVM)
jvm open root
# Alias: jvm home
```

<a id="are-sdkman-commands-like-sdk-use-supported-jvm-use--jvm-default"></a>
### Are SDKMAN! commands like `sdk use` supported? (`jvm use` / `jvm default`)
Yes! For developers transitioning from macOS or Linux who are used to SDKMAN! or nvm command patterns, DiamTek JVM provides 1:1 transparent command aliases:

```powershell
# Switch active JDK globally (identical to jvm 21)
jvm use 21

# Set default JDK globally (identical to jvm 21)
jvm default 21

# Switch locally for current terminal session only (SDKMAN 'sdk use' semantics)
jvm use 21 --session
```

Both `jvm use` and `jvm default` support semantic routing (`jvm use latest`, `jvm use lts`) and all flag overrides (`--vendor`, `--symlink`, `--legacy`).

**What is the difference between `jvm use` and `jvm default`?**
In SDKMAN!, `sdk use` applies strictly to the current shell while `sdk default` alters the global symlink. In DiamTek JVM, standard switches (`jvm 21`, `jvm use 21`, `jvm default 21`) switch the active JDK globally via the Directory Junction to match the Windows `nvm-windows` convention. If you want SDKMAN's session-isolated behavior, pass `--session` (`jvm use 21 --session`).

<a id="what-is-the-powershell-profile-hook-and-how-do-i-manage-it-jvm-hook"></a>
### What is the PowerShell Profile hook and how do I manage it? (`jvm hook`)
Because a child process in Windows cannot directly alter its parent shell's environment variables, running `jvm <version>` updates your Windows Registry and Directory Junctions, but would normally require restarting your terminal window for the current session to inherit the changes.

The **PowerShell Profile hook** eliminates this friction. It adds a lightweight, non-invasive wrapper function to your `$PROFILE` that intercepts `jvm` commands:
1. When you switch versions (`jvm 21`), the engine writes the target environment variables to a temporary session file.
2. The PowerShell wrapper reads the session file, calls `Set-JvmVar`, and updates `$env:JAVA_HOME` and `$env:Path` **live in memory** inside your current PowerShell session.
3. This provides instantaneous, seamless runtime updates across all your open PowerShell tabs with zero restarts.

#### Managing the Hook (`jvm hook`)
You can inspect, install, or remove the wrapper function at any time without touching your global User `PATH`:

```powershell
# Check hook status across Windows PowerShell and PowerShell 7+ profiles
jvm hook status
# Alias: jvm hook check

# Re-install or update the hook
jvm hook install
# Aliases: jvm hook, jvm hook setup

# Safely remove the hook from all profiles
jvm hook remove
```
You can also toggle the hook directly from the interactive TUI by navigating to **Settings** (`3`) -> **Option 2** (`PowerShell Profile Hook`).

<a id="how-do-i-enable-and-use-dynamic-tab-completion-in-powershell"></a>
### How do I enable and use dynamic Tab-Completion in PowerShell?
DiamTek JVM provides native, sub-millisecond tab-completion for **Windows PowerShell 5.1** and modern **PowerShell 7+ (`pwsh`)** using .NET's `Register-ArgumentCompleter` API.

#### 1. Setup & Reloading
Dynamic completion is installed automatically when configuring the PowerShell hook:
```powershell
jvm hook
```
Once installed, open a fresh terminal tab or reload your active profile in your current shell:
```powershell
. $PROFILE
```

#### 2. Features & Context Awareness
- **Universal Invocation Completion:** Autocompletion triggers whether you type `jvm <Tab>`, `jvm.bat <Tab>`, or `.\jvm.bat <Tab>`, guaranteeing friction-free ergonomics across both installed PATH commands and local repository checkouts.
- **Command & Tool Completion:** Typing `jvm ` and hitting `<Tab>` cycles through all canonical commands (`list`, `install`, `uninstall`, `use`, `pin`, `current`, `doctor`, `clean`, `update`, etc.), ergonomic shorthand aliases (`ls`, `rm`, `info`, `whoami`, `check`, `prune`, `path`, `home`, `local`, `run`), and ecosystem candidate tools (`java`, `maven`, `gradle`, `kotlin`, `scala`, `groovy`).
- **Installed Version Cycling:** When typing `jvm use `, `jvm default `, `jvm pin `, or `jvm uninstall `, pressing `<Tab>` queries `%LOCALAPPDATA%\JavaVersionManager\links` and `%USERPROFILE%\.jdks` to suggest installed JDK versions (e.g. `21`, `17`, `11`).
- **Vendor Filtering (All 8 Distributions):** `jvm install 21 --vendor <Tab>` autocompletes `adoptium`, `temurin`, `oracle`, `corretto`, `zulu`, `microsoft`, `graalvm`, `liberica`, `bellsoft`, `semeru`, `ibm`, `openj9`.
- **Target Folder Completion:** `jvm open <Tab>` autocompletes `home`, `dir`, `bin`, `config`, `cache`, `downloads`, `backup`, `backups`, `links`.
- **Flag Overrides:** `jvm --<Tab>` autocompletes all supported command flags (`--vendor`, `--symlink`, `--registry`, `--legacy`, `--session`, `--global`, `--skip-checksum`, `--no-verify`, `--latest`, `--yes`, `-y`, `--no-color`, `--version`, `--help`).

<a id="how-do-i-use-jvm-in-cicd-pipelines-without-ansi-color-code-artifacts-no_color"></a>
### How do I use JVM in CI/CD pipelines without ANSI color code artifacts? (NO_COLOR)
When redirecting command output to text files (`jvm list > jdks.txt`) or running in automated CI runners (GitHub Actions, Azure DevOps, Jenkins, GitLab CI), terminal color codes can pollute raw logs with escape sequences like `←[92m`.

DiamTek JVM adheres 100% to the cross-industry [NO_COLOR specification](https://no-color.org):
1. **Via Environment Variable:** If `$env:NO_COLOR` is defined and non-empty, all ANSI color codes are completely suppressed.
   ```yaml
   # GitHub Actions Workflow
   env:
     NO_COLOR: "1"
   ```
2. **Via CLI Flag:** Pass `--no-color` to any command:
   ```cmd
   jvm list --no-color
   jvm doctor --no-color
   ```
3. **Clean Redirection:**
   ```powershell
   jvm list --no-color | Out-File -FilePath jdks.txt -Encoding utf8
   ```

<a id="what-shorthand-cli-aliases-does-jvm-support-jvm-ls-jvm-rm-jvm-info"></a>
### What shorthand CLI aliases does JVM support? (jvm ls, jvm rm, jvm info)
To minimize friction for developers accustomed to Linux, macOS, Docker, Git, or SDKMAN!, JVM supports the following command aliases:

| Habit / Shorthand Alias | Canonical Command | Description |
|-------------------------|-------------------|-------------|
| `jvm ls` | `jvm list` | Lists all installed JDKs, toolchains, and vendors |
| `jvm rm <version>` | `jvm uninstall <version>` | Uninstalls a specific JDK release or tool |
| `jvm remove <version>` | `jvm uninstall <version>` | Alternative uninstall alias |
| `jvm info` | `jvm current` | Displays detailed status card for active JDK and ecosystem tools |
| `jvm whoami` | `jvm current` | Identity check showing which binary owns the shell |
| `jvm check` | `jvm doctor` | Performs comprehensive pre-flight health diagnostic audit |
| `jvm prune` | `jvm clean` | Purges download cache and extraction artifacts |
| `jvm path` | `jvm which` | Displays exact filesystem path to active binary |
| `jvm home` | `jvm open` | Opens active candidate or root in File Explorer |
| `jvm local [version]` | `jvm pin [version]` | Reads or locks directory-level `.java-version` file |
| `jvm run <ver> <cmd>` | `jvm exec <ver> <cmd>` | Runs command in ephemeral isolated subshell |

<a id="how-do-i-automatically-switch-java-versions-when-navigating-into-a-project-directory-cd-auto-switching"></a>
### How do I automatically switch Java versions when navigating into a project directory? (cd auto-switching)
Whenever you run `jvm` in any directory containing a `.java-version` or `.sdkmanrc` file, the manager automatically evaluates the file and switches your current shell session to that version without opening interactive menus.

For full automatic switching upon changing directories (`cd`), you can add a lightweight prompt hook to your PowerShell `$PROFILE`:

```powershell
# Add to your Microsoft.PowerShell_profile.ps1:
function Invoke-JvmAutoEnv {
    if (Test-Path -LiteralPath ".java-version") {
        $pinned = (Get-Content ".java-version" -First 1).Trim()
        if ($pinned -and ($env:JAVA_HOME -notmatch [regex]::Escape($pinned))) {
            jvm $pinned --session
        }
    } elseif (Test-Path -LiteralPath ".sdkmanrc") {
        $sdkVer = (Get-Content ".sdkmanrc" | Where-Object { $_ -match '^java=' } | ForEach-Object { ($_ -split '=')[1] }).Trim()
        if ($sdkVer) {
            jvm $sdkVer --session
        }
    }
}

# Attach to PowerShell prompt function
if (Test-Path function:prompt) {
    $existingPrompt = $function:prompt
    function prompt {
        Invoke-JvmAutoEnv
        & $existingPrompt
    }
}
```
This guarantees that whenever you `cd` into any repository with a `.java-version` or `.sdkmanrc` file, your `JAVA_HOME` and `PATH` are instantly configured for that session.

<a id="which-jdk-vendors-are-supported-and-how-do-bellsoft-liberica-and-ibm-semeru-differ"></a>
### Which JDK vendors are supported, and how do BellSoft Liberica and IBM Semeru differ?
DiamTek JVM provides first-class native support for **8 upstream JDK distribution vendors**:

1. **Oracle OpenJDK / Standard** — Upstream reference implementation directly from Oracle Corporation, providing rapid access to the newest six-month feature releases.
2. **Adoptium (Eclipse Temurin)** — Industry-standard, multi-platform OpenJDK distribution maintained by the Eclipse Foundation and the Adoptium Working Group. Ideal default choice for general Java development and enterprise workloads.
3. **GraalVM CE** — Oracle Labs high-performance Polyglot runtime featuring `native-image` Ahead-Of-Time (AOT) compilation, producing lightning-fast native Windows executables (`.exe`).
4. **Amazon Corretto** — Production-ready, multi-platform distribution maintained by Amazon Web Services, backed by long-term enterprise support and hardened for AWS cloud workloads.
5. **Azul Zulu** — Fully certified, 100% TCK-compliant OpenJDK builds from Azul Systems, offering deep backward compatibility across legacy and modern Java versions (8 through 25+).
6. **Microsoft Build of OpenJDK** — Enterprise LTS distribution built and supported by Microsoft, optimized for Windows native architecture and Azure cloud services.
7. **BellSoft Liberica** — The official standard base runtime image for the Spring Boot framework. Liberica provides 100% TCK-verified OpenJDK builds with both standard HotSpot and full JavaFX / LibericaFX graphical desktop library bundles, compact memory footprints, and enterprise performance.
8. **IBM Semeru Runtimes** — Powered by the **Eclipse OpenJ9** virtual machine rather than the conventional OpenJDK HotSpot engine. Semeru Runtimes excel in memory-constrained cloud environments, container deployments, and high-density microservices.

#### Why Choose BellSoft Liberica?
- **Spring Framework First:** Chosen by VMware/Spring as the default JVM provider for Spring Boot container images due to its minimal startup footprint and rigorous TCK compliance.
- **Desktop & JavaFX Ready:** Liberica includes full runtime support for JavaFX, making it the premier choice for cross-platform desktop UI development on Windows without needing external OpenJFX modules.
- **Dual Architecture:** Fully supports both Windows x64 and Windows ARM64 hardware out of the box.
- **Install command:** `jvm install 21 --vendor liberica`

#### Why Choose IBM Semeru (OpenJ9)?
- **Radical RAM Savings:** The Eclipse OpenJ9 runtime uses up to **50% less physical memory (RSS)** after startup compared to standard HotSpot engines, allowing significantly higher container and process density on the same hardware.
- **Fast Ramp-Up & Startup:** Leverages shared class caches and dynamic Ahead-of-Time (AOT) compilation to achieve swift startup times without sacrificing throughput.
- **Cloud Microservices:** Unbeatable for memory-sensitive environments, microservice clusters, and Docker/Kubernetes container pods on Windows.
- **Install command:** `jvm install 21 --vendor semeru`

<a id="how-do-update-channels-work-and-how-do-i-switch-between-stable-and-nightly"></a>
### How do update channels work, and how do I switch between Stable and Nightly?
DiamTek JVM features a **Dual Update Channel Engine** that gives developers complete control over update stability and release cadences.

#### 1. The Two Update Channels
* **🟢 `[Stable]` (Official Releases — Recommended):**
  - Resolves updates against official, tagged GitHub releases (`releases/latest`).
  - Marked with a distinctive **green** `[Stable]` badge in the CLI, status cards, and TUI menus.
  - Guarantees thoroughly vetted releases, semantic versioning milestones, and complete changelog documentation.
  - Recommended for primary workstations, production environments, enterprise fleets, and CI/CD pipelines.
* **🟣 `[Nightly]` (Cutting-edge `main` Branch):**
  - Resolves updates against the latest git commit (`HEAD`) on the repository's `main` branch.
  - Marked with a distinctive **purple** `[Nightly]` badge in the CLI, status cards, and TUI menus.
  - Delivers unreleased features, immediate bug patches, and the newest vendor API scrapers days or weeks before a general release.
  - Recommended for power users, contributors, and developers testing preview capabilities.

#### 2. Viewing the Active Channel
You can check your active update channel at any time using:
```cmd
jvm channel
```
You will see output indicating the active channel and badge:
```text
Current Update Channel: [Stable]
Description: Receiving official tagged releases (Recommended).

Usage:
  jvm channel stable    - Switch to [Stable] official releases channel
  jvm channel nightly   - Switch to [Nightly] cutting-edge main branch channel
```
You can also see your active channel on the system status card (`jvm current` / `jvm info`) or in the **About** menu (`jvm version` / `jvm -v`).

#### 3. Switching Channels
You can switch channels seamlessly using the CLI, flags, the interactive TUI, or the installer:

* **Command Line:**
  ```cmd
  jvm channel stable    :: Switches to the green [Stable] channel
  jvm channel nightly   :: Switches to the purple [Nightly] channel
  ```
* **One-off Command Overrides:**
  You can override the channel for an individual command without modifying your saved configuration:
  ```cmd
  jvm self-update --nightly
  jvm self-update --stable
  jvm self-update --channel nightly
  ```
* **Interactive TUI Menu:**
  Run `jvm` without arguments, select **Settings** (`3`), and press `4` to toggle between **[Stable]** (green) and **[Nightly]** (purple).
* **Installer Parameter:**
  When executing the PowerShell installer, specify the `-Channel` parameter:
  ```powershell
  # Install directly on the Nightly channel
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/install.ps1))) -Channel Nightly
  ```

#### 4. How Update Handoff & Security Verification Work
When you run `jvm self-update` (or check for updates in `jvm version` / **Settings → About**):
1. **Channel Inspection**: JVM reads `%LOCALAPPDATA%\DiamTek\JVM\channel.txt` to determine the active update channel.
2. **Version & Build Comparison**:
   - In **[Stable]** mode, JVM resolves the latest release tag (with automatic rate-limit fallback via web redirect if `api.github.com` reaches its 60 req/hr quota).
   - In **[Nightly]** mode, JVM queries the latest commit on `main` and fetches `jvm.bat` directly from the Fastly CDN-backed `raw.githubusercontent.com`.
   - JVM parses both the Semantic Version (`v!JVM_VERSION!`) and Build Number (`Build !JVM_BUILD!`).
3. **Ahead-of-Remote Protection (Downgrade Prevention)**:
   - If your local build is newer than the remote reference (e.g. running an unreleased development build on Stable or local commits ahead of `main` on Nightly), JVM reports `[ INFO ]` and safely **refuses to downgrade** your installation.
4. **Cryptographic Integrity Verification**:
   - On **[Stable]**, JVM downloads `SHA256SUMS.txt` from the official release assets and validates the SHA-256 hash of `install.ps1` before execution. If a hash mismatch is detected, the payload is immediately deleted and execution terminates to protect against supply chain tampering.
   - On **[Nightly]**, JVM verifies against `SHA256SUMS.txt` if present on the branch, or computes and logs the SHA-256 hash for auditable tracking.
   - In `install.ps1`, the incoming `jvm.bat` and all companion files (`uninstall.ps1`, `README.md`, `LICENSE`) are verified against `SHA256SUMS.txt` before being written to disk.
5. **Atomic Handoff**:
   - The running `jvm.bat` spawns an isolated handoff runner in `%TEMP%` and exits immediately, releasing all Windows file locks so the core engine can be updated cleanly and atomically.
   - All installed JDKs, toolchains, custom symlinks, and settings are 100% preserved.

---

<a id="how-does-jvm-handle-corporate-proxies-and-ntlmkerberos-authentication"></a>
### How does JVM handle corporate proxies and NTLM/Kerberos authentication?
In enterprise and corporate network environments, developer workstations frequently access the internet through corporate forward proxies (e.g., Blue Coat, Cisco Umbrella, Squid, Zscaler, Palo Alto Networks, Netskope) requiring Single Sign-On (SSO) authentication using Windows Active Directory domain credentials (NTLM or Kerberos).

DiamTek JVM's networking architecture is engineered natively for Windows and provides automated, zero-configuration proxy traversal:

#### 1. Automatic WinINet & WPAD/PAC Proxy Detection
JVM leverages Windows `.NET` networking APIs (`[System.Net.WebRequest]`), which automatically read and inherit your system proxy configuration from WinINet (configured under **Windows Settings → Network & Internet → Proxy**). Whether your corporate proxy is configured via Web Proxy Auto-Discovery (WPAD), a static proxy IP/port, or an automatic proxy configuration script (`proxy.pac`), JVM routes all outbound HTTPS queries (such as checking GitHub releases, Adoptium APIs, or vendor archives) through the corporate proxy without requiring manual command-line arguments.

#### 2. Native Windows Domain Single Sign-On (NTLM / Kerberos)
Unlike cross-platform tools that prompt for raw username/password combinations or fail with `HTTP 407 Proxy Authentication Required`, JVM's installation pipeline automatically binds Windows session credentials:
- In PowerShell 5.1 and modern PowerShell 7+ environments, `install.ps1` binds the caller's Active Directory security token to the proxy handler:
  ```powershell
  if ([System.Net.WebRequest]::DefaultWebProxy) {
      [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
  }
  if ($PSVersionTable.PSVersion.Major -ge 6) {
      $PSDefaultParameterValues['Invoke-WebRequest:ProxyUseDefaultCredentials'] = $true
      $PSDefaultParameterValues['Invoke-RestMethod:ProxyUseDefaultCredentials'] = $true
  }
  ```
- All HTTPS requests automatically negotiate NTLM or Kerberos handshakes against the proxy gateway using the logged-in user's Windows security context—meaning zero credential popups and zero plaintext passwords saved to disk.

#### 3. Standard POSIX & Win32 Proxy Environment Overrides
For environments where custom proxy tunnels or external proxy addresses are mandated, JVM fully respects standard proxy environment variables defined in your Command Prompt or PowerShell session:
```cmd
:: Standard HTTP/HTTPS Proxies
set HTTP_PROXY=http://proxy.company.internal:8080
set HTTPS_PROXY=http://proxy.company.internal:8080

:: Proxy Bypass Rules (Local / Intranet destinations)
set NO_PROXY=localhost,127.0.0.1,*.company.internal

:: Authenticated Proxies (with URL-encoded domain/user)
set HTTPS_PROXY=http://CORP%5Cjsmith:MySecretPassword@proxy.company.internal:8080
```
In PowerShell:
```powershell
$env:HTTP_PROXY  = "http://proxy.company.internal:8080"
$env:HTTPS_PROXY = "http://proxy.company.internal:8080"
$env:NO_PROXY    = "localhost,127.0.0.1,*.company.internal"
```

#### 4. Enterprise Root SSL Inspection (MITM CAs)
Many corporate firewalls perform Deep Packet Inspection (DPI) or SSL decryption using internal enterprise Certificate Authorities (CAs). Unix-based tools often fail with `PKIX path building failed` errors because they maintain isolated CA truststores (e.g., `/etc/ssl/certs` or Java `cacerts`).

Because DiamTek JVM validates TLS certificates against the native **Windows Trusted Root Certification Authorities** store:
- Any corporate root certificate distributed by Active Directory Group Policy (GPO) or Microsoft Intune is trusted automatically.
- No manual PEM exports or `keytool -importcert` commands are required to download JDKs or update JVM.

---

<a id="is-jvm-compatible-with-powershell-constrained-language-mode-clm-and-applockerwdac"></a>
### Is JVM compatible with PowerShell Constrained Language Mode (CLM) and AppLocker/WDAC?
Yes! Many high-security corporate enterprises, financial institutions, and regulated environments enforce **Windows Defender Application Control (WDAC)** or **AppLocker** in allowlist mode, which automatically forces PowerShell sessions into **Constrained Language Mode (CLM)** (`$ExecutionContext.SessionState.LanguageMode = 'ConstrainedLanguage'`).

In CLM, arbitrary .NET types, reflection, and static method calls are blocked to prevent malicious in-memory code execution. Traditional developer tools that rely on calls like `[Environment]::SetEnvironmentVariable(...)` fail immediately with `CannotInvokeMethodInConstrainedLanguage` exceptions.

DiamTek JVM was explicitly designed and tested to thrive in CLM-enforced environments:

#### 1. CLM Detection & Graceful Fallback in `install.ps1`
The installation script queries the active session language mode before attempting .NET configuration:
```powershell
$isFullLanguage = ($ExecutionContext.SessionState.LanguageMode -eq 'FullLanguage')
if ($isFullLanguage) {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072 -bor 12288
    } catch { }
}
```
If CLM is active, the installer avoids calling restricted .NET static methods and relies on native, allowed PowerShell cmdlets and providers.

#### 2. Fully CLM-Compliant Profile Hook (`Set-JvmVar`)
The dynamic PowerShell `$PROFILE` wrapper (`Set-JvmVar`) does not invoke prohibited .NET reflection or static class methods. Instead, it interacts directly with PowerShell's native **Environment Provider** (`env:` drive) and registry cmdlets:
```powershell
# CLM-compliant process environment injection (allowed under WDAC / AppLocker)
Set-Item -Path "env:$Name" -Value $NewValue -Force

# Read environment variables using native provider cmdlets
$old = (Get-Item -Path "env:$key" -ErrorAction SilentlyContinue).Value
$new = (Get-ItemProperty -Path 'HKCU:\Environment' -Name $v -ErrorAction SilentlyContinue).$v
```
This enables seamless, real-time `JAVA_HOME` and session `PATH` synchronization inside locked-down corporate PowerShell terminals without violating CLM policies.

#### 3. Core Engine Runs Outside PowerShell (`cmd.exe`)
The primary CLI and version-switching engine (`jvm.bat`) is written in native Windows Command Prompt batch script (`cmd.exe`). Because `cmd.exe` does not host the PowerShell runtime, `jvm` CLI execution is completely decoupled from PowerShell execution policies (`Restricted`, `RemoteSigned`, `AllSigned`) and PowerShell language constraints.

#### 4. AppLocker & WDAC Binary Allowlisting
If your enterprise prohibits running `.bat` scripts or user-space binaries from `%LOCALAPPDATA%`:
- **Native MSI Deployment**: Enterprise administrators can deploy the official, signed Windows Installer (`jvm-windows-*.msi`) silently via Microsoft Intune or MECM. MSI installations can be whitelisted by Product Code (`HKCU\Software\DiamTek\JVM`) or executable path rules.
- **Sigstore SLSA Build Provenance**: All release artifacts are cryptographically attested using GitHub's Sigstore OIDC infrastructure (`actions/attest-build-provenance`). SecOps teams can verify the immutable SLSA v1 provenance with `gh attestation verify` to guarantee zero supply chain tampering before approving JVM in enterprise software catalogs.

---

<a id="how-does-jvm-switch-java-versions-without-administrative-privileges-or-symlink-permissions"></a>
### How does JVM switch Java versions without administrative privileges or symlink permissions?
In Windows, creating standard file or directory symbolic links (`mklink /D`) requires the elevated Windows user privilege **`SeCreateSymbolicLinkPrivilege`**. By default, Windows restricts this privilege strictly to local Administrators (triggering a UAC elevation prompt) or requires enabling Windows 10/11 "Developer Mode" globally across the operating system—an option strictly forbidden by corporate security policies on managed endpoints.

DiamTek JVM resolves this fundamental Windows limitation through its **NTFS Directory Junction Architecture**:

#### 1. NTFS Directory Junctions (`mklink /J`) vs Symbolic Links (`mklink /D`)
| Capability / Characteristic | NTFS Directory Junction (`mklink /J`) | Symbolic Link (`mklink /D`) |
|:---|:---:|:---:|
| **Administrator (UAC) Required?** | ❌ **No (0 UAC Prompts)** | ⚠️ Yes (Unless Developer Mode is active) |
| **`SeCreateSymbolicLinkPrivilege` Needed?** | ❌ **No** | ⚠️ Yes |
| **Developer Mode Required?** | ❌ **No** | ⚠️ Yes |
| **Standard User Space Operation?** | ✅ **Full Support (`%LOCALAPPDATA%`)** | ❌ Restricted |
| **Windows Kernel Reparse Point Tag** | `IO_REPARSE_TAG_MOUNT_POINT` | `IO_REPARSE_TAG_SYMLINK` |
| **Cross-Process Live Synchronization** | ✅ **Instant across all shells** | ✅ Instant across all shells |

Under NTFS, a **Directory Junction** is an unprivileged soft mount point. Any standard user who possesses write permissions to a local folder (such as `%LOCALAPPDATA%\DiamTek\JVM`) can create, point, and delete directory junctions without administrative credentials.

#### 2. The Static Gateway Architecture
When DiamTek JVM is installed:
1. It injects a single, static directory into your User `PATH`:
   ```text
   %LOCALAPPDATA%\DiamTek\JVM\current\bin
   ```
2. The folder `%LOCALAPPDATA%\DiamTek\JVM\current` is created as an NTFS Directory Junction pointing to your active JDK installation directory (for example, `C:\Program Files\Java\jdk-21` or `%USERPROFILE%\.jdks\corretto-21`).

#### 3. Atomic, Zero-Privilege Version Switching
When you execute `jvm 17` or choose JDK 17 in the interactive menu:
1. JVM unbinds the existing junction:
   ```cmd
   rmdir "%LOCALAPPDATA%\DiamTek\JVM\current"
   ```
2. It immediately re-links the junction to the target JDK:
   ```cmd
   mklink /J "%LOCALAPPDATA%\DiamTek\JVM\current" "C:\Program Files\Java\jdk-17"
   ```
3. The NTFS filesystem driver updates the reparse target in milliseconds in user space.
4. Because the directory junction is resolved dynamically at path lookup time by the Windows NT kernel, **every terminal window, IDE, and build process immediately resolves `java.exe` to JDK 17** without modifying your system `PATH` or prompting for UAC elevation.

---

<a id="how-does-jvm-protect-my-system-path-and-environment-variables-from-corruption"></a>
### How does JVM protect my system PATH and environment variables from corruption?
Environment variable corruption is one of the most common and damaging issues encountered on Windows developer machines. Careless installer scripts or tools often truncate the `PATH` string, strip unexpanded system variable tokens, or induce terminal deadlocks.

DiamTek JVM incorporates a multi-layer defense engine to guarantee absolute environment integrity:

#### 1. Preservation of `REG_EXPAND_SZ` Variable Expansion
A frequent failure mode in Windows tools (including legacy batch scripts and older PowerShell scripts) occurs when reading and writing the `Path` registry value. If written as a plain string (`REG_SZ`), dynamic variable references such as `%SystemRoot%`, `%USERPROFILE%`, `%LOCALAPPDATA%`, or `%ProgramData%` are converted into unexpandable literal text or expanded into hardcoded static paths.

DiamTek JVM protects registry expansion types:
- In `install.ps1`, `uninstall.ps1`, and `jvm.bat`, JVM inspects the exact registry value kind using `Microsoft.Win32.RegistryKey.GetValueKind('Path')`.
- It enforces `[Microsoft.Win32.RegistryValueKind]::ExpandString` (`REG_EXPAND_SZ`) across both User (`HKCU\Environment`) and Machine (`HKLM\...\Environment`) scopes.
- Unexpanded environment tokens are preserved byte-for-byte, ensuring system paths never collapse into static strings.

#### 2. Combined PATH 8,191-Character Boundary Guards & 2,048-Character Warnings
Windows Command Prompt and the Windows environment subsystem enforce an absolute hard ceiling of **8,191 characters** for command lines and environment variables. If an installer appends entries to a system whose PATH is near the limit, Windows silently corrupts or truncates the environment block, breaking essential operating system utilities:
- **Combined Length Calculation**: JVM queries both User `PATH` and System `PATH` to calculate the total combined character length (`Machine PATH + User PATH + JVM entry`).
- **Hard 8,191-Character Abort**: If the combined length would exceed 8,191 characters, JVM **aborts the modification immediately** with an error message, refusing to corrupt the environment block:
  ```text
  [ ERROR  ] Combined PATH length (8245 chars) exceeds Windows 8191-character limit!
             System PATH (6120 chars) + User PATH (2125 chars).
             Modification aborted to prevent environment block corruption.
  ```
- **Proactive 2,048-Character Warning**: If the combined length exceeds 2,048 characters, JVM emits an actionable warning alerting the user that legacy 32-bit Win32 applications may truncate the path.

#### 3. Automatic Elimination of Phantom Oracle `javapath` Entries
Legacy Oracle JRE/JDK installers notoriously inject shortcut directories into the front of the System `PATH` (`C:\Program Files\Common Files\Oracle\Java\javapath` or `C:\ProgramData\Oracle\Java\javapath`). Because Windows evaluates System paths before User paths, these rogue shortcuts cause **PATH Shadowing**, intercepting `java.exe` calls regardless of which JDK you switch to.

Running `jvm clear` automatically identifies and purges these phantom Oracle paths from both User and Machine registries while preserving all legitimate developer directories (`C:\Windows\System32`, `C:\Utils`).

#### 4. Deduplication & Path Normalization Hygiene
Whenever JVM modifies the `Path` variable:
- It strips redundant surrounding quotes (`"` and `'`).
- It normalizes forward slashes (`/`) and backslashes (`\`).
- It strips trailing slashes to prevent duplicate path representations (e.g., `C:\bin\` and `C:\bin`).
- It filters out empty segments (`;;`) and deduplicates existing path entries.

#### 5. Non-Blocking `SendMessageTimeout` Environment Broadcasts
When environment variables are updated in the Windows Registry, the system broadcasts a `WM_SETTINGCHANGE` notification to all top-level desktop windows. If an application is hanging, modal, or deadlocked, a traditional `SendMessage` call hangs indefinitely, freezing the installer or terminal.

JVM uses native P/Invoke calls to `SendMessageTimeout` (`HWND_BROADCAST = 0xFFFF`, `WM_SETTINGCHANGE = 0x001A`, `SMTO_ABORTIFHUNG = 0x0002`) with a strict **3000ms - 5000ms timeout window**. If any background window fails to acknowledge the message within the timeout, the broadcast safely aborts without hanging the terminal.

#### 6. Automated Timestamped Registry Backups
Before making any destructive modifications (such as running `jvm clear`), JVM automatically exports timestamped `.reg` backup files of both User and Machine environment hives to `%LOCALAPPDATA%\DiamTek\JVM\backups\`:
- Machine snapshot: `sys_env_<date>_<time>.reg`
- User snapshot: `usr_env_<date>_<time>.reg`
Restoration can be performed instantly via `reg import` or by double-clicking the backup file in Windows File Explorer.

---

<a id="what-happens-during-uninstallation-are-my-installed-jdks-deleted"></a>
### What happens during uninstallation? Are my installed JDKs deleted?
**No. By default, your installed JDKs are NOT deleted during uninstallation.**

DiamTek JVM treats your Java runtimes as valuable developer assets. Whether you have 200 MB or 15 GB of JDK distributions installed across multiple vendors (Oracle, Adoptium Temurin, Amazon Corretto, Azul Zulu, BellSoft Liberica, Microsoft Build, IBM Semeru), uninstalling JVM does not destroy them.

Here is a detailed breakdown of uninstallation behavior and safety mechanisms:

#### 1. Explicit Interactive Confirmation for JDK Directories
When running `uninstall.ps1` or `jvm self-uninstall` interactively:
1. JVM scrubs all JVM-specific files: `%LOCALAPPDATA%\DiamTek\JVM`, candidate build tool caches (`~/.jvm`), PowerShell profile hooks (`Set-JvmVar`), Windows Terminal profiles, Start Menu shortcuts, and Windows Registry keys.
2. If the default JDK directory (`C:\Program Files\Java`) exists, the uninstaller explicitly pauses and prompts:
   ```text
   Do you also want to delete the Java installations directory? (C:\Program Files\Java) (y/N)
   ```
3. The prompt defaults to **No (`N`)**. Unless you explicitly type `y` or `yes`, `C:\Program Files\Java` and all installed JDK runtimes are left 100% intact on disk.

#### 2. Non-Destructive Silent Uninstallation (`-Quiet` / MSI `/qn`)
If you uninstall silently (e.g., via Chocolatey `choco uninstall jvm-windows`, Winget `winget uninstall DiamTek.JVM`, or Intune/MECM `msiexec /x ... /qn`):
- The `DeleteJava` switch defaults to **`$false`**.
- Installed JDK runtimes are **never deleted** in silent or unattended mode.
- Custom JDK installations registered with `jvm link` (such as `%USERPROFILE%\.jdks` or `C:\Java`) remain completely untouched.

#### 3. Non-Destructive Directory Junction Unbinding (`Remove-DirectorySafely`)
In Windows PowerShell 5.1, the native `Remove-Item -Recurse` cmdlet contains a critical flaw: when deleting a folder containing NTFS Directory Junctions or Reparse Points, it traverses into the target directories and deletes the target files instead of merely unbinding the link!

DiamTek JVM mitigates this hazard via its dedicated `Remove-DirectorySafely` engine:
- Before any JVM state or link folder is deleted, `Remove-DirectorySafely` audits all directory junctions.
- It unbinds each junction from the bottom up using `[System.IO.Directory]::Delete($_.FullName, $false)` and native `cmd.exe /c rmdir /q`.
- Only after all junction pointers are cleanly detached is the parent container removed. Your underlying target JDK runtimes and canary files remain completely untouched.

#### 4. Active Repository & System Root Protection Rails
To prevent catastrophic accidental deletions from misconfigured paths:
- **Filesystem Root Guard**: The uninstaller strictly refuses to delete protected filesystem roots (`C:\`, `%SystemRoot%`, `%ProgramFiles%`, `%ProgramFiles(x86)%`, `%USERPROFILE%`).
- **Active Development Repository Guard**: If a target directory contains a `.git` folder (such as when a developer clones and tests JVM from source), the uninstaller detects the active Git repository and refuses to delete it.
- **Marker Verification**: The uninstaller verifies that the target folder contains legitimate JVM installation markers (`jvm.bat`, `uninstall.ps1`) before deleting any standalone folder outside AppData.

---

<a id="how-can-i-run-the-automated-security-test-suite-locally"></a>
### How can I run the automated security test suite locally?
DiamTek JVM includes an enterprise-grade automated security and adversarial fuzzing test suite located at `tests/Test-JvmSecurity.ps1`. This suite validates all defensive boundaries, input sanitization routines, reparse point operations, and manifest schemas against real adversarial payloads.

#### 1. Running the Test Suite
The security test suite can be run from either modern PowerShell 7+ (`pwsh`) or native Windows PowerShell 5.1:

```powershell
# Run using modern PowerShell 7+ (Recommended):
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-JvmSecurity.ps1

# Or run using native Windows PowerShell 5.1:
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-JvmSecurity.ps1

# Run with verbose diagnostic outputs and test millisecond durations:
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-JvmSecurity.ps1 -Detailed
```

#### 2. What the 55 Automated Tests Cover
The test suite executes **55 automated test cases across 8 defensive suites**, achieving a 100% pass rate:

| Suite | Focus Area | Tests | Key Adversarial & Security Vectors Verified |
|:---|:---|:---:|:---|
| **Suite 1** | **Adversarial Inputs & Fuzzing Defense** | **30** | Path traversal (`..`, `/`, `\`), single-dot aliases (`.`), reserved keyword `current`, command injection in `.java-version`/`.sdkmanrc`, branch traversal in `install.ps1`, profile hook regex injection filters, Win32 trailing dot/space bypasses (`current.`, `current `), legacy DOS 8.3 device names (`CON`, `PRN`, `AUX`, `NUL`), poison characters (`&`, `|`, `<`, `>`, `^`, `%`, `!`), Alternate Data Streams (`:`), candidate traversal in `which`, leading hyphens (`--evil-flag`), multiple trailing dots/spaces, semicolon chaining, and wildcards (`*`, `?`). |
| **Suite 2** | **Registry & Environment Variable Boundaries** | **5** | User PATH `REG_EXPAND_SZ` preservation during setup, Base64 UTF-16LE elevation payload generation without temporary files, elevation path resolution immunity to SystemRoot environment saturation, Oracle `javapath` de-bloating, and extreme PATH lengths (>2048 chars). |
| **Suite 3** | **Reparse Point & Junction Non-Destructive Lifecycle** | **3** | Junction unbinding canary protection (verifying target JDK and canary files are not deleted when junctions are unbound), bracket-safe reparse querying with `-LiteralPath` and `$env:QUERY_PATH`, and active dev repository `.git` guards. |
| **Suite 4** | **Package Manager Manifest Integrity & Dry-Run** | **5** | Cross-package version parity (validating version sync across `jvm.bat`, Scoop, Chocolatey, and Winget), nuspec XML schema & UTF-8 No BOM validation, Scoop manifest schema, Winget multi-manifest coherence, and `bump-version.ps1 -DryRun` working tree immutability. |
| **Suite 5** | **Concurrency & Reparse Point Resilience** | **2** | Broken/dangling junction auto-recovery without deadlock and rapid sequential junction switching without lock corruption. |
| **Suite 6** | **Corrupt Registry Recovery & PATH Resilience** | **3** | `REG_SZ` vs `REG_EXPAND_SZ` type enforcement, non-blocking `SendMessageTimeout` broadcast execution under timeout constraints, and `Set-JvmVar` storage boundary enforcement. |
| **Suite 7** | **Uninstallation Safety & Marker Verification** | **3** | `Remove-DirectorySafely` target canary retention, refusal of uninstaller execution on directories lacking JVM markers, and protected system root deletion blocking. |
| **Suite 8** | **Windows Terminal JSONC Configuration Parsing** | **4** | Multi-line `/* ... */` comment stripping, single-line `//` comment stripping, trailing comma elimination before closing braces/brackets, and graceful silent fallback on corrupted JSON. |

#### 3. Complete Sandbox Isolation Guarantee
The security test suite is 100% non-destructive and safe to run on any development or production workstation:
- **Ephemeral Sandbox**: Each test run generates a unique sandbox folder in `%TEMP%\jvm_sec_test_<guid>`.
- **Zero Real Registry Impact**: Registry tests utilize temporary test keys (`TestJvmPath`, `JVM_REG_TYPE_TEST`) or mock environment variables, leaving your actual `PATH` and `JAVA_HOME` untouched.
- **Sentinel Canary Verification**: Filesystem tests create fake JDK trees with canary sentinel files (`CRITICAL_SENTINEL_DO_NOT_DELETE`) to verify that junction unbinding never leaks into target directories.
- **Guaranteed Cleanup**: A global `finally` block unbinds all created junctions and wipes the sandbox directory upon test completion.

---

[← Back to Documentation Overview](../README.md#documentation)