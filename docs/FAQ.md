# Frequently Asked Questions (FAQ)

### Why use this over SDKMAN! on Windows?
SDKMAN! is an incredible tool, but it is fundamentally built for Unix architectures (bash). Running it on Windows requires layers of virtualization like Windows Subsystem for Linux (WSL), Git Bash, or Cygwin. This Java Version Manager is built **100% natively** for Windows Command Prompt (`cmd.exe`) and PowerShell. It requires zero dependencies and directly manipulates the Windows Registry.

### Why isn't `java` recognized immediately after I switch versions?
In most cases, it is recognized immediately! 
- **PowerShell (with Profile Hook):** The installer injects the `Set-JvmVar` hook into your PowerShell `$PROFILE`. When you switch versions with `jvm`, environment variables (`JAVA_HOME`, `Path`, toolchains) are dynamically injected into the active session memory on the fly without restarting.
- **Command Prompt (CMD):** In default **Symlink Mode**, your `PATH` points to the directory junction (`%LOCALAPPDATA%\DiamTek\JVM\current\bin`). The moment the junction target changes, all open CMD terminals resolve the new `java` binary immediately.
- **IDE Terminals & Background Daemons:** If an application (such as an open VS Code window, IntelliJ instance, or build daemon) cached the environment variables in its own process block before the switch, restarting that terminal or reload the IDE window will ensure the updated variables are picked up.

### Does this require Administrator (UAC) privileges?
It depends on which architecture mode you use:
- **Symlink Mode (Default, Recommended):** **100% UAC-Free!** It leverages a Windows Directory Junction (`%LOCALAPPDATA%\DiamTek\JVM\current`). Switching versions updates the junction pointer in user-space, requiring zero administrator privileges or UAC popups.
- **Registry Mode (Legacy):** **Requires Administrator (UAC) Elevation.** This optional mode writes absolute paths directly to the Machine-level Windows Registry (`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`). Every version switch will trigger a UAC prompt to elevate a background PowerShell process. This mode is provided for enterprise applications or legacy classloaders that cannot traverse NTFS Directory Junctions.

*Note: Administrator privileges are also requested when auto-downloading JDKs directly into `C:\Program Files\Java`, scrubbing rogue legacy paths from the Machine registry, or executing the deep system uninstaller (`uninstall.ps1` / `jvm self-uninstall`).*

### How does it change the version globally without messing up my path?
Instead of adding a new folder to your system `PATH` every time you install a JDK, this tool adds one single entry: `%LOCALAPPDATA%\DiamTek\JVM\current\bin`. This is a Directory Junction. When you switch Java versions, the tool just changes where that junction points. Your actual `PATH` variable stays completely clean and bloat-free.

### Can I use this in a CI/CD pipeline (like GitHub Actions)?
Yes! The tool supports headless execution. You can bypass the interactive menu entirely by passing arguments directly, for example: `jvm install java 21` or `jvm 21`.

### Does it support custom JDKs or private binaries?
Yes! You can use `jvm link <path> [name]` to register any custom or private JDK into the manager. It will integrate seamlessly into the dynamic menus and CLI routing.

### Where are my JDKs and tools actually installed?
By default, auto-downloaded JDKs are installed to `C:\Program Files\Java\<vendor-jdk>`, and ecosystem tools (Maven, Gradle, Kotlin, Scala, Groovy) are securely stored and cached in `%LOCALAPPDATA%\DiamTek\JVM\candidates\<tool>`.

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
- **Windows Installer (MSI):** Run `msiexec /x jvm-windows-1.0.0-x64.msi /qn`.