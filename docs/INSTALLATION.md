# Installation

Getting started with the Java Version Manager for Windows takes less than 10 seconds. There are no external dependencies required.

## Standard Installation (PowerShell)

Open Windows PowerShell (you do not need Administrator privileges) and run the following command:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/install.ps1" -OutFile "$env:TEMP\install.ps1"; & "$env:TEMP\install.ps1"
```

### What this script does:
1. It downloads the latest `jvm.bat` core engine and companion branding assets (`icon.ico`, `icon.png`) from the repository.
2. It provisions the `%LOCALAPPDATA%\DiamTek\JVM\bin` and `assets` directory structure on your system.
3. It securely writes the `jvm.bat` executable into that binary path.
4. It dynamically injects the path into your PowerShell `$PROFILE` and standard Windows Registry `PATH` so the `jvm` command is available immediately across all shells.
5. It registers a dedicated **Windows Terminal Profile** with custom branding, launching `cmd.exe /c` with `closeOnExit: always` so tabs close cleanly on exit.
6. It creates a Start Menu application shortcut and automatically updates any pinned Taskbar shortcuts.
7. It registers into Windows Settings ("Installed apps") with an accurate dynamic `EstimatedSize` footprint calculation.

## Manual Installation

> [!WARNING]
> Downloading `jvm.bat` manually via a web browser can sometimes result in GitHub serving the file with UNIX line endings (LF) instead of Windows line endings (CRLF), or injecting hidden UTF-8 BOM characters. This can cause severe batch execution bugs (like the `cho` crash). The automated PowerShell installer above automatically sanitizes these artifacts.

If you prefer not to use the automated PowerShell script and understand the risks of manual text formatting, you can install the tool manually using the built-in UI:

1. Clone or download the repository to your machine (ensure it retains `CRLF` line endings).
2. Create a folder somewhere safe (e.g., `C:\Tools\JVM`).
3. Move the `jvm.bat` file into that folder.
4. Double-click `jvm.bat` or run it from a terminal to open the interactive menu.
5. Navigate to **Settings** (`3`) -> **Install Global Command** (`1`).
6. The script will dynamically inject its current folder into your Windows User PATH.
7. Restart your terminal and type `jvm`.

## Package Managers

### Winget
```powershell
winget install DiamTek.JVM
```

### Scoop
```powershell
scoop install jvm
```

### Chocolatey
```powershell
choco install jvm-windows
```

### Windows Installer (MSI)

Standalone, single-file Windows Installers are available for both **x64** (Intel/AMD) and **arm64** (Qualcomm Snapdragon / Windows on ARM):

1. Download `jvm-windows-1.0.0-x64.msi` or `jvm-windows-1.0.0-arm64.msi` directly from the [Releases](https://github.com/DiamTek/Java-Version-Manager-Windows/releases) page.
2. Double-click the `.msi` file to run the graphical setup wizard.

#### Silent / Headless Installation (Command Line)
For enterprise automation, scripts, or unattended CI environments:

```cmd
msiexec /i jvm-windows-1.0.0-x64.msi /qn
```

To enable verbose installation logging for diagnostics:
```cmd
msiexec /i jvm-windows-1.0.0-x64.msi /qn /l*v "%TEMP%\jvm-install.log"
```

#### Building the MSI from Source
You can compile native, standalone MSIs locally using the WiX Toolset v4 build pipeline:

**Prerequisites:**
- [.NET SDK 6.0+](https://dotnet.microsoft.com/download)
- WiX Toolset v4:
  ```powershell
  dotnet tool install --global wix
  ```

**Build Commands:**
```powershell
# Compiles both x64 and arm64 self-contained MSIs (default)
.\packages\msi\build-msi.ps1

# Or target a specific architecture
.\packages\msi\build-msi.ps1 -Arch x64
.\packages\msi\build-msi.ps1 -Arch arm64
```
The resulting single-file installers are placed directly into `packages\msi\`.

#### Automated Verification Suite
To validate the installer against a 14-point end-to-end integration checklist before deployment:
```powershell
.\packages\msi\test-msi.ps1 -MsiPath .\packages\msi\jvm-windows-1.0.0-x64.msi
```
This automated suite tests silent installation, directory structure, registry integrity, PATH propagation, Windows Terminal profile injection, CLI sanity, clean uninstallation, and zero filesystem residual traces.

---

## Uninstallation
 
DiamTek Java Version Manager includes a dedicated, UAC-elevated deep uninstaller (`uninstall.ps1`) that completely scrubs the application, system PATH entries, PowerShell `$PROFILE` hooks, environment variables, ecosystem tool caches, Windows Terminal profiles, pinned taskbar shortcuts, and installed JDKs.

You can uninstall JVM through any of the following methods:

1. **Windows Settings (Installed Apps):**
   - Open **Windows Settings** -> **Apps** -> **Installed apps**.
   - Locate **DiamTek Java Version Manager** and click **Uninstall**.
2. **Start Menu Shortcut:**
   - Search **"Uninstall Java Version Manager"** in the Windows taskbar search box and press **Enter**.
3. **Interactive Terminal Interface:**
   - Run `jvm` -> Navigate to **Settings** (`3`) -> Select **Uninstall JVM Completely** (`4`).
4. **Command Line (CLI):**
   ```cmd
   jvm self-uninstall
   ```
5. **Direct PowerShell Script:**
   ```powershell
   & "$env:LOCALAPPDATA\DiamTek\JVM\uninstall.ps1"
   ```
6. **Windows Installer (MSI) Silent Uninstallation:**
   ```cmd
   msiexec /x jvm-windows-1.0.0-x64.msi /qn
   ```

---

## Troubleshooting

### PowerShell Execution Policy Errors
If the automated installer fails with a red error mentioning **"cannot be loaded because running scripts is disabled on this system"**, your Windows machine has strict execution policies enabled.

To fix this, open your PowerShell terminal and run:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Press **Y** to confirm, then try running the installation one-liner again.