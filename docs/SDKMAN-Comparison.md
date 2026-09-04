# Comparison with SDKMAN!

[SDKMAN!](https://sdkman.io/) is the industry standard for managing Java versions and ecosystem tools. However, for native Windows users, it presents strict architectural challenges.

### The Problem with SDKMAN! on Windows
SDKMAN! is a collection of Bash scripts. To run it on Windows, developers must install Windows Subsystem for Linux (WSL), MSYS2, or Cygwin. While this is great for Linux-first developers, native Windows developers often find that JDKs installed *inside* WSL are not easily accessible by native Windows IDEs (like IntelliJ or VS Code running natively), nor do they map cleanly to standard Windows environment variables.

### The Native Windows Alternative
This Java Version Manager (`jvm.bat`) solves this by operating directly on the Windows Registry and native CMD/PowerShell environments.

| Feature | SDKMAN! | Java Version Manager (Windows) |
|---------|---------|--------------------------------|
| **Runtime** | Bash | Native Batch / PowerShell |
| **Dependencies** | WSL, Cygwin, or Git Bash | None |
| **Integration** | `.bashrc` / `.zshrc` | Windows Registry (`JAVA_HOME`, `PATH`) |
| **IDE Support** | Requires WSL bridges | 100% Native support (IntelliJ, Eclipse, VS Code) |

By using native Directory Junctions and Windows Environment Variables, this tool guarantees that once a JDK is selected, your entire Windows OS respects the change instantly, without the need for a virtualization layer.