<h1 align="center">Getting Support for Java Version Manager for Windows</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md)

</div>

---

Thank you for using Java Version Manager! We want to ensure you have the best possible experience managing JDKs and JVM tools on Windows.

---

## 🔍 Self-Service Diagnostic Triage

Before opening a support ticket, check this rapid decision tree for the most common operational scenarios:

### 0. "Check my entire system health automatically" (`jvm doctor`)
- **Action:** Run the automated 7-point health check in any terminal:
  ```powershell
  jvm doctor
  ```
- **What it does:** Automatically audits `%LOCALAPPDATA%` storage permissions, junction target validity, User/Machine registry synchronization, `where.exe java` PATH precedence, rogue Oracle `javapath` shadowing, and PowerShell `$PROFILE` hooks. If any conflicts exist, `jvm doctor` identifies the exact root cause and outputs direct remediation steps.
- **Exit Codes:**
  - `0`: All diagnostic checks passed cleanly with zero conflicts.
  - `1`: One or more warnings or misconfigurations detected (remediation instructions provided in output).

### 1. "I switched versions, but `java -version` didn't change" (PATH Shadowing)
- **Root Cause:** A rogue installer (e.g. older Oracle JDK MSI, Chocolatey shim, or IDE installer) forcefully injected a hardcoded path ahead of JVM in your system `PATH`.
- **Diagnosis:** Run `where.exe java` in your terminal:
  ```powershell
  where.exe java
  ```
- **Resolution:**
  - If you see `C:\Program Files (x86)\Common Files\Oracle\Java\javapath\java.exe` listed before `%LOCALAPPDATA%\DiamTek\JVM\current\bin\java.exe`:
  - Run `jvm clear` followed by your desired version switch (e.g., `jvm 21`). JVM will hunt down and scrub the phantom path from your registry.
  - Close and reopen your terminal window to refresh active process memory.

### 2. "I keep getting Windows UAC administrator elevation prompts"
- **Root Cause:** Your active configuration is set to legacy **Registry Mode** instead of the default UAC-free **Symlink Mode**. In Registry Mode, switching JDKs requires writing to Machine-level registry (`HKLM`), triggering Windows Administrator elevation prompts.
- **Diagnosis:** Run `jvm current` to check your active mode (`Mode: [Registry Mode]` indicates Registry Mode; `[Symlink Mode]` indicates Symlink Mode).
- **Resolution:**
  - **Via CLI:** Run any switch command with `--symlink`:
    ```powershell
    jvm 21 --symlink
    ```
  - **Via Interactive Menu:** Launch `jvm` -> Navigate to **Settings** (`3`) -> Press **`2`** to toggle Architecture from `[Registry Mode]` back to `[Symlink Mode] (UAC Free)`.

### 3. "Network connection failed / You appear to be offline"
- **Root Cause:** Corporate firewall, SSL-intercepting proxy (e.g. Zscaler, Netskope), or air-gapped network blocking vendor CDN endpoints.
- **Resolution:**
  - **Clean Corrupted Caches:** If an earlier download was interrupted or corrupted, purge stale cache files:
    ```powershell
    jvm clean
    ```
  - **Set Proxy Variables:** JVM inherits standard environment proxies in your active session:
    ```powershell
    $env:HTTP_PROXY  = "http://proxy.corp.internal:8080"
    $env:HTTPS_PROXY = "http://proxy.corp.internal:8080"
    ```
  - **Bypass Hash Verification (Air-Gapped):** If your proxy allows the binary download but blocks raw vendor hash mirrors, pass:
    ```powershell
    jvm install 21 --skip-checksum
    ```
  - **Bring Your Own JDK (Offline):** Pre-extract any zip/tarball to disk and link it locally without network access:
    ```powershell
    jvm link "D:\OfflineStore\jdk-21.0.2" jdk-21-offline
    ```

### 4. "PowerShell session switching doesn't update my current terminal"
- **Root Cause:** Standard batch files executed in PowerShell run inside an isolated child `cmd.exe` subshell, which cannot mutate parent process memory without the PowerShell Profile wrapper hook.
- **Resolution:**
  - **Via CLI (Recommended):** Run the dedicated profile hook installer:
    ```powershell
    jvm hook install
    # Verify active hook status:
    jvm hook status
    ```
  - **Via Interactive Menu:** Launch `jvm` -> Navigate to **Settings** (`3`) -> Select **Option 2** (`PowerShell Profile Hook: [INSTALL]`), which injects the auto-sync wrapper function into your PowerShell profiles.
  - **Via Dotfiles / Manual Setup:** Open your `$PROFILE` (`notepad $PROFILE`) and paste the official `function jvm { ... }` wrapper block documented in the [FAQ](FAQ.md#how-do-i-verify-or-manually-configure-the-powershell-profile-hook).

---

## ⚡ Troubleshooting Quick-Reference Table

| Symptom | Probable Cause | Diagnostic Command | Remediation Command |
|---|---|---|---|
| `java -version` does not change after switch | Phantom Oracle path or rogue MSI shadowing in PATH | `where.exe java` | `jvm clear` followed by `jvm <version>` |
| Constant UAC elevation prompts | Active mode set to legacy Registry Mode (`HKLM`) | `jvm current` | `jvm <version> --symlink` |
| PowerShell session variables not updating live | PowerShell Profile auto-sync hook not installed | `jvm hook status` | `jvm hook install` |
| Corrupted download / hash mismatch / network drop | Stale extraction workspaces or cache in `%TEMP%` | `jvm doctor` | `jvm clean` |
| Air-gapped / proxy hash mirror blocked | Proxy allows binary download but blocks checksum | `jvm doctor` | `jvm install <version> --skip-checksum` |
| Command `jvm` not recognized in new terminal | JVM directory missing from User PATH | `where.exe jvm` | Settings (`3`) → Option 1 (`Install to User PATH`) |
| Directory junction broken or points to missing JDK | JDK was manually deleted from disk | `jvm doctor` | `jvm link` (to inspect) or `jvm <version>` (to re-point) |
| System environment uncertain / multiple conflicts | General configuration drift | `jvm doctor` | Follow remediation output in `jvm doctor` |

---

## 📋 Standard Diagnostic Bundle

When opening a support request or asking for assistance on Discord, running these diagnostic commands and attaching their output will accelerate resolution by 10x:

```powershell
# 1. Automated all-in-one system health audit:
jvm doctor

# 2. Active JVM environment and configuration dashboard:
jvm current

# 3. Exact executable binary resolved by JVM:
jvm which

# 4. All java.exe binaries discovered in active PATH order:
where.exe java

# 5. Environment PATH entries filtered for Java/JVM:
($env:Path -split ';') | Where-Object { $_ -match 'Java|JVM|jdk|Oracle' }
```

---

## 💬 Community & Direct Maintainer Support

If self-service triage doesn't solve your issue, we are here to help:

* **Discord (Fastest Response):** Reach out directly to the lead maintainer on Discord at **@thehawk01**.
* **Email Support:** Send detailed logs and diagnostic bundles to **salexey09@gmail.com**.
* **GitHub Issues:** Open an issue on the [Bug Tracker](https://github.com/DiamTek/Java-Version-Manager-Windows/issues/new?template=bug_report.md) or request enhancements via [Feature Requests](https://github.com/DiamTek/Java-Version-Manager-Windows/issues/new?template=feature_request.md).

---

## 🛡️ Security Vulnerabilities

Please **do not** file public GitHub issues for security vulnerabilities. Review our [Security Policy](SECURITY.md) and report privately via [GitHub Security Advisories](https://github.com/DiamTek/Java-Version-Manager-Windows/security/advisories/new) or directly via email.

---

[← Back to Documentation Overview](../README.md#documentation)