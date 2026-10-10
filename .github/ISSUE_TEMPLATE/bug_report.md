---
name: Bug report
about: Report a defect, unexpected error, or crash in Java Version Manager
title: '[BUG] '
labels: 'bug'
assignees: ''
---

## 🛑 Before Submitting

Please ensure you have checked the following to help us diagnose the issue quickly:
- [ ] I have reviewed the [FAQ](https://github.com/DiamTek/Java-Version-Manager-Windows/blob/main/docs/FAQ.md) and [Troubleshooting Guide](https://github.com/DiamTek/Java-Version-Manager-Windows/blob/main/docs/INSTALLATION.md#troubleshooting--windows-security).
- [ ] I ran `jvm doctor` (or `jvm doctor --fix` / `jvm doctor --report`) to check for and repair broken junctions, permission faults, and rogue PATH shadowing.
- [ ] I verified runtime precedence via `jvm why` and `where.exe java` to confirm if a directory `.java-version`, project file, or rogue Oracle/Chocolatey path is overriding JVM.
- [ ] If reporting a failed or corrupted download/extraction, I tried running `jvm clean` to purge stale caches.
- [ ] If reporting an environment override, I tried running `jvm clear` followed by re-activating my version (`jvm <version>`).
- [ ] I have searched [Existing Issues](https://github.com/DiamTek/Java-Version-Manager-Windows/issues) to ensure this hasn't already been reported.

---

## 🐛 Bug Description

A clear and concise description of the bug or unexpected behavior.

## 🔁 Reproduction Steps

Steps to reproduce the behavior:
1. Open terminal `[e.g., Windows Terminal / PowerShell / CMD]`
2. Run command `'...'`
3. See error or unexpected output:

```text
[Paste error output, stack trace, and exit code ($LASTEXITCODE / %ERRORLEVEL%) here]
```

## 🎯 Expected Behavior

A clear and concise description of what you expected to happen.

## 💻 Environment & Diagnostics

Please provide as much information about your environment as possible:

- **JVM Version & Build**: `[Run 'jvm version' or 'jvm.bat --version', e.g., 1.0.2, Build 20261010.155]`
- **Update Channel**: `[Run 'jvm channel', e.g., Stable or Nightly]`
- **OS Version & Build**: `[e.g., Windows 11 24H2 / 23H2 (Build 22631.3007), Windows 10 22H2]`
- **CPU Architecture**: `[e.g., x64, ARM64]`
- **Installation Method**: `[e.g., PowerShell one-liner (install.ps1), Standalone MSI (x64/arm64), Winget, Scoop, Chocolatey, Portable Zip]`
- **Active Terminal / Shell**: `[e.g., Windows Terminal with PowerShell 7, ConHost with cmd.exe, PowerShell 5.1]`
- **Switching Mode**: `[e.g., Symlink Mode (Default / UAC-Free) or Registry Mode (Legacy / HKLM)]`
- **User Privilege Level**: `[e.g., Standard User (Non-Admin), Elevated Administrator, Corporate Managed Laptop]`

### 🔍 Diagnostic Output

> [!TIP]
> **🚀 Fast Track (Recommended):** Generate an automated diagnostic bundle or sanitized environment report and attach it directly to this issue. Usernames, tokens, and credentials are automatically redacted!
> ```powershell
> # Option A: Generate complete ZIP issue bundle (contains doctor health audit, environment report, and config):
> jvm doctor --report
> # -> Attach generated 'jvm-issue-bundle.zip' to this issue
>
> # Option B: Generate sanitized plain-text report:
> jvm report
> # -> Attach or paste generated 'jvm-report.txt'
> ```

Alternatively, paste the output of the individual commands below:

<details>
<summary><b>0. <code>jvm why</code> (Precedence Resolution Graph)</b></summary>

```text
[Paste output of 'jvm why' here]
```
</details>

<details>
<summary><b>1. <code>jvm doctor</code> (System Diagnostic Health Audit)</b></summary>

```text
[Paste output of 'jvm doctor' here]
```
</details>

<details>
<summary><b>2. <code>jvm current</code> (Environment & Toolchain Dashboard)</b></summary>

```text
[Paste output of 'jvm current' here]
```
</details>

<details>
<summary><b>3. <code>jvm env --diff</code> (Environment Delta Inspection)</b></summary>

```text
[Paste output of 'jvm env --diff' here]
```
</details>

<details>
<summary><b>4. <code>jvm channel</code> (Active Update Channel)</b></summary>

```text
[Paste output of 'jvm channel' here]
```
</details>

<details>
<summary><b>5. <code>jvm which</code> (Resolved Binary)</b></summary>

```text
[Paste output of 'jvm which' here]
```
</details>

<details>
<summary><b>6. <code>where.exe java</code> (Path Precedence)</b></summary>

```text
[Paste output of 'where.exe java' here]
```
</details>

<details>
<summary><b>7. Active Session PATH (optional)</b></summary>

```powershell
# In PowerShell:
($env:Path -split ';') | Where-Object { $_ -match 'Java|JVM|jdk' }
```
</details>

## 📎 Additional Context

Add any other context, screenshots, or corporate network constraints (e.g., authenticating proxy, Zscaler, offline air-gapped system) here.