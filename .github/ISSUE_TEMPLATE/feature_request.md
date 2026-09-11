---
name: Feature request
about: Suggest a new feature, candidate tool, vendor API, or enhancement
title: '[FEATURE] '
labels: 'enhancement'
assignees: ''
---

## 💡 Feature Overview

- **Category**: `[e.g., New JDK Vendor, New Ecosystem Candidate Tool, CLI Command/Flag, Enterprise/MSI Deployment, Interactive TUI, Performance/Security]`
- **Short Summary**: A concise one-sentence description of the requested feature.

---

## 🎯 Problem Statement / Motivation

Is your feature request related to a specific problem, workflow friction, or enterprise limitation?
> *Example: "When onboarding developers on a mixed-OS team, we use tool X which isn't currently supported by the Universal Candidate Engine..."*

## 🚀 Proposed Solution & Behavior

Describe how you envision the feature working:
1. **CLI Syntax** (if applicable):
   ```cmd
   jvm install <tool> [version]
   # or
   jvm <command> --flag
   ```
2. **Interactive TUI Flow** (if applicable):
   How should this appear or behave inside the interactive menus?
3. **Environment Variables & Symlinks**:
   Which environment variables (e.g., `<TOOL>_HOME`, `PATH`) should be managed?

## 🔄 Alternatives Considered

Describe any alternative tools, manual workarounds, or approaches you have evaluated (e.g., SDKMAN!, Scoop, Chocolatey, manual scripts).

## 📚 API & Specification References

If proposing a new JDK vendor or ecosystem candidate tool, please provide links to:
- Official download mirror or release API (e.g., GitHub Releases API, Apache mirrors)
- Checksum / hash verification endpoints (SHA256, SHA512)
- Official documentation or packaging format (.zip)

## 📎 Additional Context

Add any other context, CLI mockups, terminal screenshots, or architectural considerations here.