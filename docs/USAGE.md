# Usage Guide

The Java Version Manager for Windows acts both as an interactive TUI (Terminal User Interface) and a fully headless CLI for CI/CD automation.

## Interactive Mode

For the easiest experience, simply open your Command Prompt or PowerShell and type:
```cmd
jvm
```
This will launch the interactive ANSI-colored menu, allowing you to visually explore installed JDKs, fetch new versions, manage ecosystem tools (Maven, Gradle, etc.), and change global settings.

---

## Core CLI Commands

You can bypass the UI entirely by passing commands directly to the engine.

### Listing Versions
View all installed local Java versions and ecosystem candidates:
```cmd
jvm list
```

### Switching Active Versions
Immediately swap your system environment to a specific installed version:
```cmd
jvm use 21
```
*(This updates your global `JAVA_HOME` and live terminal instantly.)*

### Installing & Uninstalling
Install the latest feature release of Java:
```cmd
jvm install java
```
Install a specific version:
```cmd
jvm install 21
```
Uninstall a version cleanly:
```cmd
jvm uninstall 21
```

### Clearing the Environment
If you need to temporarily remove Java from your system `PATH` and `JAVA_HOME` without deleting the installed binaries:
```cmd
jvm clear
```
To see what your current environment is pointing to:
```cmd
jvm env
```

---

## Semantic Routing & Flags

You don't always have to specify exact version numbers. You can speak to the tool semantically, and it will query the official APIs at runtime to figure out the rest.

```cmd
jvm latest
jvm lts
jvm install lts
```

### Overrides
If you have multiple vendors (e.g., Oracle and Adoptium) installed for the same version, `jvm use 21` will pause and ask you which one you want. You can bypass this using flags:
```cmd
jvm use 21 --vendor adoptium
```
Force headless automated execution (great for CI/CD pipelines):
```cmd
jvm install lts --vendor oracle -y
```

---

## Ecosystem Management (SDKMAN! Parity)

This tool natively manages the JVM build ecosystem. You can install and switch between Maven, Gradle, Kotlin, Scala, and Groovy just like Java.

```cmd
jvm install gradle 8.5
jvm install maven latest
jvm use maven 3.9.6
```

---

## Directory-Based Auto-Switching

Instantly configure a project's required environment by simply running `jvm` inside any directory containing a `.java-version` or SDKMAN `.sdkmanrc` file.

### True Session Isolation
By default, auto-switching uses **Session Isolation**. This means it only swaps the Java version for your *current terminal window*, leaving your global Windows Registry untouched so you don't mess up other background projects.
```cmd
jvm
```
*(If a `.java-version` file containing `21` is found, the current terminal instantly switches to JDK 21).*

If you want the switch to be permanent across your entire Windows OS:
```cmd
jvm --global
```

### `.sdkmanrc` Hijacking
If you are collaborating with developers on Linux/macOS using SDKMAN!, this tool natively understands `.sdkmanrc` files. It will dynamically map their SDKMAN vendor strings (like `17-tem` or `21-amzn`) to your native Windows JDKs and isolate them for your session.

---

## Custom Local JDKs (BYO-JDK)

If you have a custom JDK build (or GraalVM native-image) downloaded manually, you can register it with the manager so it appears in the interactive UI and CLI routing.

```cmd
jvm link C:\path\to\my-custom-jdk my-custom-jdk
```
To remove a linked JDK:
```cmd
jvm unlink my-custom-jdk
```

---

## System Updates

Check your current version against the GitHub upstream:
```cmd
jvm version
```
Force an automatic, secure self-update to the latest release:
```cmd
jvm self-update
```