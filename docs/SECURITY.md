<h1 align="center">Security Policy</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md) &nbsp;•&nbsp; [🛡️ Security](SECURITY.md) &nbsp;•&nbsp; [🤝 Contributing](CONTRIBUTING.md) &nbsp;•&nbsp; [💬 Support](SUPPORT.md)

</div>

---

## Supported Versions

Currently, only the latest release of the Java Version Manager for Windows is supported with active security patches and vulnerability mitigations.

| Version | Supported | Status |
| :--- | :---: | :--- |
| `1.0.x` | ✅ | Active Security Maintenance |
| `< 1.0.0` | ❌ | End of Life (Upgrade Recommended) |

---

## Threat Model & Security Posture

DiamTek Java Version Manager (JVM) is engineered for enterprise developer workstations and managed corporate environments. The security perimeter is hardened against common Windows attack vectors, Local Privilege Escalation (LPE), and software supply chain tampering.

### 1. Zero-File In-Memory UAC Elevation (LPE / TOCTOU Mitigation)
- **Vulnerability Mitigated:** Legacy automation utilities commonly write temporary elevation scripts (e.g. `%TEMP%\elevate.bat` or `%TEMP%\admin.ps1`) before executing `Start-Process -Verb RunAs`. This creates a critical Time-of-Check to Time-of-Use (TOCTOU) race window where an unprivileged local process can overwrite the temporary file before elevated execution, gaining `NT AUTHORITY\SYSTEM` or Administrator privileges.
- **Architectural Defense:** JVM completely eliminates intermediate temporary elevation scripts. All administrative operations (such as system registry updates in legacy mode or system directory cleanups) are executed purely in-memory via parameterized PowerShell arguments:
  ```powershell
  Start-Process powershell -Verb RunAs -ArgumentList @(
      '-NoProfile', '-NonInteractive', '-Command',
      "[Environment]::SetEnvironmentVariable('JAVA_HOME', '$target', 'Machine')"
  )
  ```
- **EDR Compliance:** This design prevents CrowdStrike, Microsoft Defender for Endpoint, and SentinelOne from triggering heuristic script-drop alerts in `%TEMP%`.

### 2. Download Verification & Payload Integrity
- **Vulnerability Mitigated:** Incomplete downloads, transit corruption, CDN cache poisoning, or malicious mirror swapping.
- **Architectural Defense:** 
  - Every remote JDK payload is cryptographically validated against vendor SHA256/SHA512 checksum endpoints using native .NET Cryptography APIs (`System.Security.Cryptography.SHA256` / `SHA512`).
  - Checksum validation is strictly decoupled from interactive prompts: passing `-y` / `--yes` only suppresses confirmation dialogs and will **never** bypass integrity verification.
  - Bypassing checksum validation requires an explicit, intentional `--skip-checksum` (or `--no-verify`) flag for air-gapped or legacy mirrors without published hashes.

### 3. Repository File Metacharacter Filtering (Injection Hardening)
- **Vulnerability Mitigated:** Arbitrary shell command execution via untrusted project repository files (`.java-version` or `.sdkmanrc`).
- **Architectural Defense:**
  - Injected shell metacharacters (`&`, `|`, `<`, `>`) embedded in version strings (e.g., `21 & calc.exe`) are strictly filtered out by the parsing pipeline using `findstr /v "[&|<>]"`.
  - Malicious lines are discarded before reaching the subshell execution boundary.

### 4. Buffer Overflow & Environment Truncation Defense
- **Vulnerability Mitigated:** Legacy Windows `setx.exe` imposes a hard 1,024-character buffer limit on the `PATH` environment variable. Running `setx` on a workstation with a long `PATH` silently truncates the tail of the variable, corrupting system-wide software installations.
- **Architectural Defense:** All global and machine environment updates leverage infinite-length .NET environment APIs (`[Environment]::SetEnvironmentVariable`), completely bypassing `setx.exe` buffer overrun vulnerabilities.

### 5. Cryptographic Supply Chain Provenance (SLSA / Sigstore)
- **Vulnerability Mitigated:** Unauthorized binary replacement or build injection.
- **Architectural Defense:** Official release binaries (standalone MSIs, portable ZIPs) are built in isolated GitHub Actions runners and cryptographically signed using GitHub's OIDC Sigstore attestation authority (`actions/attest-build-provenance`).
- **Verification Command:**
  ```bash
  gh attestation verify jvm-windows-1.0.0-x64.msi --owner DiamTek
  ```

---

## Vulnerability Scope Matrix

| Category | In-Scope | Out-of-Scope |
|---|---|---|
| **Remote Code Execution** | Unauthenticated RCE via auto-downloader, candidate engine, or archive unpacking | Code execution requiring an attacker to already control local administrator credentials |
| **Path Traversal (Zip Slip)** | Archive extraction writing files outside `%LOCALAPPDATA%\DiamTek\JVM` | User explicitly running `jvm link` pointing to a compromised local directory |
| **Privilege Escalation** | Bypassing standard user boundaries to gain Administrator rights without UAC consent | Attacker already having elevated Administrator or SYSTEM privileges on the machine |
| **Command Injection** | Injecting commands via `.java-version`, `.sdkmanrc`, or CLI argument parsing | Manually editing the `jvm.bat` file on local disk |
| **Transport Security** | Silent acceptance of tampered/corrupted downloads when checksum is expected | Network denial-of-service or outages on vendor APIs (Adoptium, Oracle, GitHub) |

---

## Reporting a Vulnerability

If you discover a potential security vulnerability in DiamTek Java Version Manager, please report it through coordinated disclosure. **Do not create public GitHub issues or forum discussions for security vulnerabilities.**

### Reporting Channels

1. **GitHub Security Advisories (Preferred):**
   Navigate to the repository's [Private Vulnerability Reporting](https://github.com/DiamTek/Java-Version-Manager-Windows/security/advisories/new) page to open a confidential report.
2. **Direct Email:**
   Send an encrypted or plaintext report to the project maintainer:
   - **Contact:** Alexéy Shishkin
   - **Email:** **salexey09@gmail.com**
3. **Discord (Direct Message):**
   Reach out directly to **@thehawk01** on Discord for initial coordination.

### What to Include in Your Report

To help us triage and reproduce the issue rapidly, please include:
- The exact build number (`jvm version` or `cmd.exe /c "jvm.bat --version"`).
- Target operating system and environment (e.g., Windows 11 23H2, standard user account vs. admin).
- Step-by-step reproduction instructions or a minimal Proof of Concept (PoC) payload.
- Assessment of the potential impact (e.g., LPE, arbitrary file write, shell injection).

---

## Response & Remediation SLA

We take all security reports with utmost urgency:

| Phase | Target SLA | Description |
|---|---|---|
| **Initial Acknowledgment** | **< 48 hours** | We confirm receipt of your report and begin preliminary assessment. |
| **Triage & Reproduction** | **< 7 days** | We validate the PoC in an isolated Windows sandbox and determine severity. |
| **Patch & Release** | **< 30 days** | We develop, verify via the automated test suite, and deploy a patched release. |
| **Coordinated Disclosure** | Negotiated | We publish security advisories and credit reporters (unless anonymity is requested). |

---

[← Back to Documentation Overview](../README.md#documentation)