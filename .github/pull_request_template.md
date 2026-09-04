## Description
Please include a summary of the change and which issue is fixed (if applicable). Please also include relevant motivation and context.

Fixes # (issue)

## Type of change
Please delete options that are not relevant.
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Windows Architecture Checklist:
Because `jvm.bat` operates strictly natively on Windows, please review the following before submitting:
- [ ] I have tested this in **CMD** (Command Prompt).
- [ ] I have tested this in **PowerShell**.
- [ ] I have verified that this does not break the default UAC-free **Symlink Mode**.
- [ ] (If modifying core variables) I have verified it does not break Delayed Expansion (`!PATH!`).
- [ ] (If parsing directories) I have verified it handles spaces in file paths correctly.
- [ ] (If inline PowerShell is used) I have verified it does not conflict with strict Execution Policies.

## Additional Context
Add any other context, terminal screenshots, or tests executed about the pull request here.