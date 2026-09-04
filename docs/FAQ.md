# Frequently Asked Questions (FAQ)

### Why use this over SDKMAN! on Windows?
SDKMAN! is an incredible tool, but it is fundamentally built for Unix architectures (bash). Running it on Windows requires layers of virtualization like Windows Subsystem for Linux (WSL), Git Bash, or Cygwin. This Java Version Manager is built **100% natively** for Windows Command Prompt (`cmd.exe`) and PowerShell. It requires zero dependencies and directly manipulates the Windows Registry.

### Why isn't `java` recognized immediately after I switch versions?
If you run the switch command from the interactive menu, your *current* command prompt session is updated dynamically in memory. However, if you are running nested prompts or specific IDE terminals (like VS Code's integrated terminal, or an already-open IntelliJ instance), you may need to restart that terminal for the new `PATH` and `JAVA_HOME` variables to be inherited.

### Does this require Administrator (UAC) privileges?
Yes and no. The tool will run fine in user-space, but when you switch to a new JDK, it modifies the Global/Machine `JAVA_HOME` variable to ensure background services and global applications detect the change. When it needs to do this, it will automatically prompt you for UAC Elevation (the Windows Admin popup) gracefully, run the registry command, and return to your standard session. 

### How does it change the version globally without messing up my path?
Instead of adding a new folder to your system `PATH` every time you install a JDK, this tool adds one single entry: `%LOCALAPPDATA%\DiamTek\JVM\current\bin`. This is a Directory Junction. When you switch Java versions, the tool just changes where that junction points. Your actual `PATH` variable stays completely clean and bloat-free.

### Can I use this in a CI/CD pipeline (like GitHub Actions)?
Yes! The tool supports headless execution. You can bypass the interactive menu entirely by passing arguments directly, for example: `jvm install java 21` or `jvm use 21`.

### Does it support custom JDKs or private binaries?
Yes! You can manually extract any local JDK folder to the manager, allowing you to manage custom or private JDKs downloaded outside of the tool's internal API fetcher.

### Where are my JDKs and tools actually installed?
By default, this tool downloads, extracts, caches, and securely stores all JDKs and ecosystem tools (Maven, Gradle, Kotlin, etc.) inside the `%LOCALAPPDATA%\DiamTek\JVM` directory.

### How do I completely uninstall it?
You can use the built-in `jvm clear` command, or select the Uninstall option from the main menu. It will intelligently scrub all junction points, `JAVA_HOME`, and ecosystem variables from your Windows Registry, leaving your machine exactly as it was.