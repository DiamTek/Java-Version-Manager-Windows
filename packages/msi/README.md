# WiX v4 MSI Package for Java Version Manager (`DiamTek.JVM.msi`)

This directory contains the WiX Toolset automation, build scripts, custom action hooks, and test harnesses for generating enterprise-ready Windows Installer (`.msi`) packages for **Java Version Manager for Windows (DiamTek JVM)**.

---

## Directory Overview

```text
packages/msi/
├── build-msi.ps1                  # Dual-strategy WiX v4/v3 compiler and hook generator
├── test-msi.ps1                   # Automated MSI installation & rollback test suite
└── README.md                      # This documentation
```

---

## Architecture & Components

### 1. `build-msi.ps1`
An enterprise build automation script supporting dual compilation pipelines:
- **Strategy 1 (WiX v4/v5)**: Uses the modern `.NET` toolchain (`dotnet tool run wix build` or global `wix.exe`).
- **Strategy 2 (WiX v3 Fallback)**: Automatically falls back to WiX v3 (`candle.exe` and `light.exe`) if WiX v4 is unavailable.
- **Multi-Architecture**: Generates distinct, optimized packages for both `x64` (`x64` / `Win64="yes"`) and `arm64` (`arm64` / `Win64="yes"`).
- **Deterministic GUID Generation**: Dynamically derives reproducible UUIDv5 / SHA-1 component GUIDs based on stable repository namespaces, ensuring seamless in-place upgrades.
- **Embedded PowerShell Custom Actions**: Emits deeply hardened custom action scripts embedded into the MSI table:
  - `msiInstallHook.ps1`: Registers JVM in the per-user or machine PATH (preserving `REG_EXPAND_SZ` and checking the 8191-character boundary), configures Windows Terminal profile integrations, and builds Start Menu shortcuts.
  - `msiUninstallHook.ps1`: Safely cleans up PATH entries, unbinds ecosystem directory junctions without traversing targets, removes Windows Terminal configurations, and cleans up registry keys.

### 2. `test-msi.ps1`
Automated regression test harness that verifies MSI lifecycle operations:
- Validates the MSI file path against path traversal (`CWE-20`) and ensures file extension integrity.
- Tests silent installation (`msiexec.exe /i ... /qn`).
- Verifies binary staging in `%LOCALAPPDATA%\DiamTek\JVM\bin\jvm.bat`.
- Validates PATH entry persistence and terminal integration.
- Tests silent maintenance/repair (`msiexec.exe /fa ... /qn`).
- Tests silent uninstallation (`msiexec.exe /x ... /qn`) and asserts complete cleanup of staged binaries.

---

## Build & Test Workflow

### Prerequisites
- Windows PowerShell 5.1+ or PowerShell 7+
- WiX Toolset v4/v5 (via `dotnet tool install --global wix`) or WiX Toolset v3.11+
- Administrative privileges (only required if running tests that modify system-wide locations)

### Building MSI Packages

```powershell
# Build both x64 and arm64 MSI installers
powershell.exe -ExecutionPolicy Bypass -File .\packages\msi\build-msi.ps1 -Arch all

# Build only 64-bit Intel/AMD installer
powershell.exe -ExecutionPolicy Bypass -File .\packages\msi\build-msi.ps1 -Arch x64

# Build with explicit version override
powershell.exe -ExecutionPolicy Bypass -File .\packages\msi\build-msi.ps1 -Version 1.0.2 -Arch x64
```

### Running the MSI Test Suite

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\packages\msi\test-msi.ps1 -MsiPath .\packages\msi\DiamTek-JVM-1.0.1-x64.msi
```

---

## Security Hardening Matrix

| CWE Class | Description | Mitigation Strategy |
| :--- | :--- | :--- |
| **CWE-20** | Improper Input Validation | Strict validation of version strings, target architectures (`ValidateSet("all", "x64", "arm64")`), and `.msi` paths. |
| **CWE-59** | Improper Link Resolution | Embedded hooks enforce `Test-HasReparsePointInLineage` on PowerShell profiles, Windows Terminal `settings.json`, and shortcuts. |
| **CWE-74** | Injection via XML / WiX | Strict sanitization of version numbers and property attributes before embedding into WiX source XML (`jvm.wxs`). |
| **CWE-252** | Unchecked Return Value | Exit codes from `wix.exe`, `candle.exe`, `light.exe`, and `msiexec.exe` are strictly verified. |
| **CWE-426** | Untrusted Search Path | Pins `msiexec.exe` and `powershell.exe` to `[Environment+SpecialFolder]::System`. |
| **CWE-459** | Incomplete Cleanup | Both inner and outer `finally` blocks guarantee cleanup of temporary hooks, `.wix/` cache, `.wixobj`, and `.wixpdb` artifacts. |
| **CWE-460** | Exception Cleanup & Rollback | Registry handles are deterministically closed via `try / finally`, and install/uninstall hooks rollback state upon exception. |
| **CWE-611** | XML External Entity (XXE) | Disallows external DTD processing and schema entity expansion. |

---

[← Back to Main Repository Documentation](../../README.md) &nbsp;•&nbsp; [📦 Installation Guide](../../docs/INSTALLATION.md)