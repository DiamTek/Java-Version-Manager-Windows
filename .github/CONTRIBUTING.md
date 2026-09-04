# Contributing to Java Version Manager for Windows

First off, thank you for considering contributing! It's people like you that make this tool great for the Windows developer community.

## How Can I Contribute?

### Reporting Bugs & Requesting Features
If you've noticed a bug or have a feature request, make sure to check the [Issues](https://github.com/DiamTek/Java-Version-Manager-Windows/issues) first to see if someone else has already created a ticket. If not, go ahead and make one! Please include:
* Your Windows version (e.g., Windows 10, Windows 11).
* The exact terminal you are using (CMD, PowerShell, Windows Terminal).
* Steps to reproduce the bug.

### Getting Help & Community
If you need help using the tool, have questions about the architecture, or want to discuss a massive feature idea before writing code, you can reach out directly to the lead maintainer, Alexéy Shishkin:
* **Discord**: DM me at **@thehawk01**
* **Email**: **salexey09@gmail.com**

### Pull Requests
We actively welcome pull requests! To ensure a smooth review process, please follow this workflow:

1. **Fork** the repo on GitHub.
2. **Clone** the project to your own machine.
3. **Branch** out to a new feature branch. Please use descriptive prefixes (e.g., `feat/add-kotlin-support`, `fix/uac-elevation-bug`, `docs/update-readme`).
4. **Commit** changes to your own branch. We highly recommend using **Conventional Commits** (e.g., `feat: add Kotlin auto-switching` or `fix: resolve delayed expansion path bug`).
5. **Push** your work back up to your fork.
6. Submit a **Pull Request** targeting the `main` branch.

**Code Review Process:**
Once you open a PR, the maintainers will review your code. We may ask for changes or tests to ensure it doesn't break older Windows 10 architectures. Don't be afraid to ask for help if you get stuck!

## Development Guidelines

If you are modifying the core `jvm.bat` engine, please keep the following Windows-specific architectures in mind:

- **Batch Scripting**: The core engine is written in native Windows Batch. Be mindful of delayed expansion rules (`setlocal enabledelayedexpansion`), `!PATH!` variable escaping, and quoting strings.
- **PowerShell Hooks**: Any inline PowerShell must be thoroughly tested. Do not use `!` for logical negation inside PowerShell strings executed from the batch script, as the CMD parser will destroy it. Use `-not` instead.
- **UAC & Architecture**: Ensure any changes do not break the Symlink Architecture (which is UAC-free) or the legacy Registry Architecture (which handles its own UAC elevation).
- **Self-Contained**: Do not add external dependencies (`.dll` files, `.exe` files, or separate `.ps1` scripts). The engine must remain a single, easily portable `jvm.bat` script.

## Documentation
Documentation improvements are always welcome! Our documentation is located in the `docs/` folder and uses standard Markdown.