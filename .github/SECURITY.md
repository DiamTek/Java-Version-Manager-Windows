# Security Policy

## Supported Versions

Currently, only the latest release of the Java Version Manager for Windows is supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 0.6.x   | :white_check_mark: |
| < 0.6.0 | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within this project (e.g., path injection, UAC escalation exploits, or payload corruption), please **DO NOT** create a public GitHub issue. 

Instead, please report it privately using one of the following methods:
1. **GitHub Security Advisories**: Use the **Private vulnerability reporting** feature in GitHub under the `Security` tab of this repository.
2. **Direct Email**: Send a detailed report directly to the lead maintainer, Alexéy Shishkin, at **salexey09@gmail.com**.
3. **Discord**: Reach out via direct message on Discord at **@thehawk01**.

### What to Include in Your Report
Please provide as much context as possible to help us rapidly reproduce and patch the issue:
* The version(s) of `jvm.bat` affected.
* The exact steps, environment, or payload required to reproduce the exploit.
* The potential impact (e.g., local privilege escalation, arbitrary code execution).

### Response SLA
We take security extremely seriously. We pledge to:
* Acknowledge receipt of your vulnerability report within **48 hours**.
* Provide a timeline for investigation and patching.
* Credit you (if desired) in the release notes when the patch is published.