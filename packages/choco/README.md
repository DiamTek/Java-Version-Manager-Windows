---
layout: default
title: Chocolatey Package Guide
description: Technical guide for building, testing, and distributing the DiamTek JVM Chocolatey package on Windows.
---
# Chocolatey Package for Java Version Manager (`jvm-windows`)

This directory contains the Chocolatey packaging manifests, build scripts, and verification automation for **Java Version Manager for Windows (DiamTek JVM)**.

---

## Package Structure

```text
packages/choco/
├── jvm.nuspec                     # Chocolatey/NuGet package specification
├── build-choco.ps1                # Automated packaging, checksum binding & validation script
├── README.md                      # This documentation
└── tools/
    ├── chocolateyInstall.ps1      # Package installation script
    └── chocolateyUninstall.ps1    # Package uninstallation script
```

---

## Components

### 1. `jvm.nuspec`
The package specification conforming to the NuGet / Chocolatey v2 schema.
- **Package ID**: `jvm-windows`
- **Metadata**: Project URLs, license details, tags, author information, and release notes pointers.
- **Files**: Packages the `tools/` folder containing lifecycle automation scripts.

### 2. `tools/chocolateyInstall.ps1`
Handles seamless, secure installation of DiamTek JVM on target systems:
- Resolves upstream release binary assets from official GitHub releases.
- **Strict HTTPS & Host Allowlist (`CWE-918`)**: Validates download URIs to ensure payloads originate exclusively from `github.com` or `objects.githubusercontent.com`.
- **Cryptographic Hash Verification (`CWE-354`)**: Enforces 64-character lowercase hex SHA-256 validation prior to running installation payloads.
- **Pinned System Binaries (`CWE-426`)**: Uses absolute system paths for `powershell.exe` and `cmd.exe` to prevent planting attacks.
- Configures environment paths and registers the installation with Windows.

### 3. `tools/chocolateyUninstall.ps1`
Provides clean, deterministic uninstallation:
- Locates the active JVM installation under `%LOCALAPPDATA%\DiamTek\JVM`.
- **Reparse-Point & Link Defense (`CWE-59`)**: Verifies `uninstall.ps1` is a legitimate regular file and not a symlink or directory junction before invocation.
- Invokes `uninstall.ps1 -Silent` using pinned system PowerShell.
- Removes orphaned shortcuts and cleans up environment entries.

### 4. `build-choco.ps1`
Automation script to build and validate the Chocolatey `.nupkg` package:
- Auto-detects the version from `jvm.bat` or accepts an explicit `-Version` parameter.
- **XML XXE & DTD Protection (`CWE-611`)**: Validates `jvm.nuspec` with `DtdProcessing::Prohibit` and `XmlResolver = $null`.
- Calculates cryptographic checksums and synchronizes `chocolateyInstall.ps1`.
- Packages the `.nupkg` archive with fail-closed cleanup of temporary build artifacts (`CWE-459`).

---

## Build & Test Workflow

### Prerequisites
- Windows PowerShell 5.1+ or PowerShell Core 7+
- Chocolatey CLI installed (`choco.exe`)

### Building the Package
To build the `.nupkg` package locally:

```powershell
# From the repository root
powershell.exe -ExecutionPolicy Bypass -File .\packages\choco\build-choco.ps1

# Or specify a custom version
powershell.exe -ExecutionPolicy Bypass -File .\packages\choco\build-choco.ps1 -Version 1.0.2
```

### Testing Local Installation
To test installing the locally compiled package:

```powershell
choco install jvm-windows --source .\packages\choco -y
```

### Verifying Installation
```cmd
jvm version
jvm doctor
```

### Testing Uninstallation
```powershell
choco uninstall jvm-windows -y
```

---

## Security Hardening Matrix

| CWE Class | Description | Mitigation Strategy |
| :--- | :--- | :--- |
| **CWE-20** | Improper Input Validation | Strict SemVer regex validation (`^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$`) rejecting traversal characters (`..`). |
| **CWE-59** | Improper Link Resolution | Pre-execution reparse point check (`Test-HasReparsePointInLineage`) before executing `uninstall.ps1`. |
| **CWE-354** | Hash Verification | Mandatory 64-hex SHA-256 integrity verification before execution. |
| **CWE-426** | Untrusted Search Path | System directory pinning (`[Environment+SpecialFolder]::System`) for core binaries. |
| **CWE-459** | Incomplete Cleanup | Deterministic cleanup of `.nupkg.tmp` staging artifacts in `finally` blocks. |
| **CWE-611** | XML External Entity (XXE) | Strict prohibition of DTD processing and external XML entity resolution during manifest validation. |
| **CWE-918** | Server-Side Request Forgery | Strict host allowlist verification on download endpoints. |

---

[← Back to Main Repository Documentation](../../README.md) &nbsp;•&nbsp; [📦 Installation Guide](../../docs/INSTALLATION.md)