# Installation

Getting started with the Java Version Manager for Windows takes less than 10 seconds. There are no external dependencies required.

## Standard Installation (PowerShell)

Open Windows PowerShell (you do not need Administrator privileges) and run the following command:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/install.ps1" -OutFile "$env:TEMP\install.ps1"; & "$env:TEMP\install.ps1"
```

### What this script does:
1. It downloads the latest `jvm.bat` core engine from the `main` repository.
2. It provisions the `%LOCALAPPDATA%\DiamTek\JVM\bin` directory structure on your system.
3. It securely writes the `jvm.bat` executable into that binary path.
4. It dynamically injects the path into your PowerShell `$PROFILE` and standard Windows Registry `PATH` so the `jvm` command is available immediately in all future terminals.

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
Download the standalone `jvm-windows-1.0.0.msi` installer directly from the [Releases](https://github.com/DiamTek/Java-Version-Manager-Windows/releases) page and run the setup wizard.

---

## Uninstallation

DiamTek Java Version Manager includes a dedicated, UAC-elevated deep uninstaller (`uninstall.ps1`) that completely scrubs the application, system PATH entries, PowerShell `$PROFILE` hooks, environment variables, ecosystem tool caches, and installed JDKs.

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

---

## Troubleshooting

### PowerShell Execution Policy Errors
If the automated installer fails with a red error mentioning **"cannot be loaded because running scripts is disabled on this system"**, your Windows machine has strict execution policies enabled.

To fix this, open your PowerShell terminal and run:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Press **Y** to confirm, then try running the installation one-liner again.