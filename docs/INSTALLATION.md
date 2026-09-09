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
Run the standalone build script from anywhere on your machine (compiles both `x64` and `arm64` by default):

```powershell
# If downloaded from the web or git archive, unblock once:
Unblock-File .\packages\msi\build-msi.ps1

# Build both x64 and arm64 MSIs (works from any working directory):
powershell -NoProfile -ExecutionPolicy Bypass -File .\packages\msi\build-msi.ps1

# Or target a specific architecture:
powershell -NoProfile -ExecutionPolicy Bypass -File .\packages\msi\build-msi.ps1 -Arch x64
powershell -NoProfile -ExecutionPolicy Bypass -File .\packages\msi\build-msi.ps1 -Arch arm64
```
The resulting single-file installers are placed directly into `packages\msi\`.

#### Automated Verification Suite
The MSI subsystem includes a fully autonomous, 14-point integration verification test suite (`packages\msi\test-msi.ps1`). It actively tests live operating system integration—including the Windows Installer service (`msiexec`), Windows Terminal `settings.json`, PowerShell `$PROFILE`, Windows Registry `PATH`, Start Menu shortcuts, and live CLI subshell process execution (`cmd.exe /c "jvm.bat --version"`).

##### Autonomous 4-Tier Resolution Engine
You can run `test-msi.ps1` from **any working directory** on any Windows machine (even on a clean machine with no prior source code, Git, .NET, or WiX installed). The test runner resolves packages using a 4-tier fallback hierarchy:
1. **Local Pre-Built MSI**: Discovers and tests `jvm-windows-*-x64.msi` if already present in `packages\msi\` or current path.
2. **Local WiX Compiler**: If the `.msi` is missing, executes `build-msi.ps1 -Arch x64` to compile it from local source files.
3. **Published GitHub Release**: If local build tools/source are not available, downloads the latest official `jvm-windows-1.0.0-x64.msi` directly from GitHub Releases.
4. **Remote Source Bootstrap**: If the release binary is not yet published, downloads the latest repository source archive (`main.zip`) from GitHub, extracts to `%TEMP%`, automatically bootstraps a user-space .NET SDK and WiX CLI, compiles the MSI, and runs the test suite.

##### Command Examples:
```powershell
# Unblock the file if downloaded via browser (clears Zone.Identifier):
Unblock-File .\packages\msi\test-msi.ps1

# 1. Run the test suite silently (standard headless CI mode):
powershell -NoProfile -ExecutionPolicy Bypass -File .\packages\msi\test-msi.ps1

# 2. Display the native Windows Installer progress bar dialog on screen:
powershell -NoProfile -ExecutionPolicy Bypass -File .\packages\msi\test-msi.ps1 -ShowUI

# 3. Test and keep JVM installed on your machine ready to use:
powershell -NoProfile -ExecutionPolicy Bypass -File .\packages\msi\test-msi.ps1 -KeepInstalled

# 4. Combine flags to watch the progress dialog and keep it installed:
powershell -NoProfile -ExecutionPolicy Bypass -File .\packages\msi\test-msi.ps1 -ShowUI -KeepInstalled

# 5. Test a specific custom MSI binary:
powershell -NoProfile -ExecutionPolicy Bypass -File .\packages\msi\test-msi.ps1 -MsiPath "C:\Path\To\custom.msi"
```

> [!TIP]
> **Interactive Graphical Setup Wizard**: By default, `test-msi.ps1` runs in silent mode (`/qn`) or progress dialog mode (`/qb` with `-ShowUI`). To open the traditional full Windows Installer wizard window with Next / Install / Finish buttons, double-click `packages\msi\jvm-windows-1.0.0-x64.msi` directly in File Explorer or run:
> ```cmd
> msiexec /i .\packages\msi\jvm-windows-1.0.0-x64.msi
> ```

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

### Downloaded Script Blocked or Not Digitally Signed (Zone.Identifier)
When downloading `.ps1` scripts, archives, or installers via a web browser (Edge, Chrome, Firefox), Windows Attachment Manager marks the files with a hidden NTFS alternate data stream: `Zone.Identifier` (`ZoneId=3` meaning "Internet").

Under the default Windows PowerShell execution policy (`RemoteSigned`), Windows requires all scripts downloaded from the Internet to possess a trusted Authenticode digital signature before allowing execution. Open-source scripts that are not signed with a commercial certificate will be blocked before line 1 with:
```text
File ... cannot be loaded. The file ... is not digitally signed.
```

To resolve this, unblock the file using any of these methods:

1. **PowerShell CLI (Recommended)**:
   ```powershell
   Unblock-File .\packages\msi\test-msi.ps1
   # Or unblock all scripts in the directory:
   Get-ChildItem -Path .\packages\msi -Filter *.ps1 | Unblock-File
   ```

2. **File Explorer GUI**:
   - Right-click the `.ps1` file in File Explorer and select **Properties**.
   - At the bottom of the **General** tab, check the **Unblock** checkbox.
   - Click **Apply** and then **OK**.

3. **ExecutionPolicy Bypass**:
   Launching PowerShell with `-ExecutionPolicy Bypass` instructs PowerShell to ignore both execution policies and zone restrictions for that session:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\packages\msi\test-msi.ps1
   ```

### PowerShell Execution Policy Errors
If the automated installer fails with a red error mentioning **"cannot be loaded because running scripts is disabled on this system"**, your Windows machine has strict execution policies enabled.

To fix this, open your PowerShell terminal and run:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Press **Y** to confirm, then try running the installation one-liner again.