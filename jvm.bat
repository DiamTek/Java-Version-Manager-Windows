@echo off
rem Java Version Manager
rem Copyright (C) 2026 DiamTek / Alexéy Shishkin

rem This program is free software: you can redistribute it and/or modify
rem it under the terms of the GNU Affero General Public License as
rem published by the Free Software Foundation, either version 3 of the
rem License, or (at your option) any later version.

rem This program is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
rem GNU Affero General Public License for more details.

rem You should have received a copy of the GNU Affero General Public License
rem along with this program.  If not, see <https://www.gnu.org/licenses/>.

rem Enforce pinned system executable paths against CWE-426 (Binary Planting in CWD)
set "NoDefaultCurrentDirectoryInExePath=1"
set "SYS32=C:\Windows\System32"
if defined SystemRoot if exist "%SystemRoot%\System32\cmd.exe" if /i "%SystemRoot:~1,2%"==":\" set "SYS32=%SystemRoot%\System32"
if not exist "%SYS32%\cmd.exe" if defined windir if exist "%windir%\System32\cmd.exe" set "SYS32=%windir%\System32"
if not exist "%SYS32%\cmd.exe" if defined SystemDrive if exist "%SystemDrive%\Windows\System32\cmd.exe" set "SYS32=%SystemDrive%\Windows\System32"
if not exist "%SYS32%\cmd.exe" set "SYS32=C:\Windows\System32"
if not exist "%SystemRoot%\System32\cmd.exe" for %%W in ("%SYS32%\..") do set "SystemRoot=%%~fW"

set "CMD_BIN=%SYS32%\cmd.exe"
set "PS_BIN=%SYS32%\WindowsPowerShell\v1.0\powershell.exe"
set "FIND_BIN=%SYS32%\find.exe"
set "FINDSTR_BIN=%SYS32%\findstr.exe"
set "REG_BIN=%SYS32%\reg.exe"
set "CHOICE_BIN=%SYS32%\choice.exe"
set "FSUTIL_BIN=%SYS32%\fsutil.exe"
set "WHERE_BIN=%SYS32%\where.exe"
set "TIMEOUT_BIN=%SYS32%\timeout.exe"
set "TASKLIST_BIN=%SYS32%\tasklist.exe"
set "CHCP_BIN=%SYS32%\chcp.com"
set "ICACLS_BIN=%SYS32%\icacls.exe"
set "ATTRIB_BIN=%SYS32%\attrib.exe"
set "EXPLORER_BIN=%SystemRoot%\explorer.exe"

rem Auto-repair Unix LF line endings to Windows CRLF if executed standalone from raw download
if "%~1"=="--internal-crlf-relaunch" shift & goto :BOOTSTRAP_START
if defined CI goto :BOOTSTRAP_START
if defined GITHUB_ACTIONS goto :BOOTSTRAP_START
set "RAW_BAT_SELF=%~f0"
"%PS_BIN%" -NoProfile -EncodedCommand JABwACAAPQAgACQAZQBuAHYAOgBSAEEAVwBfAEIAQQBUAF8AUwBFAEwARgAKAGkAZgAgACgAJABwACAALQBhAG4AZAAgACgAVABlAHMAdAAtAFAAYQB0AGgAIAAtAEwAaQB0AGUAcgBhAGwAUABhAHQAaAAgACQAcAApACkAIAB7AAoAIAAgACAAIAAkAGIAeQB0AGUAcwAgAD0AIABbAFMAeQBzAHQAZQBtAC4ASQBPAC4ARgBpAGwAZQBdADoAOgBSAGUAYQBkAEEAbABsAEIAeQB0AGUAcwAoACQAcAApAAoAIAAgACAAIAAkAGgAYQBzAEMAcgAgAD0AIAAkAGYAYQBsAHMAZQAKACAAIAAgACAAJABjAGgAZQBjAGsATABlAG4AIAA9ACAAWwBtAGEAdABoAF0AOgA6AE0AaQBuACgAJABiAHkAdABlAHMALgBMAGUAbgBnAHQAaAAsACAANAAwADkANgApAAoAIAAgACAAIABmAG8AcgAgACgAJABpACAAPQAgADAAOwAgACQAaQAgAC0AbAB0ACAAJABjAGgAZQBjAGsATABlAG4AOwAgACQAaQArACsAKQAgAHsACgAgACAAIAAgACAAIAAgACAAaQBmACAAKAAkAGIAeQB0AGUAcwBbACQAaQBdACAALQBlAHEAIAAxADMAKQAgAHsAIAAkAGgAYQBzAEMAcgAgAD0AIAAkAHQAcgB1AGUAOwAgAGIAcgBlAGEAawAgAH0ACgAgACAAIAAgAH0ACgAgACAAIAAgAGkAZgAgACgALQBuAG8AdAAgACQAaABhAHMAQwByACkAIAB7AAoAIAAgACAAIAAgACAAIAAgACQAdAB4AHQAIAA9ACAAWwBTAHkAcwB0AGUAbQAuAFQAZQB4AHQALgBFAG4AYwBvAGQAaQBuAGcAXQA6ADoAVQBUAEYAOAAuAEcAZQB0AFMAdAByAGkAbgBnACgAJABiAHkAdABlAHMAKQAKACAAIAAgACAAIAAgACAAIAAkAGMAcgBsAGYAIAA9ACAAJAB0AHgAdAAuAFIAZQBwAGwAYQBjAGUAKABbAHMAdAByAGkAbgBnAF0AWwBjAGgAYQByAF0AMQAwACwAIABbAHMAdAByAGkAbgBnAF0AWwBjAGgAYQByAF0AMQAzACAAKwAgAFsAYwBoAGEAcgBdADEAMAApAC4AUgBlAHAAbABhAGMAZQAoAFsAcwB0AHIAaQBuAGcAXQBbAGMAaABhAHIAXQAxADMAIAArACAAWwBjAGgAYQByAF0AMQAzACAAKwAgAFsAYwBoAGEAcgBdADEAMAAsACAAWwBzAHQAcgBpAG4AZwBdAFsAYwBoAGEAcgBdADEAMwAgACsAIABbAGMAaABhAHIAXQAxADAAKQAKACAAIAAgACAAIAAgACAAIAB0AHIAeQAgAHsAIABbAFMAeQBzAHQAZQBtAC4ASQBPAC4ARgBpAGwAZQBdADoAOgBXAHIAaQB0AGUAQQBsAGwAQgB5AHQAZQBzACgAJABwACwAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABTAHkAcwB0AGUAbQAuAFQAZQB4AHQALgBVAFQARgA4AEUAbgBjAG8AZABpAG4AZwAoACQAZgBhAGwAcwBlACkAKQAuAEcAZQB0AEIAeQB0AGUAcwAoACQAYwByAGwAZgApACkAIAB9ACAAYwBhAHQAYwBoACAAewB9AAoAIAAgACAAIAAgACAAIAAgAGUAeABpAHQAIAA0ADIACgAgACAAIAAgAH0ACgB9AA== >nul 2>&1
if "%errorlevel%"=="42" (
    "%CMD_BIN%" /c ""%~f0" --internal-crlf-relaunch %*"
    exit /b
)
:BOOTSTRAP_START

if defined CI set "JVM_NONINTERACTIVE=1"
if defined GITHUB_ACTIONS set "JVM_NONINTERACTIVE=1"

rem Allow help queries to display without initializing host directories
if /i "%~1"=="help" goto :EARLY_HELP
if /i "%~1"=="--help" goto :EARLY_HELP
if /i "%~1"=="-h" goto :EARLY_HELP
if "%~1"=="/?" goto :EARLY_HELP

rem Verify host environment directory existence before modifying host state
set "JVM_DIR=%LOCALAPPDATA%\DiamTek\JVM"
set "JVM_SECURE_TEMP=%JVM_DIR%\temp"

if not exist "%JVM_DIR%" (
    if defined JVM_NONINTERACTIVE goto :AUTO_INIT_HOST
    if not "%~1"=="" goto :AUTO_INIT_HOST
    set "AUTO_INIT=0"
    for %%A in (%*) do (
        if /i "%%~A"=="--yes" set "AUTO_INIT=1"
        if /i "%%~A"=="-y" set "AUTO_INIT=1"
    )
    if "!AUTO_INIT!"=="1" goto :AUTO_INIT_HOST

    echo.
    echo ============================================================
    echo            Java Version Manager - First Run Setup
    echo ============================================================
    echo.
    echo %cYELLOW%[ WARNING ]%cRESET% No JVM installation found on this computer:
    echo               %JVM_DIR%
    echo.
    echo               JVM needs to create this directory to store your
    echo               settings, active junctions, and state locks.
    echo.
    echo               Notice: If you are running standalone ^(e.g. from a USB^),
    echo               this directory will remain on this PC until you
    echo               run 'jvm self-uninstall' or delete it manually.
    echo               The program cannot remove it automatically if you cancel.
    echo.
    echo ============================================================
    "%CHOICE_BIN%" /C yn /N /M "Do you want to initialize the host directory now? (y/N): "
    if errorlevel 2 (
        echo.
        echo %cBLUE%[  INFO  ]%cRESET% Setup cancelled. No files or directories were created on this PC.
        if defined ORIG_CP "%CHCP_BIN%" %ORIG_CP% >nul 2>&1
        exit /b 0
    )
)

:AUTO_INIT_HOST
if not exist "%JVM_DIR%" mkdir "%JVM_DIR%" >nul 2>&1
:HOST_DIR_READY

call :EnsureSecureTemp
if errorlevel 1 exit /b 1
goto :AFTER_EARLY_HELP

:EARLY_HELP
call :ShowHelp
if defined ORIG_CP "%CHCP_BIN%" %ORIG_CP% >nul 2>&1
exit /b 0

:AFTER_EARLY_HELP

set "SKIP_CHECKSUM=0"
if /i "%JVM_SKIP_CHECKSUM%"=="1" set "SKIP_CHECKSUM=1"
if /i "%JVM_SKIP_CHECKSUM%"=="true" set "SKIP_CHECKSUM=1"

set "ORIG_CP="
for /f "tokens=2 delims=:" %%A in ('%CHCP_BIN% 2^>nul') do (
    for /f "tokens=1 delims=. " %%B in ("%%A") do set "ORIG_CP=%%B"
)
if not defined ORIG_CP set "ORIG_CP=437"
"%CHCP_BIN%" 65001 >nul

set "INVOCATION_DIR=%cd%"

set "JVM_VERSION=1.0.1"
set "JVM_BUILD=20261001.139"

rem Generate ESC character for ANSI color codes
for /F "delims=#" %%a in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"
set "cRED=%ESC%[91m"
set "cGREEN=%ESC%[92m"
set "cYELLOW=%ESC%[93m"
set "cBLUE=%ESC%[96m"
set "cPURPLE=%ESC%[95m"
set "cMAGENTA=%ESC%[95m"
set "cGRAY=%ESC%[90m"
set "cRESET=%ESC%[0m"

rem Respect industry-standard NO_COLOR environment variable (https://no-color.org)
if defined NO_COLOR (
    if not "%NO_COLOR%"=="" (
        set "cRED="
        set "cGREEN="
        set "cYELLOW="
        set "cBLUE="
        set "cPURPLE="
        set "cMAGENTA="
        set "cGRAY="
        set "cRESET="
    )
)

rem Define base JDK search locations BEFORE delayed expansion to prevent exclamation mark corruption
set "JVM_PF=%ProgramFiles%"
if not defined JVM_PF set "JVM_PF=C:\Program Files"
set "JVM_PF86=%ProgramFiles(x86)%"
if not defined JVM_PF86 set "JVM_PF86=C:\Program Files (x86)"
set "JVM_SYSDRIVE=%SystemDrive%"
if not defined JVM_SYSDRIVE set "JVM_SYSDRIVE=C:"
set "LOCATIONS[0]=%JVM_PF%\Java"
set "LOCATIONS[1]=%JVM_PF86%\Java"
set "LOCATIONS[2]=%JVM_SYSDRIVE%\Java"
set "LOCATIONS[3]=%USERPROFILE%\.jdks"
set "LOCATIONS[4]=%USERPROFILE%\.gradle\jdks"
set "LOCATIONS[5]=%LOCALAPPDATA%\JavaVersionManager\links"
set "LOCATIONS[6]=%JVM_PF%\Eclipse Adoptium"
set "LOCATIONS[7]=%JVM_PF%\Amazon Corretto"
set "LOCATIONS[8]=%JVM_PF%\Zulu"
set "LOCATIONS[9]=%JVM_PF%\BellSoft"
set "LOCATIONS[10]=%JVM_PF%\Semeru"
set "LOCATIONS[11]=%JVM_PF%\Microsoft"

set "SCRIPT_PATH=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

setlocal disabledelayedexpansion
call :RejectExclamationArg "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
if errorlevel 1 (
    endlocal
    echo %cRED%[ ERROR  ]%cRESET% Invalid link name or argument: poison character '!' is forbidden.
    if defined ORIG_CP "%CHCP_BIN%" %ORIG_CP% >nul
    exit /b 1
)
endlocal

setlocal enabledelayedexpansion
set "LOC_IDX=12"
if exist "%USERPROFILE%\scoop\apps" (
    for /d %%A in ("%USERPROFILE%\scoop\apps\*") do (
        if exist "%%A\current\bin\java.exe" (
            set "LOCATIONS[!LOC_IDX!]=%%A"
            set /a LOC_IDX+=1
        )
    )
)
set /a MAX_LOC=LOC_IDX-1

rem Parse .java-version and establish mode BEFORE changing directories or checking UAC!
set "SILENT_MODE=0"
set "CLI_TARGET="
set "SESSION_MODE=0"

set "SWITCH_MODE=SYMLINK"
if exist "%LOCALAPPDATA%\DiamTek\JVM\mode.txt" (
    set /p SWITCH_MODE=<"%LOCALAPPDATA%\DiamTek\JVM\mode.txt"
)
if /i not "!SWITCH_MODE!"=="DIRECT" set "SWITCH_MODE=SYMLINK"

set "UPDATE_CHANNEL=STABLE"
if exist "%LOCALAPPDATA%\DiamTek\JVM\channel.txt" (
    for /f "usebackq tokens=* delims= " %%A in ("%LOCALAPPDATA%\DiamTek\JVM\channel.txt") do set "UPDATE_CHANNEL=%%A"
)
if /i not "!UPDATE_CHANNEL!"=="NIGHTLY" set "UPDATE_CHANNEL=STABLE"

if /i "%~1"=="link" goto :HANDLE_LINKS
set "IS_ADMIN_RUN=0"
if /i "%~1"=="--admin-run" goto PARSE_ADMIN_RUN
goto SKIP_ADMIN_RUN
:PARSE_ADMIN_RUN
set "IS_ADMIN_RUN=1"
shift
:SKIP_ADMIN_RUN

if /i "%~1"=="unlink" goto :HANDLE_LINKS
set "CLI_COMMAND="
set "CLI_VENDOR="
set "TARGET_CANDIDATE=java"
:PARSE_CLI_ARGS
if "%~1"=="" goto :PARSE_DONE
if /i "%~1"=="use" ( shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="default" ( shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="pin" ( shift & goto :PARSE_PIN_ARGS )
if /i "%~1"=="local" ( shift & goto :PARSE_PIN_ARGS )
if /i "%~1"=="hook" ( shift & goto :PARSE_HOOK_ARGS )
if /i "%~1"=="exec" ( shift & goto :PARSE_EXEC_ARGS )
if /i "%~1"=="run" ( shift & goto :PARSE_EXEC_ARGS )
if /i "%~1"=="java" ( set "TARGET_CANDIDATE=java" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--java" ( set "TARGET_CANDIDATE=java" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="maven" ( set "TARGET_CANDIDATE=maven" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--maven" ( set "TARGET_CANDIDATE=maven" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="gradle" ( set "TARGET_CANDIDATE=gradle" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--gradle" ( set "TARGET_CANDIDATE=gradle" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="kotlin" ( set "TARGET_CANDIDATE=kotlin" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--kotlin" ( set "TARGET_CANDIDATE=kotlin" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="scala" ( set "TARGET_CANDIDATE=scala" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--scala" ( set "TARGET_CANDIDATE=scala" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="groovy" ( set "TARGET_CANDIDATE=groovy" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--groovy" ( set "TARGET_CANDIDATE=groovy" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="ant" ( set "TARGET_CANDIDATE=ant" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--ant" ( set "TARGET_CANDIDATE=ant" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="sbt" ( set "TARGET_CANDIDATE=sbt" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--sbt" ( set "TARGET_CANDIDATE=sbt" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="jbang" ( set "TARGET_CANDIDATE=jbang" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--jbang" ( set "TARGET_CANDIDATE=jbang" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="quarkus" ( set "TARGET_CANDIDATE=quarkus" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--quarkus" ( set "TARGET_CANDIDATE=quarkus" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="spring" ( set "TARGET_CANDIDATE=spring" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--spring" ( set "TARGET_CANDIDATE=spring" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="micronaut" ( set "TARGET_CANDIDATE=micronaut" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--micronaut" ( set "TARGET_CANDIDATE=micronaut" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="mn" ( set "TARGET_CANDIDATE=micronaut" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--mn" ( set "TARGET_CANDIDATE=micronaut" & shift & goto :PARSE_CLI_ARGS )
if /i "%~1"=="--vendor" (
    set "CLI_VENDOR=%~2"
    call :ValidateStrictIdentifier "!CLI_VENDOR!" CLI_VENDOR
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Invalid vendor identifier: !CLI_VENDOR!
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 1
    )
    shift
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--yes" (
    set "FORCE_YES=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="-y" (
    set "FORCE_YES=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--skip-checksum" (
    set "SKIP_CHECKSUM=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--no-verify" (
    set "SKIP_CHECKSUM=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--latest" (
    set "FLAG_LATEST=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--session" (
    set "SESSION_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--symlink" (
    set "SWITCH_MODE_OVERRIDE=SYMLINK"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--legacy" (
    set "SWITCH_MODE_OVERRIDE=DIRECT"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--registry" (
    set "SWITCH_MODE_OVERRIDE=DIRECT"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--global" (
    set "FORCE_GLOBAL=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--offline" (
    set "JVM_OFFLINE=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--json" (
    set "OUTPUT_JSON=1"
    set "cRED="
    set "cGREEN="
    set "cYELLOW="
    set "cBLUE="
    set "cPURPLE="
    set "cMAGENTA="
    set "cGRAY="
    set "cRESET="
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--no-lock" (
    set "JVM_NO_LOCK=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--locked" (
    set "FLAG_LOCKED=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="-l" (
    set "FLAG_LOCKED=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--lock" (
    set "FLAG_CREATE_LOCK=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--no-color" (
    set "cRED="
    set "cGREEN="
    set "cYELLOW="
    set "cBLUE="
    set "cPURPLE="
    set "cMAGENTA="
    set "cGRAY="
    set "cRESET="
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--channel" (
    set "UPDATE_CHANNEL=%~2"
    set "UPDATE_CHANNEL_OVERRIDE=%~2"
    shift
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="-c" (
    set "UPDATE_CHANNEL=%~2"
    set "UPDATE_CHANNEL_OVERRIDE=%~2"
    shift
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--nightly" (
    set "UPDATE_CHANNEL=NIGHTLY"
    set "UPDATE_CHANNEL_OVERRIDE=NIGHTLY"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--stable" (
    set "UPDATE_CHANNEL=STABLE"
    set "UPDATE_CHANNEL_OVERRIDE=STABLE"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--admin-run" (
    set "IS_ADMIN_RUN=1"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="list" (
    set "CLI_COMMAND=list"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="ls" (
    set "CLI_COMMAND=list"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="env" (
    set "CLI_COMMAND=env"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="install" (
    set "CLI_COMMAND=install"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="lock" (
    set "CLI_COMMAND=lock"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="self-uninstall" (
    set "CLI_COMMAND=self-uninstall"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="uninstall-self" (
    set "CLI_COMMAND=self-uninstall"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="uninstall" (
    set "CLI_COMMAND=uninstall"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="rm" (
    set "CLI_COMMAND=uninstall"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="remove" (
    set "CLI_COMMAND=uninstall"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="update" (
    set "CLI_COMMAND=update"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="self-update" (
    set "CLI_COMMAND=self-update"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="version" (
    set "CLI_COMMAND=version"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="--version" (
    set "CLI_COMMAND=version"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="-v" (
    set "CLI_COMMAND=version"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="clear" (
    set "CLI_COMMAND=clear"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="channel" (
    set "CLI_COMMAND=channel"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="current" (
    set "CLI_COMMAND=current"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="status" (
    set "CLI_COMMAND=current"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="info" (
    set "CLI_COMMAND=current"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="whoami" (
    set "CLI_COMMAND=current"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="clean" (
    set "CLI_COMMAND=clean"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="prune" (
    set "CLI_COMMAND=clean"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="which" (
    set "CLI_COMMAND=which"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="path" (
    set "CLI_COMMAND=which"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="doctor" (
    set "CLI_COMMAND=doctor"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="check" (
    set "CLI_COMMAND=doctor"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="open" (
    set "CLI_COMMAND=open"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="home" (
    set "CLI_COMMAND=open"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="help" (
    set "CLI_COMMAND=help"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="--help" (
    set "CLI_COMMAND=help"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if /i "%~1"=="-h" (
    set "CLI_COMMAND=help"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else if "%~1"=="/?" (
    set "CLI_COMMAND=help"
    set "SILENT_MODE=1"
    shift
    goto :PARSE_CLI_ARGS
) else (
    if not defined CLI_TARGET (
        set "CLI_TARGET=%~1"
        set "SILENT_MODE=1"
    )
    shift
    goto :PARSE_CLI_ARGS
)

:PARSE_HOOK_ARGS
set "CLI_COMMAND=hook"
set "SILENT_MODE=1"
set "SKIP_HEADER=1"
if /i "%~1"=="install" ( set "CLI_TARGET=install" & shift )
if /i "%~1"=="setup" ( set "CLI_TARGET=install" & shift )
if /i "%~1"=="remove" ( set "CLI_TARGET=remove" & shift )
if /i "%~1"=="uninstall" ( set "CLI_TARGET=remove" & shift )
if /i "%~1"=="status" ( set "CLI_TARGET=status" & shift )
if /i "%~1"=="check" ( set "CLI_TARGET=status" & shift )
goto :PARSE_DONE

:PARSE_PIN_ARGS
set "PIN_VAL=%~1"
if not defined PIN_VAL (
    if exist "%INVOCATION_DIR%\.java-version" (
        echo.
        echo %cBLUE%[  INFO  ]%cRESET% Current pinned Java version in this directory:
        echo ============================================================
        type "%INVOCATION_DIR%\.java-version"
        echo.
        echo ============================================================
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 0
    ) else (
        echo.
        echo %cYELLOW%[ WARNING]%cRESET% No .java-version file exists in this directory.
        echo             Usage: jvm pin ^<version^> [flags]
        echo             Example: jvm pin 21
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 1
    )
)

set "PIN_CONTENT="
:COLLECT_PIN_LOOP
if "%~1"=="" goto :DO_PIN_WRITE
set "_PIN_TOK=%~1"
if /i "!_PIN_TOK!"=="--vendor" (
    set "_PIN_VEND=%~2"
    call :ValidateStrictIdentifier "!_PIN_VEND!" _PIN_VEND
    if errorlevel 1 (
        echo.
        echo %cRED%[ ERROR  ]%cRESET% Invalid vendor identifier for pin: %~2
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 1
    )
    if not defined PIN_CONTENT (
        set "PIN_CONTENT=--vendor !_PIN_VEND!"
    ) else (
        set "PIN_CONTENT=!PIN_CONTENT! --vendor !_PIN_VEND!"
    )
    shift
    shift
    goto :COLLECT_PIN_LOOP
)
if /i "!_PIN_TOK!"=="--symlink" (
    if not defined PIN_CONTENT (
        set "PIN_CONTENT=--symlink"
    ) else (
        set "PIN_CONTENT=!PIN_CONTENT! --symlink"
    )
    shift
    goto :COLLECT_PIN_LOOP
)
call :ValidateStrictIdentifier "!_PIN_TOK!" _PIN_TOK
if errorlevel 1 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier for pin: %~1
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
if not defined PIN_CONTENT (
    set "PIN_CONTENT=!_PIN_TOK!"
) else (
    set "PIN_CONTENT=!PIN_CONTENT! !_PIN_TOK!"
)
shift
goto :COLLECT_PIN_LOOP

:DO_PIN_WRITE
call :AcquireStateLock
if errorlevel 1 (
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
if not defined PIN_CONTENT (
    call :ReleaseStateLock
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier for pin.
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
if /i "!PIN_CONTENT!"=="current" (
    call :ReleaseStateLock
    echo.
    echo %cRED%[ ERROR  ]%cRESET% 'current' is a reserved keyword and cannot be pinned.
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
set "PIN_FOUND=0"
for /l %%k in (1,1,!JDK_COUNT!) do (
    if "!JDK_MAJOR_%%k!"=="!PIN_CONTENT!" set "PIN_FOUND=1"
    if /i "!JDK_NAME_%%k!"=="!PIN_CONTENT!" set "PIN_FOUND=1"
)
if "!PIN_FOUND!"=="0" (
    call :ReleaseStateLock
    echo.
    echo %cRED%[ ERROR  ]%cRESET% JDK '!PIN_CONTENT!' not found among installed JDKs.
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
if exist "%INVOCATION_DIR%\.java-version\" (
    call :ReleaseStateLock
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Security violation: .java-version is a directory or junction.
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
"%FSUTIL_BIN%" reparsepoint query "%INVOCATION_DIR%\.java-version" >nul 2>&1
if not errorlevel 1 (
    call :ReleaseStateLock
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Security violation: Refusing to overwrite symlink/reparse point .java-version.
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
(call )
(echo !PIN_CONTENT!)>"%INVOCATION_DIR%\.java-version" 2>nul
if errorlevel 1 (
    call :ReleaseStateLock
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Failed to write .java-version to: %INVOCATION_DIR%\.java-version
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
if not exist "%INVOCATION_DIR%\.java-version" (
    call :ReleaseStateLock
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Failed to create .java-version in: %INVOCATION_DIR%
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
echo.
echo %cGREEN%[   OK   ]%cRESET% Successfully pinned Java version '!PIN_CONTENT!' to:
echo            %INVOCATION_DIR%\.java-version
call :ReleaseStateLock
if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
exit /b 0

:PARSE_EXEC_ARGS
if /i "%~1"=="--vendor" (
    set "CLI_VENDOR=%~2"
    call :ValidateStrictIdentifier "!CLI_VENDOR!" CLI_VENDOR
    if errorlevel 1 (
        echo.
        >&2 echo %cRED%[ ERROR  ]%cRESET% Invalid vendor identifier for exec: !CLI_VENDOR!
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 1
    )
    shift
    shift
)
set "EXEC_TARGET=%~1"
if not defined EXEC_TARGET (
    echo.
    >&2 echo %cRED%[ ERROR  ]%cRESET% Missing target version for exec.
    >&2 echo            Usage: jvm exec ^<version^> [--] ^<command^> [args...]
    >&2 echo            Example: jvm exec 21 -- java -version
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
if /i "!EXEC_TARGET!" NEQ "latest" if /i "!EXEC_TARGET!" NEQ "lts" (
    call :ValidateStrictIdentifier "!EXEC_TARGET!" EXEC_TARGET
    if errorlevel 1 (
        echo.
        >&2 echo %cRED%[ ERROR  ]%cRESET% Invalid target version for exec: !EXEC_TARGET!
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 1
    )
)
shift
if "%~1"=="--" shift
if "%~1"=="" (
    echo.
    >&2 echo %cRED%[ ERROR  ]%cRESET% No command specified to execute.
    >&2 echo            Usage: jvm exec ^<version^> [--] ^<command^> [args...]
    >&2 echo            Example: jvm exec 21 -- java -version
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)

set "EXEC_CMD="
:COLLECT_EXEC_LOOP
if "%~1"=="" goto :DO_EXEC_RUN
setlocal disabledelayedexpansion
call :RejectExclamationArg %1
if errorlevel 1 (
    endlocal
    >&2 echo %cRED%[ ERROR  ]%cRESET% Invalid argument in exec command: poison character '!' is forbidden.
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
endlocal
if not defined EXEC_CMD (
    set "EXEC_CMD=%1"
) else (
    set "EXEC_CMD=!EXEC_CMD! %1"
)
shift
goto :COLLECT_EXEC_LOOP

:DO_EXEC_RUN
set "EXEC_TRIM=!EXEC_CMD: =!"
set "EXEC_TRIM=!EXEC_TRIM:"=!"
if not defined EXEC_TRIM (
    echo.
    >&2 echo %cRED%[ ERROR  ]%cRESET% No command specified to execute.
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 1
)
set "CLI_COMMAND=exec"
set "SILENT_MODE=1"
set "SKIP_HEADER=1"
goto :MAIN_LOOP

:PARSE_DONE

set "WANT_UTF8=0"
if "%SILENT_MODE%"=="0" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="version" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="self-update" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="self-uninstall" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="help" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="current" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="status" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="clean" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="which" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="doctor" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="open" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="hook" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="channel" set "WANT_UTF8=1"
if /i "%CLI_COMMAND%"=="lock" set "WANT_UTF8=1"
if "%WANT_UTF8%"=="1" "%CHCP_BIN%" 65001 >nul
if "%SILENT_MODE%"=="0" title Java Version Manager

rem Detect Hardware Architecture
set "SYS_ARCH=x64"
set "ZULU_ARCH=x86"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "SYS_ARCH=aarch64"
    set "ZULU_ARCH=arm"
)

rem If a target was provided via CLI, set variables
set "SKIP_HEADER=0"

if defined CLI_COMMAND (
    set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="help" (
        call :ShowHelp
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 0
    )
    if /i "%CLI_COMMAND%"=="which" (
        call :WhichBinary
        set "FAST_EXIT=!errorlevel!"
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b !FAST_EXIT!
    )
    if /i "%CLI_COMMAND%"=="current" if /i "!TARGET_CANDIDATE!"=="java" (
        call :ShowCurrentStatus
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 0
    )
    if /i "%CLI_COMMAND%"=="status" if /i "!TARGET_CANDIDATE!"=="java" (
        call :ShowCurrentStatus
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 0
    )
    if /i "%CLI_COMMAND%"=="env" if /i "!TARGET_CANDIDATE!"=="java" (
        call :ShowCurrentStatus
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 0
    )
    if /i "%CLI_COMMAND%"=="lock" (
        call :ExecuteLockCommand
        set "FAST_EXIT=!errorlevel!"
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b !FAST_EXIT!
    )
)
if /i not "!TARGET_CANDIDATE!"=="java" (
    if defined CLI_COMMAND (
        call :RouteEcosystemCandidate
        set "FAST_EXIT=!errorlevel!"
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b !FAST_EXIT!
    )
    if defined CLI_TARGET (
        call :RouteEcosystemCandidate
        set "FAST_EXIT=!errorlevel!"
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b !FAST_EXIT!
    )
)
if "!FLAG_LOCKED!"=="1" if not defined CLI_COMMAND (
    call :ExecuteLockedInstall
    set "FAST_EXIT=!errorlevel!"
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b !FAST_EXIT!
)
if defined CLI_TARGET (
    set "SKIP_HEADER=1"
) else if not defined CLI_COMMAND (
    if exist "%INVOCATION_DIR%\.java-version" (
        set "PARSED_JV="
        set "JV_PARSE_ERR=0"
        %FINDSTR_BIN% /r /v "^[ \t]*# ^ï»¿[ \t]*# ^[ \t]*$" "%INVOCATION_DIR%\.java-version" 2>nul | %FINDSTR_BIN% "[&|<>`%%!;$()^{}]" >nul 2>&1
        if not errorlevel 1 set "JV_PARSE_ERR=1"
        %FINDSTR_BIN% /c:"\"" "%INVOCATION_DIR%\.java-version" >nul 2>&1
        if not errorlevel 1 set "JV_PARSE_ERR=1"
        if "!JV_PARSE_ERR!"=="0" (
            for /f "eol=# delims=" %%L in ('%FINDSTR_BIN% /r /v "^[ \t]*# ^ï»¿[ \t]*# ^[ \t]*$" "%INVOCATION_DIR%\.java-version" 2^>nul ^| %FINDSTR_BIN% /r "[0-9]"') do (
                if not defined PARSED_JV (
                    call :ParseJavaVersion %%L
                    if errorlevel 1 set "JV_PARSE_ERR=1"
                    set "PARSED_JV=1"
                    if not "!FORCE_GLOBAL!"=="1" set "SESSION_MODE=1"
                    set "SILENT_MODE=1"
                    set "SKIP_HEADER=1"
                )
            )
        )
        if not defined PARSED_JV set "JV_PARSE_ERR=1"
        if "!JV_PARSE_ERR!"=="1" (
            echo %cRED%[ ERROR  ]%cRESET% Invalid or unsafe configuration in .java-version.
            if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
            exit /b 1
        )
    ) else if exist "%INVOCATION_DIR%\.sdkmanrc" (
        set "FOUND_SDKMANRC=1"
        set "SDK_PARSE_ERR=0"
        %FINDSTR_BIN% /r /v "^[ \t]*# ^ï»¿[ \t]*# ^[ \t]*$" "%INVOCATION_DIR%\.sdkmanrc" 2>nul | %FINDSTR_BIN% "[&|<>`%%!;$()^{}]" >nul 2>&1
        if not errorlevel 1 set "SDK_PARSE_ERR=1"
        %FINDSTR_BIN% /c:"\"" "%INVOCATION_DIR%\.sdkmanrc" >nul 2>&1
        if not errorlevel 1 set "SDK_PARSE_ERR=1"
        %FINDSTR_BIN% /r /v "^[ \t]*# ^ï»¿[ \t]*# ^[ \t]*$" "%INVOCATION_DIR%\.sdkmanrc" 2>nul | %FINDSTR_BIN% /v "=" >nul 2>&1
        if not errorlevel 1 set "SDK_PARSE_ERR=1"
        if "!SDK_PARSE_ERR!"=="0" (
            for /f "eol=# delims=" %%L in ('%FINDSTR_BIN% /i /r "^[ \t]*java[ \t]*=" "%INVOCATION_DIR%\.sdkmanrc" 2^>nul') do (
                for /f "tokens=1,* delims==" %%A in ("%%L") do (
                    set "_SDK_RVAL=%%B"
                    for /f "tokens=*" %%S in ("!_SDK_RVAL!") do set "_SDK_RVAL=%%S"
                    call :ParseSdkmanrc "!_SDK_RVAL!"
                    if errorlevel 1 set "SDK_PARSE_ERR=1"
                )
            )
        )
        if "!SDK_PARSE_ERR!"=="1" (
            echo %cRED%[ ERROR  ]%cRESET% Invalid or unsafe Java version in .sdkmanrc.
            if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
            exit /b 1
        )
        if not "!FORCE_GLOBAL!"=="1" set "SESSION_MODE=1"
        set "SILENT_MODE=1"
        set "SKIP_HEADER=1"
        if not defined CLI_TARGET set "CLI_TARGET=SKIP_JAVA"
    )
)

if /i "%CLI_COMMAND%"=="clear" set "SKIP_HEADER=1"

rem Check if the script is running as Administrator
if "%SESSION_MODE%"=="1" goto :SKIP_ADMIN_CHECK
if defined CLI_COMMAND (
    if /i "%CLI_COMMAND%"=="list" goto :SKIP_ADMIN_CHECK
    if /i "%CLI_COMMAND%"=="env" goto :SKIP_ADMIN_CHECK
    if /i "%CLI_COMMAND%"=="current" goto :SKIP_ADMIN_CHECK
    if /i "%CLI_COMMAND%"=="status" goto :SKIP_ADMIN_CHECK
    if /i "%CLI_COMMAND%"=="clean" goto :SKIP_ADMIN_CHECK
    if /i "%CLI_COMMAND%"=="which" goto :SKIP_ADMIN_CHECK
    if /i "%CLI_COMMAND%"=="doctor" goto :SKIP_ADMIN_CHECK
    if /i "%CLI_COMMAND%"=="open" goto :SKIP_ADMIN_CHECK
    if /i "%CLI_COMMAND%"=="exec" goto :SKIP_ADMIN_CHECK
    if /i "%CLI_COMMAND%"=="channel" goto :SKIP_ADMIN_CHECK
)

rem By default, run everything inline without Admin. We only elevate for specific file/registry operations.
goto :SKIP_ADMIN_CHECK

:SKIP_ADMIN_CHECK

rem CRITICAL: Set the working directory to the script's location
cd /d "%~dp0"
:MAIN_LOOP
rem Clear the variable before calling the menu to ensure a clean state
set "CURRENT_JDK_PATH="

rem Reload config in case it was changed inside a setlocal block
if exist "%LOCALAPPDATA%\DiamTek\JVM\mode.txt" (
    for /f "usebackq tokens=* delims= " %%A in ("%LOCALAPPDATA%\DiamTek\JVM\mode.txt") do set "SWITCH_MODE=%%A"
)
if /i not "!SWITCH_MODE!"=="DIRECT" set "SWITCH_MODE=SYMLINK"

if exist "%LOCALAPPDATA%\DiamTek\JVM\channel.txt" (
    for /f "usebackq tokens=* delims= " %%A in ("%LOCALAPPDATA%\DiamTek\JVM\channel.txt") do set "UPDATE_CHANNEL=%%A"
)
if /i not "!UPDATE_CHANNEL!"=="NIGHTLY" set "UPDATE_CHANNEL=STABLE"

if defined SWITCH_MODE_OVERRIDE (
    set "SWITCH_MODE=%SWITCH_MODE_OVERRIDE%"
)

if defined UPDATE_CHANNEL_OVERRIDE (
    if /i "!UPDATE_CHANNEL_OVERRIDE!"=="NIGHTLY" (
        set "UPDATE_CHANNEL=NIGHTLY"
    ) else (
        set "UPDATE_CHANNEL=STABLE"
    )
)

rem Jump straight to the menu function to prevent screen clearing issues
call :ShowDynamicMenu
set "MENU_EXIT_CODE=!errorlevel!"

rem If CURRENT_JDK_PATH is not set, the user chose the Exit option (unless purely doing ecosystem session switching)
if not defined CURRENT_JDK_PATH (
    if not "!FOUND_SDKMANRC!"=="1" (
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        if defined CMD_EXIT_CODE exit /B !CMD_EXIT_CODE!
        if not "!MENU_EXIT_CODE!"=="0" exit /B !MENU_EXIT_CODE!
        exit /B 0
    )
)

if "!CURRENT_JDK_PATH!"=="CLEAR" (
    call :ClearJavaEnvironment
    set "CURRENT_JDK_PATH="
    goto MAIN_LOOP
)

if "!SESSION_MODE!"=="1" (
    call :EmitSessionEnv RESET
    if errorlevel 1 (
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 1
    )
    echo.
    if defined CURRENT_JDK_PATH (
        echo %cBLUE%[ ACTION ]%cRESET% Session mode active. Setting Java to !CURRENT_JDK_PATH!...
        call :EmitSessionEnv "JAVA_HOME=!CURRENT_JDK_PATH!"
        set "JAVA_HOME=!CURRENT_JDK_PATH!"
        set "PATH=!CURRENT_JDK_PATH!\bin;!PATH!"
    ) else (
        echo %cBLUE%[ ACTION ]%cRESET% Session mode active.
    )
    
    if "!FOUND_SDKMANRC!"=="1" (
        set "SDK_ECO_ERR=0"
        %FINDSTR_BIN% /r /v "^[ \t]*# ^[ \t]*$" "%INVOCATION_DIR%\.sdkmanrc" 2>nul | %FINDSTR_BIN% "[&|<>`%%!;$()^{}]" >nul 2>&1
        if not errorlevel 1 set "SDK_ECO_ERR=1"
        %FINDSTR_BIN% /c:"\"" "%INVOCATION_DIR%\.sdkmanrc" >nul 2>&1
        if not errorlevel 1 set "SDK_ECO_ERR=1"
        if "!SDK_ECO_ERR!"=="0" (
            for /f "eol=# tokens=1,* delims==" %%A in ('%FINDSTR_BIN% /r /v "^[ \t]*# ^[ \t]*$" "%INVOCATION_DIR%\.sdkmanrc" 2^>nul ^| %FINDSTR_BIN% /i /v "^java="') do (
                set "ECO_CAND=%%A"
                set "ECO_VER=%%B"
                call :ProcessEcosystemSession "!ECO_CAND!" "!ECO_VER!"
                if errorlevel 1 set "SDK_ECO_ERR=1"
            )
        )
        if "!SDK_ECO_ERR!"=="1" (
            echo %cRED%[ ERROR  ]%cRESET% Invalid or unsafe ecosystem configuration in .sdkmanrc.
            if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
            exit /b 1
        )
    )
    
    echo %cGREEN%[   OK   ]%cRESET% Session target saved.
    goto :VERIFICATION
)

echo.
set "JVM_DIR=%LOCALAPPDATA%\DiamTek\JVM"
set "CURRENT_SYMLINK=%LOCALAPPDATA%\DiamTek\JVM\current"

call :AcquireStateLock
if errorlevel 1 (
    if defined CLI_COMMAND (
        set "JVM_EXIT_CODE=1"
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
        endlocal & exit /b 1
    )
    pause
    goto MAIN_LOOP
)

if /i "!SWITCH_MODE!"=="DIRECT" (
    echo %cBLUE%[ ACTION ]%cRESET% Setting Java to !CURRENT_JDK_PATH!...
    echo %cBLUE%[  INFO  ]%cRESET% Setting JAVA_HOME to: !CURRENT_JDK_PATH!
    
    rem Output session target so the parent PowerShell window can sync immediately
    call :EmitSessionEnv RESET
    call :EmitSessionEnv "!CURRENT_JDK_PATH!"
    
    rem Deferring registry update to UpdateSystemPath to do both in one UAC prompt
    set "SYMLINK_OR_DIRECT=!CURRENT_JDK_PATH!"
) else (
    if not exist "!JVM_DIR!" mkdir "!JVM_DIR!"
    
    echo %cBLUE%[ ACTION ]%cRESET% Updating Directory Junction: !JVM_DIR!\current...
    
    set "PREV_JUNCTION_TARGET="
    if exist "!CURRENT_SYMLINK!" (
        "%FSUTIL_BIN%" reparsepoint query "!CURRENT_SYMLINK!" >nul 2>&1
        if errorlevel 1 (
            echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): !CURRENT_SYMLINK! is a regular directory, not a junction.
            call :ReleaseStateLock
            if defined CLI_COMMAND (
                set "JVM_EXIT_CODE=1"
                if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
                endlocal & exit /b 1
            )
            pause
            goto MAIN_LOOP
        )
        for /f "delims=" %%T in ('%PS_BIN% -NoProfile -Command "$i = Get-Item -LiteralPath $env:CURRENT_SYMLINK -Force -ErrorAction SilentlyContinue; if ($i -and $i.Target) { $i.Target | Select-Object -First 1 }" 2^>nul') do set "PREV_JUNCTION_TARGET=%%T"
        rmdir "!CURRENT_SYMLINK!" >nul 2>&1
        if exist "!CURRENT_SYMLINK!" (
            echo %cRED%[ ERROR  ]%cRESET% Failed to remove existing Directory Junction.
            call :ReleaseStateLock
            if defined CLI_COMMAND (
                set "JVM_EXIT_CODE=1"
                if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
                endlocal & exit /b 1
            )
            pause
            goto MAIN_LOOP
        )
    )
    mklink /J "!CURRENT_SYMLINK!" "!CURRENT_JDK_PATH!" >nul 2>&1
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to create Directory Junction.
        echo            Notice: NTFS Directory Junctions require local NTFS volumes.
        echo            If %%LOCALAPPDATA%% or your JDK is on a network drive or UNC share,
        echo            switch to legacy Registry mode:
        echo            %cCYAN%jvm mode legacy%cRESET%
        if defined PREV_JUNCTION_TARGET if exist "!PREV_JUNCTION_TARGET!" mklink /J "!CURRENT_SYMLINK!" "!PREV_JUNCTION_TARGET!" >nul 2>&1
        if defined PREV_JUNCTION_TARGET (
            "%FSUTIL_BIN%" reparsepoint query "!CURRENT_SYMLINK!" >nul 2>&1
            if errorlevel 1 (
                echo.
                echo %cRED%[CRITICAL]%cRESET% Double-fault: Failed to restore previous directory junction!
                echo            Junction path:   !CURRENT_SYMLINK!
                echo            Previous target: !PREV_JUNCTION_TARGET!
                echo.
                echo            To restore manually, run:
                echo            %cCYAN%mklink /J "!CURRENT_SYMLINK!" "!PREV_JUNCTION_TARGET!"%cRESET%
                echo.
            )
        )
        call :ReleaseStateLock
        if defined CLI_COMMAND (
            set "JVM_EXIT_CODE=1"
            if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
            endlocal & exit /b 1
        )
        pause
        goto MAIN_LOOP
    )
    "%FSUTIL_BIN%" reparsepoint query "!CURRENT_SYMLINK!" >nul 2>&1
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Junction verification failed.
        rmdir "!CURRENT_SYMLINK!" >nul 2>&1
        if defined PREV_JUNCTION_TARGET if exist "!PREV_JUNCTION_TARGET!" mklink /J "!CURRENT_SYMLINK!" "!PREV_JUNCTION_TARGET!" >nul 2>&1
        if defined PREV_JUNCTION_TARGET (
            "%FSUTIL_BIN%" reparsepoint query "!CURRENT_SYMLINK!" >nul 2>&1
            if errorlevel 1 (
                echo.
                echo %cRED%[CRITICAL]%cRESET% Double-fault: Failed to restore previous directory junction!
                echo            Junction path:   !CURRENT_SYMLINK!
                echo            Previous target: !PREV_JUNCTION_TARGET!
                echo.
                echo            To restore manually, run:
                echo            %cCYAN%mklink /J "!CURRENT_SYMLINK!" "!PREV_JUNCTION_TARGET!"%cRESET%
                echo.
            )
        )
        call :ReleaseStateLock
        if defined CLI_COMMAND (
            set "JVM_EXIT_CODE=1"
            if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
            endlocal & exit /b 1
        )
        pause
        goto MAIN_LOOP
    )
    
    if exist "!CURRENT_SYMLINK!\bin\java.exe" (
        echo %cGREEN%[   OK   ]%cRESET% Junction successfully updated to point to !CURRENT_JDK_PATH!
    ) else (
        echo %cRED%[ ERROR  ]%cRESET% Failed to update Junction.
        rmdir "!CURRENT_SYMLINK!" >nul 2>&1
        if defined PREV_JUNCTION_TARGET if exist "!PREV_JUNCTION_TARGET!" mklink /J "!CURRENT_SYMLINK!" "!PREV_JUNCTION_TARGET!" >nul 2>&1
        if defined PREV_JUNCTION_TARGET (
            "%FSUTIL_BIN%" reparsepoint query "!CURRENT_SYMLINK!" >nul 2>&1
            if errorlevel 1 (
                echo.
                echo %cRED%[CRITICAL]%cRESET% Double-fault: Failed to restore previous directory junction!
                echo            Junction path:   !CURRENT_SYMLINK!
                echo            Previous target: !PREV_JUNCTION_TARGET!
                echo.
                echo            To restore manually, run:
                echo            %cCYAN%mklink /J "!CURRENT_SYMLINK!" "!PREV_JUNCTION_TARGET!"%cRESET%
                echo.
            )
        )
        call :ReleaseStateLock
        if defined CLI_COMMAND (
            set "JVM_EXIT_CODE=1"
            if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
            endlocal & exit /b 1
        )
        pause
        goto MAIN_LOOP
    )
    
    call :EmitSessionEnv RESET
    call :EmitSessionEnv "!CURRENT_SYMLINK!"
    
    rem Ensure JAVA_HOME permanently points to the junction in the USER registry (bypasses UAC)
    set "REG_JAVA_HOME="
    for /f "tokens=2*" %%A in ('%REG_BIN% query "HKCU\Environment" /v JAVA_HOME 2^>nul') do set "REG_JAVA_HOME=%%B"
    if /i not "!REG_JAVA_HOME!"=="!CURRENT_SYMLINK!" (
        echo.
        echo %cBLUE%[  INFO  ]%cRESET% Setting JAVA_HOME to: !CURRENT_SYMLINK!
        "%PS_BIN%" -NoProfile -Command "[Environment]::SetEnvironmentVariable('JAVA_HOME', $env:CURRENT_SYMLINK, 'User')"
        if errorlevel 1 (
            echo %cRED%[ ERROR  ]%cRESET% Failed to set JAVA_HOME in registry
            rmdir "!CURRENT_SYMLINK!" >nul 2>&1
            if defined PREV_JUNCTION_TARGET if exist "!PREV_JUNCTION_TARGET!" mklink /J "!CURRENT_SYMLINK!" "!PREV_JUNCTION_TARGET!" >nul 2>&1
            if defined PREV_JUNCTION_TARGET (
                "%FSUTIL_BIN%" reparsepoint query "!CURRENT_SYMLINK!" >nul 2>&1
                if errorlevel 1 (
                    echo.
                    echo %cRED%[CRITICAL]%cRESET% Double-fault: Failed to restore previous directory junction!
                    echo            Junction path:   !CURRENT_SYMLINK!
                    echo            Previous target: !PREV_JUNCTION_TARGET!
                    echo.
                    echo            To restore manually, run:
                    echo            %cCYAN%mklink /J "!CURRENT_SYMLINK!" "!PREV_JUNCTION_TARGET!"%cRESET%
                    echo.
                )
            )
            call :ReleaseStateLock
            if defined CLI_COMMAND (
                set "JVM_EXIT_CODE=1"
                if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
                endlocal & exit /b 1
            )
            pause
            goto MAIN_LOOP
        )
        echo %cGREEN%[   OK   ]%cRESET% JAVA_HOME set successfully via Symlink Mode.
    )
    
    set "SYMLINK_OR_DIRECT=%CURRENT_SYMLINK%"
)

rem Ensure system PATH permanently uses %JAVA_HOME%\bin
echo.
echo %cBLUE%[ ACTION ]%cRESET% Ensuring system PATH uses %%JAVA_HOME%%\bin...
call :UpdateSystemPath
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to update system PATH configuration.
    if /i "!SWITCH_MODE!" NEQ "DIRECT" (
        if defined PREV_JUNCTION_TARGET (
            rmdir "%CURRENT_SYMLINK%" >nul 2>&1
            mklink /J "%CURRENT_SYMLINK%" "!PREV_JUNCTION_TARGET!" >nul 2>&1
            "%FSUTIL_BIN%" reparsepoint query "%CURRENT_SYMLINK%" >nul 2>&1
            if errorlevel 1 (
                echo.
                echo %cRED%[CRITICAL]%cRESET% Double-fault: Failed to restore previous directory junction!
                echo            Junction path:   %CURRENT_SYMLINK%
                echo            Previous target: !PREV_JUNCTION_TARGET!
                echo.
                echo            To restore manually, run:
                echo            %cCYAN%mklink /J "%CURRENT_SYMLINK%" "!PREV_JUNCTION_TARGET!"%cRESET%
                echo.
            )
        )
    )
    call :ReleaseStateLock
    if defined CLI_COMMAND (
        endlocal & set "CMD_EXIT_CODE=1" & exit /b 1
    )
    pause
    goto MAIN_LOOP
)
call :ReleaseStateLock

rem Clean the current session PATH dynamically to prevent duplicates
setlocal enabledelayedexpansion
set "CLEAN_PATH=!PATH!"

rem Use PowerShell to safely filter out old Java paths via exact string matching to prevent accidental substring pollution
    set "PS_CMD=$p = $env:PATH -split ';'; $r = @(); foreach ($d in $p) { if ($d -ne '' -and (-not $env:JAVA_HOME -or $d -ne ($env:JAVA_HOME + '\bin')) -and (-not $env:SYMLINK_OR_DIRECT -or $d -ne ($env:SYMLINK_OR_DIRECT + '\bin')) -and (-not $env:CURRENT_JDK_PATH -or $d -ne ($env:CURRENT_JDK_PATH + '\bin'))) { $r += $d } }; $r -join ';'"
    for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "!PS_CMD!"') do set "CLEAN_PATH=%%A"

rem Export the clean path back to the main session and apply at the front
for /f "delims=" %%A in ("!CLEAN_PATH!") do (
    endlocal & set "PATH=%SYMLINK_OR_DIRECT%\bin;%%~A"
)

rem Finally update the local JAVA_HOME
set "JAVA_HOME=%SYMLINK_OR_DIRECT%"


:VERIFICATION
rem Verify the changes
echo.
echo ============================================================
echo                     VERIFICATION
echo ============================================================
echo.
echo %cBLUE%[  INFO  ]%cRESET% JAVA_HOME is now set to:
echo %JAVA_HOME%
echo.
echo %cBLUE%[ ACTION ]%cRESET% Testing Java command...
echo ------------------------------------------------------------
if exist "%JAVA_HOME%\bin\java.exe" (
    for /f "delims=" %%A in ('"%JAVA_HOME%\bin\java.exe" -version 2^>^&1') do echo %%A
    echo.
    echo %cGREEN%[   OK   ]%cRESET% Java is working correctly.
) else (
    echo %cYELLOW%[ WARNING]%cRESET% Target java.exe not found in JAVA_HOME\bin.
)
echo.
if "%SESSION_MODE%"=="1" (
    echo %cBLUE%[  INFO  ]%cRESET% Session PATH has been updated with %%JAVA_HOME%%\bin.
    echo            This change is temporary for this terminal only.
) else (
    if /i "!SWITCH_MODE!"=="DIRECT" (
        echo %cBLUE%[  INFO  ]%cRESET% System PATH has been updated in the Machine registry.
        echo            Open a new terminal for non-hooked applications to refresh environment.
    ) else (
        echo %cBLUE%[  INFO  ]%cRESET% Active JDK switched via Directory Junction.
        echo            Changes take effect immediately across all terminals.
    )
)
echo.
echo ============================================================

echo.
if "%SILENT_MODE%"=="1" (
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    exit /b 0
)
echo Press any key to return to the menu...
pause >nul
goto MAIN_LOOP


rem ============================================================
rem FUNCTIONS
rem ============================================================

rem Function to dynamically scan and display menu
:ShowDynamicMenu
setlocal enabledelayedexpansion

:RESCAN_MENU
set "NEEDS_RESCAN=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\channel.txt" (
    for /f "usebackq tokens=* delims= " %%A in ("%LOCALAPPDATA%\DiamTek\JVM\channel.txt") do set "UPDATE_CHANNEL=%%A"
)
if /i not "!UPDATE_CHANNEL!"=="NIGHTLY" set "UPDATE_CHANNEL=STABLE"
if defined UPDATE_CHANNEL_OVERRIDE (
    if /i "!UPDATE_CHANNEL_OVERRIDE!"=="NIGHTLY" (
        set "UPDATE_CHANNEL=NIGHTLY"
    ) else (
        set "UPDATE_CHANNEL=STABLE"
    )
)
if exist "%LOCALAPPDATA%\DiamTek\JVM\mode.txt" (
    for /f "usebackq tokens=* delims= " %%A in ("%LOCALAPPDATA%\DiamTek\JVM\mode.txt") do set "SWITCH_MODE=%%A"
)
if /i not "!SWITCH_MODE!"=="DIRECT" set "SWITCH_MODE=SYMLINK"
if not defined INITIAL_SESSION_JH (
    if defined JAVA_HOME set "INITIAL_SESSION_JH=!JAVA_HOME!"
)
set "JAVA_HOME="
for /f "tokens=2*" %%A in ('%REG_BIN% query "HKCU\Environment" /v JAVA_HOME 2^>nul') do set "JAVA_HOME=%%B"
if not defined JAVA_HOME (
    for /f "tokens=2*" %%A in ('%REG_BIN% query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v JAVA_HOME 2^>nul') do set "JAVA_HOME=%%B"
)
if defined INITIAL_SESSION_JH (
    set "CLEAN_SESS_JH=!INITIAL_SESSION_JH:"=!"
    if exist "!CLEAN_SESS_JH!\bin\java.exe" set "JAVA_HOME=!CLEAN_SESS_JH!"
)
if "!SKIP_HEADER!"=="0" (
    rem cls
    echo ============================================================
    echo                     Java Version Manager
    echo ============================================================
    echo.

    rem Display current Java info HERE so it survives the 'rem cls'
    if not defined JAVA_HOME (
        echo %cBLUE%[  INFO  ]%cRESET% JAVA_HOME is not currently set.
    ) else (
        echo %cBLUE%[  INFO  ]%cRESET% Current JAVA_HOME: !JAVA_HOME!
    )
    echo.

    echo Current Java information:
    echo ============================================================
    set "DISCOVERED_JAVA="
    for /f "delims=" %%A in ('%WHERE_BIN% $PATH:java 2^>nul') do (
        if not defined DISCOVERED_JAVA set "DISCOVERED_JAVA=%%A"
    )
    if not defined DISCOVERED_JAVA (
        echo %cYELLOW%[ WARNING]%cRESET% Java is NOT in PATH or not installed
        echo %cBLUE%[  INFO  ]%cRESET% This is normal if Java was just removed from PATH
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% Java is in PATH: !DISCOVERED_JAVA!
        echo.
        for /f "delims=" %%A in ('"!DISCOVERED_JAVA!" -version 2^>^&1') do echo %%A
    )
    echo ============================================================
    echo.
)

rem Resolve the true underlying path of JAVA_HOME if it is currently using the symlink mode
set "RESOLVED_JAVA_HOME=!JAVA_HOME!"
if /i "!JAVA_HOME!"=="%LOCALAPPDATA%\DiamTek\JVM\current" (
    for /f "tokens=2 delims=[]" %%A in ('dir /al "%LOCALAPPDATA%\DiamTek\JVM" 2^>nul ^| %FINDSTR_BIN% /i "current"') do (
        set "RESOLVED_JAVA_HOME=%%A"
    )
)
rem Strip trailing backslash just in case to ensure perfect path matching
if defined RESOLVED_JAVA_HOME (
    if "!RESOLVED_JAVA_HOME:~-1!"=="\" set "RESOLVED_JAVA_HOME=!RESOLVED_JAVA_HOME:~0,-1!"
)

set JDK_COUNT=0
set "LATEST_VER_NUM=0"
set "LATEST_LTS_NUM=0"
set "LATEST_JDK_PATH="
set "LATEST_JDK_NAME="
set "ORACLE_LATEST_FEATURE="
set "ORACLE_LATEST_LTS="

rem The LOCATIONS array is populated at the top of the script to prevent delayed expansion corruption

rem Find all JDK folders
for /l %%i in (0,1,!MAX_LOC!) do (
    if exist "!LOCATIONS[%%i]!" (
        pushd "!LOCATIONS[%%i]!" 2>nul
        if not errorlevel 1 (
            for /d %%j in (*) do (
                if exist "%%j\bin\java.exe" (
                    if exist "!LOCATIONS[%%i]!\current" (
                        if /i "%%j" NEQ "current" (
                            set "SKIP=1"
                        ) else (
                            set "SKIP=0"
                        )
                    ) else (
                        set "SKIP=0"
                    )
                    call :ValidateStrictIdentifier "%%j"
                    if errorlevel 1 set "SKIP=1"
                    if /i "%%j"=="current" (
                        for %%D in ("!LOCATIONS[%%i]!") do (
                            call :ValidateStrictIdentifier "%%~nxD"
                            if errorlevel 1 set "SKIP=1"
                        )
                    )
                    
                    if "!SKIP!"=="0" (
                        set /a JDK_COUNT+=1
                        set "JDK_PATH_!JDK_COUNT!=!LOCATIONS[%%i]!\%%j"
                        
                        rem Parse version to find the latest
                        set "VER="
                        set "VER_STR="
                        set "VENDOR_STR=Unknown"
                        if exist "%%j\release" (
                            for /f "tokens=2 delims==" %%R in ('%FINDSTR_BIN% /b "JAVA_VERSION=" "%%j\release" 2^>nul') do (
                                set "VER_STR=%%~R"
                                for /f "tokens=1 delims=." %%V in ("!VER_STR!") do set "VER=%%V"
                            )
                            for /f "tokens=2 delims==" %%R in ('%FINDSTR_BIN% /b "IMPLEMENTOR=" "%%j\release" 2^>nul') do (
                                set "VENDOR_RAW=%%~R"
                                set "VENDOR_RAW=!VENDOR_RAW:"=!"
                                if /i not "!VENDOR_RAW:Oracle=!"=="!VENDOR_RAW!" set "VENDOR_STR=Oracle"
                                if /i not "!VENDOR_RAW:Adoptium=!"=="!VENDOR_RAW!" set "VENDOR_STR=Adoptium"
                                if /i not "!VENDOR_RAW:GraalVM=!"=="!VENDOR_RAW!" set "VENDOR_STR=GraalVM"
                                if /i not "!VENDOR_RAW:Amazon=!"=="!VENDOR_RAW!" set "VENDOR_STR=Corretto"
                                if /i not "!VENDOR_RAW:Azul=!"=="!VENDOR_RAW!" set "VENDOR_STR=Zulu"
                                if /i not "!VENDOR_RAW:Microsoft=!"=="!VENDOR_RAW!" set "VENDOR_STR=Microsoft"
                                if /i not "!VENDOR_RAW:BellSoft=!"=="!VENDOR_RAW!" set "VENDOR_STR=Liberica"
                                if /i not "!VENDOR_RAW:Liberica=!"=="!VENDOR_RAW!" set "VENDOR_STR=Liberica"
                                if /i not "!VENDOR_RAW:IBM=!"=="!VENDOR_RAW!" set "VENDOR_STR=Semeru"
                                if /i not "!VENDOR_RAW:Semeru=!"=="!VENDOR_RAW!" set "VENDOR_STR=Semeru"
                                if /i not "!VENDOR_RAW:SAP=!"=="!VENDOR_RAW!" set "VENDOR_STR=SapMachine"
                                if /i not "!VENDOR_RAW:SapMachine=!"=="!VENDOR_RAW!" set "VENDOR_STR=SapMachine"
                                if /i not "!VENDOR_RAW:Mandrel=!"=="!VENDOR_RAW!" set "VENDOR_STR=Mandrel"
                                if /i not "!VENDOR_RAW:Red Hat=!"=="!VENDOR_RAW!" set "VENDOR_STR=Mandrel"
                                if /i not "!VENDOR_RAW:Alibaba=!"=="!VENDOR_RAW!" set "VENDOR_STR=Dragonwell"
                                if /i not "!VENDOR_RAW:Dragonwell=!"=="!VENDOR_RAW!" set "VENDOR_STR=Dragonwell"
                                if /i not "!VENDOR_RAW:Tencent=!"=="!VENDOR_RAW!" set "VENDOR_STR=Kona"
                                if /i not "!VENDOR_RAW:Kona=!"=="!VENDOR_RAW!" set "VENDOR_STR=Kona"
                                set "CURR_DIR_NAME=%%j"
                                if /i not "!CURR_DIR_NAME:mandrel=!"=="!CURR_DIR_NAME!" set "VENDOR_STR=Mandrel"
                            )
                        )
                        if not defined VER (
                            for /f "tokens=3" %%A in ('""%%j\bin\java.exe" -version 2^>^&1 ^| %FINDSTR_BIN% /i "version""') do (
                                set "VER_STR=%%~A"
                                set "VER_STR=!VER_STR:"=!"
                            )
                        )
                        rem Handle legacy 1.x versioning (e.g., 1.8.0 -> 8) safely without set /a expression evaluation (CWE-78/CWE-94)
                        set "NUM_VER=0"
                        if not defined VER_STR (
                            rem Fallback: extract version candidate from folder name (e.g., jdk-21.0.12.1+1, jdk-26.0.2.10)
                            set "DIR_VER=%%j"
                            if /i "!DIR_VER:~0,4!"=="jdk-" set "DIR_VER=!DIR_VER:~4!"
                            if /i "!DIR_VER:~0,5!"=="java-" set "DIR_VER=!DIR_VER:~5!"
                            if /i "!DIR_VER:~0,4!"=="jdk_" set "DIR_VER=!DIR_VER:~4!"
                            set "VER_STR=!DIR_VER!"
                        )
                        if defined VER_STR (
                            set "VER_STR=!VER_STR:"=!"
                            set "RAW_MAJOR="
                            for /f "tokens=1,2 delims=._+-" %%V in ("!VER_STR!") do (
                                if "%%V"=="1" (
                                    set "RAW_MAJOR=%%W"
                                ) else (
                                    set "RAW_MAJOR=%%V"
                                )
                            )
                            if defined RAW_MAJOR (
                                set "MAJOR_BAD="
                                if not "!RAW_MAJOR!"=="!RAW_MAJOR:;=!" set "MAJOR_BAD=1"
                                if not "!RAW_MAJOR!"=="!RAW_MAJOR:,=!" set "MAJOR_BAD=1"
                                for /f "eol= delims=0123456789" %%D in ("!RAW_MAJOR!") do set "MAJOR_BAD=1"
                                if not defined MAJOR_BAD (
                                    set /a "NUM_VER=!RAW_MAJOR!" 2>nul
                                )
                            )
                        )
                        
                        if "%%i"=="5" (
                            if "!VENDOR_STR!"=="Unknown" set "VENDOR_STR=Custom"
                        )
                        set "JDK_VENDOR_!JDK_COUNT!=!VENDOR_STR!"
                        
                        if /i "%%j"=="current" (
                            for %%D in ("!LOCATIONS[%%i]!") do set "APP_NAME=%%~nxD"
                            set "JDK_NAME_!JDK_COUNT!=Scoop !APP_NAME! (!NUM_VER!)"
                            set "LATEST_JDK_NAME_CANDIDATE=Scoop !APP_NAME!"
                        ) else (
                            set "JDK_NAME_!JDK_COUNT!=%%j"
                            set "LATEST_JDK_NAME_CANDIDATE=%%j"
                        )
                        
                        rem Store the major version specifically for the menu display
                        set "JDK_MAJOR_!JDK_COUNT!=!NUM_VER!"
                        
                        if !NUM_VER! GTR !LATEST_VER_NUM! (
                            set "LATEST_VER_NUM=!NUM_VER!"
                            set "LATEST_JDK_PATH=!LOCATIONS[%%i]!\%%j"
                            set "LATEST_JDK_NAME=!LATEST_JDK_NAME_CANDIDATE!"
                        )
                        
                        rem Track highest LTS version
                        if !NUM_VER!==8 set "IS_LTS=1"
                        if !NUM_VER!==11 set "IS_LTS=1"
                        if !NUM_VER!==17 set "IS_LTS=1"
                        if !NUM_VER!==21 set "IS_LTS=1"
                        if !NUM_VER!==25 set "IS_LTS=1"
                        if !NUM_VER!==29 set "IS_LTS=1"
                        
                        if defined IS_LTS (
                            if !NUM_VER! GTR !LATEST_LTS_NUM! (
                                set "LATEST_LTS_NUM=!NUM_VER!"
                            )
                        )
                        set "IS_LTS="
                    )
                )
            )
            popd
        )
    )
)

rem Sort JDKs by major version (descending)
if !JDK_COUNT! GTR 1 (
    for /l %%i in (1,1,!JDK_COUNT!) do (
        for /l %%j in (1,1,!JDK_COUNT!) do (
            if %%j GTR %%i (
                if !JDK_MAJOR_%%j! GTR !JDK_MAJOR_%%i! (
                    set "TEMP_PATH=!JDK_PATH_%%i!"
                    set "TEMP_MAJOR=!JDK_MAJOR_%%i!"
                    set "TEMP_NAME=!JDK_NAME_%%i!"
                    set "TEMP_VENDOR=!JDK_VENDOR_%%i!"
                    
                    set "JDK_PATH_%%i=!JDK_PATH_%%j!"
                    set "JDK_MAJOR_%%i=!JDK_MAJOR_%%j!"
                    set "JDK_NAME_%%i=!JDK_NAME_%%j!"
                    set "JDK_VENDOR_%%i=!JDK_VENDOR_%%j!"
                    
                    set "JDK_PATH_%%j=!TEMP_PATH!"
                    set "JDK_MAJOR_%%j=!TEMP_MAJOR!"
                    set "JDK_NAME_%%j=!TEMP_NAME!"
                    set "JDK_VENDOR_%%j=!TEMP_VENDOR!"
                )
            )
        )
    )
)

if /i not "!TARGET_CANDIDATE!"=="java" (
    call :RouteEcosystemCandidate
    set "CMD_EXIT_CODE=!errorlevel!"
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
    exit /b !CMD_EXIT_CODE!
)

if defined CLI_COMMAND (
    if /i "!CLI_COMMAND!"=="list" (
        if "!OUTPUT_JSON!"=="1" (
            call :ListJdksJson
            goto :eof
        )
        echo. 
        echo %cBLUE%[  INFO  ]%cRESET% Installed JDKs:
        echo ============================================================
        for /l %%k in (1,1,!JDK_COUNT!) do (
            set "ACTIVE_TAG="
            if /i "!JDK_PATH_%%k!"=="!RESOLVED_JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
            echo  %%k. JDK !JDK_MAJOR_%%k! ^(!JDK_NAME_%%k!^) - !JDK_VENDOR_%%k!!ACTIVE_TAG!
            echo     Path: !JDK_PATH_%%k!
            echo.
        )
        echo ============================================================
        call :ListEcosystemCandidates
        goto :eof
    )
    if /i "!CLI_COMMAND!"=="env" (
        call :ShowCurrentStatus
        goto :eof
    )
    if /i "!CLI_COMMAND!"=="current" (
        call :ShowCurrentStatus
        goto :eof
    )
    if /i "!CLI_COMMAND!"=="status" (
        call :ShowCurrentStatus
        goto :eof
    )
    if /i "!CLI_COMMAND!"=="clean" (
        call :CleanCache
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :CLI_DONE
    )
    if /i "!CLI_COMMAND!"=="which" (
        call :WhichBinary
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :CLI_DONE
    )
    if /i "!CLI_COMMAND!"=="doctor" (
        call :DoctorDiagnostics
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :CLI_DONE
    )
    if /i "!CLI_COMMAND!"=="open" (
        call :OpenFolderInExplorer
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :CLI_DONE
    )
    if /i "!CLI_COMMAND!"=="exec" (
        call :ExecuteEphemeralCommand
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :CLI_DONE
    )
    if /i "!CLI_COMMAND!"=="hook" (
        if /i "!CLI_TARGET!"=="remove" (
            call :RemovePowerShellHook
        ) else if /i "!CLI_TARGET!"=="uninstall" (
            call :RemovePowerShellHook
        ) else if /i "!CLI_TARGET!"=="status" (
            call :CheckPowerShellHookStatus
        ) else if /i "!CLI_TARGET!"=="check" (
            call :CheckPowerShellHookStatus
        ) else (
            call :InstallPowerShellHook
        )
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :CLI_DONE
    )
    if /i "!CLI_COMMAND!"=="install" (
        if "!FLAG_LOCKED!"=="1" (
            call :ExecuteLockedInstall
            set "CMD_EXIT_CODE=!errorlevel!"
            goto :CLI_DONE
        )
        if not defined CLI_TARGET (
            call :FetchLatestVersions
            call :InstallWizard
            goto :CLI_DONE
        )
        if /i "!CLI_TARGET!"=="latest" (
            call :FetchLatestVersions
            set "CLI_TARGET=!ORACLE_LATEST_FEATURE!"
        ) else if /i "!CLI_TARGET!"=="lts" (
            call :FetchLatestVersions
            if defined FLAG_LATEST (
                set "CLI_TARGET=!ORACLE_LATEST_LTS!"
            ) else (
                call :PromptLtsVersion
                if not defined CLI_TARGET goto :CLI_DONE
            )
        )
        set "DL_VERSION=!CLI_TARGET!"
        call :DownloadJDK_Headless
        if errorlevel 1 set "JVM_EXIT_CODE=1"
        goto :CLI_DONE
    )
    
    if /i "!CLI_TARGET!"=="latest" (
        if !LATEST_VER_NUM! GTR 0 set "CLI_TARGET=!LATEST_VER_NUM!"
    ) else if /i "!CLI_TARGET!"=="lts" (
        if !LATEST_LTS_NUM! GTR 0 set "CLI_TARGET=!LATEST_LTS_NUM!"
    )
    
    set "TARGET_IDX=0"
    set "MATCH_COUNT=0"
    if defined CLI_TARGET (
        if /i "!CLI_TARGET!" NEQ "--all" (
            for /l %%k in (1,1,!JDK_COUNT!) do (
                set "MATCH_FOUND=0"
                if "!JDK_MAJOR_%%k!"=="!CLI_TARGET!" set "MATCH_FOUND=1"
                if /i "!JDK_NAME_%%k!"=="!CLI_TARGET!" set "MATCH_FOUND=1"
                if "!MATCH_FOUND!"=="1" (
                    if defined CLI_VENDOR (
                        if /i "!JDK_VENDOR_%%k!" NEQ "!CLI_VENDOR!" set "MATCH_FOUND=0"
                    )
                )
                if "!MATCH_FOUND!"=="1" (
                    set /a MATCH_COUNT+=1
                    if "!TARGET_IDX!"=="0" set "TARGET_IDX=%%k"
                )
            )
        )
    )
    
    if /i "!CLI_COMMAND!"=="update" (
        call :RequireNetwork
        if errorlevel 1 (
            set "JVM_EXIT_CODE=1"
            goto :CLI_DONE
        )
        if /i not "!TARGET_CANDIDATE!"=="java" (
            set "act_ver=none"
            set "QUERY_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!\current"
            if exist "!QUERY_PATH!" (
                for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath $env:QUERY_PATH -ErrorAction SilentlyContinue).Target" 2^>nul') do for %%X in ("%%A") do set "act_ver=%%~nxX"
                call :ValidateStrictIdentifier "!act_ver!" act_ver
                if errorlevel 1 set "act_ver=none"
            )
            call :EcoPerformCheck !TARGET_CANDIDATE! "!act_ver!"
            goto :CLI_DONE
        )
        set "IS_ECO_CANDIDATE="
        for %%T in (maven gradle kotlin scala groovy ant sbt jbang quarkus spring micronaut mn) do (
            if /i "!CLI_TARGET!"=="%%T" (
                set "IS_ECO_CANDIDATE=%%T"
                if /i "%%T"=="mn" set "IS_ECO_CANDIDATE=micronaut"
            )
        )
        if defined IS_ECO_CANDIDATE (
            set "act_ver=none"
            set "QUERY_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\!IS_ECO_CANDIDATE!\current"
            if exist "!QUERY_PATH!" (
                for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath $env:QUERY_PATH -ErrorAction SilentlyContinue).Target" 2^>nul') do for %%X in ("%%A") do set "act_ver=%%~nxX"
                call :ValidateStrictIdentifier "!act_ver!" act_ver
                if errorlevel 1 set "act_ver=none"
            )
            call :EcoPerformCheck !IS_ECO_CANDIDATE! "!act_ver!"
            goto :CLI_DONE
        )
        if not defined CLI_TARGET (
            if defined CLI_VENDOR (
                echo %cBLUE%[ ACTION ]%cRESET% Automatically updating all !CLI_VENDOR! JDKs...
                echo.
                for /l %%k in (1,1,!JDK_COUNT!) do (
                    if /i "!JDK_VENDOR_%%k!"=="!CLI_VENDOR!" call :ProcessSingleUpdate %%k
                )
                echo ------------------------------------------------------------
                echo.
                echo %cGREEN%[   OK   ]%cRESET% All updates applied successfully!
                echo.
            ) else (
                echo %cRED%[ ERROR  ]%cRESET% Missing required version argument.
                echo            Usage: jvm update ^<version_number^>
                echo            Usage: jvm update --all [--vendor ^<name^>]
                set "JVM_EXIT_CODE=1"
            )
        ) else if /i "!CLI_TARGET!"=="--all" (
            if defined CLI_VENDOR (
                echo %cBLUE%[ ACTION ]%cRESET% Automatically updating all !CLI_VENDOR! JDKs...
                echo.
                for /l %%k in (1,1,!JDK_COUNT!) do (
                    if /i "!JDK_VENDOR_%%k!"=="!CLI_VENDOR!" call :ProcessSingleUpdate %%k
                )
            ) else (
                echo %cBLUE%[ ACTION ]%cRESET% Automatically updating ALL JDKs and Ecosystem Tools...
                for /l %%k in (1,1,!JDK_COUNT!) do call :ProcessSingleUpdate %%k
                for %%T in (maven gradle kotlin scala groovy ant sbt jbang quarkus spring micronaut) do (
                    if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\%%T\current" (
                        set "act_ver=none"
                        set "QUERY_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\%%T\current"
                        for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath $env:QUERY_PATH -ErrorAction SilentlyContinue).Target" 2^>nul') do for %%X in ("%%A") do set "act_ver=%%~nxX"
                        call :ValidateStrictIdentifier "!act_ver!" act_ver
                        if errorlevel 1 set "act_ver=none"
                        call :EcoPerformCheck %%T "!act_ver!"
                    )
                )
            )
            echo ------------------------------------------------------------
            echo.
            echo %cGREEN%[   OK   ]%cRESET% All updates applied successfully!
            echo.
        ) else (
            if "!TARGET_IDX!"=="0" (
                echo %cRED%[ ERROR  ]%cRESET% JDK !CLI_TARGET! not found.
                set "JVM_EXIT_CODE=1"
            ) else (
                call :ProcessSingleUpdate !TARGET_IDX!
                set "JVM_EXIT_CODE=!errorlevel!"
            )
        )
        goto :CLI_DONE
    )
    
    if /i "!CLI_COMMAND!"=="uninstall" (
        if not defined CLI_TARGET (
            echo.
            echo %cBLUE%[ ACTION ]%cRESET% Select JDK to uninstall:
            echo ============================================================
            set "RESOLVE_COUNT=0"
            for /l %%k in (1,1,!JDK_COUNT!) do (
                set "SHOW_JDK=1"
                if defined CLI_VENDOR (
                    if /i "!JDK_VENDOR_%%k!" NEQ "!CLI_VENDOR!" set "SHOW_JDK=0"
                )
                if "!SHOW_JDK!"=="1" (
                    set /a RESOLVE_COUNT+=1
                    set "RES_IDX_!RESOLVE_COUNT!=%%k"
                    set "ACTIVE_TAG="
                    if /i "!JDK_PATH_%%k!"=="!RESOLVED_JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
                    echo   !RESOLVE_COUNT!. JDK !JDK_MAJOR_%%k! ^(!JDK_NAME_%%k!^) - !JDK_VENDOR_%%k!!ACTIVE_TAG!
                    echo      Path: !JDK_PATH_%%k!
                )
            )
            echo ============================================================
            if !RESOLVE_COUNT! EQU 0 (
                if defined CLI_VENDOR (
                    echo %cYELLOW%[ WARNING]%cRESET% No installed !CLI_VENDOR! JDKs found to uninstall.
                ) else (
                    echo %cYELLOW%[ WARNING]%cRESET% No installed JDKs found to uninstall.
                )
                goto :CLI_DONE
            )
            set /a UNINST_CANCEL=RESOLVE_COUNT+1
            echo   !UNINST_CANCEL!. Cancel
            echo.
            if !UNINST_CANCEL! LEQ 9 (
                set "U_KEYS="
                for /l %%k in (1,1,!UNINST_CANCEL!) do set "U_KEYS=!U_KEYS!%%k"
                "%CHOICE_BIN%" /C !U_KEYS! /N /M "Select JDK to uninstall (1-!UNINST_CANCEL!): "
                set "UNINST_SEL=!errorlevel!"
                if !UNINST_SEL! EQU !UNINST_CANCEL! (
                    echo.
                    echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled.
                    goto :CLI_DONE
                )
                for %%C in (!UNINST_SEL!) do set "TARGET_IDX=!RES_IDX_%%C!"
            ) else (
                set "uninst_choice="
                set /p uninst_choice="Enter your choice (1-!UNINST_CANCEL!): "
::::::::::::::::::::
                  if not defined uninst_choice (
                      echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled.
                      goto :CLI_DONE
                  )
                  set "uninst_choice=!uninst_choice:"=!"
                  set "uninst_choice=!uninst_choice: =!"
                  if /i "!uninst_choice!"=="cancel" (
                      echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled.
                      goto :CLI_DONE
                  )
                  if /i "!uninst_choice!"=="c" (
                      echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled.
                      goto :CLI_DONE
                  )
                  if /i "!uninst_choice!"=="q" (
                      echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled.
                      goto :CLI_DONE
                  )
                  if "!uninst_choice!"=="" (
                      echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled.
                      goto :CLI_DONE
                  )
                  set "NUM_TEST="
                  if not "!uninst_choice!"=="!uninst_choice:;=!" set "NUM_TEST=;"
                  for /f "eol= delims=0123456789" %%A in ("!uninst_choice!") do set "NUM_TEST=%%A"
                  if defined NUM_TEST (
                      echo %cRED%[ ERROR  ]%cRESET% Invalid selection.
                      set "JVM_EXIT_CODE=1"
                      goto :CLI_DONE
                  )
                  if !uninst_choice! LSS 1 (
                      echo %cRED%[ ERROR  ]%cRESET% Invalid selection.
                      set "JVM_EXIT_CODE=1"
                      goto :CLI_DONE
                  )
                  if !uninst_choice! EQU !UNINST_CANCEL! (
                      echo.
                      echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled.
                      goto :CLI_DONE
                  )
                  if !uninst_choice! GTR !UNINST_CANCEL! (
                      echo %cRED%[ ERROR  ]%cRESET% Invalid selection.
                      set "JVM_EXIT_CODE=1"
                      goto :CLI_DONE
                  )
                  for %%C in (!uninst_choice!) do set "TARGET_IDX=!RES_IDX_%%C!"
            )
        ) else if !MATCH_COUNT! GTR 1 (
            echo %cYELLOW%[ WARNING]%cRESET% Multiple JDKs found for '!CLI_TARGET!'.
            echo.
            set "RESOLVE_COUNT=0"
            for /l %%k in (1,1,!JDK_COUNT!) do (
                set "MATCH_FOUND=0"
                if "!JDK_MAJOR_%%k!"=="!CLI_TARGET!" set "MATCH_FOUND=1"
                if /i "!JDK_NAME_%%k!"=="!CLI_TARGET!" set "MATCH_FOUND=1"
                if "!MATCH_FOUND!"=="1" (
                    if defined CLI_VENDOR (
                        if /i "!JDK_VENDOR_%%k!" NEQ "!CLI_VENDOR!" set "MATCH_FOUND=0"
                    )
                )
                if "!MATCH_FOUND!"=="1" (
                    set /a RESOLVE_COUNT+=1
                    set "RES_IDX_!RESOLVE_COUNT!=%%k"
                    echo   !RESOLVE_COUNT!. !JDK_VENDOR_%%k!
                )
            )
            set /a RESOLVE_COUNT+=1
            echo   !RESOLVE_COUNT!. Cancel
            echo.
            
            set "U_KEYS="
            for /l %%k in (1,1,!RESOLVE_COUNT!) do set "U_KEYS=!U_KEYS!%%k"
            "%CHOICE_BIN%" /C !U_KEYS! /N /M "Select vendor to uninstall (1-!RESOLVE_COUNT!): "
            if !errorlevel! EQU !RESOLVE_COUNT! goto :eof
            
            set "CHOICE_VAL=!errorlevel!"
            for %%C in (!CHOICE_VAL!) do set "TARGET_IDX=!RES_IDX_%%C!"
            echo.
        )

        if "!TARGET_IDX!"=="0" (
            echo %cRED%[ ERROR  ]%cRESET% JDK !CLI_TARGET! not found.
            set "JVM_EXIT_CODE=1"
        ) else (
            for %%A in (!TARGET_IDX!) do (
                set "DEL_PATH=!JDK_PATH_%%A!"
                set "DEL_NAME=!JDK_NAME_%%A!"
            )
            
            if "!FORCE_YES!" NEQ "1" (
                echo.
                echo %cYELLOW%[ WARNING ]%cRESET% You are about to permanently delete:
                echo              !DEL_PATH!
                "%CHOICE_BIN%" /C yn /N /M "Are you sure you want to proceed? (y/N): "
                if !errorlevel! NEQ 1 (
                    echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled.
                    goto :eof
                )
            )

            echo.
            call :AcquireStateLock
            if errorlevel 1 (
                set "JVM_EXIT_CODE=1"
                goto :CLI_DONE
            )
            echo %cBLUE%[ ACTION ]%cRESET% Terminating any active Java processes...
            echo %cBLUE%[ ACTION ]%cRESET% Deleting directory !DEL_PATH!...
            echo %cBLUE%[ ACTION ]%cRESET% Scrubbing environment variables...
            echo %cBLUE%[  INFO  ]%cRESET% Requesting administrative privileges to apply changes...
            "%PS_BIN%" -NoProfile -Command "$del = $env:DEL_PATH; $b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($del)); $script = '$del = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''' + $b64 + ''')); Get-Process java,javaw -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($del, [StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force -ErrorAction SilentlyContinue; if (Test-Path -LiteralPath $del) { $it = Get-Item -LiteralPath $del -Force -ErrorAction SilentlyContinue; if ($it -and (($it.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)) { [System.IO.Directory]::Delete($it.FullName, $false) } else { Get-ChildItem -LiteralPath $del -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 } | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object { if ($_.PSIsContainer) { [System.IO.Directory]::Delete($_.FullName, $false) } else { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue } }; Remove-Item -LiteralPath $del -Recurse -Force -ErrorAction SilentlyContinue } }; $delBin = Join-Path $del ''bin''; $p = [Environment]::GetEnvironmentVariable(''Path'', ''Machine''); if ($p) { $clean = ($p -split '';'' | Where-Object { $_ -and $_.TrimEnd(''\'') -ne $delBin.TrimEnd(''\'') }) -join '';''; Set-ItemProperty -Path ''HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'' -Name ''Path'' -Value $clean -Type ExpandString }'; $enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($script)); $s = [Environment]::GetFolderPath([Environment+SpecialFolder]::System); $ps = Join-Path $s 'WindowsPowerShell\v1.0\powershell.exe'; try { $p = Start-Process -FilePath $ps -Verb RunAs -WorkingDirectory $s -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-EncodedCommand', $enc); try { if ($p.ExitCode -ne 0) { exit $p.ExitCode } } finally { if ($null -ne $p) { $p.Dispose() } } } catch { exit 1 }" 2>nul
            if errorlevel 1 (
                echo %cRED%[ ERROR  ]%cRESET% Administrator elevation was declined or uninstallation failed.
                call :ReleaseStateLock
                set "JVM_EXIT_CODE=1"
                goto :CLI_DONE
            )
            
            rem Clean User PATH preserving REG_EXPAND_SZ
            set "DEL_BIN=!DEL_PATH!\bin"
            "%PS_BIN%" -NoProfile -Command "$delBin = $env:DEL_BIN; $p = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($p) { $clean = ($p -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ne $delBin.TrimEnd('\') }) -join ';'; Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $clean -Type ExpandString }" >nul 2>&1
            
            if not exist "%LOCALAPPDATA%\DiamTek\JVM\current\bin\java.exe" (
                rmdir "%LOCALAPPDATA%\DiamTek\JVM\current" >nul 2>&1
                "%REG_BIN%" delete "HKCU\Environment" /v JAVA_HOME /f >nul 2>&1
            )
            
            if exist "!DEL_PATH!" (
                echo %cRED%[ ERROR  ]%cRESET% Failed to completely delete directory.
                set "JVM_EXIT_CODE=1"
            ) else (
                echo.
                echo %cGREEN%[   OK   ]%cRESET% !DEL_NAME! was successfully uninstalled!
            )
            call :ReleaseStateLock
        )
        goto :CLI_DONE
    )

    if /i "!CLI_COMMAND!"=="clear" (
        if /i "!CLI_TARGET!"=="-y" set "FORCE_YES=1"
        if /i "!CLI_TARGET!"=="--yes" set "FORCE_YES=1"
        call :ClearJavaEnvironment
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :CLI_DONE
    )

    if /i "!CLI_COMMAND!"=="channel" (
        call :HandleChannelCommand !CLI_TARGET!
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :CLI_DONE
    )

    if /i "!CLI_COMMAND!"=="self-update" (
        if /i "!CLI_TARGET!"=="nightly" (
            set "UPDATE_CHANNEL=NIGHTLY"
            set "UPDATE_CHANNEL_OVERRIDE=NIGHTLY"
        )
        if /i "!CLI_TARGET!"=="stable" (
            set "UPDATE_CHANNEL=STABLE"
            set "UPDATE_CHANNEL_OVERRIDE=STABLE"
        )
        call :SelfUpdate
        if errorlevel 1 set "JVM_EXIT_CODE=1"
        goto :CLI_DONE
    )

    if /i "!CLI_COMMAND!"=="self-uninstall" (
        goto :UninstallJVM_Complete
    )
    
    if /i "!CLI_COMMAND!"=="version" (
        call :AboutMenu
        goto :eof
    )

    if /i "!CLI_COMMAND!"=="help" (
        call :ShowHelp
        goto :eof
    )
)

if defined CLI_TARGET (
    if "!CLI_TARGET!"=="SKIP_JAVA" goto :eof
    if not "!TARGET_CANDIDATE!"=="java" (
        call :RouteEcosystemCandidate
        set "CMD_EXIT_CODE=!errorlevel!"
        exit /b !errorlevel!
    )
    echo %cBLUE%[  INFO  ]%cRESET% Target JDK !CLI_TARGET! detected...
    rem Resolve Semantic Aliases
    if /i "!CLI_TARGET!"=="latest" (
        if !LATEST_VER_NUM! GTR 0 set "CLI_TARGET=!LATEST_VER_NUM!"
    ) else if /i "!CLI_TARGET!"=="lts" (
        if !LATEST_LTS_NUM! GTR 0 set "CLI_TARGET=!LATEST_LTS_NUM!"
    )
    
    for /l %%k in (1,1,!JDK_COUNT!) do (
        set "MATCH_FOUND=0"
        if "!JDK_MAJOR_%%k!"=="!CLI_TARGET!" set "MATCH_FOUND=1"
        if /i "!JDK_NAME_%%k!"=="!CLI_TARGET!" set "MATCH_FOUND=1"
        
        if "!MATCH_FOUND!"=="1" (
            if defined CLI_VENDOR (
                if /i "!JDK_VENDOR_%%k!" NEQ "!CLI_VENDOR!" (
                    set "MATCH_FOUND=0"
                )
            )
        )

        if "!MATCH_FOUND!"=="1" (
            echo.
            echo %cBLUE%[ ACTION ]%cRESET% Quick-Switching to JDK !JDK_NAME_%%k! ^(!JDK_MAJOR_%%k!^)...
            set "CURRENT_JDK_PATH=!JDK_PATH_%%k!"
            rem Return to MAIN_LOOP to apply the changes
            for /f "delims=" %%P in ("!CURRENT_JDK_PATH!") do (
                endlocal & set "CURRENT_JDK_PATH=%%~P"
            )
            goto :eof
        )
    )
    echo.
    echo %cRED%[ ERROR  ]%cRESET% JDK !CLI_TARGET! not found.
    echo            Please ensure it is installed and try again.
    if "!SILENT_MODE!"=="0" "%TIMEOUT_BIN%" /t 3 >nul
    set "JVM_EXIT_CODE=1"
    goto :CLI_DONE
)

:CLI_DONE
if defined JVM_EXIT_CODE (
    endlocal & set "CMD_EXIT_CODE=%JVM_EXIT_CODE%" & exit /b %JVM_EXIT_CODE%
)
if defined CMD_EXIT_CODE (
    endlocal & set "CMD_EXIT_CODE=%CMD_EXIT_CODE%" & exit /b %CMD_EXIT_CODE%
)
if "!SILENT_MODE!"=="1" (
    rem Safety catch: If we are hidden and CLI_TARGET was empty, abort so we don't hang!
    goto :eof
)

rem Show main menu
if defined JVM_NONINTERACTIVE exit /b 0
echo Please choose an option:
echo.
echo 1. JDK Management (Java)
echo 2. Ecosystem Management (Maven, Gradle, etc.)
echo 3. Settings (Global Command ^& Setup)
echo 4. Exit
echo.

"%CHOICE_BIN%" /C 1234 /N /M "Enter your choice (1-4): "
set "choice=!errorlevel!"

if !choice!==4 (
    echo.
    echo %cBLUE%[  INFO  ]%cRESET% Exiting Java Version Manager... ^(Press any key to cancel^)
    <nul set /p "=%cBLUE%[  INFO  ]%cRESET% "
    for %%i in (3 2 1) do (
        <nul set /p "=%%i... "
        "%CHOICE_BIN%" /C 123456789abcdefghijklmnopqrstuvwxyz0 /T 1 /D 0 /N >nul
        if !errorlevel! LSS 36 (
            echo.
            goto RESCAN_MENU
        )
    )
    echo.
    endlocal
    if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
    set "CURRENT_JDK_PATH="
    goto :eof
)

if !choice!==3 (
    call :SettingsMenu
    if errorlevel 100 (
        set "CMD_EXIT_CODE=0"
        goto :eof
    )
    if defined EXIT_JVM_ALL (
        set "CMD_EXIT_CODE=0"
        goto :eof
    )
    goto RESCAN_MENU
)

if !choice!==2 (
    call :EcosystemMenu
    goto RESCAN_MENU
)

if !choice!==1 (
    call :JdkMenu
    if defined CURRENT_JDK_PATH (
        for /f "delims=" %%P in ("!CURRENT_JDK_PATH!") do (
            endlocal & set "CURRENT_JDK_PATH=%%~P"
        )
        goto :eof
    )
    goto RESCAN_MENU
)

rem Catch-all to prevent falling through if choice errors out
goto RESCAN_MENU

:JdkMenu
echo.
echo ============================================================
echo                    JDK Management
echo ============================================================
echo Please choose an option:
echo.
echo 1. Switch Active JDK (Path ^& Environment)
echo 2. Version Management (Install, Update, Uninstall)
echo 3. Go back
echo.
"%CHOICE_BIN%" /C 123 /N /M "Enter your choice (1-3): "
set "jdk_main_choice=!errorlevel!"
if !jdk_main_choice!==3 goto :eof
if !jdk_main_choice!==1 (
    call :PathEnvironmentMenu
    if defined CURRENT_JDK_PATH goto :eof
    goto :JdkMenu
)
if !jdk_main_choice!==2 (
    call :VersionMenu
    if "!NEEDS_RESCAN!"=="1" goto :eof
    goto :JdkMenu
)
goto :JdkMenu

:EcosystemMenu
echo.
echo ============================================================
echo               Ecosystem Management
echo ============================================================
echo Please choose an option:
echo.
echo 1. Switch Active Tool (Path ^& Environment)
echo 2. Version Management (Install, Update, Uninstall)
echo 3. Go back
echo.
"%CHOICE_BIN%" /C 123 /N /M "Enter your choice (1-3): "
set "eco_main_choice=!errorlevel!"
if !eco_main_choice!==3 goto :eof
if !eco_main_choice!==1 (
    set "ECO_SUB_MODE=SWITCH"
    goto :EcosystemSelectTool
)
if !eco_main_choice!==2 goto :EcoVersionMenu
goto :EcosystemMenu

:EcoVersionMenu
echo.
echo ============================================================
echo                 Ecosystem Version Management
echo ============================================================
echo Please choose an option:
echo.
echo 1. Check for Updates for installed Tools
echo 2. Download and Install a new Tool version
echo 3. Uninstall a Tool and clean environment variables
echo 4. Go back
echo.
"%CHOICE_BIN%" /C 1234 /N /M "Enter your choice (1-4): "
set "sub_choice=!errorlevel!"
if !sub_choice!==4 goto :EcosystemMenu
if !sub_choice!==1 (
    call :UpdateEcosystemTools
    goto :EcoVersionMenu
)
if !sub_choice!==2 (
    set "ECO_SUB_MODE=INSTALL"
    goto :EcosystemSelectTool
)
if !sub_choice!==3 (
    set "ECO_SUB_MODE=UNINSTALL"
    goto :EcosystemSelectTool
)
goto :EcoVersionMenu

:UpdateEcosystemTools
echo.
echo ============================================================
echo               Ecosystem Tool Updater
echo ============================================================
echo.

rem Scan which tools are installed and their current versions
set /a EU_OPT=0
set "EU_OPT_ALL="
set /a ECO_UPDATE_SUCCESS=0
set /a ECO_UPDATE_ERRORS=0
set /a ECO_UPDATE_UPTODATE=0
set /a ECO_UPDATE_SKIPPED=0
for %%T in (maven gradle kotlin scala groovy ant sbt jbang quarkus spring micronaut) do (
    set "EU_OPT_%%T="
    set "EU_HAS_%%T=0"
    set "EU_ACTIVE_%%T="
)

for %%T in (maven gradle kotlin scala groovy ant sbt jbang quarkus spring micronaut) do (
    set "eu_cdir=%LOCALAPPDATA%\DiamTek\JVM\candidates\%%T"
    if exist "!eu_cdir!" (
        set "eu_has_ver=0"
        for /d %%V in ("!eu_cdir!\*") do if not "%%~nxV"=="current" set "eu_has_ver=1"
        if "!eu_has_ver!"=="1" (
            set "EU_HAS_%%T=1"
            rem Resolve active version from the current symlink
            set "EU_ACTIVE_%%T=none"
            set "ACTIVE_TARGET="
            for /f "tokens=1,2*" %%A in ('%FSUTIL_BIN% reparsepoint query "!eu_cdir!\current" 2^>nul ^| %FINDSTR_BIN% /i "Print Name:"') do set "ACTIVE_TARGET=%%C"
            if not defined ACTIVE_TARGET (
                set "QUERY_PATH=!eu_cdir!\current"
                for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath $env:QUERY_PATH -ErrorAction SilentlyContinue).Target" 2^>nul') do set "ACTIVE_TARGET=%%A"
            )
            if defined ACTIVE_TARGET (
                set "ACTIVE_TARGET=!ACTIVE_TARGET:\??\=!"
                set "ACTIVE_TARGET=!ACTIVE_TARGET:\\?\=!"
                for /f "tokens=*" %%A in ("!ACTIVE_TARGET!") do set "ACTIVE_TARGET=%%A"
                for %%X in ("!ACTIVE_TARGET!") do set "EU_ACTIVE_%%T=%%~nxX"
            )
        )
    )
)

rem Count installed tools and build menu
set "eu_any=0"
for %%T in (maven gradle kotlin scala groovy ant sbt jbang quarkus spring micronaut) do (
    if "!EU_HAS_%%T!"=="1" set "eu_any=1"
)

if "!eu_any!"=="0" (
    echo %cYELLOW%[ WARNING]%cRESET% No ecosystem tools are currently installed to update.
    pause
    goto :eof
)

echo %cBLUE%[ ACTION ]%cRESET% Select tool to check for updates:
echo.

set /a EU_OPT+=1
set "EU_OPT_ALL=!EU_OPT!"
echo !EU_OPT!. All Installed Tools
echo.

echo %cGRAY%--- Manage by Tool ---%cRESET%
if "!EU_HAS_maven!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_maven=!EU_OPT!"
    echo !EU_OPT!. Maven %cGRAY%[!EU_ACTIVE_maven!]%cRESET%
)
if "!EU_HAS_gradle!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_gradle=!EU_OPT!"
    echo !EU_OPT!. Gradle %cGRAY%[!EU_ACTIVE_gradle!]%cRESET%
)
if "!EU_HAS_kotlin!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_kotlin=!EU_OPT!"
    echo !EU_OPT!. Kotlin %cGRAY%[!EU_ACTIVE_kotlin!]%cRESET%
)
if "!EU_HAS_scala!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_scala=!EU_OPT!"
    echo !EU_OPT!. Scala %cGRAY%[!EU_ACTIVE_scala!]%cRESET%
)
if "!EU_HAS_groovy!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_groovy=!EU_OPT!"
    echo !EU_OPT!. Groovy %cGRAY%[!EU_ACTIVE_groovy!]%cRESET%
)
if "!EU_HAS_ant!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_ant=!EU_OPT!"
    echo !EU_OPT!. Ant %cGRAY%[!EU_ACTIVE_ant!]%cRESET%
)
if "!EU_HAS_sbt!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_sbt=!EU_OPT!"
    echo !EU_OPT!. SBT %cGRAY%[!EU_ACTIVE_sbt!]%cRESET%
)
if "!EU_HAS_jbang!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_jbang=!EU_OPT!"
    echo !EU_OPT!. JBang %cGRAY%[!EU_ACTIVE_jbang!]%cRESET%
)
if "!EU_HAS_quarkus!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_quarkus=!EU_OPT!"
    echo !EU_OPT!. Quarkus %cGRAY%[!EU_ACTIVE_quarkus!]%cRESET%
)
if "!EU_HAS_spring!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_spring=!EU_OPT!"
    echo !EU_OPT!. Spring Boot %cGRAY%[!EU_ACTIVE_spring!]%cRESET%
)
if "!EU_HAS_micronaut!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_micronaut=!EU_OPT!"
    echo !EU_OPT!. Micronaut %cGRAY%[!EU_ACTIVE_micronaut!]%cRESET%
)

echo.
echo %cGRAY%--- Actions ---%cRESET%
set /a EU_CANCEL=EU_OPT+1
echo !EU_CANCEL!. Go back
echo.

:GET_EU_CHOICE
if !EU_CANCEL! GTR 9 goto GET_EU_CHOICE_MANUAL
rem Build choice keys dynamically
set "EU_KEYS="
for /l %%i in (1,1,!EU_CANCEL!) do set "EU_KEYS=!EU_KEYS!%%i"
"%CHOICE_BIN%" /C !EU_KEYS! /N /M "Select tool (1-!EU_CANCEL!): "
set "eu_choice=!errorlevel!"
goto PROCESS_EU_CHOICE

:GET_EU_CHOICE_MANUAL
set "eu_choice="
set /p "eu_choice=Select tool (1-!EU_CANCEL!): "
if not defined eu_choice goto EcoVersionMenu
if "!eu_choice!"=="" goto EcoVersionMenu
set "eu_choice=!eu_choice:"=!"
set "eu_choice=!eu_choice: =!"
if "!eu_choice!"=="" goto GET_EU_CHOICE_MANUAL
set "NUM_TEST="
if not "!eu_choice!"=="!eu_choice:;=!" set "NUM_TEST=;"
for /f "eol= delims=0123456789" %%A in ("!eu_choice!") do set "NUM_TEST=%%A"
if defined NUM_TEST goto GET_EU_CHOICE_MANUAL
if !eu_choice! LSS 1 goto GET_EU_CHOICE_MANUAL
if !eu_choice! GTR !EU_CANCEL! goto GET_EU_CHOICE_MANUAL

:PROCESS_EU_CHOICE
if !eu_choice!==!EU_CANCEL! goto :eof

rem Determine which tools to check
for %%T in (maven gradle kotlin scala groovy ant sbt jbang quarkus spring micronaut) do (
    set "EU_CHECK_%%T=0"
)

if !eu_choice!==!EU_OPT_ALL! (
    for %%T in (maven gradle kotlin scala groovy ant sbt jbang quarkus spring micronaut) do (
        if "!EU_HAS_%%T!"=="1" set "EU_CHECK_%%T=1"
    )
)
for %%T in (maven gradle kotlin scala groovy ant sbt jbang quarkus spring micronaut) do (
    if defined EU_OPT_%%T if !eu_choice!==!EU_OPT_%%T! set "EU_CHECK_%%T=1"
)

rem Now run update checks for selected tools
for %%T in (maven gradle kotlin scala groovy ant sbt jbang quarkus spring micronaut) do (
    if "!EU_CHECK_%%T!"=="1" call :EcoPerformCheck %%T "!EU_ACTIVE_%%T!"
)
goto :EcoPerformCheck_End

:EcoPerformCheck
set "CAND_NAME=%~1"
call :ValidateStrictIdentifier "!CAND_NAME!" CAND_NAME
if errorlevel 1 exit /b 1
set "CHK_T=!CAND_NAME!"
set "CHK_ACT=%~2"
if not defined CHK_ACT set "CHK_ACT=none"
call :ValidateStrictIdentifier "!CHK_ACT!" CHK_ACT
if errorlevel 1 set "CHK_ACT=none"
set "TARGET_CANDIDATE=!CHK_T!"
set "c_dir=%LOCALAPPDATA%\DiamTek\JVM\candidates\!CHK_T!"
call :GetCandidateEnvVar
echo ------------------------------------------------------------
echo %cBLUE%[ ACTION ]%cRESET% Analyzing !CANDIDATE_PROPER_NAME!...
echo %cBLUE%[  INFO  ]%cRESET% Checking vendor API for updates...
echo %cBLUE%[  INFO  ]%cRESET% Active version: !CHK_ACT!

call :ResolveLatestEcosystemCandidate

if not "!LATEST_VER!"=="ERROR" (
    call :ValidateStrictIdentifier "!LATEST_VER!" LATEST_VER
    if errorlevel 1 set "LATEST_VER=ERROR"
    if /i "!LATEST_VER!"=="current" set "LATEST_VER=ERROR"
)

if "!LATEST_VER!"=="ERROR" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to resolve latest version for !CANDIDATE_PROPER_NAME!.
    set /a ECO_UPDATE_ERRORS+=1
) else (
    if exist "!c_dir!\!LATEST_VER!" (
        if /i "!CHK_ACT!"=="!LATEST_VER!" (
            echo %cGREEN%[   OK   ]%cRESET% !CANDIDATE_PROPER_NAME! is up to date ^(!LATEST_VER!^).
        ) else (
            echo %cBLUE%[  INFO  ]%cRESET% Latest version ^(!LATEST_VER!^) is installed, but active version is !CHK_ACT!.
            if not defined CLI_COMMAND (
                "%CHOICE_BIN%" /C YN /M "Do you want to switch active !CANDIDATE_PROPER_NAME! to !LATEST_VER!? "
                if !errorlevel!==1 (
                    echo.
                    echo %cBLUE%[ ACTION ]%cRESET% Activating !CANDIDATE_PROPER_NAME! !LATEST_VER!...
                    call :SwitchCandidate "!LATEST_VER!"
                )
            ) else (
                echo.
                echo %cBLUE%[ ACTION ]%cRESET% Activating latest installed !CANDIDATE_PROPER_NAME! !LATEST_VER!...
                call :SwitchCandidate "!LATEST_VER!"
                if not errorlevel 1 (
                    echo %cGREEN%[   OK   ]%cRESET% !CANDIDATE_PROPER_NAME! !LATEST_VER! is now active^^!
                ) else (
                    echo %cRED%[ ERROR  ]%cRESET% Failed to activate !CANDIDATE_PROPER_NAME! !LATEST_VER!.
                )
            )
        )
        set /a ECO_UPDATE_UPTODATE+=1
    ) else (
        echo %cYELLOW%[ UPDATE ]%cRESET% New version available: !LATEST_VER!
        if defined CLI_COMMAND (
            echo.
            set "CLI_TARGET=!LATEST_VER!"
            set "IS_UPDATER=1"
            call :InstallCandidate
            set "IS_UPDATER="
            if exist "!c_dir!\!LATEST_VER!" (
                call :SwitchCandidate "!LATEST_VER!"
                if not errorlevel 1 (
                    set /a ECO_UPDATE_SUCCESS+=1
                    for /d %%V in ("!c_dir!\*") do (
                        set "V_NAME=%%~nxV"
                        call :ValidateStrictIdentifier "!V_NAME!" V_NAME
                        if not errorlevel 1 (
                            if /i not "!V_NAME!"=="current" if /i not "!V_NAME!"=="!LATEST_VER!" (
                                set "OLD_CAND_DIR=%%~fV"
                                "%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -Command "$d = $env:OLD_CAND_DIR; if (Test-Path -LiteralPath $d) { Get-ChildItem -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint } | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object { if ($_.PSIsContainer) { [System.IO.Directory]::Delete($_.FullName, $false) } else { [System.IO.File]::Delete($_.FullName) } }; Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue }" >nul 2>&1
                            )
                        )
                    )
                ) else (
                    set /a ECO_UPDATE_ERRORS+=1
                )
            ) else (
                set /a ECO_UPDATE_ERRORS+=1
                echo %cRED%[ ERROR  ]%cRESET% Failed to update !CANDIDATE_PROPER_NAME! to !LATEST_VER!.
            )
        ) else (
            "%CHOICE_BIN%" /C YN /M "Do you want to download and install !CANDIDATE_PROPER_NAME! !LATEST_VER! now? "
            if !errorlevel!==1 (
                echo.
                set "CLI_TARGET=!LATEST_VER!"
                set "IS_UPDATER=1"
                call :InstallCandidate
                set "IS_UPDATER="
                if exist "!c_dir!\!LATEST_VER!" (
                    echo.
                    echo %cBLUE%[ ACTION ]%cRESET% Activating newly installed !CANDIDATE_PROPER_NAME! !LATEST_VER!...
                    call :SwitchCandidate "!LATEST_VER!"
                    if not errorlevel 1 (
                        set /a ECO_UPDATE_SUCCESS+=1
                        echo %cGREEN%[   OK   ]%cRESET% !CANDIDATE_PROPER_NAME! !LATEST_VER! is now active^^!
                    ) else (
                        set /a ECO_UPDATE_ERRORS+=1
                        echo %cRED%[ ERROR  ]%cRESET% Failed to activate !CANDIDATE_PROPER_NAME! !LATEST_VER!.
                    )
                ) else (
                    set /a ECO_UPDATE_ERRORS+=1
                    echo.
                    echo %cRED%[ ERROR  ]%cRESET% Failed to update !CANDIDATE_PROPER_NAME!. Previous version ^(!CHK_ACT!^) remains intact.
                )
            ) else (
                set /a ECO_UPDATE_SKIPPED+=1
                echo %cBLUE%[  INFO  ]%cRESET% Update skipped for !CANDIDATE_PROPER_NAME!.
            )
        )
    )
)
exit /b 0

:EcoPerformCheck_End
echo ------------------------------------------------------------
echo.
if !ECO_UPDATE_ERRORS! GTR 0 (
    echo %cYELLOW%[ WARNING]%cRESET% Update check completed with !ECO_UPDATE_ERRORS! error^(s^).
) else (
    echo %cGREEN%[   OK   ]%cRESET% All update checks complete.
)
if not defined CLI_COMMAND pause
goto :eof

:EcosystemSelectTool
echo.
echo ============================================================
if "!ECO_SUB_MODE!"=="SWITCH" (
    echo           Ecosystem Path ^& Environment
) else if "!ECO_SUB_MODE!"=="INSTALL" (
    echo               Ecosystem Downloader
) else (
    echo               Ecosystem Uninstaller
)
echo ============================================================

set "OPT_M=" & set "OPT_G=" & set "OPT_K=" & set "OPT_S=" & set "OPT_GR="
set "OPT_ANT=" & set "OPT_SBT=" & set "OPT_JBANG=" & set "OPT_QUARKUS=" & set "OPT_SPRING=" & set "OPT_MICRONAUT="
set "HAS_ANY=0"
set "HAS_M=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\maven\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\maven\*") do if not "%%~nxD"=="current" ( set "HAS_M=1" & set "HAS_ANY=1" )
set "HAS_G=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\gradle\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\gradle\*") do if not "%%~nxD"=="current" ( set "HAS_G=1" & set "HAS_ANY=1" )
set "HAS_K=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\kotlin\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\kotlin\*") do if not "%%~nxD"=="current" ( set "HAS_K=1" & set "HAS_ANY=1" )
set "HAS_S=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\scala\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\scala\*") do if not "%%~nxD"=="current" ( set "HAS_S=1" & set "HAS_ANY=1" )
set "HAS_GR=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\groovy\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\groovy\*") do if not "%%~nxD"=="current" ( set "HAS_GR=1" & set "HAS_ANY=1" )
set "HAS_ANT=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\ant\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\ant\*") do if not "%%~nxD"=="current" ( set "HAS_ANT=1" & set "HAS_ANY=1" )
set "HAS_SBT=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\sbt\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\sbt\*") do if not "%%~nxD"=="current" ( set "HAS_SBT=1" & set "HAS_ANY=1" )
set "HAS_JBANG=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\jbang\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\jbang\*") do if not "%%~nxD"=="current" ( set "HAS_JBANG=1" & set "HAS_ANY=1" )
set "HAS_QUARKUS=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\quarkus\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\quarkus\*") do if not "%%~nxD"=="current" ( set "HAS_QUARKUS=1" & set "HAS_ANY=1" )
set "HAS_SPRING=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\spring\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\spring\*") do if not "%%~nxD"=="current" ( set "HAS_SPRING=1" & set "HAS_ANY=1" )
set "HAS_MICRONAUT=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\micronaut\*" for /d %%D in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\micronaut\*") do if not "%%~nxD"=="current" ( set "HAS_MICRONAUT=1" & set "HAS_ANY=1" )

if "!ECO_SUB_MODE!"=="SWITCH" goto :ECO_TOOL_FILTERED
if "!ECO_SUB_MODE!"=="UNINSTALL" goto :ECO_TOOL_FILTERED

rem For INSTALL, show everything
echo Select an ecosystem tool to install:
echo.
echo %cGRAY%--- Manage by Tool ---%cRESET%
set "OPT_M=1" & echo 1. Maven
set "OPT_G=2" & echo 2. Gradle
set "OPT_K=3" & echo 3. Kotlin
set "OPT_S=4" & echo 4. Scala
set "OPT_GR=5" & echo 5. Groovy
set "OPT_ANT=6" & echo 6. Ant
set "OPT_SBT=7" & echo 7. SBT
set "OPT_JBANG=8" & echo 8. JBang
set "OPT_QUARKUS=9" & echo 9. Quarkus
set "OPT_SPRING=10" & echo 10. Spring Boot
set "OPT_MICRONAUT=11" & echo 11. Micronaut
set "cancel_opt=12"
echo.
echo %cGRAY%--- Actions ---%cRESET%
echo 12. Go back
goto :ECO_TOOL_PROMPT

:ECO_TOOL_FILTERED
if "!HAS_ANY!"=="0" (
    echo.
    echo %cYELLOW%[ WARNING]%cRESET% No ecosystem tools are currently installed.
    if "!ECO_SUB_MODE!"=="SWITCH" echo %cBLUE%[  INFO  ]%cRESET% Please use the Version Management menu to install them.
    pause
    if "!ECO_SUB_MODE!"=="SWITCH" goto :EcosystemMenu
    goto :EcoVersionMenu
)

if "!ECO_SUB_MODE!"=="SWITCH" (
    echo Select an installed ecosystem tool to set as active:
) else (
    echo Select an installed ecosystem tool to uninstall from:
)
echo.

echo %cGRAY%--- Manage by Tool ---%cRESET%
set /a TOOL_OPT=0
if "!HAS_M!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_M=!TOOL_OPT!" & echo !TOOL_OPT!. Maven )
if "!HAS_G!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_G=!TOOL_OPT!" & echo !TOOL_OPT!. Gradle )
if "!HAS_K!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_K=!TOOL_OPT!" & echo !TOOL_OPT!. Kotlin )
if "!HAS_S!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_S=!TOOL_OPT!" & echo !TOOL_OPT!. Scala )
if "!HAS_GR!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_GR=!TOOL_OPT!" & echo !TOOL_OPT!. Groovy )
if "!HAS_ANT!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_ANT=!TOOL_OPT!" & echo !TOOL_OPT!. Ant )
if "!HAS_SBT!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_SBT=!TOOL_OPT!" & echo !TOOL_OPT!. SBT )
if "!HAS_JBANG!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_JBANG=!TOOL_OPT!" & echo !TOOL_OPT!. JBang )
if "!HAS_QUARKUS!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_QUARKUS=!TOOL_OPT!" & echo !TOOL_OPT!. Quarkus )
if "!HAS_SPRING!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_SPRING=!TOOL_OPT!" & echo !TOOL_OPT!. Spring Boot )
if "!HAS_MICRONAUT!"=="1" ( set /a TOOL_OPT+=1 & set "OPT_MICRONAUT=!TOOL_OPT!" & echo !TOOL_OPT!. Micronaut )

set /a cancel_opt=!TOOL_OPT! + 1
echo.
echo %cGRAY%--- Actions ---%cRESET%
echo !cancel_opt!. Go back

:ECO_TOOL_PROMPT
echo.
if !cancel_opt! GTR 9 goto ECO_TOOL_PROMPT_MANUAL
set "VALID_CHOICES="
for /l %%k in (1,1,!cancel_opt!) do set "VALID_CHOICES=!VALID_CHOICES!%%k"

"%CHOICE_BIN%" /C !VALID_CHOICES! /N /M "Enter your choice (1-!cancel_opt!): "
set "tool_choice=!errorlevel!"
goto PROCESS_TOOL_CHOICE

:ECO_TOOL_PROMPT_MANUAL
set "tool_choice="
set /p "tool_choice=Enter your choice (1-!cancel_opt!): "
if not defined tool_choice (
    if "!ECO_SUB_MODE!"=="SWITCH" goto :EcosystemMenu
    goto :EcoVersionMenu
)
if "!tool_choice!"=="" (
    if "!ECO_SUB_MODE!"=="SWITCH" goto :EcosystemMenu
    goto :EcoVersionMenu
)
set "tool_choice=!tool_choice:"=!"
set "tool_choice=!tool_choice: =!"
if "!tool_choice!"=="" goto ECO_TOOL_PROMPT_MANUAL
set "NUM_TEST="
if not "!tool_choice!"=="!tool_choice:;=!" set "NUM_TEST=;"
for /f "eol= delims=0123456789" %%A in ("!tool_choice!") do set "NUM_TEST=%%A"
if defined NUM_TEST goto ECO_TOOL_PROMPT_MANUAL
if !tool_choice! LSS 1 goto ECO_TOOL_PROMPT_MANUAL
if !tool_choice! GTR !cancel_opt! goto ECO_TOOL_PROMPT_MANUAL

:PROCESS_TOOL_CHOICE
if !tool_choice!==!cancel_opt! (
    if "!ECO_SUB_MODE!"=="SWITCH" goto :EcosystemMenu
    goto :EcoVersionMenu
)
if defined OPT_M if !tool_choice!==!OPT_M! set "TARGET_CANDIDATE=maven"
if defined OPT_G if !tool_choice!==!OPT_G! set "TARGET_CANDIDATE=gradle"
if defined OPT_K if !tool_choice!==!OPT_K! set "TARGET_CANDIDATE=kotlin"
if defined OPT_S if !tool_choice!==!OPT_S! set "TARGET_CANDIDATE=scala"
if defined OPT_GR if !tool_choice!==!OPT_GR! set "TARGET_CANDIDATE=groovy"
if defined OPT_ANT if !tool_choice!==!OPT_ANT! set "TARGET_CANDIDATE=ant"
if defined OPT_SBT if !tool_choice!==!OPT_SBT! set "TARGET_CANDIDATE=sbt"
if defined OPT_JBANG if !tool_choice!==!OPT_JBANG! set "TARGET_CANDIDATE=jbang"
if defined OPT_QUARKUS if !tool_choice!==!OPT_QUARKUS! set "TARGET_CANDIDATE=quarkus"
if defined OPT_SPRING if !tool_choice!==!OPT_SPRING! set "TARGET_CANDIDATE=spring"
if defined OPT_MICRONAUT if !tool_choice!==!OPT_MICRONAUT! set "TARGET_CANDIDATE=micronaut"

call :GetCandidateEnvVar

if "!ECO_SUB_MODE!"=="INSTALL" (
    echo.
    set "CUSTOM_VER="
    set /p "CUSTOM_VER=Enter version of !CANDIDATE_PROPER_NAME! to install (or type 'latest'): "
::::::::::::::::::::
      if "!CUSTOM_VER!"=="" set "CUSTOM_VER=latest"
      if not defined CUSTOM_VER set "CUSTOM_VER=latest"
      if /i "!CUSTOM_VER!"=="c" goto :EcoVersionMenu
      if /i "!CUSTOM_VER!"=="cancel" goto :EcoVersionMenu
      if /i "!CUSTOM_VER!"=="q" goto :EcoVersionMenu
      if /i "!CUSTOM_VER!"=="quit" goto :EcoVersionMenu
      if /i "!CUSTOM_VER!"=="exit" goto :EcoVersionMenu
      if /i "!CUSTOM_VER!"=="back" goto :EcoVersionMenu
    call :ValidateStrictIdentifier "!CUSTOM_VER!" CUSTOM_VER
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier. Metacharacters, spaces, and reserved keywords are forbidden.
        pause
        goto :EcoVersionMenu
    )
    if /i "!CUSTOM_VER!"=="current" (
        echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier. Metacharacters, spaces, and reserved keywords are forbidden.
        pause
        goto :EcoVersionMenu
    )
    set "CLI_TARGET=!CUSTOM_VER!"
    call :InstallCandidate
    goto :EcoVersionMenu
)

if "!ECO_SUB_MODE!"=="UNINSTALL" (
    echo.
    echo %cBLUE%[  INFO  ]%cRESET% Installed !CANDIDATE_PROPER_NAME! versions:
    for /f "delims=" %%V in ('%PS_BIN% -NoProfile -Command "Get-ChildItem -LiteralPath '%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { $r=($_.Name -replace '-.*','').Trim(); if ($r -match '^\d+$') { [version]\"$r.0\" } elseif ($r -match '^\d+(\.\d+)+$') { [version]$r } else { [version]'0.0' } } -Descending | Select-Object -ExpandProperty Name"') do (
        echo   - %%V
    )
    echo.
    set "TARGET_VER="
    set /p "TARGET_VER=Enter exact version to uninstall: "
::::::::::::::::::::
      if not defined TARGET_VER (
          echo %cYELLOW%[  INFO  ]%cRESET% No version entered. Uninstallation cancelled.
          pause
          goto :EcoVersionMenu
      )
      if "!TARGET_VER!"=="" goto :EcoVersionMenu
      if /i "!TARGET_VER!"=="c" goto :EcoVersionMenu
      if /i "!TARGET_VER!"=="cancel" goto :EcoVersionMenu
      if /i "!TARGET_VER!"=="q" goto :EcoVersionMenu
      if /i "!TARGET_VER!"=="quit" goto :EcoVersionMenu
      if /i "!TARGET_VER!"=="exit" goto :EcoVersionMenu
      if /i "!TARGET_VER!"=="back" goto :EcoVersionMenu
    call :ValidateStrictIdentifier "!TARGET_VER!" TARGET_VER
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier.
        pause
        goto :EcoVersionMenu
    )
    set "CLI_TARGET=!TARGET_VER!"
    call :UninstallCandidate
    pause
    goto :EcoVersionMenu
)

:EcosystemToolMenu
echo.
echo ============================================================
echo           !CANDIDATE_PROPER_NAME! Path ^& Environment
echo ============================================================
echo.
if defined !CANDIDATE_ENV_VAR! (
    echo %cBLUE%[  INFO  ]%cRESET% Current !CANDIDATE_ENV_VAR!: !%CANDIDATE_ENV_VAR%!
) else (
    echo %cBLUE%[  INFO  ]%cRESET% !CANDIDATE_ENV_VAR! is not currently set.
)
echo.

set "eco_count=0"
set "CANDIDATE_DIR=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!"
if exist "!CANDIDATE_DIR!" (
    for /f "delims=" %%V in ('%PS_BIN% -NoProfile -Command "Get-ChildItem -Path '!CANDIDATE_DIR!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { $r=($_.Name -replace '-.*','').Trim(); if ($r -match '^\d+$') { [version]\"$r.0\" } elseif ($r -match '^\d+(\.\d+)+$') { [version]$r } else { [version]'0.0' } } -Descending | Select-Object -ExpandProperty Name"') do (
        set /a eco_count+=1
        set "ECO_VER_!eco_count!=%%V"
    )
)

:EcoToolSwitchMode
if !eco_count!==0 (
    echo %cYELLOW%[ WARNING]%cRESET% No installed versions found for !CANDIDATE_PROPER_NAME!.
    pause
    goto :EcosystemSelectTool
)

set "ACTIVE_TARGET="
for /f "tokens=1,2*" %%A in ('%FSUTIL_BIN% reparsepoint query "!CANDIDATE_DIR!\current" 2^>nul ^| %FINDSTR_BIN% /i "Print Name:"') do set "ACTIVE_TARGET=%%C"
if not defined ACTIVE_TARGET (
    set "QUERY_PATH=!CANDIDATE_DIR!\current"
    for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath $env:QUERY_PATH -ErrorAction SilentlyContinue).Target" 2^>nul') do set "ACTIVE_TARGET=%%A"
)
if defined ACTIVE_TARGET (
    set "ACTIVE_TARGET=!ACTIVE_TARGET:\??\=!"
    set "ACTIVE_TARGET=!ACTIVE_TARGET:\\?\=!"
    for /f "tokens=*" %%A in ("!ACTIVE_TARGET!") do set "ACTIVE_TARGET=%%A"
)

echo Please select an option:
echo.
echo %cGRAY%--- Installed Versions ---%cRESET%
for /l %%i in (1,1,!eco_count!) do (
    set "IS_ACTIVE="
    for /f "delims=" %%A in ("!CANDIDATE_DIR!\!ECO_VER_%%i!") do set "TP=%%~fA"
    if /i "!ACTIVE_TARGET!" == "!TP!" set "IS_ACTIVE= %cGREEN%[ACTIVE]%cRESET%"
    echo %%i. !ECO_VER_%%i!!IS_ACTIVE!
)
set /a clear_opt=eco_count+1
set /a cancel_opt=eco_count+2
echo.
echo %cGRAY%--- Global Actions ---%cRESET%
echo !clear_opt!. Clear !CANDIDATE_PROPER_NAME! from Environment Variables (De-activate)
echo.
echo %cGRAY%--- Actions ---%cRESET%
echo !cancel_opt!. Go back
echo.

set /a total_opts=eco_count+2

if !total_opts! GTR 9 goto :ECO_CHOICE_MANUAL

set "ALLOWED_CHOICES=123456789"
for %%A in (!total_opts!) do set "VALID_CHOICES=!ALLOWED_CHOICES:~0,%%A!"
"%CHOICE_BIN%" /C !VALID_CHOICES! /N /M "Select an option (1-!total_opts!): "
set "user_choice=!errorlevel!"
goto :PROCESS_ECO_CHOICE

:ECO_CHOICE_MANUAL
set user_choice=
set /p user_choice="Select an option (1-!total_opts!): "
::::::::::::::::::::
      if not defined user_choice goto :EcosystemSelectTool
      if "!user_choice!"=="" goto :EcosystemSelectTool
set "user_choice=!user_choice:"=!"
set "user_choice=!user_choice: =!"
if "!user_choice!"=="" goto :ECO_CHOICE_MANUAL
set "NUM_TEST="
if not "!user_choice!"=="!user_choice:;=!" set "NUM_TEST=;"
for /f "eol= delims=0123456789" %%A in ("!user_choice!") do set "NUM_TEST=%%A"
if defined NUM_TEST goto :ECO_CHOICE_MANUAL
if !user_choice! LSS 1 goto :ECO_CHOICE_MANUAL
if !user_choice! GTR !total_opts! goto :ECO_CHOICE_MANUAL

:PROCESS_ECO_CHOICE
if !user_choice!==!cancel_opt! goto :EcosystemSelectTool
if !user_choice!==!clear_opt! (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Clearing !CANDIDATE_PROPER_NAME! from environment...
    set "SYMLINK_PATH=!CANDIDATE_DIR!\current"
    rmdir "!SYMLINK_PATH!" >nul 2>&1
    "%REG_BIN%" delete "HKCU\Environment" /v !CANDIDATE_ENV_VAR! /f >nul 2>&1
    set "!CANDIDATE_ENV_VAR!="
    echo %cGREEN%[   OK   ]%cRESET% !CANDIDATE_PROPER_NAME! has been de-activated.
    pause
    goto :EcosystemToolMenu
)

rem Otherwise they selected a version to switch to
set "TARGET_VER=!ECO_VER_%user_choice%!"
if "!TARGET_VER!"=="" goto :EcosystemToolMenu
call :SwitchCandidate "!TARGET_VER!"
pause
goto :EcosystemToolMenu

:PromptLtsVersion
echo.
echo %cBLUE%[ ACTION ]%cRESET% Select Long-Term Support ^(LTS^) Version:
echo.
set "LTS_OPT=1"
if !ORACLE_LATEST_LTS! GTR 21 (
    echo !LTS_OPT!. Java !ORACLE_LATEST_LTS! ^(Latest LTS^)
    set "LTS_VER_!LTS_OPT!=!ORACLE_LATEST_LTS!"
    set /a LTS_OPT+=1
    echo !LTS_OPT!. Java 21
    set "LTS_VER_!LTS_OPT!=21"
    set /a LTS_OPT+=1
) else (
    echo !LTS_OPT!. Java 21 ^(Latest LTS^)
    set "LTS_VER_!LTS_OPT!=21"
    set /a LTS_OPT+=1
)
echo !LTS_OPT!. Java 17
set "LTS_VER_!LTS_OPT!=17"
set /a LTS_OPT+=1
echo.
echo !LTS_OPT!. Cancel
set "LTS_CANCEL_OPT=!LTS_OPT!"
echo.
set "LTS_CHOICE_STR="
for /l %%c in (1,1,!LTS_OPT!) do set "LTS_CHOICE_STR=!LTS_CHOICE_STR!%%c"
"%CHOICE_BIN%" /C !LTS_CHOICE_STR! /N /M "Select LTS version (1-!LTS_OPT!): "
set "LTS_CHOICE=!errorlevel!"
if !LTS_CHOICE!==!LTS_CANCEL_OPT! (
    set "CLI_TARGET="
    goto :eof
)
for %%C in (!LTS_CHOICE!) do set "CLI_TARGET=!LTS_VER_%%C!"
goto :eof

:DownloadJDK_Headless
call :RequireNetwork
if errorlevel 1 (
    if "!CLI_COMMAND!"=="" pause
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
if not defined DL_VERSION (
    echo %cRED%[ ERROR  ]%cRESET% No version specified.
    if "!CLI_COMMAND!"=="" pause
    exit /b 1
)
set "DL_VERSION=!DL_VERSION:"=!"
if not defined DL_VERSION (
    echo %cRED%[ ERROR  ]%cRESET% Invalid version specified: version cannot be empty.
    if "!CLI_COMMAND!"=="" pause
    exit /b 1
)
set "VER_NUM_TEST="
if not "!DL_VERSION!"=="!DL_VERSION:;=!" set "VER_NUM_TEST=;"
for /f "eol= delims=0123456789" %%A in ("!DL_VERSION!") do set "VER_NUM_TEST=%%A"
if defined VER_NUM_TEST (
    echo %cRED%[ ERROR  ]%cRESET% '!DL_VERSION!' is not a JDK major version number.
    echo            Expected a plain number, e.g. 8, 17, 21, 25.
    if "!CLI_COMMAND!"=="" pause
    exit /b 1
)

if "!CLI_VENDOR!"=="" (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Select JDK Distribution Vendor:
    echo.
    echo 1. Oracle ^(Standard^)
    echo 2. Adoptium ^(Eclipse Temurin^)
    echo 3. GraalVM ^(Community Edition^)
    echo 4. Amazon Corretto
    echo 5. Azul Zulu
    echo 6. Microsoft Build of OpenJDK
    echo 7. BellSoft Liberica
    echo 8. IBM Semeru ^(OpenJ9^)
    echo 9. SapMachine ^(SAP^)
    echo 10. Mandrel ^(Red Hat GraalVM^)
    echo 11. Alibaba Dragonwell
    echo 12. Tencent Kona
    echo 13. Cancel
    echo.
:GET_DL_VENDOR_CHOICE
    set "V_CHOICE="
    set /p "V_CHOICE=Select vendor (1-13): "
    if not defined V_CHOICE goto :eof
    if "!V_CHOICE!"=="" goto :eof
    set "V_CHOICE=!V_CHOICE:"=!"
    set "V_CHOICE=!V_CHOICE: =!"
    if "!V_CHOICE!"=="" goto GET_DL_VENDOR_CHOICE
    set "NUM_TEST="
    if not "!V_CHOICE!"=="!V_CHOICE:;=!" set "NUM_TEST=;"
    for /f "eol= delims=0123456789" %%A in ("!V_CHOICE!") do set "NUM_TEST=%%A"
    if defined NUM_TEST goto GET_DL_VENDOR_CHOICE
    if !V_CHOICE! LSS 1 goto GET_DL_VENDOR_CHOICE
    if !V_CHOICE! GTR 13 goto GET_DL_VENDOR_CHOICE
    if !V_CHOICE!==13 goto :eof
    if !V_CHOICE!==1 set "CLI_VENDOR=Oracle"
    if !V_CHOICE!==2 set "CLI_VENDOR=Adoptium"
    if !V_CHOICE!==3 set "CLI_VENDOR=GraalVM"
    if !V_CHOICE!==4 set "CLI_VENDOR=Corretto"
    if !V_CHOICE!==5 set "CLI_VENDOR=Zulu"
    if !V_CHOICE!==6 set "CLI_VENDOR=Microsoft"
    if !V_CHOICE!==7 set "CLI_VENDOR=Liberica"
    if !V_CHOICE!==8 set "CLI_VENDOR=Semeru"
    if !V_CHOICE!==9 set "CLI_VENDOR=SapMachine"
    if !V_CHOICE!==10 set "CLI_VENDOR=Mandrel"
    if !V_CHOICE!==11 set "CLI_VENDOR=Dragonwell"
    if !V_CHOICE!==12 set "CLI_VENDOR=Kona"
)

rem Normalize vendor aliases
if /i "!CLI_VENDOR!"=="bellsoft" set "CLI_VENDOR=Liberica"
if /i "!CLI_VENDOR!"=="ibm" set "CLI_VENDOR=Semeru"
if /i "!CLI_VENDOR!"=="openj9" set "CLI_VENDOR=Semeru"
if /i "!CLI_VENDOR!"=="temurin" set "CLI_VENDOR=Adoptium"
if /i "!CLI_VENDOR!"=="sap" set "CLI_VENDOR=SapMachine"
if /i "!CLI_VENDOR!"=="sapmachine" set "CLI_VENDOR=SapMachine"
if /i "!CLI_VENDOR!"=="redhat-mandrel" set "CLI_VENDOR=Mandrel"
if /i "!CLI_VENDOR!"=="mandrel" set "CLI_VENDOR=Mandrel"
if /i "!CLI_VENDOR!"=="alibaba" set "CLI_VENDOR=Dragonwell"
if /i "!CLI_VENDOR!"=="dragonwell" set "CLI_VENDOR=Dragonwell"
if /i "!CLI_VENDOR!"=="tencent" set "CLI_VENDOR=Kona"
if /i "!CLI_VENDOR!"=="kona" set "CLI_VENDOR=Kona"

rem Check if this vendor and major version combination is already installed
if "!IS_UPDATER!" NEQ "1" (
    set "EXISTING_PATH="
    set "EXISTING_VENDOR="
    for /l %%k in (1,1,!JDK_COUNT!) do (
        if "!JDK_MAJOR_%%k!"=="!DL_VERSION!" (
            if /i "!JDK_VENDOR_%%k!"=="!CLI_VENDOR!" (
                set "EXISTING_PATH=!JDK_PATH_%%k!"
                set "EXISTING_VENDOR=!JDK_VENDOR_%%k!"
            )
        )
    )
    if defined EXISTING_PATH (
        echo.
        echo %cYELLOW%[ WARNING]%cRESET% !EXISTING_VENDOR! JDK !DL_VERSION! is already installed on your system:
        echo            - !EXISTING_PATH!
        echo.
        if "!FORCE_YES!"=="1" (
            echo %cBLUE%[  INFO  ]%cRESET% Reinstalling/overwriting due to --yes flag...
        ) else (
            "%CHOICE_BIN%" /C yn /N /M "Would you like to reinstall and overwrite it? (y/N): "
            if !errorlevel! NEQ 1 (
                echo %cBLUE%[  INFO  ]%cRESET% Installation cancelled.
                if "!CLI_COMMAND!"=="" pause
                goto :eof
            )
        )
    )
)

if !DL_VERSION! LEQ 16 (
    if /i "!CLI_VENDOR!"=="oracle" (
        echo.
        echo %cRED%[ ERROR  ]%cRESET% Oracle Java 16 and below are locked behind an authentication wall.
        echo            Please use Adoptium, GraalVM, Liberica, or Semeru for these versions.
        if "!CLI_COMMAND!"=="" pause
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
)

if "!DL_VERSION!"=="17" (
    if /i "!CLI_VENDOR!"=="oracle" (
        echo.
        echo %cYELLOW%[ WARNING]%cRESET% Oracle restricts headless downloads for JDK 17 newer than 17.0.12.
        echo            This will attempt to install 17.0.12. For newer security patches,
        echo            download manually from Oracle or install from Adoptium/GraalVM instead.
        echo.
        if "!FORCE_YES!"=="1" (
            echo Proceed with installing 17.0.12? ^(y/N^): Y [AUTO-YES]
        ) else (
            "%CHOICE_BIN%" /C yn /N /M "Proceed with installing 17.0.12? (y/N): "
            if errorlevel 2 goto :eof
        )
    )
)

if /i "!CLI_VENDOR!"=="oracle" goto :Resolve_Oracle
if /i "!CLI_VENDOR!"=="adoptium" goto :Resolve_Adoptium
if /i "!CLI_VENDOR!"=="graalvm" goto :Resolve_GraalVM
if /i "!CLI_VENDOR!"=="corretto" goto :Resolve_Corretto
if /i "!CLI_VENDOR!"=="zulu" goto :Resolve_Zulu
if /i "!CLI_VENDOR!"=="microsoft" goto :Resolve_Microsoft
if /i "!CLI_VENDOR!"=="liberica" goto :Resolve_Liberica
if /i "!CLI_VENDOR!"=="semeru" goto :Resolve_Semeru
if /i "!CLI_VENDOR!"=="sapmachine" goto :Resolve_SapMachine
if /i "!CLI_VENDOR!"=="mandrel" goto :Resolve_Mandrel
if /i "!CLI_VENDOR!"=="dragonwell" goto :Resolve_Dragonwell
if /i "!CLI_VENDOR!"=="kona" goto :Resolve_Kona
if "!API_URL!"=="" (
    echo %cRED%[ ERROR  ]%cRESET% Unknown or unsupported vendor: !CLI_VENDOR!
    if "!CLI_COMMAND!"=="" pause
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
goto :FetchAndExtract

:Resolve_Oracle
set "DL_VENDOR=Oracle"
if /i "!SYS_ARCH!" NEQ "x64" (
    echo.
    echo %cYELLOW%[ WARNING]%cRESET% Oracle does not publish native Windows ARM64 ZIP archives.
    echo            Downloading x64 build ^(runs under Windows 11 Prism x64 emulation^).
    echo            Tip: Use Adoptium, Zulu, or Microsoft for native Windows ARM64 builds.
)
set "API_URL=https://download.oracle.com/java/!DL_VERSION!/latest/jdk-!DL_VERSION!_windows-x64_bin.zip"
if "!DL_VERSION!"=="17" set "API_URL=https://download.oracle.com/java/17/archive/jdk-17.0.12_windows-x64_bin.zip"
if "!DL_VERSION!"=="18" set "API_URL=https://download.oracle.com/java/18/archive/jdk-18.0.2.1_windows-x64_bin.zip"
if "!DL_VERSION!"=="19" set "API_URL=https://download.oracle.com/java/19/archive/jdk-19.0.2_windows-x64_bin.zip"
if "!DL_VERSION!"=="20" set "API_URL=https://download.oracle.com/java/20/archive/jdk-20.0.2_windows-x64_bin.zip"
if "!DL_VERSION!"=="22" set "API_URL=https://download.oracle.com/java/22/archive/jdk-22.0.2_windows-x64_bin.zip"
if "!DL_VERSION!"=="23" set "API_URL=https://download.oracle.com/java/23/archive/jdk-23.0.2_windows-x64_bin.zip"
if "!DL_VERSION!"=="24" set "API_URL=https://download.oracle.com/java/24/archive/jdk-24.0.2_windows-x64_bin.zip"
set "API_SHA256_URL=!API_URL!.sha256"
set "API_SHA256="
if "!IS_LOCKING_ONLY!"=="1" goto :FinishLockResolution
goto :FetchAndExtract

:Resolve_Adoptium
set "DL_VENDOR=Adoptium"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying Adoptium API for latest JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $res = Invoke-RestMethod -Uri 'https://api.adoptium.net/v3/assets/feature_releases/!DL_VERSION!/ga?architecture=!SYS_ARCH!&image_type=jdk&jvm_impl=hotspot&os=windows&page=0&page_size=1' -UseBasicParsing -TimeoutSec 15; if ($res[0].binaries[0].package.link -and $res[0].binaries[0].package.checksum) { Write-Output ('API_URL='+$res[0].binaries[0].package.link); Write-Output ('API_SHA256='+$res[0].binaries[0].package.checksum) } else { exit 1 } } catch { $m = ($_.Exception.Message -replace '[\r\n]+', ' '); if ($env:LOCALAPPDATA) { $m = $m.Replace($env:LOCALAPPDATA, '%%LOCALAPPDATA%%') }; if ($env:USERPROFILE) { $m = $m.Replace($env:USERPROFILE, '%%USERPROFILE%%') }; Write-Output ('API_ERROR='+$m); exit 1 }"
goto Run_API_Query

:Resolve_GraalVM
set "DL_VENDOR=GraalVM"
if /i "!SYS_ARCH!" NEQ "x64" (
    echo.
    echo %cYELLOW%[ WARNING]%cRESET% GraalVM CE does not publish native Windows ARM64 builds.
    echo            Downloading x64 build ^(runs under Windows 11 Prism x64 emulation^).
    echo            Tip: Use Adoptium, Zulu, or Microsoft for native Windows ARM64 builds.
)
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying GraalVM GitHub API for latest JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $res = $null; try { $res = Invoke-RestMethod -Uri 'https://api.github.com/repos/graalvm/graalvm-ce-builds/releases' -UseBasicParsing -TimeoutSec 15 } catch { }; $t = $null; $foundVer = !DL_VERSION!; if ($res) { foreach ($r in $res) { if ($r.tag_name -like 'jdk-!DL_VERSION!*') { $t = $r; break } }; if (-not $t) { foreach ($r in $res) { $a = $r.assets | Where-Object { $_.name -match 'windows-(x64|amd64)_bin\.zip$' } | Select-Object -First 1; if ($a -and ($r.tag_name -match 'jdk-(\d+)')) { $foundVer = [int]$matches[1]; $t = $r; break } } } }; if (-not $t) { try { $req = [Net.HttpWebRequest]::Create('https://github.com/graalvm/graalvm-ce-builds/releases/latest'); $req.AllowAutoRedirect = $false; $req.UserAgent = 'Mozilla/5.0'; $req.Timeout = 5000; $resp = $req.GetResponse(); $tag = $null; if ($resp.Headers['Location'] -match '/releases/tag/([a-zA-Z0-9._+-]+)$') { $tag = $matches[1] }; $resp.Close(); if ($tag) { $tagEnc = [System.Uri]::EscapeDataString($tag); $html = (New-Object Net.WebClient).DownloadString('https://github.com/graalvm/graalvm-ce-builds/releases/expanded_assets/' + $tagEnc); $m = [regex]::Match($html, 'graalvm-community-jdk-(\d+)[A-Za-z0-9._+-]*windows-(x64|amd64)_bin\.zip'); if ($m.Success) { $foundVer = [int]$m.Groups[1].Value; $u = 'https://github.com/graalvm/graalvm-ce-builds/releases/download/' + $tagEnc + '/' + $m.Value; $s = $u + '.sha256'; Write-Output ('API_VERSION=' + $foundVer); Write-Output ('API_URL=' + $u); Write-Output ('API_SHA256_URL=' + $s); exit 0 } } } catch { } }; if ($t) { $u = $null; $s = $null; foreach ($a in $t.assets) { if ($a.name -match 'windows-(x64|amd64)_bin\.zip$') { $u = $a.browser_download_url }; if ($a.name -match 'windows-(x64|amd64)_bin\.zip\.sha256$') { $s = $a.browser_download_url } }; if ($u -and $s) { Write-Output ('API_VERSION=' + $foundVer); Write-Output ('API_URL=' + $u); Write-Output ('API_SHA256_URL=' + $s) } else { exit 1 } } else { exit 1 } } catch { $m = ($_.Exception.Message -replace '[\r\n]+', ' '); if ($env:LOCALAPPDATA) { $m = $m.Replace($env:LOCALAPPDATA, '%%LOCALAPPDATA%%') }; if ($env:USERPROFILE) { $m = $m.Replace($env:USERPROFILE, '%%USERPROFILE%%') }; Write-Output ('API_ERROR='+$m); exit 1 }"
goto Run_API_Query

:Resolve_Corretto
set "DL_VENDOR=Corretto"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Resolving Amazon Corretto JDK !DL_VERSION! URLs...
set "API_URL=https://corretto.aws/downloads/latest/amazon-corretto-!DL_VERSION!-!SYS_ARCH!-windows-jdk.zip"
set "API_SHA256_URL=https://corretto.aws/downloads/latest_sha256/amazon-corretto-!DL_VERSION!-!SYS_ARCH!-windows-jdk.zip"
set "API_SHA256="
if "!IS_LOCKING_ONLY!"=="1" goto :FinishLockResolution
goto :FetchAndExtract

:Resolve_Zulu
set "DL_VENDOR=Zulu"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying Azul Zulu API for latest JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $list = Invoke-RestMethod -Uri 'https://api.azul.com/metadata/v1/zulu/packages/?java_version=!DL_VERSION!&os=windows&arch=!ZULU_ARCH!&archive_type=zip&java_package_type=jdk&javafx_bundled=false&release_status=ga&availability_types=CA&latest=true&page=1&page_size=1' -UseBasicParsing -TimeoutSec 15; if (-not $list -or -not $list[0].download_url) { exit 1 }; Write-Output ('API_URL='+$list[0].download_url); $uuid = $list[0].package_uuid; if ($uuid) { try { $d = Invoke-RestMethod -Uri ('https://api.azul.com/metadata/v1/zulu/packages/'+$uuid) -UseBasicParsing -TimeoutSec 15; if ($d.sha256_hash) { Write-Output ('API_SHA256='+$d.sha256_hash) } } catch { } } } catch { $m = ($_.Exception.Message -replace '[\r\n]+', ' '); if ($env:LOCALAPPDATA) { $m = $m.Replace($env:LOCALAPPDATA, '%%LOCALAPPDATA%%') }; if ($env:USERPROFILE) { $m = $m.Replace($env:USERPROFILE, '%%USERPROFILE%%') }; Write-Output ('API_ERROR='+$m); exit 1 }"
goto Run_API_Query

:Resolve_Microsoft
set "DL_VENDOR=Microsoft"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Resolving Microsoft Build of OpenJDK !DL_VERSION! URLs...
set "API_URL=https://aka.ms/download-jdk/microsoft-jdk-!DL_VERSION!-windows-!SYS_ARCH!.zip"
set "API_SHA256_URL=https://aka.ms/download-jdk/microsoft-jdk-!DL_VERSION!-windows-!SYS_ARCH!.zip.sha256sum.txt"
set "API_SHA256="
if "!IS_LOCKING_ONLY!"=="1" goto :FinishLockResolution
goto :FetchAndExtract

:Resolve_Liberica
set "DL_VENDOR=Liberica"
rem BellSoft official REST API exclusively distributes SHA1 checksums.
rem jvm verifies the provided SHA1 hash directly against the downloaded payload.
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying BellSoft Liberica API for latest JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $res = Invoke-RestMethod -Uri 'https://api.bell-sw.com/v1/liberica/releases?version-feature=!DL_VERSION!&version-modifier=latest&bitness=64&os=windows&arch=!ZULU_ARCH!&package-type=zip&bundle-type=jdk' -UseBasicParsing -TimeoutSec 15; if (-not $res -or -not $res[0].downloadUrl) { exit 1 }; Write-Output ('API_URL='+$res[0].downloadUrl); if ($res[0].sha1) { Write-Output ('API_SHA1='+$res[0].sha1) } } catch { $m = ($_.Exception.Message -replace '[\r\n]+', ' '); if ($env:LOCALAPPDATA) { $m = $m.Replace($env:LOCALAPPDATA, '%LOCALAPPDATA%') }; if ($env:USERPROFILE) { $m = $m.Replace($env:USERPROFILE, '%USERPROFILE%') }; Write-Output ('API_ERROR='+$m); exit 1 }"
goto Run_API_Query

:Resolve_Semeru
set "DL_VENDOR=Semeru"
if /i "!SYS_ARCH!" NEQ "x64" (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% IBM Semeru ^(OpenJ9^) does not publish Windows ARM64 builds.
    echo            Please use Adoptium, Zulu, or Microsoft for Windows ARM64.
    if "!CLI_COMMAND!"=="" pause
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying IBM Semeru release data for JDK !DL_VERSION!...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $res = $null; $foundVer = !DL_VERSION!; $tag = $null; $searchVers = @($foundVer) + (27..8 | Where-Object { $_ -lt $foundVer }); foreach ($v in $searchVers) { try { $rel = Invoke-RestMethod -Uri ('https://api.github.com/repos/ibmruntimes/semeru' + $v + '-binaries/releases/latest') -UseBasicParsing -TimeoutSec 5; if ($rel.assets) { $res = $rel; $foundVer = $v; break } } catch { }; if (-not $res) { try { $req = [Net.HttpWebRequest]::Create('https://github.com/ibmruntimes/semeru' + $v + '-binaries/releases/latest'); $req.AllowAutoRedirect = $false; $req.UserAgent = 'Mozilla/5.0'; $req.Timeout = 5000; $resp = $req.GetResponse(); try { if ($resp.Headers['Location'] -match '/releases/tag/([a-zA-Z0-9._+-]+)$') { $tag = $matches[1]; $foundVer = $v; break } } finally { $resp.Close() } } catch { } }; if ($res -or $tag) { break } }; if ($tag -and -not $res) { $tagEnc = [System.Uri]::EscapeDataString($tag); $html = (New-Object Net.WebClient).DownloadString('https://github.com/ibmruntimes/semeru' + $foundVer + '-binaries/releases/expanded_assets/' + $tagEnc); $m = [regex]::Match($html, 'ibm-semeru-open-jdk_x64_windows_[a-zA-Z0-9._+-]+\.zip'); if ($m.Success) { $u = 'https://github.com/ibmruntimes/semeru' + $foundVer + '-binaries/releases/download/' + $tagEnc + '/' + $m.Value; $s = $u + '.sha256.txt'; Write-Output ('API_VERSION=' + $foundVer); Write-Output ('API_URL=' + $u); Write-Output ('API_SHA256_URL=' + $s); exit 0 } }; if (-not $res -or -not $res.assets) { exit 1 }; $u = $null; $s = $null; foreach ($a in $res.assets) { if ($a.name -match 'ibm-semeru-open-jdk_x64_windows_.*\.zip$') { $u = $a.browser_download_url }; if ($a.name -match 'ibm-semeru-open-jdk_x64_windows_.*\.zip\.sha256\.txt$') { $s = $a.browser_download_url } }; if ($u) { Write-Output ('API_VERSION=' + $foundVer); Write-Output ('API_URL=' + $u); if ($s) { Write-Output ('API_SHA256_URL=' + $s) } } else { exit 1 } } catch { $m = ($_.Exception.Message -replace '[\r\n]+', ' '); if ($env:LOCALAPPDATA) { $m = $m.Replace($env:LOCALAPPDATA, '%%LOCALAPPDATA%%') }; if ($env:USERPROFILE) { $m = $m.Replace($env:USERPROFILE, '%%USERPROFILE%%') }; Write-Output ('API_ERROR='+$m); exit 1 }"
goto Run_API_Query

:Resolve_SapMachine
set "DL_VENDOR=SapMachine"
if /i "!SYS_ARCH!" NEQ "x64" (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% SapMachine does not publish native Windows ARM64 builds.
    echo            Please use Adoptium, Zulu, or Microsoft for Windows ARM64.
    if "!CLI_COMMAND!"=="" pause
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying SapMachine release data for JDK !DL_VERSION!...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $res = Invoke-RestMethod -Uri 'https://sap.github.io/SapMachine/assets/data/sapmachine_releases.json' -UseBasicParsing -TimeoutSec 15; $foundVer = '!DL_VERSION!'; $vObj = $res.assets.$foundVer; if (-not $vObj) { $avail = @($res.assets.psobject.properties.Name | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } | Sort-Object -Descending); if ($avail.Count -gt 0) { $foundVer = '' + $avail[0]; $vObj = $res.assets.$foundVer } }; if ($vObj -and $vObj.releases[0].jdk.'windows-x64') { $u = $vObj.releases[0].jdk.'windows-x64'; Write-Output ('API_VERSION=' + $foundVer); Write-Output ('API_URL=' + $u); if ($vObj.checksums[0].jdk.'windows-x64') { $c = ($vObj.checksums[0].jdk.'windows-x64' -split '\s+')[-1].Trim(); Write-Output ('API_SHA256=' + $c) } } else { exit 1 } } catch { $m = ($_.Exception.Message -replace '[\r\n]+', ' '); if ($env:LOCALAPPDATA) { $m = $m.Replace($env:LOCALAPPDATA, '%%LOCALAPPDATA%%') }; if ($env:USERPROFILE) { $m = $m.Replace($env:USERPROFILE, '%%USERPROFILE%%') }; Write-Output ('API_ERROR='+$m); exit 1 }"
goto Run_API_Query

:Resolve_Mandrel
set "DL_VENDOR=Mandrel"
if /i "!SYS_ARCH!" NEQ "x64" (
    echo.
    echo %cYELLOW%[ WARNING]%cRESET% Mandrel does not publish native Windows ARM64 builds.
    echo            Downloading x64 build ^(runs under Windows 11 Prism x64 emulation^).
    echo            Tip: Use Adoptium, Zulu, or Microsoft for native Windows ARM64 builds.
)
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying Mandrel release data for JDK !DL_VERSION!...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $h = @{}; if ($env:GITHUB_TOKEN) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }; $res = $null; try { $res = Invoke-RestMethod -Uri 'https://api.github.com/repos/graalvm/mandrel/releases' -Headers $h -UseBasicParsing -TimeoutSec 10 } catch { }; $t = $null; $foundVer = !DL_VERSION!; if ($res) { foreach ($r in $res) { if (-not $r.prerelease -and ($r.assets | Where-Object { $_.name -like ('mandrel-java!DL_VERSION!-windows-amd64-*.zip') })) { $t = $r; break } }; if (-not $t) { foreach ($r in $res) { if (-not $r.prerelease) { $ma = $r.assets | Where-Object { $_.name -match 'mandrel-java(\d+)-windows-amd64-.*\.zip$' } | Select-Object -First 1; if ($ma -and ($ma.name -match 'mandrel-java(\d+)-windows-amd64')) { $foundVer = [int]$matches[1]; $t = $r; break } } } } }; if (-not $t) { try { $req = [Net.HttpWebRequest]::Create('https://github.com/graalvm/mandrel/releases/latest'); $req.AllowAutoRedirect = $false; $req.UserAgent = 'Mozilla/5.0'; $req.Timeout = 5000; $resp = $req.GetResponse(); $tag = $null; if ($resp.Headers['Location'] -match '/releases/tag/([a-zA-Z0-9._+-]+)$') { $tag = $matches[1] }; $resp.Close(); if ($tag) { $tagEnc = [System.Uri]::EscapeDataString($tag); $html = (New-Object Net.WebClient).DownloadString('https://github.com/graalvm/mandrel/releases/expanded_assets/' + $tagEnc); $m = [regex]::Match($html, 'mandrel-java(\d+)-windows-amd64-([A-Za-z0-9._+-]+)\.zip'); if ($m.Success) { $foundVer = [int]$m.Groups[1].Value; $u = 'https://github.com/graalvm/mandrel/releases/download/' + $tagEnc + '/' + $m.Value; $s = $u + '.sha256'; Write-Output ('API_VERSION=' + $foundVer); Write-Output ('API_URL=' + $u); Write-Output ('API_SHA256_URL=' + $s); exit 0 } } } catch { } }; if ($t) { $u = ($t.assets | Where-Object { $_.name -like ('mandrel-java' + $foundVer + '-windows-amd64-*.zip') } | Select-Object -First 1).browser_download_url; $s = ($t.assets | Where-Object { $_.name -like ('mandrel-java' + $foundVer + '-windows-amd64-*.zip.sha256') } | Select-Object -First 1).browser_download_url; if ($u) { Write-Output ('API_VERSION=' + $foundVer); Write-Output ('API_URL=' + $u); if ($s) { Write-Output ('API_SHA256_URL=' + $s) } } else { exit 1 } } else { exit 1 } } catch { $m = ($_.Exception.Message -replace '[\r\n]+', ' '); if ($env:LOCALAPPDATA) { $m = $m.Replace($env:LOCALAPPDATA, '%%LOCALAPPDATA%%') }; if ($env:USERPROFILE) { $m = $m.Replace($env:USERPROFILE, '%%USERPROFILE%%') }; Write-Output ('API_ERROR='+$m); exit 1 }"
goto Run_API_Query

:Resolve_Dragonwell
set "DL_VENDOR=Dragonwell"
if /i "!SYS_ARCH!" NEQ "x64" (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Alibaba Dragonwell does not publish Windows ARM64 builds.
    echo            Please use Adoptium, Zulu, or Microsoft for Windows ARM64.
    if "!CLI_COMMAND!"=="" pause
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
echo.
echo %cBLUE%[ ACTION ]%cRESET% Resolving Alibaba Dragonwell JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $h = @{}; if ($env:GITHUB_TOKEN) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }; $tag = $null; $foundVer = !DL_VERSION!; $searchVers = @($foundVer) + (26..8 | Where-Object { $_ -lt $foundVer }); foreach ($v in $searchVers) { try { $rel = Invoke-RestMethod -Uri ('https://api.github.com/repos/dragonwell-project/dragonwell' + $v + '/releases/latest') -Headers $h -UseBasicParsing -TimeoutSec 5; if ($rel.tag_name) { $tag = $rel.tag_name; $foundVer = $v; break } } catch { }; if (-not $tag) { try { $req = [Net.HttpWebRequest]::Create('https://github.com/dragonwell-project/dragonwell' + $v + '/releases/latest'); $req.AllowAutoRedirect = $false; $req.UserAgent = 'Mozilla/5.0'; $req.Timeout = 5000; $resp = $req.GetResponse(); try { if ($resp.Headers['Location'] -match '/releases/tag/([a-zA-Z0-9._+-]+)$') { $tag = $matches[1]; $foundVer = $v; break } } finally { $resp.Close() } } catch { } }; if ($tag) { break } }; if (-not $tag) { exit 1 }; $tagEnc = [System.Uri]::EscapeDataString($tag); $html = (New-Object Net.WebClient).DownloadString('https://github.com/dragonwell-project/dragonwell' + $foundVer + '/releases/expanded_assets/' + $tagEnc); $zipMatch = [regex]::Match($html, 'Alibaba_Dragonwell_[A-Za-z0-9._+-]+_x64_windows\.zip'); if (-not $zipMatch.Success) { exit 1 }; $zipName = $zipMatch.Value; Write-Output ('API_VERSION=' + $foundVer); Write-Output ('API_URL=https://github.com/dragonwell-project/dragonwell' + $foundVer + '/releases/download/' + $tagEnc + '/' + $zipName); Write-Output ('API_SHA256_URL=https://github.com/dragonwell-project/dragonwell' + $foundVer + '/releases/download/' + $tagEnc + '/' + $zipName + '.sha256.txt') } catch { $m = ($_.Exception.Message -replace '[\r\n]+', ' '); if ($env:LOCALAPPDATA) { $m = $m.Replace($env:LOCALAPPDATA, '%%LOCALAPPDATA%%') }; if ($env:USERPROFILE) { $m = $m.Replace($env:USERPROFILE, '%%USERPROFILE%%') }; Write-Output ('API_ERROR='+$m); exit 1 }"
goto Run_API_Query

:Resolve_Kona
set "DL_VENDOR=Kona"
if /i "!SYS_ARCH!" NEQ "x64" (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Tencent Kona does not publish Windows ARM64 builds.
    echo            Please use Adoptium, Zulu, or Microsoft for Windows ARM64.
    if "!CLI_COMMAND!"=="" pause
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
echo.
echo %cBLUE%[ ACTION ]%cRESET% Resolving Tencent Kona JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $h = @{}; if ($env:GITHUB_TOKEN) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }; $tag = $null; $foundVer = !DL_VERSION!; $searchVers = @($foundVer) + (26..8 | Where-Object { $_ -lt $foundVer }); foreach ($v in $searchVers) { try { $rel = Invoke-RestMethod -Uri ('https://api.github.com/repos/Tencent/TencentKona-' + $v + '/releases/latest') -Headers $h -UseBasicParsing -TimeoutSec 5; if ($rel.tag_name) { $tag = $rel.tag_name; $foundVer = $v; break } } catch { }; if (-not $tag) { try { $req = [Net.HttpWebRequest]::Create('https://github.com/Tencent/TencentKona-' + $v + '/releases/latest'); $req.AllowAutoRedirect = $false; $req.UserAgent = 'Mozilla/5.0'; $req.Timeout = 5000; $resp = $req.GetResponse(); try { if ($resp.Headers['Location'] -match '/releases/tag/([a-zA-Z0-9._+-]+)$') { $tag = $matches[1]; $foundVer = $v; break } } finally { $resp.Close() } } catch { } }; if ($tag) { break } }; if (-not $tag) { exit 1 }; $tagEnc = [System.Uri]::EscapeDataString($tag); $html = (New-Object Net.WebClient).DownloadString('https://github.com/Tencent/TencentKona-' + $foundVer + '/releases/expanded_assets/' + $tagEnc); $zipMatch = [regex]::Match($html, 'TencentKona-[A-Za-z0-9._+-]+windows[A-Za-z0-9._+-]*\.zip'); if (-not $zipMatch.Success) { exit 1 }; $zipName = $zipMatch.Value; Write-Output ('API_VERSION=' + $foundVer); Write-Output ('API_URL=https://github.com/Tencent/TencentKona-' + $foundVer + '/releases/download/' + $tagEnc + '/' + $zipName); Write-Output ('API_MD5_URL=https://github.com/Tencent/TencentKona-' + $foundVer + '/releases/download/' + $tagEnc + '/' + $zipName + '.md5') } catch { $m = ($_.Exception.Message -replace '[\r\n]+', ' '); if ($env:LOCALAPPDATA) { $m = $m.Replace($env:LOCALAPPDATA, '%%LOCALAPPDATA%%') }; if ($env:USERPROFILE) { $m = $m.Replace($env:USERPROFILE, '%%USERPROFILE%%') }; Write-Output ('API_ERROR='+$m); exit 1 }"
goto Run_API_Query

:Run_API_Query
call :RequireNetwork
if errorlevel 1 (
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
set "API_URL=" & set "API_RESOLVED_VER=" & set "API_SHA256=" & set "API_SHA256_URL=" & set "API_SHA1=" & set "API_MD5=" & set "API_MD5_URL=" & set "API_ERROR="
set "PS_CMD=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288; !PS_CMD!"
for /f "tokens=1,* delims==" %%A in ('%PS_BIN% -NoProfile -Command "!PS_CMD!"') do (
    if "%%A"=="API_URL" set "API_URL=%%B"
    if "%%A"=="API_VERSION" set "API_RESOLVED_VER=%%B"
    if "%%A"=="API_SHA256" set "API_SHA256=%%B"
    if "%%A"=="API_SHA256_URL" set "API_SHA256_URL=%%B"
    if "%%A"=="API_SHA1" set "API_SHA1=%%B"
    if "%%A"=="API_MD5" set "API_MD5=%%B"
    if "%%A"=="API_MD5_URL" set "API_MD5_URL=%%B"
    if "%%A"=="API_ERROR" set "API_ERROR=%%B"
)

if defined API_ERROR (
    set "API_ERR_TYPE=0"
    for /f "delims=" %%E in ('%PS_BIN% -NoProfile -Command "if ($env:API_ERROR -match '429|403|rate limit') { 1 } elseif ($env:API_ERROR -match '500|502|503|504|server') { 2 } else { 0 }"') do set "API_ERR_TYPE=%%E"
    if "!API_ERR_TYPE!"=="1" (
        echo %cYELLOW%[ WARN   ]%cRESET% Upstream API rate limit reached ^(HTTP 429/403^). Please wait or retry later.
    ) else if "!API_ERR_TYPE!"=="2" (
        echo %cRED%[ ERROR  ]%cRESET% Upstream vendor API server is temporarily unavailable.
    ) else (
        echo %cRED%[ ERROR  ]%cRESET% Network connection failed. You appear to be offline.
    )
    echo %cYELLOW%[ DETAIL ]%cRESET% !API_ERROR!
    if "!CLI_COMMAND!"=="" pause
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
if "!API_URL!"=="" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to find !DL_VENDOR! JDK !DL_VERSION!. The version might not exist.
    if "!CLI_COMMAND!"=="" pause
    set "JVM_EXIT_CODE=1"
    exit /b 1
)

if defined API_RESOLVED_VER if "!API_RESOLVED_VER!" NEQ "!DL_VERSION!" (
    call :ValidateStrictIdentifier "!API_RESOLVED_VER!" API_RESOLVED_VER
    if not errorlevel 1 (
        echo.
        echo %cBLUE%[  INFO  ]%cRESET% !DL_VENDOR! does not publish JDK !DL_VERSION!.
        echo            Auto-falling back to latest available release: JDK !API_RESOLVED_VER!...
        set "DL_VERSION=!API_RESOLVED_VER!"
        if "!IS_UPDATER!" NEQ "1" (
            set "EXISTING_FALLBACK_PATH="
            for /l %%k in (1,1,!JDK_COUNT!) do (
                if "!JDK_MAJOR_%%k!"=="!DL_VERSION!" (
                    if /i "!JDK_VENDOR_%%k!"=="!CLI_VENDOR!" (
                        set "EXISTING_FALLBACK_PATH=!JDK_PATH_%%k!"
                    )
                )
            )
            if defined EXISTING_FALLBACK_PATH (
                echo.
                echo %cYELLOW%[ WARNING]%cRESET% !CLI_VENDOR! JDK !DL_VERSION! is already installed on your system:
                echo            - !EXISTING_FALLBACK_PATH!
                echo.
                if "!FORCE_YES!"=="1" (
                    echo %cBLUE%[  INFO  ]%cRESET% Reinstalling/overwriting due to --yes flag...
                ) else (
                    "%CHOICE_BIN%" /C yn /N /M "Would you like to reinstall and overwrite it? (y/N): "
                    if !errorlevel! NEQ 1 (
                        echo %cBLUE%[  INFO  ]%cRESET% Installation cancelled.
                        if "!CLI_COMMAND!"=="" pause
                        set "JVM_EXIT_CODE=0"
                        exit /b 0
                    )
                )
            )
        )
    )
)

if "!IS_LOCKING_ONLY!"=="1" goto :FinishLockResolution
goto :FetchAndExtract

:FetchLatestVersions
if defined ORACLE_LATEST_FEATURE goto :eof
if "%JVM_OFFLINE%"=="1" (
    set "ORACLE_LATEST_FEATURE=26"
    set "ORACLE_LATEST_LTS=25"
    set "REL_ADOPTIUM=26"
    goto :eof
)
set "PS_CMD=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288; $ProgressPreference = 'SilentlyContinue'; try { $res = Invoke-RestMethod -Uri 'https://api.adoptium.net/v3/info/available_releases' -UseBasicParsing -TimeoutSec 5; $f = [int]$res.most_recent_feature_release; $l = [int]$res.most_recent_lts; if ($f -ge 8 -and $l -ge 8) { Write-Output ('LATEST_FEATURE='+$f); Write-Output ('LATEST_LTS='+$l) } else { throw 'invalid' } } catch { Write-Output 'LATEST_FEATURE=26'; Write-Output 'LATEST_LTS=25' }"
for /f "tokens=1,* delims==" %%A in ('%PS_BIN% -NoProfile -Command "!PS_CMD!"') do (
    if "%%A"=="LATEST_FEATURE" set "ORACLE_LATEST_FEATURE=%%B"
    if "%%A"=="LATEST_LTS" set "ORACLE_LATEST_LTS=%%B"
)
set "REL_ADOPTIUM=!ORACLE_LATEST_FEATURE!"
call :ValidateStrictIdentifier "!REL_ADOPTIUM!" REL_ADOPTIUM
call :ValidateStrictIdentifier "!ORACLE_LATEST_LTS!" ORACLE_LATEST_LTS
goto :eof

:FetchAndExtract
setlocal enabledelayedexpansion
call :AcquireStateLock
if errorlevel 1 (
    endlocal & set "JVM_EXIT_CODE=1" & exit /b 1
)
for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "DL_RANDOM_NAME=%%A"
set "ZIP_PATH=%JVM_SECURE_TEMP%\jdk_!DL_VENDOR!_!DL_VERSION!_!DL_RANDOM_NAME!_download.zip"
set "EXTRACT_DIR=%JVM_SECURE_TEMP%\jdk_!DL_VENDOR!_!DL_VERSION!_!DL_RANDOM_NAME!_extract"
set "DEST_DIR=!JVM_PF!\Java"

if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!"

rem Map variables to Universal Downloader
set "DL_URL=!API_URL!"
set "DL_ZIP=!ZIP_PATH!"
set "DL_EXTRACT=!EXTRACT_DIR!"
set "DL_CHKSUM_URL=!API_SHA256_URL!"
set "DL_CHKSUM_VAL=!API_SHA256!"
set "DL_CHKSUM_TYPE=SHA256"
if defined API_SHA1 (
    set "DL_CHKSUM_VAL=!API_SHA1!"
    set "DL_CHKSUM_TYPE=SHA1"
)
if defined API_MD5_URL (
    set "DL_CHKSUM_URL=!API_MD5_URL!"
    set "DL_CHKSUM_TYPE=MD5"
)
if defined API_MD5 (
    set "DL_CHKSUM_VAL=!API_MD5!"
    set "DL_CHKSUM_TYPE=MD5"
)
set "DL_STRIP_ROOT=0"

call :ExecuteSharedDownloader
if !errorlevel! NEQ 0 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% The installation failed.
    if exist "!ZIP_PATH!" del /f /q "!ZIP_PATH!" >nul 2>&1
    if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!" >nul 2>&1
    if "!CLI_COMMAND!"=="" pause
    call :ReleaseStateLock
    endlocal & set "JVM_EXIT_CODE=1" & exit /b 1
)

:DoElevatedJdkInstall
set "NEW_FOLDER="
set "ROOT_COUNT=0"
for /d %%D in ("!EXTRACT_DIR!\*") do (
    set "NEW_FOLDER=%%~nxD"
    set /a ROOT_COUNT+=1
)

if !ROOT_COUNT! EQU 0 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Could not locate the extracted JDK folder.
    if exist "!ZIP_PATH!" del /f /q "!ZIP_PATH!" >nul 2>&1
    if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!" >nul 2>&1
    if "!CLI_COMMAND!"=="" pause
    call :ReleaseStateLock
    endlocal & set "JVM_EXIT_CODE=1" & exit /b 1
)

if !ROOT_COUNT! GTR 1 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Invalid archive structure: Multiple root folders detected in the ZIP.
    echo %cYELLOW%[ DETAIL ]%cRESET% Expected exactly 1 root folder, but found !ROOT_COUNT!.
    if exist "!ZIP_PATH!" del /f /q "!ZIP_PATH!" >nul 2>&1
    if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!" >nul 2>&1
    if "!CLI_COMMAND!"=="" pause
    call :ReleaseStateLock
    endlocal & set "JVM_EXIT_CODE=1" & exit /b 1
)

call :ValidateStrictIdentifier "!NEW_FOLDER!" NEW_FOLDER
if errorlevel 1 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Security validation failed: Malformed folder name extracted from archive.
    if exist "!ZIP_PATH!" del /f /q "!ZIP_PATH!" >nul 2>&1
    if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!" >nul 2>&1
    if "!CLI_COMMAND!"=="" pause
    call :ReleaseStateLock
    endlocal & set "JVM_EXIT_CODE=1" & exit /b 1
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Installing !NEW_FOLDER! to system directory...
"%PS_BIN%" -NoProfile -Command "$d = $env:DEST_DIR; $f = $env:NEW_FOLDER; $e = $env:EXTRACT_DIR; $b64d = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($d)); $b64f = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($f)); $b64e = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($e)); $script = '$d = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''' + $b64d + ''')); $f = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''' + $b64f + ''')); $e = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''' + $b64e + ''')); if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }; $fullD = [System.IO.Path]::GetFullPath($d).TrimEnd(''\'') + ''\''; $t = [System.IO.Path]::GetFullPath((Join-Path $d $f)); if (-not $t.StartsWith($fullD, [System.StringComparison]::OrdinalIgnoreCase)) { throw ''Path traversal detected in destination folder'' }; $bak = $t + ''.jvm_bak_'' + [Guid]::NewGuid().ToString(''N''); if (Test-Path -LiteralPath $t) { Move-Item -LiteralPath $t -Destination $bak -Force }; try { Move-Item -LiteralPath (Join-Path $e $f) -Destination $d -Force; if (Test-Path -LiteralPath $bak) { Remove-Item -LiteralPath $bak -Recurse -Force -ErrorAction SilentlyContinue } } catch { if (Test-Path -LiteralPath $bak) { if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }; Move-Item -LiteralPath $bak -Destination $t -Force -ErrorAction SilentlyContinue }; throw } finally { if (Test-Path -LiteralPath $e) { Remove-Item -LiteralPath $e -Recurse -Force -ErrorAction SilentlyContinue } }'; $enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($script)); $s = [Environment]::GetFolderPath([Environment+SpecialFolder]::System); $ps = Join-Path $s 'WindowsPowerShell\v1.0\powershell.exe'; try { $p = Start-Process -FilePath $ps -Verb RunAs -WorkingDirectory $s -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-EncodedCommand', $enc); try { if ($p.ExitCode -ne 0) { exit $p.ExitCode } } finally { if ($null -ne $p) { $p.Dispose() } } } catch { exit 1 }" 2>nul
if exist "!ZIP_PATH!" del /f /q "!ZIP_PATH!" >nul 2>&1
if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!" >nul 2>&1

call :ReleaseStateLock
if exist "!DEST_DIR!\!NEW_FOLDER!\bin\java.exe" (
    echo.
    echo %cGREEN%[   OK   ]%cRESET% !DL_VENDOR! JDK !DL_VERSION! successfully installed!
    if "!FLAG_CREATE_LOCK!"=="1" (
        set "ENTRY_CANDIDATE=java"
        set "ENTRY_VENDOR=!DL_VENDOR!"
        set "ENTRY_VERSION=!DL_VERSION!"
        set "ENTRY_ARCH=!SYS_ARCH!"
        set "ENTRY_URL=!DL_URL!"
        set "ENTRY_CHKSUM_TYPE=!DL_CHKSUM_TYPE!"
        set "ENTRY_CHKSUM=!DL_CHKSUM_VAL!"
        call :WriteLockFileEntry
    )
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    endlocal & set "NEEDS_RESCAN=1" & exit /b 0
) else (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% The installation failed during the move operation.
    if "!CLI_COMMAND!"=="" pause
    endlocal & set "JVM_EXIT_CODE=1" & exit /b 1
)


rem ============================================================
rem PATH UPDATER
rem ============================================================
:UpdateSystemPath
if not defined CURRENT_JDK_PATH goto :eof
call :BackupRegistry
setlocal enabledelayedexpansion

echo            - De-bloating Phantom Oracle paths and injecting %%JAVA_HOME%%\bin natively...

if /i "!SWITCH_MODE!"=="DIRECT" (
    echo %cBLUE%[ ACTION ]%cRESET% Requesting Administrator privileges to update Machine Registry...
    
    rem Preserve existing User-level JAVA_HOME before removal so we can restore if UAC is declined
    set "PREV_HKCU_JH="
    for /f "tokens=2*" %%A in ('%REG_BIN% query "HKCU\Environment" /v JAVA_HOME 2^>nul') do set "PREV_HKCU_JH=%%B"
    "%REG_BIN%" delete "HKCU\Environment" /v JAVA_HOME /f >nul 2>&1
    
    "%PS_BIN%" -NoProfile -Command "$target = $env:CURRENT_JDK_PATH; $b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($target)); $script = '$target = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''' + $b64 + ''')); $p = [Environment]::GetEnvironmentVariable(''Path'', ''Machine''); $juncBin = Join-Path $env:LOCALAPPDATA ''DiamTek\JVM\current\bin''; $purges = @(''C:\Program Files\Common Files\Oracle\Java\javapath'', ''C:\Program Files (x86)\Common Files\Oracle\Java\javapath'', ''C:\ProgramData\Oracle\Java\javapath'', $juncBin, $target + ''\bin''); if ($p) { $clean = ($p -split '';'' | Where-Object { $_ -and $purges -notcontains $_.TrimEnd(''\'') -and $_.TrimEnd(''\'') -ne ''%%JAVA_HOME%%\bin'' }) -join '';''; $finalPath = ''%%JAVA_HOME%%\bin;'' + $clean; [Environment]::SetEnvironmentVariable(''JAVA_HOME'', $target, ''Machine''); Set-ItemProperty -Path ''HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'' -Name ''Path'' -Value $finalPath -Type ExpandString }'; $enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($script)); $s = [Environment]::GetFolderPath([Environment+SpecialFolder]::System); $ps = Join-Path $s 'WindowsPowerShell\v1.0\powershell.exe'; try { $proc = Start-Process -FilePath $ps -Verb RunAs -WorkingDirectory $s -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-EncodedCommand', $enc); try { if ($null -eq $proc -or $proc.ExitCode -ne 0) { exit 1 } } finally { if ($null -ne $proc) { $proc.Dispose() } } } catch { exit 1 }" 2>nul
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to update Machine JAVA_HOME and SYSTEM PATH ^(UAC declined or registry access denied^).
        if defined PREV_HKCU_JH (
            "%REG_BIN%" add "HKCU\Environment" /v JAVA_HOME /t REG_SZ /d "!PREV_HKCU_JH!" /f >nul 2>&1
        )
        endlocal & exit /b 1
    )
    
    echo %cGREEN%[   OK   ]%cRESET% JAVA_HOME and SYSTEM PATH updated successfully via UAC.
) else (
    echo %cBLUE%[ ACTION ]%cRESET% Updating USER PATH...
    set "SAFE_JDK_PATH=!CURRENT_JDK_PATH!"
    "%PS_BIN%" -NoProfile -Command "$p = [Environment]::GetEnvironmentVariable('Path', 'User'); $juncBin = Join-Path $env:LOCALAPPDATA 'DiamTek\JVM\current\bin'; $targetBin = Join-Path $env:SAFE_JDK_PATH 'bin'; $purges = @('C:\Program Files\Common Files\Oracle\Java\javapath', 'C:\Program Files (x86)\Common Files\Oracle\Java\javapath', 'C:\ProgramData\Oracle\Java\javapath', $juncBin, $targetBin); if ($p) { $clean = ($p -split ';' | Where-Object { $_ -and $purges -notcontains $_.TrimEnd('\') -and $_.TrimEnd('\') -ne '%%JAVA_HOME%%\bin' }) -join ';'; $finalPath = '%%JAVA_HOME%%\bin;' + $clean } else { $finalPath = '%%JAVA_HOME%%\bin' }; Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $finalPath -Type ExpandString"
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to update USER PATH.
        endlocal & exit /b 1
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% USER PATH updated successfully.
    )
)

echo.
echo %cGREEN%[   OK   ]%cRESET% PATH update complete.
endlocal & exit /b 0

rem ============================================================
rem UPDATE CHANNEL HANDLER
rem ============================================================
:HandleChannelCommand
if "%~1"=="" (
    if /i "!UPDATE_CHANNEL!"=="NIGHTLY" (
        echo Current Update Channel: %cPURPLE%[Nightly]%cRESET%
        echo Description: Receiving cutting-edge builds directly from the 'main' branch.
    ) else (
        echo Current Update Channel: %cGREEN%[Stable]%cRESET%
        echo Description: Receiving official tagged releases ^(Recommended^).
    )
    echo.
    echo Usage:
    echo   jvm channel stable    - Switch to %cGREEN%[Stable]%cRESET% official releases channel
    echo   jvm channel nightly   - Switch to %cPURPLE%[Nightly]%cRESET% cutting-edge main branch channel
    goto :eof
)
if /i "%~1"=="stable" (
    set "UPDATE_CHANNEL=STABLE"
    call :WriteConfigFile "%LOCALAPPDATA%\DiamTek\JVM\channel.txt" "STABLE"
    if errorlevel 1 (
        set "JVM_EXIT_CODE=1"
        goto :eof
    )
    echo %cGREEN%[   OK   ]%cRESET% Switched update channel to %cGREEN%[Stable]%cRESET% ^(Official Releases^).
    goto :eof
)
if /i "%~1"=="nightly" (
    set "UPDATE_CHANNEL=NIGHTLY"
    call :WriteConfigFile "%LOCALAPPDATA%\DiamTek\JVM\channel.txt" "NIGHTLY"
    if errorlevel 1 (
        set "JVM_EXIT_CODE=1"
        goto :eof
    )
    echo %cGREEN%[   OK   ]%cRESET% Switched update channel to %cPURPLE%[Nightly]%cRESET% ^(Cutting-edge main branch^).
    goto :eof
)
echo %cRED%[ ERROR  ]%cRESET% Unknown channel '%~1'. Valid options are 'stable' or 'nightly'.
set "JVM_EXIT_CODE=1"
goto :eof

rem ============================================================
rem CLEAR JAVA ENVIRONMENT
rem ============================================================
:ClearJavaEnvironment
setlocal enabledelayedexpansion
rem cls
echo ============================================================
echo               Clear Java Environment Variables
echo ============================================================
echo.
echo %cYELLOW%[ WARNING ]%cRESET% You are about to remove JAVA_HOME and clean all Java paths
echo             from your SYSTEM and USER environment variables.
echo             Your installed JDK files will NOT be deleted.
echo.
if "!FORCE_YES!"=="1" goto :CONFIRMED_CLEAR
"%CHOICE_BIN%" /C yn /N /M "Are you sure you want to proceed? (y/N): "
if !errorlevel! NEQ 1 (
    endlocal
    goto :eof
)
:CONFIRMED_CLEAR
call :AcquireStateLock
if errorlevel 1 (
    endlocal
    goto :eof
)

rem Create Registry Backups Before Destructive Scrubbing
echo %cBLUE%[ ACTION ]%cRESET% Creating redundant registry backups...
call :BackupRegistry

echo.
echo %cBLUE%[ ACTION ]%cRESET% Removing JAVA_HOME and Ecosystem variables from registry...
"%REG_BIN%" delete "HKCU\Environment" /v JAVA_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v MAVEN_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v GRADLE_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v KOTLIN_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v SCALA_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v GROOVY_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v ANT_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v SBT_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v JBANG_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v QUARKUS_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v SPRING_HOME /f >nul 2>&1
"%REG_BIN%" delete "HKCU\Environment" /v MICRONAUT_HOME /f >nul 2>&1

echo %cBLUE%[ ACTION ]%cRESET% Removing active directory junctions...
rmdir "%LOCALAPPDATA%\DiamTek\JVM\current" >nul 2>&1
for /d %%C in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\*") do (
    rmdir "%%C\current" >nul 2>&1
)

rem Safely gather paths to purge to prevent catastrophic '\bin' wiping if variables are empty
set PURGE_PATHS="%LOCALAPPDATA%\DiamTek\JVM\current\bin" "%%JAVA_HOME%%\bin" "C:\Program Files\Common Files\Oracle\Java\javapath" "C:\Program Files (x86)\Common Files\Oracle\Java\javapath" "C:\ProgramData\Oracle\Java\javapath"
if defined JAVA_HOME set PURGE_PATHS=!PURGE_PATHS! "!JAVA_HOME!\bin"
for /l %%k in (1,1,!JDK_COUNT!) do set PURGE_PATHS=!PURGE_PATHS! "!JDK_PATH_%%k!\bin"

rem Format purges as semicolon-delimited lists to avoid space-splitting and quotation issues
set "ENV_PURGE_LIST=%LOCALAPPDATA%\DiamTek\JVM\current\bin;%%JAVA_HOME%%\bin;C:\Program Files\Common Files\Oracle\Java\javapath;C:\Program Files (x86)\Common Files\Oracle\Java\javapath;C:\ProgramData\Oracle\Java\javapath"
if defined JAVA_HOME set "ENV_PURGE_LIST=!ENV_PURGE_LIST!;!JAVA_HOME!\bin"
for /l %%k in (1,1,!JDK_COUNT!) do set "ENV_PURGE_LIST=!ENV_PURGE_LIST!;!JDK_PATH_%%k!\bin"

rem Clean SYSTEM PATH
echo %cBLUE%[ ACTION ]%cRESET% Cleaning SYSTEM PATH...
set "SYS_PATH="
for /f "tokens=2*" %%A in ('%REG_BIN% query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
if defined SYS_PATH (
    set "CLEAN_SYS_PATH="
    for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "$purges = $env:ENV_PURGE_LIST -split ';' | Where-Object { $_ } | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') }; $p = [Environment]::GetEnvironmentVariable('Path', 'Machine'); if ($p) { ($p -split ';' | Where-Object { $_ -and $purges -notcontains $_.TrimEnd('\') -and $_.TrimEnd('\') -ne '%%JAVA_HOME%%\bin' }) -join ';' }"') do set "CLEAN_SYS_PATH=%%A"
    
    if defined CLEAN_SYS_PATH (
        echo %cBLUE%[ ACTION ]%cRESET% Requesting Administrator privileges to clear Machine Registry...
        set "SYS_PATH=!CLEAN_SYS_PATH!"
        "%PS_BIN%" -NoProfile -Command "$sysPath = $env:SYS_PATH; $b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($sysPath)); $script = '$sysPath = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''' + $b64 + ''')); [Environment]::SetEnvironmentVariable(''JAVA_HOME'', $null, ''Machine''); Set-ItemProperty -Path ''HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'' -Name ''Path'' -Value $sysPath -Type ExpandString'; $enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($script)); $s = [Environment]::GetFolderPath([Environment+SpecialFolder]::System); $ps = Join-Path $s 'WindowsPowerShell\v1.0\powershell.exe'; try { $p = Start-Process -FilePath $ps -Verb RunAs -WorkingDirectory $s -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-EncodedCommand', $enc); try { if ($p.ExitCode -ne 0) { exit $p.ExitCode } } finally { if ($null -ne $p) { $p.Dispose() } } } catch { exit 1 }" 2>nul
    )
)

rem Clean USER PATH
echo %cBLUE%[ ACTION ]%cRESET% Cleaning USER PATH...
set "USR_PATH="
for /f "tokens=2*" %%A in ('%REG_BIN% query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
if defined USR_PATH (
    set "CLEAN_USR_PATH="
    set "ENV_USR_PURGE=!ENV_PURGE_LIST!;%%MAVEN_HOME%%\bin;%%GRADLE_HOME%%\bin;%%KOTLIN_HOME%%\bin;%%SCALA_HOME%%\bin;%%GROOVY_HOME%%\bin;%%ANT_HOME%%\bin;%%SBT_HOME%%\bin;%%JBANG_HOME%%\bin;%%QUARKUS_HOME%%\bin;%%SPRING_HOME%%\bin;%%MICRONAUT_HOME%%\bin"
    for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "$purges = $env:ENV_USR_PURGE -split ';' | Where-Object { $_ } | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') }; $p = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($p) { ($p -split ';' | Where-Object { $_ -and $purges -notcontains $_.TrimEnd('\') -and $_.TrimEnd('\') -ne '%%JAVA_HOME%%\bin' }) -join ';' }"') do set "CLEAN_USR_PATH=%%A"

    if defined CLEAN_USR_PATH (
        set "USR_PATH=!CLEAN_USR_PATH!"
        "%PS_BIN%" -NoProfile -Command "Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $env:USR_PATH -Type ExpandString"
    )
)

rem Clean active session variables
echo %cBLUE%[ ACTION ]%cRESET% Cleaning current session environment...
set "SESS_PURGE_LIST=!ENV_PURGE_LIST!"
if defined MAVEN_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!MAVEN_HOME!\bin"
if defined GRADLE_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!GRADLE_HOME!\bin"
if defined KOTLIN_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!KOTLIN_HOME!\bin"
if defined SCALA_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!SCALA_HOME!\bin"
if defined GROOVY_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!GROOVY_HOME!\bin"
if defined ANT_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!ANT_HOME!\bin"
if defined SBT_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!SBT_HOME!\bin"
if defined JBANG_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!JBANG_HOME!\bin"
if defined QUARKUS_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!QUARKUS_HOME!\bin"
if defined SPRING_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!SPRING_HOME!\bin"
if defined MICRONAUT_HOME set "SESS_PURGE_LIST=!SESS_PURGE_LIST!;!MICRONAUT_HOME!\bin"

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "$purges = $env:SESS_PURGE_LIST -split ';' | Where-Object { $_ } | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') }; ($env:PATH -split ';' | Where-Object { $_ -and $purges -notcontains $_.TrimEnd('\') }) -join ';'"') do set "CLEAN_PATH=%%A"

rem Export active session path
call :ReleaseStateLock
for /f "delims=" %%A in ("!CLEAN_PATH!") do (
    endlocal & set "PATH=%%~A" & set "JAVA_HOME=" & set "MAVEN_HOME=" & set "GRADLE_HOME=" & set "KOTLIN_HOME=" & set "SCALA_HOME=" & set "GROOVY_HOME=" & set "ANT_HOME=" & set "SBT_HOME=" & set "JBANG_HOME=" & set "QUARKUS_HOME=" & set "SPRING_HOME=" & set "MICRONAUT_HOME="
)
echo %cGREEN%[   OK   ]%cRESET% Java environment variables cleared.
echo            Your terminal will automatically sync when you exit the menu.
if not defined CLI_COMMAND (
    echo.
    echo Press any key to return to the menu...
    pause >nul
)
goto :eof

rem ============================================================
rem PATH & ENVIRONMENT SUB-MENU
rem ============================================================
:PathEnvironmentMenu
rem cls
echo ============================================================
echo             Path ^& Environment Management
echo ============================================================
echo.
if not defined JAVA_HOME (
    echo %cBLUE%[  INFO  ]%cRESET% JAVA_HOME is not currently set.
) else (
    echo %cBLUE%[  INFO  ]%cRESET% Current JAVA_HOME: !JAVA_HOME!
)
echo.
echo Current Java information:
echo ============================================================
set "DISCOVERED_JAVA="
    for /f "delims=" %%A in ('%WHERE_BIN% java 2^>nul') do (
        if not defined DISCOVERED_JAVA set "DISCOVERED_JAVA=%%A"
    )
    if not defined DISCOVERED_JAVA (
        echo %cYELLOW%[ WARNING]%cRESET% Java is NOT in PATH or not installed
        echo %cBLUE%[  INFO  ]%cRESET% This is normal if Java was just removed from PATH
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% Java is in PATH: !DISCOVERED_JAVA!
        echo.
        for /f "delims=" %%A in ('"!DISCOVERED_JAVA!" -version 2^>^&1') do echo %%A
    )
echo ============================================================
echo.

if !JDK_COUNT!==0 (
    echo %cYELLOW%[ WARNING]%cRESET% No Java installations found.
    pause
    goto :eof
)

set /a P_OPT=0
set "OPT_P_ORACLE="
set "OPT_P_ADOPTIUM="
set "OPT_P_GRAALVM="

set "HAS_ORACLE=0"
set "HAS_ADOPTIUM=0"
set "HAS_GRAALVM=0"
set "HAS_CORRETTO=0"
set "HAS_ZULU=0"
set "HAS_MICROSOFT=0"
set "HAS_LIBERICA=0"
set "HAS_SEMERU=0"
set "HAS_SAPMACHINE=0"
set "HAS_MANDREL=0"
set "HAS_DRAGONWELL=0"
set "HAS_KONA=0"
set "HAS_CUSTOM=0"

for /l %%k in (1,1,!JDK_COUNT!) do (
    if /i "!JDK_VENDOR_%%k!"=="Oracle" set "HAS_ORACLE=1"
    if /i "!JDK_VENDOR_%%k!"=="Adoptium" set "HAS_ADOPTIUM=1"
    if /i "!JDK_VENDOR_%%k!"=="GraalVM" set "HAS_GRAALVM=1"
    if /i "!JDK_VENDOR_%%k!"=="Corretto" set "HAS_CORRETTO=1"
    if /i "!JDK_VENDOR_%%k!"=="Zulu" set "HAS_ZULU=1"
    if /i "!JDK_VENDOR_%%k!"=="Microsoft" set "HAS_MICROSOFT=1"
    if /i "!JDK_VENDOR_%%k!"=="Liberica" set "HAS_LIBERICA=1"
    if /i "!JDK_VENDOR_%%k!"=="Semeru" set "HAS_SEMERU=1"
    if /i "!JDK_VENDOR_%%k!"=="SapMachine" set "HAS_SAPMACHINE=1"
    if /i "!JDK_VENDOR_%%k!"=="Mandrel" set "HAS_MANDREL=1"
    if /i "!JDK_VENDOR_%%k!"=="Dragonwell" set "HAS_DRAGONWELL=1"
    if /i "!JDK_VENDOR_%%k!"=="Kona" set "HAS_KONA=1"
    if /i "!JDK_VENDOR_%%k!"=="Custom" set "HAS_CUSTOM=1"
)

echo Please select an option:
echo.
echo %cGRAY%--- Manage by Vendor ---%cRESET%
if "!HAS_ORACLE!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_ORACLE=!P_OPT!"
    echo !OPT_P_ORACLE!. Oracle
)
if "!HAS_ADOPTIUM!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_ADOPTIUM=!P_OPT!"
    echo !OPT_P_ADOPTIUM!. Adoptium
)
if "!HAS_GRAALVM!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_GRAALVM=!P_OPT!"
    echo !OPT_P_GRAALVM!. GraalVM
)
if "!HAS_CORRETTO!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_CORRETTO=!P_OPT!"
    echo !OPT_P_CORRETTO!. Corretto
)
if "!HAS_ZULU!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_ZULU=!P_OPT!"
    echo !OPT_P_ZULU!. Zulu
)
if "!HAS_MICROSOFT!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_MICROSOFT=!P_OPT!"
    echo !OPT_P_MICROSOFT!. Microsoft
)
if "!HAS_LIBERICA!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_LIBERICA=!P_OPT!"
    echo !OPT_P_LIBERICA!. Liberica
)
if "!HAS_SEMERU!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_SEMERU=!P_OPT!"
    echo !OPT_P_SEMERU!. Semeru
)
if "!HAS_SAPMACHINE!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_SAPMACHINE=!P_OPT!"
    echo !OPT_P_SAPMACHINE!. SapMachine
)
if "!HAS_MANDREL!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_MANDREL=!P_OPT!"
    echo !OPT_P_MANDREL!. Mandrel
)
if "!HAS_DRAGONWELL!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_DRAGONWELL=!P_OPT!"
    echo !OPT_P_DRAGONWELL!. Dragonwell
)
if "!HAS_KONA!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_KONA=!P_OPT!"
    echo !OPT_P_KONA!. Kona
)
if "!HAS_CUSTOM!"=="1" (
    set /a P_OPT+=1
    set "OPT_P_CUSTOM=!P_OPT!"
    echo !OPT_P_CUSTOM!. Custom (Local Links^)
)

echo.
echo %cGRAY%--- Global Actions ---%cRESET%
set /a P_OPT+=1
set "OPT_P_LATEST=!P_OPT!"
set "LATEST_ACTIVE_TAG="
if /i "!LATEST_JDK_PATH!"=="!RESOLVED_JAVA_HOME!" set "LATEST_ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
echo !OPT_P_LATEST!. Switch to the latest %cBLUE%JDK ^(JDK !LATEST_VER_NUM!^)%cRESET%!LATEST_ACTIVE_TAG!

set /a P_OPT+=1
set "OPT_P_CLEAR=!P_OPT!"
echo !OPT_P_CLEAR!. Clear Java from Environment Variables (De-activate)

echo.
echo %cGRAY%--- Actions ---%cRESET%
set /a P_OPT+=1
set "OPT_P_CANCEL=!P_OPT!"
echo !OPT_P_CANCEL!. Go back

set "ALLOWED_CHOICES=123456789abcdefghijklmnopqrstuvwxyz"
set "P_KEYS=!ALLOWED_CHOICES:~0,%P_OPT%!"

echo.
"%CHOICE_BIN%" /C !P_KEYS! /N /M "Select option (1-!P_OPT!): "
set "v_choice=!errorlevel!"

if !v_choice!==!OPT_P_CANCEL! goto :eof

if !v_choice!==!OPT_P_CLEAR! (
    set "CURRENT_JDK_PATH=CLEAR"
    goto :eof
)

if !v_choice!==!OPT_P_LATEST! (
    set "CURRENT_JDK_PATH=!LATEST_JDK_PATH!"
    goto :eof
)

if defined OPT_P_ORACLE if !v_choice!==!OPT_P_ORACLE! set "TARGET_VENDOR=Oracle"
if defined OPT_P_ADOPTIUM if !v_choice!==!OPT_P_ADOPTIUM! set "TARGET_VENDOR=Adoptium"
if defined OPT_P_GRAALVM if !v_choice!==!OPT_P_GRAALVM! set "TARGET_VENDOR=GraalVM"
if defined OPT_P_CORRETTO if !v_choice!==!OPT_P_CORRETTO! set "TARGET_VENDOR=Corretto"
if defined OPT_P_ZULU if !v_choice!==!OPT_P_ZULU! set "TARGET_VENDOR=Zulu"
if defined OPT_P_MICROSOFT if !v_choice!==!OPT_P_MICROSOFT! set "TARGET_VENDOR=Microsoft"
if defined OPT_P_LIBERICA if !v_choice!==!OPT_P_LIBERICA! set "TARGET_VENDOR=Liberica"
if defined OPT_P_SEMERU if !v_choice!==!OPT_P_SEMERU! set "TARGET_VENDOR=Semeru"
if defined OPT_P_SAPMACHINE if !v_choice!==!OPT_P_SAPMACHINE! set "TARGET_VENDOR=SapMachine"
if defined OPT_P_MANDREL if !v_choice!==!OPT_P_MANDREL! set "TARGET_VENDOR=Mandrel"
if defined OPT_P_DRAGONWELL if !v_choice!==!OPT_P_DRAGONWELL! set "TARGET_VENDOR=Dragonwell"
if defined OPT_P_KONA if !v_choice!==!OPT_P_KONA! set "TARGET_VENDOR=Kona"
if defined OPT_P_CUSTOM if !v_choice!==!OPT_P_CUSTOM! set "TARGET_VENDOR=Custom"

:PathEnvironmentMenu_Vendor
rem cls
echo ============================================================
echo             Path ^& Environment Management
echo ============================================================
echo.
echo Please select a !TARGET_VENDOR! JDK to set as active:
echo.

set "P_JDK_MAP="
set /a P_NUM=0
for /l %%k in (1,1,!JDK_COUNT!) do (
    if /i "!JDK_VENDOR_%%k!"=="!TARGET_VENDOR!" (
        set /a P_NUM+=1
        set "ACTIVE_TAG="
        if /i "!JDK_PATH_%%k!"=="!RESOLVED_JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
        echo !P_NUM!. Set Java to %cBLUE%JDK !JDK_MAJOR_%%k! ^(!JDK_NAME_%%k!^)%cRESET%  %cGRAY%[!JDK_PATH_%%k!]%cRESET%!ACTIVE_TAG!
        set "P_MAP_!P_NUM!=%%k"
    )
)
set /a P_CANCEL=!P_NUM! + 1
echo.
echo !P_CANCEL!. Back to Menu
echo.

:GET_P_CHOICE
if !P_CANCEL! GTR 9 goto GET_P_CHOICE_MANUAL

set "P_CHOICE_KEYS="
for /l %%k in (1,1,!P_CANCEL!) do set "P_CHOICE_KEYS=!P_CHOICE_KEYS!%%k"

"%CHOICE_BIN%" /C !P_CHOICE_KEYS! /N /M "Enter your choice (1-!P_CANCEL!): "
set "p_choice=!errorlevel!"

if !p_choice!==0 (
    echo.
    goto GET_P_CHOICE
)
goto PROCESS_P_CHOICE

:GET_P_CHOICE_MANUAL
set p_choice=
set /p p_choice="Enter your choice (1-!P_CANCEL!): "
::::::::::::::::::::
      if not defined p_choice goto PathEnvironmentMenu
      if "!p_choice!"=="" goto PathEnvironmentMenu
set "p_choice=!p_choice:"=!"
set "p_choice=!p_choice: =!"
if "!p_choice!"=="" goto GET_P_CHOICE_MANUAL
set "NUM_TEST="
if not "!p_choice!"=="!p_choice:;=!" set "NUM_TEST=;"
for /f "eol= delims=0123456789" %%A in ("!p_choice!") do set "NUM_TEST=%%A"
if defined NUM_TEST goto GET_P_CHOICE_MANUAL
if !p_choice! LSS 1 goto GET_P_CHOICE_MANUAL
if !p_choice! GTR !P_CANCEL! goto GET_P_CHOICE_MANUAL

:PROCESS_P_CHOICE
if !p_choice!==!P_CANCEL! goto PathEnvironmentMenu

set "GLOBAL_IDX=!P_MAP_%p_choice%!"
set "CURRENT_JDK_PATH=!JDK_PATH_%GLOBAL_IDX%!"
goto :eof


rem ============================================================
rem VERSION MANAGEMENT SUB-MENU
rem ============================================================
:VersionMenu
if "!NEEDS_RESCAN!"=="1" goto :eof
rem cls
echo ============================================================
echo                       Version Management
echo ============================================================
echo.
echo Please choose an option:
echo.
echo 1. Check for Updates for installed JDKs
echo 2. Download and Install a new JDK version
echo 3. Uninstall a JDK and clean environment variables
echo 4. Go back
echo.

"%CHOICE_BIN%" /C 1234 /N /M "Enter your choice (1-4): "
set "sub_choice=!errorlevel!"

if !sub_choice!==4 goto :eof
if !sub_choice!==1 (
    call :UpdateJDKs
    goto VersionMenu
)
if !sub_choice!==2 (
    call :InstallWizard_JDK
    goto VersionMenu
)
if !sub_choice!==3 (
    call :UninstallJDK
    goto VersionMenu
)

goto VersionMenu

rem ============================================================
rem INSTALL WIZARDS
rem ============================================================
:InstallWizard
echo ============================================================
echo                     Global Installer
echo ============================================================
echo.
echo %cBLUE%[ ACTION ]%cRESET% What would you like to install?
echo.
echo 1. JDK (Java Development Kit)
echo 2. Ecosystem Build Tool (Maven, Gradle, etc.)
echo.
echo 3. Cancel
echo.
"%CHOICE_BIN%" /C 123 /N /M "Enter your choice (1-3): "
if !errorlevel!==1 call :InstallWizard_JDK
if !errorlevel!==2 (
    set "ECO_SUB_MODE=INSTALL"
    call :EcosystemSelectTool
)
goto :eof

:InstallWizard_JDK
echo.
echo %cBLUE%[ ACTION ]%cRESET% Enter the JDK version you wish to install.
echo            ^(e.g., 8, 11, 17, 21, 22, 23, 24, 25, 26^)
echo            Type 'lts' for latest Long-Term Support
echo            Type 'latest' for the absolute newest release
echo            Type 'cancel' ^(or press Enter^) to return
echo.
set "TARGET_VER="
set /p "TARGET_VER=Enter version: "
::::::::::::::::::::
      if not defined TARGET_VER goto :eof
      if "!TARGET_VER!"=="" goto :eof
      if /i "!TARGET_VER!"=="c" goto :eof
      if /i "!TARGET_VER!"=="cancel" goto :eof
      if /i "!TARGET_VER!"=="q" goto :eof
      if /i "!TARGET_VER!"=="quit" goto :eof
      if /i "!TARGET_VER!"=="exit" goto :eof
      if /i "!TARGET_VER!"=="back" goto :eof
call :ValidateStrictIdentifier "!TARGET_VER!" TARGET_VER
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier.
    pause
    goto :eof
)
if /i "!TARGET_VER!"=="latest" (
    call :FetchLatestVersions
    set "TARGET_VER=!ORACLE_LATEST_FEATURE!"
) else if /i "!TARGET_VER!"=="lts" (
    call :FetchLatestVersions
    set "TARGET_VER=!ORACLE_LATEST_LTS!"
)
set "DL_VERSION=!TARGET_VER!"
set "CLI_VENDOR="
call :DownloadJDK_Headless
goto :eof

rem ============================================================
rem JDK UPDATER 
rem ============================================================
rem ============================================================
rem SHARED VENDOR MENU BUILDER
rem ============================================================
rem Sets TARGET_VENDOR based on user selection. Returns "CANCEL" if user backs out.
rem Requires JDK_COUNT and JDK_VENDOR_n to be populated.
:BuildVendorMenu
set "TARGET_VENDOR="
set /a BV_OPT=0
set "BV_OPT_ALL=" & set "BV_OPT_CANCEL="
set "BV_HAS_ORACLE=0" & set "BV_HAS_ADOPTIUM=0" & set "BV_HAS_GRAALVM=0"
set "BV_HAS_CORRETTO=0" & set "BV_HAS_ZULU=0" & set "BV_HAS_MICROSOFT=0"
set "BV_HAS_LIBERICA=0" & set "BV_HAS_SEMERU=0"
set "BV_HAS_SAPMACHINE=0" & set "BV_HAS_MANDREL=0" & set "BV_HAS_DRAGONWELL=0" & set "BV_HAS_KONA=0"

for /l %%k in (1,1,!JDK_COUNT!) do (
    for %%V in (Oracle Adoptium GraalVM Corretto Zulu Microsoft Liberica Semeru SapMachine Mandrel Dragonwell Kona) do (
        if /i "!JDK_VENDOR_%%k!"=="%%V" set "BV_HAS_%%V=1"
    )
)

if "%~1"=="SHOW_ALL" (
    set /a BV_OPT+=1
    set "BV_OPT_ALL=!BV_OPT!"
    echo.
    echo !BV_OPT!. All Installed JDKs
)
echo.
echo %cGRAY%--- Manage by Vendor ---%cRESET%
for %%V in (Oracle Adoptium GraalVM Corretto Zulu Microsoft Liberica Semeru SapMachine Mandrel Dragonwell Kona) do (
    if "!BV_HAS_%%V!"=="1" (
        set /a BV_OPT+=1
        set "BV_MAP_!BV_OPT!=%%V"
        echo !BV_OPT!. %%V
    )
)
echo.
echo %cGRAY%--- Actions ---%cRESET%
set /a BV_OPT_CANCEL=BV_OPT+1
echo !BV_OPT_CANCEL!. Go back
echo.

if !BV_OPT_CANCEL! GTR 9 goto GET_BV_CHOICE_MANUAL

set "BV_KEYS="
for /l %%k in (1,1,!BV_OPT_CANCEL!) do set "BV_KEYS=!BV_KEYS!%%k"
"%CHOICE_BIN%" /C !BV_KEYS! /N /M "Select option (1-!BV_OPT_CANCEL!): "
set "bv_choice=!errorlevel!"
goto PROCESS_BV_CHOICE

:GET_BV_CHOICE_MANUAL
set bv_choice=
set /p bv_choice="Select option (1-!BV_OPT_CANCEL!): "
if not defined bv_choice goto GET_BV_CHOICE_MANUAL
set "bv_choice=!bv_choice:"=!"
set "bv_choice=!bv_choice: =!"
if "!bv_choice!"=="" goto GET_BV_CHOICE_MANUAL
set "NUM_TEST="
if not "!bv_choice!"=="!bv_choice:;=!" set "NUM_TEST=;"
for /f "eol= delims=0123456789" %%A in ("!bv_choice!") do set "NUM_TEST=%%A"
if defined NUM_TEST goto GET_BV_CHOICE_MANUAL
if !bv_choice! LSS 1 goto GET_BV_CHOICE_MANUAL
if !bv_choice! GTR !BV_OPT_CANCEL! goto GET_BV_CHOICE_MANUAL

:PROCESS_BV_CHOICE
if !bv_choice!==!BV_OPT_CANCEL! (
    set "TARGET_VENDOR=CANCEL"
    goto :eof
)
if defined BV_OPT_ALL if !bv_choice!==!BV_OPT_ALL! (
    set "TARGET_VENDOR=ALL"
    goto :eof
)
set "TARGET_VENDOR=!BV_MAP_%bv_choice%!"
goto :eof

rem ============================================================
rem JDK UPDATE CHECKER
rem ============================================================
:UpdateJDKs
echo ============================================================
echo                     JDK Update Checker
echo ============================================================
echo.

if not "%~1"=="" (
    for %%A in (%~1) do call :ProcessSingleUpdate %%A
    goto FINISH_UPDATE
)

if !JDK_COUNT!==0 (
    echo %cYELLOW%[ WARNING]%cRESET% No JDKs found to update.
    pause
    goto :eof
)

echo %cBLUE%[ ACTION ]%cRESET% Select vendor to check for updates:
call :BuildVendorMenu SHOW_ALL
if "!TARGET_VENDOR!"=="CANCEL" goto :eof

echo.
if "!TARGET_VENDOR!"=="ALL" (
    echo %cBLUE%[ ACTION ]%cRESET% Checking ALL JDKs for updates...
    for /l %%k in (1,1,!JDK_COUNT!) do call :ProcessSingleUpdate %%k
) else (
    echo %cBLUE%[ ACTION ]%cRESET% Checking !TARGET_VENDOR! JDKs for updates...
    for /l %%k in (1,1,!JDK_COUNT!) do (
        if /i "!JDK_VENDOR_%%k!"=="!TARGET_VENDOR!" call :ProcessSingleUpdate %%k
    )
)

:FINISH_UPDATE
echo ------------------------------------------------------------
echo.
echo %cGREEN%[   OK   ]%cRESET% All update checks complete!
echo.
pause
goto :eof

:ProcessSingleUpdate
set "UP_IDX=%1"
set "UP_PATH=!JDK_PATH_%UP_IDX%!"
set "UP_MAJOR=!JDK_MAJOR_%UP_IDX%!"
set "UP_NAME=!JDK_NAME_%UP_IDX%!"
set "UP_VENDOR=!JDK_VENDOR_%UP_IDX%!"

echo ------------------------------------------------------------
echo %cBLUE%[ ACTION ]%cRESET% Analyzing !UP_NAME! ^(!UP_VENDOR!^)...

set "VENDOR_SUPPORTED="
for %%V in (Oracle Adoptium GraalVM Corretto Zulu Microsoft Liberica Semeru SapMachine Mandrel Dragonwell Kona) do (
    if /i "!UP_VENDOR!"=="%%V" set "VENDOR_SUPPORTED=1"
)
if not defined VENDOR_SUPPORTED (
    echo %cYELLOW%[ WARNING]%cRESET% Vendor '!UP_VENDOR!' has no update source. Skipping.
    echo %cBLUE%[  INFO  ]%cRESET% Manually managed or linked JDKs must be updated by hand.
    goto :eof
)

call :RequireNetwork
if errorlevel 1 goto :eof

echo %cBLUE%[  INFO  ]%cRESET% Checking vendor API for updates...

set "UPDATE_RESULT=" & set "LOCAL_VER=" & set "REMOTE_VER="

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "UPD_RANDOM_NAME=%%A"
set "UPDATE_CHECKER_PS1=%JVM_SECURE_TEMP%\jvm_update_!UPD_RANDOM_NAME!.ps1"
(
    echo $ProgressPreference = 'SilentlyContinue'
    echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288
    echo $Vendor = $env:UP_VENDOR
    echo $Major = $env:UP_MAJOR
    echo $LocalPath = $env:UP_PATH
    echo if ^($Major -notmatch '^^\d+$'^) { Write-Output "ERROR|Invalid major version"; exit 1 }
    echo $localVersion = "UNKNOWN"
    echo $releaseFile = Join-Path $LocalPath "release"
    echo if ^(Test-Path -LiteralPath $releaseFile^) {
    echo     $content = Get-Content -LiteralPath $releaseFile -ErrorAction SilentlyContinue
    echo     $implVerLine = $content ^| Where-Object { $_ -match "^IMPLEMENTOR_VERSION=" } ^| Select-Object -First 1
    echo     $semVerLine = $content ^| Where-Object { $_ -match "^SEMANTIC_VERSION=" } ^| Select-Object -First 1
    echo     $javaVerLine = $content ^| Where-Object { $_ -match "^JAVA_VERSION=" } ^| Select-Object -First 1
    echo     $runtimeVerLine = $content ^| Where-Object { $_ -match "^JAVA_RUNTIME_VERSION=" } ^| Select-Object -First 1
    echo     if ^($Vendor -eq "Semeru" -and $implVerLine^) {
    echo         $raw = ^($implVerLine -split "=", 2^)[1].Trim^([char]34, [char]39, ' '^).TrimStart^('jdk-'^)
    echo         if ^($raw -match "([0-9]+[0-9A-Za-z._+-]*)"^) { $localVersion = $matches[1] }
    echo     } elseif ^($Vendor -eq "Corretto" -and $implVerLine^) {
    echo         $raw = ^($implVerLine -split "=", 2^)[1].Trim^([char]34, [char]39, ' '^).TrimStart^('Corretto-'^)
    echo         if ^($raw -match "([0-9]+[0-9A-Za-z._+-]*)"^) { $localVersion = $matches[1] }
    echo     } elseif ^($Vendor -eq "SapMachine" -and $implVerLine^) {
    echo         $raw = ^($implVerLine -split "=", 2^)[1].Trim^([char]34, [char]39, ' '^).TrimStart^('SapMachine-'^)
    echo         if ^($raw -match "([0-9]+[0-9A-Za-z._+-]*)"^) { $localVersion = $matches[1] }
    echo     } elseif ^($Vendor -eq "Mandrel" -and $implVerLine^) {
    echo         $raw = ^($implVerLine -split "=", 2^)[1].Trim^([char]34, [char]39, ' '^).TrimStart^('mandrel-'^)
    echo         if ^($raw -match "([0-9]+[0-9A-Za-z._+-]*)"^) { $localVersion = $matches[1] }
    echo     } elseif ^($Vendor -eq "Dragonwell" -and $implVerLine^) {
    echo         $raw = ^($implVerLine -split "=", 2^)[1].Trim^([char]34, [char]39, ' '^)
    echo         if ^($raw -match "([0-9]+[0-9A-Za-z._+-]*)"^) { $localVersion = $matches[1] }
    echo     } elseif ^($Vendor -eq "Kona" -and $implVerLine^) {
    echo         $raw = ^($implVerLine -split "=", 2^)[1].Trim^([char]34, [char]39, ' '^).TrimStart^('TencentKonaJDK-'^)
    echo         if ^($raw -match "([0-9]+[0-9A-Za-z._+-]*)"^) { $localVersion = $matches[1] }
    echo     } elseif ^($implVerLine^) {
    echo         $raw = ^($implVerLine -split "=", 2^)[1].Trim^([char]34, [char]39, ' '^)
    echo         if ^($raw -match "([0-9]+[0-9A-Za-z._+-]*)"^) { $localVersion = $matches[1] }
    echo     }
    echo     if ^($localVersion -eq "UNKNOWN" -or $localVersion -notmatch '\d'^) {
    echo         if ^($semVerLine^) {
    echo             $val = ^($semVerLine -split "=", 2^)[1].Trim^([char]34, [char]39, ' '^)
    echo             if ^($val -match '^^[0-9A-Za-z._+-]{1,64}$'^) { $localVersion = $val }
    echo         }
    echo     }
    echo     if ^($localVersion -eq "UNKNOWN" -or $localVersion -notmatch '\d'^) {
    echo         if ^($javaVerLine^) {
    echo             $val = ^($javaVerLine -split "=", 2^)[1].Trim^([char]34, [char]39, ' '^)
    echo             if ^($val -match '^^[0-9A-Za-z._+-]{1,64}$'^) { $localVersion = $val }
    echo         }
    echo     }
    echo     if ^($localVersion -eq "UNKNOWN" -or $localVersion -notmatch '\d'^) {
    echo         if ^($runtimeVerLine^) {
    echo             $val = ^($runtimeVerLine -split "=", 2^)[1].Trim^([char]34, [char]39, ' '^)
    echo             if ^($val -match '^^[0-9A-Za-z._+-]{1,64}$'^) { $localVersion = $val }
    echo         }
    echo     }
    echo     if ^($localVersion -notmatch '^^[0-9A-Za-z._+-]{1,64}$'^) { $localVersion = "UNKNOWN" }
    echo }
    echo if ^($localVersion -eq "UNKNOWN" -or $localVersion -notmatch '\d'^) {
    echo     $folderName = Split-Path $LocalPath -Leaf
    echo     if ^($folderName -match "([0-9]+[0-9A-Za-z._+-]*)"^) {
    echo         $cand = $matches[1]
    echo         if ^($cand -match '^^[0-9A-Za-z._+-]{1,64}$'^) { $localVersion = $cand }
    echo     }
    echo }
    echo $remoteVersion = "UNKNOWN"
    echo try {
    echo     if ^($Vendor -eq "Oracle"^) {
    echo         Write-Output "ORACLE_LEGACY"
    echo         exit 0
    echo     } elseif ^($Vendor -eq "Adoptium"^) {
    echo         $res = Invoke-RestMethod -Uri "https://api.adoptium.net/v3/assets/feature_releases/$Major/ga?architecture=$env:SYS_ARCH&image_type=jdk&jvm_impl=hotspot&os=windows&page=0&page_size=1" -UseBasicParsing -TimeoutSec 5
    echo         $remoteVersion = $res[0].version_data.openjdk_version.Replace^('-LTS', ''^)
    echo     } elseif ^($Vendor -eq "Corretto"^) {
    echo         $req = [Net.HttpWebRequest]::Create^("https://corretto.aws/downloads/latest/amazon-corretto-$Major-$env:SYS_ARCH-windows-jdk.zip"^)
    echo         $req.AllowAutoRedirect = $false
    echo         $req.Timeout = 5000
    echo         $res = $req.GetResponse^(^)
    echo         try { if ^($res.Headers["Location"] -match "resources/([^^/]+)/"^) { $remoteVersion = $matches[1] } } finally { $res.Close^(^) }
    echo     } elseif ^($Vendor -eq "GraalVM"^) {
    echo         $res = Invoke-RestMethod -Uri "https://api.github.com/repos/graalvm/graalvm-ce-builds/releases/latest" -UseBasicParsing -TimeoutSec 5
    echo         $remoteVersion = $res.tag_name -replace "^^jdk-", ""
    echo     } elseif ^($Vendor -eq "Zulu"^) {
    echo         $res = Invoke-RestMethod -Uri "https://api.azul.com/metadata/v1/zulu/packages/?java_version=$Major&os=windows&arch=$env:ZULU_ARCH&hw_bitness=64&archive_type=zip&java_package_type=jdk&latest=true" -UseBasicParsing -TimeoutSec 5
    echo         $remoteVersion = ^($res[0].java_version -join '.'^)
    echo     } elseif ^($Vendor -eq "Microsoft"^) {
    echo         $req = [Net.HttpWebRequest]::Create^("https://aka.ms/download-jdk/microsoft-jdk-$Major-windows-$env:SYS_ARCH.zip"^)
    echo         $req.AllowAutoRedirect = $false
    echo         $req.Timeout = 5000
    echo         $res = $req.GetResponse^(^)
    echo         try { if ^($res.Headers["Location"] -match "jdk-([^^/-]+)-"^) { $remoteVersion = $matches[1] } } finally { $res.Close^(^) }
    echo     } elseif ^($Vendor -eq "Liberica"^) {
    echo         $res = Invoke-RestMethod -Uri "https://api.bell-sw.com/v1/liberica/releases?version-feature=$Major&version-modifier=latest&bitness=64&os=windows&arch=$env:ZULU_ARCH&package-type=zip&bundle-type=jdk" -UseBasicParsing -TimeoutSec 5
    echo         if ^($res -and $res[0].version^) { $remoteVersion = $res[0].version }
    echo     } elseif ^($Vendor -eq "Semeru"^) {
    echo         $res = Invoke-RestMethod -Uri "https://api.github.com/repos/ibmruntimes/semeru$Major-binaries/releases/latest" -UseBasicParsing -TimeoutSec 5
    echo         if ^($res -and $res.tag_name^) { $remoteVersion = $res.tag_name -replace "^^jdk-", "" }
    echo     } elseif ^($Vendor -eq "SapMachine"^) {
    echo         $res = Invoke-RestMethod -Uri "https://sap.github.io/SapMachine/assets/data/sapmachine_releases.json" -UseBasicParsing -TimeoutSec 5
    echo         if ^($res.assets.$Major -and $res.assets.$Major.releases[0].jdk.'windows-x64' -match "sapmachine-(?:jdk-)?([0-9A-Za-z._+-]+)_windows"^) { $remoteVersion = $matches[1] }
    echo     } elseif ^($Vendor -eq "Mandrel"^) {
    echo         $found = $null
    echo         try {
    echo             $h = @{}; if ^($env:GITHUB_TOKEN^) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }
    echo             $res = Invoke-RestMethod -Uri "https://api.github.com/repos/graalvm/mandrel/releases" -Headers $h -UseBasicParsing -TimeoutSec 5
    echo             foreach ^($r in $res^) {
    echo                 if ^(-not $r.prerelease^) {
    echo                     $a = $r.assets ^| Where-Object { $_.name -like "mandrel-java$Major-windows-amd64-*.zip" } ^| Select-Object -First 1
    echo                     if ^($a -and $a.name -match "mandrel-java\d+-windows-amd64-([0-9A-Za-z._+-]+)\.zip"^) {
    echo                         $remoteVersion = $matches[1]; $found = $true; break
    echo                     }
    echo                 }
    echo             }
    echo         } catch { }
    echo         if ^(-not $found^) {
    echo             $wc = New-Object Net.WebClient; $wc.Headers['User-Agent'] = 'Mozilla/5.0'
    echo             $html = $wc.DownloadString^("https://github.com/graalvm/mandrel/releases"^)
    echo             $tags = [regex]::Matches^($html, '/graalvm/mandrel/releases/tag/^([a-zA-Z0-9._+-]+^)'^) ^| ForEach-Object { $_.Groups[1].Value } ^| Select-Object -Unique
    echo             foreach ^($t in $tags^) {
    echo                 $eHtml = $wc.DownloadString^("https://github.com/graalvm/mandrel/releases/expanded_assets/" + $t^)
    echo                 if ^($eHtml -match "mandrel-java$Major-windows-amd64-([0-9A-Za-z._+-]+)\.zip"^) {
    echo                     $remoteVersion = $matches[1]; break
    echo                 }
    echo             }
    echo         }
    echo     } elseif ^($Vendor -eq "Dragonwell"^) {
    echo         $tag = $null
    echo         try {
    echo             $h = @{}; if ^($env:GITHUB_TOKEN^) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }
    echo             $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/dragonwell-project/dragonwell$Major/releases/latest" -Headers $h -UseBasicParsing -TimeoutSec 5
    echo             if ^($rel.tag_name^) { $tag = $rel.tag_name }
    echo         } catch { }
    echo         if ^(-not $tag^) {
    echo             $req = [Net.HttpWebRequest]::Create^("https://github.com/dragonwell-project/dragonwell$Major/releases/latest"^)
    echo             $req.AllowAutoRedirect = $false
    echo             $req.UserAgent = 'Mozilla/5.0'
    echo             $req.Timeout = 5000
    echo             $res = $req.GetResponse^(^)
    echo             try { if ^($res.Headers["Location"] -match "/releases/tag/([a-zA-Z0-9._+-]+)$"^) { $tag = $matches[1] } } finally { $res.Close^(^) }
    echo         }
    echo         if ^($tag -and $tag -match "dragonwell-(?:standard-)?([0-9.]+)"^) {
    echo             $remoteVersion = $matches[1]
    echo         }
    echo     } elseif ^($Vendor -eq "Kona"^) {
    echo         $tag = $null
    echo         try {
    echo             $h = @{}; if ^($env:GITHUB_TOKEN^) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }
    echo             $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/Tencent/TencentKona-$Major/releases/latest" -Headers $h -UseBasicParsing -TimeoutSec 5
    echo             if ^($rel.tag_name^) { $tag = $rel.tag_name }
    echo         } catch { }
    echo         if ^(-not $tag^) {
    echo             $req = [Net.HttpWebRequest]::Create^("https://github.com/Tencent/TencentKona-$Major/releases/latest"^)
    echo             $req.AllowAutoRedirect = $false
    echo             $req.UserAgent = 'Mozilla/5.0'
    echo             $req.Timeout = 5000
    echo             $res = $req.GetResponse^(^)
    echo             try { if ^($res.Headers["Location"] -match "/releases/tag/([a-zA-Z0-9._+-]+)$"^) { $tag = $matches[1] } } finally { $res.Close^(^) }
    echo         }
    echo         if ^($tag -and $tag -match "TencentKona-([0-9A-Za-z._+-]+)"^) {
    echo             $remoteVersion = $matches[1]
    echo         }
    echo     }
    echo     if ^($remoteVersion -notmatch '^^[0-9A-Za-z._+-]{1,64}$'^) { $remoteVersion = "UNKNOWN" }
    echo } catch {
    echo     $msg = ^($_.Exception.Message -replace '[\r\n]+', ' '^)
    echo     if ^($env:LOCALAPPDATA^) { $msg = $msg.Replace^($env:LOCALAPPDATA, '%%LOCALAPPDATA%%'^) }
    echo     if ^($env:USERPROFILE^) { $msg = $msg.Replace^($env:USERPROFILE, '%%USERPROFILE%%'^) }
    echo     Write-Output "ERROR|$msg"
    echo     exit 1
    echo }
    echo Write-Output "LOCAL|$localVersion"
    echo Write-Output "REMOTE|$remoteVersion"
    echo $cleanLocal = $localVersion -replace '^^1\.8\.0_', '8.0.' -replace '[\+-].*$', ''
    echo $cleanRemote = $remoteVersion -replace '^^1\.8\.0_', '8.0.' -replace '[\+-].*$', ''
    echo if ^($localVersion -eq "UNKNOWN" -and $remoteVersion -eq "UNKNOWN"^) {
    echo     Write-Output "RESULT|UNKNOWN_BOTH"
    echo } elseif ^($localVersion -eq "UNKNOWN"^) {
    echo     Write-Output "RESULT|UNKNOWN_LOCAL"
    echo } elseif ^($remoteVersion -eq "UNKNOWN"^) {
    echo     Write-Output "RESULT|UNKNOWN_REMOTE"
    echo } elseif ^($cleanLocal -eq $cleanRemote^) {
    echo     Write-Output "RESULT|UP_TO_DATE"
    echo } else {
    echo     $lParts = @^($cleanLocal.Split^('.'^) ^| ForEach-Object { [int]^($_ -replace '\D.*$', ''^) }^)
    echo     $rParts = @^($cleanRemote.Split^('.'^) ^| ForEach-Object { [int]^($_ -replace '\D.*$', ''^) }^)
    echo     $len = [math]::Max^($lParts.Length, $rParts.Length^)
    echo     $diff = 0
    echo     for ^($i = 0; $i -lt $len; $i++^) {
    echo         $lp = if ^($i -lt $lParts.Length^) { $lParts[$i] } else { 0 }
    echo         $rp = if ^($i -lt $rParts.Length^) { $rParts[$i] } else { 0 }
    echo         if ^($lp -ne $rp^) { $diff = $lp - $rp; break }
    echo     }
    echo     if ^($diff -ge 0^) {
    echo         Write-Output "RESULT|UP_TO_DATE"
    echo     } else {
    echo         Write-Output "RESULT|UPDATE_AVAILABLE"
    echo     }
    echo }
) > "!UPDATE_CHECKER_PS1!"

set "API_ERROR="
set "IS_ORACLE_LEGACY=0"
for /f "tokens=1,* delims=|" %%A in ('%PS_BIN% -NoProfile -ExecutionPolicy Bypass -File "!UPDATE_CHECKER_PS1!"') do (
    if "%%A"=="ORACLE_LEGACY" set "IS_ORACLE_LEGACY=1"
    if "%%A"=="LOCAL" set "LOCAL_VER=%%B"
    if "%%A"=="REMOTE" set "REMOTE_VER=%%B"
    if "%%A"=="RESULT" set "UPDATE_RESULT=%%B"
    if "%%A"=="ERROR" set "API_ERROR=%%B"
)
if exist "!UPDATE_CHECKER_PS1!" del /f /q "!UPDATE_CHECKER_PS1!" >nul 2>&1
if "!IS_ORACLE_LEGACY!"=="1" goto :Update_OracleLegacy

if defined API_ERROR (
    if not "!API_ERROR:404=!"=="!API_ERROR!" (
        echo %cYELLOW%[ WARNING]%cRESET% No remote release found for !UP_VENDOR! JDK !UP_MAJOR! ^(HTTP 404^).
        echo %cBLUE%[  INFO  ]%cRESET% Vendor !UP_VENDOR! has not published a GA update build for JDK !UP_MAJOR!.
    ) else (
        echo %cRED%[ ERROR  ]%cRESET% Network connection failed. You appear to be offline.
        echo %cYELLOW%[ DETAIL ]%cRESET% !API_ERROR!
    )
    goto :eof
)

echo %cBLUE%[  INFO  ]%cRESET% Local Build Version : !LOCAL_VER!
echo %cBLUE%[  INFO  ]%cRESET% Remote API Version  : !REMOTE_VER!

if "!UPDATE_RESULT!"=="UNKNOWN_LOCAL" (
    echo %cRED%[ ERROR  ]%cRESET% Could not determine local build version from release metadata.
    goto :eof
)
if "!UPDATE_RESULT!"=="UNKNOWN_REMOTE" (
    echo %cRED%[ ERROR  ]%cRESET% Could not fetch update data from !UP_VENDOR!.
    goto :eof
)
if "!UPDATE_RESULT!"=="UNKNOWN_BOTH" (
    echo %cRED%[ ERROR  ]%cRESET% Could not fetch update data from !UP_VENDOR!.
    goto :eof
)
if "!UPDATE_RESULT!"=="UNKNOWN" (
    echo %cRED%[ ERROR  ]%cRESET% Could not fetch update data from !UP_VENDOR!.
    goto :eof
)
if "!UPDATE_RESULT!"=="UP_TO_DATE" (
    echo %cGREEN%[   OK   ]%cRESET% You are already running the latest build of JDK !UP_MAJOR!!
    goto :eof
)

echo %cYELLOW%[ UPDATE ]%cRESET% A newer build is available!
if not defined CLI_COMMAND (
    "%CHOICE_BIN%" /C yn /N /M "Would you like to download and install this update? (y/N): "
    if !errorlevel! NEQ 1 goto :eof
)
goto :TriggerUpdateDownload

:Update_OracleLegacy
set "PS_CMD=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288; $req = [Net.HttpWebRequest]::Create('https://download.oracle.com/java/!UP_MAJOR!/latest/jdk-!UP_MAJOR!_windows-!SYS_ARCH!_bin.zip'); $req.Method = 'HEAD'; $req.Timeout = 5000; $req.AllowAutoRedirect = $false; try { $res = $req.GetResponse(); $d = $res.LastModified.ToString('yyyy-MM-dd'); $res.Close(); $d } catch { 'ERROR|' + $_.Exception.Message }"
set "REMOTE_DATE=UNKNOWN" & set "API_ERROR="
for /f "tokens=1,* delims=|" %%A in ('%PS_BIN% -NoProfile -Command "!PS_CMD!"') do (
    if "%%A"=="ERROR" ( set "API_ERROR=%%B" ) else ( set "REMOTE_DATE=%%A" )
)
if defined API_ERROR (
    if not "!API_ERROR:404=!"=="!API_ERROR!" (
        echo %cYELLOW%[ WARNING]%cRESET% No remote release found for Oracle JDK !UP_MAJOR! ^(HTTP 404^).
        echo %cBLUE%[  INFO  ]%cRESET% Oracle has not published a GA update build for JDK !UP_MAJOR!.
    ) else (
        echo %cRED%[ ERROR  ]%cRESET% Network connection failed. You appear to be offline.
        echo %cYELLOW%[ DETAIL ]%cRESET% !API_ERROR!
    )
    goto :eof
)
set "LOCAL_DATE=UNKNOWN"
if exist "!UP_PATH!\release" (
    for /f "tokens=2 delims==" %%A in ('%FINDSTR_BIN% /b "JAVA_VERSION_DATE=" "!UP_PATH!\release"') do set "LOCAL_DATE=%%~A"
)
echo %cBLUE%[  INFO  ]%cRESET% Local Build Date : !LOCAL_DATE!
echo %cBLUE%[  INFO  ]%cRESET% Remote Build Date: !REMOTE_DATE!

if "!REMOTE_DATE!"=="UNKNOWN" ( echo %cRED%[ ERROR  ]%cRESET% Could not connect to Oracle servers. & goto :eof )
if "!LOCAL_DATE!"=="!REMOTE_DATE!" ( echo %cGREEN%[   OK   ]%cRESET% You are already running the latest build of JDK !UP_MAJOR!! & goto :eof )
if "!LOCAL_DATE!" NEQ "UNKNOWN" if "!LOCAL_DATE!" GTR "!REMOTE_DATE!" ( echo %cGREEN%[   OK   ]%cRESET% Your local build is newer than the current Oracle release! & goto :eof )

echo %cYELLOW%[ UPDATE ]%cRESET% A newer build is available!
if defined CLI_COMMAND (
    if /i "!CLI_TARGET!"=="" ( echo %cYELLOW%[ UPDATE ]%cRESET% Run 'jvm update !UP_MAJOR!' to install. & goto :eof )
) else (
    "%CHOICE_BIN%" /C yn /N /M "Would you like to download and install this update? (y/N): "
    if !errorlevel! NEQ 1 goto :eof
)

:TriggerUpdateDownload
set "VENDOR_SUPPORTED="
for %%V in (Oracle Adoptium GraalVM Corretto Zulu Microsoft Liberica Semeru SapMachine Mandrel Dragonwell Kona) do (
    if /i "!UP_VENDOR!"=="%%V" set "VENDOR_SUPPORTED=1"
)
if not defined VENDOR_SUPPORTED (
    echo %cRED%[ ERROR  ]%cRESET% No download source for vendor '!UP_VENDOR!'.
    goto :eof
)
echo.
echo %cGREEN%[DOWNLOAD]%cRESET% Fetching newest JDK !UP_MAJOR! from !UP_VENDOR!...
set "CLI_VENDOR=!UP_VENDOR!" & set "DL_VERSION=!UP_MAJOR!" & set "IS_UPDATER=1"
goto :Resolve_!UP_VENDOR!

rem ============================================================
rem JDK UNINSTALLER
rem ============================================================
:UninstallJDK
echo ============================================================
echo                     JDK Uninstaller
echo ============================================================
echo.
echo %cBLUE%[ ACTION ]%cRESET% Select vendor to uninstall from:
call :BuildVendorMenu
if "!TARGET_VENDOR!"=="CANCEL" goto :eof

echo.
echo Please select a !TARGET_VENDOR! JDK to PERMANENTLY remove:
set /a U_NUM=0
for /l %%k in (1,1,!JDK_COUNT!) do (
    if /i "!JDK_VENDOR_%%k!"=="!TARGET_VENDOR!" (
        set /a U_NUM+=1
        set "ACTIVE_TAG="
        if /i "!JDK_PATH_%%k!"=="!RESOLVED_JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
        echo !U_NUM!. Remove %cBLUE%JDK !JDK_MAJOR_%%k! ^(!JDK_NAME_%%k!^)%cRESET%  %cGRAY%[!JDK_PATH_%%k!]%cRESET%!ACTIVE_TAG!
        set "U_MAP_!U_NUM!=%%k"
    )
)
set /a U_CANCEL=U_NUM+1
echo.
echo !U_CANCEL!. Go back
echo.

if !U_CANCEL! GTR 9 (
    set u_choice=
    set /p u_choice="Enter your choice (1-!U_CANCEL!): "
::::::::::::::::::::
      if not defined u_choice goto :UninstallJDK
      if "!u_choice!"=="" goto :UninstallJDK
    set "u_choice=!u_choice:"=!"
    set "u_choice=!u_choice: =!"
    if "!u_choice!"=="" goto :UninstallJDK
    set "NUM_TEST="
    if not "!u_choice!"=="!u_choice:;=!" set "NUM_TEST=;"
    for /f "eol= delims=0123456789" %%A in ("!u_choice!") do set "NUM_TEST=%%A"
    if defined NUM_TEST goto :UninstallJDK
    if !u_choice! LSS 1 goto :UninstallJDK
    if !u_choice! GTR !U_CANCEL! goto :UninstallJDK
) else (
    set "U_CHOICE_KEYS="
    for /l %%k in (1,1,!U_CANCEL!) do set "U_CHOICE_KEYS=!U_CHOICE_KEYS!%%k"
    "%CHOICE_BIN%" /C !U_CHOICE_KEYS! /N /M "Enter your choice (1-!U_CANCEL!): "
    set "u_choice=!errorlevel!"
)
if !u_choice!==!U_CANCEL! goto :UninstallJDK

set "GLOBAL_IDX=!U_MAP_%u_choice%!"
set "DEL_PATH=!JDK_PATH_%GLOBAL_IDX%!"
set "DEL_NAME=!JDK_NAME_%GLOBAL_IDX%!"

echo.
echo %cYELLOW%[ WARNING ]%cRESET% You are about to permanently delete:
echo             !DEL_PATH!
echo             This action cannot be undone.
"%CHOICE_BIN%" /C yn /N /M "Are you sure you want to proceed? (y/N): "
if !errorlevel! NEQ 1 (
    echo.
    echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled. Returning to menu...
    "%TIMEOUT_BIN%" /t 2 >nul
    goto :eof
)

call :AcquireStateLock
if errorlevel 1 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Failed to acquire state lock for uninstallation.
    pause
    goto :eof
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Terminating Java processes running from this JDK...
"%PS_BIN%" -NoProfile -Command "Get-Process java,javaw -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($env:DEL_PATH, [StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1

echo %cBLUE%[ ACTION ]%cRESET% Deleting directory and scrubbing environment variables...
echo %cBLUE%[  INFO  ]%cRESET% Requesting administrative privileges to apply changes...
"%PS_BIN%" -NoProfile -Command "$del = $env:DEL_PATH; $b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($del)); $script = '$del = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''' + $b64 + ''')); Get-Process java,javaw -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($del, [StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force -ErrorAction SilentlyContinue; if (Test-Path -LiteralPath $del) { $it = Get-Item -LiteralPath $del -Force -ErrorAction SilentlyContinue; if ($it -and (($it.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)) { [System.IO.Directory]::Delete($it.FullName, $false) } else { Get-ChildItem -LiteralPath $del -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 } | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object { if ($_.PSIsContainer) { [System.IO.Directory]::Delete($_.FullName, $false) } else { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue } }; Remove-Item -LiteralPath $del -Recurse -Force -ErrorAction SilentlyContinue } }; $delBin = Join-Path $del ''bin''; $p = [Environment]::GetEnvironmentVariable(''Path'', ''Machine''); if ($p) { $clean = ($p -split '';'' | Where-Object { $_ -and $_.TrimEnd(''\'') -ne $delBin.TrimEnd(''\'') }) -join '';''; Set-ItemProperty -Path ''HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'' -Name ''Path'' -Value $clean -Type ExpandString }'; $enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($script)); $s = [Environment]::GetFolderPath([Environment+SpecialFolder]::System); $ps = Join-Path $s 'WindowsPowerShell\v1.0\powershell.exe'; try { $p = Start-Process -FilePath $ps -Verb RunAs -WorkingDirectory $s -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-EncodedCommand', $enc); try { if ($p.ExitCode -ne 0) { exit $p.ExitCode } } finally { if ($null -ne $p) { $p.Dispose() } } } catch { exit 1 }" 2>nul
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Administrator elevation was declined or uninstallation failed.
    pause
    call :ReleaseStateLock
    goto :eof
)

rem Clean User PATH preserving REG_EXPAND_SZ
set "DEL_BIN=!DEL_PATH!\bin"
"%PS_BIN%" -NoProfile -Command "$delBin = $env:DEL_BIN; $p = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($p) { $clean = ($p -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ne $delBin.TrimEnd('\') }) -join ';'; Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $clean -Type ExpandString }" >nul 2>&1

if not exist "%LOCALAPPDATA%\DiamTek\JVM\current\bin\java.exe" (
    rmdir "%LOCALAPPDATA%\DiamTek\JVM\current" >nul 2>&1
    "%REG_BIN%" delete "HKCU\Environment" /v JAVA_HOME /f >nul 2>&1
)

if exist "!DEL_PATH!" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to completely delete directory.
    echo             A file might be locked or in use by another program.
    pause
    call :ReleaseStateLock
    goto :eof
)

echo.
echo %cGREEN%[   OK   ]%cRESET% !DEL_NAME! was successfully uninstalled!
set "NEEDS_RESCAN=1"
if not exist "%LOCALAPPDATA%\DiamTek\JVM\current\bin\java.exe" (
    set "JAVA_HOME="
    echo %cYELLOW%[  INFO  ]%cRESET% The uninstalled JDK was currently active. JAVA_HOME has been cleared.
    echo            Please switch to another installed JDK version.
)
call :ReleaseStateLock
echo Press any key to return to the menu...
pause >nul
goto :eof

rem SETTINGS MENU
rem ============================================================
:SettingsMenu
rem cls
echo ============================================================
echo                             Settings
echo ============================================================
echo.

set "SCRIPT_DIR=%~dp0"
if "!SCRIPT_DIR:~-1!"=="\" set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"

set "IN_PATH=0"
set "USER_PATH="
for /f "tokens=2*" %%A in ('%REG_BIN% query "HKCU\Environment" /v Path 2^>nul') do (
    set "USER_PATH=%%B"
)

if defined USER_PATH (
    set "CLEAN_USER_PATH=!USER_PATH:"=!"
    set "TEST_PATH=;!CLEAN_USER_PATH!;"
    for %%D in ("!SCRIPT_DIR!") do (
        if "!TEST_PATH:;%%~D;=!" NEQ "!TEST_PATH!" set "IN_PATH=1"
        if "!TEST_PATH:;%%~D\;=!" NEQ "!TEST_PATH!" set "IN_PATH=1"
    )
    for %%D in ("%LOCALAPPDATA%\DiamTek\JVM\bin") do (
        if "!TEST_PATH:;%%~D;=!" NEQ "!TEST_PATH!" set "IN_PATH=1"
        if "!TEST_PATH:;%%~D\;=!" NEQ "!TEST_PATH!" set "IN_PATH=1"
    )
)

set "HOOK_IN_PROFILE=0"
for /f "delims=" %%P in ('%PS_BIN% -NoProfile -Command "$userProfile = [Environment]::GetFolderPath('UserProfile'); $myDocs = [Environment]::GetFolderPath('MyDocuments'); $docPaths = @($myDocs, (Join-Path $userProfile 'Documents')) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique; $p = @($PROFILE); foreach ($doc in $docPaths) { $p += (Join-Path $doc 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'); $p += (Join-Path $doc 'PowerShell\Microsoft.PowerShell_profile.ps1') }; foreach ($f in ($p | Select-Object -Unique)) { if ($f -and (Test-Path -LiteralPath $f) -and (Select-String -LiteralPath $f -Pattern '# >>> jvm >>>' -Quiet)) { Write-Output 'FOUND'; break } }" 2^>nul') do (
    if "%%P"=="FOUND" set "HOOK_IN_PROFILE=1"
)

echo Please choose an option:
echo.

if "!IN_PATH!"=="1" (
    echo 1. Remove JVM from User PATH ^(Global Command^) %cGREEN%[INSTALLED]%cRESET%
) else (
    echo 1. Install JVM to User PATH ^(Global Command^) %cYELLOW%[NOT INSTALLED]%cRESET%
)
if "!HOOK_IN_PROFILE!"=="1" (
    echo 2. Remove PowerShell Profile Hook %cGREEN%[INSTALLED]%cRESET%
) else (
    echo 2. Install PowerShell Profile Hook %cYELLOW%[NOT INSTALLED]%cRESET%
)
if /i "!SWITCH_MODE!"=="DIRECT" (
    echo 3. Architecture: %cRED%[Registry Mode]%cRESET% ^(UAC Required^) - Click to use Symlink
) else (
    echo 3. Architecture: %cGREEN%[Symlink Mode]%cRESET% ^(UAC Free^) - Click to use Registry
)
if /i "!UPDATE_CHANNEL!"=="NIGHTLY" (
    echo 4. Update Channel: %cPURPLE%[Nightly]%cRESET% ^(main branch^) - Click to use Stable
) else (
    echo 4. Update Channel: %cGREEN%[Stable]%cRESET% ^(Official Releases^) - Click to use Nightly
)
echo 5. About JVM ^& Updates
echo 6. %cRED%Uninstall JVM Completely%cRESET% ^(Full System Wipe^)
echo 7. Back to Main Menu
echo.

"%CHOICE_BIN%" /C 1234567 /N /M "Enter your choice (1-7): "
set "sub_choice=!errorlevel!"

if !sub_choice!==7 goto :eof
if !sub_choice!==6 (
    goto :UninstallJVM_Complete
)
if !sub_choice!==5 (
    call :AboutMenu
    goto :SettingsMenu
)
if !sub_choice!==4 (
    set "UPDATE_CHANNEL_OVERRIDE="
    if /i "!UPDATE_CHANNEL!"=="NIGHTLY" (
        set "TARGET_CH=STABLE"
        set "CH_NAME=%cGREEN%[Stable]%cRESET%"
    ) else (
        set "TARGET_CH=NIGHTLY"
        set "CH_NAME=%cPURPLE%[Nightly]%cRESET%"
    )
    call :WriteConfigFile "%LOCALAPPDATA%\DiamTek\JVM\channel.txt" "!TARGET_CH!"
    echo.
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to persist update channel configuration.
    ) else (
        set "UPDATE_CHANNEL=!TARGET_CH!"
        echo %cGREEN%[   OK   ]%cRESET% Switched update channel to !CH_NAME!.
    )
    "%TIMEOUT_BIN%" /t 2 >nul
    goto SettingsMenu
)
if !sub_choice!==3 (
    if /i "!SWITCH_MODE!"=="DIRECT" (
        set "TARGET_MODE=SYMLINK"
        echo.
        echo %cBLUE%[ ACTION ]%cRESET% Scrubbing Machine Registry to prevent Legacy override...
        set "SYS_PATH="
        for /f "tokens=2*" %%A in ('%REG_BIN% query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
        
        set "ENV_PURGE_LIST=!JVM_PF!\Common Files\Oracle\Java\javapath;!JVM_PF86!\Common Files\Oracle\Java\javapath;%ProgramData%\Oracle\Java\javapath"
        for /l %%k in (1,1,!JDK_COUNT!) do set "ENV_PURGE_LIST=!ENV_PURGE_LIST!;!JDK_PATH_%%k!\bin"
        
        if defined SYS_PATH (
            set "CLEAN_SYS_PATH="
            for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "$purges = $env:ENV_PURGE_LIST -split ';' | Where-Object { $_ } | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') }; $p = [Environment]::GetEnvironmentVariable('Path', 'Machine'); if ($p) { ($p -split ';' | Where-Object { $_ -and $purges -notcontains $_.TrimEnd('\') -and $_.TrimEnd('\') -ne '%%JAVA_HOME%%\bin' }) -join ';' }"') do set "CLEAN_SYS_PATH=%%A"
            if defined CLEAN_SYS_PATH (
                set "SYS_PATH=!CLEAN_SYS_PATH!"
                "%PS_BIN%" -NoProfile -Command "$sysPath = $env:SYS_PATH; $b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($sysPath)); $script = '$sysPath = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''' + $b64 + ''')); [Environment]::SetEnvironmentVariable(''JAVA_HOME'', $null, ''Machine''); Set-ItemProperty -Path ''HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'' -Name ''Path'' -Value $sysPath -Type ExpandString'; $enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($script)); $s = [Environment]::GetFolderPath([Environment+SpecialFolder]::System); $ps = Join-Path $s 'WindowsPowerShell\v1.0\powershell.exe'; try { $p = Start-Process -FilePath $ps -Verb RunAs -WorkingDirectory $s -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-EncodedCommand', $enc); try { if ($p.ExitCode -ne 0) { exit $p.ExitCode } } finally { if ($null -ne $p) { $p.Dispose() } } } catch { exit 1 }" 2>nul
            )
        )
    ) else (
        set "TARGET_MODE=DIRECT"
    )
    call :WriteConfigFile "%LOCALAPPDATA%\DiamTek\JVM\mode.txt" "!TARGET_MODE!"
    echo.
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to persist switch mode configuration.
    ) else (
        set "SWITCH_MODE=!TARGET_MODE!"
        echo %cGREEN%[   OK   ]%cRESET% Switched mode to !SWITCH_MODE!.
    )
    "%TIMEOUT_BIN%" /t 2 >nul
    goto SettingsMenu
)
if !sub_choice!==2 (
    if "!HOOK_IN_PROFILE!"=="1" (
        call :RemovePowerShellHook
    ) else (
        call :InstallPowerShellHook
    )
    goto SettingsMenu
)
if !sub_choice!==1 (
    if "!IN_PATH!"=="1" (
        call :RemoveGlobalCommand
    ) else (
        call :InstallGlobalCommand
    )
    goto SettingsMenu
)

goto SettingsMenu

rem ============================================================
rem GLOBAL COMMAND REMOVER
rem ============================================================
:RemoveGlobalCommand
rem cls
echo ============================================================
echo                Global Command Removal
echo ============================================================
echo.
echo %cBLUE%[  INFO  ]%cRESET% Target: !SCRIPT_DIR!
echo %cYELLOW%[ WARNING]%cRESET% Removing JVM directory from your User PATH.
"%CHOICE_BIN%" /C yn /N /M "Are you sure you want to proceed? (y/N): "
if errorlevel 2 goto :eof

echo.

rem Offload string manipulation to PowerShell to prevent delayed expansion corruption of exclamation marks
set "SAFE_TARGET=!SCRIPT_DIR!"
"%PS_BIN%" -NoProfile -Command "$p = (Get-ItemProperty -Path 'HKCU:\Environment' -Name 'Path').Path; if ($p) { $target = $env:SAFE_TARGET.TrimEnd('\'); $clean = ($p -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ne $target -and $_.TrimEnd('\') -ne ([Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%\DiamTek\JVM\bin').TrimEnd('\')) }) -join ';'; Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $clean -Type ExpandString }"

if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Registry write failed. Run as Administrator.
    echo.
    echo Press any key to return...
    pause >nul
    exit /b 1
) else (
    "%PS_BIN%" -NoProfile -Command "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Env { [DllImport(\"user32.dll\", SetLastError=true, CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult); }'; $res = [IntPtr]::Zero; [Env]::SendMessageTimeout([IntPtr]0xFFFF, 0x001A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$res) | Out-Null"
    echo %cGREEN%[   OK   ]%cRESET% User PATH successfully updated.
)

echo.
echo ============================================================
echo %cGREEN%[   OK   ]%cRESET% Removal Complete.
echo %cBLUE%[  INFO  ]%cRESET% You will no longer be able to launch 'jvm' globally via PATH.
echo ============================================================
echo.
echo Press any key to return...
pause >nul
goto :eof


rem ============================================================
rem GLOBAL COMMAND INSTALLER
rem ============================================================
:InstallGlobalCommand
rem cls
echo ============================================================
echo                 Global Command Installation
echo ============================================================
echo.
echo %cBLUE%[ ACTION ]%cRESET% Scanning User PATH for JVM directory...

set "USER_PATH="
for /f "tokens=2*" %%A in ('%REG_BIN% query "HKCU\Environment" /v Path 2^>nul') do (
    set "USER_PATH=%%B"
)

set "ALREADY_INSTALLED=0"
if defined USER_PATH (
    set "CLEAN_USER_PATH=!USER_PATH:"=!"
    set "TEST_PATH=;!CLEAN_USER_PATH!;"
    for %%D in ("!SCRIPT_DIR!") do (
        if "!TEST_PATH:;%%~D;=!" NEQ "!TEST_PATH!" set "ALREADY_INSTALLED=1"
        if "!TEST_PATH:;%%~D\;=!" NEQ "!TEST_PATH!" set "ALREADY_INSTALLED=1"
    )
    for %%D in ("%LOCALAPPDATA%\DiamTek\JVM\bin") do (
        if "!TEST_PATH:;%%~D;=!" NEQ "!TEST_PATH!" set "ALREADY_INSTALLED=1"
        if "!TEST_PATH:;%%~D\;=!" NEQ "!TEST_PATH!" set "ALREADY_INSTALLED=1"
    )
)

if "!ALREADY_INSTALLED!"=="1" (
    echo.
    echo %cGREEN%[   OK   ]%cRESET% The Java Version Manager is already in your User PATH:
    echo              !SCRIPT_DIR!
    echo.
    echo Press any key to return...
    pause >nul
    goto :eof
)

echo.
set "CANONICAL_BIN=%LOCALAPPDATA%\DiamTek\JVM\bin"
echo %cBLUE%[  INFO  ]%cRESET% Target: !CANONICAL_BIN!
echo %cBLUE%[  INFO  ]%cRESET% Installing JVM to user bin directory and adding to User PATH.
"%CHOICE_BIN%" /C yn /N /M "Are you sure you want to proceed? (y/N): "
if errorlevel 2 goto :eof

echo.

"%FSUTIL_BIN%" reparsepoint query "!CANONICAL_BIN!" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation: !CANONICAL_BIN! is a reparse point.
    exit /b 1
)
if not exist "!CANONICAL_BIN!" mkdir "!CANONICAL_BIN!" >nul 2>&1
"%FSUTIL_BIN%" reparsepoint query "!CANONICAL_BIN!" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation: !CANONICAL_BIN! is a reparse point.
    exit /b 1
)
"%ICACLS_BIN%" "!CANONICAL_BIN!" /inheritance:r /grant:r "*S-1-5-18:(OI)(CI)F" "*S-1-5-32-544:(OI)(CI)F" "%USERNAME%:(OI)(CI)F" >nul 2>&1
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to secure permissions on !CANONICAL_BIN!.
    exit /b 1
)

if /i not "!SCRIPT_DIR!"=="!CANONICAL_BIN!" (
    copy /y "!SCRIPT_PATH!" "!CANONICAL_BIN!\jvm.bat" >nul 2>&1
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to copy jvm.bat to !CANONICAL_BIN!.
        echo.
        echo Press any key to return...
        pause >nul
        exit /b 1
    )
    if not exist "!CANONICAL_BIN!\jvm.bat" (
        echo %cRED%[ ERROR  ]%cRESET% Failed to verify !CANONICAL_BIN!\jvm.bat after copy.
        echo.
        echo Press any key to return...
        pause >nul
        exit /b 1
    )
    if exist "!SCRIPT_DIR!\uninstall.ps1" copy /y "!SCRIPT_DIR!\uninstall.ps1" "!CANONICAL_BIN!\uninstall.ps1" >nul 2>&1
)

set "SAFE_TARGET=!CANONICAL_BIN!"
"%PS_BIN%" -NoProfile -Command "$k = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true); $p = $k.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames); $t = $env:SAFE_TARGET.TrimEnd('\'); $parts = @($p -split ';' | Where-Object { $_ -ne '' }); if (-not ($parts | Where-Object { $_.TrimEnd('\') -ieq $t })) { $newPath = if ($p) { $p.TrimEnd(';') + ';' + $env:SAFE_TARGET } else { $env:SAFE_TARGET }; $k.SetValue('Path', $newPath, [Microsoft.Win32.RegistryValueKind]::ExpandString) }; $k.Close()"

if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Registry write failed. Run as Administrator.
    echo.
    echo Press any key to return...
    pause >nul
    exit /b 1
) else (
    "%PS_BIN%" -NoProfile -Command "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Env { [DllImport(\"user32.dll\", SetLastError=true, CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult); }'; $res = [IntPtr]::Zero; [Env]::SendMessageTimeout([IntPtr]0xFFFF, 0x001A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$res) | Out-Null"
    echo %cGREEN%[   OK   ]%cRESET% User PATH successfully updated and broadcasted to OS.
)

echo.
echo ============================================================
echo %cGREEN%[   OK   ]%cRESET% Installation Complete.
echo %cBLUE%[  INFO  ]%cRESET% You can now type 'jvm' from any new command prompt or terminal.
echo ============================================================
echo.
echo Press any key to return...
pause >nul
goto :eof

rem ============================================================
rem POWERSHELL PROFILE HOOK INSTALLER
rem ============================================================
:InstallPowerShellHook
echo %cBLUE%[ ACTION ]%cRESET% Configuring JVM wrapper function in PowerShell profiles...

rem Switch to UTF-8 code page temporarily so file and path encoding is pristine
set "ORIG_HOOK_CP="
for /f "tokens=2 delims=:" %%A in ('%CHCP_BIN% 2^>nul') do (
    for /f "tokens=1 delims=. " %%B in ("%%A") do set "ORIG_HOOK_CP=%%B"
)
"%CHCP_BIN%" 65001 >nul

set "SAFE_TARGET=!SCRIPT_DIR!"
for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "HOOK_RANDOM_NAME=%%A"
set "INSTALL_PS1=%JVM_SECURE_TEMP%\jvm_setup_hook_!HOOK_RANDOM_NAME!.ps1"
set JVM_TRIM_DQ="
set "JVM_TRIM_BS=\"
set "JVM_TRIM1=        if ($OldValue) { $OldValue = $OldValue.Trim('!JVM_TRIM_DQ!').TrimEnd('!JVM_TRIM_BS!') }"
set "JVM_TRIM2=        if ($NewValue) { $NewValue = $NewValue.Trim('!JVM_TRIM_DQ!').TrimEnd('!JVM_TRIM_BS!') }"
set "JVM_TRME1=            $parts = $parts | Where-Object { $_.TrimEnd('!JVM_TRIM_BS!') -ne !JVM_TRIM_DQ!$OldValue\bin!JVM_TRIM_DQ! }"
set "JVM_TRME2=            $parts = $parts | Where-Object { $_.TrimEnd('!JVM_TRIM_BS!') -ne !JVM_TRIM_DQ!$NewValue\bin!JVM_TRIM_DQ! }"
(
    echo $targetBat = Join-Path $env:SAFE_TARGET 'jvm.bat'
    echo $targetBatEscaped = $targetBat.Replace^("'", "''"^)
    echo $hook = @'
    echo(# ^>^>^> jvm ^>^>^>
    echo(function jvm {
    echo(    $bat = '__FALLBACK_BAT__'
    echo(    if ^(-not ^(Test-Path -LiteralPath $bat^)^) {
    echo(        $bat = Get-Command jvm.bat -CommandType Application -ErrorAction SilentlyContinue ^| Select-Object -ExpandProperty Source -First 1
    echo(    }
    echo(    if ^(-not $bat -or -not ^(Test-Path -LiteralPath $bat^)^) {
    echo(        Write-Error "jvm: Java Version Manager is not installed or not in PATH. Please reinstall JVM or restart your terminal."
    echo(        return
    echo(    }
    echo(    $env:JVM_CALLER_PID = $PID
    echo(    ^& $bat @args
    echo(
    echo(    function Set-JvmVar {
    echo(        param^([string]$Name, [string]$OldValue, [string]$NewValue^)
    echo(
    echo(        $allowedVars = @^('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME', 'ANT_HOME', 'SBT_HOME', 'JBANG_HOME', 'QUARKUS_HOME', 'SPRING_HOME', 'MICRONAUT_HOME'^)
    echo(        if ^($allowedVars -notcontains $Name^) { return }
    echo(
    echo(!JVM_TRIM1!
    echo(!JVM_TRIM2!
    echo(
    echo(        if ^(-not [string]::IsNullOrWhiteSpace^($NewValue^)^) {
    echo(            if ^($NewValue -match '[\x00\x3B\x26\x7C\x3C\x3E\x22\x60\x24\x25\r\n]'^) { return }
    echo(            if ^(-not ^(Test-Path -LiteralPath $NewValue -PathType Container^)^) { return }
    echo(        }
    echo(
    echo(        [Environment]::SetEnvironmentVariable^($Name, $NewValue, 'Process'^)
    echo(
    echo(        $parts = $env:Path -split ';' ^| Where-Object { $_ -ne '' }
    echo(        if ^(-not [string]::IsNullOrWhiteSpace^($OldValue^)^) {
    echo(!JVM_TRME1!
    echo(        }
    echo(        if ^(-not [string]::IsNullOrWhiteSpace^($NewValue^)^) {
    echo(!JVM_TRME2!
    echo(            $parts = @^("$NewValue\bin"^) + $parts
    echo(        }
    echo(        $env:Path = $parts -join ';'
    echo(    }
    echo(
    echo(    $sessionFile = Join-Path $env:LOCALAPPDATA 'DiamTek\JVM\temp\.jvm_session_target'
    echo(    if ^(Test-Path $sessionFile^) {
    echo(        $lines = Get-Content $sessionFile -ErrorAction SilentlyContinue
    echo(        Remove-Item $sessionFile -Force -ErrorAction SilentlyContinue
    echo(        foreach ^($line in $lines^) {
    echo(            if ^([string]::IsNullOrWhiteSpace^($line^)^) { continue }
    echo(            if ^($line -match '^^^([A-Za-z0-9_]+^)=^(.*^)$'^) {
    echo(                $key = $matches[1]
    echo(                $val = $matches[2]
    echo(            } else {
    echo(                $key = 'JAVA_HOME'
    echo(                $val = $line
    echo(            }
    echo(            $old = [Environment]::GetEnvironmentVariable^($key, 'Process'^)
    echo(            Set-JvmVar -Name $key -OldValue $old -NewValue $val
    echo(        }
    echo(    } else {
    echo(        foreach ^($v in @^('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME', 'ANT_HOME', 'SBT_HOME', 'JBANG_HOME', 'QUARKUS_HOME', 'SPRING_HOME', 'MICRONAUT_HOME'^)^) {
    echo(            $old = [Environment]::GetEnvironmentVariable^($v, 'Process'^)
    echo(            $new = [Environment]::GetEnvironmentVariable^($v, 'User'^)
    echo(            if ^([string]::IsNullOrEmpty^($new^)^) {
    echo(                $new = [Environment]::GetEnvironmentVariable^($v, 'Machine'^)
    echo(            }
    echo(            if ^($old -eq $new^) { continue }
    echo(            Set-JvmVar -Name $v -OldValue $old -NewValue $new
    echo(        }
    echo(    }
    echo(}
    echo(
    echo(if ^(Get-Command Register-ArgumentCompleter -ErrorAction SilentlyContinue^) {
    echo(    Register-ArgumentCompleter -Native -CommandName @^('jvm', 'jvm.bat', '.\jvm.bat'^) -ScriptBlock {
    echo(        param^($wordToComplete, $commandAst, $cursorPosition^)
    echo(        $subcommands = @^(
    echo(            'list', 'ls', 'install', 'uninstall', 'rm', 'remove', 'use', 'default',
    echo(            'pin', 'local', 'current', 'status', 'info', 'whoami', 'which', 'path',
    echo(            'doctor', 'check', 'clean', 'prune', 'clear', 'update', 'self-update',
    echo(            'self-uninstall', 'open', 'home', 'exec', 'run', 'env', 'hook',
    echo(            'link', 'unlink', 'version', 'help', 'channel', 'lock'
    echo(        ^)
    echo(        $candidates = @^('java', 'maven', 'gradle', 'kotlin', 'scala', 'groovy', 'ant', 'sbt', 'jbang', 'quarkus', 'spring', 'micronaut', 'mn'^)
    echo(        $vendors = @^('adoptium', 'temurin', 'oracle', 'corretto', 'zulu', 'microsoft', 'graalvm', 'liberica', 'bellsoft', 'semeru', 'ibm', 'openj9', 'sapmachine', 'sap', 'mandrel', 'redhat-mandrel', 'dragonwell', 'alibaba', 'kona', 'tencent'^)
    echo(        $openTargets = @^('home', 'dir', 'bin', 'config', 'cache', 'downloads', 'backup', 'backups', 'links', 'maven', 'gradle', 'kotlin', 'scala', 'groovy', 'ant', 'sbt', 'jbang', 'quarkus', 'spring', 'micronaut', 'mn'^)
    echo(        $hookTargets = @^('install', 'status', 'check', 'remove', 'uninstall'^)
    echo(        $flags = @^(
    echo(            '--vendor', '--symlink', '--registry', '--legacy', '--session', '--global',
    echo(            '--skip-checksum', '--no-verify', '--latest', '--yes', '-y', '--no-color',
    echo(            '--offline', '--json', '--no-lock', '--locked', '-l',
    echo(            '--channel', '--nightly', '--stable',
    echo(            '--version', '-v', '--help', '-h'
    echo(        ^)
    echo(
    echo(        $elements = @^($commandAst.CommandElements ^| ForEach-Object { $_.Extent.Text }^)
    echo(        $count = $elements.Count
    echo(        $prev = if ^($wordToComplete -and $count -ge 2^) { $elements[-2] } elseif ^(-not $wordToComplete -and $count -ge 1^) { $elements[-1] } else { '' }
    echo(
    echo(        $completions = @^(^)
    echo(        if ^($prev -in @^('--vendor'^)^) {
    echo(            $completions = $vendors
    echo(        } elseif ^($prev -in @^('channel', '--channel'^)^) {
    echo(            $completions = @^('stable', 'nightly'^)
    echo(        } elseif ^($prev -in @^('open', 'home'^)^) {
    echo(            $completions = $openTargets
    echo(        } elseif ^($prev -in @^('hook'^)^) {
    echo(            $completions = $hookTargets
    echo(        } elseif ^($prev -in @^('use', 'default', 'pin', 'local', 'uninstall', 'rm', 'remove', 'which', 'path'^)^) {
    echo(            $installed = @^(^)
    echo(            $linksDir = "$env:LOCALAPPDATA\JavaVersionManager\links"
    echo(            if ^(Test-Path -LiteralPath $linksDir^) {
    echo(                $installed += @^(Get-ChildItem -LiteralPath $linksDir -ErrorAction SilentlyContinue ^| Select-Object -ExpandProperty Name^)
    echo(            }
    echo(            $jdksDir = "$env:USERPROFILE\.jdks"
    echo(            if ^(Test-Path -LiteralPath $jdksDir^) {
    echo(                $installed += @^(Get-ChildItem -LiteralPath $jdksDir -ErrorAction SilentlyContinue ^| Select-Object -ExpandProperty Name^)
    echo(            }
    echo(            $completions = @^($installed ^| Select-Object -Unique^) + $candidates
    echo(        } elseif ^($wordToComplete -like '-*'^) {
    echo(            $completions = $flags
    echo(        } else {
    echo(            $completions = $subcommands + $candidates + $flags
    echo(        }
    echo(
    echo(        $completions ^| Where-Object { $_ -like "$wordToComplete*" } ^| ForEach-Object {
    echo(            [System.Management.Automation.CompletionResult]::new^($_, $_, 'ParameterValue', $_^)
    echo(        }
    echo(    }
    echo(}
    echo(# ^<^<^< jvm ^<^<^<
    echo('@
    echo(
    echo $hook = $hook.Replace^('__FALLBACK_BAT__', $targetBatEscaped^)
    echo $userProfile = [Environment]::GetFolderPath^('UserProfile'^)
    echo $myDocs = [Environment]::GetFolderPath^('MyDocuments'^)
    echo $docPaths = @^($myDocs, ^(Join-Path $userProfile 'Documents'^)^) ^| Where-Object { $_ -and ^(Test-Path -LiteralPath $_^) } ^| Select-Object -Unique
    echo $profiles = @^($PROFILE^)
    echo foreach ^($doc in $docPaths^) {
    echo     $profiles += ^(Join-Path $doc 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'^)
    echo     $profiles += ^(Join-Path $doc 'PowerShell\Microsoft.PowerShell_profile.ps1'^)
    echo }
    echo $profiles = $profiles ^| Where-Object { $_ } ^| Select-Object -Unique
    echo $utf8 = New-Object System.Text.UTF8Encoding^($true^)
    echo foreach ^($p in $profiles^) {
    echo     if ^([string]::IsNullOrWhiteSpace^($p^)^) { continue }
    echo     $profileDir = Split-Path -Path $p -Parent
    echo     if ^(-not ^(Test-Path -LiteralPath $profileDir^)^) { New-Item -ItemType Directory -Path $profileDir -Force ^| Out-Null }
    echo     $dirItem = Get-Item -LiteralPath $profileDir -Force -ErrorAction SilentlyContinue
    echo     if ^($dirItem -and ^($dirItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint^)^) { continue }
    echo     $profContent = ''
    echo     if ^(Test-Path -LiteralPath $p^) {
    echo         $profItem = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
    echo         if ^($profItem -and ^($profItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint^)^) { continue }
    echo         $profContent = [System.IO.File]::ReadAllText^($p, [System.Text.Encoding]::UTF8^)
    echo     }
    echo     $blockPattern = '^(?s^)# ^>^>^> jvm ^>^>^>.*?# ^<^<^< jvm ^<^<^<'
    echo     $m = [Regex]::Match^($profContent, $blockPattern^)
    echo     if ^($m.Success^) {
    echo         $profContent = $profContent.Substring^(0, $m.Index^) + $hook + $profContent.Substring^($m.Index + $m.Length^)
    echo     } else {
    echo         $profContent = if ^([string]::IsNullOrWhiteSpace^($profContent^)^) { $hook } else { "$profContent`r`n`r`n$hook" }
    echo     }
    echo     $stageProf = "$p.stage.$([Guid]::NewGuid().ToString('N')).tmp"
    echo     try {
    echo         [System.IO.File]::WriteAllText^($stageProf, $profContent, $utf8^)
    echo         Move-Item -LiteralPath $stageProf -Destination $p -Force
    echo     } finally {
    echo         if ^(Test-Path -LiteralPath $stageProf^) { Remove-Item -LiteralPath $stageProf -Force -ErrorAction SilentlyContinue }
    echo     }
    echo     $esc = [char]27
    echo     Write-Host "$esc[92m[   OK   ]$esc[0m Hook configured in: $p"
    echo }
) > "!INSTALL_PS1!"

"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -File "!INSTALL_PS1!"
set "HOOK_EXIT=!errorlevel!"
if exist "!INSTALL_PS1!" del "!INSTALL_PS1!" >nul 2>&1
if "!HOOK_EXIT!" NEQ "0" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to configure PowerShell profile hook.
    if defined ORIG_HOOK_CP "%CHCP_BIN%" !ORIG_HOOK_CP! >nul
    exit /b 1
)

echo.
echo %cGREEN%[   OK   ]%cRESET% PowerShell profile hook successfully configured.
echo %cBLUE%[  INFO  ]%cRESET% Environment variables and PATH will now sync seamlessly across all PowerShell tabs.
echo %cBLUE%[  HINT  ]%cRESET% Run '. $PROFILE' or restart your terminal to activate completions immediately.
if defined ORIG_HOOK_CP "%CHCP_BIN%" !ORIG_HOOK_CP! >nul
if "!CLI_COMMAND!"=="" (
    echo.
    echo Press any key to return...
    pause >nul
)
exit /b 0

rem ============================================================
rem POWERSHELL PROFILE HOOK REMOVER
rem ============================================================
:RemovePowerShellHook
echo %cBLUE%[ ACTION ]%cRESET% Removing JVM wrapper function from PowerShell profiles...

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "RM_RANDOM_NAME=%%A"
set "REMOVE_PS1=%JVM_SECURE_TEMP%\jvm_remove_hook_!RM_RANDOM_NAME!.ps1"
(
    echo $userProfile = [Environment]::GetFolderPath^('UserProfile'^)
    echo $myDocs = [Environment]::GetFolderPath^('MyDocuments'^)
    echo $docPaths = @^($myDocs, ^(Join-Path $userProfile 'Documents'^)^) ^| Where-Object { $_ -and ^(Test-Path -LiteralPath $_^) } ^| Select-Object -Unique
    echo $profiles = @^($PROFILE^)
    echo foreach ^($doc in $docPaths^) {
    echo     $profiles += ^(Join-Path $doc 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'^)
    echo     $profiles += ^(Join-Path $doc 'PowerShell\Microsoft.PowerShell_profile.ps1'^)
    echo }
    echo $profiles = $profiles ^| Where-Object { $_ } ^| Select-Object -Unique
    echo $utf8 = New-Object System.Text.UTF8Encoding^($true^)
    echo $esc = [char]27
    echo foreach ^($prof in $profiles^) {
    echo     if ^($prof -and ^(Test-Path -LiteralPath $prof^)^) {
    echo         $profItem = Get-Item -LiteralPath $prof -Force -ErrorAction SilentlyContinue
    echo         if ^($profItem -and ^($profItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint^)^) { continue }
    echo         $c = [System.IO.File]::ReadAllText^($prof, [System.Text.Encoding]::UTF8^)
    echo         $m = [Regex]::Match^($c, '^(?s^)# ^>^>^> jvm ^>^>^>.*?# ^<^<^< jvm ^<^<^<'^)
    echo         if ^($m.Success^) {
    echo             $c = ^($c.Substring^(0, $m.Index^) + $c.Substring^($m.Index + $m.Length^)^).Trim^(^)
    echo             if ^([string]::IsNullOrWhiteSpace^($c^)^) {
    echo                 Remove-Item -LiteralPath $prof -Force
    echo                 Write-Host "$esc[92m[   OK   ]$esc[0m Cleaned empty profile: $prof"
    echo             } else {
    echo                 $stageProf = "$prof.stage.$([Guid]::NewGuid().ToString('N')).tmp"
    echo                 try {
    echo                     [System.IO.File]::WriteAllText^($stageProf, $c, $utf8^)
    echo                     Move-Item -LiteralPath $stageProf -Destination $prof -Force
    echo                 } finally {
    echo                     if ^(Test-Path -LiteralPath $stageProf^) { Remove-Item -LiteralPath $stageProf -Force -ErrorAction SilentlyContinue }
    echo                 }
    echo                 Write-Host "$esc[92m[   OK   ]$esc[0m Removed hook from: $prof"
    echo             }
    echo         }
    echo     }
    echo }
) > "!REMOVE_PS1!"

"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -File "!REMOVE_PS1!"
set "RM_HOOK_EXIT=!errorlevel!"
if exist "!REMOVE_PS1!" del "!REMOVE_PS1!" >nul 2>&1
if "!RM_HOOK_EXIT!" NEQ "0" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to remove PowerShell profile hook.
    exit /b 1
)

echo.
echo %cGREEN%[   OK   ]%cRESET% PowerShell profile hook successfully removed.
if "!CLI_COMMAND!"=="" (
    echo.
    echo Press any key to return...
    pause >nul
)
exit /b 0

rem ============================================================
rem POWERSHELL PROFILE HOOK STATUS CHECKER
rem ============================================================
:CheckPowerShellHookStatus
echo %cBLUE%[ ACTION ]%cRESET% Checking JVM PowerShell Profile Hook status...
echo ============================================================

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "ST_RANDOM_NAME=%%A"
set "STATUS_PS1=%JVM_SECURE_TEMP%\jvm_status_hook_!ST_RANDOM_NAME!.ps1"
(
    echo $userProfile = [Environment]::GetFolderPath^('UserProfile'^)
    echo $myDocs = [Environment]::GetFolderPath^('MyDocuments'^)
    echo $docPaths = @^($myDocs, ^(Join-Path $userProfile 'Documents'^)^) ^| Where-Object { $_ -and ^(Test-Path -LiteralPath $_^) } ^| Select-Object -Unique
    echo $profiles = @^($PROFILE^)
    echo foreach ^($doc in $docPaths^) {
    echo     $profiles += ^(Join-Path $doc 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'^)
    echo     $profiles += ^(Join-Path $doc 'PowerShell\Microsoft.PowerShell_profile.ps1'^)
    echo }
    echo $profiles = $profiles ^| Where-Object { $_ } ^| Select-Object -Unique
    echo $foundCount = 0
    echo $esc = [char]27
    echo foreach ^($prof in $profiles^) {
    echo     if ^($prof -and ^(Test-Path -LiteralPath $prof^)^) {
    echo         if ^(Select-String -LiteralPath $prof -Pattern '# ^>^>^> jvm ^>^>^>' -Quiet^) {
    echo             Write-Host "$esc[92m[   OK   ]$esc[0m Active in: $prof"
    echo             $foundCount++
    echo         } else {
    echo             Write-Host "$esc[96m[  INFO  ]$esc[0m Profile exists ^(hook not present^): $prof"
    echo         }
    echo     } else {
    echo         Write-Host "$esc[96m[  INFO  ]$esc[0m Profile file not yet created: $prof"
    echo     }
    echo }
) > "!STATUS_PS1!"

"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -File "!STATUS_PS1!"
if exist "!STATUS_PS1!" del "!STATUS_PS1!" >nul 2>&1

echo ============================================================
exit /b 0

rem ============================================================
rem COMPLETE UNINSTALLER (Calls uninstall.ps1)
rem ============================================================
:UninstallJVM_Complete
echo.
echo ============================================================
echo         Uninstall Java Version Manager (Complete Wipe)
echo ============================================================
echo.
echo %cYELLOW%[ WARNING]%cRESET% This will run the deep uninstaller.
echo            It will remove JVM, PATH entries, profile hooks,
echo            all downloaded ecosystem tools, and installed JDKs.
echo.
"%CHOICE_BIN%" /C yn /N /M "Are you sure you want to proceed? (y/N): "
if errorlevel 2 (
    if defined CLI_COMMAND (
        if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul
        exit /b 0
    )
    goto :SettingsMenu
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Locating uninstaller...
set "UNINSTALL_REF=v!JVM_VERSION!"
set "UNINSTALL_SCRIPT="
set "UNINSTALL_VERIFIED=0"
if /i "!UPDATE_CHANNEL!"=="NIGHTLY" set "UNINSTALL_REF=main"
for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "UNINS_RANDOM_NAME=%%A"

if exist "!SCRIPT_DIR!\uninstall.ps1" set "UNINSTALL_SCRIPT=!SCRIPT_DIR!\uninstall.ps1"
if not defined UNINSTALL_SCRIPT if exist "!SCRIPT_DIR!\..\uninstall.ps1" set "UNINSTALL_SCRIPT=!SCRIPT_DIR!\..\uninstall.ps1"
if not defined UNINSTALL_SCRIPT if exist "%LOCALAPPDATA%\DiamTek\JVM\uninstall.ps1" set "UNINSTALL_SCRIPT=%LOCALAPPDATA%\DiamTek\JVM\uninstall.ps1"
if not defined UNINSTALL_SCRIPT if exist "%LOCALAPPDATA%\DiamTek\JVM\bin\uninstall.ps1" set "UNINSTALL_SCRIPT=%LOCALAPPDATA%\DiamTek\JVM\bin\uninstall.ps1"

if defined UNINSTALL_SCRIPT (
    "%FSUTIL_BIN%" reparsepoint query "!UNINSTALL_SCRIPT!" >nul 2>&1
    if !errorlevel! EQU 0 (
        echo %cYELLOW%[ WARNING]%cRESET% Local uninstall.ps1 is a symlink or reparse point. Ignoring local file...
        set "UNINSTALL_SCRIPT="
    ) else (
        call :VerifyDownloadedScript "!UNINSTALL_SCRIPT!" "!UNINSTALL_REF!" "uninstall.ps1"
        if errorlevel 1 (
            echo %cYELLOW%[ WARNING]%cRESET% Local uninstall.ps1 does not match !UNINSTALL_REF! digest. Fetching verified release copy...
            set "UNINSTALL_SCRIPT="
        ) else (
            set "UNINSTALL_VERIFIED=1"
            echo %cGREEN%[   OK   ]%cRESET% uninstall.ps1 cryptographic digest verified ^(!UPDATE_CHANNEL!^).
        )
    )
)

if not defined UNINSTALL_SCRIPT (
    call :RequireNetwork
    if errorlevel 1 exit /b 1
    echo %cBLUE%[ ACTION ]%cRESET% Downloading verified uninstall.ps1 ^(!UPDATE_CHANNEL! / !UNINSTALL_REF!^)...

    set "UNINSTALL_SCRIPT=%TEMP%\jvm_uninstall_!UNINS_RANDOM_NAME!.ps1"
    set "UNINSTALL_DOWNLOADED_TEMP=!UNINSTALL_SCRIPT!"

    "%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -Command ^
        "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288;" ^
        "$ProgressPreference = 'SilentlyContinue';" ^
        "$ref = $env:UNINSTALL_REF;" ^
        "$f = $env:UNINSTALL_SCRIPT;" ^
        "try {" ^
        "  Invoke-WebRequest -Uri ('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/contents/uninstall.ps1?ref=' + $ref) -Headers @{'Accept'='application/vnd.github.v3.raw'} -UserAgent 'DiamTek-JVM' -OutFile $f -UseBasicParsing -TimeoutSec 5" ^
        "} catch {" ^
        "  try {" ^
        "    Invoke-WebRequest -Uri ('https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/' + $ref + '/uninstall.ps1') -UserAgent 'DiamTek-JVM' -OutFile $f -UseBasicParsing -TimeoutSec 5" ^
        "  } catch {}" ^
        "}"
)

if not exist "!UNINSTALL_SCRIPT!" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to locate or download uninstall.ps1.
    exit /b 1
)

"%FSUTIL_BIN%" reparsepoint query "!UNINSTALL_SCRIPT!" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Downloaded uninstall.ps1 is a reparse point.
    exit /b 1
)

if "!UNINSTALL_VERIFIED!"=="0" (
    call :VerifyDownloadedScript "!UNINSTALL_SCRIPT!" "!UNINSTALL_REF!" "uninstall.ps1"
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Cryptographic verification of uninstall.ps1 failed ^(!UPDATE_CHANNEL!^).
        del "!UNINSTALL_SCRIPT!" >nul 2>&1
        exit /b 1
    )

    echo %cGREEN%[   OK   ]%cRESET% uninstall.ps1 cryptographic digest verified ^(!UPDATE_CHANNEL!^).
)

set "RUNNER_PS1=%TEMP%\diamtek_uninstall_runner_!UNINS_RANDOM_NAME!.ps1"
copy /y "!UNINSTALL_SCRIPT!" "!RUNNER_PS1!" >nul 2>&1
if defined UNINSTALL_DOWNLOADED_TEMP if exist "!UNINSTALL_DOWNLOADED_TEMP!" del /f /q "!UNINSTALL_DOWNLOADED_TEMP!" >nul 2>&1

set "TARGET_UNINSTALL_DIR=!SCRIPT_DIR!"
cd /d "%TEMP%"

"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -File "!RUNNER_PS1!" -SourceDir "!TARGET_UNINSTALL_DIR!"
set "UNINST_ERR=!errorlevel!"
if exist "!RUNNER_PS1!" del /f /q "!RUNNER_PS1!" >nul 2>&1
if "!ORIG_CP!" NEQ "" "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
set "CMD_EXIT_CODE=0"
set "EXIT_JVM_ALL=1"
if defined CLI_COMMAND (
    exit /b !UNINST_ERR!
) else (
    exit /b 100
)

:HANDLE_LINKS
setlocal enabledelayedexpansion
set "LINK_PARENT=%LOCALAPPDATA%\JavaVersionManager"
set "LINK_DIR=%LOCALAPPDATA%\JavaVersionManager\links"
"%FSUTIL_BIN%" reparsepoint query "%LOCALAPPDATA%\DiamTek\JVM" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): %LOCALAPPDATA%\DiamTek\JVM is a reparse point.
    goto :HANDLE_LINKS_FAIL
)
"%FSUTIL_BIN%" reparsepoint query "%LOCALAPPDATA%\DiamTek\JVM\links" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): %LOCALAPPDATA%\DiamTek\JVM\links is a reparse point.
    goto :HANDLE_LINKS_FAIL
)
"%FSUTIL_BIN%" reparsepoint query "%LINK_PARENT%" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): %LINK_PARENT% is a reparse point.
    goto :HANDLE_LINKS_FAIL
)
if not exist "%LINK_PARENT%" mkdir "%LINK_PARENT%" >nul 2>&1
"%FSUTIL_BIN%" reparsepoint query "%LINK_DIR%" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): %LINK_DIR% is a reparse point.
    goto :HANDLE_LINKS_FAIL
)
if not exist "%LINK_DIR%" mkdir "%LINK_DIR%" >nul 2>&1
"%FSUTIL_BIN%" reparsepoint query "%LINK_DIR%" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): %LINK_DIR% is a reparse point.
    goto :HANDLE_LINKS_FAIL
)
"%ICACLS_BIN%" "%LINK_DIR%" /inheritance:r /grant:r "*S-1-5-18:(OI)(CI)F" "*S-1-5-32-544:(OI)(CI)F" "%USERNAME%:(OI)(CI)F" >nul 2>&1

if /i "%~1"=="link" (
    if "%~2"=="" (
        echo.
        echo %cBLUE%[  INFO  ]%cRESET% Linked JDKs:
        echo ============================================================
        dir /ad /b "%LINK_DIR%" 2>nul | %FINDSTR_BIN% "^" >nul
        if errorlevel 1 (
            echo                  No custom JDKs linked yet.
        ) else (
            for /d %%d in ("%LINK_DIR%\*") do (
                set "LINK_TARGET="
                for /f "tokens=1,2*" %%A in ('%FSUTIL_BIN% reparsepoint query "%%d" 2^>nul ^| %FINDSTR_BIN% /i "Print Name:"') do set "LINK_TARGET=%%C"
                if not defined LINK_TARGET (
                    set "QUERY_PATH=%%d"
                    for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath $env:QUERY_PATH -ErrorAction SilentlyContinue).Target" 2^>nul') do set "LINK_TARGET=%%A"
                )
                if defined LINK_TARGET (
                    set "LINK_TARGET=!LINK_TARGET:\??\=!"
                    set "LINK_TARGET=!LINK_TARGET:\\?\=!"
                    for /f "tokens=*" %%A in ("!LINK_TARGET!") do set "LINK_TARGET=%%A"
                )

                if not exist "%%d\bin\java.exe" (
                    echo %%~nxd -^> !LINK_TARGET! %cRED%[BROKEN]%cRESET%
                ) else if defined LINK_TARGET (
                    echo %%~nxd -^> !LINK_TARGET!
                ) else (
                    echo %%~nxd
                )
            )
        )
        echo ============================================================
        echo.
        echo Use "jvm link <path> [name]" to add a link.
        echo.
        goto :HANDLE_LINKS_SUCCESS
    )

    call :AcquireStateLock
    if errorlevel 1 goto :HANDLE_LINKS_FAIL

    rem Reject Win32 device namespace paths (\\.\, \\?\, \??\), NTFS ADS colons, and PATH/batch delimiters (CWE-88/CWE-78)
    rem Note: Commas (',') are valid in Windows directory names and allowed here since linked JDKs are accessed via their sanitized junction name in %LINK_DIR%
    set "RAW_LINK_PATH=%~2"
    if "!RAW_LINK_PATH:~0,2!"=="\\" (
        echo %cRED%[ ERROR  ]%cRESET% Invalid JDK path: Win32 device or UNC paths are forbidden.
        goto :HANDLE_LINKS_FAIL
    )
    if "!RAW_LINK_PATH:~0,4!"=="\??\" (
        echo %cRED%[ ERROR  ]%cRESET% Invalid JDK path: NT namespace paths are forbidden.
        goto :HANDLE_LINKS_FAIL
    )
    if not "!RAW_LINK_PATH!"=="!RAW_LINK_PATH:;=!" (
        echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-88^): JDK path cannot contain semicolon ';' characters.
        goto :HANDLE_LINKS_FAIL
    )
    if not "!RAW_LINK_PATH!"=="!RAW_LINK_PATH:&=!" (
        echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-78^): JDK path contains forbidden shell metacharacters.
        goto :HANDLE_LINKS_FAIL
    )
    if not "!RAW_LINK_PATH!"=="!RAW_LINK_PATH:|=!" (
        echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-78^): JDK path contains forbidden shell metacharacters.
        goto :HANDLE_LINKS_FAIL
    )
    if not "!RAW_LINK_PATH!"=="!RAW_LINK_PATH:^=!" (
        echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-78^): JDK path contains forbidden shell metacharacters.
        goto :HANDLE_LINKS_FAIL
    )
    set "LINK_AFTER_DRIVE=!RAW_LINK_PATH:~2!"
    if defined LINK_AFTER_DRIVE (
        if not "!LINK_AFTER_DRIVE!"=="!LINK_AFTER_DRIVE::=!" (
            echo %cRED%[ ERROR  ]%cRESET% Invalid JDK path: NTFS Alternate Data Streams are forbidden.
            goto :HANDLE_LINKS_FAIL
        )
    )

    rem Resolve absolute path
    pushd "%~2" 2>nul
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% The directory "%~2" does not exist!
        goto :HANDLE_LINKS_FAIL
    )
    set "TARGET_PATH=!CD!"
    popd
    for %%I in ("!TARGET_PATH!") do set "TARGET_PATH=%%~fI"

    if not exist "!TARGET_PATH!\bin\java.exe" (
        echo %cRED%[ ERROR  ]%cRESET% Invalid JDK path. Could not find bin\java.exe inside !TARGET_PATH!
        goto :HANDLE_LINKS_FAIL
    )

    set "LINK_NAME=%~nx2"
    if "%~3"=="" (
        set "LINK_NAME=!LINK_NAME:,=-!"
        set "LINK_NAME=!LINK_NAME: =-!"
    ) else (
        set "LINK_NAME=%~3"
    )
    if "!LINK_NAME!"=="." (
        echo %cRED%[ ERROR  ]%cRESET% Invalid link name: '.' is forbidden.
        goto :HANDLE_LINKS_FAIL
    )
    if not "!LINK_NAME!"=="!LINK_NAME:\=!" (
        echo %cRED%[ ERROR  ]%cRESET% Link name cannot contain path separators: !LINK_NAME!
        goto :HANDLE_LINKS_FAIL
    )
    if not "!LINK_NAME!"=="!LINK_NAME:/=!" (
        echo %cRED%[ ERROR  ]%cRESET% Link name cannot contain path separators: !LINK_NAME!
        goto :HANDLE_LINKS_FAIL
    )
    if not "!LINK_NAME!"=="!LINK_NAME:..=!" (
        echo %cRED%[ ERROR  ]%cRESET% Link name cannot contain '..': !LINK_NAME!
        goto :HANDLE_LINKS_FAIL
    )
    call :ValidateStrictIdentifier "!LINK_NAME!" LINK_NAME
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Invalid link name: "!LINK_NAME!"
        goto :HANDLE_LINKS_FAIL
    )
    if /i "!LINK_NAME!"=="current" (
        echo %cRED%[ ERROR  ]%cRESET% 'current' is a reserved keyword and cannot be targeted.
        goto :HANDLE_LINKS_FAIL
    )

    if exist "%LINK_DIR%\!LINK_NAME!" (
        echo %cRED%[ ERROR  ]%cRESET% A link named '!LINK_NAME!' already exists.
        goto :HANDLE_LINKS_FAIL
    )

    echo %cBLUE%[ ACTION ]%cRESET% Creating link '!LINK_NAME!' -^> !TARGET_PATH!
    mklink /J "%LINK_DIR%\!LINK_NAME!" "!TARGET_PATH!" >nul 2>&1
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to create junction point.
        goto :HANDLE_LINKS_FAIL
    )
    "%FSUTIL_BIN%" reparsepoint query "%LINK_DIR%\!LINK_NAME!" >nul 2>&1
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Junction verification failed for '!LINK_NAME!'.
        rmdir "%LINK_DIR%\!LINK_NAME!" >nul 2>&1
        goto :HANDLE_LINKS_FAIL
    )
    echo %cGREEN%[   OK   ]%cRESET% Custom JDK linked successfully.
    goto :HANDLE_LINKS_SUCCESS
)

if /i "%~1"=="unlink" (
    if "%~2"=="" (
        echo %cRED%[ ERROR  ]%cRESET% Please specify a link name to remove.
        echo Usage: jvm unlink ^<name^>
        goto :HANDLE_LINKS_FAIL
    )

    call :AcquireStateLock
    if errorlevel 1 goto :HANDLE_LINKS_FAIL

    set "UNLINK_NAME=%~2"
    if "!UNLINK_NAME!"=="." (
        echo %cRED%[ ERROR  ]%cRESET% Invalid link name: '.' is forbidden.
        goto :HANDLE_LINKS_FAIL
    )
    if not "!UNLINK_NAME!"=="!UNLINK_NAME:\=!" (
        echo %cRED%[ ERROR  ]%cRESET% Link name cannot contain path separators: !UNLINK_NAME!
        goto :HANDLE_LINKS_FAIL
    )
    if not "!UNLINK_NAME!"=="!UNLINK_NAME:/=!" (
        echo %cRED%[ ERROR  ]%cRESET% Link name cannot contain path separators: !UNLINK_NAME!
        goto :HANDLE_LINKS_FAIL
    )
    if not "!UNLINK_NAME!"=="!UNLINK_NAME:..=!" (
        echo %cRED%[ ERROR  ]%cRESET% Link name cannot contain '..': !UNLINK_NAME!
        goto :HANDLE_LINKS_FAIL
    )
    call :ValidateStrictIdentifier "!UNLINK_NAME!" UNLINK_NAME
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Invalid link name: "!UNLINK_NAME!"
        goto :HANDLE_LINKS_FAIL
    )
    if /i "!UNLINK_NAME!"=="current" (
        echo %cRED%[ ERROR  ]%cRESET% 'current' is a reserved keyword and cannot be targeted.
        goto :HANDLE_LINKS_FAIL
    )
    if not exist "%LINK_DIR%\!UNLINK_NAME!" (
        echo %cRED%[ ERROR  ]%cRESET% Link '!UNLINK_NAME!' not found.
        goto :HANDLE_LINKS_FAIL
    )
    "%FSUTIL_BIN%" reparsepoint query "%LINK_DIR%\!UNLINK_NAME!" >nul 2>&1
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): '%LINK_DIR%\!UNLINK_NAME!' is a regular directory, not a junction.
        goto :HANDLE_LINKS_FAIL
    )
    echo %cBLUE%[ ACTION ]%cRESET% Removing link '!UNLINK_NAME!'...
    rmdir "%LINK_DIR%\!UNLINK_NAME!" >nul 2>&1
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to remove link '!UNLINK_NAME!'.
        goto :HANDLE_LINKS_FAIL
    )
    if exist "%LINK_DIR%\!UNLINK_NAME!" (
        echo %cRED%[ ERROR  ]%cRESET% Failed to remove link '!UNLINK_NAME!'.
        goto :HANDLE_LINKS_FAIL
    )
    echo %cGREEN%[   OK   ]%cRESET% Link removed.
    goto :HANDLE_LINKS_SUCCESS
)

:HANDLE_LINKS_FAIL
if "!JVM_LOCK_ACQUIRED!"=="1" call :ReleaseStateLock
if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
exit /b 1

:HANDLE_LINKS_SUCCESS
if "!JVM_LOCK_ACQUIRED!"=="1" call :ReleaseStateLock
if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
exit /b 0

:CLI_DONE
if "!IS_ADMIN_RUN!"=="1" (
    echo.
    echo Press any key to close this window...
    pause >nul
)
if defined ORIG_CP "%CHCP_BIN%" !ORIG_CP! >nul 2>&1
if defined JVM_EXIT_CODE exit /b !JVM_EXIT_CODE!
exit /b 0

rem ============================================================
rem CLI HELP SCREEN
rem ============================================================
:ShowHelp
echo Java Version Manager ^(JVM^) for Windows - Version !JVM_VERSION! ^(Build !JVM_BUILD!^)
echo.
echo Usage:
echo   jvm                            Open interactive Terminal User Interface ^(TUI^)
echo   jvm ^<version^>                  Switch active JDK ^(e.g. jvm 21, jvm latest, jvm lts^)
echo   jvm ^<candidate^> ^<version^>      Switch ecosystem tool ^(e.g. jvm maven 3.9.6, jvm gradle 8.5^)
echo.
echo Management Commands:
echo   jvm list, ls                   List all installed JDKs and Ecosystem tools
echo   jvm current, status, info      Display active JDK, mode, and ecosystem status
echo   jvm which, path [candidate]    Display absolute binary path to active java/tool
echo   jvm use, default ^<version^>     Switch active JDK ^(SDKMAN/nvm alias^)
echo   jvm pin, local [version]       Lock or display directory-level .java-version
echo   jvm exec, run ^<ver^> [--] ^<cmd^> Run command in ephemeral isolated JDK subshell
echo   jvm open, home [candidate]     Open active candidate or root in File Explorer
echo   jvm clean, prune               Purge temporary download caches and extraction artifacts
echo   jvm clear                      Purge JAVA_HOME and remove Java from PATH
echo   jvm env                        Display current environment variables
echo   jvm install ^<candidate^> ^<ver^>  Download and install a tool or JDK ^(12 vendors supported^)
echo   jvm install --locked, -l       Install exact dependencies from repository .jvm.lock
echo   jvm lock [candidate] [ver]     Generate reproducible .jvm.lock lockfile
echo   jvm uninstall, rm [cand] ^<ver^> Uninstall a specific JDK or candidate tool
echo   jvm update ^<ver^> ^| --all       Check for and apply vendor patches to JDKs / tools
echo   jvm link ^<path^> [name]         Register an external JDK directory
echo   jvm unlink ^<name^>              Unregister an external JDK directory
echo.
echo System ^& Maintenance Commands:
echo   jvm doctor, check              Deep diagnostic health audit and conflict scanner
echo   jvm hook [install^|remove]      Manage PowerShell profile auto-sync wrapper hook
echo   jvm channel [stable^|nightly]   View or switch JVM update channel ^(Stable or Nightly^)
echo   jvm version, -v                Display version, build, and check for updates
echo   jvm self-update                Automatically download and install the latest JVM update
echo   jvm self-uninstall             Launch the deep uninstaller ^(full system wipe^)
echo   jvm help, --help, -h, /?       Show this help message
echo.
echo Flag Overrides:
echo   --vendor ^<name^>                Filter or target vendor ^(oracle, adoptium, graalvm, corretto, zulu, ms, liberica, semeru, sapmachine, mandrel, dragonwell, kona^)
echo   --channel ^<name^>               Override update channel ^(stable or nightly^)
echo   --nightly, --stable            Shortcut flags to target update channel
echo   --symlink                      Force Symlink Mode ^(UAC-Free Directory Junction^)
echo   --legacy, --registry           Force Legacy Mode ^(System HKLM Registry, requires UAC^)
echo   --session                      Force True Session Isolation for the active terminal
echo   --global                       Force global system-wide switch
echo   --locked, -l, --lock           Install candidate^(s^) locked in .jvm.lock with strict checksums
echo   --offline                      Disallow outbound network requests ^(operate locally only^)
echo   --json                         Emit machine-readable JSON output for automation
echo   --yes, -y                      Bypass interactive confirmation prompts
echo   --no-lock                      Bypass mutual exclusion lock ^(UNSAFE for concurrent operations^)
echo   --skip-checksum, --no-verify   Bypass checksum verification if hash is unavailable
echo   --no-color                     Disable ANSI colors ^(also respects NO_COLOR env^)
goto :eof

rem ============================================================
rem SHOW CURRENT STATUS / ENVIRONMENT
rem ============================================================
:ShowCurrentStatus
set "CURR_JAVA_VER="
set "CURR_JAVA_BIN="
set "CURR_JAVA_VENDOR="

if defined JAVA_HOME (
    set "JAVA_HOME=!JAVA_HOME:"=!"
    if exist "!JAVA_HOME!\release" (
        for /f "tokens=1,* delims==" %%A in ('type "!JAVA_HOME!\release" 2^>nul ^| %FINDSTR_BIN% /i "^JAVA_VERSION= ^IMPLEMENTOR="') do (
            if /i "%%A"=="JAVA_VERSION" set "CURR_JAVA_VER=%%~B"
            if /i "%%A"=="IMPLEMENTOR" set "CURR_JAVA_VENDOR=%%~B"
        )
    )
    if exist "!JAVA_HOME!\bin\java.exe" (
        set "CURR_JAVA_BIN=!JAVA_HOME!\bin\java.exe"
    )
)

if not defined CURR_JAVA_BIN (
    for /f "delims=" %%A in ('%WHERE_BIN% $PATH:java 2^>nul') do (
        if not defined CURR_JAVA_BIN set "CURR_JAVA_BIN=%%A"
    )
)

if not defined CURR_JAVA_VER (
    if defined CURR_JAVA_BIN (
        for /f "tokens=3" %%A in ('"!CURR_JAVA_BIN!" -version 2^>^&1 ^| %FINDSTR_BIN% /i version') do (
            set "CURR_JAVA_VER=%%~A"
        )
    )
)

set "JUNCTION_TARGET="
if exist "%LOCALAPPDATA%\DiamTek\JVM\current" (
    for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath ($env:LOCALAPPDATA + '\DiamTek\JVM\current') -ErrorAction SilentlyContinue).Target" 2^>nul') do set "JUNCTION_TARGET=%%A"
)

if "%OUTPUT_JSON%"=="1" (
    set "JSON_JH=!JAVA_HOME!"
    if defined JSON_JH set "JSON_JH=!JSON_JH:\=\\!"
    if defined JSON_JH set "JSON_JH=!JSON_JH:"=!"
    set "JSON_BIN=!CURR_JAVA_BIN!"
    if defined JSON_BIN set "JSON_BIN=!JSON_BIN:\=\\!"
    if defined JSON_BIN set "JSON_BIN=!JSON_BIN:"=!"
    set "JSON_JT=!JUNCTION_TARGET!"
    if defined JSON_JT set "JSON_JT=!JSON_JT:\=\\!"
    if defined JSON_JT set "JSON_JT=!JSON_JT:"=!"
    set "JSON_ACTIVE=false"
    if defined CURR_JAVA_BIN set "JSON_ACTIVE=true"

    echo {"candidate":"java","active":!JSON_ACTIVE!,"version":"!CURR_JAVA_VER!","vendor":"!CURR_JAVA_VENDOR!","java_home":"!JSON_JH!","binary":"!JSON_BIN!","mode":"!SWITCH_MODE!","channel":"!UPDATE_CHANNEL!","junction_target":"!JSON_JT!"}
    exit /b 0
)

echo.
echo %cBLUE%[  INFO  ]%cRESET% Current JVM Environment Status:
echo ============================================================

echo  Java Configuration:
if defined CURR_JAVA_VER (
    if defined CURR_JAVA_VENDOR (
        echo    - Version:       !CURR_JAVA_VENDOR! !CURR_JAVA_VER!
    ) else (
        echo    - Version:       Java !CURR_JAVA_VER!
    )
) else (
    echo    - Version:       Not Active / Not Found
)

if defined JAVA_HOME (
    echo    - JAVA_HOME:     !JAVA_HOME!
) else (
    echo    - JAVA_HOME:     NOT SET
)

if defined CURR_JAVA_BIN (
    echo    - Binary:        !CURR_JAVA_BIN!
) else (
    echo    - Binary:        NOT FOUND
)

if /i "!SWITCH_MODE!"=="DIRECT" (
    echo    - Mode:          %cRED%[Registry Mode]%cRESET% ^(Machine HKLM^)
) else (
    echo    - Mode:          %cGREEN%[Symlink Mode]%cRESET% ^(User Junction, UAC Free^)
    if defined JUNCTION_TARGET (
        echo    - Junction:      %LOCALAPPDATA%\DiamTek\JVM\current -^> %cGREEN%!JUNCTION_TARGET!%cRESET%
    ) else (
        echo    - Junction:      %LOCALAPPDATA%\DiamTek\JVM\current %cYELLOW%^(Inactive^)%cRESET%
    )
)

if /i "!UPDATE_CHANNEL!"=="NIGHTLY" (
    echo    - Channel:       %cPURPLE%[Nightly]%cRESET% ^(Cutting-edge main branch^)
) else (
    echo    - Channel:       %cGREEN%[Stable]%cRESET% ^(Official Releases^)
)

echo.
echo  Ecosystem Tools:
set "ECO_FOUND=0"
if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates" (
    for /d %%C in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\*") do (
        set "CAND_ID=%%~nxC"
        call :ValidateStrictIdentifier "!CAND_ID!" CAND_ID
        if not errorlevel 1 (
            set "C_NAME=!CAND_ID!"
            set "C_TARGET="
            if exist "%%C\current" (
                set "QUERY_CAND_DIR=%%C\current"
                for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath $env:QUERY_CAND_DIR -ErrorAction SilentlyContinue).Target" 2^>nul') do set "C_TARGET=%%A"
                if defined C_TARGET (
                    set "ECO_FOUND=1"
                    for /f "delims=" %%V in ("!C_TARGET!") do (
                        echo    - !C_NAME!:         %%~nxV %cGREEN%[ACTIVE]%cRESET%
                    )
                )
            )
        )
    )
)
if "!ECO_FOUND!"=="0" (
    echo    - ^(None active. Use 'jvm ^<tool^> install' to install candidates^)
)
echo ============================================================
exit /b 0

rem ============================================================
rem CLEAN CACHE AND TEMPORARY ARTIFACTS
rem ============================================================
:CleanCache
call :AcquireStateLock
if errorlevel 1 exit /b 1
echo.
echo %cBLUE%[ ACTION ]%cRESET% Scanning temporary files, installer archives, and cache...
set "FREED_MB=0"
set "FREED_COUNT=0"
set "CLEAN_CMD=$temp = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'DiamTek\JVM\temp'); $appdata = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'DiamTek\JVM'); $patterns = @((Join-Path $temp 'jdk_*_download.*'), (Join-Path $temp 'jdk_*_extract'), (Join-Path $temp 'jvm_*_*.zip'), (Join-Path $temp 'jvm_*_*_temp'), (Join-Path $temp 'verify_*.txt'), (Join-Path $temp 'jvm_remote_build_*.txt'), (Join-Path $temp 'jvm_dl_*.ps1'), (Join-Path $temp 'jvm_updater_*.bat'), (Join-Path $temp 'jvm_install_*.ps1'), (Join-Path $temp 'jvm_uninstall_*.bat'), (Join-Path $temp 'jvm_uninstall_*.ps1'), (Join-Path $temp '.jvm_session_target*'), (Join-Path $appdata 'downloads\*'), (Join-Path $appdata 'candidates\*\temp_*')); $totalBytes = 0; $fileCount = 0; foreach ($p in $patterns) { Get-Item $p -Force -ErrorAction SilentlyContinue | ForEach-Object { if (($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { $fileCount++; if ($_.PSIsContainer) { try { [System.IO.Directory]::Delete($_.FullName, $false) } catch {} } else { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue } } elseif ($_.PSIsContainer) { Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 } | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object { if ($_.PSIsContainer) { try { [System.IO.Directory]::Delete($_.FullName, $false) } catch {} } else { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue } }; $subFiles = Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue; foreach ($sf in $subFiles) { $totalBytes += $sf.Length; $fileCount++ }; Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue } else { $totalBytes += $_.Length; $fileCount++; Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue } } }; $mb = [math]::Round($totalBytes / 1MB, 2); Write-Output ('FREED_MB=' + $mb); Write-Output ('FREED_COUNT=' + $fileCount)"
for /f "tokens=1,2 delims==" %%A in ('%PS_BIN% -NoProfile -Command "!CLEAN_CMD!"') do (
    if "%%A"=="FREED_MB" set "FREED_MB=%%B"
    if "%%A"=="FREED_COUNT" set "FREED_COUNT=%%B"
)

if defined FREED_COUNT (
    if !FREED_COUNT! GTR 0 (
        echo %cGREEN%[   OK   ]%cRESET% Successfully cleaned !FREED_COUNT! temporary files ^(reclaimed !FREED_MB! MB^).
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% Cache is already clean. Zero orphaned files detected.
    )
) else (
    echo %cGREEN%[   OK   ]%cRESET% Cache is already clean.
)
call :EnsureSecureTemp
call :ReleaseStateLock
exit /b 0

rem ============================================================
rem RESOLVE BINARY PATH
rem ============================================================
:WhichBinary
set "WHICH_TARGET=!TARGET_CANDIDATE!"
if defined CLI_TARGET (
    if /i not "!CLI_TARGET!"=="SKIP_JAVA" (
        set "WHICH_TARGET=!CLI_TARGET!"
    )
)
if not defined WHICH_TARGET set "WHICH_TARGET=java"
call :ValidateStrictIdentifier "!WHICH_TARGET!" WHICH_TARGET
if errorlevel 1 (
    if "%OUTPUT_JSON%"=="1" (
        echo {"candidate":"!WHICH_TARGET!","binary":null,"status":"invalid_identifier"}
        exit /b 1
    )
    echo %cRED%[ ERROR  ]%cRESET% Invalid candidate name: "!WHICH_TARGET!"
    exit /b 1
)

if /i "!WHICH_TARGET!"=="java" (
    set "FOUND_WHICH_BIN="
    if defined JAVA_HOME (
        set "CLEAN_WHICH_JH=!JAVA_HOME:"=!"
        if exist "!CLEAN_WHICH_JH!\bin\java.exe" (
            for %%I in ("!CLEAN_WHICH_JH!\bin\java.exe") do set "FOUND_WHICH_BIN=%%~fI"
        )
    )
    if not defined FOUND_WHICH_BIN (
        for /f "delims=" %%A in ('%WHERE_BIN% $PATH:java 2^>nul') do (
            if not defined FOUND_WHICH_BIN set "FOUND_WHICH_BIN=%%A"
        )
    )
    if defined FOUND_WHICH_BIN (
        if "%OUTPUT_JSON%"=="1" (
            set "JSON_WB=!FOUND_WHICH_BIN:\=\\!"
            set "JSON_WB=!JSON_WB:"=!"
            echo {"candidate":"java","binary":"!JSON_WB!","status":"found"}
            exit /b 0
        )
        echo !FOUND_WHICH_BIN!
        exit /b 0
    )
    if "%OUTPUT_JSON%"=="1" (
        echo {"candidate":"java","binary":null,"status":"not_found"}
        exit /b 1
    )
    >&2 echo %cRED%[ ERROR  ]%cRESET% No java executable found in JAVA_HOME or PATH.
    exit /b 1
)

set "CAND_JUNC=%LOCALAPPDATA%\DiamTek\JVM\candidates\!WHICH_TARGET!\current"
set "CAND_ROOT=!CAND_JUNC!\bin"
if exist "!CAND_JUNC!" (
    "%FSUTIL_BIN%" reparsepoint query "!CAND_JUNC!" >nul 2>&1
    if errorlevel 1 (
        if "%OUTPUT_JSON%"=="1" (
            echo {"candidate":"!WHICH_TARGET!","binary":null,"status":"security_violation"}
            exit /b 1
        )
        >&2 echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): !CAND_JUNC! is a regular directory, not a junction.
        exit /b 1
    )
)
set "FOUND_CAND_BIN="
if exist "!CAND_ROOT!" (
    if /i "!WHICH_TARGET!"=="maven" (
        for /f "delims=" %%A in ('dir /b /s "!CAND_ROOT!\mvn.cmd" "!CAND_ROOT!\mvn.bat" 2^>nul') do (
            if not defined FOUND_CAND_BIN set "FOUND_CAND_BIN=%%A"
        )
    )
    if /i "!WHICH_TARGET!"=="kotlin" (
        for /f "delims=" %%A in ('dir /b /s "!CAND_ROOT!\kotlinc.bat" 2^>nul') do (
            if not defined FOUND_CAND_BIN set "FOUND_CAND_BIN=%%A"
        )
    )
    if /i "!WHICH_TARGET!"=="micronaut" (
        for /f "delims=" %%A in ('dir /b /s "!CAND_ROOT!\mn.bat" "!CAND_ROOT!\mn.cmd" "!CAND_ROOT!\mn.exe" 2^>nul') do (
            if not defined FOUND_CAND_BIN set "FOUND_CAND_BIN=%%A"
        )
    )
    if /i "!WHICH_TARGET!"=="mn" (
        for /f "delims=" %%A in ('dir /b /s "!CAND_ROOT!\mn.bat" "!CAND_ROOT!\mn.cmd" "!CAND_ROOT!\mn.exe" 2^>nul') do (
            if not defined FOUND_CAND_BIN set "FOUND_CAND_BIN=%%A"
        )
    )
    if not defined FOUND_CAND_BIN (
        for /f "delims=" %%A in ('dir /b /s "!CAND_ROOT!\!WHICH_TARGET!*.exe" "!CAND_ROOT!\!WHICH_TARGET!*.bat" "!CAND_ROOT!\!WHICH_TARGET!*.cmd" 2^>nul') do (
            if not defined FOUND_CAND_BIN set "FOUND_CAND_BIN=%%A"
        )
    )
    if not defined FOUND_CAND_BIN (
        for /f "delims=" %%A in ('dir /b /s "!CAND_ROOT!\*.cmd" "!CAND_ROOT!\*.bat" "!CAND_ROOT!\*.exe" 2^>nul') do (
            if not defined FOUND_CAND_BIN set "FOUND_CAND_BIN=%%A"
        )
    )
)
if defined FOUND_CAND_BIN (
    if "%OUTPUT_JSON%"=="1" (
        set "JSON_CB=!FOUND_CAND_BIN:\=\\!"
        set "JSON_CB=!JSON_CB:"=!"
        echo {"candidate":"!WHICH_TARGET!","binary":"!JSON_CB!","status":"found"}
        exit /b 0
    )
    echo !FOUND_CAND_BIN!
    exit /b 0
)
if "%OUTPUT_JSON%"=="1" (
    echo {"candidate":"!WHICH_TARGET!","binary":null,"status":"not_found"}
    exit /b 1
)
>&2 echo %cRED%[ ERROR  ]%cRESET% Candidate '!WHICH_TARGET!' is not installed or active.
exit /b 1

rem ============================================================
rem DOCTOR - SYSTEM HEALTH AUDIT & DIAGNOSTICS
rem ============================================================
:DoctorDiagnostics
if "%OUTPUT_JSON%"=="1" (
    set "DOC_STORAGE_OK=false"
    if exist "%LOCALAPPDATA%\DiamTek\JVM" set "DOC_STORAGE_OK=true"
    set "DOC_JUNC_OK=false"
    if exist "%LOCALAPPDATA%\DiamTek\JVM\current\bin\java.exe" set "DOC_JUNC_OK=true"
    set "DOC_JH_VAL=!JAVA_HOME!"
    if defined DOC_JH_VAL set "DOC_JH_VAL=!DOC_JH_VAL:\=\\!"
    if defined DOC_JH_VAL set "DOC_JH_VAL=!DOC_JH_VAL:"=!"
    set "DOC_FIRST_BIN="
    for /f "delims=" %%A in ('%WHERE_BIN% $PATH:java 2^>nul') do if not defined DOC_FIRST_BIN set "DOC_FIRST_BIN=%%A"
    if defined DOC_FIRST_BIN set "DOC_FIRST_BIN=!DOC_FIRST_BIN:\=\\!"
    if defined DOC_FIRST_BIN set "DOC_FIRST_BIN=!DOC_FIRST_BIN:"=!"
    echo {"status":"doctor","storage_root_ok":!DOC_STORAGE_OK!,"mode":"!SWITCH_MODE!","junction_ok":!DOC_JUNC_OK!,"java_home":"!DOC_JH_VAL!","active_binary":"!DOC_FIRST_BIN!","arch":"!SYS_ARCH!","installed_jdks":!JDK_COUNT!}
    exit /b 0
)
echo.
echo %cBLUE%[ ACTION ]%cRESET% Running DiamTek JVM System Health Audit...
echo ============================================================

set "DOC_ISSUES=0"

rem 1. Storage Root & Permissions
set "DOC_APPDIR=%LOCALAPPDATA%\DiamTek\JVM"
if exist "!DOC_APPDIR!" (
    for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "DOC_RANDOM_NAME=%%A"
set "DOC_TESTFILE=!DOC_APPDIR!\.health_check_!DOC_RANDOM_NAME!"
    copy /y nul "!DOC_TESTFILE!" >nul 2>&1
    if exist "!DOC_TESTFILE!" (
        del "!DOC_TESTFILE!" >nul 2>&1
        echo %cGREEN%[   OK   ]%cRESET% Storage Root:        !DOC_APPDIR! ^(Writable^)
    ) else (
        echo %cRED%[ ERROR  ]%cRESET% Storage Root:        !DOC_APPDIR! ^(Read-Only / Permission Denied^)
        set /a DOC_ISSUES+=1
    )
) else (
    echo %cYELLOW%[ WARNING]%cRESET% Storage Root:        !DOC_APPDIR! ^(Missing - run install.ps1^)
    set /a DOC_ISSUES+=1
)

rem 2. Mode & Junction Health
if /i "!SWITCH_MODE!"=="DIRECT" (
    echo %cBLUE%[  INFO  ]%cRESET% Architecture Mode:   [Registry Mode] ^(UAC Required for switches^)
) else (
    echo %cGREEN%[   OK   ]%cRESET% Architecture Mode:   [Symlink Mode] ^(User Junction, UAC-Free^)
    set "DOC_JUNC=%LOCALAPPDATA%\DiamTek\JVM\current"
    if exist "!DOC_JUNC!" (
        "%FSUTIL_BIN%" reparsepoint query "!DOC_JUNC!" >nul 2>&1
        if errorlevel 1 (
            echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): !DOC_JUNC! is a regular directory, not a junction.
            set /a DOC_ISSUES+=1
        ) else if exist "!DOC_JUNC!\bin\java.exe" (
            echo %cGREEN%[   OK   ]%cRESET% Directory Junction:  !DOC_JUNC! -^> !RESOLVED_JAVA_HOME!
        ) else (
            echo %cRED%[ ERROR  ]%cRESET% Directory Junction:  !DOC_JUNC! is broken ^(target missing java.exe^)
            set /a DOC_ISSUES+=1
        )
    ) else (
        echo %cYELLOW%[ WARNING]%cRESET% Directory Junction:  !DOC_JUNC! not initialized ^(switch with 'jvm ^<ver^>'^)
        set /a DOC_ISSUES+=1
    )
)

rem 3. JAVA_HOME Configuration & Sync
set "HKCU_JH="
for /f "tokens=2*" %%A in ('%REG_BIN% query "HKCU\Environment" /v JAVA_HOME 2^>nul') do set "HKCU_JH=%%B"
set "HKLM_JH="
for /f "tokens=2*" %%A in ('%REG_BIN% query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v JAVA_HOME 2^>nul') do set "HKLM_JH=%%B"

if defined INITIAL_SESSION_JH (
    set "CHK_SESS_JH=!INITIAL_SESSION_JH:"=!"
    if not "!CHK_SESS_JH!"=="!CHK_SESS_JH:;=!" (
        echo %cRED%[ ERROR  ]%cRESET% Session JAVA_HOME:   Security violation ^(CWE-88^): contains semicolon ';' delimiter
        set /a DOC_ISSUES+=1
    ) else if not exist "!CHK_SESS_JH!\bin\java.exe" (
        echo %cRED%[ ERROR  ]%cRESET% Session JAVA_HOME:   !CHK_SESS_JH! ^(Broken - missing bin\java.exe^)
        set /a DOC_ISSUES+=1
    )
)
if defined HKCU_JH (
    set "CLEAN_HKCU_JH=!HKCU_JH:"=!"
    if not "!CLEAN_HKCU_JH!"=="!CLEAN_HKCU_JH:;=!" (
        echo %cRED%[ ERROR  ]%cRESET% User JAVA_HOME:      Security violation ^(CWE-88^): contains semicolon ';' delimiter
        set /a DOC_ISSUES+=1
    ) else if not exist "!CLEAN_HKCU_JH!\bin\java.exe" (
        echo %cRED%[ ERROR  ]%cRESET% User JAVA_HOME:      !CLEAN_HKCU_JH! ^(Broken - missing bin\java.exe^)
        set /a DOC_ISSUES+=1
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% User JAVA_HOME:      !CLEAN_HKCU_JH!
    )
) else if defined HKLM_JH (
    set "CLEAN_HKLM_JH=!HKLM_JH:"=!"
    if not exist "!CLEAN_HKLM_JH!\bin\java.exe" (
        echo %cRED%[ ERROR  ]%cRESET% Machine JAVA_HOME:   !CLEAN_HKLM_JH! ^(Broken - missing bin\java.exe^)
        set /a DOC_ISSUES+=1
    ) else (
        echo %cBLUE%[  INFO  ]%cRESET% Machine JAVA_HOME:   !CLEAN_HKLM_JH!
    )
) else (
    echo %cYELLOW%[ WARNING]%cRESET% JAVA_HOME:           Not set in User or Machine registry
    set /a DOC_ISSUES+=1
)

rem 4. PATH Precedence & Shadowing Check
set "FIRST_JAVA="
set "SHADOW_FOUND=0"
for /f "delims=" %%A in ('%WHERE_BIN% $PATH:java 2^>nul') do (
    if not defined FIRST_JAVA (
        set "FIRST_JAVA=%%A"
        if /i not "!FIRST_JAVA:Common Files\Oracle\Java\javapath=!"=="!FIRST_JAVA!" set "SHADOW_FOUND=1"
        if /i not "!FIRST_JAVA:ProgramData\Oracle\Java\javapath=!"=="!FIRST_JAVA!" set "SHADOW_FOUND=1"
        if /i not "!FIRST_JAVA:System32\java.exe=!"=="!FIRST_JAVA!" set "SHADOW_FOUND=1"
    )
)

if not defined FIRST_JAVA (
    echo %cRED%[ ERROR  ]%cRESET% Active Binary:       'java.exe' not found in PATH
    set /a DOC_ISSUES+=1
) else if "!SHADOW_FOUND!"=="1" (
    echo %cYELLOW%[ WARNING]%cRESET% PATH Shadowing:      Rogue path found before JVM: !FIRST_JAVA!
    echo                        ^(Run 'jvm clear' to purge legacy Oracle javapath entries^)
    set /a DOC_ISSUES+=1
) else (
    echo %cGREEN%[   OK   ]%cRESET% PATH Precedence:     !FIRST_JAVA! ^(Clean^)
)

rem 5. PowerShell Profile Hook Check
set "DOC_HOOK_OK=0"
for /f "delims=" %%P in ('%PS_BIN% -NoProfile -Command "$userProfile = [Environment]::GetFolderPath('UserProfile'); $myDocs = [Environment]::GetFolderPath('MyDocuments'); $docPaths = @($myDocs, (Join-Path $userProfile 'Documents')) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique; $p = @($PROFILE); foreach ($doc in $docPaths) { $p += (Join-Path $doc 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'); $p += (Join-Path $doc 'PowerShell\Microsoft.PowerShell_profile.ps1') }; foreach ($f in ($p | Select-Object -Unique)) { if ($f -and (Test-Path -LiteralPath $f) -and (Select-String -LiteralPath $f -Pattern '# >>> jvm >>>' -Quiet)) { Write-Output 'FOUND'; break } }" 2^>nul') do (
    if "%%P"=="FOUND" set "DOC_HOOK_OK=1"
)
if "!DOC_HOOK_OK!"=="1" (
    echo %cGREEN%[   OK   ]%cRESET% PowerShell Hook:     Active in $PROFILE
) else (
    echo %cBLUE%[  INFO  ]%cRESET% PowerShell Hook:     Not installed ^(run 'jvm hook' or Settings -^> 2^)
)

rem 6. Hardware Architecture Match
echo %cGREEN%[   OK   ]%cRESET% CPU Architecture:    !SYS_ARCH! ^(Native %PROCESSOR_ARCHITECTURE% detected^)

rem 7. Installed JDK Inventory
echo %cGREEN%[   OK   ]%cRESET% Discovered JDKs:     !JDK_COUNT! installed distributions detected

echo ============================================================
if !DOC_ISSUES! EQU 0 (
    echo %cGREEN%[   OK   ]%cRESET% All diagnostic health checks passed. Zero conflicts detected.
    exit /b 0
) else (
    echo %cYELLOW%[ WARNING]%cRESET% Health check complete: !DOC_ISSUES! potential issues or warnings detected.
    exit /b 1
)

rem ============================================================
rem EPHEMERAL ONE-OFF COMMAND EXECUTION
rem ============================================================
:ExecuteEphemeralCommand
set "FOUND_EXEC_JDK="
if /i "!EXEC_TARGET!"=="latest" (
    if !LATEST_VER_NUM! GTR 0 set "FOUND_EXEC_JDK=!LATEST_JDK_PATH!"
) else if /i "!EXEC_TARGET!"=="lts" (
    if !LATEST_LTS_NUM! GTR 0 (
        for /l %%k in (1,1,!JDK_COUNT!) do (
            set "EXEC_MATCH=1"
            if defined CLI_VENDOR if /i "!JDK_VENDOR_%%k!" NEQ "!CLI_VENDOR!" set "EXEC_MATCH=0"
            if "!EXEC_MATCH!"=="1" if "!JDK_MAJOR_%%k!"=="!LATEST_LTS_NUM!" (
                if not defined FOUND_EXEC_JDK set "FOUND_EXEC_JDK=!JDK_PATH_%%k!"
            )
        )
    )
)

if not defined FOUND_EXEC_JDK (
    for /l %%k in (1,1,!JDK_COUNT!) do (
        set "EXEC_MATCH=1"
        if defined CLI_VENDOR if /i "!JDK_VENDOR_%%k!" NEQ "!CLI_VENDOR!" set "EXEC_MATCH=0"
        if "!EXEC_MATCH!"=="1" (
            if "!JDK_MAJOR_%%k!"=="!EXEC_TARGET!" (
                if not defined FOUND_EXEC_JDK set "FOUND_EXEC_JDK=!JDK_PATH_%%k!"
            )
            if /i "!JDK_NAME_%%k!"=="!EXEC_TARGET!" (
                if not defined FOUND_EXEC_JDK set "FOUND_EXEC_JDK=!JDK_PATH_%%k!"
            )
        )
    )
)

if not defined FOUND_EXEC_JDK (
    for /l %%k in (1,1,!JDK_COUNT!) do (
        set "EXEC_MATCH=1"
        if defined CLI_VENDOR if /i "!JDK_VENDOR_%%k!" NEQ "!CLI_VENDOR!" set "EXEC_MATCH=0"
        if "!EXEC_MATCH!"=="1" (
            for /f "delims=" %%T in ("!EXEC_TARGET!") do (
                if /i not "!JDK_NAME_%%k:%%T=!"=="!JDK_NAME_%%k!" (
                    if not defined FOUND_EXEC_JDK set "FOUND_EXEC_JDK=!JDK_PATH_%%k!"
                )
            )
        )
    )
)

if not defined FOUND_EXEC_JDK (
    echo.
    >&2 echo %cRED%[ ERROR  ]%cRESET% JDK '!EXEC_TARGET!' not found among installed JDKs.
    >&2 echo             Run 'jvm list' to view installed versions.
    exit /b 1
)

set "JAVA_HOME=!FOUND_EXEC_JDK!"
set "PATH=!FOUND_EXEC_JDK!\bin;!PATH!"

setlocal disabledelayedexpansion
"%CMD_BIN%" /d /s /c "%EXEC_CMD%"
set "EXEC_EXIT_CODE=%errorlevel%"
endlocal & exit /b %EXEC_EXIT_CODE%

rem ============================================================
rem OPEN DIRECTORY IN FILE EXPLORER
rem ============================================================
:OpenFolderInExplorer
if defined CLI_TARGET set "CLI_TARGET=!CLI_TARGET:"=!"
set "OPEN_PATH="
if /i "!CLI_TARGET!"=="current" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\current"
if /i "!CLI_TARGET!"=="java" (
    if defined JAVA_HOME (
        set "OPEN_PATH=!JAVA_HOME!"
    ) else (
        set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\current"
    )
)
if /i "!CLI_TARGET!"=="root" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM"
if /i "!CLI_TARGET!"=="appdata" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM"
if /i "!CLI_TARGET!"=="home" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM"
if /i "!CLI_TARGET!"=="dir" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM"
if /i "!CLI_TARGET!"=="config" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM"
if /i "!CLI_TARGET!"=="bin" (
    set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\bin"
    if not exist "!OPEN_PATH!" mkdir "!OPEN_PATH!" >nul 2>&1
)
if /i "!CLI_TARGET!"=="candidates" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates"
if /i "!CLI_TARGET!"=="downloads" (
    set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\downloads"
    if not exist "!OPEN_PATH!" mkdir "!OPEN_PATH!" >nul 2>&1
)
if /i "!CLI_TARGET!"=="cache" (
    set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\downloads"
    if not exist "!OPEN_PATH!" mkdir "!OPEN_PATH!" >nul 2>&1
)
if /i "!CLI_TARGET!"=="backup" (
    set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\backups"
    if not exist "!OPEN_PATH!" mkdir "!OPEN_PATH!" >nul 2>&1
)
if /i "!CLI_TARGET!"=="backups" (
    set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\backups"
    if not exist "!OPEN_PATH!" mkdir "!OPEN_PATH!" >nul 2>&1
)
if /i "!CLI_TARGET!"=="links" (
    set "OPEN_PATH=%LOCALAPPDATA%\JavaVersionManager\links"
    if not exist "!OPEN_PATH!" mkdir "!OPEN_PATH!" >nul 2>&1
)

if not defined OPEN_PATH (
    if /i not "!TARGET_CANDIDATE!"=="java" (
        set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!\current"
        if not exist "!OPEN_PATH!" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!"
    ) else if defined CLI_TARGET (
        if /i "!CLI_TARGET!"=="maven" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\maven\current"
        if /i "!CLI_TARGET!"=="gradle" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\gradle\current"
        if /i "!CLI_TARGET!"=="kotlin" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\kotlin\current"
        if /i "!CLI_TARGET!"=="scala" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\scala\current"
        if /i "!CLI_TARGET!"=="groovy" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\groovy\current"
        if /i "!CLI_TARGET!"=="ant" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\ant\current"
        if /i "!CLI_TARGET!"=="sbt" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\sbt\current"
        if /i "!CLI_TARGET!"=="jbang" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\jbang\current"
        if /i "!CLI_TARGET!"=="quarkus" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\quarkus\current"
        if /i "!CLI_TARGET!"=="spring" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\spring\current"
        if /i "!CLI_TARGET!"=="micronaut" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\micronaut\current"
        if /i "!CLI_TARGET!"=="mn" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\micronaut\current"
        if not exist "!OPEN_PATH!" if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\!CLI_TARGET!" set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\!CLI_TARGET!"
    )
)

if not defined OPEN_PATH (
    if defined CLI_TARGET (
        for /l %%k in (1,1,!JDK_COUNT!) do (
            if "!JDK_MAJOR_%%k!"=="!CLI_TARGET!" set "OPEN_PATH=!JDK_PATH_%%k!"
            if /i "!JDK_NAME_%%k!"=="!CLI_TARGET!" set "OPEN_PATH=!JDK_PATH_%%k!"
        )
    )
)

if defined CLI_TARGET if not defined OPEN_PATH (
    echo.
    >&2 echo %cRED%[ ERROR  ]%cRESET% Unknown or uninstalled target for 'jvm open': !CLI_TARGET!
    exit /b 1
)

if not defined OPEN_PATH (
    if defined RESOLVED_JAVA_HOME (
        set "OPEN_PATH=!RESOLVED_JAVA_HOME!"
    ) else if defined JAVA_HOME (
        set "OPEN_PATH=!JAVA_HOME!"
    ) else if exist "%LOCALAPPDATA%\DiamTek\JVM\current" (
        set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM\current"
    ) else (
        set "OPEN_PATH=%LOCALAPPDATA%\DiamTek\JVM"
    )
)

rem Canonicalize OPEN_PATH and block explorer.exe comma/flag/UNC/CLSID injection (CWE-88)
for /f "delims=" %%I in ("!OPEN_PATH!") do set "OPEN_PATH=%%~fI"
if "!OPEN_PATH:~0,1!"=="/" ( >&2 echo %cRED%[ ERROR  ]%cRESET% Invalid path for explorer. & exit /b 1 )
if "!OPEN_PATH:~0,2!"=="\\" ( >&2 echo %cRED%[ ERROR  ]%cRESET% UNC paths are forbidden in 'jvm open'. & exit /b 1 )
if not "!OPEN_PATH!"=="!OPEN_PATH:,=!" (
    >&2 echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-88^): Target path contains comma delimiter forbidden by explorer.exe.
    exit /b 1
)
if not "!OPEN_PATH!"=="!OPEN_PATH:::{=!" (
    >&2 echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-88^): Shell CLSID namespace forbidden.
    exit /b 1
)

if not exist "!OPEN_PATH!\" (
    echo.
    >&2 echo %cRED%[ ERROR  ]%cRESET% Target path does not exist: !OPEN_PATH!
    exit /b 1
)

echo %cBLUE%[ ACTION ]%cRESET% Opening File Explorer: !OPEN_PATH!
start "" "%EXPLORER_BIN%" "!OPEN_PATH!"
exit /b 0

rem ============================================================
rem JVM Version / About Menu
rem ============================================================
:AboutMenu
rem cls
if defined UPDATE_CHANNEL_OVERRIDE (
    if /i "!UPDATE_CHANNEL_OVERRIDE!"=="NIGHTLY" (
        set "UPDATE_CHANNEL=NIGHTLY"
    ) else (
        set "UPDATE_CHANNEL=STABLE"
    )
)
if /i "!UPDATE_CHANNEL!"=="NIGHTLY" (
    set "UPDATE_CHANNEL=NIGHTLY"
    set "CH_TAG=%cPURPLE%[Nightly]%cRESET%"
) else (
    set "UPDATE_CHANNEL=STABLE"
    set "CH_TAG=%cGREEN%[Stable]%cRESET%"
)
echo ============================================================
echo                     Java Version Manager
echo ============================================================
echo.
echo Version: !JVM_VERSION!
echo Build:   !JVM_BUILD!
echo Channel: !CH_TAG!
echo.
echo Developed by DiamTek / Alexéy Shishkin
echo Licensed under the GNU AGPL v3.0
echo.
echo ============================================================
echo.
echo %cBLUE%[ ACTION ]%cRESET% Checking for updates ^(!CH_TAG! channel^)...

rem Fetch latest build from GitHub based on active update channel
call :CheckUpdateStatus

if "!UPDATE_FLAG!"=="RATE_LIMIT" (
    echo %cYELLOW%[ WARN   ]%cRESET% GitHub API rate limit reached ^(HTTP 429/403^). Please wait or retry later.
    if not defined CLI_COMMAND (
        echo.
        echo Press any key to return...
        pause >nul
    )
    goto :eof
)
if "!UPDATE_FLAG!"=="SERVER_ERROR" (
    echo %cRED%[ ERROR  ]%cRESET% GitHub server is temporarily unavailable ^(HTTP 5xx^). Please retry later.
    if not defined CLI_COMMAND (
        echo.
        echo Press any key to return...
        pause >nul
    )
    goto :eof
)
if "!UPDATE_FLAG!"=="ERROR" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to connect to GitHub. Please check your internet connection.
    if not defined CLI_COMMAND (
        echo.
        echo Press any key to return...
        pause >nul
    )
    goto :eof
)

if "!UPDATE_FLAG!"=="NO_STABLE_RELEASE" (
    echo %cYELLOW%[  INFO  ]%cRESET% No official tagged releases published on GitHub yet.
    echo            Switch to Nightly to track cutting-edge builds:
    echo            Run '%cCYAN%jvm channel nightly%cRESET%'
    if not defined CLI_COMMAND (
        echo.
        echo Press any key to return...
        pause >nul
    )
    goto :eof
)

if "!UPDATE_FLAG!"=="AHEAD_OF_STABLE" (
    echo %cYELLOW%[  INFO  ]%cRESET% You are running an unreleased build ahead of official releases.
    echo            Installed:   v!JVM_VERSION! ^(Build !JVM_BUILD!^)
    if "!REMOTE_BUILD!"=="N/A" (
        echo            Latest GA:   v!REMOTE_VER! ^(!REMOTE_REF!^)
    ) else (
        echo            Latest GA:   v!REMOTE_VER! ^(Build !REMOTE_BUILD!^) ^(!REMOTE_REF!^)
    )
    echo.
    echo            Switch to Nightly to track cutting-edge updates:
    echo            Run '%cCYAN%jvm channel nightly%cRESET%'
    if not defined CLI_COMMAND (
        echo.
        echo Press any key to return...
        pause >nul
    )
    goto :eof
)

if "!UPDATE_FLAG!"=="AHEAD_OF_NIGHTLY" (
    echo %cYELLOW%[  INFO  ]%cRESET% You are running a local build ahead of 'main'.
    echo            Installed:   v!JVM_VERSION! ^(Build !JVM_BUILD!^)
    if "!REMOTE_BUILD!"=="N/A" (
        echo            Latest Main: v!REMOTE_VER! ^(!REMOTE_REF!^)
    ) else (
        echo            Latest Main: v!REMOTE_VER! ^(Build !REMOTE_BUILD!^) ^(!REMOTE_REF!^)
    )
    if not defined CLI_COMMAND (
        echo.
        echo Press any key to return...
        pause >nul
    )
    goto :eof
)

if "!UPDATE_FLAG!"=="UNKNOWN" (
    echo %cYELLOW%[ WARNING]%cRESET% Could not parse remote build version.
    if not defined CLI_COMMAND (
        echo.
        echo Press any key to return...
        pause >nul
    )
    goto :eof
)

if "!UPDATE_FLAG!"=="INVALID_REMOTE" (
    echo %cYELLOW%[ WARNING]%cRESET% Remote version '!REMOTE_VER!' is not a valid Semantic Version.
    if not defined CLI_COMMAND (
        echo.
        echo Press any key to return...
        pause >nul
    )
    goto :eof
)

if "!UPDATE_FLAG!"=="UPDATE" (
    echo %cYELLOW%[ UPDATE ]%cRESET% A newer version of Java Version Manager is available ^(!CH_TAG! channel^).
    if /i "!UPDATE_CHANNEL!"=="NIGHTLY" (
        echo            Installed:      v!JVM_VERSION! ^(Build !JVM_BUILD!^)
        if "!REMOTE_BUILD!"=="N/A" (
            echo            Latest Nightly: v!REMOTE_VER! ^(!REMOTE_REF!^)
        ) else (
            echo            Latest Nightly: v!REMOTE_VER! ^(Build !REMOTE_BUILD!^) ^(!REMOTE_REF!^)
        )
    ) else (
        echo            Installed:      v!JVM_VERSION! ^(Build !JVM_BUILD!^)
        if "!REMOTE_BUILD!"=="N/A" (
            echo            Latest GA:      v!REMOTE_VER! ^(!REMOTE_REF!^)
        ) else (
            echo            Latest GA:      v!REMOTE_VER! ^(Build !REMOTE_BUILD!^) ^(!REMOTE_REF!^)
        )
    )
    echo.
    if not defined CLI_COMMAND (
        "%CHOICE_BIN%" /C yn /N /M "Would you like to download and install this update? (y/N): "
        if !errorlevel! EQU 1 (
            call :SelfUpdate
        )
    ) else (
        echo Run 'jvm self-update' to install the latest version.
    )
    goto :eof
) else (
    echo %cGREEN%[   OK   ]%cRESET% You are running the latest version ^(v!JVM_VERSION!, Build !JVM_BUILD!^) ^(!CH_TAG! channel^).
    if not defined CLI_COMMAND (
        echo.
        echo Press any key to return...
        pause >nul
    )
    goto :eof
)

rem ============================================================
rem Self-Updater
rem ============================================================
:SelfUpdate
call :RequireNetwork
if errorlevel 1 (
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
if defined UPDATE_CHANNEL_OVERRIDE (
    if /i "!UPDATE_CHANNEL_OVERRIDE!"=="NIGHTLY" (
        set "UPDATE_CHANNEL=NIGHTLY"
    ) else (
        set "UPDATE_CHANNEL=STABLE"
    )
)
if /i "!UPDATE_CHANNEL!"=="NIGHTLY" (
    set "UPDATE_CHANNEL=NIGHTLY"
    set "CH_TAG=%cPURPLE%[Nightly]%cRESET%"
) else (
    set "UPDATE_CHANNEL=STABLE"
    set "CH_TAG=%cGREEN%[Stable]%cRESET%"
)
if "!CLI_COMMAND!"=="self-update" (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking for updates ^(!CH_TAG! channel^)...
    call :CheckUpdateStatus

    if "!UPDATE_FLAG!"=="RATE_LIMIT" (
        echo %cYELLOW%[ WARN   ]%cRESET% GitHub API rate limit reached ^(HTTP 429/403^). Please wait or retry later.
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!UPDATE_FLAG!"=="SERVER_ERROR" (
        echo %cRED%[ ERROR  ]%cRESET% GitHub server is temporarily unavailable ^(HTTP 5xx^). Please retry later.
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!UPDATE_FLAG!"=="ERROR" (
        echo %cRED%[ ERROR  ]%cRESET% Failed to connect to GitHub. Please check your internet connection.
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!UPDATE_FLAG!"=="NO_STABLE_RELEASE" (
        echo.
        echo %cYELLOW%[  INFO  ]%cRESET% No official tagged releases published on GitHub yet.
        echo            Installed:   v!JVM_VERSION! ^(Build !JVM_BUILD!^)
        echo.
        echo            Switch to Nightly to track cutting-edge builds:
        echo            Run '%cCYAN%jvm channel nightly ^& jvm self-update%cRESET%'
        goto :eof
    )
    if "!UPDATE_FLAG!"=="AHEAD_OF_STABLE" (
        echo.
        echo %cYELLOW%[  INFO  ]%cRESET% You are running an unreleased build ahead of official releases.
        echo            Installed:   v!JVM_VERSION! ^(Build !JVM_BUILD!^)
        if "!REMOTE_BUILD!"=="N/A" (
            echo            Latest GA:   v!REMOTE_VER! ^(!REMOTE_REF!^)
        ) else (
            echo            Latest GA:   v!REMOTE_VER! ^(Build !REMOTE_BUILD!^) ^(!REMOTE_REF!^)
        )
        echo.
        echo            No stable downgrade will be performed.
        echo            Switch to Nightly to update from 'main':
        echo            Run '%cCYAN%jvm channel nightly ^& jvm self-update%cRESET%'
        goto :eof
    )
    if "!UPDATE_FLAG!"=="AHEAD_OF_NIGHTLY" (
        echo.
        echo %cYELLOW%[  INFO  ]%cRESET% You are running a local build ahead of 'main'.
        echo            Installed:   v!JVM_VERSION! ^(Build !JVM_BUILD!^)
        if "!REMOTE_BUILD!"=="N/A" (
            echo            Latest Main: v!REMOTE_VER! ^(!REMOTE_REF!^)
        ) else (
            echo            Latest Main: v!REMOTE_VER! ^(Build !REMOTE_BUILD!^) ^(!REMOTE_REF!^)
        )
        echo.
        echo            No nightly downgrade will be performed.
        goto :eof
    )
    if "!UPDATE_FLAG!"=="UNKNOWN" (
        echo %cYELLOW%[ WARNING]%cRESET% Could not parse remote build version.
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!UPDATE_FLAG!"=="INVALID_REMOTE" (
        echo %cYELLOW%[ WARNING]%cRESET% Remote version '!REMOTE_VER!' is not a valid Semantic Version.
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!UPDATE_FLAG!"=="OK" (
        echo %cGREEN%[   OK   ]%cRESET% You are already running the latest version ^(v!JVM_VERSION!, Build !JVM_BUILD!^) on the !CH_TAG! channel.
        goto :eof
    )
)

if not defined REMOTE_REF set "REMOTE_REF=HEAD"
if "!REMOTE_REF!"=="NONE" set "REMOTE_REF=HEAD"

echo.
echo %cBLUE%[ ACTION ]%cRESET% Connecting to GitHub repository...

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "INS_RANDOM_NAME=%%A"
set "INSTALL_SCRIPT=%JVM_SECURE_TEMP%\jvm_install_!INS_RANDOM_NAME!.ps1"
"%FSUTIL_BIN%" reparsepoint query "!INSTALL_SCRIPT!" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Staged installer path is a reparse point.
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288; $ProgressPreference = 'SilentlyContinue'; $ref = $env:REMOTE_REF; try { Invoke-WebRequest -Uri ('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/contents/install.ps1?ref=' + $ref) -Headers @{ 'Accept'='application/vnd.github.v3.raw'; 'Cache-Control'='no-cache'; 'Pragma'='no-cache' } -UserAgent 'DiamTek-JVM' -OutFile $env:INSTALL_SCRIPT -UseBasicParsing -TimeoutSec 5 } catch { Invoke-WebRequest -Uri ('https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/' + $ref + '/install.ps1?t=' + [DateTimeOffset]::UtcNow.Ticks) -Headers @{ 'Cache-Control'='no-cache'; 'Pragma'='no-cache' } -OutFile $env:INSTALL_SCRIPT -UseBasicParsing -TimeoutSec 5 }"

if not exist "!INSTALL_SCRIPT!" (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Failed to download the latest installer.
    if "!CLI_COMMAND!"=="" pause
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
"%FSUTIL_BIN%" reparsepoint query "!INSTALL_SCRIPT!" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Downloaded installer is a reparse point.
    if exist "!INSTALL_SCRIPT!" del /f /q "!INSTALL_SCRIPT!" >nul 2>&1
    set "JVM_EXIT_CODE=1"
    exit /b 1
)

echo %cBLUE%[ ACTION ]%cRESET% Verifying installer cryptographic integrity...
set "VERIFY_TMP=%JVM_SECURE_TEMP%\jvm_sha_!INS_RANDOM_NAME!.txt"
"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288; $ProgressPreference = 'SilentlyContinue'; $ref = $env:REMOTE_REF; $ch = $env:UPDATE_CHANNEL; $f = $env:INSTALL_SCRIPT; if (-not (Test-Path -LiteralPath $f)) { Write-Output 'MISSING'; exit }; $txt = [System.IO.File]::ReadAllText($f); if ($txt.Length -lt 200 -or $txt -notmatch 'rem END OF SCRIPT|# Java Version Manager' -or $txt -notmatch 'param\s*\(' -or $txt -notmatch 'DiamTek') { Write-Output 'TRUNCATED'; exit }; $s = [System.Security.Cryptography.SHA256]::Create(); $fs = [System.IO.File]::OpenRead($f); $actual = try { ([System.BitConverter]::ToString($s.ComputeHash($fs)) -replace '-','').ToLower() } finally { $fs.Close(); $s.Dispose() }; if ($ch -eq 'STABLE' -and $ref -match '^v?[0-9]') { $shaTxt = $null; try { $rc = (Invoke-WebRequest -Uri ('https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/' + $ref + '/SHA256SUMS.txt') -Headers @{'Cache-Control'='no-cache'} -UserAgent 'DiamTek-JVM' -UseBasicParsing -TimeoutSec 5).Content; $shaTxt = if ($rc -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($rc) } else { [string]$rc } } catch {}; if (-not $shaTxt) { try { $relJson = (Invoke-RestMethod -Uri ('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/releases/tags/' + $ref) -UserAgent 'DiamTek-JVM'); $asset = $relJson.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' } | Select-Object -First 1; if ($asset) { $rc = (Invoke-WebRequest -Uri $asset.browser_download_url -UserAgent 'DiamTek-JVM' -UseBasicParsing -TimeoutSec 5).Content; $shaTxt = if ($rc -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($rc) } else { [string]$rc } } } catch {} }; if ($shaTxt) { $exp = $null; foreach ($line in ($shaTxt -split '\r?\n')) { if ($line.Trim() -match '^([0-9a-fA-F]{64})\s+[\*]?install\.ps1$') { $exp = $matches[1].ToLower(); break } }; if ($exp) { if ($actual -eq $exp) { Write-Output ('VERIFIED|' + $exp) } else { Write-Output ('MISMATCH|' + $exp + '|' + $actual) } } else { Write-Output ('NO_ENTRY|' + $actual) } } else { Write-Output ('NO_SHA_FILE|' + $actual) } } else { $metaSha = $null; try { $meta = Invoke-RestMethod -Uri ('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/contents/install.ps1?ref=' + $ref) -Headers @{'Cache-Control'='no-cache'} -UserAgent 'DiamTek-JVM' -TimeoutSec 5; if ($meta -and $meta.sha) { $metaSha = ([string]$meta.sha).ToLower() } } catch {}; if ($metaSha) { $sha1 = [System.Security.Cryptography.SHA1]::Create(); try { $rawBytes = [System.IO.File]::ReadAllBytes($f); $lfBytes = [System.Text.Encoding]::UTF8.GetBytes(($txt -replace '\r\n', \"`n\")); $crlfBytes = [System.Text.Encoding]::UTF8.GetBytes(($txt -replace '\r?\n', \"`r`n\")); $matchedGit = $false; $computedGit = ''; foreach ($b in @($rawBytes, $lfBytes, $crlfBytes)) { $hdr = [System.Text.Encoding]::ASCII.GetBytes('blob ' + $b.Length + [char]0); $blob = New-Object byte[] ($hdr.Length + $b.Length); [Array]::Copy($hdr, 0, $blob, 0, $hdr.Length); [Array]::Copy($b, 0, $blob, $hdr.Length, $b.Length); $g = ([System.BitConverter]::ToString($sha1.ComputeHash($blob)) -replace '-','').ToLower(); if (-not $computedGit) { $computedGit = $g }; if ($g -eq $metaSha) { $matchedGit = $true; break } }; if ($matchedGit) { Write-Output ('VERIFIED|' + $actual) } else { Write-Output ('MISMATCH|' + $metaSha + '|' + $computedGit) } } finally { $sha1.Dispose() } } else { Write-Output ('NO_META_SHA|' + $actual) } }" > "!VERIFY_TMP!" 2>nul

set "SHA_STATUS=UNKNOWN"
set "SHA_EXP="
set "SHA_ACT="
if exist "!VERIFY_TMP!" (
    for /f "usebackq tokens=1,2,3 delims=|" %%A in ("!VERIFY_TMP!") do (
        set "SHA_STATUS=%%A"
        set "SHA_EXP=%%B"
        set "SHA_ACT=%%C"
    )
    del "!VERIFY_TMP!" >nul 2>&1
)

if "!UPDATE_CHANNEL!"=="STABLE" (
    if not "!SHA_STATUS!"=="VERIFIED" (
        echo.
        echo %cRED%[ ERROR  ]%cRESET% Cryptographic integrity verification failed for install.ps1 on [Stable] channel!
        if "!SHA_STATUS!"=="MISMATCH" (
            echo            Expected: !SHA_EXP!
            echo            Computed: !SHA_ACT!
            echo            Checksum mismatch detected. Download may be corrupted or compromised.
        ) else if "!SHA_STATUS!"=="NO_SHA_FILE" (
            echo            Official SHA256SUMS.txt could not be retrieved from release assets.
        ) else if "!SHA_STATUS!"=="NO_ENTRY" (
            echo            No SHA-256 checksum entry for install.ps1 found in release manifest.
        ) else if "!SHA_STATUS!"=="TRUNCATED" (
            echo            Downloaded installer file is corrupted or truncated.
        ) else (
            echo            Integrity status: !SHA_STATUS! - Verification could not be completed.
        )
        echo            Update aborted to protect system integrity.
        if exist "!INSTALL_SCRIPT!" del "!INSTALL_SCRIPT!" >nul 2>&1
        if "!CLI_COMMAND!"=="" pause
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    echo %cGREEN%[   OK   ]%cRESET% Cryptographic integrity verified ^(SHA-256: !SHA_EXP:~0,16!...^)
) else (
    if not "!SHA_STATUS!"=="VERIFIED" (
        echo.
        echo %cRED%[ ERROR  ]%cRESET% Cryptographic integrity check failed for install.ps1 on [Nightly] channel ^(!SHA_STATUS!^)!
        if "!SHA_STATUS!"=="MISMATCH" (
            echo            Expected: !SHA_EXP!
            echo            Computed: !SHA_ACT!
        )
        echo            Update aborted to prevent untrusted execution ^(CWE-494^).
        if exist "!INSTALL_SCRIPT!" del "!INSTALL_SCRIPT!" >nul 2>&1
        if "!CLI_COMMAND!"=="" pause
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    echo %cGREEN%[   OK   ]%cRESET% Cryptographic integrity verified ^(SHA-256: !SHA_EXP:~0,16!...^)
)

echo %cBLUE%[ ACTION ]%cRESET% Preparing update handoff engine...
for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "BAT_RANDOM_NAME=%%A"
set "UPDATER_BAT=%JVM_SECURE_TEMP%\jvm_updater_!BAT_RANDOM_NAME!.bat"
"%FSUTIL_BIN%" reparsepoint query "!UPDATER_BAT!" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Staged updater path is a reparse point.
    if exist "!INSTALL_SCRIPT!" del "!INSTALL_SCRIPT!" >nul 2>&1
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
(
    echo @echo off
    echo for /F "delims=#" %%%%a in ^('"prompt #$E# ^& echo on ^& for %%%%b in ^(1^) do rem"'^) do set "ESC=%%%%a"
    echo set "cGREEN=%%ESC%%[92m"
    echo set "cRED=%%ESC%%[91m"
    echo set "cBLUE=%%ESC%%[96m"
    echo set "cRESET=%%ESC%%[0m"
    echo echo.
    echo "%FSUTIL_BIN%" reparsepoint query "!SCRIPT_DIR!\jvm.bat.old" ^>nul 2^>^&1 ^&^& del /f /q "!SCRIPT_DIR!\jvm.bat.old" ^>nul 2^>^&1
    echo "%FSUTIL_BIN%" reparsepoint query "!SCRIPT_DIR!\uninstall.ps1.old" ^>nul 2^>^&1 ^&^& del /f /q "!SCRIPT_DIR!\uninstall.ps1.old" ^>nul 2^>^&1
    echo if exist "!SCRIPT_DIR!\jvm.bat" copy /y "!SCRIPT_DIR!\jvm.bat" "!SCRIPT_DIR!\jvm.bat.old" ^>nul 2^>^&1
    echo if exist "!SCRIPT_DIR!\uninstall.ps1" copy /y "!SCRIPT_DIR!\uninstall.ps1" "!SCRIPT_DIR!\uninstall.ps1.old" ^>nul 2^>^&1
    echo "!PS_BIN!" -NoProfile -ExecutionPolicy Bypass -File "!INSTALL_SCRIPT!" -Update -TargetDir "!SCRIPT_DIR!" -Branch "!REMOTE_REF!" -Channel "!UPDATE_CHANNEL!"
    echo set "UPD_ERR=%%errorlevel%%"
    echo if exist "!INSTALL_SCRIPT!" del /f /q "!INSTALL_SCRIPT!" ^>nul 2^>^&1
    echo if not exist "!SCRIPT_DIR!\jvm.bat" set "UPD_ERR=1"
    echo if exist "%LOCALAPPDATA%\DiamTek\JVM\state.lock\owner.pid" del /f /q "%LOCALAPPDATA%\DiamTek\JVM\state.lock\owner.pid" ^>nul 2^>^&1
    echo if exist "%LOCALAPPDATA%\DiamTek\JVM\state.lock" rmdir "%LOCALAPPDATA%\DiamTek\JVM\state.lock" ^>nul 2^>^&1
    echo if %%UPD_ERR%% NEQ 0 ^(
    echo     if exist "!SCRIPT_DIR!\jvm.bat.old" move /y "!SCRIPT_DIR!\jvm.bat.old" "!SCRIPT_DIR!\jvm.bat" ^>nul 2^>^&1
    echo     if exist "!SCRIPT_DIR!\uninstall.ps1.old" move /y "!SCRIPT_DIR!\uninstall.ps1.old" "!SCRIPT_DIR!\uninstall.ps1" ^>nul 2^>^&1
    echo     echo.
    echo     echo %%cRED%%[ ERROR  ]%%cRESET%% Update encountered an error. Rolled back to previous version.
    if not defined CLI_COMMAND (
        echo     pause
    )
    echo     ^(goto^) 2^>nul ^& del /f /q "%%~f0" ^>nul 2^>^&1 ^& exit /b 1
    echo ^)
    echo if exist "!SCRIPT_DIR!\jvm.bat.old" del /f /q "!SCRIPT_DIR!\jvm.bat.old" ^>nul 2^>^&1
    echo if exist "!SCRIPT_DIR!\uninstall.ps1.old" del /f /q "!SCRIPT_DIR!\uninstall.ps1.old" ^>nul 2^>^&1
    echo echo.
    echo echo %%cGREEN%%[   OK   ]%%cRESET%% Java Version Manager successfully updated.
    echo echo.
    if defined CLI_COMMAND (
        echo ^(goto^) 2^>nul ^& del /f /q "%%~f0" ^>nul 2^>^&1 ^& exit /b 0
    ) else (
        echo echo Press any key to return to Java Version Manager...
        echo pause ^>nul
        echo cls
        echo "%~f0"
    )
) > "!UPDATER_BAT!"

rem Chain execution to external updater in secure temp so jvm.bat is immediately closed by cmd.exe!
call :AcquireStateLock
"!UPDATER_BAT!"
exit /b 0

rem ============================================================
rem Query Remote Update Status Helper
rem ============================================================
:CheckUpdateStatus
call :RequireNetwork
if errorlevel 1 (
    set "UPDATE_FLAG=ERROR"
    exit /b 1
)
if defined UPDATE_CHANNEL_OVERRIDE (
    if /i "!UPDATE_CHANNEL_OVERRIDE!"=="NIGHTLY" (
        set "UPDATE_CHANNEL=NIGHTLY"
    ) else (
        set "UPDATE_CHANNEL=STABLE"
    )
)
set "PS_SCRIPT=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288; $ProgressPreference = 'SilentlyContinue'; $localVer = [version]'!JVM_VERSION!'; $localBld = [version]'!JVM_BUILD!'; $channel = '!UPDATE_CHANNEL!'; if ($channel -eq 'STABLE') { $data = $null; $tagName = $null; try { $api = [Net.HttpWebRequest]::Create('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/releases/latest'); $api.UserAgent = 'DiamTek-JVM'; $api.Timeout = 3000; $apiRes = $api.GetResponse(); try { $sr = New-Object System.IO.StreamReader($apiRes.GetResponseStream()); try { $raw = $sr.ReadToEnd() } finally { $sr.Close() } } finally { $apiRes.Close() }; $data = $raw | ConvertFrom-Json; if ($data -and $data.tag_name) { $tagName = [string]$data.tag_name; } } catch { try { $req = [Net.HttpWebRequest]::Create('https://github.com/DiamTek/Java-Version-Manager-Windows/releases/latest'); $req.AllowAutoRedirect = $false; $req.UserAgent = 'DiamTek-JVM'; $req.Timeout = 3000; $res = $req.GetResponse(); try { $loc = [string]$res.Headers['Location'] } finally { $res.Close() }; if ($loc -match '^https://github\.com/DiamTek/Java-Version-Manager-Windows/releases/tag/(v?[0-9]+\.[0-9]+\.[0-9]+)$') { $tagName = $matches[1]; } } catch [Net.WebException] { $resp = $_.Exception.Response; if ($resp) { $code = [int]$resp.StatusCode; if ($code -eq 404) { Write-Output 'NONE|NONE|NO_STABLE_RELEASE|NONE'; exit; } elseif ($code -eq 429 -or $code -eq 403) { Write-Output 'NONE|NONE|RATE_LIMIT|NONE'; exit; } elseif ($code -ge 500) { Write-Output 'NONE|NONE|SERVER_ERROR|NONE'; exit; } } } catch {} }; if (-not $tagName) { Write-Output 'NONE|NONE|NO_STABLE_RELEASE|NONE'; exit; }; $tagVerStr = $null; if ($tagName -match '^v?([0-9]+(\.[0-9]+)+)') { $tagVerStr = $matches[1]; } elseif ($tagName -match '^v?([0-9]+)') { $tagVerStr = $matches[1] + '.0'; }; if (-not $tagVerStr) { Write-Output ($tagName + '|UNKNOWN|INVALID_REMOTE|' + $tagName); exit; }; try { $remoteVer = [version]$tagVerStr; } catch { Write-Output ($tagVerStr + '|UNKNOWN|INVALID_REMOTE|' + $tagName); exit; }; $remBuild = $null; $remBldStr = 'N/A'; try { $rawUrl = 'https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/' + $tagName + '/jvm.bat?t=' + [DateTimeOffset]::UtcNow.Ticks; $req = [Net.HttpWebRequest]::Create($rawUrl); $req.Timeout = 3000; $req.UserAgent = 'DiamTek-JVM'; $res = $req.GetResponse(); try { $sr = New-Object System.IO.StreamReader($res.GetResponseStream()); try { $c = $sr.ReadToEnd() } finally { $sr.Close() } } finally { $res.Close() }; if ($c -match 'set \x22JVM_BUILD=(.*?)\x22') { $remBuild = [version]$matches[1]; $remBldStr = $matches[1]; } } catch {}; if ($remoteVer -gt $localVer) { Write-Output ($tagVerStr + '|' + $remBldStr + '|UPDATE|' + $tagName); } elseif ($remoteVer -lt $localVer) { Write-Output ($tagVerStr + '|' + $remBldStr + '|AHEAD_OF_STABLE|' + $tagName); } else { if ($remBuild) { if ($remBuild -gt $localBld) { Write-Output ($tagVerStr + '|' + $remBldStr + '|UPDATE|' + $tagName); } elseif ($remBuild -lt $localBld) { Write-Output ($tagVerStr + '|' + $remBldStr + '|AHEAD_OF_STABLE|' + $tagName); } else { Write-Output ($tagVerStr + '|' + $remBldStr + '|OK|' + $tagName); } } else { Write-Output ($tagVerStr + '|' + $remBldStr + '|OK|' + $tagName); } } } else { $commitSha = 'main'; try { $api = [Net.HttpWebRequest]::Create('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/commits/main'); $api.UserAgent = 'DiamTek-JVM'; $api.Timeout = 3000; $apiRes = $api.GetResponse(); try { $sr = New-Object System.IO.StreamReader($apiRes.GetResponseStream()); try { $raw = $sr.ReadToEnd() } finally { $sr.Close() } } finally { $apiRes.Close() }; $cData = $raw | ConvertFrom-Json; if ($cData -and $cData.sha) { $commitSha = $cData.sha.Substring(0, 7); } } catch { $commitSha = 'main'; }; $content = $null; try { $req = [Net.HttpWebRequest]::Create('https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/jvm.bat?t=' + [DateTimeOffset]::UtcNow.Ticks); $req.Method = 'GET'; $req.Timeout = 4000; $req.UserAgent = 'DiamTek-JVM'; $req.Headers.Add('Cache-Control', 'no-cache'); $req.Headers.Add('Pragma', 'no-cache'); $res = $req.GetResponse(); try { $sr = New-Object System.IO.StreamReader($res.GetResponseStream()); try { $content = $sr.ReadToEnd() } finally { $sr.Close() } } finally { $res.Close() }; } catch { try { $apiReq = [Net.HttpWebRequest]::Create('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/contents/jvm.bat?ref=main'); $apiReq.Method = 'GET'; $apiReq.Timeout = 4000; $apiReq.UserAgent = 'DiamTek-JVM'; $apiReq.Accept = 'application/vnd.github.v3.raw'; $apiReq.Headers.Add('Cache-Control', 'no-cache'); $apiReq.Headers.Add('Pragma', 'no-cache'); $apiRes = $apiReq.GetResponse(); try { $sr = New-Object System.IO.StreamReader($apiRes.GetResponseStream()); try { $content = $sr.ReadToEnd() } finally { $sr.Close() } } finally { $apiRes.Close() }; } catch {} }; if (-not $content) { Write-Output 'UNKNOWN|UNKNOWN|ERROR|main'; exit; }; $remVerStr = '1.0.1'; $remBldStr = 'UNKNOWN'; if ($content -match 'set \x22JVM_VERSION=(.*?)\x22') { $remVerStr = $matches[1]; }; if ($content -match 'set \x22JVM_BUILD=(.*?)\x22') { $remBldStr = $matches[1]; }; try { $remoteVer = [version]$remVerStr; $remoteBld = [version]$remBldStr; if ($remoteVer -gt $localVer) { Write-Output ($remVerStr + '|' + $remBldStr + '|UPDATE|' + $commitSha); } elseif ($remoteVer -lt $localVer) { Write-Output ($remVerStr + '|' + $remBldStr + '|AHEAD_OF_NIGHTLY|' + $commitSha); } else { if ($remoteBld -gt $localBld) { Write-Output ($remVerStr + '|' + $remBldStr + '|UPDATE|' + $commitSha); } elseif ($remoteBld -lt $localBld) { Write-Output ($remVerStr + '|' + $remBldStr + '|AHEAD_OF_NIGHTLY|' + $commitSha); } else { Write-Output ($remVerStr + '|' + $remBldStr + '|OK|' + $commitSha); } } } catch { Write-Output ($remVerStr + '|' + $remBldStr + '|INVALID_REMOTE|' + $commitSha); } }"
for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "REM_RANDOM_NAME=%%A"
set "REMOTE_TMP=%JVM_SECURE_TEMP%\jvm_remote_build_!REM_RANDOM_NAME!.txt"
"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -Command "!PS_SCRIPT!" > "!REMOTE_TMP!" 2>nul
set "REMOTE_VER=UNKNOWN"
set "REMOTE_BUILD=UNKNOWN"
set "UPDATE_FLAG=ERROR"
set "REMOTE_REF=HEAD"
if exist "!REMOTE_TMP!" (
    for /f "usebackq tokens=1,2,3,4 delims=|" %%A in ("!REMOTE_TMP!") do (
        set "REMOTE_VER=%%A"
        set "REMOTE_BUILD=%%B"
        set "UPDATE_FLAG=%%C"
        set "REMOTE_REF=%%D"
    )
    del "!REMOTE_TMP!" >nul 2>&1
)
call :ValidateStrictIdentifier "!REMOTE_VER!" REMOTE_VER
if errorlevel 1 (
    set "REMOTE_VER=UNKNOWN"
    set "UPDATE_FLAG=INVALID_REMOTE"
)
if not "!REMOTE_BUILD!"=="N/A" if not "!REMOTE_BUILD!"=="NONE" if not "!REMOTE_BUILD!"=="UNKNOWN" (
    call :ValidateStrictIdentifier "!REMOTE_BUILD!" REMOTE_BUILD
    if errorlevel 1 (
        set "REMOTE_BUILD=UNKNOWN"
        set "UPDATE_FLAG=INVALID_REMOTE"
    )
)
if not "!REMOTE_REF!"=="NONE" (
    call :ValidateStrictIdentifier "!REMOTE_REF!" REMOTE_REF
    if errorlevel 1 (
        set "REMOTE_REF=HEAD"
        set "UPDATE_FLAG=INVALID_REMOTE"
    )
)
exit /b 0

rem ============================================================
rem Parse contents of .java-version file
rem ============================================================
:ParseJavaVersion
if "%~1"=="" exit /b 0
set "CLI_TARGET=%~1"
set "CLI_TARGET=!CLI_TARGET:"=!"
set "CLI_TARGET=!CLI_TARGET:;=!"
set "CLI_TARGET=!CLI_TARGET:ï»¿=!"
if /i "!CLI_TARGET:~0,4!"=="jdk-" set "CLI_TARGET=!CLI_TARGET:~4!"
if /i "!CLI_TARGET:~0,5!"=="java-" set "CLI_TARGET=!CLI_TARGET:~5!"
for /f "tokens=1,2 delims=." %%M in ("!CLI_TARGET!") do (
    if "%%M"=="1" (
        if not "%%N"=="" set "CLI_TARGET=%%N"
    ) else (
        set "CLI_TARGET=%%M"
    )
)
call :ValidateStrictIdentifier "!CLI_TARGET!" CLI_TARGET
if errorlevel 1 (
    set "CLI_TARGET="
    exit /b 1
)
shift
:PARSE_JV_LOOP
if "%~1"=="" exit /b 0
if /i "%~1"=="--vendor" (
    set "CLI_VENDOR=%~2"
    call :ValidateStrictIdentifier "!CLI_VENDOR!" CLI_VENDOR
    if errorlevel 1 (
        set "CLI_VENDOR="
        set "CLI_TARGET="
        exit /b 1
    )
    shift
    shift
    goto PARSE_JV_LOOP
)
if /i "%~1"=="--symlink" (
    set "SWITCH_MODE_OVERRIDE=SYMLINK"
    shift
    goto PARSE_JV_LOOP
)
if /i "%~1"=="--legacy" (
    echo %cRED%[ ERROR  ]%cRESET% Security policy: --legacy / --registry is forbidden inside .java-version.
    set "CLI_TARGET="
    exit /b 1
)
if /i "%~1"=="--registry" (
    echo %cRED%[ ERROR  ]%cRESET% Security policy: --legacy / --registry is forbidden inside .java-version.
    set "CLI_TARGET="
    exit /b 1
)
shift
goto PARSE_JV_LOOP

rem ============================================================
rem Hijack SDKMAN configuration file
rem ============================================================
:ParseSdkmanrc
if "%~1"=="" exit /b 1
set "RAW_SDK_VER=%~1"
set "RAW_SDK_VER=!RAW_SDK_VER:"=!"
set "RAW_SDK_VER=!RAW_SDK_VER:;=!"
for /f "tokens=1 delims=# " %%C in ("!RAW_SDK_VER!") do set "RAW_SDK_VER=%%C"
if not defined RAW_SDK_VER exit /b 1
set "CLI_VENDOR="
set "CLI_TARGET="
for /f "tokens=1,2 delims=-" %%V in ("!RAW_SDK_VER!") do (
    for /f "tokens=1,2 delims=." %%M in ("%%V") do (
        if "%%M"=="1" (
            if not "%%N"=="" ( set "CLI_TARGET=%%N" ) else ( set "CLI_TARGET=%%M" )
        ) else (
            set "CLI_TARGET=%%M"
        )
    )
    if defined CLI_TARGET (
        call :ValidateStrictIdentifier "!CLI_TARGET!" CLI_TARGET
        if errorlevel 1 (
            set "CLI_TARGET="
            exit /b 1
        )
        if /i "!CLI_TARGET!"=="current" (
            set "CLI_TARGET="
            exit /b 1
        )
    ) else (
        exit /b 1
    )
    if not "%%W"=="" (
        call :ValidateStrictIdentifier "%%W"
        if errorlevel 1 (
            set "CLI_TARGET="
            exit /b 1
        )
        if /i "%%W"=="tem" set "CLI_VENDOR=Adoptium"
        if /i "%%W"=="amzn" set "CLI_VENDOR=Corretto"
        if /i "%%W"=="zulu" set "CLI_VENDOR=Zulu"
        if /i "%%W"=="ms" set "CLI_VENDOR=Microsoft"
        if /i "%%W"=="msft" set "CLI_VENDOR=Microsoft"
        if /i "%%W"=="open" set "CLI_VENDOR=Oracle"
        if /i "%%W"=="graal" set "CLI_VENDOR=GraalVM"
        if /i "%%W"=="graalce" set "CLI_VENDOR=GraalVM"
        if /i "%%W"=="oracle" set "CLI_VENDOR=Oracle"
        if /i "%%W"=="librca" set "CLI_VENDOR=Liberica"
        if /i "%%W"=="nik" set "CLI_VENDOR=Liberica"
        if /i "%%W"=="liberica" set "CLI_VENDOR=Liberica"
        if /i "%%W"=="sem" set "CLI_VENDOR=Semeru"
        if /i "%%W"=="semeru" set "CLI_VENDOR=Semeru"
        if not defined CLI_VENDOR (
            set "CLI_TARGET="
            exit /b 1
        )
    )
)
if not defined CLI_TARGET exit /b 1
exit /b 0

:EmitSessionEnv
if defined JVM_CALLER_PID (
    set "_PID_BAD="
    if "!JVM_CALLER_PID:~0,1!"=="-" set "_PID_BAD=1"
    if "!JVM_CALLER_PID:~0,1!"=="." set "_PID_BAD=1"
    if not "!JVM_CALLER_PID!"=="!JVM_CALLER_PID:\=!" set "_PID_BAD=1"
    if not "!JVM_CALLER_PID!"=="!JVM_CALLER_PID:/=!" set "_PID_BAD=1"
    if not "!JVM_CALLER_PID!"=="!JVM_CALLER_PID:..=!" set "_PID_BAD=1"
    for /f "delims=0123456789" %%P in ("!JVM_CALLER_PID!") do set "_PID_BAD=1"
    if defined _PID_BAD (
        echo %cRED%[ ERROR  ]%cRESET% Invalid JVM_CALLER_PID: non-numeric or path traversal characters forbidden.
        exit /b 1
    )
)
set "SESSION_ENV_BASE=%JVM_SECURE_TEMP%\.jvm_session_target"
set "SESSION_ENV_PID="
if defined JVM_CALLER_PID set "SESSION_ENV_PID=%JVM_SECURE_TEMP%\.jvm_session_target_!JVM_CALLER_PID!"
if exist "!SESSION_ENV_BASE!\" (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): !SESSION_ENV_BASE! is a directory.
    exit /b 1
)
"%FSUTIL_BIN%" reparsepoint query "!SESSION_ENV_BASE!" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): !SESSION_ENV_BASE! is a symlink or reparse point.
    exit /b 1
)
if defined SESSION_ENV_PID (
    if exist "!SESSION_ENV_PID!\" (
        echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): !SESSION_ENV_PID! is a directory.
        exit /b 1
    )
    "%FSUTIL_BIN%" reparsepoint query "!SESSION_ENV_PID!" >nul 2>&1
    if !errorlevel! EQU 0 (
        echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): !SESSION_ENV_PID! is a symlink or reparse point.
        exit /b 1
    )
)
if /i "%~1"=="RESET" (
    if exist "!SESSION_ENV_BASE!" del "!SESSION_ENV_BASE!" >nul 2>&1
    if defined SESSION_ENV_PID if exist "!SESSION_ENV_PID!" del "!SESSION_ENV_PID!" >nul 2>&1
    exit /b 0
)
if not "%~1"=="" (
    >>"!SESSION_ENV_BASE!" echo %~1
    if defined SESSION_ENV_PID >>"!SESSION_ENV_PID!" echo %~1
)
exit /b 0

:WriteConfigFile
set "_CFG_FILE=%~1"
set "_CFG_VAL=%~2"
for %%F in ("!_CFG_FILE!") do set "_CFG_DIR=%%~dpF"
if "!_CFG_DIR:~-1!"=="\" set "_CFG_DIR=!_CFG_DIR:~0,-1!"
if not exist "!_CFG_DIR!" mkdir "!_CFG_DIR!" >nul 2>&1
"%FSUTIL_BIN%" reparsepoint query "!_CFG_DIR!" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Config directory !_CFG_DIR! is a reparse point.
    exit /b 1
)
if exist "!_CFG_FILE!\" (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Config path !_CFG_FILE! is a directory.
    exit /b 1
)
"%FSUTIL_BIN%" reparsepoint query "!_CFG_FILE!" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Config file !_CFG_FILE! is a symlink or reparse point.
    exit /b 1
)
set "_CFG_RND="
for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "_CFG_RND=%%A"
if not defined _CFG_RND set "_CFG_RND=!JVM_PID!"
set "_CFG_TMP=!_CFG_FILE!.stage.!_CFG_RND!.tmp"
if exist "!_CFG_TMP!" del "!_CFG_TMP!" >nul 2>&1
"%FSUTIL_BIN%" reparsepoint query "!_CFG_TMP!" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Staging config file is a symlink.
    exit /b 1
)
(call )
(echo !_CFG_VAL!)>"!_CFG_TMP!" 2>nul
if errorlevel 1 (
    if exist "!_CFG_TMP!" del "!_CFG_TMP!" >nul 2>&1
    echo %cRED%[ ERROR  ]%cRESET% Failed to write configuration file !_CFG_FILE!.
    exit /b 1
)
move /y "!_CFG_TMP!" "!_CFG_FILE!" >nul 2>&1
if errorlevel 1 (
    if exist "!_CFG_TMP!" del "!_CFG_TMP!" >nul 2>&1
    echo %cRED%[ ERROR  ]%cRESET% Failed to write configuration file !_CFG_FILE!.
    exit /b 1
)
if not exist "!_CFG_FILE!" (
    echo %cRED%[ ERROR  ]%cRESET% Configuration file !_CFG_FILE! was not created.
    exit /b 1
)
exit /b 0

rem ============================================================
rem REPRODUCIBLE LOCKFILE ENGINE (.jvm.lock)
rem ============================================================

:BuildEcosystemCandidateUrls
set "DOWNLOAD_URL="
set "CHECKSUM_URL="
set "FALLBACK_URL="
set "FALLBACK_CHECKSUM_URL="
set "FALLBACK2_URL="
set "FALLBACK2_CHECKSUM_URL="
set "CHECKSUM_TYPE="
if /i "!TARGET_CANDIDATE!"=="maven" (
    set "DOWNLOAD_URL=https://downloads.apache.org/maven/maven-3/!TARGET_VER!/binaries/apache-maven-!TARGET_VER!-bin.zip"
    set "CHECKSUM_URL=https://downloads.apache.org/maven/maven-3/!TARGET_VER!/binaries/apache-maven-!TARGET_VER!-bin.zip.sha512"
    set "FALLBACK_URL=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/!TARGET_VER!/apache-maven-!TARGET_VER!-bin.zip"
    set "FALLBACK_CHECKSUM_URL=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/!TARGET_VER!/apache-maven-!TARGET_VER!-bin.zip.sha512"
    set "FALLBACK2_URL=https://archive.apache.org/dist/maven/maven-3/!TARGET_VER!/binaries/apache-maven-!TARGET_VER!-bin.zip"
    set "FALLBACK2_CHECKSUM_URL=https://archive.apache.org/dist/maven/maven-3/!TARGET_VER!/binaries/apache-maven-!TARGET_VER!-bin.zip.sha512"
    set "CHECKSUM_TYPE=SHA512"
)
if /i "!TARGET_CANDIDATE!"=="gradle" (
    set "DOWNLOAD_URL=https://services.gradle.org/distributions/gradle-!TARGET_VER!-bin.zip"
    set "CHECKSUM_URL=https://services.gradle.org/distributions/gradle-!TARGET_VER!-bin.zip.sha256"
    set "FALLBACK_URL=https://downloads.gradle.org/distributions/gradle-!TARGET_VER!-bin.zip"
    set "FALLBACK_CHECKSUM_URL=https://downloads.gradle.org/distributions/gradle-!TARGET_VER!-bin.zip.sha256"
    set "CHECKSUM_TYPE=SHA256"
)
if /i "!TARGET_CANDIDATE!"=="kotlin" (
    set "DOWNLOAD_URL=https://github.com/JetBrains/kotlin/releases/download/v!TARGET_VER!/kotlin-compiler-!TARGET_VER!.zip"
    set "CHECKSUM_URL=https://github.com/JetBrains/kotlin/releases/download/v!TARGET_VER!/kotlin-compiler-!TARGET_VER!.zip.sha256"
    set "CHECKSUM_TYPE=SHA256"
)
if /i "!TARGET_CANDIDATE!"=="scala" (
    set "DOWNLOAD_URL=https://github.com/scala/scala3/releases/download/!TARGET_VER!/scala3-!TARGET_VER!.zip"
    set "CHECKSUM_URL=https://github.com/scala/scala3/releases/download/!TARGET_VER!/scala3-!TARGET_VER!.zip.sha256"
    set "CHECKSUM_TYPE=SHA256"
)
if /i "!TARGET_CANDIDATE!"=="groovy" (
    set "DOWNLOAD_URL=https://archive.apache.org/dist/groovy/!TARGET_VER!/distribution/apache-groovy-binary-!TARGET_VER!.zip"
    set "CHECKSUM_URL=https://archive.apache.org/dist/groovy/!TARGET_VER!/distribution/apache-groovy-binary-!TARGET_VER!.zip.sha256"
    set "FALLBACK_URL=https://downloads.apache.org/groovy/!TARGET_VER!/distribution/apache-groovy-binary-!TARGET_VER!.zip"
    set "FALLBACK_CHECKSUM_URL=https://downloads.apache.org/groovy/!TARGET_VER!/distribution/apache-groovy-binary-!TARGET_VER!.zip.sha256"
    set "CHECKSUM_TYPE=SHA256"
)
if /i "!TARGET_CANDIDATE!"=="ant" (
    set "DOWNLOAD_URL=https://archive.apache.org/dist/ant/binaries/apache-ant-!TARGET_VER!-bin.zip"
    set "CHECKSUM_URL=https://archive.apache.org/dist/ant/binaries/apache-ant-!TARGET_VER!-bin.zip.sha512"
    set "FALLBACK_URL=https://downloads.apache.org/ant/binaries/apache-ant-!TARGET_VER!-bin.zip"
    set "FALLBACK_CHECKSUM_URL=https://downloads.apache.org/ant/binaries/apache-ant-!TARGET_VER!-bin.zip.sha512"
    set "CHECKSUM_TYPE=SHA512"
)
if /i "!TARGET_CANDIDATE!"=="sbt" (
    set "DOWNLOAD_URL=https://github.com/sbt/sbt/releases/download/v!TARGET_VER!/sbt-!TARGET_VER!.zip"
    set "CHECKSUM_URL=https://github.com/sbt/sbt/releases/download/v!TARGET_VER!/sbt-!TARGET_VER!.zip.sha256"
    set "CHECKSUM_TYPE=SHA256"
)
if /i "!TARGET_CANDIDATE!"=="jbang" (
    set "DOWNLOAD_URL=https://github.com/jbangdev/jbang/releases/download/v!TARGET_VER!/jbang-!TARGET_VER!.zip"
    set "CHECKSUM_URL=https://github.com/jbangdev/jbang/releases/download/v!TARGET_VER!/jbang-!TARGET_VER!.zip.sha256"
    set "CHECKSUM_TYPE=SHA256"
)
if /i "!TARGET_CANDIDATE!"=="quarkus" (
    set "DOWNLOAD_URL=https://github.com/quarkusio/quarkus/releases/download/!TARGET_VER!/quarkus-cli-!TARGET_VER!.zip"
    set "CHECKSUM_URL=https://github.com/quarkusio/quarkus/releases/download/!TARGET_VER!/checksums_sha256.txt"
    set "CHECKSUM_TYPE=SHA256"
)
if /i "!TARGET_CANDIDATE!"=="spring" (
    set "DOWNLOAD_URL=https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-cli/!TARGET_VER!/spring-boot-cli-!TARGET_VER!-bin.zip"
    set "CHECKSUM_URL=https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-cli/!TARGET_VER!/spring-boot-cli-!TARGET_VER!-bin.zip.sha1"
    set "CHECKSUM_TYPE=SHA1"
)
if /i "!TARGET_CANDIDATE!"=="micronaut" (
    set "DOWNLOAD_URL=https://github.com/micronaut-projects/micronaut-starter/releases/download/v!TARGET_VER!/micronaut-cli-!TARGET_VER!.zip"
    set "CHECKSUM_URL=https://github.com/micronaut-projects/micronaut-starter/releases/download/v!TARGET_VER!/micronaut-cli-!TARGET_VER!.zip.sha256"
    set "CHECKSUM_TYPE=SHA256"
)
if /i "!TARGET_CANDIDATE!"=="mn" (
    set "TARGET_CANDIDATE=micronaut"
    set "DOWNLOAD_URL=https://github.com/micronaut-projects/micronaut-starter/releases/download/v!TARGET_VER!/micronaut-cli-!TARGET_VER!.zip"
    set "CHECKSUM_URL=https://github.com/micronaut-projects/micronaut-starter/releases/download/v!TARGET_VER!/micronaut-cli-!TARGET_VER!.zip.sha256"
    set "CHECKSUM_TYPE=SHA256"
)
exit /b 0

:ExecuteLockCommand
call :RequireNetwork
if errorlevel 1 exit /b 1

call :AcquireStateLock
if errorlevel 1 exit /b 1

set "LOCK_CANDIDATE=!TARGET_CANDIDATE!"
if not defined LOCK_CANDIDATE set "LOCK_CANDIDATE=java"
if /i not "!LOCK_CANDIDATE!"=="java" goto :LockEcosystemCandidate

:LockJavaCandidate
set "LOCK_VER=!CLI_TARGET!"
set "LOCK_VENDOR=!CLI_VENDOR!"

if not defined LOCK_VER (
    if exist "%INVOCATION_DIR%\.java-version" (
        for /f "eol=# delims=" %%L in ('%FINDSTR_BIN% /r /v "^[ \t]*# ^ï»¿[ \t]*# ^[ \t]*$" "%INVOCATION_DIR%\.java-version" 2^>nul ^| %FINDSTR_BIN% /r "[0-9]"') do (
            if not defined LOCK_VER (
                for /f "tokens=1,2,3" %%A in ("%%L") do (
                    set "LOCK_VER=%%A"
                    if /i "%%B"=="--vendor" set "LOCK_VENDOR=%%C"
                )
            )
        )
    )
)

if not defined LOCK_VER (
    if exist "%INVOCATION_DIR%\.sdkmanrc" (
        for /f "eol=# tokens=1,* delims==" %%A in ('%FINDSTR_BIN% /i /r "^[ \t]*java[ \t]*=" "%INVOCATION_DIR%\.sdkmanrc" 2^>nul') do (
            set "SDK_VAL=%%B"
            for /f "tokens=*" %%S in ("!SDK_VAL!") do set "SDK_VAL=%%S"
            for /f "tokens=1,2 delims=-" %%V in ("!SDK_VAL!") do (
                set "LOCK_VER=%%V"
                if /i "%%W"=="tem" set "LOCK_VENDOR=Adoptium"
                if /i "%%W"=="amzn" set "LOCK_VENDOR=Corretto"
                if /i "%%W"=="zulu" set "LOCK_VENDOR=Zulu"
                if /i "%%W"=="ms" set "LOCK_VENDOR=Microsoft"
                if /i "%%W"=="librca" set "LOCK_VENDOR=Liberica"
                if /i "%%W"=="sem" set "LOCK_VENDOR=Semeru"
                if /i "%%W"=="graalce" set "LOCK_VENDOR=GraalVM"
                if /i "%%W"=="sapmchn" set "LOCK_VENDOR=SapMachine"
                if /i "%%W"=="mandrel" set "LOCK_VENDOR=Mandrel"
                if /i "%%W"=="albba" set "LOCK_VENDOR=Dragonwell"
                if /i "%%W"=="kona" set "LOCK_VENDOR=Kona"
                if /i "%%W"=="oracle" set "LOCK_VENDOR=Oracle"
            )
        )
    )
)

if not defined LOCK_VER (
    if defined CURRENT_JDK_PATH if exist "!CURRENT_JDK_PATH!\release" (
        for /f "tokens=2 delims==" %%A in ('%FINDSTR_BIN% /b "JAVA_VERSION=" "!CURRENT_JDK_PATH!\release" 2^>nul') do (
            set "RAW_VER=%%~A"
            for /f "tokens=1 delims=." %%M in ("!RAW_VER!") do (
                if "%%M"=="1" ( set "LOCK_VER=8" ) else ( set "LOCK_VER=%%M" )
            )
        )
    )
)

if not defined LOCK_VER (
    if defined JDK_COUNT if !JDK_COUNT! GTR 0 (
        set "LOCK_VER=!JDK_MAJOR_1!"
        if not defined LOCK_VENDOR set "LOCK_VENDOR=!JDK_VENDOR_1!"
    )
)

if not defined LOCK_VER (
    echo %cRED%[ ERROR  ]%cRESET% No Java version specified and no active Java installation or .java-version found.
    echo            Usage: jvm lock [version] [--vendor ^<name^>]
    call :ReleaseStateLock
    exit /b 1
)

if not defined LOCK_VENDOR set "LOCK_VENDOR=Adoptium"

rem Normalize vendor
if /i "!LOCK_VENDOR!"=="bellsoft" set "LOCK_VENDOR=Liberica"
if /i "!LOCK_VENDOR!"=="ibm" set "LOCK_VENDOR=Semeru"
if /i "!LOCK_VENDOR!"=="openj9" set "LOCK_VENDOR=Semeru"
if /i "!LOCK_VENDOR!"=="temurin" set "LOCK_VENDOR=Adoptium"
if /i "!LOCK_VENDOR!"=="sap" set "LOCK_VENDOR=SapMachine"
if /i "!LOCK_VENDOR!"=="sapmachine" set "LOCK_VENDOR=SapMachine"
if /i "!LOCK_VENDOR!"=="redhat-mandrel" set "LOCK_VENDOR=Mandrel"
if /i "!LOCK_VENDOR!"=="mandrel" set "LOCK_VENDOR=Mandrel"
if /i "!LOCK_VENDOR!"=="alibaba" set "LOCK_VENDOR=Dragonwell"
if /i "!LOCK_VENDOR!"=="dragonwell" set "LOCK_VENDOR=Dragonwell"
if /i "!LOCK_VENDOR!"=="tencent" set "LOCK_VENDOR=Kona"
if /i "!LOCK_VENDOR!"=="kona" set "LOCK_VENDOR=Kona"

set "IS_LOCKING_ONLY=1"
set "DL_VERSION=!LOCK_VER!"
set "CLI_VENDOR=!LOCK_VENDOR!"

if /i "!LOCK_VENDOR!"=="oracle" goto :Resolve_Oracle
if /i "!LOCK_VENDOR!"=="adoptium" goto :Resolve_Adoptium
if /i "!LOCK_VENDOR!"=="graalvm" goto :Resolve_GraalVM
if /i "!LOCK_VENDOR!"=="corretto" goto :Resolve_Corretto
if /i "!LOCK_VENDOR!"=="zulu" goto :Resolve_Zulu
if /i "!LOCK_VENDOR!"=="microsoft" goto :Resolve_Microsoft
if /i "!LOCK_VENDOR!"=="liberica" goto :Resolve_Liberica
if /i "!LOCK_VENDOR!"=="semeru" goto :Resolve_Semeru
if /i "!LOCK_VENDOR!"=="sapmachine" goto :Resolve_SapMachine
if /i "!LOCK_VENDOR!"=="mandrel" goto :Resolve_Mandrel
if /i "!LOCK_VENDOR!"=="dragonwell" goto :Resolve_Dragonwell
if /i "!LOCK_VENDOR!"=="kona" goto :Resolve_Kona

echo %cRED%[ ERROR  ]%cRESET% Unknown or unsupported vendor: !LOCK_VENDOR!
call :ReleaseStateLock
exit /b 1

:LockEcosystemCandidate
call :GetCandidateEnvVar
set "TARGET_VER=!CLI_TARGET!"
if not defined TARGET_VER (
    set "QUERY_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\!LOCK_CANDIDATE!\current"
    if exist "!QUERY_PATH!" (
        for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "^(Get-Item -LiteralPath $env:QUERY_PATH -ErrorAction SilentlyContinue^).Target" 2^>nul') do for %%X in ("%%A") do set "TARGET_VER=%%~nxX"
    )
)
if not defined TARGET_VER set "TARGET_VER=latest"
if /i "!TARGET_VER!"=="latest" (
    echo %cBLUE%[ ACTION ]%cRESET% Resolving latest version of !CANDIDATE_PROPER_NAME!...
    call :ResolveLatestEcosystemCandidate
    set "TARGET_VER=!LATEST_VER!"
    if "!TARGET_VER!"=="ERROR" (
        echo %cRED%[ ERROR  ]%cRESET% Failed to resolve latest version of !CANDIDATE_PROPER_NAME!. Check your internet connection.
        call :ReleaseStateLock
        exit /b 1
    )
)
call :ValidateStrictIdentifier "!TARGET_VER!" TARGET_VER
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Invalid candidate version: !TARGET_VER!
    call :ReleaseStateLock
    exit /b 1
)

set "TARGET_CANDIDATE=!LOCK_CANDIDATE!"
call :BuildEcosystemCandidateUrls
if not defined DOWNLOAD_URL (
    echo %cRED%[ ERROR  ]%cRESET% No download source for candidate: !LOCK_CANDIDATE!
    call :ReleaseStateLock
    exit /b 1
)

set "FINAL_CHKSUM_VAL="
if defined CHECKSUM_URL (
    for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "LOCK_FETCH_RND=%%A"
    set "FETCH_PS1=%JVM_SECURE_TEMP%\jvm_chk_fetch_!LOCK_FETCH_RND!.ps1"
    (
        echo $ErrorActionPreference = 'Stop'
        echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288
        echo try {
        echo     $req = [Net.HttpWebRequest]::Create^($env:CHECKSUM_URL^)
        echo     $req.UserAgent = 'Mozilla/5.0'
        echo     $req.Timeout = 5000
        echo     $resp = $req.GetResponse^(^)
        echo     $sr = New-Object IO.StreamReader^($resp.GetResponseStream^(^)^)
        echo     $txt = $sr.ReadToEnd^(^)
        echo     $sr.Close^(^)
        echo     $resp.Close^(^)
        echo     if ^($txt -match '[0-9a-fA-F]{32,128}'^) { Write-Output $matches[0].ToLower^(^) }
        echo } catch { }
    ) > "!FETCH_PS1!"
    for /f "delims=" %%H in ('%PS_BIN% -NoProfile -ExecutionPolicy Bypass -File "!FETCH_PS1!"') do set "FINAL_CHKSUM_VAL=%%H"
    if exist "!FETCH_PS1!" del /f /q "!FETCH_PS1!" >nul 2>&1
)

if not defined FINAL_CHKSUM_VAL (
    echo %cYELLOW%[ WARNING]%cRESET% Fetching checksum from archive payload...
    set "DL_URL=!DOWNLOAD_URL!"
    set "DL_ZIP=%JVM_SECURE_TEMP%\lock_calc_!TARGET_CANDIDATE!_!TARGET_VER!.zip"
    set "DL_EXTRACT=%JVM_SECURE_TEMP%\lock_calc_!TARGET_CANDIDATE!_!TARGET_VER!_ext"
    set "DL_CHKSUM_VAL="
    set "DL_CHKSUM_URL="
    set "DL_CHKSUM_TYPE=SHA256"
    set "DL_STRIP_ROOT=0"
    set "SKIP_CHECKSUM=1"
    call :ExecuteSharedDownloader
    if exist "!DL_ZIP!" (
        for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "LOCK_HASH_RND=%%A"
        set "HASH_PS1=%JVM_SECURE_TEMP%\jvm_chk_hash_!LOCK_HASH_RND!.ps1"
        (
            echo $stream = [System.IO.File]::OpenRead^($env:DL_ZIP^)
            echo $sha = [System.Security.Cryptography.SHA256]::Create^(^)
            echo $hash = [System.BitConverter]::ToString^($sha.ComputeHash^($stream^)^).Replace^('-', ''^).ToLower^(^)
            echo $stream.Close^(^)
            echo Write-Output $hash
        ) > "!HASH_PS1!"
        for /f "delims=" %%H in ('%PS_BIN% -NoProfile -ExecutionPolicy Bypass -File "!HASH_PS1!"') do set "FINAL_CHKSUM_VAL=%%H"
        if exist "!HASH_PS1!" del /f /q "!HASH_PS1!" >nul 2>&1
        del /f /q "!DL_ZIP!" >nul 2>&1
    )
    if exist "!DL_EXTRACT!" rmdir /s /q "!DL_EXTRACT!" >nul 2>&1
    set "SKIP_CHECKSUM="
    set "CHECKSUM_TYPE=SHA256"
)

set "ENTRY_CANDIDATE=!LOCK_CANDIDATE!"
set "ENTRY_VENDOR="
set "ENTRY_VERSION=!TARGET_VER!"
set "ENTRY_ARCH=all"
set "ENTRY_URL=!DOWNLOAD_URL!"
set "ENTRY_CHKSUM_TYPE=!CHECKSUM_TYPE!"
set "ENTRY_CHKSUM=!FINAL_CHKSUM_VAL!"
goto :WriteLockFileEntry

:FinishLockResolution
set "IS_LOCKING_ONLY="
if not defined API_RESOLVED_VER set "API_RESOLVED_VER=!DL_VERSION!"
set "FINAL_CHKSUM_VAL=!API_SHA256!"
set "FINAL_CHKSUM_TYPE=sha256"
if defined API_SHA1 (
    set "FINAL_CHKSUM_VAL=!API_SHA1!"
    set "FINAL_CHKSUM_TYPE=sha1"
)
if defined API_MD5 (
    set "FINAL_CHKSUM_VAL=!API_MD5!"
    set "FINAL_CHKSUM_TYPE=md5"
)
if not defined FINAL_CHKSUM_VAL (
    set "FETCH_URL="
    if defined API_SHA256_URL set "FETCH_URL=!API_SHA256_URL!" & set "FINAL_CHKSUM_TYPE=sha256"
    if defined API_MD5_URL set "FETCH_URL=!API_MD5_URL!" & set "FINAL_CHKSUM_TYPE=md5"
    if defined FETCH_URL (
        for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "LOCK_FETCH_RND=%%A"
        set "FETCH_PS1=%JVM_SECURE_TEMP%\jvm_chk_fetch_!LOCK_FETCH_RND!.ps1"
        (
            echo $ErrorActionPreference = 'Stop'
            echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288
            echo try {
            echo     $req = [Net.HttpWebRequest]::Create^($env:FETCH_URL^)
            echo     $req.UserAgent = 'Mozilla/5.0'
            echo     $req.Timeout = 5000
            echo     $resp = $req.GetResponse^(^)
            echo     $sr = New-Object IO.StreamReader^($resp.GetResponseStream^(^)^)
            echo     $txt = $sr.ReadToEnd^(^)
            echo     $sr.Close^(^)
            echo     $resp.Close^(^)
            echo     if ^($txt -match '[0-9a-fA-F]{32,128}'^) { Write-Output $matches[0].ToLower^(^) }
            echo } catch { }
        ) > "!FETCH_PS1!"
        for /f "delims=" %%H in ('%PS_BIN% -NoProfile -ExecutionPolicy Bypass -File "!FETCH_PS1!"') do set "FINAL_CHKSUM_VAL=%%H"
        if exist "!FETCH_PS1!" del /f /q "!FETCH_PS1!" >nul 2>&1
    )
)

if not defined FINAL_CHKSUM_VAL (
    echo %cYELLOW%[ WARNING]%cRESET% Upstream provider did not publish an automated checksum.
    echo            Computing checksum by downloading payload into secure temporary cache...
    set "DL_URL=!API_URL!"
    set "DL_ZIP=%JVM_SECURE_TEMP%\lock_calc_!DL_RANDOM_NAME!.zip"
    set "DL_EXTRACT=%JVM_SECURE_TEMP%\lock_calc_!DL_RANDOM_NAME!_ext"
    set "DL_CHKSUM_VAL="
    set "DL_CHKSUM_URL="
    set "DL_CHKSUM_TYPE=SHA256"
    set "DL_STRIP_ROOT=0"
    set "SKIP_CHECKSUM=1"
    call :ExecuteSharedDownloader
    if exist "!DL_ZIP!" (
        for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "LOCK_HASH_RND=%%A"
        set "HASH_PS1=%JVM_SECURE_TEMP%\jvm_chk_hash_!LOCK_HASH_RND!.ps1"
        (
            echo $stream = [System.IO.File]::OpenRead^($env:DL_ZIP^)
            echo $sha = [System.Security.Cryptography.SHA256]::Create^(^)
            echo $hash = [System.BitConverter]::ToString^($sha.ComputeHash^($stream^)^).Replace^('-', ''^).ToLower^(^)
            echo $stream.Close^(^)
            echo Write-Output $hash
        ) > "!HASH_PS1!"
        for /f "delims=" %%H in ('%PS_BIN% -NoProfile -ExecutionPolicy Bypass -File "!HASH_PS1!"') do set "FINAL_CHKSUM_VAL=%%H"
        if exist "!HASH_PS1!" del /f /q "!HASH_PS1!" >nul 2>&1
        del /f /q "!DL_ZIP!" >nul 2>&1
    )
    if exist "!DL_EXTRACT!" rmdir /s /q "!DL_EXTRACT!" >nul 2>&1
    set "SKIP_CHECKSUM="
    set "FINAL_CHKSUM_TYPE=sha256"
)

set "ENTRY_CANDIDATE=java"
set "ENTRY_VENDOR=!LOCK_VENDOR!"
set "ENTRY_VERSION=!API_RESOLVED_VER!"
set "ENTRY_ARCH=!SYS_ARCH!"
set "ENTRY_URL=!API_URL!"
set "ENTRY_CHKSUM_TYPE=!FINAL_CHKSUM_TYPE!"
set "ENTRY_CHKSUM=!FINAL_CHKSUM_VAL!"
goto :WriteLockFileEntry

:WriteLockFileEntry
set "LOCK_FILE_PATH=%INVOCATION_DIR%\.jvm.lock"

rem Security checks on .jvm.lock target (CWE-59)
if exist "!LOCK_FILE_PATH!\" (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): .jvm.lock is a directory.
    call :ReleaseStateLock
    exit /b 1
)
"%FSUTIL_BIN%" reparsepoint query "!LOCK_FILE_PATH!" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Refusing to overwrite symlink/reparse point .jvm.lock.
    call :ReleaseStateLock
    exit /b 1
)

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "LOCK_PS_RND=%%A"
set "LOCK_WRITER_PS1=%JVM_SECURE_TEMP%\jvm_lock_write_!LOCK_PS_RND!.ps1"

(
    echo $ErrorActionPreference = 'Stop'
    echo $lockPath = $env:LOCK_FILE_PATH
    echo $candidate = $env:ENTRY_CANDIDATE
    echo $vendor = $env:ENTRY_VENDOR
    echo $version = $env:ENTRY_VERSION
    echo $arch = $env:ENTRY_ARCH
    echo $url = $env:ENTRY_URL
    echo $chkType = $env:ENTRY_CHKSUM_TYPE
    echo $chkVal = $env:ENTRY_CHKSUM
    echo $toolsDict = [ordered]@{}
    echo if ^(Test-Path -LiteralPath $lockPath^) {
    echo     try {
    echo         $raw = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8
    echo         $existing = $raw ^| ConvertFrom-Json
    echo         if ^($existing.tools^) {
    echo             foreach ^($prop in $existing.tools.PSObject.Properties^) {
    echo                 $toolsDict[$prop.Name] = $prop.Value
    echo             }
    echo         }
    echo     } catch { }
    echo }
    echo $cType = if ^($chkType^) { $chkType.ToLowerInvariant^(^) } else { 'sha256' }
    echo $cVal = if ^($chkVal^) { $chkVal.ToLowerInvariant^(^) } else { '' }
    echo $entry = [ordered]@{
    echo     version = $version
    echo     arch = $arch
    echo     url = $url
    echo     checksum_type = $cType
    echo     checksum = $cVal
    echo }
    echo if ^($vendor^) { $entry.vendor = $vendor.ToLowerInvariant^(^) }
    echo $toolsDict[$candidate] = $entry
    echo $lockObj = [ordered]@{
    echo     lockfile_version = 1
    echo     generated_at = ^(Get-Date^).ToUniversalTime^(^).ToString^("yyyy-MM-ddTHH:mm:ssZ"^)
    echo     tools = $toolsDict
    echo }
    echo $json = $lockObj ^| ConvertTo-Json -Depth 10
    echo $stage = $lockPath + ".stage." + [Guid]::NewGuid^(^).ToString^("N"^) + ".tmp"
    echo $utf8NoBom = New-Object System.Text.UTF8Encoding^($false^)
    echo [System.IO.File]::WriteAllText^($stage, ^($json + "`r`n"^), $utf8NoBom^)
    echo Move-Item -LiteralPath $stage -Destination $lockPath -Force
) > "!LOCK_WRITER_PS1!"

"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -File "!LOCK_WRITER_PS1!"
set "LOCK_EXIT=!errorlevel!"
if exist "!LOCK_WRITER_PS1!" del /f /q "!LOCK_WRITER_PS1!" >nul 2>&1

if !LOCK_EXIT! NEQ 0 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to write .jvm.lock.
    call :ReleaseStateLock
    exit /b 1
)

if "%OUTPUT_JSON%"=="1" (
    echo {"status":"locked","candidate":"!ENTRY_CANDIDATE!","version":"!ENTRY_VERSION!","vendor":"!ENTRY_VENDOR!","file":"!LOCK_FILE_PATH:\=\\!"}
    call :ReleaseStateLock
    exit /b 0
)

echo.
echo %cGREEN%[   OK   ]%cRESET% Successfully locked !ENTRY_CANDIDATE! !ENTRY_VERSION! in:
echo            !LOCK_FILE_PATH!
call :ReleaseStateLock
exit /b 0

:ExecuteLockedInstall
call :AcquireStateLock
if errorlevel 1 exit /b 1

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "LOCK_FIND_RND=%%A"
set "LOCK_FIND_PS1=%JVM_SECURE_TEMP%\jvm_lock_find_!LOCK_FIND_RND!.ps1"
(
    echo $dir = $env:INVOCATION_DIR
    echo while ^($dir^) {
    echo     $c = Join-Path $dir '.jvm.lock'
    echo     if ^(Test-Path -LiteralPath $c^) {
    echo         Write-Output $c
    echo         break
    echo     }
    echo     $p = Split-Path -Path $dir -Parent
    echo     if ^(-not $p -or $p -eq $dir^) { break }
    echo     $dir = $p
    echo }
) > "!LOCK_FIND_PS1!"
for /f "delims=" %%A in ('%PS_BIN% -NoProfile -ExecutionPolicy Bypass -File "!LOCK_FIND_PS1!"') do (
    set "RESOLVED_LOCK_FILE=%%A"
)
if exist "!LOCK_FIND_PS1!" del /f /q "!LOCK_FIND_PS1!" >nul 2>&1

if not defined RESOLVED_LOCK_FILE (
    echo %cRED%[ ERROR  ]%cRESET% No .jvm.lock found in the current directory or parent directories.
    echo            Run 'jvm lock' to generate a lockfile for this project.
    call :ReleaseStateLock
    exit /b 1
)

rem 2. Security validation on resolved lockfile (CWE-59)
if exist "!RESOLVED_LOCK_FILE!\" (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): .jvm.lock is a directory.
    call :ReleaseStateLock
    exit /b 1
)
"%FSUTIL_BIN%" reparsepoint query "!RESOLVED_LOCK_FILE!" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Refusing to process symlinked/reparse point .jvm.lock.
    call :ReleaseStateLock
    exit /b 1
)

echo %cBLUE%[  INFO  ]%cRESET% Using lockfile: !RESOLVED_LOCK_FILE!

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "LOCK_RND=%%A"
set "LOCK_PARSER_PS1=%JVM_SECURE_TEMP%\jvm_lock_parse_!LOCK_RND!.ps1"

(
    echo $ErrorActionPreference = 'Stop'
    echo try {
    echo     $raw = Get-Content -LiteralPath $env:RESOLVED_LOCK_FILE -Raw -Encoding UTF8
    echo     $data = $raw ^| ConvertFrom-Json
    echo     if ^(-not $data.tools^) {
    echo         Write-Output "ERROR|Lockfile does not contain any tool definitions"
    echo         exit 0
    echo     }
    echo     foreach ^($prop in $data.tools.PSObject.Properties^) {
    echo         $c = $prop.Name
    echo         $t = $prop.Value
    echo         $v = if ^($t.version^) { $t.version } else { 'none' }
    echo         $vend = if ^($t.vendor^) { $t.vendor } else { 'none' }
    echo         $arch = if ^($t.arch^) { $t.arch } else { 'all' }
    echo         $url = if ^($t.url^) { $t.url } else { 'none' }
    echo         $chkType = if ^($t.checksum_type^) { $t.checksum_type } else { 'sha256' }
    echo         $chk = if ^($t.checksum^) { $t.checksum } else { 'none' }
    echo         $line = @^('TOOL', $c, $vend, $v, $arch, $url, $chkType, $chk^) -join [char]124
    echo         Write-Output $line
    echo     }
    echo } catch {
    echo     Write-Output ^("ERROR|" + $_.Exception.Message^)
    echo }
) > "!LOCK_PARSER_PS1!"

set "LOCK_ERR="
set "LOCKED_TOOL_COUNT=0"
for /f "tokens=1-8 delims=|" %%A in ('%PS_BIN% -NoProfile -ExecutionPolicy Bypass -File "!LOCK_PARSER_PS1!"') do (
    if "%%A"=="ERROR" set "LOCK_ERR=%%B"
    if "%%A"=="TOOL" (
        set /a LOCKED_TOOL_COUNT+=1
        set "L_TOOL_!LOCKED_TOOL_COUNT!=%%B"
        set "L_VEND_!LOCKED_TOOL_COUNT!=%%C"
        set "L_VER_!LOCKED_TOOL_COUNT!=%%D"
        set "L_ARCH_!LOCKED_TOOL_COUNT!=%%E"
        set "L_URL_!LOCKED_TOOL_COUNT!=%%F"
        set "L_CHKTYPE_!LOCKED_TOOL_COUNT!=%%G"
        set "L_CHK_!LOCKED_TOOL_COUNT!=%%H"
    )
)
if exist "!LOCK_PARSER_PS1!" del /f /q "!LOCK_PARSER_PS1!" >nul 2>&1

if defined LOCK_ERR (
    echo %cRED%[ ERROR  ]%cRESET% Failed to parse .jvm.lock: !LOCK_ERR!
    call :ReleaseStateLock
    exit /b 1
)

if !LOCKED_TOOL_COUNT! EQU 0 (
    echo %cYELLOW%[ WARNING]%cRESET% .jvm.lock contains no tool entries.
    call :ReleaseStateLock
    exit /b 0
)

rem 3. Process each locked tool
set "FILTER_TOOL="
if defined CLI_TARGET if /i not "!CLI_TARGET!"=="SKIP_JAVA" set "FILTER_TOOL=!CLI_TARGET!"
if /i not "!TARGET_CANDIDATE!"=="java" set "FILTER_TOOL=!TARGET_CANDIDATE!"
if defined FILTER_TOOL (
    call :ValidateStrictIdentifier "!FILTER_TOOL!" FILTER_TOOL
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-20^): Invalid candidate filter '!FILTER_TOOL!'.
        call :ReleaseStateLock
        exit /b 1
    )
)

set "MATCHED_LOCKED_COUNT=0"
for /l %%i in (1,1,!LOCKED_TOOL_COUNT!) do (
    set "CURR_TOOL=!L_TOOL_%%i!"
    set "DO_PROCESS=1"
    if defined FILTER_TOOL (
        if /i "!CURR_TOOL!" NEQ "!FILTER_TOOL!" set "DO_PROCESS=0"
    )
    if "!DO_PROCESS!"=="1" (
        set /a MATCHED_LOCKED_COUNT+=1
        set "T_CAND=!L_TOOL_%%i!"
        set "T_VEND=!L_VEND_%%i!"
        set "T_VER=!L_VER_%%i!"
        set "T_ARCH=!L_ARCH_%%i!"
        set "T_URL=!L_URL_%%i!"
        set "T_CHKTYPE=!L_CHKTYPE_%%i!"
        set "T_CHK=!L_CHK_%%i!"
        call :InstallSingleLockedTool
        if errorlevel 1 (
            call :ReleaseStateLock
            exit /b 1
        )
    )
)

if defined FILTER_TOOL if !MATCHED_LOCKED_COUNT! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Candidate '!FILTER_TOOL!' is not defined in .jvm.lock.
    call :ReleaseStateLock
    exit /b 1
)

echo.
echo %cGREEN%[   OK   ]%cRESET% Locked installation complete!
call :ReleaseStateLock
exit /b 0

:InstallSingleLockedTool
if not "%~1"=="" (
    set "T_CAND=%~1"
    set "T_VEND=%~2"
    set "T_VER=%~3"
    set "T_ARCH=%~4"
    set "T_URL=%~5"
    set "T_CHKTYPE=%~6"
    set "T_CHK=%~7"
)
if /i "!T_VEND!"=="none" set "T_VEND="
if /i "!T_CHK!"=="none" set "T_CHK="

rem Security sanitization on locked candidate, version, vendor, and URL (CWE-20 / CWE-22 / CWE-319)
call :ValidateStrictIdentifier "!T_CAND!" T_CAND
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-20^): Invalid candidate identifier in .jvm.lock: !T_CAND!
    exit /b 1
)
call :ValidateStrictIdentifier "!T_VER!" T_VER
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-20^): Invalid candidate version in .jvm.lock: !T_VER!
    exit /b 1
)
if defined T_VEND (
    call :ValidateStrictIdentifier "!T_VEND!" T_VEND
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-20^): Invalid candidate vendor in .jvm.lock: !T_VEND!
        exit /b 1
    )
)
set "VALID_LOCKED_CAND=0"
for %%C in (java maven gradle kotlin scala groovy ant sbt jbang quarkus spring micronaut mn visualvm) do (
    if /i "!T_CAND!"=="%%C" set "VALID_LOCKED_CAND=1"
)
if "!VALID_LOCKED_CAND!"=="0" (
    echo %cRED%[ ERROR  ]%cRESET% Security policy violation ^(CWE-20^): Unsupported or unmanaged tool '!T_CAND!' in .jvm.lock.
    exit /b 1
)
if not "!T_URL:~0,8!"=="https://" (
    echo %cRED%[ ERROR  ]%cRESET% Security policy violation ^(CWE-319^): Refusing non-HTTPS URL in .jvm.lock: !T_URL!
    exit /b 1
)

echo.
echo ------------------------------------------------------------
echo %cBLUE%[ ACTION ]%cRESET% Processing locked candidate: !T_CAND! !T_VER! ...

rem Validate architecture
if /i "!T_ARCH!" NEQ "all" if /i "!T_ARCH!" NEQ "any" (
    if /i "!T_ARCH!" NEQ "!SYS_ARCH!" (
        if /i "!SYS_ARCH!"=="aarch64" if /i "!T_ARCH!"=="x64" (
            echo %cYELLOW%[ WARNING]%cRESET% Locked tool is x64, running under ARM64 emulation.
        ) else (
            echo %cRED%[ ERROR  ]%cRESET% Architecture mismatch in .jvm.lock!
            echo            Locked architecture: !T_ARCH!
            echo            Current host       : !SYS_ARCH!
            exit /b 1
        )
    )
)

if /i "!T_CAND!"=="java" goto :InstallLockedJava

rem Ecosystem candidate
set "INST_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\!T_CAND!\!T_VER!"
if exist "!INST_PATH!\bin" (
    echo %cGREEN%[   OK   ]%cRESET% Locked !T_CAND! !T_VER! is already installed:
    echo            !INST_PATH!
    call :SwitchCandidate "!T_VER!"
    exit /b 0
)

call :RequireNetwork
if errorlevel 1 exit /b 1

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "T_RANDOM_NAME=%%A"
set "DL_URL=!T_URL!"
set "DL_ZIP=%JVM_SECURE_TEMP%\jvm_locked_!T_CAND!_!T_VER!_!T_RANDOM_NAME!.zip"
set "DL_EXTRACT=!INST_PATH!"
set "DL_CHKSUM_URL="
set "DL_CHKSUM_VAL=!T_CHK!"
set "DL_CHKSUM_TYPE=!T_CHKTYPE!"
set "DL_STRIP_ROOT=1"

call :ExecuteSharedDownloader
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to download/verify locked candidate !T_CAND!.
    if exist "!INST_PATH!" rmdir /s /q "!INST_PATH!" >nul 2>&1
    exit /b 1
)

set "TARGET_CANDIDATE=!T_CAND!"
call :SwitchCandidate "!T_VER!"
exit /b 0

:InstallLockedJava
set "ALREADY_INST_PATH="
for /l %%k in (1,1,!JDK_COUNT!) do (
    if not defined ALREADY_INST_PATH (
        if /i "!JDK_VENDOR_%%k!"=="!T_VEND!" (
            if "!JDK_MAJOR_%%k!"=="!T_VER!" set "ALREADY_INST_PATH=!JDK_PATH_%%k!"
            if /i "!JDK_NAME_%%k!"=="!T_VER!" set "ALREADY_INST_PATH=!JDK_PATH_%%k!"
        )
    )
)

if defined ALREADY_INST_PATH (
    echo %cGREEN%[   OK   ]%cRESET% Locked Java !T_VER! ^(!T_VEND!^) is already installed:
    echo            !ALREADY_INST_PATH!
    set "CURRENT_JDK_PATH=!ALREADY_INST_PATH!"
    if "!SESSION_MODE!"=="1" (
        call :EmitSessionEnv "JAVA_HOME=!CURRENT_JDK_PATH!"
    ) else (
        call :UpdateSystemPath
    )
    exit /b 0
)

call :RequireNetwork
if errorlevel 1 exit /b 1

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "T_RANDOM_NAME=%%A"
set "DL_VENDOR=!T_VEND!"
set "DL_VERSION=!T_VER!"
set "ZIP_PATH=%JVM_SECURE_TEMP%\jdk_locked_!T_VEND!_!T_VER!_!T_RANDOM_NAME!.zip"
set "EXTRACT_DIR=%JVM_SECURE_TEMP%\jdk_locked_!T_VEND!_!T_VER!_!T_RANDOM_NAME!_ext"
set "DEST_DIR=!JVM_PF!\Java"

set "DL_URL=!T_URL!"
set "DL_ZIP=!ZIP_PATH!"
set "DL_EXTRACT=!EXTRACT_DIR!"
set "DL_CHKSUM_URL="
set "DL_CHKSUM_VAL=!T_CHK!"
set "DL_CHKSUM_TYPE=!T_CHKTYPE!"
set "DL_STRIP_ROOT=0"

call :ExecuteSharedDownloader
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to download/verify locked JDK !T_VER! ^(!T_VEND!^).
    if exist "!ZIP_PATH!" del /f /q "!ZIP_PATH!" >nul 2>&1
    if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!" >nul 2>&1
    exit /b 1
)

setlocal enabledelayedexpansion
goto :DoElevatedJdkInstall

rem ============================================================
rem Universal Candidate Engine
rem ============================================================
:RouteEcosystemCandidate
if /i "!CLI_COMMAND!"=="install" (
    if "!FLAG_LOCKED!"=="1" (
        call :ExecuteLockedInstall
        exit /b !errorlevel!
    )
    call :InstallCandidate
    exit /b !errorlevel!
)
if /i "!CLI_COMMAND!"=="update" (
    call :RequireNetwork
    if errorlevel 1 exit /b 1
    set "act_ver=none"
    set "QUERY_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!\current"
    if exist "!QUERY_PATH!" (
        for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath $env:QUERY_PATH -ErrorAction SilentlyContinue).Target" 2^>nul') do for %%X in ("%%A") do set "act_ver=%%~nxX"
        call :ValidateStrictIdentifier "!act_ver!" act_ver
        if errorlevel 1 set "act_ver=none"
    )
    call :EcoPerformCheck !TARGET_CANDIDATE! "!act_ver!"
    exit /b !errorlevel!
)
if /i "!CLI_COMMAND!"=="lock" (
    call :ExecuteLockCommand
    exit /b !errorlevel!
)
if /i "!CLI_COMMAND!"=="list" (
    call :ListEcosystemCandidates
    exit /b !errorlevel!
)
if /i "!CLI_COMMAND!"=="uninstall" (
    call :UninstallCandidate
    exit /b !errorlevel!
)
if /i "!CLI_COMMAND!"=="which" (
    call :WhichBinary
    exit /b !errorlevel!
)
if /i "!CLI_COMMAND!"=="open" (
    call :OpenFolderInExplorer
    exit /b !errorlevel!
)
if /i "!CLI_COMMAND!"=="current" (
    echo %cRED%[ ERROR  ]%cRESET% 'current' is a reserved keyword and cannot be targeted.
    exit /b 1
)
if /i "!CLI_COMMAND!"=="" (
    if defined CLI_TARGET (
        call :SwitchCandidate "!CLI_TARGET!"
        exit /b !errorlevel!
    )
)
echo %cRED%[ ERROR  ]%cRESET% Unknown command for !TARGET_CANDIDATE!
exit /b 1

:ValidateStrictIdentifier
setlocal disabledelayedexpansion
set "_VSI_RAW=%~1"
if not defined _VSI_RAW (
    endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)

:: Check for ! without pipes or subshells to prevent poison character evaluation
if "%_VSI_RAW:~0,1%"=="!" (
    endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
if "%_VSI_RAW:~-1%"=="!" (
    endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
for /f "tokens=1* delims=!" %%a in ("%_VSI_RAW%") do (
    if not "%%b"=="" (
        endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
)

setlocal enabledelayedexpansion
set "_VSI_VAL=!_VSI_RAW!"

:: Check for % via substitution
set "_VSI_SUB=!_VSI_VAL:%%=!"
if not "!_VSI_VAL!"=="!_VSI_SUB!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)

:: Strip trailing dots and spaces first to prevent Win32 normalization bypass
:VSI_StripTrailing
if "!_VSI_VAL:~-1!"=="." (
    set "_VSI_VAL=!_VSI_VAL:~0,-1!"
    goto :VSI_StripTrailing
)
if "!_VSI_VAL:~-1!"==" " (
    set "_VSI_VAL=!_VSI_VAL:~0,-1!"
    goto :VSI_StripTrailing
)
if not defined _VSI_VAL (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)

:: Disallow leading '-' (flag injection)
if "!_VSI_VAL:~0,1!"=="-" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)

:: Disallow path separators, traversal, and ADS stream colons via substitution
if not "!_VSI_VAL!"=="!_VSI_VAL:\=!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
if not "!_VSI_VAL!"=="!_VSI_VAL:/=!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
if not "!_VSI_VAL!"=="!_VSI_VAL:..=!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
if not "!_VSI_VAL!"=="!_VSI_VAL::=!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)

:: Check poison chars via substitution (&, |, <, >, ^, ;, \")
set "_VSI_SUB=!_VSI_VAL:^=!"
if not "!_VSI_VAL!"=="!_VSI_SUB!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
set "_VSI_SUB=!_VSI_VAL:&=!"
if not "!_VSI_VAL!"=="!_VSI_SUB!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
set "_VSI_SUB=!_VSI_VAL:|=!"
if not "!_VSI_VAL!"=="!_VSI_SUB!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
set "_VSI_SUB=!_VSI_VAL:<=!"
if not "!_VSI_VAL!"=="!_VSI_SUB!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
set "_VSI_SUB=!_VSI_VAL:>=!"
if not "!_VSI_VAL!"=="!_VSI_SUB!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
set "_VSI_SUB=!_VSI_VAL:;=!"
if not "!_VSI_VAL!"=="!_VSI_SUB!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
set "_VSI_SUB=!_VSI_VAL:,=!"
if not "!_VSI_VAL!"=="!_VSI_SUB!" (
    endlocal & endlocal
    set "JVM_EXIT_CODE=1"
    exit /b 1
)
:: Loop characters to detect wildcards (*, ?) and URL/PowerShell injection metacharacters without subshells or pipes
set _VSI_DQ="
set "_VSI_REM=!_VSI_VAL!"
:VSI_CharLoop
if defined _VSI_REM (
    set "_VSI_CH=!_VSI_REM:~0,1!"
    set "_VSI_REM=!_VSI_REM:~1!"
    if "!_VSI_CH!"=="*" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!_VSI_CH!"=="?" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!_VSI_CH!"=="!_VSI_DQ!" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!_VSI_CH!"=="#" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!_VSI_CH!"=="@" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!_VSI_CH!"=="'" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!_VSI_CH!"=="$" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!_VSI_CH!"=="`" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!_VSI_CH!"=="(" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!_VSI_CH!"==")" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if "!_VSI_CH!"==" " (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    goto :VSI_CharLoop
)

:: Check DOS device names (CON, PRN, AUX, NUL, COM1-9, LPT1-9) including base name with extension (e.g., NUL.jdk)
set "_VSI_BASE=!_VSI_VAL!"
for /f "tokens=1 delims=." %%B in ("!_VSI_VAL!") do set "_VSI_BASE=%%B"
for %%D in (CON PRN AUX NUL COM1 COM2 COM3 COM4 COM5 COM6 COM7 COM8 COM9 LPT1 LPT2 LPT3 LPT4 LPT5 LPT6 LPT7 LPT8 LPT9) do (
    if /i "!_VSI_VAL!"=="%%D" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
    if /i "!_VSI_BASE!"=="%%D" (
        endlocal & endlocal
        set "JVM_EXIT_CODE=1"
        exit /b 1
    )
)

:: Export sanitized value if requested
for /f "delims=" %%V in ("!_VSI_VAL!") do (
    endlocal & endlocal
    if not "%~2"=="" set "%~2=%%V"
    exit /b 0
)
endlocal & endlocal
exit /b 0

:GetCandidateEnvVar
set "CANDIDATE_ENV_VAR="
set "CANDIDATE_PROPER_NAME="
if /i "!TARGET_CANDIDATE!"=="maven" ( set "CANDIDATE_ENV_VAR=MAVEN_HOME" & set "CANDIDATE_PROPER_NAME=Maven" )
if /i "!TARGET_CANDIDATE!"=="gradle" ( set "CANDIDATE_ENV_VAR=GRADLE_HOME" & set "CANDIDATE_PROPER_NAME=Gradle" )
if /i "!TARGET_CANDIDATE!"=="kotlin" ( set "CANDIDATE_ENV_VAR=KOTLIN_HOME" & set "CANDIDATE_PROPER_NAME=Kotlin" )
if /i "!TARGET_CANDIDATE!"=="scala" ( set "CANDIDATE_ENV_VAR=SCALA_HOME" & set "CANDIDATE_PROPER_NAME=Scala" )
if /i "!TARGET_CANDIDATE!"=="groovy" ( set "CANDIDATE_ENV_VAR=GROOVY_HOME" & set "CANDIDATE_PROPER_NAME=Groovy" )
if /i "!TARGET_CANDIDATE!"=="ant" ( set "CANDIDATE_ENV_VAR=ANT_HOME" & set "CANDIDATE_PROPER_NAME=Ant" )
if /i "!TARGET_CANDIDATE!"=="sbt" ( set "CANDIDATE_ENV_VAR=SBT_HOME" & set "CANDIDATE_PROPER_NAME=sbt" )
if /i "!TARGET_CANDIDATE!"=="jbang" ( set "CANDIDATE_ENV_VAR=JBANG_HOME" & set "CANDIDATE_PROPER_NAME=JBang" )
if /i "!TARGET_CANDIDATE!"=="quarkus" ( set "CANDIDATE_ENV_VAR=QUARKUS_HOME" & set "CANDIDATE_PROPER_NAME=Quarkus" )
if /i "!TARGET_CANDIDATE!"=="spring" ( set "CANDIDATE_ENV_VAR=SPRING_HOME" & set "CANDIDATE_PROPER_NAME=Spring Boot CLI" )
if /i "!TARGET_CANDIDATE!"=="micronaut" ( set "CANDIDATE_ENV_VAR=MICRONAUT_HOME" & set "CANDIDATE_PROPER_NAME=Micronaut" )
if /i "!TARGET_CANDIDATE!"=="mn" ( set "CANDIDATE_ENV_VAR=MICRONAUT_HOME" & set "CANDIDATE_PROPER_NAME=Micronaut" )
exit /b 0

:SwitchCandidate
call :AcquireStateLock
if errorlevel 1 exit /b 1
set "TARGET_VER=%~1"
call :GetCandidateEnvVar
set "CANDIDATE_DIR=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!"

if /i "!TARGET_VER!"=="latest" (
    if exist "!CANDIDATE_DIR!" (
        for /f "delims=" %%V in ('%PS_BIN% -NoProfile -Command "Get-ChildItem -LiteralPath '!CANDIDATE_DIR!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { $r=($_.Name -replace '-.*','').Trim(); if ($r -match '^\d+$') { [version]\"$r.0\" } elseif ($r -match '^\d+(\.\d+)+$') { [version]$r } else { [version]'0.0' } } -Descending | Select-Object -First 1 -ExpandProperty Name" 2^>nul') do (
            set "TARGET_VER=%%V"
        )
    )
)

if not "!TARGET_VER!"=="!TARGET_VER:\=!" (
    call :ReleaseStateLock
    echo %cRED%[ ERROR  ]%cRESET% Version identifier cannot contain path separators: !TARGET_VER!
    exit /b 1
)
if not "!TARGET_VER!"=="!TARGET_VER:/=!" (
    call :ReleaseStateLock
    echo %cRED%[ ERROR  ]%cRESET% Version identifier cannot contain path separators: !TARGET_VER!
    exit /b 1
)
if not "!TARGET_VER!"=="!TARGET_VER:..=!" (
    call :ReleaseStateLock
    echo %cRED%[ ERROR  ]%cRESET% Version identifier cannot contain '..': !TARGET_VER!
    exit /b 1
)
if "!TARGET_VER!"=="." (
    call :ReleaseStateLock
    echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier: '.' is forbidden.
    exit /b 1
)
call :ValidateStrictIdentifier "!TARGET_VER!" TARGET_VER
if errorlevel 1 (
    call :ReleaseStateLock
    echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier: %~1
    exit /b 1
)
if /i "!TARGET_VER!"=="current" (
    call :ReleaseStateLock
    echo %cRED%[ ERROR  ]%cRESET% 'current' is a reserved keyword and cannot be targeted.
    exit /b 1
)

set "TARGET_PATH=!CANDIDATE_DIR!\!TARGET_VER!"

if not exist "!TARGET_PATH!" (
    call :ReleaseStateLock
    echo.
    echo %cRED%[ ERROR  ]%cRESET% !CANDIDATE_PROPER_NAME! version !TARGET_VER! is not installed.
    exit /b 1
)
"%FSUTIL_BIN%" reparsepoint query "!TARGET_PATH!" >nul 2>&1
if not errorlevel 1 (
    call :ReleaseStateLock
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Candidate target directory cannot be a reparse point.
    exit /b 1
)
if not exist "!TARGET_PATH!\bin" (
    call :ReleaseStateLock
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-426^): Target candidate has no bin directory: !TARGET_PATH!\bin
    exit /b 1
)

set "SYMLINK_PATH=!CANDIDATE_DIR!\current"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Activating !CANDIDATE_PROPER_NAME! !TARGET_VER!...

set "PREV_JUNCTION_TARGET="
if exist "!SYMLINK_PATH!" (
    "%FSUTIL_BIN%" reparsepoint query "!SYMLINK_PATH!" >nul 2>&1
    if errorlevel 1 (
        call :ReleaseStateLock
        echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): !SYMLINK_PATH! is a regular directory, not a junction.
        exit /b 1
    )
    for /f "delims=" %%T in ('%PS_BIN% -NoProfile -Command "$i = Get-Item -LiteralPath $env:SYMLINK_PATH -Force -ErrorAction SilentlyContinue; if ($i -and $i.Target) { $i.Target | Select-Object -First 1 }" 2^>nul') do set "PREV_JUNCTION_TARGET=%%T"
    rmdir "!SYMLINK_PATH!" >nul 2>&1
    if exist "!SYMLINK_PATH!" (
        call :ReleaseStateLock
        echo %cRED%[ ERROR  ]%cRESET% Failed to remove existing directory junction for !CANDIDATE_PROPER_NAME!.
        exit /b 1
    )
)
mklink /j "!SYMLINK_PATH!" "!TARGET_PATH!" >nul 2>&1
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to create directory junction for !CANDIDATE_PROPER_NAME!.
    echo            Notice: NTFS Directory Junctions require local NTFS volumes.
    echo            Ensure %%LOCALAPPDATA%% and candidate paths reside on local NTFS volumes.
    if defined PREV_JUNCTION_TARGET if exist "!PREV_JUNCTION_TARGET!" mklink /j "!SYMLINK_PATH!" "!PREV_JUNCTION_TARGET!" >nul 2>&1
    call :ReleaseStateLock
    exit /b 1
)
"%FSUTIL_BIN%" reparsepoint query "!SYMLINK_PATH!" >nul 2>&1
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Junction verification failed for !CANDIDATE_PROPER_NAME!.
    rmdir "!SYMLINK_PATH!" >nul 2>&1
    if defined PREV_JUNCTION_TARGET if exist "!PREV_JUNCTION_TARGET!" mklink /j "!SYMLINK_PATH!" "!PREV_JUNCTION_TARGET!" >nul 2>&1
    call :ReleaseStateLock
    exit /b 1
)
echo            - Updating Directory Junction...

"%PS_BIN%" -NoProfile -Command "[Environment]::SetEnvironmentVariable($env:CANDIDATE_ENV_VAR, $env:SYMLINK_PATH, 'User')"
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to set !CANDIDATE_ENV_VAR! in registry.
    rmdir "!SYMLINK_PATH!" >nul 2>&1
    if defined PREV_JUNCTION_TARGET if exist "!PREV_JUNCTION_TARGET!" mklink /j "!SYMLINK_PATH!" "!PREV_JUNCTION_TARGET!" >nul 2>&1
    call :ReleaseStateLock
    exit /b 1
)

rem Update user PATH safely in PowerShell avoiding CMD pipe parsing hazards
set "PATH_UPDATED=0"
for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "$varBin = [char]37 + $env:CANDIDATE_ENV_VAR + [char]37 + '\bin'; $p = [Environment]::GetEnvironmentVariable('Path', 'User'); if (-not $p) { Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $varBin -Type ExpandString; Write-Output 'INJECTED' } elseif (($p -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -eq $varBin }) -eq $null) { Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value ($varBin + ';' + $p) -Type ExpandString; Write-Output 'INJECTED' } else { Write-Output 'EXISTS' }"') do (
    if "%%A"=="INJECTED" set "PATH_UPDATED=1"
)
if "!PATH_UPDATED!"=="1" (
    echo            - Injecting %%!CANDIDATE_ENV_VAR!%%\bin into PATH...
) else (
    echo            - Updating !CANDIDATE_ENV_VAR! variables...
)

rem Inject immediately into active terminal session without spawning pipe child shell (CWE-78)
call :EmitSessionEnv "!CANDIDATE_ENV_VAR!=!SYMLINK_PATH!"
set "!CANDIDATE_ENV_VAR!=!SYMLINK_PATH!"
set "CHECK_PATH=;!PATH!;"
if "!CHECK_PATH:;!SYMLINK_PATH!\bin;=!"=="!CHECK_PATH!" (
    set "PATH=!SYMLINK_PATH!\bin;!PATH!"
)

echo.
echo %cGREEN%[   OK   ]%cRESET% !CANDIDATE_PROPER_NAME! !TARGET_VER! is now active!
call :ReleaseStateLock
exit /b 0

:InstallCandidate
call :RequireNetwork
if errorlevel 1 (
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)
call :GetCandidateEnvVar
set "IS_INTERACTIVE_UI=0"
if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" set "IS_INTERACTIVE_UI=1"
echo %cBLUE%[ ACTION ]%cRESET% Installing !CANDIDATE_PROPER_NAME!...

set "TARGET_VER=!CLI_TARGET!"
if not defined TARGET_VER set "TARGET_VER=latest"
if /i "!TARGET_VER!"=="latest" (
    echo %cBLUE%[ ACTION ]%cRESET% Resolving latest version of !CANDIDATE_PROPER_NAME!...
    call :ResolveLatestEcosystemCandidate
    set "TARGET_VER=!LATEST_VER!"
    
    if "!TARGET_VER!"=="ERROR" (
        echo %cRED%[ ERROR  ]%cRESET% Failed to resolve latest version of !CANDIDATE_PROPER_NAME!. Check your internet connection.
        if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
        exit /b 1
    )
    echo %cGREEN%[   OK   ]%cRESET% Latest version resolved to !TARGET_VER!.
)

if not "!TARGET_VER!"=="!TARGET_VER:\=!" (
    echo %cRED%[ ERROR  ]%cRESET% Version identifier cannot contain path separators: !TARGET_VER!
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)
if not "!TARGET_VER!"=="!TARGET_VER:/=!" (
    echo %cRED%[ ERROR  ]%cRESET% Version identifier cannot contain path separators: !TARGET_VER!
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)
if not "!TARGET_VER!"=="!TARGET_VER:..=!" (
    echo %cRED%[ ERROR  ]%cRESET% Version identifier cannot contain '..': !TARGET_VER!
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)
if "!TARGET_VER!"=="." (
    echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier: '.' is forbidden.
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)
if /i "!TARGET_VER!"=="current" (
    echo %cRED%[ ERROR  ]%cRESET% 'current' is a reserved keyword and cannot be targeted.
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)
call :ValidateStrictIdentifier "!TARGET_VER!" TARGET_VER
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier: !TARGET_VER!
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)

rem Build the download URL
call :BuildEcosystemCandidateUrls

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "CAND_RANDOM_NAME=%%A"
set "ZIP_DEST=%JVM_SECURE_TEMP%\jvm_!TARGET_CANDIDATE!_!TARGET_VER!_!CAND_RANDOM_NAME!.zip"
set "EXTRACT_DEST=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!\!TARGET_VER!"
set "EXTRACT_DEST_TEMP=%JVM_SECURE_TEMP%\jvm_!TARGET_CANDIDATE!_!TARGET_VER!_!CAND_RANDOM_NAME!_temp"
set "EXTRACT_DEST_OLD=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!\!TARGET_VER!.jvm_bak_!CAND_RANDOM_NAME!"

if exist "!EXTRACT_DEST!" (
    echo.
    echo %cYELLOW%[ WARNING]%cRESET% !CANDIDATE_PROPER_NAME! version !TARGET_VER! is already installed^^!
    echo.
    if "!FORCE_YES!"=="1" (
        echo %cBLUE%[  INFO  ]%cRESET% Reinstalling/overwriting due to --yes flag...
    ) else (
        "%CHOICE_BIN%" /C yn /N /M "Would you like to reinstall and overwrite it? (y/N): "
        if !errorlevel! NEQ 1 (
            echo %cBLUE%[  INFO  ]%cRESET% Installation cancelled.
            exit /b 0
        )
    )
)

if exist "!EXTRACT_DEST_TEMP!" rmdir /s /q "!EXTRACT_DEST_TEMP!"
mkdir "!EXTRACT_DEST_TEMP!" >nul 2>&1

rem Map variables to Universal Downloader
set "DL_URL=!DOWNLOAD_URL!"
set "DL_ZIP=!ZIP_DEST!"
set "DL_EXTRACT=!EXTRACT_DEST_TEMP!"
set "DL_CHKSUM_URL=!CHECKSUM_URL!"
set "DL_FALLBACK_URL=!FALLBACK_URL!"
set "DL_FALLBACK_CHKSUM=!FALLBACK_CHECKSUM_URL!"
set "DL_FALLBACK2_URL=!FALLBACK2_URL!"
set "DL_FALLBACK2_CHKSUM=!FALLBACK2_CHECKSUM_URL!"
set "DL_CHKSUM_VAL="
set "DL_CHKSUM_TYPE=!CHECKSUM_TYPE!"
set "DL_STRIP_ROOT=1"

if not exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!" mkdir "%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!"

call :AcquireStateLock
if errorlevel 1 (
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)

call :ExecuteSharedDownloader
if !errorlevel! NEQ 0 (
    if exist "!ZIP_DEST!" del /f /q "!ZIP_DEST!" >nul 2>&1
    if exist "!EXTRACT_DEST_TEMP!" rmdir /S /Q "!EXTRACT_DEST_TEMP!" >nul 2>&1
    call :ReleaseStateLock
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)

if exist "!EXTRACT_DEST!" (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Staging existing installation for atomic replacement...
    move /Y "!EXTRACT_DEST!" "!EXTRACT_DEST_OLD!" >nul 2>&1
)

move /Y "!EXTRACT_DEST_TEMP!" "!EXTRACT_DEST!" >nul 2>&1
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to move extracted !CANDIDATE_PROPER_NAME! into destination. Rolling back...
    if exist "!EXTRACT_DEST_OLD!" move /Y "!EXTRACT_DEST_OLD!" "!EXTRACT_DEST!" >nul 2>&1
    if exist "!ZIP_DEST!" del /f /q "!ZIP_DEST!" >nul 2>&1
    if exist "!EXTRACT_DEST_TEMP!" rmdir /S /Q "!EXTRACT_DEST_TEMP!" >nul 2>&1
    call :ReleaseStateLock
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)
if not exist "!EXTRACT_DEST!" (
    echo %cRED%[ ERROR  ]%cRESET% Destination directory missing after move. Rolling back...
    if exist "!EXTRACT_DEST_OLD!" move /Y "!EXTRACT_DEST_OLD!" "!EXTRACT_DEST!" >nul 2>&1
    if exist "!ZIP_DEST!" del /f /q "!ZIP_DEST!" >nul 2>&1
    if exist "!EXTRACT_DEST_TEMP!" rmdir /S /Q "!EXTRACT_DEST_TEMP!" >nul 2>&1
    call :ReleaseStateLock
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    exit /b 1
)
if exist "!EXTRACT_DEST_OLD!" (
    "%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -Command "$d = $env:EXTRACT_DEST_OLD; if (Test-Path -LiteralPath $d) { Get-ChildItem -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint } | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object { if ($_.PSIsContainer) { [System.IO.Directory]::Delete($_.FullName, $false) } else { [System.IO.File]::Delete($_.FullName) } }; Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue }" >nul 2>&1
)
if exist "!ZIP_DEST!" del /f /q "!ZIP_DEST!" >nul 2>&1
if exist "!EXTRACT_DEST_TEMP!" rmdir /S /Q "!EXTRACT_DEST_TEMP!" >nul 2>&1
echo.

echo %cGREEN%[   OK   ]%cRESET% Successfully installed !CANDIDATE_PROPER_NAME! !TARGET_VER!.

if not exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!\current" (
    echo.
    echo %cBLUE%[  INFO  ]%cRESET% First installation detected. Auto-activating...
    call :SwitchCandidate "!TARGET_VER!"
    if errorlevel 1 (
        call :ReleaseStateLock
        if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
        exit /b 1
    )
) else (
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" (
        echo.
        "%CHOICE_BIN%" /C yn /N /M "Would you like to activate !CANDIDATE_PROPER_NAME! !TARGET_VER! now? (y/N): "
        if !errorlevel!==1 (
            call :SwitchCandidate "!TARGET_VER!"
        )
    )
)

call :ReleaseStateLock
if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
exit /b 0

:UninstallCandidate
call :GetCandidateEnvVar
set "TARGET_VER=!CLI_TARGET!"
if defined TARGET_VER if /i not "!TARGET_VER!"=="latest" (
    if not "!TARGET_VER!"=="!TARGET_VER:\=!" (
        echo %cRED%[ ERROR  ]%cRESET% Version identifier cannot contain path separators: !TARGET_VER!
        exit /b 1
    )
    if not "!TARGET_VER!"=="!TARGET_VER:/=!" (
        echo %cRED%[ ERROR  ]%cRESET% Version identifier cannot contain path separators: !TARGET_VER!
        exit /b 1
    )
    if not "!TARGET_VER!"=="!TARGET_VER:..=!" (
        echo %cRED%[ ERROR  ]%cRESET% Version identifier cannot contain '..': !TARGET_VER!
        exit /b 1
    )
    if "!TARGET_VER!"=="." (
        echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier: '.' is forbidden.
        exit /b 1
    )
    call :ValidateStrictIdentifier "!TARGET_VER!" TARGET_VER
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier: !CLI_TARGET!
        exit /b 1
    )
    if /i "!TARGET_VER!"=="current" (
        echo %cRED%[ ERROR  ]%cRESET% 'current' is a reserved keyword and cannot be targeted.
        exit /b 1
    )
)
if "!TARGET_VER!"=="" (
    set "CANDIDATE_DIR=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!"
    if not exist "!CANDIDATE_DIR!" (
        echo %cRED%[ ERROR  ]%cRESET% No !CANDIDATE_PROPER_NAME! versions are installed.
        exit /b 1
    )
    set "VER_COUNT=0"
    set "SINGLE_VER="
    for /f "delims=" %%V in ('%PS_BIN% -NoProfile -Command "Get-ChildItem -LiteralPath '!CANDIDATE_DIR!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { $r=($_.Name -replace '-.*','').Trim(); if ($r -match '^\d+$') { [version]\"$r.0\" } elseif ($r -match '^\d+(\.\d+)+$') { [version]$r } else { [version]'0.0' } } -Descending | Select-Object -ExpandProperty Name" 2^>nul') do (
        set /a VER_COUNT+=1
        set "SINGLE_VER=%%V"
    )
    if !VER_COUNT! EQU 0 (
        echo %cRED%[ ERROR  ]%cRESET% No !CANDIDATE_PROPER_NAME! versions are installed.
        exit /b 1
    )
    if !VER_COUNT! EQU 1 (
        set "TARGET_VER=!SINGLE_VER!"
        echo %cBLUE%[  INFO  ]%cRESET% Only one version installed: !SINGLE_VER!
    ) else (
        echo.
        echo %cBLUE%[  INFO  ]%cRESET% Multiple !CANDIDATE_PROPER_NAME! versions installed:
        echo.
        set "IDX=0"
        for /f "delims=" %%V in ('%PS_BIN% -NoProfile -Command "Get-ChildItem -LiteralPath '!CANDIDATE_DIR!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { $r=($_.Name -replace '-.*','').Trim(); if ($r -match '^\d+$') { [version]\"$r.0\" } elseif ($r -match '^\d+(\.\d+)+$') { [version]$r } else { [version]'0.0' } } -Descending | Select-Object -ExpandProperty Name" 2^>nul') do (
            set /a IDX+=1
            set "VER_!IDX!=%%V"
            echo    !IDX!. %%V
        )
        echo.
        set "ver_choice="
        set /p "ver_choice=Select version to uninstall (1-!IDX!): "
::::::::::::::::::::
        set "TARGET_VER="
        if not defined ver_choice (
            echo %cYELLOW%[  INFO  ]%cRESET% Uninstallation cancelled.
            exit /b 0
        )
        if "!ver_choice!"=="" (
            echo %cYELLOW%[  INFO  ]%cRESET% Uninstallation cancelled.
            exit /b 0
        )
        if defined ver_choice (
            set "ver_choice=!ver_choice:"=!"
            set "ver_choice=!ver_choice: =!"
            if defined ver_choice (
                set "NUM_TEST="
                if not "!ver_choice!"=="!ver_choice:;=!" set "NUM_TEST=;"
                for /f "eol= delims=0123456789" %%A in ("!ver_choice!") do set "NUM_TEST=%%A"
                if not defined NUM_TEST (
                    if !ver_choice! GEQ 1 if !ver_choice! LEQ !IDX! (
                        for %%C in (!ver_choice!) do set "TARGET_VER=!VER_%%C!"
                    )
                )
            )
        )
        if not defined TARGET_VER (
            echo %cRED%[ ERROR  ]%cRESET% Invalid selection.
            exit /b 1
        )
    )
)

set "CANDIDATE_DIR=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!"

if /i "!TARGET_VER!"=="latest" (
    set "TARGET_VER="
    if exist "!CANDIDATE_DIR!" (
        for /f "delims=" %%V in ('%PS_BIN% -NoProfile -Command "Get-ChildItem -LiteralPath '!CANDIDATE_DIR!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { $r=($_.Name -replace '-.*','').Trim(); if ($r -match '^\d+$') { [version]\"$r.0\" } elseif ($r -match '^\d+(\.\d+)+$') { [version]$r } else { [version]'0.0' } } -Descending | Select-Object -First 1 -ExpandProperty Name" 2^>nul') do (
            set "TARGET_VER=%%V"
        )
    )
)

if not defined TARGET_VER (
    echo %cRED%[ ERROR  ]%cRESET% No version specified to uninstall.
    exit /b 1
)
call :ValidateStrictIdentifier "!TARGET_VER!" TARGET_VER
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Invalid version identifier: !TARGET_VER!
    exit /b 1
)
if /i "!TARGET_VER!"=="current" (
    echo %cRED%[ ERROR  ]%cRESET% 'current' is a reserved keyword and cannot be targeted.
    exit /b 1
)
set "TARGET_PATH=!CANDIDATE_DIR!\!TARGET_VER!"

if /i "!TARGET_PATH!"=="!CANDIDATE_DIR!" (
    echo %cRED%[ ERROR  ]%cRESET% Refusing to delete candidate root directory.
    exit /b 1
)
if /i "!TARGET_PATH!"=="!CANDIDATE_DIR!\" (
    echo %cRED%[ ERROR  ]%cRESET% Refusing to delete candidate root directory.
    exit /b 1
)
if not exist "!TARGET_PATH!" (
    echo %cRED%[ ERROR  ]%cRESET% !CANDIDATE_PROPER_NAME! version !TARGET_VER! is not installed.
    exit /b 1
)

call :AcquireStateLock
if errorlevel 1 exit /b 1

echo %cBLUE%[ ACTION ]%cRESET% Uninstalling !CANDIDATE_PROPER_NAME! version !TARGET_VER!...
"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -Command "$d = $env:TARGET_PATH; if (Test-Path -LiteralPath $d) { Get-ChildItem -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint } | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object { if ($_.PSIsContainer) { [System.IO.Directory]::Delete($_.FullName, $false) } else { [System.IO.File]::Delete($_.FullName) } }; $item = Get-Item -LiteralPath $d -Force -ErrorAction SilentlyContinue; if ($item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) { [System.IO.Directory]::Delete($d, $false) } else { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue } }" >nul 2>&1

if exist "!TARGET_PATH!" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to completely remove !CANDIDATE_PROPER_NAME! directory: !TARGET_PATH!
    echo            A file may be locked or in use by another process.
    call :ReleaseStateLock
    exit /b 1
)

rem Check if it was the active version
set "SYMLINK_PATH=!CANDIDATE_DIR!\current"
set "ACTIVE_TARGET="
for /f "tokens=1,2*" %%A in ('%FSUTIL_BIN% reparsepoint query "!SYMLINK_PATH!" 2^>nul ^| %FINDSTR_BIN% /i "Print Name:"') do set "ACTIVE_TARGET=%%C"
if not defined ACTIVE_TARGET (
    set "QUERY_PATH=!SYMLINK_PATH!"
    for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath $env:QUERY_PATH -ErrorAction SilentlyContinue).Target" 2^>nul') do set "ACTIVE_TARGET=%%A"
)
if defined ACTIVE_TARGET (
    set "ACTIVE_TARGET=!ACTIVE_TARGET:\??\=!"
    set "ACTIVE_TARGET=!ACTIVE_TARGET:\\?\=!"
    for /f "tokens=*" %%A in ("!ACTIVE_TARGET!") do set "ACTIVE_TARGET=%%A"
    for /f "delims=" %%A in ("!TARGET_PATH!") do set "NORM_TARGET=%%~fA"
    if /i "!ACTIVE_TARGET!"=="!NORM_TARGET!" (
        echo %cYELLOW%[ WARNING]%cRESET% Uninstalled the active version. Removing symlink...
        "%FSUTIL_BIN%" reparsepoint query "!SYMLINK_PATH!" >nul 2>&1
        if !errorlevel! EQU 0 (
            rmdir "!SYMLINK_PATH!" >nul 2>&1
            if errorlevel 1 (
                echo %cRED%[ ERROR  ]%cRESET% Failed to remove active junction: !SYMLINK_PATH!
                call :ReleaseStateLock
                exit /b 1
            )
            if exist "!SYMLINK_PATH!" (
                echo %cRED%[ ERROR  ]%cRESET% Active junction still exists after removal attempt: !SYMLINK_PATH!
                call :ReleaseStateLock
                exit /b 1
            )
        )
        "%REG_BIN%" delete "HKCU\Environment" /v !CANDIDATE_ENV_VAR! /f >nul 2>&1
    )
)

echo %cGREEN%[   OK   ]%cRESET% !CANDIDATE_PROPER_NAME! !TARGET_VER! successfully uninstalled.
call :ReleaseStateLock
exit /b 0

:ListEcosystemCandidates
if not exist "%LOCALAPPDATA%\DiamTek\JVM\candidates" exit /b 0
echo.
echo %cBLUE%[  INFO  ]%cRESET% Installed Ecosystem Tools:
echo ============================================================
for /d %%C in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\*") do (
    set "TARGET_CANDIDATE=%%~nxC"
    call :GetCandidateEnvVar
    echo  - !CANDIDATE_PROPER_NAME!
    
    set "ACTIVE_TARGET="
    for /f "tokens=1,2*" %%A in ('%FSUTIL_BIN% reparsepoint query "%%C\current" 2^>nul ^| %FINDSTR_BIN% /i "Print Name:"') do set "ACTIVE_TARGET=%%C"
    if not defined ACTIVE_TARGET (
        set "QUERY_PATH=%%C\current"
        for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "(Get-Item -LiteralPath $env:QUERY_PATH -ErrorAction SilentlyContinue).Target" 2^>nul') do set "ACTIVE_TARGET=%%A"
    )
    if defined ACTIVE_TARGET (
        set "ACTIVE_TARGET=!ACTIVE_TARGET:\??\=!"
        set "ACTIVE_TARGET=!ACTIVE_TARGET:\\?\=!"
        for /f "tokens=*" %%A in ("!ACTIVE_TARGET!") do set "ACTIVE_TARGET=%%A"
    )

    for /f "delims=" %%V in ('%PS_BIN% -NoProfile -Command "Get-ChildItem -LiteralPath '%%C' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { $r=($_.Name -replace '-.*','').Trim(); if ($r -match '^\d+$') { [version]\"$r.0\" } elseif ($r -match '^\d+(\.\d+)+$') { [version]$r } else { [version]'0.0' } } -Descending | Select-Object -ExpandProperty Name"') do (
        set "V_NAME=%%V"
        set "IS_ACTIVE="
        for /f "delims=" %%A in ("%%~fC\%%V") do set "TP=%%~fA"
        if /i "!ACTIVE_TARGET!"=="!TP!" set "IS_ACTIVE= %cGREEN%[ACTIVE]%cRESET%"
        echo      * !V_NAME!!IS_ACTIVE!
    )
    echo.
)
exit /b 0

:ListJdksJson
if !JDK_COUNT! LEQ 0 (
    echo []
    goto :eof
)
echo [
for /l %%k in (1,1,!JDK_COUNT!) do (
    set "IS_ACT=false"
    if /i "!JDK_PATH_%%k!"=="!RESOLVED_JAVA_HOME!" set "IS_ACT=true"
    set "ESCAPED_PATH=!JDK_PATH_%%k!"
    set "ESCAPED_PATH=!ESCAPED_PATH:\=\\!"
    set "ESCAPED_PATH=!ESCAPED_PATH:"=!"
    set "ESCAPED_NAME=!JDK_NAME_%%k!"
    set "ESCAPED_NAME=!ESCAPED_NAME:\=\\!"
    set "ESCAPED_NAME=!ESCAPED_NAME:"=!"
    set "COMMA=,"
    if %%k==!JDK_COUNT! set "COMMA="
    echo   {"index":%%k,"major":!JDK_MAJOR_%%k!,"name":"!ESCAPED_NAME!","vendor":"!JDK_VENDOR_%%k!","path":"!ESCAPED_PATH!","active":!IS_ACT!}!COMMA!
)
echo ]
goto :eof

:ProcessEcosystemSession
set "TARGET_CANDIDATE=%~1"
call :ValidateStrictIdentifier "!TARGET_CANDIDATE!" TARGET_CANDIDATE
if errorlevel 1 exit /b 1
set "TARGET_VER=%~2"
for /f "tokens=1 delims=# " %%C in ("!TARGET_VER!") do set "TARGET_VER=%%C"
call :ValidateStrictIdentifier "!TARGET_VER!" TARGET_VER
if errorlevel 1 exit /b 1
if /i "!TARGET_VER!"=="current" exit /b 1
call :GetCandidateEnvVar
if not defined CANDIDATE_ENV_VAR exit /b 0

set "T_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!\!TARGET_VER!"
if not exist "!T_PATH!" (
    echo %cYELLOW%[ WARNING]%cRESET% !CANDIDATE_PROPER_NAME! !TARGET_VER! is not installed.
    exit /b 0
)
"%FSUTIL_BIN%" reparsepoint query "!T_PATH!" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): !T_PATH! is a reparse point.
    exit /b 1
)
echo %cBLUE%[ ACTION ]%cRESET% Setting !CANDIDATE_PROPER_NAME! to !TARGET_VER!...
call :EmitSessionEnv "!CANDIDATE_ENV_VAR!=!T_PATH!"
set "!CANDIDATE_ENV_VAR!=!T_PATH!"
set "PATH=!T_PATH!\bin;!PATH!"
exit /b 0

rem ============================================================
rem Shared API Resolver for Ecosystem Tools
rem ============================================================
:ResolveLatestEcosystemCandidate
call :RequireNetwork
if errorlevel 1 (
    set "LATEST_VER=ERROR"
    exit /b 1
)
set "PS_RESOLVE_LATEST="
set "PS_TLS=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288; $ProgressPreference = 'SilentlyContinue';"
set "PS_CATCH=catch { if ($_.Exception.Response -and $_.Exception.Response.StatusCode -eq 'Forbidden') { 'RATE_LIMITED' } else { 'ERROR' } }"
if /i "!TARGET_CANDIDATE!"=="maven" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.github.com/repos/apache/maven/releases?per_page=50'; try { $h = @{}; if ($env:GITHUB_TOKEN) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }; $r = Invoke-RestMethod -Uri $url -Headers $h -UseBasicParsing -TimeoutSec 5; $t = $r | Where-Object { -not $_.prerelease -and -not $_.draft -and $_.tag_name -like 'maven-*' } | Select-Object -First 1; if ($t) { $t.tag_name.Replace('maven-','') } else { 'ERROR' } } !PS_CATCH!"
if /i "!TARGET_CANDIDATE!"=="gradle" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://services.gradle.org/versions/current'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 5).version } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="kotlin" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.github.com/repos/JetBrains/kotlin/releases/latest'; try { $h = @{}; if ($env:GITHUB_TOKEN) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }; ((Invoke-RestMethod -Uri $url -Headers $h -UseBasicParsing -TimeoutSec 5).tag_name).TrimStart('v') } !PS_CATCH!"
if /i "!TARGET_CANDIDATE!"=="scala" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.github.com/repos/scala/scala3/releases/latest'; try { $h = @{}; if ($env:GITHUB_TOKEN) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }; (Invoke-RestMethod -Uri $url -Headers $h -UseBasicParsing -TimeoutSec 5).tag_name } !PS_CATCH!"
if /i "!TARGET_CANDIDATE!"=="groovy" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.sdkman.io/2/candidates/default/groovy'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 5) } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="ant" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.sdkman.io/2/candidates/default/ant'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 5) } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="sbt" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.sdkman.io/2/candidates/default/sbt'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 5) } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="jbang" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.sdkman.io/2/candidates/default/jbang'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 5) } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="quarkus" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.sdkman.io/2/candidates/default/quarkus'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 5) } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="spring" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.sdkman.io/2/candidates/default/springboot'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 5) } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="micronaut" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.sdkman.io/2/candidates/default/micronaut'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 5) } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="mn" set "PS_RESOLVE_LATEST=!PS_TLS! $url='https://api.sdkman.io/2/candidates/default/micronaut'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 5) } catch { 'ERROR' }"

set "LATEST_VER=ERROR"
for /f "delims=" %%V in ('%PS_BIN% -NoProfile -Command "!PS_RESOLVE_LATEST!"') do (
    set "LATEST_VER=%%V"
)
if "!LATEST_VER!"=="RATE_LIMITED" (
    echo %cYELLOW%[ WARNING]%cRESET% GitHub API Rate Limit reached. Trying redirect fallback...
    set "PS_REDIR="
    if /i "!TARGET_CANDIDATE!"=="maven" set "PS_REDIR=!PS_TLS! try { $r=[Net.HttpWebRequest]::Create('https://github.com/apache/maven/releases/latest'); $r.AllowAutoRedirect=$false; $r.Timeout=10000; $resp=$r.GetResponse(); $loc=$null; try { $loc=[string]$resp.Headers['Location'] } finally { $resp.Close() }; if ($loc -match '^https://github\.com/apache/maven/releases/tag/maven-([0-9A-Za-z._+-]{1,64})$') { $Matches[1] } else { 'ERROR' } } catch { 'ERROR' }"
    if /i "!TARGET_CANDIDATE!"=="kotlin" set "PS_REDIR=!PS_TLS! try { $r=[Net.HttpWebRequest]::Create('https://github.com/JetBrains/kotlin/releases/latest'); $r.AllowAutoRedirect=$false; $r.Timeout=10000; $resp=$r.GetResponse(); $loc=$null; try { $loc=[string]$resp.Headers['Location'] } finally { $resp.Close() }; if ($loc -match '^https://github\.com/JetBrains/kotlin/releases/tag/v?([0-9A-Za-z._+-]{1,64})$') { $Matches[1] } else { 'ERROR' } } catch { 'ERROR' }"
    if /i "!TARGET_CANDIDATE!"=="scala" set "PS_REDIR=!PS_TLS! try { $r=[Net.HttpWebRequest]::Create('https://github.com/scala/scala3/releases/latest'); $r.AllowAutoRedirect=$false; $r.Timeout=10000; $resp=$r.GetResponse(); $loc=$null; try { $loc=[string]$resp.Headers['Location'] } finally { $resp.Close() }; if ($loc -match '^https://github\.com/scala/scala3/releases/tag/v?([0-9A-Za-z._+-]{1,64})$') { $Matches[1] } else { 'ERROR' } } catch { 'ERROR' }"
    if defined PS_REDIR (
        set "REDIR_TAG="
        for /f "delims=" %%T in ('%PS_BIN% -NoProfile -Command "!PS_REDIR!"') do set "REDIR_TAG=%%T"
        if not "!REDIR_TAG!"=="ERROR" if not "!REDIR_TAG!"=="" (
            set "LATEST_VER=!REDIR_TAG!"
            echo %cGREEN%[   OK   ]%cRESET% Resolved via redirect fallback.
        ) else (
            echo %cRED%[ ERROR  ]%cRESET% GitHub API Rate Limit reached and redirect fallback failed. Set GITHUB_TOKEN environment variable or try again later.
            set "LATEST_VER=ERROR"
        )
    ) else (
        echo %cRED%[ ERROR  ]%cRESET% GitHub API Rate Limit reached. Set GITHUB_TOKEN environment variable or try again later.
        set "LATEST_VER=ERROR"
    )
)
if not "!LATEST_VER!"=="ERROR" (
    call :ValidateStrictIdentifier "!LATEST_VER!" LATEST_VER
    if errorlevel 1 set "LATEST_VER=ERROR"
    if /i "!LATEST_VER!"=="current" set "LATEST_VER=ERROR"
    if /i "!LATEST_VER!"=="latest" set "LATEST_VER=ERROR"
)
exit /b 0

rem ============================================================
rem Universal Downloader & Extractor (PowerShell)
rem ============================================================
:ExecuteSharedDownloader
call :RequireNetwork
if errorlevel 1 exit /b 1
for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "PS_RANDOM_NAME=%%A"
set "PS_SCRIPT=%JVM_SECURE_TEMP%\jvm_dl_!PS_RANDOM_NAME!.ps1"
(
    echo $ErrorActionPreference = 'Stop'
    echo $ProgressPreference = 'SilentlyContinue'
    echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288
    echo try {
    echo     $url = $env:DL_URL
    echo     $out = $env:DL_ZIP
    echo     function Test-TrustedJvmUri^([System.Uri]$u^) {
    echo         if ^(-not $u -or $u.Scheme -ne 'https' -or $u.IsLoopback^) { return $false }
    echo         $h = $u.Host.ToLowerInvariant^(^)
    echo         $exact = @^('download.oracle.com','edelivery.oracle.com','api.adoptium.net','github.com','api.github.com','objects.githubusercontent.com','release-assets.githubusercontent.com','raw.githubusercontent.com','corretto.aws','api.azul.com','cdn.azul.com','static.azul.com','aka.ms','download.visualstudio.microsoft.com','api.bell-sw.com','download.bell-sw.com','repo.maven.apache.org','archive.apache.org','dlcdn.apache.org','downloads.apache.org','services.gradle.org','downloads.gradle.org','downloads.gradle-dn.com','api.sdkman.io','sap.github.io'^)
    echo         if ^($exact -contains $h^) { return $true }
    echo         if ^($h -match '^^corretto^(-downloads^)?\.[a-z0-9\-]+\.amazonaws\.com$' -or $h -match '^^corretto\.aws\.s3^(\.[a-z0-9\-]+^)?\.amazonaws\.com$'^) { return $true }
    echo         foreach ^($sfx in @^('.oracle.com','.adoptium.net','.github.com','.githubusercontent.com','.azul.com','.microsoft.com','.bell-sw.com','.apache.org','.gradle.org','.gradle-dn.com','.github.io'^)^) {
    echo             if ^($h.EndsWith^($sfx^)^) { return $true }
    echo         }
    echo         return $false
    echo     }
    echo     $dlUri = $null
    echo     if ^(-not [System.Uri]::TryCreate^($url, [System.UriKind]::Absolute, [ref]$dlUri^) -or $dlUri.Scheme -ne 'https'^) {
    echo         throw ^('Security policy violation ^(CWE-319^): Refusing non-HTTPS download URL: ' + $url^)
    echo     }
    echo     if ^(-not ^(Test-TrustedJvmUri $dlUri^)^) {
    echo         throw ^('Security policy violation ^(CWE-918^): Untrusted download host: ' + $dlUri.Host^)
    echo     }
    echo     if ^($env:DL_CHKSUM_URL^) {
    echo         $chkUri = $null
    echo         if ^(-not [System.Uri]::TryCreate^($env:DL_CHKSUM_URL, [System.UriKind]::Absolute, [ref]$chkUri^) -or $chkUri.Scheme -ne 'https'^) {
    echo             throw ^('Security policy violation ^(CWE-319^): Refusing non-HTTPS checksum URL: ' + $env:DL_CHKSUM_URL^)
    echo         }
    echo         if ^(-not ^(Test-TrustedJvmUri $chkUri^)^) {
    echo             throw ^('Security policy violation ^(CWE-918^): Untrusted checksum host: ' + $chkUri.Host^)
    echo         }
    echo     }
    echo     $dlUrls = @^($url^)
    echo     $dlChks = @^($env:DL_CHKSUM_URL^)
    echo     if ^($env:DL_FALLBACK_URL^) {
    echo         $fbUri = $null
    echo         if ^(-not [System.Uri]::TryCreate^($env:DL_FALLBACK_URL, [System.UriKind]::Absolute, [ref]$fbUri^) -or $fbUri.Scheme -ne 'https'^) {
    echo             throw ^('Security policy violation ^(CWE-319^): Refusing non-HTTPS download URL: ' + $env:DL_FALLBACK_URL^)
    echo         }
    echo         if ^(-not ^(Test-TrustedJvmUri $fbUri^)^) {
    echo             throw ^('Security policy violation ^(CWE-918^): Untrusted download host: ' + $fbUri.Host^)
    echo         }
    echo         $dlUrls += $env:DL_FALLBACK_URL
    echo         $dlChks += $env:DL_FALLBACK_CHKSUM
    echo     }
    echo     if ^($env:DL_FALLBACK2_URL^) {
    echo         $fb2Uri = $null
    echo         if ^(-not [System.Uri]::TryCreate^($env:DL_FALLBACK2_URL, [System.UriKind]::Absolute, [ref]$fb2Uri^) -or $fb2Uri.Scheme -ne 'https'^) {
    echo             throw ^('Security policy violation ^(CWE-319^): Refusing non-HTTPS download URL: ' + $env:DL_FALLBACK2_URL^)
    echo         }
    echo         if ^(-not ^(Test-TrustedJvmUri $fb2Uri^)^) {
    echo             throw ^('Security policy violation ^(CWE-918^): Untrusted download host: ' + $fb2Uri.Host^)
    echo         }
    echo         $dlUrls += $env:DL_FALLBACK2_URL
    echo         $dlChks += $env:DL_FALLBACK2_CHKSUM
    echo     }
    echo     $downloadStarted = $false
    echo     $response = $null
    echo     for ^($mi = 0; $mi -lt $dlUrls.Length; $mi++^) {
    echo         $mUrl = $dlUrls[$mi]
    echo         $mChk = $dlChks[$mi]
    echo         Write-Host ^('[ ACTION ] Downloading from ' + $mUrl + ' ...'^) -ForegroundColor Cyan
    echo         $maxRetries = 3; $retryCount = 0
    echo         while ^($retryCount -lt $maxRetries^) {
    echo             try {
    echo                 $request = [System.Net.WebRequest]::Create^($mUrl^)
    echo                 $request.Timeout = 15000
    echo                 $request.ReadWriteTimeout = 30000
    echo                 $response = $request.GetResponse^(^)
    echo                 if ^($response.ResponseUri -and $response.ResponseUri.Scheme -ne 'https'^) {
    echo                     $badUri = $response.ResponseUri; $response.Close^(^)
    echo                     throw ^('Security policy violation ^(CWE-319^): Blocked redirect to non-HTTPS URL: ' + $badUri^)
    echo                 }
    echo                 if ^($response.ResponseUri -and -not ^(Test-TrustedJvmUri $response.ResponseUri^)^) {
    echo                     $badUri = $response.ResponseUri; $response.Close^(^)
    echo                     throw ^('Security policy violation ^(CWE-601^): Blocked redirect to untrusted host: ' + $badUri.Host^)
    echo                 }
    echo                 $downloadStarted = $true
    echo                 $url = $mUrl
    echo                 $env:DL_CHKSUM_URL = $mChk
    echo                 break
    echo             } catch {
    echo                 $retryCount++
    echo                 $is404 = $false
    echo                 if ^($_.Exception -and $_.Exception.Response^) {
    echo                     try { if ^([int]$_.Exception.Response.StatusCode -eq 404^) { $is404 = $true } } catch { }
    echo                 }
    echo                 if ^($is404^) { break }
    echo                 if ^($retryCount -ge $maxRetries^) { break }
    echo                 Write-Host "`r[ WARNING] Network error, retrying ($retryCount/$maxRetries)... " -ForegroundColor Yellow
    echo                 Start-Sleep -Seconds 2
    echo             }
    echo         }
    echo         if ^($downloadStarted^) { break }
    echo         if ^($dlUrls.Length -gt 1^) {
    echo             Write-Host "`n[  INFO  ] Mirror returned 404 or failed. Trying alternate mirror..." -ForegroundColor Yellow
    echo         }
    echo     }
    echo     if ^(-not $downloadStarted -or -not $response^) {
    echo         throw ^('Failed to download from any trusted mirror: ' + $url^)
    echo     }
    echo     $totalLength = $response.ContentLength
    echo     $stream = $response.GetResponseStream^(^)
    echo     $fileStream = New-Object System.IO.FileStream^($out, [System.IO.FileMode]::Create^)
    echo     try {
    echo         $buffer = New-Object byte[] 65536
    echo         $downloaded = 0
    echo         $lastPercent = -1
    echo         while ^( ^( $read = $stream.Read^($buffer, 0, $buffer.Length^) ^) -gt 0 ^) {
    echo             $fileStream.Write^($buffer, 0, $read^)
    echo             $downloaded += $read
    echo             if ^($totalLength -gt 0^) {
    echo                 $percent = [math]::Floor^( ^($downloaded / $totalLength^) * 100 ^)
    echo                 if ^($percent -ne $lastPercent^) {
    echo                     $bar = '[' + ^('=' * [math]::Floor^($percent / 2^)^) + ^(' ' * ^(50 - [math]::Floor^($percent / 2^)^)^) + ']'
    echo                     $dMB = [math]::Round^($downloaded / 1MB, 1^)
    echo                     $tMB = [math]::Round^($totalLength / 1MB, 1^)
    echo                     Write-Host "`r[ ACTION ] Downloading: $bar $percent%% ($dMB / $tMB MB) " -NoNewline -ForegroundColor Cyan
    echo                     $lastPercent = $percent
    echo                 }
    echo             }
    echo         }
    echo     } finally {
    echo         $fileStream.Close^(^)
    echo         $fileStream.Dispose^(^)
    echo         if ^($stream^) { $stream.Close^(^); $stream.Dispose^(^) }
    echo         if ^($response^) { $response.Close^(^) }
    echo     }
    echo     if ^($totalLength -gt 0^) {
    echo         $tMB = [math]::Round^($totalLength / 1MB, 1^)
    echo         $fullBar = '[' + ^('=' * 50^) + ']'
    echo         Write-Host "`r[ ACTION ] Downloading: $fullBar 100%% ($tMB / $tMB MB) " -NoNewline -ForegroundColor Cyan
    echo     }
    echo     Write-Host "`n"
    echo     $cryptoType = if ^($env:DL_CHKSUM_TYPE^) { $env:DL_CHKSUM_TYPE } else { 'SHA256' }
    echo     if ^(-not $env:DL_CHKSUM_URL -and -not $env:DL_CHKSUM_VAL^) {
    echo         if ^($env:SKIP_CHECKSUM -ne '1'^) {
    echo             Write-Host '[ ERROR  ] Integrity checksum configuration missing for this download payload.' -ForegroundColor Red
    echo             Write-Host '           Aborting due to security policy. Rerun with --skip-checksum to bypass verification.' -ForegroundColor Red
    echo             if ^(Test-Path $out^) { Remove-Item $out -Force -ErrorAction SilentlyContinue }
    echo             exit 1
    echo         }
    echo         Write-Host '[ WARNING] Proceeding WITHOUT integrity verification ^(--skip-checksum active^).' -ForegroundColor Yellow
    echo         Write-Host ""
    echo     } else {
    echo         Write-Host "[ ACTION ] Verifying $cryptoType checksum..." -ForegroundColor Cyan
    echo         function Get-TrustedChecksumText^([string]$chkUrl^) {
    echo             $u = $null
    echo             if ^(-not [System.Uri]::TryCreate^($chkUrl, [System.UriKind]::Absolute, [ref]$u^) -or $u.Scheme -ne 'https'^) {
    echo                 throw ^('Security policy violation ^(CWE-319^): Refusing non-HTTPS checksum URL: ' + $chkUrl^)
    echo             }
    echo             if ^(-not ^(Test-TrustedJvmUri $u^)^) {
    echo                 throw ^('Security policy violation ^(CWE-918^): Untrusted checksum host: ' + $u.Host^)
    echo             }
    echo             $req = [System.Net.WebRequest]::Create^($chkUrl^)
    echo             $req.Timeout = 15000
    echo             $req.ReadWriteTimeout = 15000
    echo             $resp = $req.GetResponse^(^)
    echo             try {
    echo                 if ^($resp.ResponseUri -and $resp.ResponseUri.Scheme -ne 'https'^) {
    echo                     throw ^('Security policy violation ^(CWE-319^): Blocked checksum redirect to non-HTTPS URL: ' + $resp.ResponseUri^)
    echo                 }
    echo                 if ^($resp.ResponseUri -and -not ^(Test-TrustedJvmUri $resp.ResponseUri^)^) {
    echo                     throw ^('Security policy violation ^(CWE-601^): Blocked checksum redirect to untrusted host: ' + $resp.ResponseUri.Host^)
    echo                 }
    echo                 $sr = New-Object System.IO.StreamReader^($resp.GetResponseStream^(^)^)
    echo                 try {
    echo                     $buf = New-Object char[] 4096
    echo                     $n = $sr.Read^($buf, 0, $buf.Length^)
    echo                     return ^(New-Object string^($buf, 0, $n^)^).Trim^(^)
    echo                 } finally {
    echo                     $sr.Close^(^); $sr.Dispose^(^)
    echo                 }
    echo             } finally {
    echo                 $resp.Close^(^)
    echo             }
    echo         }
    echo         $expectedHash = $null
    echo         if ^($env:DL_CHKSUM_URL^) {
    echo             try {
    echo                 $expectedHash = Get-TrustedChecksumText $env:DL_CHKSUM_URL
    echo             } catch {
    echo                 if ^($_.Exception.Message -like 'Security policy violation*'^) { throw }
    echo                 if ^($env:DL_CHKSUM_URL -match '\.sha512$'^) {
    echo                     Write-Host "[ WARNING] SHA512 checksum not found, falling back to SHA1..." -ForegroundColor Yellow
    echo                     $fallbackUrl = $env:DL_CHKSUM_URL -replace '\.sha512$', '.sha1'
    echo                     try {
    echo                         $expectedHash = Get-TrustedChecksumText $fallbackUrl
    echo                         $cryptoType = 'SHA1'
    echo                     } catch {
    echo                         if ^($_.Exception.Message -like 'Security policy violation*'^) { throw }
    echo                         $expectedHash = $null
    echo                     }
    echo                 }
    echo             }
    echo         } else {
    echo             $expectedHash = $env:DL_CHKSUM_VAL
    echo         }
    echo         $zipName = [System.IO.Path]::GetFileName^($url^)
    echo         if ^($expectedHash -and ^($expectedHash -match '[\r\n]'^)^) {
    echo             $mLine = ^($expectedHash -split '[\r\n]+'^) ^| Where-Object { $_ -match [regex]::Escape^($zipName^) } ^| Select-Object -First 1
    echo             if ^($mLine -and ^($mLine -match '[0-9a-fA-F]{32,128}'^)^) { $expectedHash = $Matches[0] }
    echo         } elseif ^($expectedHash^) {
    echo             if ^($expectedHash -match '[0-9a-fA-F]{32,128}'^) { $expectedHash = $Matches[0] } else { $expectedHash = ^($expectedHash -split '\s+'^)[0].Trim^(^) }
    echo         }
    echo         if ^([string]::IsNullOrWhiteSpace^($expectedHash^) -and $url.StartsWith^('https://github.com/'^) -and $url.Contains^('/releases/download/'^)^) {
    echo             try {
    echo                 $uParts = $url.Substring^(19^).Split^('/'^)
    echo                 if ^($uParts.Length -ge 5 -and $uParts[2] -eq 'releases' -and $uParts[3] -eq 'download'^) {
    echo                     $ghOwner = $uParts[0]; $ghRepo = $uParts[1]; $ghTag = $uParts[4]; $ghAsset = $uParts[$uParts.Length - 1]
    echo                     $ghApiUri = [System.Uri]^('https://api.github.com/repos/' + $ghOwner + '/' + $ghRepo + '/releases/tags/' + $ghTag^)
    echo                     if ^(Test-TrustedJvmUri $ghApiUri^) {
    echo                         $ghReq = [System.Net.WebRequest]::Create^($ghApiUri^)
    echo                         $ghReq.UserAgent = 'DiamTek-JVM'
    echo                         $ghReq.Timeout = 8000
    echo                         if ^($env:GITHUB_TOKEN^) { $ghReq.Headers['Authorization'] = 'token ' + $env:GITHUB_TOKEN }
    echo                         $ghResp = $ghReq.GetResponse^(^)
    echo                         try {
    echo                             $ghSr = New-Object System.IO.StreamReader^($ghResp.GetResponseStream^(^)^)
    echo                             try { $ghJson = $ghSr.ReadToEnd^(^) ^| ConvertFrom-Json } finally { $ghSr.Close^(^); $ghSr.Dispose^(^) }
    echo                             if ^($ghJson -and $ghJson.assets^) {
    echo                                 $mAst = $ghJson.assets ^| Where-Object { $_.name -eq $ghAsset } ^| Select-Object -First 1
    echo                                 $dStr = [string]$mAst.digest
    echo                                 if ^($dStr -and $dStr.Contains^(':'^)^) {
    echo                                     $dParts = $dStr.Split^(':'^)
    echo                                     if ^($dParts.Length -eq 2 -and $dParts[1] -match '^^[0-9a-fA-F]{64,128}$'^) {
    echo                                         $expectedHash = $dParts[1]
    echo                                         $cryptoType = 'SHA256'
    echo                                     }
    echo                                 }
    echo                             }
    echo                         } finally { $ghResp.Close^(^) }
    echo                     }
    echo                 }
    echo             } catch { }
    echo         }
    echo         if ^($cryptoType -eq 'SHA256' -and $expectedHash -notmatch '^^[0-9a-fA-F]{64}$'^) { $expectedHash = $null }
    echo         if ^($cryptoType -eq 'SHA512' -and $expectedHash -notmatch '^^[0-9a-fA-F]{128}$'^) { $expectedHash = $null }
    echo         if ^($cryptoType -eq 'SHA1' -and $expectedHash -notmatch '^^[0-9a-fA-F]{40}$'^) { $expectedHash = $null }
    echo         if ^($cryptoType -eq 'MD5' -and $expectedHash -notmatch '^^[0-9a-fA-F]{32}$'^) { $expectedHash = $null }
    echo         if ^([string]::IsNullOrWhiteSpace^($expectedHash^)^) {
    echo             Write-Host '[ WARNING] Integrity verification unavailable or failed to fetch.' -ForegroundColor Yellow
    echo             $allowUnverified = ^($env:SKIP_CHECKSUM -eq '1'^)
    echo             if ^(-not $allowUnverified -and ^($env:IS_INTERACTIVE_UI -eq '1'^)^) {
    echo                 Write-Host ""
    echo                 $choice = Read-Host 'Do you want to continue installation without checksum verification? ^(y/N^)'
    echo                 if ^($choice -and ^($choice.Trim^(^) -eq 'y' -or $choice.Trim^(^) -eq 'Y'^)^) {
    echo                     $allowUnverified = $true
    echo                 }
    echo             }
    echo             if ^(-not $allowUnverified^) {
    echo                 Write-Host '[ ERROR  ] Aborting due to security policy. Rerun with --skip-checksum to bypass verification.' -ForegroundColor Red
    echo                 if ^(Test-Path $out^) { Remove-Item $out -Force -ErrorAction SilentlyContinue }
    echo                 exit 1
    echo             }
    echo             Write-Host '[ WARNING] Proceeding WITHOUT integrity verification ^(--skip-checksum active^).' -ForegroundColor Yellow
    echo             Write-Host ""
    echo         } else {
    echo             $crypto = [System.Security.Cryptography.HashAlgorithm]::Create^($cryptoType^)
    echo             if ^(-not $crypto^) {
    echo                 if ^($cryptoType -eq 'MD5'^) { $crypto = [System.Security.Cryptography.MD5]::Create^(^) } else { $crypto = [System.Security.Cryptography.SHA256]::Create^(^) }
    echo             }
    echo             $fs2 = [System.IO.File]::OpenRead^($out^)
    echo             $hashBytes = try { $crypto.ComputeHash^($fs2^) } finally { $fs2.Close^(^); $fs2.Dispose^(^) }
    echo             $actualHash = [System.BitConverter]::ToString^($hashBytes^).Replace^('-', ''^).ToLower^(^)
    echo             if ^($actualHash -ne $expectedHash.ToLower^(^)^) {
    echo                 Write-Host '[ ERROR  ] Checksum mismatch. Download corrupted or compromised.' -ForegroundColor Red
    echo                 Write-Host "           Expected: $expectedHash" -ForegroundColor Red
    echo                 Write-Host "           Actual:   $actualHash" -ForegroundColor Red
    echo                 if ^(Test-Path $out^) { Remove-Item $out -Force -ErrorAction SilentlyContinue }
    echo                 exit 1
    echo             }
    echo             Write-Host '[   OK   ] Checksum verified successfully.' -ForegroundColor Green
    echo             Write-Host ""
    echo         }
    echo     }
    echo     if ^($env:DL_EXTRACT^) {
    echo         Write-Host '[ ACTION ] Extracting archive...' -ForegroundColor Cyan
    echo         Add-Type -AssemblyName System.IO.Compression.FileSystem
    echo         $zip = [System.IO.Compression.ZipFile]::OpenRead^($out^)
    echo         try {
    echo             $entries = $zip.Entries
    echo             $totalEntries = $entries.Count
    echo             if ^($totalEntries -le 0 -or $totalEntries -gt 40000^) {
    echo                 throw ^('Security policy violation ^(CWE-409^): Archive entry count out of safe bounds: ' + $totalEntries^)
    echo             }
    echo             $maxTotalBytes = 1879048192L
    echo             $totalExtractedBytes = 0L
    echo             $extracted = 0
    echo             $lastPercent = -1
    echo             $fullRoot = [System.IO.Path]::GetFullPath^($env:DL_EXTRACT^)
    echo             if ^(-not $fullRoot.EndsWith^([System.IO.Path]::DirectorySeparatorChar.ToString^(^)^)^) {
    echo                 $fullRoot += [System.IO.Path]::DirectorySeparatorChar
    echo             }
    echo             foreach ^($entry in $entries^) {
    echo                 if ^(^($entry.ExternalAttributes -shr 16^) -band 0xF000 -eq 0xA000^) {
    echo                     throw ^('Security policy violation ^(CWE-59^): Symbolic link entry detected in archive: ' + $entry.FullName^)
    echo                 }
    echo                 $destinationPath = [System.IO.Path]::GetFullPath^([System.IO.Path]::Combine^($env:DL_EXTRACT, $entry.FullName^)^)
    echo                 if ^($entry.FullName -match '^^[/\\]' -or $entry.FullName -match ':' -or ^(-not $destinationPath.StartsWith^($fullRoot, [System.StringComparison]::OrdinalIgnoreCase^) -and $destinationPath -ne $fullRoot.TrimEnd^([System.IO.Path]::DirectorySeparatorChar^)^)^) {
    echo                     throw ^('Blocked path traversal in archive entry: ' + $entry.FullName^)
    echo                 }
    echo                 if ^($entry.FullName -match '[\x00-\x1F]' -or $entry.FullName -match '^(^^^|[/\\]^)^(CON^|PRN^|AUX^|NUL^|COM[1-9]^|LPT[1-9]^)^(\.[0-9A-Za-z._-]*^)?^([/\\]^|$^)' -or $entry.FullName -match '[\. ]^([/\\]^|$^)'^) {
    echo                     throw ^('Security policy violation ^(CWE-66^): Unsafe Win32 device or control char in archive entry: ' + $entry.FullName^)
    echo                 }
    echo                 $parentDir = [System.IO.Path]::GetDirectoryName^($destinationPath^)
    echo                 if ^([System.IO.Directory]::Exists^($parentDir^)^) {
    echo                     $pItem = Get-Item -LiteralPath $parentDir -Force
    echo                     if ^(^($pItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint^) -eq [System.IO.FileAttributes]::ReparsePoint^) {
    echo                         throw ^('Security policy violation ^(CWE-59^): Reparse point parent directory detected: ' + $parentDir^)
    echo                     }
    echo                 }
    echo                 $totalExtractedBytes += [math]::Max^(0L, [int64]$entry.Length^)
    echo                 if ^($totalExtractedBytes -gt $maxTotalBytes^) {
    echo                     throw ^('Security policy violation ^(CWE-409^): Archive decompression limit exceeded ^(Zip Bomb protection^).'^)
    echo                 }
    echo                 if ^([string]::IsNullOrEmpty^($entry.Name^)^) {
    echo                     [System.IO.Directory]::CreateDirectory^($destinationPath^) ^| Out-Null
    echo                 } else {
    echo                     [System.IO.Directory]::CreateDirectory^([System.IO.Path]::GetDirectoryName^($destinationPath^)^) ^| Out-Null
    echo                     [System.IO.Compression.ZipFileExtensions]::ExtractToFile^($entry, $destinationPath, $true^)
    echo                 }
    echo                 $extracted++
    echo                 $percent = [math]::Round^(^($extracted / $totalEntries^) * 100^)
    echo                 if ^($percent -ne $lastPercent^) {
    echo                     $bar = '[' + ^('=' * [math]::Floor^($percent / 2^)^) + ^(' ' * ^(50 - [math]::Floor^($percent / 2^)^)^) + ']'
    echo                     Write-Host "`r[ ACTION ] Extracting: $bar $percent%% ($extracted / $totalEntries) " -NoNewline -ForegroundColor Cyan
    echo                     $lastPercent = $percent
    echo                 }
    echo             }
    echo             Write-Host "`r[ ACTION ] Extracting: [==================================================] 100%% ($totalEntries / $totalEntries) " -NoNewline -ForegroundColor Cyan
    echo         } finally {
    echo             if ^($zip^) { $zip.Dispose^(^) }
    echo         }
    echo         $badReparse = Get-ChildItem -LiteralPath $env:DL_EXTRACT -Recurse -Force ^| Where-Object { ^($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint^) -eq [System.IO.FileAttributes]::ReparsePoint }
    echo         if ^($badReparse^) {
    echo             throw 'Security policy violation ^(CWE-59^): Reparse point detected inside extracted archive'
    echo         }
    echo         Write-Host "`n"
    echo         Remove-Item -LiteralPath $out -Force
    echo         if ^($env:DL_STRIP_ROOT -eq '1'^) {
    echo             $items = @^(Get-ChildItem -LiteralPath $env:DL_EXTRACT -Force^)
    echo             if ^($items.Count -eq 1 -and $items[0].PSIsContainer^) {
    echo                 if ^($items[0].Name -notmatch '^^[a-zA-Z0-9._+-]+$' -or $items[0].Name.StartsWith^('-'^)^) {
    echo                     throw ^('Security validation failed: Unsafe root directory name in archive: ' + $items[0].Name^)
    echo                 }
    echo                 Get-ChildItem -LiteralPath $items[0].FullName -Force ^| ForEach-Object { Move-Item -LiteralPath $_.FullName -Destination $env:DL_EXTRACT -Force }
    echo                 Remove-Item -LiteralPath $items[0].FullName -Recurse -Force
    echo             }
    echo         }
    echo     }
    echo } catch {
    echo     Write-Host "[ ERROR  ] Failed to download or extract." -ForegroundColor Red
    echo     $errMsg = ^($_.Exception.Message -replace '[\r\n]+', ' '^)
    echo     if ^($env:LOCALAPPDATA^) { $errMsg = $errMsg.Replace^($env:LOCALAPPDATA, '%%LOCALAPPDATA%%'^) }
    echo     if ^($env:USERPROFILE^) { $errMsg = $errMsg.Replace^($env:USERPROFILE, '%%USERPROFILE%%'^) }
    echo     Write-Host ^('[ DETAIL ] ' + $errMsg^) -ForegroundColor Yellow
    echo     if ^(Test-Path -LiteralPath $out^) { Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue }
    echo     if ^($env:DL_EXTRACT -and ^(Test-Path -LiteralPath $env:DL_EXTRACT^)^) {
    echo         Get-ChildItem -LiteralPath $env:DL_EXTRACT -Recurse -Force -ErrorAction SilentlyContinue ^| Where-Object { ^($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint^) -eq [System.IO.FileAttributes]::ReparsePoint } ^| ForEach-Object { if ^($_.PSIsContainer^) { [System.IO.Directory]::Delete^($_.FullName^) } else { [System.IO.File]::Delete^($_.FullName^) } }
    echo         Remove-Item -LiteralPath $env:DL_EXTRACT -Recurse -Force -ErrorAction SilentlyContinue
    echo     }
    echo     exit 1
    echo }
) > "!PS_SCRIPT!"

"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!"
set PS_EXIT_CODE=!errorlevel!
if exist "!PS_SCRIPT!" del "!PS_SCRIPT!" >nul 2>&1
exit /b !PS_EXIT_CODE!

:BackupRegistry
set "JVM_BACKUP_DIR=%LOCALAPPDATA%\DiamTek\JVM\backups"
"%FSUTIL_BIN%" reparsepoint query "%JVM_BACKUP_DIR%" >nul 2>&1
if not errorlevel 1 (
    rmdir "%JVM_BACKUP_DIR%" >nul 2>&1
)
if not exist "%JVM_BACKUP_DIR%" mkdir "%JVM_BACKUP_DIR%" >nul 2>&1
if not exist "%JVM_BACKUP_DIR%" (
    echo %cYELLOW%[ WARN   ]%cRESET% Could not create registry backup directory.
    exit /b 1
)
"%FSUTIL_BIN%" reparsepoint query "%JVM_BACKUP_DIR%" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation ^(CWE-59^): Registry backup directory is a reparse point.
    exit /b 1
)
"%ICACLS_BIN%" "%JVM_BACKUP_DIR%" /inheritance:r /grant:r "*S-1-5-18:(OI)(CI)F" "*S-1-5-32-544:(OI)(CI)F" "%USERNAME%:(OI)(CI)F" >nul 2>&1
if errorlevel 1 (
    echo %cYELLOW%[ WARN   ]%cRESET% Failed to set strict ACLs on registry backup directory.
    exit /b 1
)
set "BAK_DATE=%DATE:/=-%"
set "BAK_DATE=!BAK_DATE:\=-!"
set "BAK_DATE=!BAK_DATE: =_!"
set "BAK_TIME=%TIME::=-%"
set "BAK_TIME=!BAK_TIME: =0!"
set "BAK_TIME=!BAK_TIME:~0,6!"
"%REG_BIN%" export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "%JVM_BACKUP_DIR%\sys_env_!BAK_DATE!_!BAK_TIME!.reg" /y >nul 2>&1
"%REG_BIN%" export "HKCU\Environment" "%JVM_BACKUP_DIR%\usr_env_!BAK_DATE!_!BAK_TIME!.reg" /y >nul 2>&1
if errorlevel 1 (
    echo %cYELLOW%[ WARN   ]%cRESET% Failed to export HKCU registry backup.
    exit /b 1
)
if not exist "%JVM_BACKUP_DIR%\usr_env_!BAK_DATE!_!BAK_TIME!.reg" (
    echo %cYELLOW%[ WARN   ]%cRESET% HKCU registry backup file was not created.
    exit /b 1
)
exit /b 0

:RejectExclamationArg
if "%~1"=="" exit /b 0
set "_REA_VAL=%~1"
if "%_REA_VAL:~0,1%"=="!" exit /b 1
if "%_REA_VAL:~-1%"=="!" exit /b 1
for /f "tokens=1* delims=!" %%a in ("%_REA_VAL%") do (
    if not "%%b"=="" exit /b 1
)
shift
goto :RejectExclamationArg

:EnsureSecureTemp
"%FSUTIL_BIN%" reparsepoint query "%JVM_SECURE_TEMP%" >nul 2>&1
if not errorlevel 1 (
    rmdir "%JVM_SECURE_TEMP%" >nul 2>&1
)
if not exist "%JVM_SECURE_TEMP%" (
    mkdir "%JVM_SECURE_TEMP%" >nul 2>&1
)

if not exist "%JVM_SECURE_TEMP%" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to create secure temporary directory.
    exit /b 1
)

"%FSUTIL_BIN%" reparsepoint query "%JVM_SECURE_TEMP%" >nul 2>&1
if not errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Security violation: %JVM_SECURE_TEMP% is a reparse point.
    exit /b 1
)

"%ICACLS_BIN%" "%JVM_SECURE_TEMP%" /inheritance:r /grant:r "*S-1-5-18:(OI)(CI)F" "*S-1-5-32-544:(OI)(CI)F" "%USERNAME%:(OI)(CI)F" >nul 2>&1
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to secure permissions on secure temp.
    exit /b 1
)

exit /b 0

:AcquireStateLock
if "%JVM_NO_LOCK%"=="1" exit /b 0
if "%SESSION_MODE%"=="1" exit /b 0
if defined JVM_LOCK_DEPTH (
    if !JVM_LOCK_DEPTH! GTR 0 (
        set /a JVM_LOCK_DEPTH+=1
        exit /b 0
    )
)
set "JVM_LOCK_DIR=%LOCALAPPDATA%\DiamTek\JVM\state.lock"
set "JVM_LOCK_ATTEMPTS=0"
if not defined JVM_CALLER_PID (
    for /f "delims=" %%P in ('"%PS_BIN%" -NoProfile -Command "$PID" 2^>nul') do set "JVM_CALLER_PID=%%P"
)
if not defined JVM_CALLER_PID (
    for /f "tokens=2 delims==" %%P in ('wmic process where "ProcessId=%PID%" get ParentProcessId /value 2^>nul ^| %FINDSTR_BIN% "="') do set "JVM_CALLER_PID=%%P"
)
if not defined JVM_CALLER_PID (
    set "JVM_CALLER_PID=%RANDOM%"
)
:LOCK_RETRY_LOOP
mkdir "%JVM_LOCK_DIR%" >nul 2>&1
if not errorlevel 1 (
    (echo !JVM_CALLER_PID!^|%DATE%_%TIME%)>"%JVM_LOCK_DIR%\owner.pid" 2>nul
    if errorlevel 1 (
        rmdir "%JVM_LOCK_DIR%" >nul 2>&1
        echo %cRED%[ ERROR  ]%cRESET% Failed to initialize JVM state lock.
        exit /b 1
    )
    if not exist "%JVM_LOCK_DIR%\owner.pid" (
        rmdir "%JVM_LOCK_DIR%" >nul 2>&1
        echo %cRED%[ ERROR  ]%cRESET% Failed to initialize JVM state lock.
        exit /b 1
    )
    set "JVM_LOCK_ACQUIRED=1"
    set "JVM_LOCK_DEPTH=1"
    exit /b 0
)
rem Stale lock auto-recovery without delete/re-mkdir race:
rem Verify owner PID is dead or invalid, stage takeover PID, and atomically replace owner.pid
if exist "%JVM_LOCK_DIR%\owner.pid" (
    set "LOCK_OWNER_PID="
    for /f "tokens=1 delims=|" %%P in ('type "%JVM_LOCK_DIR%\owner.pid" 2^>nul') do set "LOCK_OWNER_PID=%%P"
    set "OWNER_DEAD=0"
    if not defined LOCK_OWNER_PID (
        set "OWNER_DEAD=1"
    ) else (
        if "!LOCK_OWNER_PID!"=="!JVM_CALLER_PID!" (
            set "JVM_LOCK_ACQUIRED=1"
            set /a JVM_LOCK_DEPTH+=1
            exit /b 0
        )
        set "LOCK_PID_NUM=1"
        for /f "delims=0123456789" %%A in ("!LOCK_OWNER_PID!") do set "LOCK_PID_NUM=0"
        if "!LOCK_PID_NUM!"=="1" (
            set "PID_ALIVE=0"
            for /f "tokens=2 delims=," %%Q in ('"%TASKLIST_BIN%" /FI "PID eq !LOCK_OWNER_PID!" /FO CSV /NH 2^>nul') do (
                set "FOUND_PID=%%~Q"
                if "!FOUND_PID!"=="!LOCK_OWNER_PID!" set "PID_ALIVE=1"
            )
            if "!PID_ALIVE!"=="0" set "OWNER_DEAD=1"
        ) else (
            set "OWNER_DEAD=1"
        )
    )
    if "!OWNER_DEAD!"=="1" (
        set "LOCK_TAKEOVER=%JVM_LOCK_DIR%\takeover_!JVM_CALLER_PID!.tmp"
        (echo !JVM_CALLER_PID!^|%DATE%_%TIME%)>"!LOCK_TAKEOVER!" 2>nul
        move /y "!LOCK_TAKEOVER!" "%JVM_LOCK_DIR%\owner.pid" >nul 2>&1
        if not errorlevel 1 (
            set "VERIFY_CLAIM="
            for /f "tokens=1 delims=|" %%V in ('type "%JVM_LOCK_DIR%\owner.pid" 2^>nul') do set "VERIFY_CLAIM=%%V"
            if "!VERIFY_CLAIM!"=="!JVM_CALLER_PID!" (
                set "JVM_LOCK_ACQUIRED=1"
                set "JVM_LOCK_DEPTH=1"
                exit /b 0
            )
        )
        if exist "!LOCK_TAKEOVER!" del /f /q "!LOCK_TAKEOVER!" >nul 2>&1
    )
)
set /a JVM_LOCK_ATTEMPTS+=1
if !JVM_LOCK_ATTEMPTS! GEQ 15 (
    echo %cYELLOW%[  WARN  ]%cRESET% Another JVM operation is currently modifying state.
    echo            Waiting for state lock release ^(Local\DiamTek-JVM-State^)...
)
if !JVM_LOCK_ATTEMPTS! GEQ 30 (
    echo %cRED%[ ERROR  ]%cRESET% Concurrency timeout ^(CWE-362^): Could not acquire state lock after 30 seconds.
    echo           Pass --no-lock to override ^(UNSAFE: disables mutual exclusion during concurrent operations^).
    exit /b 1
)
"%TIMEOUT_BIN%" /t 1 /nobreak >nul 2>&1
goto :LOCK_RETRY_LOOP

:ReleaseStateLock
if "%JVM_NO_LOCK%"=="1" exit /b 0
if not "!JVM_LOCK_ACQUIRED!"=="1" exit /b 0
if defined JVM_LOCK_DEPTH (
    if !JVM_LOCK_DEPTH! GTR 1 (
        set /a JVM_LOCK_DEPTH-=1
        exit /b 0
    )
)
set "JVM_LOCK_DEPTH=0"
set "JVM_LOCK_DIR=%LOCALAPPDATA%\DiamTek\JVM\state.lock"
if exist "%JVM_LOCK_DIR%\owner.pid" (
    set "CURR_LOCK_PID="
    for /f "tokens=1 delims=|" %%P in ('type "%JVM_LOCK_DIR%\owner.pid" 2^>nul') do set "CURR_LOCK_PID=%%P"
    if defined CURR_LOCK_PID if defined JVM_CALLER_PID (
        if "!CURR_LOCK_PID!" NEQ "!JVM_CALLER_PID!" exit /b 0
    )
    del /f /q "%JVM_LOCK_DIR%\owner.pid" >nul 2>&1
)
if exist "%JVM_LOCK_DIR%" rmdir "%JVM_LOCK_DIR%" >nul 2>&1
set "JVM_LOCK_ACQUIRED=0"
exit /b 0

:RequireNetwork
if "%JVM_OFFLINE%"=="1" (
    echo %cRED%[ ERROR  ]%cRESET% Operation requires network access, but --offline mode is active.
    exit /b 1
)
exit /b 0

:VerifyDownloadedScript
call :RequireNetwork
if errorlevel 1 exit /b 1
set "VERIFY_FILE=%~1"
set "VERIFY_REF=%~2"
set "VERIFY_NAME=%~3"

if not exist "%VERIFY_FILE%" exit /b 1

for /f "delims=" %%A in ('%PS_BIN% -NoProfile -Command "[System.IO.Path]::GetRandomFileName().Replace('.', '')"') do set "VER_RANDOM_NAME=%%A"
set "VERIFY_RESULT=%JVM_SECURE_TEMP%\verify_!VER_RANDOM_NAME!.txt"

"%PS_BIN%" -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288 } catch { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 };" ^
    "$f=$env:VERIFY_FILE;" ^
    "$ref=$env:VERIFY_REF;" ^
    "$name=$env:VERIFY_NAME;" ^
    "if (-not (Test-Path -LiteralPath $f)) { Write-Output 'MISSING'; exit };" ^
    "if ($ref -notmatch '^[a-zA-Z0-9._-]+$' -or $ref -match '\.\.') { Write-Output 'INVALID_REF'; exit };" ^
    "$s=[System.Security.Cryptography.SHA256]::Create();" ^
    "$fs=[System.IO.File]::OpenRead($f);" ^
    "$actual=try { ([System.BitConverter]::ToString($s.ComputeHash($fs)) -replace '-','').ToLower() } finally { $fs.Close(); $s.Dispose() };" ^
    "if ($ref -match '^v?[0-9]') {" ^
    "  $txt=$null; $res=$null; $sr=$null;" ^
    "  try { $req=[System.Net.WebRequest]::Create('https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/' + $ref + '/SHA256SUMS.txt'); $req.Timeout=5000; $res=$req.GetResponse(); $rHost=$res.ResponseUri.Host.ToLowerInvariant(); if ($res.ResponseUri.Scheme -ne 'https' -or (@('github.com','objects.githubusercontent.com','release-assets.githubusercontent.com','raw.githubusercontent.com') -notcontains $rHost -and -not $rHost.EndsWith('.githubusercontent.com'))) { Write-Output 'UNTRUSTED_REDIRECT'; exit }; $sr=New-Object System.IO.StreamReader($res.GetResponseStream(), [System.Text.Encoding]::UTF8); $txt=$sr.ReadToEnd() } catch {} finally { if ($sr) { $sr.Close(); $sr.Dispose() }; if ($res) { $res.Close() } };" ^
    "  if (-not $txt) { Write-Output 'NO_SHA_FILE'; exit };" ^
    "  $expected=$null;" ^
    "  foreach ($line in ($txt -split '\r?\n')) {" ^
    "    if ($line.Trim() -match ('^([0-9a-fA-F]{64})\s+\*?' + [regex]::Escape($name) + '$')) {" ^
    "      $expected=$matches[1].ToLower(); break" ^
    "    }" ^
    "  };" ^
    "  if (-not $expected) { Write-Output 'NO_ENTRY'; exit };" ^
    "  if ($actual -ne $expected) { Write-Output ('MISMATCH|' + $expected + '|' + $actual); exit };" ^
    "  Write-Output ('VERIFIED|' + $expected)" ^
    "} else {" ^
    "  $metaSha=$null;" ^
    "  try { $meta=Invoke-RestMethod -Uri ('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/contents/' + $name + '?ref=' + $ref) -Headers @{'Cache-Control'='no-cache'} -UserAgent 'DiamTek-JVM' -TimeoutSec 5; if ($meta -and $meta.sha -and $meta.sha -match '^[0-9a-fA-F]{40}$') { $metaSha=([string]$meta.sha).ToLower() } } catch {};" ^
    "  if ($metaSha) {" ^
    "    $sha1=[System.Security.Cryptography.SHA1]::Create();" ^
    "    $matchedGit=$false; $computedGit='';" ^
    "    try {" ^
    "      $rawBytes=[System.IO.File]::ReadAllBytes($f);" ^
    "      $rawTxt=[System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8);" ^
    "      $lfBytes=[System.Text.Encoding]::UTF8.GetBytes(($rawTxt -replace '\r\n', \"`n\"));" ^
    "      $crlfBytes=[System.Text.Encoding]::UTF8.GetBytes(($rawTxt -replace '\r?\n', \"`r`n\"));" ^
    "      foreach ($b in @($rawBytes, $lfBytes, $crlfBytes)) {" ^
    "        $hdr=[System.Text.Encoding]::ASCII.GetBytes('blob ' + $b.Length + [char]0);" ^
    "        $blob=New-Object byte[] ($hdr.Length + $b.Length);" ^
    "        [Array]::Copy($hdr, 0, $blob, 0, $hdr.Length);" ^
    "        [Array]::Copy($b, 0, $blob, $hdr.Length, $b.Length);" ^
    "        $g=([System.BitConverter]::ToString($sha1.ComputeHash($blob)) -replace '-','').ToLower();" ^
    "        if (-not $computedGit) { $computedGit=$g };" ^
    "        if ($g -eq $metaSha) { $matchedGit=$true; break }" ^
    "      }" ^
    "    } finally { if ($sha1) { $sha1.Dispose() } };" ^
    "    if ($matchedGit) { Write-Output ('VERIFIED|' + $actual); exit }" ^
    "    Write-Output ('MISMATCH|' + $metaSha + '|' + $computedGit); exit" ^
    "  };" ^
    "  $sidecar=$f + '.sha256';" ^
    "  if (Test-Path -LiteralPath $sidecar) {" ^
    "    $scItem=Get-Item -LiteralPath $sidecar -Force -ErrorAction SilentlyContinue;" ^
    "    if ($scItem -and -not ($scItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {" ^
    "      $pinned=([System.IO.File]::ReadAllText($sidecar, [System.Text.Encoding]::UTF8)).Trim().ToLower();" ^
    "      if ($pinned -match '^[0-9a-fA-F]{64}$') {" ^
    "        if ($actual -eq $pinned) { Write-Output ('VERIFIED|' + $actual); exit } else { Write-Output ('MISMATCH|' + $pinned + '|' + $actual); exit }" ^
    "      }" ^
    "    }" ^
    "  };" ^
    "  Write-Output 'NO_META_SHA'" ^
    "}" ^
    > "%VERIFY_RESULT%" 2>nul

set "VERIFY_STATUS="
set "VERIFY_EXPECTED="
set "VERIFY_ACTUAL="

if exist "%VERIFY_RESULT%" (
    for /f "usebackq tokens=1,2,3 delims=|" %%A in ("%VERIFY_RESULT%") do (
        set "VERIFY_STATUS=%%A"
        set "VERIFY_EXPECTED=%%B"
        set "VERIFY_ACTUAL=%%C"
    )
    del "%VERIFY_RESULT%" >nul 2>&1
)

if /i not "!VERIFY_STATUS!"=="VERIFIED" exit /b 1
exit /b 0

rem END OF SCRIPT