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

set "ORIG_CP="
for /f "tokens=* delims=:" %%C in ('chcp') do for %%D in (%%C) do set "ORIG_CP=%%D"

set "INVOCATION_DIR=%cd%"

rem Cleanup self-updater artifacts if they exist
if exist "%TEMP%\jvm_updater_*.bat" del "%TEMP%\jvm_updater_*.bat" >nul 2>&1
if exist "%TEMP%\jvm_install_*.ps1" del "%TEMP%\jvm_install_*.ps1" >nul 2>&1
if exist "%TEMP%\jvm_updater.bat" del "%TEMP%\jvm_updater.bat" >nul 2>&1
if exist "%TEMP%\jvm_uninstall_*.bat" del "%TEMP%\jvm_uninstall_*.bat" >nul 2>&1
if exist "%TEMP%\jvm_uninstall_*.ps1" del "%TEMP%\jvm_uninstall_*.ps1" >nul 2>&1

set "JVM_VERSION=1.0.0"
set "JVM_BUILD=20260915.103"

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
set "LOCATIONS[0]=C:\Program Files\Java"
set "LOCATIONS[1]=C:\Program Files (x86)\Java"
set "LOCATIONS[2]=C:\Java"
set "LOCATIONS[3]=%USERPROFILE%\.jdks"
set "LOCATIONS[4]=%USERPROFILE%\.gradle\jdks"
set "LOCATIONS[5]=%LOCALAPPDATA%\JavaVersionManager\links"
set "LOCATIONS[6]=C:\Program Files\Eclipse Adoptium"
set "LOCATIONS[7]=C:\Program Files\Amazon Corretto"
set "LOCATIONS[8]=C:\Program Files\Zulu"
set "LOCATIONS[9]=C:\Program Files\BellSoft"
set "LOCATIONS[10]=C:\Program Files\Semeru"
set "LOCATIONS[11]=C:\Program Files\Microsoft"

setlocal enabledelayedexpansion
set "LOC_IDX=12"
if exist "!USERPROFILE!\scoop\apps" (
    for /d %%A in ("!USERPROFILE!\scoop\apps\*") do (
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
set "ORIGINAL_ARGS=%*"
set "SCRIPT_PATH=%~f0"
set "SCRIPT_DIR=%~dp0"
if "!SCRIPT_DIR:~-1!"=="\" set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"

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

if /i "%~1"=="link" (
    call :HANDLE_LINKS %*
    exit /b %errorlevel%
)
set "IS_ADMIN_RUN=0"
if /i "%~1"=="--admin-run" goto PARSE_ADMIN_RUN
goto SKIP_ADMIN_RUN
:PARSE_ADMIN_RUN
set "IS_ADMIN_RUN=1"
shift
:SKIP_ADMIN_RUN

if /i "%~1"=="unlink" (
    call :HANDLE_LINKS %*
    exit /b %errorlevel%
)
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
if /i "%~1"=="--vendor" (
    set "CLI_VENDOR=%~2"
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
    shift
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--nightly" (
    set "UPDATE_CHANNEL=NIGHTLY"
    shift
    goto :PARSE_CLI_ARGS
)
if /i "%~1"=="--stable" (
    set "UPDATE_CHANNEL=STABLE"
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
        if defined ORIG_CP chcp !ORIG_CP! >nul
        exit /b 0
    ) else (
        echo.
        echo %cYELLOW%[ WARNING]%cRESET% No .java-version file exists in this directory.
        echo             Usage: jvm pin ^<version^> [flags]
        echo             Example: jvm pin 21
        if defined ORIG_CP chcp !ORIG_CP! >nul
        exit /b 1
    )
)

set "PIN_CONTENT="
:COLLECT_PIN_LOOP
if "%~1"=="" goto :DO_PIN_WRITE
if not defined PIN_CONTENT (
    set "PIN_CONTENT=%~1"
) else (
    set "PIN_CONTENT=!PIN_CONTENT! %~1"
)
shift
goto :COLLECT_PIN_LOOP

:DO_PIN_WRITE
>"%INVOCATION_DIR%\.java-version" echo !PIN_CONTENT!
echo.
echo %cGREEN%[   OK   ]%cRESET% Successfully pinned Java version '!PIN_CONTENT!' to:
echo            %INVOCATION_DIR%\.java-version
if defined ORIG_CP chcp !ORIG_CP! >nul
exit /b 0

:PARSE_EXEC_ARGS
set "EXEC_TARGET=%~1"
if not defined EXEC_TARGET (
    echo.
    >&2 echo %cRED%[ ERROR  ]%cRESET% Missing target version for exec.
    >&2 echo            Usage: jvm exec ^<version^> [--] ^<command^> [args...]
    >&2 echo            Example: jvm exec 21 -- java -version
    if defined ORIG_CP chcp !ORIG_CP! >nul
    exit /b 1
)
shift
if "%~1"=="--" shift
if "%~1"=="" (
    echo.
    >&2 echo %cRED%[ ERROR  ]%cRESET% No command specified to execute.
    >&2 echo            Usage: jvm exec ^<version^> [--] ^<command^> [args...]
    >&2 echo            Example: jvm exec 21 -- java -version
    if defined ORIG_CP chcp !ORIG_CP! >nul
    exit /b 1
)

set "EXEC_CMD="
:COLLECT_EXEC_LOOP
if "%~1"=="" goto :DO_EXEC_RUN
if not defined EXEC_CMD (
    set "EXEC_CMD=%1"
) else (
    set "EXEC_CMD=!EXEC_CMD! %1"
)
shift
goto :COLLECT_EXEC_LOOP

:DO_EXEC_RUN
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
if "%WANT_UTF8%"=="1" chcp 65001 >nul
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
    if /i "%CLI_COMMAND%"=="list" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="env" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="current" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="status" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="clean" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="which" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="doctor" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="open" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="exec" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="hook" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="channel" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="update" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="self-update" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="self-uninstall" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="version" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="help" (
        call :ShowHelp
        if defined ORIG_CP chcp !ORIG_CP! >nul
        exit /b 0
    )
)
if defined CLI_TARGET (
    set "SKIP_HEADER=1"
) else if exist ".java-version" (
    for /f "delims=" %%L in ('type ".java-version" 2^>nul ^| findstr /r "[0-9]" ^| findstr /v "[&|<>]"') do (
        call :ParseJavaVersion %%L
        if not "!FORCE_GLOBAL!"=="1" set "SESSION_MODE=1"
        set "SILENT_MODE=1"
        set "SKIP_HEADER=1"
    )
) else if exist "%INVOCATION_DIR%\.sdkmanrc" (
    set "FOUND_SDKMANRC=1"
    for /f "tokens=1,2 delims==" %%A in ('type "%INVOCATION_DIR%\.sdkmanrc" 2^>nul ^| findstr /i "^java=" ^| findstr /v "[&|<>]"') do (
        call :ParseSdkmanrc %%B
    )
    if not "!FORCE_GLOBAL!"=="1" set "SESSION_MODE=1"
    set "SILENT_MODE=1"
    set "SKIP_HEADER=1"
    if not defined CLI_TARGET set "CLI_TARGET=SKIP_JAVA"
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

rem Jump straight to the menu function to prevent screen clearing issues
call :ShowDynamicMenu

rem If CURRENT_JDK_PATH is not set, the user chose the Exit option (unless purely doing ecosystem session switching)
if not defined CURRENT_JDK_PATH (
    if not "!FOUND_SDKMANRC!"=="1" (
        if defined ORIG_CP chcp !ORIG_CP! >nul
        if defined CMD_EXIT_CODE exit /B !CMD_EXIT_CODE!
        exit /B 0
    )
)

if "!CURRENT_JDK_PATH!"=="CLEAR" (
    call :ClearJavaEnvironment
    set "CURRENT_JDK_PATH="
    goto MAIN_LOOP
)

if "!SESSION_MODE!"=="1" (
    echo.
    if exist "%TEMP%\.jvm_session_target" del "%TEMP%\.jvm_session_target"
    if defined CURRENT_JDK_PATH (
        echo %cBLUE%[ ACTION ]%cRESET% Session mode active. Setting Java to !CURRENT_JDK_PATH!...
        >>"%TEMP%\.jvm_session_target" echo JAVA_HOME=!CURRENT_JDK_PATH!
        set "JAVA_HOME=!CURRENT_JDK_PATH!"
        set "PATH=!CURRENT_JDK_PATH!\bin;!PATH!"
    ) else (
        echo %cBLUE%[ ACTION ]%cRESET% Session mode active.
    )
    
    if "!FOUND_SDKMANRC!"=="1" (
        for /f "tokens=1,2 delims==" %%A in ('type "%INVOCATION_DIR%\.sdkmanrc" 2^>nul ^| findstr /i /v "^java=" ^| findstr /v "[&|<>]"') do (
            set "ECO_CAND=%%A"
            set "ECO_VER=%%B"
            call :ProcessEcosystemSession "!ECO_CAND!" "!ECO_VER!"
        )
    )
    
    echo %cGREEN%[   OK   ]%cRESET% Session target saved.
    goto :VERIFICATION
)

echo.
set "JVM_DIR=%LOCALAPPDATA%\DiamTek\JVM"
set "CURRENT_SYMLINK=%LOCALAPPDATA%\DiamTek\JVM\current"

if /i "%SWITCH_MODE%"=="DIRECT" (
    echo %cBLUE%[ ACTION ]%cRESET% Setting Java to %CURRENT_JDK_PATH%...
    echo %cBLUE%[  INFO  ]%cRESET% Setting JAVA_HOME to: %CURRENT_JDK_PATH%
    
    rem Output session target so the parent PowerShell window can sync immediately
    >"%TEMP%\.jvm_session_target" echo %CURRENT_JDK_PATH%
    
    rem Deferring registry update to UpdateSystemPath to do both in one UAC prompt
    set "SYMLINK_OR_DIRECT=%CURRENT_JDK_PATH%"
) else (
    if not exist "%JVM_DIR%" mkdir "%JVM_DIR%"
    
    echo %cBLUE%[ ACTION ]%cRESET% Updating Directory Junction: %JVM_DIR%\current...
    
    if exist "%CURRENT_SYMLINK%" rmdir "%CURRENT_SYMLINK%"
    mklink /J "%CURRENT_SYMLINK%" "%CURRENT_JDK_PATH%" >nul
    
    if exist "%CURRENT_SYMLINK%\bin\java.exe" (
        echo %cGREEN%[   OK   ]%cRESET% Junction successfully updated to point to %CURRENT_JDK_PATH%!
    ) else (
        echo %cRED%[ ERROR  ]%cRESET% Failed to update Junction.
        pause
        goto MAIN_LOOP
    )
    
    >"%TEMP%\.jvm_session_target" echo %CURRENT_SYMLINK%
    
    rem Ensure JAVA_HOME permanently points to the junction in the USER registry (bypasses UAC)
    set "REG_JAVA_HOME="
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v JAVA_HOME 2^>nul') do set "REG_JAVA_HOME=%%B"
    if /i not "!REG_JAVA_HOME!"=="%CURRENT_SYMLINK%" (
        echo.
        echo %cBLUE%[  INFO  ]%cRESET% Setting JAVA_HOME to: %CURRENT_SYMLINK%
        powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('JAVA_HOME', $env:CURRENT_SYMLINK, 'User')"
        if errorlevel 1 (
            echo %cRED%[ ERROR  ]%cRESET% Failed to set JAVA_HOME in registry
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


rem Clean the current session PATH dynamically to prevent duplicates
setlocal enabledelayedexpansion
set "CLEAN_PATH=!PATH!"

rem Use PowerShell to safely filter out old Java paths via exact string matching to prevent accidental substring pollution
    set "PS_CMD=$p = $env:PATH -split ';'; $r = @(); foreach ($d in $p) { if ($d -ne '' -and (-not $env:JAVA_HOME -or $d -ne ($env:JAVA_HOME + '\bin')) -and (-not $env:SYMLINK_OR_DIRECT -or $d -ne ($env:SYMLINK_OR_DIRECT + '\bin')) -and (-not $env:CURRENT_JDK_PATH -or $d -ne ($env:CURRENT_JDK_PATH + '\bin'))) { $r += $d } }; $r -join ';'"
    for /f "delims=" %%A in ('powershell -NoProfile -Command "!PS_CMD!"') do set "CLEAN_PATH=%%A"

rem Export the clean path back to the main session and apply at the front
for /f "delims=" %%A in (""!CLEAN_PATH!"") do (
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
for /f "delims=" %%A in ('java -version 2^>^&1') do echo %%A
echo.
java -version >nul 2>&1
if errorlevel 1 (
    echo %cBLUE%[  INFO  ]%cRESET% Java may not work until you restart command prompt.
) else (
    echo %cGREEN%[   OK   ]%cRESET% Java is working correctly.
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
    if defined ORIG_CP chcp !ORIG_CP! >nul
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
if exist "%LOCALAPPDATA%\DiamTek\JVM\mode.txt" (
    for /f "usebackq tokens=* delims= " %%A in ("%LOCALAPPDATA%\DiamTek\JVM\mode.txt") do set "SWITCH_MODE=%%A"
)
if /i not "!SWITCH_MODE!"=="DIRECT" set "SWITCH_MODE=SYMLINK"
set "JAVA_HOME="
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v JAVA_HOME 2^>nul') do set "JAVA_HOME=%%B"
if not defined JAVA_HOME (
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v JAVA_HOME 2^>nul') do set "JAVA_HOME=%%B"
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
    where java >nul 2>nul
    if errorlevel 1 (
        echo %cYELLOW%[ WARNING]%cRESET% Java is NOT in PATH or not installed
        echo %cBLUE%[  INFO  ]%cRESET% This is normal if Java was just removed from PATH
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% Java is in PATH
        echo.
        for /f "delims=" %%A in ('java -version 2^>^&1') do echo %%A
    )
    echo ============================================================
    echo.
)

rem Resolve the true underlying path of JAVA_HOME if it is currently using the symlink mode
set "RESOLVED_JAVA_HOME=!JAVA_HOME!"
if /i "!JAVA_HOME!"=="%LOCALAPPDATA%\DiamTek\JVM\current" (
    for /f "tokens=2 delims=[]" %%A in ('dir /al "%LOCALAPPDATA%\DiamTek\JVM" 2^>nul ^| findstr /i "current"') do (
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
                    
                    if "!SKIP!"=="0" (
                        set /a JDK_COUNT+=1
                        set "JDK_PATH_!JDK_COUNT!=!LOCATIONS[%%i]!\%%j"
                        
                        rem Parse version to find the latest
                        set "VER="
                        set "VENDOR_STR=Unknown"
                        if exist "%%j\release" (
                            for /f "tokens=2 delims==" %%R in ('findstr /b "JAVA_VERSION=" "%%j\release" 2^>nul') do (
                                set "VER_STR=%%~R"
                                for /f "tokens=1 delims=." %%V in ("!VER_STR!") do set "VER=%%V"
                            )
                            for /f "tokens=2 delims==" %%R in ('findstr /b "IMPLEMENTOR=" "%%j\release" 2^>nul') do (
                                set "VENDOR_RAW=%%~R"
                                set "VENDOR_RAW=!VENDOR_RAW:"=!"
                                echo !VENDOR_RAW! | find /i "Oracle" >nul && set "VENDOR_STR=Oracle"
                                echo !VENDOR_RAW! | find /i "Adoptium" >nul && set "VENDOR_STR=Adoptium"
                                echo !VENDOR_RAW! | find /i "GraalVM" >nul && set "VENDOR_STR=GraalVM"
                                echo !VENDOR_RAW! | find /i "Amazon" >nul && set "VENDOR_STR=Corretto"
                                echo !VENDOR_RAW! | find /i "Azul" >nul && set "VENDOR_STR=Zulu"
                                echo !VENDOR_RAW! | find /i "Microsoft" >nul && set "VENDOR_STR=Microsoft"
                                echo !VENDOR_RAW! | find /i "BellSoft" >nul && set "VENDOR_STR=Liberica"
                                echo !VENDOR_RAW! | find /i "Liberica" >nul && set "VENDOR_STR=Liberica"
                                echo !VENDOR_RAW! | find /i "IBM" >nul && set "VENDOR_STR=Semeru"
                                echo !VENDOR_RAW! | find /i "Semeru" >nul && set "VENDOR_STR=Semeru"
                            )
                        )
                        if not defined VER (
                            for /f "tokens=3" %%A in ('""%%j\bin\java.exe" -version 2^>^&1 ^| findstr /i "version""') do (
                                set "VER_STR=%%~A"
                                set "VER_STR=!VER_STR:"=!"
                            )
                        )
                        rem Handle legacy 1.x versioning (e.g., 1.8.0 -> 8)
                        set "NUM_VER=0"
                        if defined VER_STR (
                            for /f "tokens=1,2 delims=." %%V in ("!VER_STR!") do (
                                if "%%V"=="1" (
                                    set /a "NUM_VER=%%W" 2>nul
                                ) else (
                                    set /a "NUM_VER=%%V" 2>nul
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
    goto :eof
)

if defined CLI_COMMAND (
    if /i "!CLI_COMMAND!"=="list" (
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
        goto :eof
    )
    if /i "!CLI_COMMAND!"=="which" (
        call :WhichBinary
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :eof
    )
    if /i "!CLI_COMMAND!"=="doctor" (
        call :DoctorDiagnostics
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :eof
    )
    if /i "!CLI_COMMAND!"=="open" (
        call :OpenFolderInExplorer
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :eof
    )
    if /i "!CLI_COMMAND!"=="exec" (
        call :ExecuteEphemeralCommand
        set "CMD_EXIT_CODE=!errorlevel!"
        goto :eof
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
        goto :eof
    )
    if /i "!CLI_COMMAND!"=="install" (
        call :FetchLatestVersions
        if not defined CLI_TARGET (
            call :InstallWizard
            goto :CLI_DONE
        )
        if /i "!CLI_TARGET!"=="latest" (
            set "CLI_TARGET=!ORACLE_LATEST_FEATURE!"
        ) else if /i "!CLI_TARGET!"=="lts" (
            if defined FLAG_LATEST (
                set "CLI_TARGET=!ORACLE_LATEST_LTS!"
            ) else (
                call :PromptLtsVersion
                if not defined CLI_TARGET goto :CLI_DONE
            )
        )
        set "DL_VERSION=!CLI_TARGET!"
        call :DownloadJDK_Headless
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
                for %%T in (maven gradle kotlin scala groovy) do (
                    if exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\%%T\current" (
                        set "act_ver=none"
                        for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '%LOCALAPPDATA%\DiamTek\JVM\candidates\%%T\current' -ErrorAction SilentlyContinue).Target"') do for %%X in ("%%A") do set "act_ver=%%~nxX"
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
            ) else (
                call :ProcessSingleUpdate !TARGET_IDX!
            )
        )
        goto :CLI_DONE
    )
    
    if /i "!CLI_COMMAND!"=="uninstall" (
        if not defined CLI_TARGET (
            echo %cRED%[ ERROR  ]%cRESET% Missing required version argument.
            echo            Usage: jvm uninstall ^<version_number^>
            goto :CLI_DONE
        )
        if !MATCH_COUNT! GTR 1 (
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
            choice /C !U_KEYS! /N /M "Select vendor to uninstall (1-!RESOLVE_COUNT!): "
            if !errorlevel! EQU !RESOLVE_COUNT! goto :eof
            
            set "CHOICE_VAL=!errorlevel!"
            for %%C in (!CHOICE_VAL!) do set "TARGET_IDX=!RES_IDX_%%C!"
            echo.
        )

        if "!TARGET_IDX!"=="0" (
            echo %cRED%[ ERROR  ]%cRESET% JDK !CLI_TARGET! not found.
        ) else (
            for %%A in (!TARGET_IDX!) do (
                set "DEL_PATH=!JDK_PATH_%%A!"
                set "DEL_NAME=!JDK_NAME_%%A!"
            )
            
            if "!IS_ADMIN_RUN!"=="1" (
                powershell -NoProfile -Command "Get-Process java,javaw -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($env:DEL_PATH, [StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2^>^&1
                rmdir /s /q "!DEL_PATH!"
                if not exist "%LOCALAPPDATA%\DiamTek\JVM\current\bin\java.exe" (
                    if exist "%LOCALAPPDATA%\DiamTek\JVM\current" rmdir "%LOCALAPPDATA%\DiamTek\JVM\current"
                    reg delete "HKCU\Environment" /v JAVA_HOME /f >nul 2^>^&1
                )
                set "DEL_BIN=!DEL_PATH!\bin"
                powershell -NoProfile -Command "$p = [Environment]::GetEnvironmentVariable('Path', 'Machine'); if ($p) { $clean = ($p -split ';' | Where-Object { $_ -and $_ -ne $env:DEL_BIN }) -join ';'; [Environment]::SetEnvironmentVariable('Path', $clean, 'Machine') }"
                powershell -NoProfile -Command "$p = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($p) { $clean = ($p -split ';' | Where-Object { $_ -and $_ -ne $env:DEL_BIN }) -join ';'; [Environment]::SetEnvironmentVariable('Path', $clean, 'User') }"
                exit /b 0
            ) else (
                echo.
                echo %cBLUE%[ ACTION ]%cRESET% Terminating any active Java processes...
                echo %cBLUE%[ ACTION ]%cRESET% Deleting directory !DEL_PATH!...
                echo %cBLUE%[ ACTION ]%cRESET% Scrubbing environment variables...
                
                echo %cBLUE%[  INFO  ]%cRESET% Requesting administrative privileges to apply changes...
                set "WORK_DIR=%cd%"
                set "UAC_ARGS=%ORIGINAL_ARGS%"
                powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath \"$env:SCRIPT_PATH\" -WorkingDirectory \"$env:WORK_DIR\" -ArgumentList \"--admin-run $env:UAC_ARGS\" -Verb RunAs -WindowStyle Hidden -Wait"
                
                if exist "!DEL_PATH!" (
                    echo %cRED%[ ERROR  ]%cRESET% Failed to completely delete directory. 
                ) else (
                    echo.
                    echo %cGREEN%[   OK   ]%cRESET% !DEL_NAME! was successfully uninstalled!
                )
            )
        )
        goto :eof
    )

    if /i "!CLI_COMMAND!"=="clear" (
        call :ClearJavaEnvironment
        goto :eof
    )

    if /i "!CLI_COMMAND!"=="channel" (
        call :HandleChannelCommand !CLI_TARGET!
        goto :eof
    )

    if /i "!CLI_COMMAND!"=="self-update" (
        call :SelfUpdate
        goto :eof
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
        goto :eof
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
            for /f "delims=" %%P in (""!CURRENT_JDK_PATH!"") do (
                endlocal & set "CURRENT_JDK_PATH=%%~P"
            )
            goto :eof
        )
    )
    echo.
    echo %cRED%[ ERROR  ]%cRESET% JDK !CLI_TARGET! not found.
    echo             Please ensure it is installed and try again.
    if "!SILENT_MODE!"=="0" timeout /t 3 >nul
    goto :eof
)

if "!SILENT_MODE!"=="1" (
    rem Safety catch: If we are hidden and CLI_TARGET was empty, abort so we don't hang!
    goto :eof
)

rem Show main menu
echo Please choose an option:
echo.
echo 1. JDK Management (Java)
echo 2. Ecosystem Management (Maven, Gradle, etc.)
echo 3. Settings (Global Command ^& Setup)
echo 4. Exit
echo.

choice /C 1234 /N /M "Enter your choice (1-4): "
set "choice=!errorlevel!"

if !choice!==4 (
    echo.
    echo %cBLUE%[  INFO  ]%cRESET% Exiting Java Version Manager... ^(Press any key to cancel^)
    <nul set /p "=%cBLUE%[  INFO  ]%cRESET% "
    for %%i in (3 2 1) do (
        <nul set /p "=%%i... "
        choice /C 123456789abcdefghijklmnopqrstuvwxyz0 /T 1 /D 0 /N >nul
        if !errorlevel! LSS 36 (
            echo.
            goto RESCAN_MENU
        )
    )
    echo.
    endlocal
    if defined ORIG_CP chcp !ORIG_CP! >nul
    set "CURRENT_JDK_PATH="
    goto :eof
)

if !choice!==3 (
    call :SettingsMenu
    if errorlevel 100 (
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
        for /f "delims=" %%P in (""!CURRENT_JDK_PATH!"") do (
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
choice /C 123 /N /M "Enter your choice (1-3): "
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
choice /C 123 /N /M "Enter your choice (1-3): "
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
choice /C 1234 /N /M "Enter your choice (1-4): "
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
set "EU_OPT_MAVEN=" & set "EU_OPT_GRADLE=" & set "EU_OPT_KOTLIN=" & set "EU_OPT_SCALA=" & set "EU_OPT_GROOVY="
set "EU_HAS_MAVEN=0" & set "EU_HAS_GRADLE=0" & set "EU_HAS_KOTLIN=0" & set "EU_HAS_SCALA=0" & set "EU_HAS_GROOVY=0"
set "EU_ACTIVE_MAVEN=" & set "EU_ACTIVE_GRADLE=" & set "EU_ACTIVE_KOTLIN=" & set "EU_ACTIVE_SCALA=" & set "EU_ACTIVE_GROOVY="

for %%T in (maven gradle kotlin scala groovy) do (
    set "eu_cdir=%LOCALAPPDATA%\DiamTek\JVM\candidates\%%T"
    if exist "!eu_cdir!" (
        set "eu_has_ver=0"
        for /d %%V in ("!eu_cdir!\*") do if not "%%~nxV"=="current" set "eu_has_ver=1"
        if "!eu_has_ver!"=="1" (
            set "EU_HAS_%%T=1"
            rem Resolve active version from the current symlink
            set "EU_ACTIVE_%%T=none"
            set "ACTIVE_TARGET="
            for /f "tokens=1,2*" %%A in ('fsutil reparsepoint query "!eu_cdir!\current" 2^>nul ^| findstr /i "Print Name:"') do set "ACTIVE_TARGET=%%C"
            if not defined ACTIVE_TARGET (
                for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '!eu_cdir!\current' -ErrorAction SilentlyContinue).Target" 2^>nul') do set "ACTIVE_TARGET=%%A"
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
for %%T in (maven gradle kotlin scala groovy) do (
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
    set "EU_OPT_MAVEN=!EU_OPT!"
    echo !EU_OPT!. Maven %cGRAY%[!EU_ACTIVE_maven!]%cRESET%
)
if "!EU_HAS_gradle!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_GRADLE=!EU_OPT!"
    echo !EU_OPT!. Gradle %cGRAY%[!EU_ACTIVE_gradle!]%cRESET%
)
if "!EU_HAS_kotlin!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_KOTLIN=!EU_OPT!"
    echo !EU_OPT!. Kotlin %cGRAY%[!EU_ACTIVE_kotlin!]%cRESET%
)
if "!EU_HAS_scala!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_SCALA=!EU_OPT!"
    echo !EU_OPT!. Scala %cGRAY%[!EU_ACTIVE_scala!]%cRESET%
)
if "!EU_HAS_groovy!"=="1" (
    set /a EU_OPT+=1
    set "EU_OPT_GROOVY=!EU_OPT!"
    echo !EU_OPT!. Groovy %cGRAY%[!EU_ACTIVE_groovy!]%cRESET%
)

echo.
echo %cGRAY%--- Actions ---%cRESET%
set /a EU_CANCEL=EU_OPT+1
echo !EU_CANCEL!. Go back
echo.

rem Build choice keys dynamically
set "EU_KEYS="
for /l %%i in (1,1,!EU_CANCEL!) do set "EU_KEYS=!EU_KEYS!%%i"
choice /C !EU_KEYS! /N /M "Select tool (1-!EU_CANCEL!): "
set "eu_choice=!errorlevel!"

if !eu_choice!==!EU_CANCEL! goto :eof

rem Determine which tools to check
set "EU_CHECK_MAVEN=0" & set "EU_CHECK_GRADLE=0" & set "EU_CHECK_KOTLIN=0" & set "EU_CHECK_SCALA=0" & set "EU_CHECK_GROOVY=0"

if !eu_choice!==!EU_OPT_ALL! (
    if "!EU_HAS_maven!"=="1" set "EU_CHECK_MAVEN=1"
    if "!EU_HAS_gradle!"=="1" set "EU_CHECK_GRADLE=1"
    if "!EU_HAS_kotlin!"=="1" set "EU_CHECK_KOTLIN=1"
    if "!EU_HAS_scala!"=="1" set "EU_CHECK_SCALA=1"
    if "!EU_HAS_groovy!"=="1" set "EU_CHECK_GROOVY=1"
)
if defined EU_OPT_MAVEN if !eu_choice!==!EU_OPT_MAVEN! set "EU_CHECK_MAVEN=1"
if defined EU_OPT_GRADLE if !eu_choice!==!EU_OPT_GRADLE! set "EU_CHECK_GRADLE=1"
if defined EU_OPT_KOTLIN if !eu_choice!==!EU_OPT_KOTLIN! set "EU_CHECK_KOTLIN=1"
if defined EU_OPT_SCALA if !eu_choice!==!EU_OPT_SCALA! set "EU_CHECK_SCALA=1"
if defined EU_OPT_GROOVY if !eu_choice!==!EU_OPT_GROOVY! set "EU_CHECK_GROOVY=1"

rem Now run update checks for selected tools
for %%T in (maven gradle kotlin scala groovy) do (
    if "!EU_CHECK_%%T!"=="1" call :EcoPerformCheck %%T "!EU_ACTIVE_%%T!"
)
goto :EcoPerformCheck_End

:EcoPerformCheck
set "CHK_T=%~1"
set "CHK_ACT=%~2"
set "TARGET_CANDIDATE=!CHK_T!"
set "c_dir=%LOCALAPPDATA%\DiamTek\JVM\candidates\!CHK_T!"
call :GetCandidateEnvVar
echo ------------------------------------------------------------
echo %cBLUE%[ ACTION ]%cRESET% Analyzing !CANDIDATE_PROPER_NAME!...
echo %cBLUE%[  INFO  ]%cRESET% Checking vendor API for updates...
echo %cBLUE%[  INFO  ]%cRESET% Active version: !CHK_ACT!

call :ResolveLatestEcosystemCandidate

if "!LATEST_VER!"=="ERROR" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to resolve latest version for !CANDIDATE_PROPER_NAME!.
) else (
    if exist "!c_dir!\!LATEST_VER!" (
        echo %cGREEN%[   OK   ]%cRESET% !CANDIDATE_PROPER_NAME! is up to date ^(!LATEST_VER!^).
    ) else (
        echo %cYELLOW%[ UPDATE ]%cRESET% New version available: !LATEST_VER!
        if defined CLI_COMMAND (
            echo.
            set "CLI_TARGET=!LATEST_VER!"
            set "IS_UPDATER=1"
            call :InstallCandidate
            set "IS_UPDATER="
        ) else (
            choice /C YN /M "Do you want to download and install !CANDIDATE_PROPER_NAME! !LATEST_VER! now? "
            if !errorlevel!==1 (
                echo.
                set "CLI_TARGET=!LATEST_VER!"
                set "IS_UPDATER=1"
                call :InstallCandidate
                set "IS_UPDATER="
            )
        )
    )
)
exit /b 0

:EcoPerformCheck_End

echo.
echo %cGREEN%[   OK   ]%cRESET% Update check complete.
pause
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
set "cancel_opt=6"
echo.
echo %cGRAY%--- Actions ---%cRESET%
echo 6. Go back
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

set /a cancel_opt=!TOOL_OPT! + 1
echo.
echo %cGRAY%--- Actions ---%cRESET%
echo !cancel_opt!. Go back

:ECO_TOOL_PROMPT
echo.
set "VALID_CHOICES="
for /l %%k in (1,1,!cancel_opt!) do set "VALID_CHOICES=!VALID_CHOICES!%%k"

choice /C !VALID_CHOICES! /N /M "Enter your choice (1-!cancel_opt!): "
set "tool_choice=!errorlevel!"
if !tool_choice!==!cancel_opt! (
    if "!ECO_SUB_MODE!"=="SWITCH" goto :EcosystemMenu
    goto :EcoVersionMenu
)
if defined OPT_M if !tool_choice!==!OPT_M! set "TARGET_CANDIDATE=maven"
if defined OPT_G if !tool_choice!==!OPT_G! set "TARGET_CANDIDATE=gradle"
if defined OPT_K if !tool_choice!==!OPT_K! set "TARGET_CANDIDATE=kotlin"
if defined OPT_S if !tool_choice!==!OPT_S! set "TARGET_CANDIDATE=scala"
if defined OPT_GR if !tool_choice!==!OPT_GR! set "TARGET_CANDIDATE=groovy"

call :GetCandidateEnvVar

if "!ECO_SUB_MODE!"=="INSTALL" (
    echo.
    set /p TARGET_VER="Enter version of !CANDIDATE_PROPER_NAME! to install (or type 'latest'): "
    if "!TARGET_VER!"=="" set "TARGET_VER=latest"
    set "CLI_TARGET=!TARGET_VER!"
    call :InstallCandidate
    goto :EcoVersionMenu
)

if "!ECO_SUB_MODE!"=="UNINSTALL" (
    echo.
    echo %cBLUE%[  INFO  ]%cRESET% Installed !CANDIDATE_PROPER_NAME! versions:
    for /f "delims=" %%V in ('powershell -NoProfile -Command "Get-ChildItem -Path '%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { [version]($_.Name -replace '-.*','') } -Descending | Select-Object -ExpandProperty Name"') do (
        echo   - %%V
    )
    echo.
    set /p TARGET_VER="Enter exact version to uninstall: "
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
    for /f "delims=" %%V in ('powershell -NoProfile -Command "Get-ChildItem -Path '!CANDIDATE_DIR!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { [version]($_.Name -replace '-.*','') } -Descending | Select-Object -ExpandProperty Name"') do (
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
for /f "tokens=1,2*" %%A in ('fsutil reparsepoint query "!CANDIDATE_DIR!\current" 2^>nul ^| findstr /i "Print Name:"') do set "ACTIVE_TARGET=%%C"
if not defined ACTIVE_TARGET (
    for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '!CANDIDATE_DIR!\current' -ErrorAction SilentlyContinue).Target" 2^>nul') do set "ACTIVE_TARGET=%%A"
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
choice /C !VALID_CHOICES! /N /M "Select an option (1-!total_opts!): "
set "user_choice=!errorlevel!"
goto :PROCESS_ECO_CHOICE

:ECO_CHOICE_MANUAL
set user_choice=
set /p user_choice="Select an option (1-!total_opts!): "
if "!user_choice!"=="" goto :ECO_CHOICE_MANUAL
set "user_choice=!user_choice: =!"
set "NUM_TEST="
for /f "delims=0123456789" %%A in (""!user_choice!"") do set "NUM_TEST=%%A"
if defined NUM_TEST goto :ECO_CHOICE_MANUAL
if !user_choice! LSS 1 goto :ECO_CHOICE_MANUAL
if !user_choice! GTR !total_opts! goto :ECO_CHOICE_MANUAL

:PROCESS_ECO_CHOICE
if !user_choice!==!cancel_opt! goto :EcosystemSelectTool
if !user_choice!==!clear_opt! (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Clearing !CANDIDATE_PROPER_NAME! from environment...
    set "SYMLINK_PATH=!CANDIDATE_DIR!\current"
    if exist "!SYMLINK_PATH!" rmdir "!SYMLINK_PATH!" >nul 2>&1
    reg delete "HKCU\Environment" /v !CANDIDATE_ENV_VAR! /f >nul 2>&1
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
choice /C !LTS_CHOICE_STR! /N /M "Select LTS version (1-!LTS_OPT!): "
set "LTS_CHOICE=!errorlevel!"
if !LTS_CHOICE!==!LTS_CANCEL_OPT! (
    set "CLI_TARGET="
    goto :eof
)
call set "CLI_TARGET=%%LTS_VER_!LTS_CHOICE!%%"
goto :eof

:DownloadJDK_Headless
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
    echo 9. Cancel
    echo.
    choice /C 123456789 /N /M "Select vendor (1-9): "
    if !errorlevel!==9 goto :eof
    if !errorlevel!==1 set "CLI_VENDOR=Oracle"
    if !errorlevel!==2 set "CLI_VENDOR=Adoptium"
    if !errorlevel!==3 set "CLI_VENDOR=GraalVM"
    if !errorlevel!==4 set "CLI_VENDOR=Corretto"
    if !errorlevel!==5 set "CLI_VENDOR=Zulu"
    if !errorlevel!==6 set "CLI_VENDOR=Microsoft"
    if !errorlevel!==7 set "CLI_VENDOR=Liberica"
    if !errorlevel!==8 set "CLI_VENDOR=Semeru"
)

rem Normalize vendor aliases
if /i "!CLI_VENDOR!"=="bellsoft" set "CLI_VENDOR=Liberica"
if /i "!CLI_VENDOR!"=="ibm" set "CLI_VENDOR=Semeru"
if /i "!CLI_VENDOR!"=="openj9" set "CLI_VENDOR=Semeru"
if /i "!CLI_VENDOR!"=="temurin" set "CLI_VENDOR=Adoptium"

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
            choice /C yn /N /M "Would you like to reinstall and overwrite it? (y/N): "
            if !errorlevel! NEQ 1 (
                echo %cBLUE%[  INFO  ]%cRESET% Installation cancelled.
                if "!CLI_COMMAND!"=="" pause
                goto :eof
            )
        )
    )
)

if not defined DL_VERSION (
    echo %cRED%[ ERROR  ]%cRESET% No version specified.
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)
set "VER_NUM_TEST="
for /f "delims=0123456789" %%A in ("!DL_VERSION!") do set "VER_NUM_TEST=%%A"
if defined VER_NUM_TEST (
    echo %cRED%[ ERROR  ]%cRESET% '!DL_VERSION!' is not a JDK major version number.
    echo            Expected a plain number, e.g. 8, 17, 21, 25.
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)

if !DL_VERSION! LEQ 16 (
    if /i "!CLI_VENDOR!"=="oracle" (
        echo.
        echo %cRED%[ ERROR  ]%cRESET% Oracle Java 16 and below are locked behind an authentication wall.
        echo            Please use Adoptium, GraalVM, Liberica, or Semeru for these versions.
        if "!CLI_COMMAND!"=="" pause
        goto :eof
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
            choice /C yn /N /M "Proceed with installing 17.0.12? (y/N): "
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
if "!API_URL!"=="" (
    echo %cRED%[ ERROR  ]%cRESET% Unknown or unsupported vendor: !CLI_VENDOR!
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)
goto :FetchAndExtract

:Resolve_Oracle
set "DL_VENDOR=Oracle"
set "API_URL=https://download.oracle.com/java/!DL_VERSION!/latest/jdk-!DL_VERSION!_windows-!SYS_ARCH!_bin.zip"
if "!DL_VERSION!"=="17" set "API_URL=https://download.oracle.com/java/17/archive/jdk-17.0.12_windows-x64_bin.zip"
if "!DL_VERSION!"=="18" set "API_URL=https://download.oracle.com/java/18/archive/jdk-18.0.2.1_windows-x64_bin.zip"
if "!DL_VERSION!"=="19" set "API_URL=https://download.oracle.com/java/19/archive/jdk-19.0.2_windows-x64_bin.zip"
if "!DL_VERSION!"=="20" set "API_URL=https://download.oracle.com/java/20/archive/jdk-20.0.2_windows-x64_bin.zip"
if "!DL_VERSION!"=="22" set "API_URL=https://download.oracle.com/java/22/archive/jdk-22.0.2_windows-x64_bin.zip"
if "!DL_VERSION!"=="23" set "API_URL=https://download.oracle.com/java/23/archive/jdk-23.0.2_windows-x64_bin.zip"
if "!DL_VERSION!"=="24" set "API_URL=https://download.oracle.com/java/24/archive/jdk-24.0.2_windows-x64_bin.zip"
set "API_SHA256_URL=!API_URL!.sha256"
set "API_SHA256="
goto :FetchAndExtract

:Resolve_Adoptium
set "DL_VENDOR=Adoptium"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying Adoptium API for latest JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $res = Invoke-RestMethod -Uri 'https://api.adoptium.net/v3/assets/feature_releases/!DL_VERSION!/ga?architecture=!SYS_ARCH!&image_type=jdk&jvm_impl=hotspot&os=windows&page=0&page_size=1' -UseBasicParsing; if ($res[0].binaries[0].package.link -and $res[0].binaries[0].package.checksum) { Write-Output ('API_URL='+$res[0].binaries[0].package.link); Write-Output ('API_SHA256='+$res[0].binaries[0].package.checksum) } else { exit 1 } } catch { Write-Output ('API_ERROR='+$_.Exception.Message); exit 1 }"
goto Run_API_Query

:Resolve_GraalVM
set "DL_VENDOR=GraalVM"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying GraalVM GitHub API for latest JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $res = Invoke-RestMethod -Uri 'https://api.github.com/repos/graalvm/graalvm-ce-builds/releases' -UseBasicParsing; $t = $null; foreach ($r in $res) { if ($r.tag_name -like 'jdk-!DL_VERSION!*') { $t = $r; break } }; if (-not $t) { exit 1 }; $u = $null; $s = $null; foreach ($a in $t.assets) { if ($a.name -match 'windows-(x64|amd64)_bin\.zip$') { $u = $a.browser_download_url }; if ($a.name -match 'windows-(x64|amd64)_bin\.zip\.sha256$') { $s = $a.browser_download_url } }; if ($u -and $s) { Write-Output ('API_URL='+$u); Write-Output ('API_SHA256_URL='+$s) } else { exit 1 } } catch { Write-Output ('API_ERROR='+$_.Exception.Message); exit 1 }"
goto Run_API_Query

:Resolve_Corretto
set "DL_VENDOR=Corretto"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Resolving Amazon Corretto JDK !DL_VERSION! URLs...
set "API_URL=https://corretto.aws/downloads/latest/amazon-corretto-!DL_VERSION!-!SYS_ARCH!-windows-jdk.zip"
set "API_SHA256_URL=https://corretto.aws/downloads/latest_sha256/amazon-corretto-!DL_VERSION!-!SYS_ARCH!-windows-jdk.zip"
set "API_SHA256="
goto :FetchAndExtract

:Resolve_Zulu
set "DL_VENDOR=Zulu"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying Azul Zulu API for latest JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $list = Invoke-RestMethod -Uri 'https://api.azul.com/metadata/v1/zulu/packages/?java_version=!DL_VERSION!&os=windows&arch=!ZULU_ARCH!&archive_type=zip&java_package_type=jdk&javafx_bundled=false&release_status=ga&availability_types=CA&latest=true&page=1&page_size=1' -UseBasicParsing; if (-not $list -or -not $list[0].download_url) { exit 1 }; Write-Output ('API_URL='+$list[0].download_url); $uuid = $list[0].package_uuid; if ($uuid) { try { $d = Invoke-RestMethod -Uri ('https://api.azul.com/metadata/v1/zulu/packages/'+$uuid) -UseBasicParsing; if ($d.sha256_hash) { Write-Output ('API_SHA256='+$d.sha256_hash) } } catch { } } } catch { Write-Output ('API_ERROR='+$_.Exception.Message); exit 1 }"
goto Run_API_Query

:Resolve_Microsoft
set "DL_VENDOR=Microsoft"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Resolving Microsoft Build of OpenJDK !DL_VERSION! URLs...
set "API_URL=https://aka.ms/download-jdk/microsoft-jdk-!DL_VERSION!-windows-!SYS_ARCH!.zip"
set "API_SHA256_URL=https://aka.ms/download-jdk/microsoft-jdk-!DL_VERSION!-windows-!SYS_ARCH!.zip.sha256sum.txt"
set "API_SHA256="
goto :FetchAndExtract

:Resolve_Liberica
set "DL_VENDOR=Liberica"
rem BellSoft official REST API exclusively distributes SHA1 checksums.
rem jvm verifies the provided SHA1 hash directly against the downloaded payload.
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying BellSoft Liberica API for latest JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $res = Invoke-RestMethod -Uri 'https://api.bell-sw.com/v1/liberica/releases?version-feature=!DL_VERSION!&version-modifier=latest&bitness=64&os=windows&arch=!ZULU_ARCH!&package-type=zip&bundle-type=jdk' -UseBasicParsing; if (-not $res -or -not $res[0].downloadUrl) { exit 1 }; Write-Output ('API_URL='+$res[0].downloadUrl); if ($res[0].sha1) { Write-Output ('API_SHA1='+$res[0].sha1) } } catch { Write-Output ('API_ERROR='+$_.Exception.Message); exit 1 }"
goto Run_API_Query

:Resolve_Semeru
set "DL_VENDOR=Semeru"
if /i "!SYS_ARCH!" NEQ "x64" (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% IBM Semeru ^(OpenJ9^) does not publish Windows ARM64 builds.
    echo            Please use Adoptium, Zulu, or Microsoft for Windows ARM64.
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying IBM Semeru GitHub API for latest JDK !DL_VERSION! release...
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $res = Invoke-RestMethod -Uri 'https://api.github.com/repos/ibmruntimes/semeru!DL_VERSION!-binaries/releases/latest' -UseBasicParsing; if (-not $res -or -not $res.assets) { exit 1 }; $u = $null; $s = $null; foreach ($a in $res.assets) { if ($a.name -match 'ibm-semeru-open-jdk_x64_windows_.*\.zip$') { $u = $a.browser_download_url }; if ($a.name -match 'ibm-semeru-open-jdk_x64_windows_.*\.zip\.sha256\.txt$') { $s = $a.browser_download_url } }; if ($u) { Write-Output ('API_URL='+$u); if ($s) { Write-Output ('API_SHA256_URL='+$s) } } else { exit 1 } } catch { Write-Output ('API_ERROR='+$_.Exception.Message); exit 1 }"
goto Run_API_Query

:Run_API_Query
set "API_URL=" & set "API_SHA256=" & set "API_SHA256_URL=" & set "API_SHA1=" & set "API_ERROR="
for /f "tokens=1,* delims==" %%A in ('powershell -NoProfile -Command "!PS_CMD!"') do (
    if "%%A"=="API_URL" set "API_URL=%%B"
    if "%%A"=="API_SHA256" set "API_SHA256=%%B"
    if "%%A"=="API_SHA256_URL" set "API_SHA256_URL=%%B"
    if "%%A"=="API_SHA1" set "API_SHA1=%%B"
    if "%%A"=="API_ERROR" set "API_ERROR=%%B"
)

if defined API_ERROR (
    echo %cRED%[ ERROR  ]%cRESET% Network connection failed. You appear to be offline.
    echo %cYELLOW%[ DETAIL ]%cRESET% !API_ERROR!
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)
if "!API_URL!"=="" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to find !DL_VENDOR! JDK !DL_VERSION!. The version might not exist.
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)
goto :FetchAndExtract

:FetchLatestVersions
if defined ORACLE_LATEST_FEATURE goto :eof
set "PS_CMD=$ProgressPreference = 'SilentlyContinue'; try { $res = Invoke-RestMethod -Uri 'https://api.adoptium.net/v3/info/available_releases' -UseBasicParsing -TimeoutSec 3; Write-Output ('LATEST_FEATURE='+$res.most_recent_feature_release); Write-Output ('LATEST_LTS='+$res.most_recent_lts) } catch { Write-Output 'LATEST_FEATURE=26'; Write-Output 'LATEST_LTS=25' }"
for /f "tokens=1,* delims==" %%A in ('powershell -NoProfile -Command "!PS_CMD!"') do (
    if "%%A"=="LATEST_FEATURE" set "ORACLE_LATEST_FEATURE=%%B"
    if "%%A"=="LATEST_LTS" set "ORACLE_LATEST_LTS=%%B"
)
goto :eof

:FetchAndExtract
setlocal enabledelayedexpansion
set "ZIP_PATH=%TEMP%\jdk_!DL_VENDOR!_!DL_VERSION!_download.zip"
set "EXTRACT_DIR=%TEMP%\jdk_!DL_VENDOR!_!DL_VERSION!_extract"
set "DEST_DIR=C:\Program Files\Java"

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
set "DL_STRIP_ROOT=0"

call :ExecuteSharedDownloader
if !errorlevel! NEQ 0 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% The installation failed.
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)

set "NEW_FOLDER="
set "ROOT_COUNT=0"
for /d %%D in ("!EXTRACT_DIR!\*") do (
    set "NEW_FOLDER=%%~nxD"
    set /a ROOT_COUNT+=1
)

if !ROOT_COUNT! EQU 0 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Could not locate the extracted JDK folder.
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)

if !ROOT_COUNT! GTR 1 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Invalid archive structure: Multiple root folders detected in the ZIP.
    echo %cYELLOW%[ DETAIL ]%cRESET% Expected exactly 1 root folder, but found !ROOT_COUNT!.
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Installing !NEW_FOLDER! to system directory...
set "SAFE_DEST=!DEST_DIR:'=''!"
set "SAFE_FOLDER=!NEW_FOLDER:'=''!"
set "SAFE_EXTRACT=!EXTRACT_DIR:'=''!"
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -WindowStyle Hidden -Wait -ArgumentList @('-NoProfile', '-Command', '$d = ''!SAFE_DEST!''; $f = ''!SAFE_FOLDER!''; $e = ''!SAFE_EXTRACT!''; if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }; $t = Join-Path $d $f; if (Test-Path $t) { Remove-Item -LiteralPath $t -Recurse -Force }; Move-Item -LiteralPath (Join-Path $e $f) -Destination $d -Force; if (Test-Path $e) { Remove-Item -LiteralPath $e -Recurse -Force -ErrorAction SilentlyContinue }')"

if exist "!DEST_DIR!\!NEW_FOLDER!\bin\java.exe" (
    echo.
    echo %cGREEN%[   OK   ]%cRESET% !DL_VENDOR! JDK !DL_VERSION! successfully installed!
    if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
    endlocal & set "NEEDS_RESCAN=1"
    goto :eof
) else (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% The installation failed during the move operation.
    if "!CLI_COMMAND!"=="" pause
)
endlocal
goto :eof


rem ============================================================
rem PATH UPDATER
rem ============================================================
:UpdateSystemPath
if not defined CURRENT_JDK_PATH goto :eof
call :BackupRegistry
setlocal enabledelayedexpansion

set "SAFE_JDK_PATH=!CURRENT_JDK_PATH:'=''!"

echo            - De-bloating Phantom Oracle paths and injecting %%JAVA_HOME%%\bin natively...

if /i "!SWITCH_MODE!"=="DIRECT" (
    echo %cBLUE%[ ACTION ]%cRESET% Requesting Administrator privileges to update Machine Registry...
    
    rem Scrub any conflicting User-level JAVA_HOME that might override the Machine-level variable
    reg delete "HKCU\Environment" /v JAVA_HOME /f >nul 2>&1
    
    powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -WindowStyle Hidden -Wait -ArgumentList @('-NoProfile', '-Command', '$p = [Environment]::GetEnvironmentVariable(''Path'', ''Machine''); $purges = @(''C:\Program Files\Common Files\Oracle\Java\javapath'', ''C:\Program Files (x86)\Common Files\Oracle\Java\javapath'', ''C:\ProgramData\Oracle\Java\javapath'', ''%LOCALAPPDATA%\DiamTek\JVM\current\bin'', ''!SAFE_JDK_PATH!\bin''); if ($p) { $clean = ($p -split '';'' | Where-Object { $_ -and $purges -notcontains $_.TrimEnd(''\'') -and $_.TrimEnd(''\'') -ne ''%%JAVA_HOME%%\bin'' }) -join '';''; $finalPath = ''%%JAVA_HOME%%\bin;'' + $clean; [Environment]::SetEnvironmentVariable(''JAVA_HOME'', ''!SAFE_JDK_PATH!'', ''Machine''); [Environment]::SetEnvironmentVariable(''Path'', $finalPath, ''Machine'') }')" 2>nul
    
    echo %cGREEN%[   OK   ]%cRESET% JAVA_HOME and SYSTEM PATH updated successfully via UAC.
) else (
    echo %cBLUE%[ ACTION ]%cRESET% Updating USER PATH...
    
    powershell -NoProfile -Command "$p = [Environment]::GetEnvironmentVariable('Path', 'User'); $purges = @('C:\Program Files\Common Files\Oracle\Java\javapath', 'C:\Program Files (x86)\Common Files\Oracle\Java\javapath', 'C:\ProgramData\Oracle\Java\javapath', '%LOCALAPPDATA%\DiamTek\JVM\current\bin', '!SAFE_JDK_PATH!\bin'); if ($p) { $clean = ($p -split ';' | Where-Object { $_ -and $purges -notcontains $_.TrimEnd('\') -and $_.TrimEnd('\') -ne '%%JAVA_HOME%%\bin' }) -join ';'; $finalPath = '%%JAVA_HOME%%\bin;' + $clean; [Environment]::SetEnvironmentVariable('Path', $finalPath, 'User') } else { [Environment]::SetEnvironmentVariable('Path', '%%JAVA_HOME%%\bin', 'User') }"
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to update USER PATH.
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% USER PATH updated successfully.
    )
)

echo.
echo %cGREEN%[   OK   ]%cRESET% PATH update complete.
endlocal
goto :eof

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
    if not exist "%LOCALAPPDATA%\DiamTek\JVM" mkdir "%LOCALAPPDATA%\DiamTek\JVM"
    > "%LOCALAPPDATA%\DiamTek\JVM\channel.txt" echo STABLE
    echo %cGREEN%[   OK   ]%cRESET% Switched update channel to %cGREEN%[Stable]%cRESET% ^(Official Releases^).
    goto :eof
)
if /i "%~1"=="nightly" (
    set "UPDATE_CHANNEL=NIGHTLY"
    if not exist "%LOCALAPPDATA%\DiamTek\JVM" mkdir "%LOCALAPPDATA%\DiamTek\JVM"
    > "%LOCALAPPDATA%\DiamTek\JVM\channel.txt" echo NIGHTLY
    echo %cGREEN%[   OK   ]%cRESET% Switched update channel to %cPURPLE%[Nightly]%cRESET% ^(Cutting-edge main branch^).
    goto :eof
)
echo %cRED%[ ERROR  ]%cRESET% Unknown channel '%~1'. Valid options are 'stable' or 'nightly'.
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
choice /C yn /N /M "Are you sure you want to proceed? (y/N): "
if !errorlevel! NEQ 1 (
    endlocal
    goto :eof
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Removing JAVA_HOME and Ecosystem variables from registry...
reg delete "HKCU\Environment" /v JAVA_HOME /f >nul 2>&1
reg delete "HKCU\Environment" /v MAVEN_HOME /f >nul 2>&1
reg delete "HKCU\Environment" /v GRADLE_HOME /f >nul 2>&1
reg delete "HKCU\Environment" /v KOTLIN_HOME /f >nul 2>&1
reg delete "HKCU\Environment" /v SCALA_HOME /f >nul 2>&1
reg delete "HKCU\Environment" /v GROOVY_HOME /f >nul 2>&1

echo %cBLUE%[ ACTION ]%cRESET% Removing active directory junctions...
if exist "%LOCALAPPDATA%\DiamTek\JVM\current" rmdir "%LOCALAPPDATA%\DiamTek\JVM\current" >nul 2>&1
for /d %%C in ("%LOCALAPPDATA%\DiamTek\JVM\candidates\*") do (
    if exist "%%C\current" rmdir "%%C\current" >nul 2>&1
)

rem Safely gather paths to purge to prevent catastrophic '\bin' wiping if variables are empty
set PURGE_PATHS="%LOCALAPPDATA%\DiamTek\JVM\current\bin" "%%JAVA_HOME%%\bin" "C:\Program Files\Common Files\Oracle\Java\javapath" "C:\Program Files (x86)\Common Files\Oracle\Java\javapath" "C:\ProgramData\Oracle\Java\javapath"
if defined JAVA_HOME set PURGE_PATHS=!PURGE_PATHS! "!JAVA_HOME!\bin"
for /l %%k in (1,1,!JDK_COUNT!) do set PURGE_PATHS=!PURGE_PATHS! "!JDK_PATH_%%k!\bin"

rem Create Registry Backups Before Destructive Scrubbing
echo %cBLUE%[ ACTION ]%cRESET% Creating redundant registry backups...
call :BackupRegistry

rem Clean SYSTEM PATH
echo %cBLUE%[ ACTION ]%cRESET% Cleaning SYSTEM PATH...
set "SYS_PATH="
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
if defined SYS_PATH (
    set "PS_CMD=$p = $env:SYS_PATH -split ';'; $r = @(); foreach ($d in $p) { if ($d -ne ''"
    for %%P in (!PURGE_PATHS!) do (
        set "PS_CMD=!PS_CMD! -and $d -ne '%%~P'"
    )
    set "PS_CMD=!PS_CMD!) { $r += $d } }; $r -join ';'"
    for /f "delims=" %%A in ('powershell -NoProfile -Command "!PS_CMD!"') do set "SYS_PATH=%%A"
    
    echo %cBLUE%[ ACTION ]%cRESET% Requesting Administrator privileges to clear Machine Registry...
    set "SAFE_SYS_PATH=!SYS_PATH:'=''!"
    powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -WindowStyle Hidden -Wait -ArgumentList @('-NoProfile', '-Command', '[Environment]::SetEnvironmentVariable(''JAVA_HOME'', $null, ''Machine''); [Environment]::SetEnvironmentVariable(''Path'', ''!SAFE_SYS_PATH!'', ''Machine'')')" 2>nul
)

rem Clean USER PATH
echo %cBLUE%[ ACTION ]%cRESET% Cleaning USER PATH...
set "USR_PATH="
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
if defined USR_PATH (
    set "ECO_PURGE="%%MAVEN_HOME%%\bin" "%%GRADLE_HOME%%\bin" "%%KOTLIN_HOME%%\bin" "%%SCALA_HOME%%\bin" "%%GROOVY_HOME%%\bin""
    set "PS_CMD=$p = $env:USR_PATH -split ';'; $r = @(); foreach ($d in $p) { if ($d -ne ''"
    for %%P in (!PURGE_PATHS! !ECO_PURGE!) do (
        set "PS_CMD=!PS_CMD! -and $d -ne '%%~P'"
    )
    set "PS_CMD=!PS_CMD!) { $r += $d } }; $r -join ';'"
    for /f "delims=" %%A in ('powershell -NoProfile -Command "!PS_CMD!"') do set "USR_PATH=%%A"
    powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('Path', $env:USR_PATH, 'User')"
)

rem Clean active session variables
echo %cBLUE%[ ACTION ]%cRESET% Cleaning current session environment...
set "CLEAN_PATH=!PATH!"

set "SESS_ECO_PURGE="%%MAVEN_HOME%%\bin" "%%GRADLE_HOME%%\bin" "%%KOTLIN_HOME%%\bin" "%%SCALA_HOME%%\bin" "%%GROOVY_HOME%%\bin""
if defined MAVEN_HOME set "SESS_ECO_PURGE=!SESS_ECO_PURGE! "!MAVEN_HOME!\bin""
if defined GRADLE_HOME set "SESS_ECO_PURGE=!SESS_ECO_PURGE! "!GRADLE_HOME!\bin""
if defined KOTLIN_HOME set "SESS_ECO_PURGE=!SESS_ECO_PURGE! "!KOTLIN_HOME!\bin""
if defined SCALA_HOME set "SESS_ECO_PURGE=!SESS_ECO_PURGE! "!SCALA_HOME!\bin""
if defined GROOVY_HOME set "SESS_ECO_PURGE=!SESS_ECO_PURGE! "!GROOVY_HOME!\bin""

rem Use PowerShell to explicitly filter paths via exact array string matching
set "PS_CMD=$p = $env:PATH -split ';'; $r = @(); foreach ($d in $p) { if ($d -ne ''"
for %%P in (!PURGE_PATHS! !SESS_ECO_PURGE!) do (
    set "PS_CMD=!PS_CMD! -and $d -ne '%%~P'"
)
set "PS_CMD=!PS_CMD!) { $r += $d } }; $r -join ';'"
for /f "delims=" %%A in ('powershell -NoProfile -Command "!PS_CMD!"') do set "CLEAN_PATH=%%A"

rem Export active session path
for /f "delims=" %%A in (""!CLEAN_PATH!"") do (
    endlocal & set "PATH=%%~A" & set "JAVA_HOME=" & set "MAVEN_HOME=" & set "GRADLE_HOME=" & set "KOTLIN_HOME=" & set "SCALA_HOME=" & set "GROOVY_HOME="
)
echo %cGREEN%[   OK   ]%cRESET% Java environment variables cleared.
echo            Your terminal will automatically sync when you exit the menu.
echo.
echo Press any key to return to the menu...
pause >nul
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
where java >nul 2>nul
if errorlevel 1 (
    echo %cYELLOW%[ WARNING]%cRESET% Java is NOT in PATH or not installed
    echo %cBLUE%[  INFO  ]%cRESET% This is normal if Java was just removed from PATH
) else (
    echo %cGREEN%[   OK   ]%cRESET% Java is in PATH
    echo.
    for /f "delims=" %%A in ('java -version 2^>^&1') do echo %%A
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
choice /C !P_KEYS! /N /M "Select option (1-!P_OPT!): "
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

choice /C !P_CHOICE_KEYS! /N /M "Enter your choice (1-!P_CANCEL!): "
set "p_choice=!errorlevel!"

if !p_choice!==0 (
    echo.
    goto GET_P_CHOICE
)
goto PROCESS_P_CHOICE

:GET_P_CHOICE_MANUAL
set p_choice=
set /p p_choice="Enter your choice (1-!P_CANCEL!): "
if "!p_choice!"=="" goto GET_P_CHOICE_MANUAL
set "p_choice=!p_choice: =!"
set "NUM_TEST="
for /f "delims=0123456789" %%A in (""!p_choice!"") do set "NUM_TEST=%%A"
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

choice /C 1234 /N /M "Enter your choice (1-4): "
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
choice /C 123 /N /M "Enter your choice (1-3): "
if !errorlevel!==1 call :InstallWizard_JDK
if !errorlevel!==2 (
    set "ECO_SUB_MODE=INSTALL"
    call :EcosystemSelectTool
)
goto :eof

:InstallWizard_JDK
echo.
echo %cBLUE%[ ACTION ]%cRESET% Enter the JDK version you wish to install.
echo             ^(e.g., 8, 11, 17, 21, 22, 23, 24, 25, 26^)
echo             Type 'lts' for latest Long-Term Support
echo             Type 'latest' for the absolute newest release
echo.
set /p TARGET_VER="Enter version: "
if "!TARGET_VER!"=="" goto :eof
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

for /l %%k in (1,1,!JDK_COUNT!) do (
    for %%V in (Oracle Adoptium GraalVM Corretto Zulu Microsoft Liberica Semeru) do (
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
for %%V in (Oracle Adoptium GraalVM Corretto Zulu Microsoft Liberica Semeru) do (
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

set "BV_KEYS="
for /l %%k in (1,1,!BV_OPT_CANCEL!) do set "BV_KEYS=!BV_KEYS!%%k"
choice /C !BV_KEYS! /N /M "Select option (1-!BV_OPT_CANCEL!): "
set "bv_choice=!errorlevel!"

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
for %%V in (Oracle Adoptium GraalVM Corretto Zulu Microsoft Liberica Semeru) do (
    if /i "!UP_VENDOR!"=="%%V" set "VENDOR_SUPPORTED=1"
)
if not defined VENDOR_SUPPORTED (
    echo %cYELLOW%[ WARNING]%cRESET% Vendor '!UP_VENDOR!' has no update source. Skipping.
    echo %cBLUE%[  INFO  ]%cRESET% Manually managed or linked JDKs must be updated by hand.
    goto :eof
)

echo %cBLUE%[  INFO  ]%cRESET% Checking vendor API for updates...

set "UPDATE_RESULT=" & set "LOCAL_VER=" & set "REMOTE_VER="

set "UPDATE_CHECKER_PS1=%TEMP%\jvm_update_!RANDOM!.ps1"
(
    echo param^(
    echo     [Parameter^(Mandatory=$true^)][string]$Vendor,
    echo     [Parameter^(Mandatory=$true^)][string]$Major,
    echo     [Parameter^(Mandatory=$true^)][string]$LocalPath
    echo ^)
    echo $ProgressPreference = 'SilentlyContinue'
    echo $localVersion = "UNKNOWN"
    echo $releaseFile = Join-Path $LocalPath "release"
    echo if ^(Test-Path $releaseFile^) {
    echo     $content = Get-Content $releaseFile
    echo     $semVerLine = $content ^| Where-Object { $_ -match "^^SEMANTIC_VERSION=" }
    echo     $javaVerLine = $content ^| Where-Object { $_ -match "^^JAVA_VERSION=" }
    echo     if ^($semVerLine^) { $localVersion = ^($semVerLine -split "="^)[1].Trim^([char]34, ' '^) }
    echo     elseif ^($javaVerLine^) { $localVersion = ^($javaVerLine -split "="^)[1].Trim^([char]34, ' '^) }
    echo }
    echo $remoteVersion = "UNKNOWN"
    echo try {
    echo     if ^($Vendor -eq "Oracle"^) {
    echo         Write-Output "ORACLE_LEGACY"
    echo         exit 0
    echo     } elseif ^($Vendor -eq "Adoptium"^) {
    echo         $res = Invoke-RestMethod -Uri "https://api.adoptium.net/v3/assets/feature_releases/$Major/ga?architecture=!SYS_ARCH!&image_type=jdk&jvm_impl=hotspot&os=windows&page=0&page_size=1" -UseBasicParsing -TimeoutSec 5
    echo         $remoteVersion = $res[0].version_data.openjdk_version.Replace^('-LTS', ''^)
    echo     } elseif ^($Vendor -eq "Corretto"^) {
    echo         $req = [Net.HttpWebRequest]::Create^("https://corretto.aws/downloads/latest/amazon-corretto-$Major-!SYS_ARCH!-windows-jdk.zip"^)
    echo         $req.AllowAutoRedirect = $false
    echo         $req.Timeout = 5000
    echo         $res = $req.GetResponse^(^)
    echo         if ^($res.Headers["Location"] -match "resources/([^^/]+)/"^) { $remoteVersion = $matches[1] }
    echo     } elseif ^($Vendor -eq "GraalVM"^) {
    echo         $res = Invoke-RestMethod -Uri "https://api.github.com/repos/graalvm/graalvm-ce-builds/releases/latest" -UseBasicParsing -TimeoutSec 5
    echo         $remoteVersion = $res.tag_name -replace "^^jdk-", ""
    echo     } elseif ^($Vendor -eq "Zulu"^) {
    echo         $res = Invoke-RestMethod -Uri "https://api.azul.com/metadata/v1/zulu/packages/?java_version=$Major&os=windows&arch=!ZULU_ARCH!&hw_bitness=64&archive_type=zip&java_package_type=jdk&latest=true" -UseBasicParsing -TimeoutSec 5
    echo         $remoteVersion = ^($res[0].java_version -join '.'^)
    echo     } elseif ^($Vendor -eq "Microsoft"^) {
    echo         $req = [Net.HttpWebRequest]::Create^("https://aka.ms/download-jdk/microsoft-jdk-$Major-windows-!SYS_ARCH!.zip"^)
    echo         $req.AllowAutoRedirect = $false
    echo         $req.Timeout = 5000
    echo         $res = $req.GetResponse^(^)
    echo         if ^($res.Headers["Location"] -match "jdk-([^^/-]+)-"^) { $remoteVersion = $matches[1] }
    echo     } elseif ^($Vendor -eq "Liberica"^) {
    echo         $res = Invoke-RestMethod -Uri "https://api.bell-sw.com/v1/liberica/releases?version-feature=$Major&version-modifier=latest&bitness=64&os=windows&arch=!ZULU_ARCH!&package-type=zip&bundle-type=jdk" -UseBasicParsing -TimeoutSec 5
    echo         if ^($res -and $res[0].version^) { $remoteVersion = $res[0].version }
    echo     } elseif ^($Vendor -eq "Semeru"^) {
    echo         $res = Invoke-RestMethod -Uri "https://api.github.com/repos/ibmruntimes/semeru$Major-binaries/releases/latest" -UseBasicParsing -TimeoutSec 5
    echo         if ^($res -and $res.tag_name^) { $remoteVersion = $res.tag_name -replace "^^jdk-", "" }
    echo     }
    echo } catch {
    echo     Write-Output "ERROR|$($_.Exception.Message)"
    echo     exit 1
    echo }
    echo Write-Output "LOCAL|$localVersion"
    echo Write-Output "REMOTE|$remoteVersion"
    echo $cleanLocal = $localVersion -replace '^^1\.8\.0_', '8.0.' -replace '[\+-].*$', ''
    echo $cleanRemote = $remoteVersion -replace '^^1\.8\.0_', '8.0.' -replace '[\+-].*$', ''
    echo if ^($localVersion -eq "UNKNOWN" -or $remoteVersion -eq "UNKNOWN"^) {
    echo     Write-Output "RESULT|UNKNOWN"
    echo } elseif ^($cleanLocal -eq $cleanRemote^) {
    echo     Write-Output "RESULT|UP_TO_DATE"
    echo } else {
    echo     Write-Output "RESULT|UPDATE_AVAILABLE"
    echo }
) > "!UPDATE_CHECKER_PS1!"

set "API_ERROR="
for /f "tokens=1,* delims=|" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!UPDATE_CHECKER_PS1!" -Vendor "!UP_VENDOR!" -Major "!UP_MAJOR!" -LocalPath "!UP_PATH!"') do (
    if "%%A"=="ORACLE_LEGACY" goto :Update_OracleLegacy
    if "%%A"=="LOCAL" set "LOCAL_VER=%%B"
    if "%%A"=="REMOTE" set "REMOTE_VER=%%B"
    if "%%A"=="RESULT" set "UPDATE_RESULT=%%B"
    if "%%A"=="ERROR" set "API_ERROR=%%B"
)
if exist "!UPDATE_CHECKER_PS1!" del "!UPDATE_CHECKER_PS1!"

if defined API_ERROR (
    echo %cRED%[ ERROR  ]%cRESET% Network connection failed. You appear to be offline.
    echo %cYELLOW%[ DETAIL ]%cRESET% !API_ERROR!
    goto :eof
)

echo %cBLUE%[  INFO  ]%cRESET% Local Build Version : !LOCAL_VER!
echo %cBLUE%[  INFO  ]%cRESET% Remote API Version  : !REMOTE_VER!

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
    choice /C yn /N /M "Would you like to download and install this update? (y/N): "
    if !errorlevel! NEQ 1 goto :eof
)
goto :TriggerUpdateDownload

:Update_OracleLegacy
set "PS_CMD=$req = [Net.HttpWebRequest]::Create('https://download.oracle.com/java/!UP_MAJOR!/latest/jdk-!UP_MAJOR!_windows-!SYS_ARCH!_bin.zip'); $req.Method = 'HEAD'; try { $res = $req.GetResponse(); $res.LastModified.ToString('yyyy-MM-dd') } catch { 'ERROR|' + $_.Exception.Message }"
set "REMOTE_DATE=UNKNOWN" & set "API_ERROR="
for /f "tokens=1,* delims=|" %%A in ('powershell -NoProfile -Command "!PS_CMD!"') do (
    if "%%A"=="ERROR" ( set "API_ERROR=%%B" ) else ( set "REMOTE_DATE=%%A" )
)
if defined API_ERROR (
    echo %cRED%[ ERROR  ]%cRESET% Network connection failed. You appear to be offline.
    echo %cYELLOW%[ DETAIL ]%cRESET% !API_ERROR!
    goto :eof
)
set "LOCAL_DATE=UNKNOWN"
if exist "!UP_PATH!\release" (
    for /f "tokens=2 delims==" %%A in ('findstr "JAVA_VERSION_DATE" "!UP_PATH!\release"') do set "LOCAL_DATE=%%~A"
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
    choice /C yn /N /M "Would you like to download and install this update? (y/N): "
    if !errorlevel! NEQ 1 goto :eof
)

:TriggerUpdateDownload
set "VENDOR_SUPPORTED="
for %%V in (Oracle Adoptium GraalVM Corretto Zulu Microsoft Liberica Semeru) do (
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
    if "!u_choice!"=="" goto :UninstallJDK
    set "u_choice=!u_choice: =!"
    set "NUM_TEST=" & for /f "delims=0123456789" %%A in (""!u_choice!"") do set "NUM_TEST=%%A"
    if defined NUM_TEST goto :UninstallJDK
    if !u_choice! LSS 1 goto :UninstallJDK
    if !u_choice! GTR !U_CANCEL! goto :UninstallJDK
) else (
    set "U_CHOICE_KEYS="
    for /l %%k in (1,1,!U_CANCEL!) do set "U_CHOICE_KEYS=!U_CHOICE_KEYS!%%k"
    choice /C !U_CHOICE_KEYS! /N /M "Enter your choice (1-!U_CANCEL!): "
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
choice /C yn /N /M "Are you sure you want to proceed? (y/N): "
if !errorlevel! NEQ 1 (
    echo.
    echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled. Returning to menu...
    timeout /t 2 >nul
    goto :eof
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Terminating Java processes running from this JDK...
powershell -NoProfile -Command "Get-Process java,javaw -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($env:DEL_PATH, [StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1

echo %cBLUE%[ ACTION ]%cRESET% Deleting directory and scrubbing environment variables...
echo %cBLUE%[  INFO  ]%cRESET% Requesting administrative privileges to apply changes...
set "SAFE_DEL_PATH=!DEL_PATH:'=''!"
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -WindowStyle Hidden -Wait -ArgumentList @('-NoProfile', '-Command', '$del = ''!SAFE_DEL_PATH!''; Get-Process java,javaw -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($del, [StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force -ErrorAction SilentlyContinue; if (Test-Path -LiteralPath $del) { Remove-Item -LiteralPath $del -Recurse -Force -ErrorAction SilentlyContinue }; $delBin = Join-Path $del ''bin''; $p = [Environment]::GetEnvironmentVariable(''Path'', ''Machine''); if ($p) { $clean = ($p -split '';'' | Where-Object { $_ -and $_.TrimEnd(''\'') -ne $delBin.TrimEnd(''\'') }) -join '';''; [Environment]::SetEnvironmentVariable(''Path'', $clean, ''Machine'') }')"
if not exist "%LOCALAPPDATA%\DiamTek\JVM\current\bin\java.exe" (
    if exist "%LOCALAPPDATA%\DiamTek\JVM\current" rmdir "%LOCALAPPDATA%\DiamTek\JVM\current" >nul 2>&1
    reg delete "HKCU\Environment" /v JAVA_HOME /f >nul 2>&1
)

if exist "!DEL_PATH!" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to completely delete directory.
    echo             A file might be locked or in use by another program.
    pause
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
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    set "USER_PATH=%%B"
)

if defined USER_PATH (
    set "CLEAN_USER_PATH=!USER_PATH:"=!"
    set "TEST_PATH=;!CLEAN_USER_PATH!;"
    for %%D in ("!SCRIPT_DIR!") do (
        if "!TEST_PATH:;%%~D;=!" NEQ "!TEST_PATH!" set "IN_PATH=1"
    )
)

set "HOOK_IN_PROFILE=0"
for /f "delims=" %%P in ('powershell -NoProfile -Command "$userProfile = [Environment]::GetFolderPath('UserProfile'); $myDocs = [Environment]::GetFolderPath('MyDocuments'); $docPaths = @($myDocs, (Join-Path $userProfile 'Documents')) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique; $p = @($PROFILE); foreach ($doc in $docPaths) { $p += (Join-Path $doc 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'); $p += (Join-Path $doc 'PowerShell\Microsoft.PowerShell_profile.ps1') }; foreach ($f in ($p | Select-Object -Unique)) { if ($f -and (Test-Path $f) -and (Select-String -Path $f -Pattern '# >>> jvm >>>' -Quiet)) { Write-Output 'FOUND'; break } }" 2^>nul') do (
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

choice /C 1234567 /N /M "Enter your choice (1-7): "
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
    if /i "!UPDATE_CHANNEL!"=="NIGHTLY" (
        set "UPDATE_CHANNEL=STABLE"
        set "CH_NAME=%cGREEN%[Stable]%cRESET%"
    ) else (
        set "UPDATE_CHANNEL=NIGHTLY"
        set "CH_NAME=%cPURPLE%[Nightly]%cRESET%"
    )
    if not exist "%LOCALAPPDATA%\DiamTek\JVM" mkdir "%LOCALAPPDATA%\DiamTek\JVM"
    > "%LOCALAPPDATA%\DiamTek\JVM\channel.txt" echo !UPDATE_CHANNEL!
    echo.
    echo %cGREEN%[   OK   ]%cRESET% Switched update channel to !CH_NAME!.
    timeout /t 2 >nul
    goto SettingsMenu
)
if !sub_choice!==3 (
    if /i "!SWITCH_MODE!"=="DIRECT" (
        set "SWITCH_MODE=SYMLINK"
        echo.
        echo %cBLUE%[ ACTION ]%cRESET% Scrubbing Machine Registry to prevent Legacy override...
        set "SYS_PATH="
        for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
        
        set PURGE_PATHS="C:\Program Files\Common Files\Oracle\Java\javapath" "C:\Program Files (x86)\Common Files\Oracle\Java\javapath" "C:\ProgramData\Oracle\Java\javapath"
        for /l %%k in (1,1,!JDK_COUNT!) do set PURGE_PATHS=!PURGE_PATHS! "!JDK_PATH_%%k!\bin"
        
        if defined SYS_PATH (
            set "PS_CMD=$p = $env:SYS_PATH -split ';'; $r = @(); foreach ($d in $p) { if ($d -ne ''"
            for %%P in (!PURGE_PATHS!) do (
                set "PS_CMD=!PS_CMD! -and $d -ne '%%~P'"
            )
            set "PS_CMD=!PS_CMD!) { $r += $d } }; $r -join ';'"
            for /f "delims=" %%A in ('powershell -NoProfile -Command "!PS_CMD!"') do set "SYS_PATH=%%A"
        )
        set "SAFE_SYS_PATH=!SYS_PATH:'=''!"
        
        powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -WindowStyle Hidden -Wait -ArgumentList @('-NoProfile', '-Command', '[Environment]::SetEnvironmentVariable(''JAVA_HOME'', $null, ''Machine''); [Environment]::SetEnvironmentVariable(''Path'', ''!SAFE_SYS_PATH!'', ''Machine'')')" 2>nul
    ) else (
        set "SWITCH_MODE=DIRECT"
    )
    if not exist "%LOCALAPPDATA%\DiamTek\JVM" mkdir "%LOCALAPPDATA%\DiamTek\JVM"
    echo !SWITCH_MODE!> "%LOCALAPPDATA%\DiamTek\JVM\mode.txt"
    echo.
    echo %cGREEN%[   OK   ]%cRESET% Switched mode to !SWITCH_MODE!.
    timeout /t 2 >nul
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
choice /C yn /N /M "Are you sure you want to proceed? (y/N): "
if errorlevel 2 goto :eof

echo.

rem Offload string manipulation to PowerShell to prevent delayed expansion corruption of exclamation marks
set "SAFE_TARGET=!SCRIPT_DIR!"
powershell -NoProfile -Command "$p = (Get-ItemProperty -Path 'HKCU:\Environment' -Name 'Path').Path; if ($p) { $clean = ($p -split ';' | Where-Object { $_ -and $_ -ne $env:SAFE_TARGET }) -join ';'; Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $clean -Type ExpandString }"

if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Registry write failed. Run as Administrator.
) else (
    powershell -NoProfile -Command "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Env { [DllImport(\"user32.dll\", SetLastError=true, CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult); }'; $res = [IntPtr]::Zero; [Env]::SendMessageTimeout([IntPtr]0xFFFF, 0x001A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$res) | Out-Null"
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
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    set "USER_PATH=%%B"
)

set "ALREADY_INSTALLED=0"
if defined USER_PATH (
    set "CLEAN_USER_PATH=!USER_PATH:"=!"
    set "TEST_PATH=;!CLEAN_USER_PATH!;"
    for %%D in ("!SCRIPT_DIR!") do (
        if "!TEST_PATH:;%%~D;=!" NEQ "!TEST_PATH!" set "ALREADY_INSTALLED=1"
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
echo %cBLUE%[  INFO  ]%cRESET% Target: !SCRIPT_DIR!
echo %cBLUE%[  INFO  ]%cRESET% Adding JVM directory to your User PATH.
choice /C yn /N /M "Are you sure you want to proceed? (y/N): "
if errorlevel 2 goto :eof

echo.

set "SAFE_TARGET=!SCRIPT_DIR!"
powershell -NoProfile -Command "$p = (Get-ItemProperty -Path 'HKCU:\Environment' -Name 'Path').Path; $newPath = if ($p) { $p.TrimEnd(';') + ';' + $env:SAFE_TARGET } else { $env:SAFE_TARGET }; Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $newPath -Type ExpandString"

if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Registry write failed. Run as Administrator.
) else (
    powershell -NoProfile -Command "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Env { [DllImport(\"user32.dll\", SetLastError=true, CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult); }'; $res = [IntPtr]::Zero; [Env]::SendMessageTimeout([IntPtr]0xFFFF, 0x001A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$res) | Out-Null"
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
for /f "tokens=2 delims=:" %%A in ('chcp 2^>nul') do set "ORIG_HOOK_CP=%%A"
chcp 65001 >nul

set "SAFE_TARGET=!SCRIPT_DIR!"
set "INSTALL_PS1=%TEMP%\jvm_setup_hook_!RANDOM!.ps1"
(
    echo $targetBat = Join-Path $env:SAFE_TARGET 'jvm.bat'
    echo $hook = @'
    echo(# ^>^>^> jvm ^>^>^>
    echo(function jvm {
    echo(    $bat = Get-Command jvm.bat -CommandType Application -ErrorAction SilentlyContinue ^| Select-Object -ExpandProperty Source -First 1
    echo(    if ^(-not $bat^) { $bat = '__FALLBACK_BAT__' }
    echo(    ^& $bat @args
    echo(
    echo(    function Set-JvmVar {
    echo(        param^([string]$Name, [string]$OldValue, [string]$NewValue^)
    echo(
    echo(        if ^($OldValue^) { $OldValue = $OldValue.TrimEnd^('\'^) }
    echo(        if ^($NewValue^) { $NewValue = $NewValue.TrimEnd^('\'^) }
    echo(
    echo(        [Environment]::SetEnvironmentVariable^($Name, $NewValue, 'Process'^)
    echo(
    echo(        $parts = $env:Path -split ';' ^| Where-Object { $_ -ne '' }
    echo(        if ^(-not [string]::IsNullOrWhiteSpace^($OldValue^)^) {
    echo(            $parts = $parts ^| Where-Object { $_.TrimEnd^('\'^) -ne "$OldValue\bin" }
    echo(        }
    echo(        if ^(-not [string]::IsNullOrWhiteSpace^($NewValue^)^) {
    echo(            $parts = $parts ^| Where-Object { $_.TrimEnd^('\'^) -ne "$NewValue\bin" }
    echo(            $parts = @^("$NewValue\bin"^) + $parts
    echo(        }
    echo(        $env:Path = $parts -join ';'
    echo(    }
    echo(
    echo(    $sessionFile = "$env:TEMP\.jvm_session_target"
    echo(    if ^(Test-Path $sessionFile^) {
    echo(        foreach ^($line in ^(Get-Content $sessionFile^)^) {
    echo(            if ^([string]::IsNullOrWhiteSpace^($line^)^) { continue }
    echo(            if ^($line -match '^^^([^^=]+^)=^(.*^)$'^) {
    echo(                $key = $matches[1]
    echo(                $val = $matches[2]
    echo(            } else {
    echo(                $key = 'JAVA_HOME'
    echo(                $val = $line
    echo(            }
    echo(            $old = [Environment]::GetEnvironmentVariable^($key, 'Process'^)
    echo(            Set-JvmVar -Name $key -OldValue $old -NewValue $val
    echo(        }
    echo(        Remove-Item $sessionFile -Force
    echo(    } else {
    echo(        foreach ^($v in @^('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME'^)^) {
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
    echo(            'link', 'unlink', 'version', 'help', 'channel'
    echo(        ^)
    echo(        $candidates = @^('java', 'maven', 'gradle', 'kotlin', 'scala', 'groovy'^)
    echo(        $vendors = @^('adoptium', 'temurin', 'oracle', 'corretto', 'zulu', 'microsoft', 'graalvm', 'liberica', 'bellsoft', 'semeru', 'ibm', 'openj9'^)
    echo(        $openTargets = @^('home', 'dir', 'bin', 'config', 'cache', 'downloads', 'backup', 'backups', 'links'^)
    echo(        $hookTargets = @^('install', 'status', 'check', 'remove', 'uninstall'^)
    echo(        $flags = @^(
    echo(            '--vendor', '--symlink', '--registry', '--legacy', '--session', '--global',
    echo(            '--skip-checksum', '--no-verify', '--latest', '--yes', '-y', '--no-color',
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
    echo $hook = $hook.Replace^('__FALLBACK_BAT__', $targetBat^)
    echo $userProfile = [Environment]::GetFolderPath^('UserProfile'^)
    echo $myDocs = [Environment]::GetFolderPath^('MyDocuments'^)
    echo $docPaths = @^($myDocs, ^(Join-Path $userProfile 'Documents'^)^) ^| Where-Object { $_ -and ^(Test-Path $_^) } ^| Select-Object -Unique
    echo $profiles = @^($PROFILE^)
    echo foreach ^($doc in $docPaths^) {
    echo     $profiles += ^(Join-Path $doc 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'^)
    echo     $profiles += ^(Join-Path $doc 'PowerShell\Microsoft.PowerShell_profile.ps1'^)
    echo }
    echo $profiles = $profiles ^| Where-Object { $_ } ^| Select-Object -Unique
    echo $utf8 = New-Object System.Text.UTF8Encoding^($true^)
    echo foreach ^($p in $profiles^) {
    echo     if ^([string]::IsNullOrWhiteSpace^($p^)^) { continue }
    echo     $profileDir = Split-Path $p
    echo     if ^(-not ^(Test-Path $profileDir^)^) { New-Item -ItemType Directory -Path $profileDir -Force ^| Out-Null }
    echo     $profContent = ''
    echo     if ^(Test-Path $p^) { $profContent = [System.IO.File]::ReadAllText^($p, [System.Text.Encoding]::UTF8^) }
    echo     $blockPattern = '^(?s^)# ^>^>^> jvm ^>^>^>.*?# ^<^<^< jvm ^<^<^<'
    echo     $m = [Regex]::Match^($profContent, $blockPattern^)
    echo     if ^($m.Success^) {
    echo         $profContent = $profContent.Substring^(0, $m.Index^) + $hook + $profContent.Substring^($m.Index + $m.Length^)
    echo     } else {
    echo         $profContent = if ^([string]::IsNullOrWhiteSpace^($profContent^)^) { $hook } else { "$profContent`r`n`r`n$hook" }
    echo     }
    echo     [System.IO.File]::WriteAllText^($p, $profContent, $utf8^)
    echo     $esc = [char]27
    echo     Write-Host "$esc[92m[   OK   ]$esc[0m Hook configured in: $p"
    echo }
) > "!INSTALL_PS1!"

powershell -NoProfile -ExecutionPolicy Bypass -File "!INSTALL_PS1!"
if exist "!INSTALL_PS1!" del "!INSTALL_PS1!" >nul 2>&1
if defined ORIG_HOOK_CP chcp !ORIG_HOOK_CP! >nul

echo.
echo %cGREEN%[   OK   ]%cRESET% PowerShell profile hook successfully configured.
echo %cBLUE%[  INFO  ]%cRESET% Environment variables and PATH will now sync seamlessly across all PowerShell tabs.
echo %cBLUE%[  HINT  ]%cRESET% Run '. $PROFILE' or restart your terminal to activate completions immediately.
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

set "REMOVE_PS1=%TEMP%\jvm_remove_hook_!RANDOM!.ps1"
(
    echo $userProfile = [Environment]::GetFolderPath^('UserProfile'^)
    echo $myDocs = [Environment]::GetFolderPath^('MyDocuments'^)
    echo $docPaths = @^($myDocs, ^(Join-Path $userProfile 'Documents'^)^) ^| Where-Object { $_ -and ^(Test-Path $_^) } ^| Select-Object -Unique
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
    echo         $c = [System.IO.File]::ReadAllText^($prof, [System.Text.Encoding]::UTF8^)
    echo         $m = [Regex]::Match^($c, '^(?s^)# ^>^>^> jvm ^>^>^>.*?# ^<^<^< jvm ^<^<^<'^)
    echo         if ^($m.Success^) {
    echo             $c = ^($c.Substring^(0, $m.Index^) + $c.Substring^($m.Index + $m.Length^)^).Trim^(^)
    echo             if ^([string]::IsNullOrWhiteSpace^($c^)^) {
    echo                 Remove-Item -LiteralPath $prof -Force
    echo                 Write-Host "$esc[92m[   OK   ]$esc[0m Cleaned empty profile: $prof"
    echo             } else {
    echo                 [System.IO.File]::WriteAllText^($prof, $c, $utf8^)
    echo                 Write-Host "$esc[92m[   OK   ]$esc[0m Removed hook from: $prof"
    echo             }
    echo         }
    echo     }
    echo }
) > "!REMOVE_PS1!"

powershell -NoProfile -ExecutionPolicy Bypass -File "!REMOVE_PS1!"
if exist "!REMOVE_PS1!" del "!REMOVE_PS1!" >nul 2>&1

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

set "STATUS_PS1=%TEMP%\jvm_status_hook_!RANDOM!.ps1"
(
    echo $userProfile = [Environment]::GetFolderPath^('UserProfile'^)
    echo $myDocs = [Environment]::GetFolderPath^('MyDocuments'^)
    echo $docPaths = @^($myDocs, ^(Join-Path $userProfile 'Documents'^)^) ^| Where-Object { $_ -and ^(Test-Path $_^) } ^| Select-Object -Unique
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
    echo         if ^(Select-String -Path $prof -Pattern '# ^>^>^> jvm ^>^>^>' -Quiet^) {
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

powershell -NoProfile -ExecutionPolicy Bypass -File "!STATUS_PS1!"
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
choice /C yn /N /M "Are you sure you want to proceed? (y/N): "
if errorlevel 2 (
    if defined CLI_COMMAND (
        if defined ORIG_CP chcp !ORIG_CP! >nul
        exit /b 0
    )
    goto :SettingsMenu
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Locating uninstaller...
set "UNINSTALL_SCRIPT="
if exist "!SCRIPT_DIR!\uninstall.ps1" set "UNINSTALL_SCRIPT=!SCRIPT_DIR!\uninstall.ps1"
if not defined UNINSTALL_SCRIPT if exist "!SCRIPT_DIR!\..\uninstall.ps1" set "UNINSTALL_SCRIPT=!SCRIPT_DIR!\..\uninstall.ps1"
if not defined UNINSTALL_SCRIPT if exist "%LOCALAPPDATA%\DiamTek\JVM\uninstall.ps1" set "UNINSTALL_SCRIPT=%LOCALAPPDATA%\DiamTek\JVM\uninstall.ps1"
if not defined UNINSTALL_SCRIPT if exist "%LOCALAPPDATA%\DiamTek\JVM\bin\uninstall.ps1" set "UNINSTALL_SCRIPT=%LOCALAPPDATA%\DiamTek\JVM\bin\uninstall.ps1"

if not defined UNINSTALL_SCRIPT (
    echo %cBLUE%[ ACTION ]%cRESET% Downloading latest uninstall.ps1...
    set "UNINSTALL_SCRIPT=%TEMP%\jvm_uninstall_!RANDOM!.ps1"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; $f = '!UNINSTALL_SCRIPT!'; try { Invoke-WebRequest -Uri 'https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/contents/uninstall.ps1?ref=HEAD' -Headers @{ 'Accept'='application/vnd.github.v3.raw'; 'Cache-Control'='no-cache'; 'Pragma'='no-cache' } -UserAgent 'DiamTek-JVM' -OutFile $f -UseBasicParsing -TimeoutSec 5 } catch { try { Invoke-WebRequest -Uri ('https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/HEAD/uninstall.ps1?t=' + [DateTimeOffset]::UtcNow.Ticks) -Headers @{ 'Cache-Control'='no-cache'; 'Pragma'='no-cache' } -OutFile $f -UseBasicParsing -TimeoutSec 5 } catch {} }; if (Test-Path $f) { $txt = [System.IO.File]::ReadAllText($f); if ($txt.Length -lt 200 -or $txt -notmatch 'Java Version Manager - Uninstaller') { Remove-Item $f -Force -ErrorAction SilentlyContinue } }"
)

if not exist "!UNINSTALL_SCRIPT!" (
    echo %cRED%[ ERROR  ]%cRESET% Could not find or download uninstall.ps1!
    echo.
    echo Press any key to return...
    pause >nul
    if defined CLI_COMMAND (
        if defined ORIG_CP chcp !ORIG_CP! >nul
        exit /b 1
    )
    goto :SettingsMenu
)

rem Stage uninstaller to %TEMP% so the JVM directory is completely unlocked
set "RUNNER_PS1=%TEMP%\jvm_uninstall_runner_!RANDOM!.ps1"
copy /y "!UNINSTALL_SCRIPT!" "!RUNNER_PS1!" >nul 2>&1

rem Switch working directory to %TEMP% to release directory lock from cmd.exe
set "TARGET_UNINSTALL_DIR=!SCRIPT_DIR!"
cd /d "%TEMP%"

echo %cBLUE%[ ACTION ]%cRESET% Preparing uninstaller handoff engine...
set "UNINSTALL_BAT=%TEMP%\jvm_uninstall_!RANDOM!.bat"
(
    echo @echo off
    echo cd /d "%TEMP%"
    echo echo.
    echo powershell -NoProfile -ExecutionPolicy Bypass -File "!RUNNER_PS1!" -SourceDir "!TARGET_UNINSTALL_DIR!"
    echo if exist "!RUNNER_PS1!" del "!RUNNER_PS1!" ^>nul 2^>^&1
    echo if "!ORIG_CP!" NEQ "" chcp !ORIG_CP! ^>nul 2^>^&1
    echo ^(goto^) 2^>nul ^& del "%%~f0" ^>nul 2^>^&1 ^& exit /b 0
) > "!UNINSTALL_BAT!"

rem Pop all subroutine call frames and chain to external uninstaller in %TEMP%
rem This ensures jvm.bat is immediately closed and unlocked before powershell deletes it!
call :ChainUninstallerRunner "!UNINSTALL_BAT!"
exit /b 0

:ChainUninstallerRunner
cd /d "%TEMP%"
(goto) 2>nul & (goto) 2>nul & (goto) 2>nul & (goto) 2>nul & (goto) 2>nul & (goto) 2>nul & (goto) 2>nul & "%~1"
exit /b 0

:HANDLE_LINKS
setlocal enabledelayedexpansion
set "LINK_DIR=%LOCALAPPDATA%\JavaVersionManager\links"
if not exist "%LINK_DIR%" mkdir "%LINK_DIR%"

if /i "%~1"=="link" (
    if "%~2"=="" (
        echo.
        echo %cBLUE%[  INFO  ]%cRESET% Linked JDKs:
        echo ============================================================
        dir /ad /b "%LINK_DIR%" 2>nul | findstr "^" >nul
        if errorlevel 1 (
            echo                  No custom JDKs linked yet.
        ) else (
            for /d %%d in ("%LINK_DIR%\*") do (
                set "LINK_TARGET="
                for /f "tokens=1,2*" %%A in ('fsutil reparsepoint query "%%d" 2^>nul ^| findstr /i "Print Name:"') do set "LINK_TARGET=%%C"
                if not defined LINK_TARGET (
                    for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '%%d' -ErrorAction SilentlyContinue).Target" 2^>nul') do set "LINK_TARGET=%%A"
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
        exit /b 0
    )

    rem Resolve absolute path
    pushd "%~2" 2>nul
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% The directory "%~2" does not exist!
        exit /b 1
    )
    set "TARGET_PATH=!CD!"
    popd

    if not exist "!TARGET_PATH!\bin\java.exe" (
        echo %cRED%[ ERROR  ]%cRESET% Invalid JDK path. Could not find bin\java.exe inside !TARGET_PATH!
        exit /b 1
    )

    set "LINK_NAME=%~nx2"
    if "%~3" NEQ "" set "LINK_NAME=%~3"

    if exist "%LINK_DIR%\!LINK_NAME!" (
        echo %cRED%[ ERROR  ]%cRESET% A link named '!LINK_NAME!' already exists.
        exit /b 1
    )

    echo %cBLUE%[ ACTION ]%cRESET% Creating link '!LINK_NAME!' -^> !TARGET_PATH!
    mklink /J "%LINK_DIR%\!LINK_NAME!" "!TARGET_PATH!" >nul
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to create junction point.
        exit /b 1
    )
    echo %cGREEN%[   OK   ]%cRESET% Custom JDK linked successfully.
    exit /b 0
)

if /i "%~1"=="unlink" (
    if "%~2"=="" (
        echo %cRED%[ ERROR  ]%cRESET% Please specify a link name to remove.
        echo Usage: jvm unlink ^<name^>
        exit /b 1
    )
    if not exist "%LINK_DIR%\%~2" (
        echo %cRED%[ ERROR  ]%cRESET% Link '%~2' not found.
        exit /b 1
    )
    echo %cBLUE%[ ACTION ]%cRESET% Removing link '%~2'...
    rmdir "%LINK_DIR%\%~2"
    echo %cGREEN%[   OK   ]%cRESET% Link removed.
    exit /b 0
)

:CLI_DONE
if "!IS_ADMIN_RUN!"=="1" (
    echo.
    echo Press any key to close this window...
    pause >nul
)
goto :eof

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
echo   jvm install ^<candidate^> ^<ver^>  Download and install a tool or JDK ^(8 vendors supported^)
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
echo   --vendor ^<name^>                Filter or target vendor ^(oracle, adoptium, graalvm, corretto, zulu, ms, liberica, semeru^)
echo   --channel ^<name^>               Override update channel ^(stable or nightly^)
echo   --nightly, --stable            Shortcut flags to target update channel
echo   --symlink                      Force Symlink Mode ^(UAC-Free Directory Junction^)
echo   --legacy, --registry           Force Legacy Mode ^(System HKLM Registry, requires UAC^)
echo   --session                      Force True Session Isolation for the active terminal
echo   --global                       Force global system-wide switch
echo   --yes, -y                      Bypass interactive confirmation prompts
echo   --skip-checksum, --no-verify   Bypass checksum verification if hash is unavailable
echo   --no-color                     Disable ANSI colors ^(also respects NO_COLOR env^)
goto :eof

rem ============================================================
rem SHOW CURRENT STATUS / ENVIRONMENT
rem ============================================================
:ShowCurrentStatus
echo.
echo %cBLUE%[  INFO  ]%cRESET% Current JVM Environment Status:
echo ============================================================

set "CURR_JAVA_VER="
set "CURR_JAVA_BIN="
set "CURR_JAVA_VENDOR="

if defined JAVA_HOME (
    if exist "!JAVA_HOME!\release" (
        for /f "tokens=1,* delims==" %%A in ('type "!JAVA_HOME!\release" 2^>nul ^| findstr /i "^JAVA_VERSION= ^IMPLEMENTOR="') do (
            if /i "%%A"=="JAVA_VERSION" set "CURR_JAVA_VER=%%~B"
            if /i "%%A"=="IMPLEMENTOR" set "CURR_JAVA_VENDOR=%%~B"
        )
    )
    if exist "!JAVA_HOME!\bin\java.exe" (
        set "CURR_JAVA_BIN=!JAVA_HOME!\bin\java.exe"
    )
)

if not defined CURR_JAVA_BIN (
    for /f "delims=" %%A in ('where.exe java 2^>nul') do (
        if not defined CURR_JAVA_BIN set "CURR_JAVA_BIN=%%A"
    )
)

if not defined CURR_JAVA_VER (
    if defined CURR_JAVA_BIN (
        for /f "tokens=3" %%A in ('"!CURR_JAVA_BIN!" -version 2^>^&1 ^| findstr /i "version"') do (
            set "CURR_JAVA_VER=%%~A"
        )
    )
)

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
    set "JUNCTION_TARGET="
    if exist "%LOCALAPPDATA%\DiamTek\JVM\current" (
        for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item -LiteralPath '%LOCALAPPDATA%\DiamTek\JVM\current' -ErrorAction SilentlyContinue).Target" 2^>nul') do set "JUNCTION_TARGET=%%A"
    )
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
        set "C_NAME=%%~nxC"
        set "C_TARGET="
        if exist "%%C\current" (
            for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item -LiteralPath '%%C\current' -ErrorAction SilentlyContinue).Target" 2^>nul') do set "C_TARGET=%%A"
            if defined C_TARGET (
                set "ECO_FOUND=1"
                for /f "delims=" %%V in ("!C_TARGET!") do (
                    echo    - !C_NAME!:         %%~nxV %cGREEN%[ACTIVE]%cRESET%
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
echo.
echo %cBLUE%[ ACTION ]%cRESET% Scanning temporary files, installer archives, and cache...
set "FREED_MB=0"
set "FREED_COUNT=0"
set "CLEAN_CMD=$temp = [System.IO.Path]::GetTempPath(); $appdata = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'DiamTek\JVM'); $patterns = @((Join-Path $temp 'jdk_*_download.*'), (Join-Path $temp 'jdk_*_extract'), (Join-Path $temp 'jvm_dl_*.ps1'), (Join-Path $temp 'jvm_updater_*.bat'), (Join-Path $temp 'jvm_install_*.ps1'), (Join-Path $temp 'jvm_uninstall_*.bat'), (Join-Path $temp 'jvm_uninstall_*.ps1'), (Join-Path $temp '.jvm_session_target'), (Join-Path $appdata 'downloads\*'), (Join-Path $appdata 'candidates\*\temp_*')); $totalBytes = 0; $fileCount = 0; foreach ($p in $patterns) { Get-Item $p -ErrorAction SilentlyContinue | ForEach-Object { if ($_.PSIsContainer) { $subFiles = Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue; foreach ($sf in $subFiles) { $totalBytes += $sf.Length; $fileCount++ }; Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue } else { $totalBytes += $_.Length; $fileCount++; Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue } } }; $mb = [math]::Round($totalBytes / 1MB, 2); Write-Output ('FREED_MB=' + $mb); Write-Output ('FREED_COUNT=' + $fileCount)"
for /f "tokens=1,2 delims==" %%A in ('powershell -NoProfile -Command "!CLEAN_CMD!"') do (
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

if /i "!WHICH_TARGET!"=="java" (
    if defined JAVA_HOME (
        if exist "!JAVA_HOME!\bin\java.exe" (
            echo !JAVA_HOME!\bin\java.exe
            exit /b 0
        )
    )
    for /f "delims=" %%A in ('where.exe java 2^>nul') do (
        echo %%A
        exit /b 0
    )
    >&2 echo %cRED%[ ERROR  ]%cRESET% No java executable found in JAVA_HOME or PATH.
    exit /b 1
)

set "CAND_ROOT=%LOCALAPPDATA%\DiamTek\JVM\candidates\!WHICH_TARGET!\current\bin"
if exist "!CAND_ROOT!" (
    if /i "!WHICH_TARGET!"=="maven" (
        for /f "delims=" %%A in ('dir /b /s "!CAND_ROOT!\mvn.cmd" "!CAND_ROOT!\mvn.bat" 2^>nul') do (
            echo %%A
            exit /b 0
        )
    )
    if /i "!WHICH_TARGET!"=="kotlin" (
        for /f "delims=" %%A in ('dir /b /s "!CAND_ROOT!\kotlinc.bat" 2^>nul') do (
            echo %%A
            exit /b 0
        )
    )
    for /f "delims=" %%A in ('dir /b /s "!CAND_ROOT!\!WHICH_TARGET!*.exe" "!CAND_ROOT!\!WHICH_TARGET!*.bat" "!CAND_ROOT!\!WHICH_TARGET!*.cmd" 2^>nul') do (
        echo %%A
        exit /b 0
    )
    for /f "delims=" %%A in ('dir /b /s "!CAND_ROOT!\*.cmd" "!CAND_ROOT!\*.bat" "!CAND_ROOT!\*.exe" 2^>nul') do (
        echo %%A
        exit /b 0
    )
)
>&2 echo %cRED%[ ERROR  ]%cRESET% Candidate '!WHICH_TARGET!' is not installed or active.
exit /b 1

rem ============================================================
rem DOCTOR - SYSTEM HEALTH AUDIT & DIAGNOSTICS
rem ============================================================
:DoctorDiagnostics
echo.
echo %cBLUE%[ ACTION ]%cRESET% Running DiamTek JVM System Health Audit...
echo ============================================================

set "DOC_ISSUES=0"

rem 1. Storage Root & Permissions
set "DOC_APPDIR=%LOCALAPPDATA%\DiamTek\JVM"
if exist "!DOC_APPDIR!" (
    set "DOC_TESTFILE=!DOC_APPDIR!\.health_check_!RANDOM!"
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
        if exist "!DOC_JUNC!\bin\java.exe" (
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
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v JAVA_HOME 2^>nul') do set "HKCU_JH=%%B"
set "HKLM_JH="
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v JAVA_HOME 2^>nul') do set "HKLM_JH=%%B"

if defined HKCU_JH (
    echo %cGREEN%[   OK   ]%cRESET% User JAVA_HOME:      !HKCU_JH!
) else if defined HKLM_JH (
    echo %cBLUE%[  INFO  ]%cRESET% Machine JAVA_HOME:   !HKLM_JH!
) else (
    echo %cYELLOW%[ WARNING]%cRESET% JAVA_HOME:           Not set in User or Machine registry
    set /a DOC_ISSUES+=1
)

rem 4. PATH Precedence & Shadowing Check
set "FIRST_JAVA="
set "SHADOW_FOUND=0"
for /f "delims=" %%A in ('where.exe java 2^>nul') do (
    if not defined FIRST_JAVA (
        set "FIRST_JAVA=%%A"
        echo %%A | findstr /i "Common.Files\\Oracle\\Java\\javapath" >nul 2>&1 && set "SHADOW_FOUND=1"
        echo %%A | findstr /i "ProgramData\\Oracle\\Java\\javapath" >nul 2>&1 && set "SHADOW_FOUND=1"
        echo %%A | findstr /i "System32\\java.exe" >nul 2>&1 && set "SHADOW_FOUND=1"
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
for /f "delims=" %%P in ('powershell -NoProfile -Command "$userProfile = [Environment]::GetFolderPath('UserProfile'); $myDocs = [Environment]::GetFolderPath('MyDocuments'); $docPaths = @($myDocs, (Join-Path $userProfile 'Documents')) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique; $p = @($PROFILE); foreach ($doc in $docPaths) { $p += (Join-Path $doc 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'); $p += (Join-Path $doc 'PowerShell\Microsoft.PowerShell_profile.ps1') }; foreach ($f in ($p | Select-Object -Unique)) { if ($f -and (Test-Path $f) -and (Select-String -Path $f -Pattern '# >>> jvm >>>' -Quiet)) { Write-Output 'FOUND'; break } }" 2^>nul') do (
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
            if "!JDK_MAJOR_%%k!"=="!LATEST_LTS_NUM!" (
                if not defined FOUND_EXEC_JDK set "FOUND_EXEC_JDK=!JDK_PATH_%%k!"
            )
        )
    )
)

if not defined FOUND_EXEC_JDK (
    for /l %%k in (1,1,!JDK_COUNT!) do (
        if "!JDK_MAJOR_%%k!"=="!EXEC_TARGET!" (
            if not defined FOUND_EXEC_JDK set "FOUND_EXEC_JDK=!JDK_PATH_%%k!"
        )
        if /i "!JDK_NAME_%%k!"=="!EXEC_TARGET!" (
            if not defined FOUND_EXEC_JDK set "FOUND_EXEC_JDK=!JDK_PATH_%%k!"
        )
    )
)

if not defined FOUND_EXEC_JDK (
    for /l %%k in (1,1,!JDK_COUNT!) do (
        echo !JDK_PATH_%%k! | findstr /i "!EXEC_TARGET!" >nul 2>&1 && (
            if not defined FOUND_EXEC_JDK set "FOUND_EXEC_JDK=!JDK_PATH_%%k!"
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

call !EXEC_CMD!
set "EXEC_EXIT_CODE=!errorlevel!"
exit /b !EXEC_EXIT_CODE!

rem ============================================================
rem OPEN DIRECTORY IN FILE EXPLORER
rem ============================================================
:OpenFolderInExplorer
set "OPEN_PATH="
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

if not exist "!OPEN_PATH!" (
    echo.
    >&2 echo %cRED%[ ERROR  ]%cRESET% Target path does not exist: !OPEN_PATH!
    exit /b 1
)

echo %cBLUE%[ ACTION ]%cRESET% Opening File Explorer: !OPEN_PATH!
start "" explorer.exe "!OPEN_PATH!"
exit /b 0

rem ============================================================
rem JVM Version / About Menu
rem ============================================================
:AboutMenu
rem cls
set "CH_TAG=%cGREEN%[Stable]%cRESET%"
if /i "!UPDATE_CHANNEL!"=="NIGHTLY" set "CH_TAG=%cPURPLE%[Nightly]%cRESET%"
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
        choice /C yn /N /M "Would you like to download and install this update? (y/N): "
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
set "CH_TAG=%cGREEN%[Stable]%cRESET%"
if /i "!UPDATE_CHANNEL!"=="NIGHTLY" set "CH_TAG=%cPURPLE%[Nightly]%cRESET%"
if "!CLI_COMMAND!"=="self-update" if "!FORCE_YES!" NEQ "1" (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking for updates ^(!CH_TAG! channel^)...
    call :CheckUpdateStatus

    if "!UPDATE_FLAG!"=="ERROR" (
        echo %cRED%[ ERROR  ]%cRESET% Failed to connect to GitHub. Please check your internet connection.
        goto :eof
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
        goto :eof
    )
    if "!UPDATE_FLAG!"=="INVALID_REMOTE" (
        echo %cYELLOW%[ WARNING]%cRESET% Remote version '!REMOTE_VER!' is not a valid Semantic Version.
        goto :eof
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

set "INSTALL_SCRIPT=%TEMP%\jvm_install_!RANDOM!.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; $ref = '!REMOTE_REF!'; try { Invoke-WebRequest -Uri ('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/contents/install.ps1?ref=' + $ref) -Headers @{ 'Accept'='application/vnd.github.v3.raw'; 'Cache-Control'='no-cache'; 'Pragma'='no-cache' } -UserAgent 'DiamTek-JVM' -OutFile '!INSTALL_SCRIPT!' -UseBasicParsing -TimeoutSec 5 } catch { Invoke-WebRequest -Uri ('https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/' + $ref + '/install.ps1?t=' + [DateTimeOffset]::UtcNow.Ticks) -Headers @{ 'Cache-Control'='no-cache'; 'Pragma'='no-cache' } -OutFile '!INSTALL_SCRIPT!' -UseBasicParsing -TimeoutSec 5 }"

if not exist "!INSTALL_SCRIPT!" (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Failed to download the latest installer.
    pause
    goto :eof
)

echo %cBLUE%[ ACTION ]%cRESET% Verifying installer cryptographic integrity...
set "VERIFY_TMP=%TEMP%\jvm_sha_!RANDOM!.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; $ref = '!REMOTE_REF!'; $ch = '!UPDATE_CHANNEL!'; $f = '!INSTALL_SCRIPT!'; if (-not (Test-Path $f)) { Write-Output 'MISSING'; exit }; $txt = [System.IO.File]::ReadAllText($f); if ($txt.Length -lt 200 -or $txt -notmatch 'rem END OF SCRIPT|# Java Version Manager') { Write-Output 'TRUNCATED'; exit }; $actual = (Get-FileHash -Path $f -Algorithm SHA256).Hash.ToLower(); if ($ch -eq 'STABLE' -and $ref -match '^v?[0-9]') { $shaTxt = $null; try { $shaTxt = (Invoke-WebRequest -Uri ('https://github.com/DiamTek/Java-Version-Manager-Windows/releases/download/' + $ref + '/SHA256SUMS.txt') -Headers @{'Cache-Control'='no-cache'} -UserAgent 'DiamTek-JVM' -UseBasicParsing -TimeoutSec 5).Content } catch {}; if (-not $shaTxt) { try { $relJson = (Invoke-RestMethod -Uri ('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/releases/tags/' + $ref) -UserAgent 'DiamTek-JVM'); $asset = $relJson.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' } | Select-Object -First 1; if ($asset) { $shaTxt = (Invoke-WebRequest -Uri $asset.browser_download_url -UserAgent 'DiamTek-JVM' -UseBasicParsing -TimeoutSec 5).Content } } catch {} }; if ($shaTxt) { $exp = $null; foreach ($line in ($shaTxt -split '\r?\n')) { if ($line -match '^([0-9a-fA-F]{64})\s+[\*]?install\.ps1$') { $exp = $matches[1].ToLower(); break } }; if ($exp) { if ($actual -eq $exp) { Write-Output ('VERIFIED|' + $exp) } else { Write-Output ('MISMATCH|' + $exp + '|' + $actual) } } else { Write-Output ('NO_ENTRY|' + $actual) } } else { Write-Output ('NO_SHA_FILE|' + $actual) } } else { $shaTxt = $null; try { $shaTxt = (Invoke-WebRequest -Uri ('https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/' + $ref + '/SHA256SUMS.txt?t=' + [DateTimeOffset]::UtcNow.Ticks) -Headers @{'Cache-Control'='no-cache'} -UserAgent 'DiamTek-JVM' -UseBasicParsing -TimeoutSec 5).Content } catch {}; if ($shaTxt) { $exp = $null; foreach ($line in ($shaTxt -split '\r?\n')) { if ($line -match '^([0-9a-fA-F]{64})\s+[\*]?install\.ps1$') { $exp = $matches[1].ToLower(); break } }; if ($exp) { if ($actual -eq $exp) { Write-Output ('VERIFIED|' + $exp) } else { Write-Output ('MISMATCH|' + $exp + '|' + $actual) } } else { Write-Output ('NIGHTLY|' + $actual) } } else { Write-Output ('NIGHTLY|' + $actual) } }" > "!VERIFY_TMP!" 2>nul

set "SHA_STATUS=UNKNOWN"
set "SHA_EXP="
set "SHA_ACT="
if exist "!VERIFY_TMP!" (
    for /f "tokens=1,2,3 delims=|" %%A in (!VERIFY_TMP!) do (
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
        pause
        goto :eof
    )
    echo %cGREEN%[   OK   ]%cRESET% Cryptographic integrity verified ^(SHA-256: !SHA_EXP:~0,16!...^)
) else (
    if "!SHA_STATUS!"=="MISMATCH" (
        echo.
        echo %cRED%[ ERROR  ]%cRESET% Cryptographic integrity check failed for install.ps1!
        echo            Expected: !SHA_EXP!
        echo            Computed: !SHA_ACT!
        echo            Update aborted to prevent untrusted execution.
        if exist "!INSTALL_SCRIPT!" del "!INSTALL_SCRIPT!" >nul 2>&1
        pause
        goto :eof
    )
    if "!SHA_STATUS!"=="TRUNCATED" (
        echo.
        echo %cRED%[ ERROR  ]%cRESET% Downloaded installer is truncated or empty.
        echo            Update aborted to prevent untrusted execution.
        if exist "!INSTALL_SCRIPT!" del "!INSTALL_SCRIPT!" >nul 2>&1
        pause
        goto :eof
    )
    if "!SHA_STATUS!"=="VERIFIED" (
        echo %cGREEN%[   OK   ]%cRESET% Cryptographic integrity verified ^(SHA-256: !SHA_EXP:~0,16!...^)
    ) else (
        echo %cBLUE%[  INFO  ]%cRESET% Nightly build integrity hash ^(SHA-256: !SHA_EXP:~0,16!...^)
    )
)

echo %cBLUE%[ ACTION ]%cRESET% Preparing update handoff engine...
set "UPDATER_BAT=%TEMP%\jvm_updater_!RANDOM!.bat"
(
    echo @echo off
    echo for /F "delims=#" %%%%a in ^('"prompt #$E# ^& echo on ^& for %%%%b in ^(1^) do rem"'^) do set "ESC=%%%%a"
    echo set "cGREEN=%%ESC%%[92m"
    echo set "cRED=%%ESC%%[91m"
    echo set "cBLUE=%%ESC%%[96m"
    echo set "cRESET=%%ESC%%[0m"
    echo echo.
    echo powershell -NoProfile -ExecutionPolicy Bypass -File "!INSTALL_SCRIPT!" -Update -TargetDir "!SCRIPT_DIR!" -Branch "!REMOTE_REF!" -Channel "!UPDATE_CHANNEL!"
    echo set "UPD_ERR=%%errorlevel%%"
    echo if exist "!INSTALL_SCRIPT!" del "!INSTALL_SCRIPT!" ^>nul 2^>^&1
    echo if %%UPD_ERR%% NEQ 0 ^(
    echo     echo.
    echo     echo %%cRED%%[ ERROR  ]%%cRESET%% Update encountered an error.
    echo     pause
    echo     ^(goto^) 2^>nul ^& del "%%~f0"
    echo ^)
    echo echo.
    echo echo %%cGREEN%%[   OK   ]%%cRESET%% Java Version Manager successfully updated.
    echo echo.
    if defined CLI_COMMAND (
        echo ^(goto^) 2^>nul ^& del "%%~f0"
    ) else (
        echo echo Press any key to return to Java Version Manager...
        echo pause ^>nul
        echo cls
        echo "%~f0"
    )
) > "!UPDATER_BAT!"

rem Chain execution to external updater in %TEMP% so jvm.bat is immediately closed by cmd.exe!
"!UPDATER_BAT!"
exit /b 0

rem ============================================================
rem Query Remote Update Status Helper
rem ============================================================
:CheckUpdateStatus
set "PS_SCRIPT=$ProgressPreference = 'SilentlyContinue'; $localVer = [version]'!JVM_VERSION!'; $localBld = [version]'!JVM_BUILD!'; $channel = '!UPDATE_CHANNEL!'; if ($channel -eq 'STABLE') { $data = $null; $tagName = $null; try { $api = [Net.HttpWebRequest]::Create('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/releases/latest'); $api.UserAgent = 'DiamTek-JVM'; $api.Timeout = 3000; $apiRes = $api.GetResponse(); $sr = New-Object System.IO.StreamReader($apiRes.GetResponseStream()); $raw = $sr.ReadToEnd(); $sr.Close(); $apiRes.Close(); $data = $raw | ConvertFrom-Json; if ($data -and $data.tag_name) { $tagName = [string]$data.tag_name; } } catch { try { $req = [Net.HttpWebRequest]::Create('https://github.com/DiamTek/Java-Version-Manager-Windows/releases/latest'); $req.AllowAutoRedirect = $false; $req.UserAgent = 'DiamTek-JVM'; $req.Timeout = 3000; $res = $req.GetResponse(); $loc = $res.Headers['Location']; $res.Close(); if ($loc -match '/releases/tag/(.+)$') { $tagName = $matches[1]; } } catch [Net.WebException] { $resp = $_.Exception.Response; if ($resp -and ($resp.StatusCode -eq [Net.HttpStatusCode]::NotFound)) { Write-Output 'NONE|NONE|NO_STABLE_RELEASE|NONE'; exit; } } catch {} }; if (-not $tagName) { Write-Output 'NONE|NONE|NO_STABLE_RELEASE|NONE'; exit; }; $tagVerStr = $null; if ($tagName -match '^v?([0-9]+(\.[0-9]+)+)') { $tagVerStr = $matches[1]; } elseif ($tagName -match '^v?([0-9]+)') { $tagVerStr = $matches[1] + '.0'; }; if (-not $tagVerStr) { Write-Output ($tagName + '|UNKNOWN|INVALID_REMOTE|' + $tagName); exit; }; try { $remoteVer = [version]$tagVerStr; } catch { Write-Output ($tagVerStr + '|UNKNOWN|INVALID_REMOTE|' + $tagName); exit; }; $remBuild = $null; $remBldStr = 'N/A'; try { $rawUrl = 'https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/' + $tagName + '/jvm.bat?t=' + [DateTimeOffset]::UtcNow.Ticks; $req = [Net.HttpWebRequest]::Create($rawUrl); $req.Timeout = 3000; $req.UserAgent = 'DiamTek-JVM'; $res = $req.GetResponse(); $sr = New-Object System.IO.StreamReader($res.GetResponseStream()); $c = $sr.ReadToEnd(); $sr.Close(); $res.Close(); if ($c -match 'set \x22JVM_BUILD=(.*?)\x22') { $remBuild = [version]$matches[1]; $remBldStr = $matches[1]; } } catch {}; if ($remoteVer -gt $localVer) { Write-Output ($tagVerStr + '|' + $remBldStr + '|UPDATE|' + $tagName); } elseif ($remoteVer -lt $localVer) { Write-Output ($tagVerStr + '|' + $remBldStr + '|AHEAD_OF_STABLE|' + $tagName); } else { if ($remBuild) { if ($remBuild -gt $localBld) { Write-Output ($tagVerStr + '|' + $remBldStr + '|UPDATE|' + $tagName); } elseif ($remBuild -lt $localBld) { Write-Output ($tagVerStr + '|' + $remBldStr + '|AHEAD_OF_STABLE|' + $tagName); } else { Write-Output ($tagVerStr + '|' + $remBldStr + '|OK|' + $tagName); } } else { Write-Output ($tagVerStr + '|' + $remBldStr + '|OK|' + $tagName); } } } else { $commitSha = 'main'; try { $api = [Net.HttpWebRequest]::Create('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/commits/main'); $api.UserAgent = 'DiamTek-JVM'; $api.Timeout = 3000; $apiRes = $api.GetResponse(); $sr = New-Object System.IO.StreamReader($apiRes.GetResponseStream()); $raw = $sr.ReadToEnd(); $sr.Close(); $apiRes.Close(); $cData = $raw | ConvertFrom-Json; if ($cData -and $cData.sha) { $commitSha = $cData.sha.Substring(0, 7); } } catch { $commitSha = 'main'; }; $content = $null; try { $req = [Net.HttpWebRequest]::Create('https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/jvm.bat?t=' + [DateTimeOffset]::UtcNow.Ticks); $req.Method = 'GET'; $req.Timeout = 4000; $req.UserAgent = 'DiamTek-JVM'; $req.Headers.Add('Cache-Control', 'no-cache'); $req.Headers.Add('Pragma', 'no-cache'); $res = $req.GetResponse(); $sr = New-Object System.IO.StreamReader($res.GetResponseStream()); $content = $sr.ReadToEnd(); $sr.Close(); $res.Close(); } catch { try { $apiReq = [Net.HttpWebRequest]::Create('https://api.github.com/repos/DiamTek/Java-Version-Manager-Windows/contents/jvm.bat?ref=main'); $apiReq.Method = 'GET'; $apiReq.Timeout = 4000; $apiReq.UserAgent = 'DiamTek-JVM'; $apiReq.Accept = 'application/vnd.github.v3.raw'; $apiReq.Headers.Add('Cache-Control', 'no-cache'); $apiReq.Headers.Add('Pragma', 'no-cache'); $apiRes = $apiReq.GetResponse(); $sr = New-Object System.IO.StreamReader($apiRes.GetResponseStream()); $content = $sr.ReadToEnd(); $sr.Close(); $apiRes.Close(); } catch {} }; if (-not $content) { Write-Output 'UNKNOWN|UNKNOWN|ERROR|main'; exit; }; $remVerStr = '1.0.0'; $remBldStr = 'UNKNOWN'; if ($content -match 'set \x22JVM_VERSION=(.*?)\x22') { $remVerStr = $matches[1]; }; if ($content -match 'set \x22JVM_BUILD=(.*?)\x22') { $remBldStr = $matches[1]; }; try { $remoteVer = [version]$remVerStr; $remoteBld = [version]$remBldStr; if ($remoteVer -gt $localVer) { Write-Output ($remVerStr + '|' + $remBldStr + '|UPDATE|' + $commitSha); } elseif ($remoteVer -lt $localVer) { Write-Output ($remVerStr + '|' + $remBldStr + '|AHEAD_OF_NIGHTLY|' + $commitSha); } else { if ($remoteBld -gt $localBld) { Write-Output ($remVerStr + '|' + $remBldStr + '|UPDATE|' + $commitSha); } elseif ($remoteBld -lt $localBld) { Write-Output ($remVerStr + '|' + $remBldStr + '|AHEAD_OF_NIGHTLY|' + $commitSha); } else { Write-Output ($remVerStr + '|' + $remBldStr + '|OK|' + $commitSha); } } } catch { Write-Output ($remVerStr + '|' + $remBldStr + '|INVALID_REMOTE|' + $commitSha); } }
set "REMOTE_TMP=%TEMP%\jvm_remote_build_!RANDOM!.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "!PS_SCRIPT!" > "!REMOTE_TMP!" 2>nul
set "REMOTE_VER=UNKNOWN"
set "REMOTE_BUILD=UNKNOWN"
set "UPDATE_FLAG=ERROR"
set "REMOTE_REF=HEAD"
if exist "!REMOTE_TMP!" (
    for /f "tokens=1,2,3,4 delims=|" %%A in (!REMOTE_TMP!) do (
        set "REMOTE_VER=%%A"
        set "REMOTE_BUILD=%%B"
        set "UPDATE_FLAG=%%C"
        set "REMOTE_REF=%%D"
    )
    del "!REMOTE_TMP!" >nul 2>&1
)
exit /b 0

rem ============================================================
rem Parse contents of .java-version file
rem ============================================================
:ParseJavaVersion
if "%~1"=="" exit /b 0
set "CLI_TARGET=%~1"
shift
:PARSE_JV_LOOP
if "%~1"=="" exit /b 0
if /i "%~1"=="--vendor" (
    set "CLI_VENDOR=%~2"
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
    set "SWITCH_MODE_OVERRIDE=DIRECT"
    shift
    goto PARSE_JV_LOOP
)
if /i "%~1"=="--registry" (
    set "SWITCH_MODE_OVERRIDE=DIRECT"
    shift
    goto PARSE_JV_LOOP
)
shift
goto PARSE_JV_LOOP

rem ============================================================
rem Hijack SDKMAN configuration file
rem ============================================================
:ParseSdkmanrc
if "%~1"=="" exit /b 0
for /f "tokens=1,2 delims=-" %%V in ("%~1") do (
    for /f "tokens=1 delims=." %%M in ("%%V") do set "CLI_TARGET=%%M"
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
)
exit /b 0
rem ============================================================
rem Universal Candidate Engine
rem ============================================================
:RouteEcosystemCandidate
if /i "!CLI_COMMAND!"=="install" (
    call :InstallCandidate
    exit /b 0
)
if /i "!CLI_COMMAND!"=="uninstall" (
    call :UninstallCandidate
    exit /b 0
)
if /i "!CLI_COMMAND!"=="which" (
    call :WhichBinary
    exit /b !errorlevel!
)
if /i "!CLI_COMMAND!"=="open" (
    call :OpenFolderInExplorer
    exit /b !errorlevel!
)
if /i "!CLI_COMMAND!"=="" (
    if defined CLI_TARGET (
        call :SwitchCandidate "!CLI_TARGET!"
        exit /b 0
    )
)
echo %cRED%[ ERROR  ]%cRESET% Unknown command for !TARGET_CANDIDATE!
exit /b 1

:GetCandidateEnvVar
if /i "!TARGET_CANDIDATE!"=="maven" ( set "CANDIDATE_ENV_VAR=MAVEN_HOME" & set "CANDIDATE_PROPER_NAME=Maven" )
if /i "!TARGET_CANDIDATE!"=="gradle" ( set "CANDIDATE_ENV_VAR=GRADLE_HOME" & set "CANDIDATE_PROPER_NAME=Gradle" )
if /i "!TARGET_CANDIDATE!"=="kotlin" ( set "CANDIDATE_ENV_VAR=KOTLIN_HOME" & set "CANDIDATE_PROPER_NAME=Kotlin" )
if /i "!TARGET_CANDIDATE!"=="scala" ( set "CANDIDATE_ENV_VAR=SCALA_HOME" & set "CANDIDATE_PROPER_NAME=Scala" )
if /i "!TARGET_CANDIDATE!"=="groovy" ( set "CANDIDATE_ENV_VAR=GROOVY_HOME" & set "CANDIDATE_PROPER_NAME=Groovy" )
exit /b 0

:SwitchCandidate
set "TARGET_VER=%~1"
call :GetCandidateEnvVar
set "CANDIDATE_DIR=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!"

if /i "!TARGET_VER!"=="latest" (
    if exist "!CANDIDATE_DIR!" (
        for /f "delims=" %%V in ('powershell -NoProfile -Command "Get-ChildItem -Path '!CANDIDATE_DIR!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { [version]($_.Name -replace '-.*','') } -Descending | Select-Object -First 1 -ExpandProperty Name" 2^>nul') do (
            set "TARGET_VER=%%V"
        )
    )
)

set "TARGET_PATH=!CANDIDATE_DIR!\!TARGET_VER!"

if not exist "!TARGET_PATH!" (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% !CANDIDATE_PROPER_NAME! version !TARGET_VER! is not installed.
    exit /b 1
)

set "SYMLINK_PATH=!CANDIDATE_DIR!\current"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Activating !CANDIDATE_PROPER_NAME! !TARGET_VER!...

if exist "!SYMLINK_PATH!" rmdir "!SYMLINK_PATH!" >nul 2>&1
mklink /j "!SYMLINK_PATH!" "!TARGET_PATH!" >nul 2>&1
echo            - Updating Directory Junction...

powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable($env:CANDIDATE_ENV_VAR, $env:SYMLINK_PATH, 'User')"

rem Update user PATH to ensure %CANDIDATE_ENV_VAR%\bin is present
set "HAS_CANDIDATE_PATH=0"
set "USR_PATH="
for /f "tokens=2*" %%P in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    set "USR_PATH=%%Q"
)

echo(!USR_PATH! | findstr /i "%%!CANDIDATE_ENV_VAR!%%\bin" >nul
if !errorlevel!==0 set "HAS_CANDIDATE_PATH=1"

if "!HAS_CANDIDATE_PATH!"=="0" (
    set "NEW_PATH=%%!CANDIDATE_ENV_VAR!%%\bin;!USR_PATH!"
    powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('Path', $env:NEW_PATH, 'User')"
    if errorlevel 1 (
        reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
    )
    echo            - Injecting %%!CANDIDATE_ENV_VAR!%%\bin into PATH...
) else (
    echo            - Updating !CANDIDATE_ENV_VAR! variables...
)

rem Inject immediately into active terminal session
set "!CANDIDATE_ENV_VAR!=!SYMLINK_PATH!"
echo(!PATH! | findstr /i "!SYMLINK_PATH!\bin" >nul
if !errorlevel! NEQ 0 (
    set "PATH=!SYMLINK_PATH!\bin;!PATH!"
)

echo.
echo %cGREEN%[   OK   ]%cRESET% !CANDIDATE_PROPER_NAME! !TARGET_VER! is now active!
exit /b 0

:InstallCandidate
call :GetCandidateEnvVar
echo %cBLUE%[ ACTION ]%cRESET% Installing !CANDIDATE_PROPER_NAME!...

set "TARGET_VER=!CLI_TARGET!"
if not defined TARGET_VER set "TARGET_VER=latest"
if /i "!TARGET_VER!"=="latest" (
    echo %cBLUE%[ ACTION ]%cRESET% Resolving latest version of !CANDIDATE_PROPER_NAME!...
    call :ResolveLatestEcosystemCandidate
    set "TARGET_VER=!LATEST_VER!"
    
    if "!TARGET_VER!"=="ERROR" (
        echo %cRED%[ ERROR  ]%cRESET% Failed to resolve latest version of !CANDIDATE_PROPER_NAME!. Check your internet connection.
        exit /b 1
    )
    echo %cGREEN%[   OK   ]%cRESET% Latest version resolved to !TARGET_VER!.
)

rem Build the download URL
set "DOWNLOAD_URL="
set "CHECKSUM_URL="
set "CHECKSUM_TYPE="
if /i "!TARGET_CANDIDATE!"=="maven" (
    set "DOWNLOAD_URL=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/!TARGET_VER!/apache-maven-!TARGET_VER!-bin.zip"
    set "CHECKSUM_URL=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/!TARGET_VER!/apache-maven-!TARGET_VER!-bin.zip.sha512"
    set "CHECKSUM_TYPE=SHA512"
)
if /i "!TARGET_CANDIDATE!"=="gradle" (
    set "DOWNLOAD_URL=https://services.gradle.org/distributions/gradle-!TARGET_VER!-bin.zip"
    set "CHECKSUM_URL=https://services.gradle.org/distributions/gradle-!TARGET_VER!-bin.zip.sha256"
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
    set "CHECKSUM_TYPE=SHA256"
)

set "ZIP_DEST=%TEMP%\jvm_!TARGET_CANDIDATE!_!TARGET_VER!.zip"
set "EXTRACT_DEST=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!\!TARGET_VER!"
set "EXTRACT_DEST_TEMP=%TEMP%\jvm_!TARGET_CANDIDATE!_!TARGET_VER!_temp"

if exist "!EXTRACT_DEST!" (
    echo.
    echo %cYELLOW%[ WARNING]%cRESET% !CANDIDATE_PROPER_NAME! version !TARGET_VER! is already installed^^!
    echo.
    if "!FORCE_YES!"=="1" (
        echo %cBLUE%[  INFO  ]%cRESET% Reinstalling/overwriting due to --yes flag...
    ) else (
        choice /C yn /N /M "Would you like to reinstall and overwrite it? (y/N): "
        if !errorlevel! NEQ 1 (
            echo %cBLUE%[  INFO  ]%cRESET% Installation cancelled.
            exit /b 0
        )
    )
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Removing existing installation...
    rmdir /S /Q "!EXTRACT_DEST!" >nul 2>&1
)

if exist "!EXTRACT_DEST_TEMP!" rmdir /s /q "!EXTRACT_DEST_TEMP!"
mkdir "!EXTRACT_DEST_TEMP!" >nul 2>&1

rem Map variables to Universal Downloader
set "DL_URL=!DOWNLOAD_URL!"
set "DL_ZIP=!ZIP_DEST!"
set "DL_EXTRACT=!EXTRACT_DEST_TEMP!"
set "DL_CHKSUM_URL=!CHECKSUM_URL!"
set "DL_CHKSUM_VAL="
set "DL_CHKSUM_TYPE=!CHECKSUM_TYPE!"
set "DL_STRIP_ROOT=1"

if not exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!" mkdir "%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!"

call :ExecuteSharedDownloader
if !errorlevel! NEQ 0 (
    rmdir /S /Q "!EXTRACT_DEST_TEMP!" >nul 2>&1
    exit /b 1
)

move /Y "!EXTRACT_DEST_TEMP!" "!EXTRACT_DEST!" >nul 2>&1
echo.

echo %cGREEN%[   OK   ]%cRESET% Successfully installed !CANDIDATE_PROPER_NAME! !TARGET_VER!.

if not exist "%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!\current" (
    echo.
    echo %cBLUE%[  INFO  ]%cRESET% First installation detected. Auto-activating...
    call :SwitchCandidate "!TARGET_VER!"
)

if "!CLI_COMMAND!"=="" if "!IS_UPDATER!"=="" pause
exit /b 0

:UninstallCandidate
call :GetCandidateEnvVar
set "TARGET_VER=!CLI_TARGET!"
if "!TARGET_VER!"=="" (
    set "CANDIDATE_DIR=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!"
    if not exist "!CANDIDATE_DIR!" (
        echo %cRED%[ ERROR  ]%cRESET% No !CANDIDATE_PROPER_NAME! versions are installed.
        exit /b 1
    )
    set "VER_COUNT=0"
    set "SINGLE_VER="
    for /f "delims=" %%V in ('powershell -NoProfile -Command "Get-ChildItem -Path '!CANDIDATE_DIR!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { [version]($_.Name -replace '-.*','') } -Descending | Select-Object -ExpandProperty Name" 2^>nul') do (
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
        for /f "delims=" %%V in ('powershell -NoProfile -Command "Get-ChildItem -Path '!CANDIDATE_DIR!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { [version]($_.Name -replace '-.*','') } -Descending | Select-Object -ExpandProperty Name" 2^>nul') do (
            set /a IDX+=1
            set "VER_!IDX!=%%V"
            echo    !IDX!. %%V
        )
        echo.
        set /p "ver_choice=Select version to uninstall (1-!IDX!): "
        call set "TARGET_VER=%%VER_!ver_choice!%%"
        if not defined TARGET_VER (
            echo %cRED%[ ERROR  ]%cRESET% Invalid selection.
            exit /b 1
        )
    )
)

set "CANDIDATE_DIR=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!"

if /i "!TARGET_VER!"=="latest" (
    if exist "!CANDIDATE_DIR!" (
        for /f "delims=" %%V in ('powershell -NoProfile -Command "Get-ChildItem -Path '!CANDIDATE_DIR!' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { [version]($_.Name -replace '-.*','') } -Descending | Select-Object -First 1 -ExpandProperty Name" 2^>nul') do (
            set "TARGET_VER=%%V"
        )
    )
)

set "TARGET_PATH=!CANDIDATE_DIR!\!TARGET_VER!"

if not exist "!TARGET_PATH!" (
    echo %cRED%[ ERROR  ]%cRESET% !CANDIDATE_PROPER_NAME! version !TARGET_VER! is not installed.
    exit /b 1
)

echo %cBLUE%[ ACTION ]%cRESET% Uninstalling !CANDIDATE_PROPER_NAME! version !TARGET_VER!...
rmdir /S /Q "!TARGET_PATH!" >nul 2>&1

rem Check if it was the active version
set "SYMLINK_PATH=!CANDIDATE_DIR!\current"
set "ACTIVE_TARGET="
for /f "tokens=1,2*" %%A in ('fsutil reparsepoint query "!SYMLINK_PATH!" 2^>nul ^| findstr /i "Print Name:"') do set "ACTIVE_TARGET=%%C"
if not defined ACTIVE_TARGET (
    for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '!SYMLINK_PATH!' -ErrorAction SilentlyContinue).Target" 2^>nul') do set "ACTIVE_TARGET=%%A"
)
if defined ACTIVE_TARGET (
    set "ACTIVE_TARGET=!ACTIVE_TARGET:\??\=!"
    set "ACTIVE_TARGET=!ACTIVE_TARGET:\\?\=!"
    for /f "tokens=*" %%A in ("!ACTIVE_TARGET!") do set "ACTIVE_TARGET=%%A"
    for /f "delims=" %%A in ("!TARGET_PATH!") do set "NORM_TARGET=%%~fA"
    if /i "!ACTIVE_TARGET!"=="!NORM_TARGET!" (
        echo %cYELLOW%[ WARNING]%cRESET% Uninstalled the active version. Removing symlink...
        rmdir "!SYMLINK_PATH!" >nul 2>&1
        reg delete "HKCU\Environment" /v !CANDIDATE_ENV_VAR! /f >nul 2>&1
    )
)

echo %cGREEN%[   OK   ]%cRESET% !CANDIDATE_PROPER_NAME! !TARGET_VER! successfully uninstalled.
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
    for /f "tokens=1,2*" %%A in ('fsutil reparsepoint query "%%C\current" 2^>nul ^| findstr /i "Print Name:"') do set "ACTIVE_TARGET=%%C"
    if not defined ACTIVE_TARGET (
        for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '%%C\current' -ErrorAction SilentlyContinue).Target" 2^>nul') do set "ACTIVE_TARGET=%%A"
    )
    if defined ACTIVE_TARGET (
        set "ACTIVE_TARGET=!ACTIVE_TARGET:\??\=!"
        set "ACTIVE_TARGET=!ACTIVE_TARGET:\\?\=!"
        for /f "tokens=*" %%A in ("!ACTIVE_TARGET!") do set "ACTIVE_TARGET=%%A"
    )

    for /f "delims=" %%V in ('powershell -NoProfile -Command "Get-ChildItem -Path '%%C' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { [version]($_.Name -replace '-.*','') } -Descending | Select-Object -ExpandProperty Name"') do (
        set "V_NAME=%%V"
        set "IS_ACTIVE="
        for /f "delims=" %%A in ("%%~fC\%%V") do set "TP=%%~fA"
        if /i "!ACTIVE_TARGET!"=="!TP!" set "IS_ACTIVE= %cGREEN%[ACTIVE]%cRESET%"
        echo      * !V_NAME!!IS_ACTIVE!
    )
    echo.
)
exit /b 0

:ProcessEcosystemSession
set "TARGET_CANDIDATE=%~1"
call :GetCandidateEnvVar
if not defined CANDIDATE_ENV_VAR exit /b 0

set "T_PATH=%LOCALAPPDATA%\DiamTek\JVM\candidates\!TARGET_CANDIDATE!\%~2"
if not exist "!T_PATH!" (
    echo %cYELLOW%[ WARNING]%cRESET% !CANDIDATE_PROPER_NAME! %~2 is not installed.
    exit /b 0
)
echo %cBLUE%[ ACTION ]%cRESET% Setting !CANDIDATE_PROPER_NAME! to %~2...
>>"%TEMP%\.jvm_session_target" echo !CANDIDATE_ENV_VAR!=!T_PATH!
set "!CANDIDATE_ENV_VAR!=!T_PATH!"
set "PATH=!T_PATH!\bin;!PATH!"
exit /b 0

rem ============================================================
rem Shared API Resolver for Ecosystem Tools
rem ============================================================
:ResolveLatestEcosystemCandidate
set "PS_RESOLVE_LATEST="
set "PS_CATCH=catch { if ($_.Exception.Response -and $_.Exception.Response.StatusCode -eq 'Forbidden') { 'RATE_LIMITED' } else { 'ERROR' } }"
if /i "!TARGET_CANDIDATE!"=="maven" set "PS_RESOLVE_LATEST=$ProgressPreference = 'SilentlyContinue'; $url='https://api.github.com/repos/apache/maven/releases?per_page=50'; try { $h = @{}; if ($env:GITHUB_TOKEN) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }; $r = Invoke-RestMethod -Uri $url -Headers $h -UseBasicParsing; $t = $r | Where-Object { -not $_.prerelease -and -not $_.draft -and $_.tag_name -like 'maven-*' } | Select-Object -First 1; if ($t) { $t.tag_name.Replace('maven-','') } else { 'ERROR' } } !PS_CATCH!"
if /i "!TARGET_CANDIDATE!"=="gradle" set "PS_RESOLVE_LATEST=$ProgressPreference = 'SilentlyContinue'; $url='https://services.gradle.org/versions/current'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing).version } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="kotlin" set "PS_RESOLVE_LATEST=$ProgressPreference = 'SilentlyContinue'; $url='https://api.github.com/repos/JetBrains/kotlin/releases/latest'; try { $h = @{}; if ($env:GITHUB_TOKEN) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }; ((Invoke-RestMethod -Uri $url -Headers $h -UseBasicParsing).tag_name).TrimStart('v') } !PS_CATCH!"
if /i "!TARGET_CANDIDATE!"=="scala" set "PS_RESOLVE_LATEST=$ProgressPreference = 'SilentlyContinue'; $url='https://api.github.com/repos/scala/scala3/releases/latest'; try { $h = @{}; if ($env:GITHUB_TOKEN) { $h['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN }; (Invoke-RestMethod -Uri $url -Headers $h -UseBasicParsing).tag_name } !PS_CATCH!"
if /i "!TARGET_CANDIDATE!"=="groovy" set "PS_RESOLVE_LATEST=$ProgressPreference = 'SilentlyContinue'; $url='https://api.sdkman.io/2/candidates/default/groovy'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing) } catch { 'ERROR' }"

set "LATEST_VER=ERROR"
for /f "delims=" %%V in ('powershell -NoProfile -Command "!PS_RESOLVE_LATEST!"') do (
    set "LATEST_VER=%%V"
)
if "!LATEST_VER!"=="RATE_LIMITED" (
    echo %cYELLOW%[ WARNING]%cRESET% GitHub API Rate Limit reached. Trying redirect fallback...
    set "PS_REDIR="
    if /i "!TARGET_CANDIDATE!"=="maven" set "PS_REDIR=try { $r=[Net.HttpWebRequest]::Create('https://github.com/apache/maven/releases/latest'); $r.AllowAutoRedirect=$false; $r.Timeout=10000; $resp=$r.GetResponse(); $loc=$resp.Headers['Location']; $resp.Close(); if ($loc -match '/tag/maven-(.+)$') { $Matches[1] } else { 'ERROR' } } catch { 'ERROR' }"
    if /i "!TARGET_CANDIDATE!"=="kotlin" set "PS_REDIR=try { $r=[Net.HttpWebRequest]::Create('https://github.com/JetBrains/kotlin/releases/latest'); $r.AllowAutoRedirect=$false; $r.Timeout=10000; $resp=$r.GetResponse(); $loc=$resp.Headers['Location']; $resp.Close(); if ($loc -match '/tag/v?(.+)$') { $Matches[1] } else { 'ERROR' } } catch { 'ERROR' }"
    if /i "!TARGET_CANDIDATE!"=="scala" set "PS_REDIR=try { $r=[Net.HttpWebRequest]::Create('https://github.com/scala/scala3/releases/latest'); $r.AllowAutoRedirect=$false; $r.Timeout=10000; $resp=$r.GetResponse(); $loc=$resp.Headers['Location']; $resp.Close(); if ($loc -match '/tag/(.+)$') { $Matches[1] } else { 'ERROR' } } catch { 'ERROR' }"
    if defined PS_REDIR (
        set "REDIR_TAG="
        for /f "delims=" %%T in ('powershell -NoProfile -Command "!PS_REDIR!"') do set "REDIR_TAG=%%T"
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
exit /b 0

rem ============================================================
rem Universal Downloader & Extractor (PowerShell)
rem ============================================================
:ExecuteSharedDownloader
set "PS_SCRIPT=%TEMP%\jvm_dl_!RANDOM!.ps1"
(
    echo $ErrorActionPreference = 'Stop'
    echo $ProgressPreference = 'SilentlyContinue'
    echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    echo try {
    echo     Write-Host '[ ACTION ] Downloading from !DL_URL! ...' -ForegroundColor Cyan
    echo     $url = '!DL_URL!'
    echo     $out = '!DL_ZIP!'
    echo     $maxRetries = 3; $retryCount = 0; $response = $null
    echo     while ^($retryCount -lt $maxRetries^) {
    echo         try {
    echo             $request = [System.Net.WebRequest]::Create^($url^)
    echo             $response = $request.GetResponse^(^)
    echo             break
    echo         } catch {
    echo             $retryCount++
    echo             if ^($retryCount -eq $maxRetries^) { throw }
    echo             Write-Host "`r[ WARNING] Network error, retrying ($retryCount/$maxRetries)... " -ForegroundColor Yellow
    echo             Start-Sleep -Seconds 2
    echo         }
    echo     }
    echo     $totalLength = $response.ContentLength
    echo     $stream = $response.GetResponseStream^(^)
    echo     $fileStream = New-Object System.IO.FileStream^($out, [System.IO.FileMode]::Create^)
    echo     $buffer = New-Object byte[] 65536
    echo     $downloaded = 0
    echo     $lastPercent = -1
    echo     while ^( ^( $read = $stream.Read^($buffer, 0, $buffer.Length^) ^) -gt 0 ^) {
    echo         $fileStream.Write^($buffer, 0, $read^)
    echo         $downloaded += $read
    echo         if ^($totalLength -gt 0^) {
    echo             $percent = [math]::Floor^( ^($downloaded / $totalLength^) * 100 ^)
    echo             if ^($percent -ne $lastPercent^) {
    echo                 $bar = '[' + ^('=' * [math]::Floor^($percent / 2^)^) + ^(' ' * ^(50 - [math]::Floor^($percent / 2^)^)^) + ']'
    echo                 $dMB = [math]::Round^($downloaded / 1MB, 1^)
    echo                 $tMB = [math]::Round^($totalLength / 1MB, 1^)
    echo                 Write-Host "`r[ ACTION ] Downloading: $bar $percent%% ($dMB / $tMB MB) " -NoNewline -ForegroundColor Cyan
    echo                 $lastPercent = $percent
    echo             }
    echo         }
    echo     }
    echo     $fileStream.Close^(^)
    echo     $stream.Close^(^)
    echo     if ^($totalLength -gt 0^) {
    echo         $tMB = [math]::Round^($totalLength / 1MB, 1^)
    echo         $fullBar = '[' + ^('=' * 50^) + ']'
    echo         Write-Host "`r[ ACTION ] Downloading: $fullBar 100%% ($tMB / $tMB MB) " -NoNewline -ForegroundColor Cyan
    echo     }
    echo     Write-Host "`n"
    echo     $cryptoType = if ^('!DL_CHKSUM_TYPE!' -ne ''^) { '!DL_CHKSUM_TYPE!' } else { 'SHA256' }
    echo     if ^('!DL_CHKSUM_URL!' -eq '' -and '!DL_CHKSUM_VAL!' -eq ''^) {
    echo         if ^('!SKIP_CHECKSUM!' -ne '1'^) {
    echo             Write-Host '[ ERROR  ] Integrity checksum configuration missing for this download payload.' -ForegroundColor Red
    echo             Write-Host '           Aborting due to security policy. Rerun with --skip-checksum to bypass verification.' -ForegroundColor Red
    echo             if ^(Test-Path '!DL_ZIP!'^) { Remove-Item '!DL_ZIP!' -Force -ErrorAction SilentlyContinue }
    echo             exit 1
    echo         }
    echo         Write-Host '[ WARNING] Proceeding WITHOUT integrity verification ^(--skip-checksum active^).' -ForegroundColor Yellow
    echo         Write-Host ""
    echo     } else {
    echo         Write-Host "[ ACTION ] Verifying $cryptoType checksum..." -ForegroundColor Cyan
    echo         $expectedHash = $null
    echo         if ^('!DL_CHKSUM_URL!' -ne ''^) {
    echo             try {
    echo                 $expectedHash = ^(Invoke-RestMethod -Uri '!DL_CHKSUM_URL!' -UseBasicParsing^).Trim^(^)
    echo             } catch {
    echo                 if ^('!DL_CHKSUM_URL!' -match '\.sha512$'^) {
    echo                     Write-Host "[ WARNING] SHA512 checksum not found, falling back to SHA1..." -ForegroundColor Yellow
    echo                     $fallbackUrl = '!DL_CHKSUM_URL!' -replace '\.sha512$', '.sha1'
    echo                     try {
    echo                         $expectedHash = ^(Invoke-RestMethod -Uri $fallbackUrl -UseBasicParsing^).Trim^(^)
    echo                         $cryptoType = 'SHA1'
    echo                     } catch { $expectedHash = $null }
    echo                 }
    echo             }
    echo             if ^($expectedHash^) { $expectedHash = ^($expectedHash -split '\s+'^)[0].Trim^(^) }
    echo             if ^($cryptoType -eq 'SHA256' -and $expectedHash -notmatch '^[0-9a-fA-F]{64}$'^) { $expectedHash = $null }
    echo             if ^($cryptoType -eq 'SHA512' -and $expectedHash -notmatch '^[0-9a-fA-F]{128}$'^) { $expectedHash = $null }
    echo             if ^($cryptoType -eq 'SHA1' -and $expectedHash -notmatch '^[0-9a-fA-F]{40}$'^) { $expectedHash = $null }
    echo         } else {
    echo             $expectedHash = '!DL_CHKSUM_VAL!'
    echo         }
    echo         if ^([string]::IsNullOrWhiteSpace^($expectedHash^)^) {
    echo             Write-Host '[ WARNING] Integrity verification unavailable or failed to fetch.' -ForegroundColor Yellow
    echo             if ^('!SKIP_CHECKSUM!' -ne '1'^) {
    echo                 Write-Host '[ ERROR  ] Aborting due to security policy. Rerun with --skip-checksum to bypass verification.' -ForegroundColor Red
    echo                 if ^(Test-Path '!DL_ZIP!'^) { Remove-Item '!DL_ZIP!' -Force -ErrorAction SilentlyContinue }
    echo                 exit 1
    echo             }
    echo             Write-Host '            Proceeding WITHOUT integrity verification ^(--skip-checksum active^).' -ForegroundColor Yellow
    echo             Write-Host ""
    echo         } else {
    echo             $crypto = [System.Security.Cryptography.HashAlgorithm]::Create^($cryptoType^)
    echo             if ^(-not $crypto^) { $crypto = [System.Security.Cryptography.SHA256]::Create^(^) }
    echo             $fs2 = [System.IO.File]::OpenRead^('!DL_ZIP!'^)
    echo             $hashBytes = $crypto.ComputeHash^($fs2^)
    echo             $fs2.Close^(^)
    echo             $actualHash = [System.BitConverter]::ToString^($hashBytes^).Replace^('-', ''^).ToLower^(^)
    echo             if ^($actualHash -ne $expectedHash.ToLower^(^)^) {
    echo                 Write-Host '[ ERROR  ] Checksum mismatch. Download corrupted or compromised.' -ForegroundColor Red
    echo                 Write-Host "           Expected: $expectedHash" -ForegroundColor Red
    echo                 Write-Host "           Actual:   $actualHash" -ForegroundColor Red
    echo                 if ^(Test-Path '!DL_ZIP!'^) { Remove-Item '!DL_ZIP!' -Force -ErrorAction SilentlyContinue }
    echo                 exit 1
    echo             }
    echo             Write-Host '[   OK   ] Checksum verified successfully.' -ForegroundColor Green
    echo             Write-Host ""
    echo         }
    echo     }
    echo     if ^('!DL_EXTRACT!' -ne ''^) {
    echo         Write-Host '[ ACTION ] Extracting archive...' -ForegroundColor Cyan
    echo         Add-Type -AssemblyName System.IO.Compression.FileSystem
    echo         $zip = [System.IO.Compression.ZipFile]::OpenRead^('!DL_ZIP!'^)
    echo         $entries = $zip.Entries
    echo         $totalEntries = $entries.Count
    echo         $extracted = 0
    echo         $lastPercent = -1
    echo         $fullRoot = [System.IO.Path]::GetFullPath^('!DL_EXTRACT!'^)
    echo         if ^(-not $fullRoot.EndsWith^([System.IO.Path]::DirectorySeparatorChar.ToString^(^)^)^) {
    echo             $fullRoot += [System.IO.Path]::DirectorySeparatorChar
    echo         }
    echo         foreach ^($entry in $entries^) {
    echo             $destinationPath = [System.IO.Path]::GetFullPath^([System.IO.Path]::Combine^('!DL_EXTRACT!', $entry.FullName^)^)
    echo             if ^(-not $destinationPath.StartsWith^($fullRoot, [System.StringComparison]::OrdinalIgnoreCase^) -and $destinationPath -ne $fullRoot.TrimEnd^([System.IO.Path]::DirectorySeparatorChar^)^) {
    echo                 throw ^('Blocked path traversal in archive entry: ' + $entry.FullName^)
    echo             }
    echo             if ^([string]::IsNullOrEmpty^($entry.Name^)^) {
    echo                 [System.IO.Directory]::CreateDirectory^($destinationPath^) ^| Out-Null
    echo             } else {
    echo                 [System.IO.Directory]::CreateDirectory^([System.IO.Path]::GetDirectoryName^($destinationPath^)^) ^| Out-Null
    echo                 [System.IO.Compression.ZipFileExtensions]::ExtractToFile^($entry, $destinationPath, $true^)
    echo             }
    echo             $extracted++
    echo             $percent = [math]::Round^(^($extracted / $totalEntries^) * 100^)
    echo             if ^($percent -ne $lastPercent^) {
    echo                 $bar = '[' + ^('=' * [math]::Floor^($percent / 2^)^) + ^(' ' * ^(50 - [math]::Floor^($percent / 2^)^)^) + ']'
    echo                 Write-Host "`r[ ACTION ] Extracting: $bar $percent%% ($extracted / $totalEntries) " -NoNewline -ForegroundColor Cyan
    echo                 $lastPercent = $percent
    echo             }
    echo         }
    echo         Write-Host "`r[ ACTION ] Extracting: [==================================================] 100%% ($totalEntries / $totalEntries) " -NoNewline -ForegroundColor Cyan
    echo         $zip.Dispose^(^)
    echo         Write-Host "`n"
    echo         Remove-Item '!DL_ZIP!'
    echo         if ^('!DL_STRIP_ROOT!' -eq '1'^) {
    echo             $items = Get-ChildItem '!DL_EXTRACT!'
    echo             if ^($items.Count -eq 1 -and $items[0].PSIsContainer^) {
    echo                 Move-Item -Path ^($items[0].FullName + '\*'^) -Destination '!DL_EXTRACT!\' -Force
    echo                 Remove-Item $items[0].FullName -Recurse -Force
    echo             }
    echo         }
    echo     }
    echo } catch {
    echo     Write-Host "[ ERROR  ] Failed to download or extract." -ForegroundColor Red
    echo     Write-Host '[ DETAIL ] ' $_.Exception.Message -ForegroundColor Yellow
    echo     if ^(Test-Path '!DL_ZIP!'^) { Remove-Item '!DL_ZIP!' -ErrorAction SilentlyContinue }
    echo     exit 1
    echo }
) > "!PS_SCRIPT!"

powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!"
set PS_EXIT_CODE=!errorlevel!
if exist "!PS_SCRIPT!" del "!PS_SCRIPT!" >nul 2>&1
exit /b !PS_EXIT_CODE!

:BackupRegistry
if not exist "%LOCALAPPDATA%\DiamTek\JVM\backups" mkdir "%LOCALAPPDATA%\DiamTek\JVM\backups"
set "BAK_TIME=%TIME::=-%"
set "BAK_TIME=!BAK_TIME: =0!"
set "BAK_TIME=!BAK_TIME:~0,6!"
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "%LOCALAPPDATA%\DiamTek\JVM\backups\sys_env_!DATE!_!BAK_TIME!.reg" /y >nul 2>&1
reg export "HKCU\Environment" "%LOCALAPPDATA%\DiamTek\JVM\backups\usr_env_!DATE!_!BAK_TIME!.reg" /y >nul 2>&1
exit /b 0

rem END OF SCRIPT