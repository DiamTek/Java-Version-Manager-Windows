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
- [ ] I ran `jvm doctor` to check for broken junctions, permission faults, and rogue PATH shadowing.
- [ ] I verified that this is not **PATH Shadowing** (run `where.exe java` to see if a rogue Oracle or Chocolatey path is overriding JVM).
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
[Paste error output or stack trace here]
```

## 🎯 Expected Behavior

A clear and concise description of what you expected to happen.

## 💻 Environment & Diagnostics

Please provide as much information about your environment as possible:

- **JVM Version & Build**: `[Run 'jvm version' or 'jvm.bat --version', e.g., 1.0.0, Build 20260912.96]`
- **OS Version & Build**: `[e.g., Windows 11 23H2 (Build 22631.3007), Windows 10 22H2]`
- **CPU Architecture**: `[e.g., x64, ARM64]`
- **Installation Method**: `[e.g., PowerShell one-liner (install.ps1), Standalone MSI (x64/arm64), Winget, Scoop, Chocolatey, Portable Zip]`
- **Active Terminal / Shell**: `[e.g., Windows Terminal with PowerShell 7, ConHost with cmd.exe, PowerShell 5.1]`
- **Switching Mode**: `[e.g., Symlink Mode (Default / UAC-Free) or Registry Mode (Legacy / HKLM)]`
- **User Privilege Level**: `[e.g., Standard User (Non-Admin), Elevated Administrator, Corporate Managed Laptop]`

### 🔍 Diagnostic Output

To accelerate resolution, please paste the output of the following commands:

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
<summary><b>3. <code>jvm which</code> (Resolved Binary)</b></summary>

```text
[Paste output of 'jvm which' here]
```
</details>

<details>
<summary><b>4. <code>where.exe java</code> (Path Precedence)</b></summary>

```text
[Paste output of 'where.exe java' here]
```
</details>

<details>
<summary><b>5. Active Session PATH (optional)</b></summary>

```powershell
# In PowerShell:
($env:Path -split ';') | Where-Object { $_ -match 'Java|JVM|jdk' }
```
</details>

## 📎 Additional Context

Add any other context, screenshots, or corporate network constraints (e.g., authenticating proxy, Zscaler, offline air-gapped system) here.