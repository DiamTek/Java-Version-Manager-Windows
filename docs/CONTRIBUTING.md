<h1 align="center">Contributing to Java Version Manager for Windows</h1>

<div align="center" markdown="1">

[🏠 Overview](../README.md) &nbsp;•&nbsp; [📦 Installation](INSTALLATION.md) &nbsp;•&nbsp; [📖 Usage](USAGE.md) &nbsp;•&nbsp; [🏗️ Architecture](ARCHITECTURE.md) &nbsp;•&nbsp; [❓ FAQ](FAQ.md) &nbsp;•&nbsp; [⚖️ SDKMAN! Comparison](SDKMAN-Comparison.md) &nbsp;•&nbsp; [📜 Changelog](CHANGELOG.md)

</div>

---

First off, thank you for considering contributing! It's developers like you that keep this tool fast, secure, and rock-solid for the Windows engineering community.

---

## 🛠️ Local Development & Sandbox Testing

Because `jvm.bat` actively modifies system and user environment variables (`PATH`, `JAVA_HOME`), testing changes directly in your primary environment can disrupt your local development workflow. Follow these sandbox testing practices:

### 1. Isolated Execution (Local Checkout vs. Global PATH)
When testing local changes in your cloned repository, invoke the script directly from your working directory rather than relying on the installed command:

```cmd
:: In CMD or PowerShell, run the local working copy directly:
.\jvm.bat list
.\jvm.bat env
.\jvm.bat 21 --session
```

> [!NOTE]
> **Remember:** If you already have JVM installed and present in your system `PATH`, simply typing `jvm` will invoke the **globally installed** executable rather than your local working copy. When developing and testing locally, always prefix the command with `.\` (e.g. `.\jvm.bat list` or `.\jvm.bat 21 --session`). Once installed into `PATH`, standard users run `jvm` without prefixes from any directory.

### 2. Testing Session Switching (Zero System Impact)
Always use the `--session` flag during manual CLI testing. This mutates only the memory of the active subshell process and leaves your global Windows Registry and User environment untouched:

```cmd
:: CMD subshell verification:
cmd.exe /c ".\jvm.bat 21 --session && java -version"
```

> [!TIP]
> In PowerShell, running `.\jvm.bat 21 --session` spawns a transient child `cmd.exe` process, so session environment mutations do not persist into the parent PowerShell process. The global `jvm` command in PowerShell persists session variables because it is wrapped by the PowerShell `$PROFILE` hook function (`function jvm`). When developing locally in PowerShell, use the `cmd.exe /c` pattern above to test session switching.

### 3. Dedicated Sandbox Testing
To test directory junction creation and candidate downloads in total isolation, redirect the storage root temporarily before launching `jvm.bat`:

```cmd
set "LOCALAPPDATA=%TEMP%\JVM_Sandbox"
.\jvm.bat list
```

---

## 🧪 Automated Test Suite Execution

DiamTek JVM includes a synthetic 18-point integration test suite (`packages\msi\test-msi.ps1`) used by our CI/CD pipeline to validate real operating system integration.

### Running the Integration Test Suite

Open PowerShell (Run as Administrator if testing elevated MSI installation) and execute:

```powershell
# Run the complete test suite against local build artifacts:
powershell -ExecutionPolicy Bypass -File packages\msi\test-msi.ps1

# Run with interactive Windows Installer UI dialogs visible:
powershell -ExecutionPolicy Bypass -File packages\msi\test-msi.ps1 -ShowUI

# Keep the test installation for manual inspection post-run:
powershell -ExecutionPolicy Bypass -File packages\msi\test-msi.ps1 -KeepInstalled
```

### Building the WiX Toolset v4 MSI Locally

To verify installer packaging changes:

```powershell
# Compiles both x64 and arm64 MSIs into packages\msi\:
powershell -ExecutionPolicy Bypass -File packages\msi\build-msi.ps1 -Arch all
```

---

## 📐 Windows Scripting Rules & Pitfalls

The core `jvm.bat` engine is nearly 100 KB of mathematically optimized Windows Batch script. When contributing code, you **must** adhere to these battle-tested rules:

### 1. Strict CRLF Line Ending Enforcement
- **The Issue:** Windows `cmd.exe` parses batch scripts line-by-line using byte offsets. If a batch file is checked out with UNIX (`LF`) line endings, `cmd.exe` miscalculates byte offsets when parsing multi-line blocks, corrupting `echo` statements into `e` + `cho` (the infamous "`'cho' is not recognized`" bug).
- **The Rule:** Never commit LF-only scripts. Ensure git respects `.gitattributes` (`*.bat text eol=crlf`).

### 2. Delayed Expansion & Exclamation Mark Safety
- **The Issue:** When `setlocal enabledelayedexpansion` is active, `cmd.exe` eagerly parses exclamation marks (`!`) as variable references. A file path containing an exclamation mark (e.g. `C:\Projects\Test!App`) will have its name destroyed.
- **The Rule:** 
  - Never reference raw user input or unquoted paths inside delayed expansion blocks without prior sanitization.
  - In inline PowerShell strings executed via CMD, never use `!` for logical negation. Always use the `-not` operator (e.g. `Where-Object { -not ($_.Name -eq 'foo') }`).

### 3. Quote Encapsulation Across Subshell Boundaries
- **The Issue:** `PATH` strings on real-world Windows machines often contain rogue unclosed quotes (e.g., `C:\Program Files\Foo"Bar;C:\Java`). Standard `for /f "tokens=*" %%a in (...)` loops treat quotes as token delimiters, interpreting path segments as nonexistent files.
- **The Rule:** All variable-passing loops must use double-quote encapsulation:
  ```cmd
  for /f "tokens=*" %%A in ('""!DYNAMIC_CMD!""') do ( ... )
  ```

### 4. Metacharacter Sanitization for Repository Files
- **The Issue:** Untrusted project `.java-version` and `.sdkmanrc` files can embed shell redirection operators (`&`, `|`, `<`, `>`) to execute arbitrary code.
- **The Rule:** All file parsing pipelines must enforce metacharacter rejection:
  ```cmd
  for /f "usebackq tokens=*" %%v in (`type "%CONFIG_FILE%" 2^>nul ^| findstr /v "[&|<>]"`) do ( ... )
  ```

### 5. The "Zero External Dependencies" Rule
- **The Rule:** `jvm.bat` must run cleanly out-of-the-box on a fresh, clean install of Windows 10/11.
- Never add external dependencies (`.dll`, standalone `.exe`, `curl.exe`, `tar.exe`, `unzip.exe`, or external `.ps1` files). All networking, extraction, and cryptographic hashing must rely solely on native Windows APIs and inline PowerShell bridging.

---

## 🔄 Pull Request Workflow

We actively welcome contributions! Follow this workflow for a seamless review:

1. **Fork** the repository on GitHub.
2. **Create a topic branch** from `main`:
   ```bash
   git checkout -b feat/add-candidate-scala
   # or
   git checkout -b fix/path-quote-handling
   ```
3. **Write Conventional Commits:**
   - `feat: add Scala support to Universal Candidate Engine`
   - `fix: resolve delayed expansion path collision in BYO-JDK`
   - `docs: update Intune silent deployment switches`
   - `test: add synthetic validation case for ARM64 detection`
4. **Run the Pre-Flight Checklist:**
   - [ ] `cmd.exe /c "jvm.bat --version"` executes cleanly with exit code `0`.
   - [ ] Verified in standard **Command Prompt (`cmd.exe`)**.
   - [ ] Verified in **Windows PowerShell (5.1)** and **PowerShell (7+)**.
   - [ ] Verified in **Windows Terminal**.
   - [ ] UAC-free **Symlink Mode** switches without prompts.
   - [ ] No temporary script files left behind in `%TEMP%`.
5. **Open a Pull Request** targeting the `main` branch with a clear description and testing proof.

---

## 🤝 Code of Conduct

This project adheres to the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to uphold a welcoming, respectful, and inclusive environment for everyone.

Questions or architecture discussions? Reach out to Alexéy Shishkin on Discord (**@thehawk01**) or via email (**salexey09@gmail.com**).

---

[← Back to Documentation Overview](../README.md#documentation)