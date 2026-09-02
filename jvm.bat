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

rem Enable UTF-8 encoding for console output
chcp 65001 >nul

setlocal enabledelayedexpansion
set "INVOCATION_DIR=%cd%"

rem Cleanup self-updater artifact if it exists
if exist "%TEMP%\jvm_updater.bat" del "%TEMP%\jvm_updater.bat" >nul 2>&1

title Java Version Manager

set "JVM_VERSION=0.6.0"
set "JVM_BUILD=20260902.25"

rem Generate ESC character for ANSI color codes
for /F "delims=#" %%a in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"
set "cRED=%ESC%[91m"
set "cGREEN=%ESC%[92m"
set "cYELLOW=%ESC%[93m"
set "cBLUE=%ESC%[96m"
set "cGRAY=%ESC%[90m"
set "cRESET=%ESC%[0m"

rem Define base JDK search locations BEFORE delayed expansion to prevent exclamation mark corruption
set "LOCATIONS[0]=C:\Program Files\Java"
set "LOCATIONS[1]=C:\Program Files (x86)\Java"
set "LOCATIONS[2]=C:\Java"
set "LOCATIONS[3]=%USERPROFILE%\.jdks"
set "LOCATIONS[4]=%USERPROFILE%\.gradle\jdks"
set "LOCATIONS[5]=%LOCALAPPDATA%\JavaVersionManager\links"

set LOC_IDX=6
if exist "%USERPROFILE%\scoop\apps" (
    for /d %%A in ("%USERPROFILE%\scoop\apps\*") do (
        if exist "%%A\current\bin\java.exe" (
            call set "LOCATIONS[%%LOC_IDX%%]=%%A"
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

set "SWITCH_MODE=SYMLINK"
if exist "%LOCALAPPDATA%\DiamTek\JVM\mode.txt" (
    set /p SWITCH_MODE=<"%LOCALAPPDATA%\DiamTek\JVM\mode.txt"
)
if /i not "!SWITCH_MODE!"=="DIRECT" set "SWITCH_MODE=SYMLINK"

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
) else if /i "%~1"=="uninstall" (
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
) else (
    if not defined CLI_TARGET (
        set "CLI_TARGET=%~1"
        set "SILENT_MODE=1"
    )
    shift
    goto :PARSE_CLI_ARGS
)

:PARSE_DONE

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
    if /i "%CLI_COMMAND%"=="update" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="self-update" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="version" set "SKIP_HEADER=1"
)
if defined CLI_TARGET (
    set "SKIP_HEADER=1"
) else if exist ".java-version" (
    for /f "delims=" %%L in ('type ".java-version" 2^>nul ^| findstr /r "[0-9]"') do (
        call :ParseJavaVersion %%L
        if not "!FORCE_GLOBAL!"=="1" set "SESSION_MODE=1"
        set "SILENT_MODE=1"
        set "SKIP_HEADER=1"
    )
) else if exist "%INVOCATION_DIR%\.sdkmanrc" (
    set "FOUND_SDKMANRC=1"
    for /f "tokens=1,2 delims==" %%A in ('type "%INVOCATION_DIR%\.sdkmanrc" 2^>nul ^| findstr /i "^java="') do (
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
    set /p SWITCH_MODE=<"%LOCALAPPDATA%\DiamTek\JVM\mode.txt"
)
if /i not "!SWITCH_MODE!"=="DIRECT" set "SWITCH_MODE=SYMLINK"

if defined SWITCH_MODE_OVERRIDE (
    set "SWITCH_MODE=%SWITCH_MODE_OVERRIDE%"
)

rem Jump straight to the menu function to prevent screen clearing issues
call :ShowDynamicMenu %*

rem If CURRENT_JDK_PATH is not set, the user chose the Exit option (unless purely doing ecosystem session switching)
if not defined CURRENT_JDK_PATH (
    if not "!FOUND_SDKMANRC!"=="1" (
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
        for /f "tokens=1,2 delims==" %%A in ('type "%INVOCATION_DIR%\.sdkmanrc" 2^>nul ^| findstr /i /v "^java="') do (
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
    if /i not "%JAVA_HOME%"=="%CURRENT_SYMLINK%" (
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

rem Strip the OLD Java Home if it exists
if defined JAVA_HOME (
    set "CLEAN_PATH=!CLEAN_PATH:%JAVA_HOME%\bin;=!"
    set "CLEAN_PATH=!CLEAN_PATH:;%JAVA_HOME%\bin=!"
)
rem Strip the NEW path just in case to prevent doubling up
set "CLEAN_PATH=!CLEAN_PATH:%SYMLINK_OR_DIRECT%\bin;=!"
set "CLEAN_PATH=!CLEAN_PATH:;%SYMLINK_OR_DIRECT%\bin=!"
rem Strip the hardcoded JDK path just in case
set "CLEAN_PATH=!CLEAN_PATH:%CURRENT_JDK_PATH%\bin;=!"
set "CLEAN_PATH=!CLEAN_PATH:;%CURRENT_JDK_PATH%\bin=!"
rem Remove double semicolons
set "CLEAN_PATH=!CLEAN_PATH:;;=;!"

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
if errorlevel 1 (
    echo %cBLUE%[  INFO  ]%cRESET% Java may not work until you restart command prompt.
) else (
    echo %cGREEN%[   OK   ]%cRESET% Java is working correctly!
)
echo.
if "%SESSION_MODE%"=="1" (
    echo %cBLUE%[  INFO  ]%cRESET% Session PATH has been updated with %%JAVA_HOME%%\bin
    echo            This change is temporary for this terminal only.
) else (
    echo %cBLUE%[  INFO  ]%cRESET% System PATH has been updated with %%JAVA_HOME%%\bin
    echo            Open a new command prompt for changes to take full effect globally.
)
echo.
echo ============================================================

echo.
if "%SILENT_MODE%"=="1" (
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
    for /f "tokens=2* delims=:" %%P in ('fsutil reparsepoint query "%LOCALAPPDATA%\DiamTek\JVM\current" 2^>nul ^| findstr /c:"Print Name:"') do (
        set "RAW_TARGET=%%P:%%Q"
        for /f "tokens=* delims= " %%A in ("!RAW_TARGET!") do set "RESOLVED_JAVA_HOME=%%A"
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
                            )
                        )
                        if not defined VER (
                            for /f "tokens=3" %%A in ('"%%j\bin\java.exe" -version 2^>^&1 ^| findstr /i "version"') do (
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
        echo.
        echo %cBLUE%[  INFO  ]%cRESET% Java Environment Variables:
        echo ============================================================
        if defined JAVA_HOME (
            echo JAVA_HOME = !JAVA_HOME!
        ) else (
            echo JAVA_HOME is NOT SET
        )
        echo ============================================================
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
            set "CLI_TARGET=!ORACLE_LATEST_LTS!"
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
                        for /f "tokens=2*" %%A in ('fsutil reparsepoint query "%LOCALAPPDATA%\DiamTek\JVM\candidates\%%T\current" 2^>nul ^| findstr /i "Print Name:"') do for %%X in ("%%B") do set "act_ver=%%~nxX"
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
                taskkill /f /im java.exe >nul 2^>^&1
                taskkill /f /im javaw.exe >nul 2^>^&1
                rmdir /s /q "!DEL_PATH!"
                if not exist "%LOCALAPPDATA%\DiamTek\JVM\current\bin\java.exe" (
                    if exist "%LOCALAPPDATA%\DiamTek\JVM\current" rmdir "%LOCALAPPDATA%\DiamTek\JVM\current"
                    reg delete "HKCU\Environment" /v JAVA_HOME /f >nul 2^>^&1
                )
                set "SYS_PATH="
                for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
                if defined SYS_PATH (
                    for %%P in ("!DEL_PATH!") do (
                        set "SYS_PATH=!SYS_PATH:%%~P\bin;=!"
                        set "SYS_PATH=!SYS_PATH:;%%~P\bin=!"
                    )
                    set "SYS_PATH=!SYS_PATH:;;=;!"
                    powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('Path', $env:SYS_PATH, 'Machine')"
                )
                set "USR_PATH="
                for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
                if defined USR_PATH (
                    for %%P in ("!DEL_PATH!") do (
                        set "USR_PATH=!USR_PATH:%%~P\bin;=!"
                        set "USR_PATH=!USR_PATH:;%%~P\bin=!"
                    )
                    set "USR_PATH=!USR_PATH:;;=;!"
                    powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('Path', $env:USR_PATH, 'User')"
                )
                exit /b 0
            ) else (
                echo.
                echo %cBLUE%[ ACTION ]%cRESET% Terminating any active Java processes...
                echo %cBLUE%[ ACTION ]%cRESET% Deleting directory !DEL_PATH!...
                echo %cBLUE%[ ACTION ]%cRESET% Scrubbing environment variables...
                
                echo %cBLUE%[  INFO  ]%cRESET% Requesting administrative privileges to apply changes...
                set "WORK_DIR=%cd%"
                set "UAC_ARGS=%ORIGINAL_ARGS%"
                powershell -NoProfile -ExecutionPolicy Bypass -Command "$argsArray = @('--admin-run') + ($env:UAC_ARGS -split ' '); Start-Process -FilePath \"$env:SCRIPT_PATH\" -WorkingDirectory \"$env:WORK_DIR\" -ArgumentList $argsArray -Verb RunAs -WindowStyle Hidden -Wait"
                
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

    if /i "!CLI_COMMAND!"=="self-update" (
        call :SelfUpdate
        goto :eof
    )
    
    if /i "!CLI_COMMAND!"=="version" (
        call :AboutMenu
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
    set "CURRENT_JDK_PATH="
    goto :eof
)

if !choice!==3 (
    call :SettingsMenu
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
            for /f "tokens=2*" %%A in ('fsutil reparsepoint query "!eu_cdir!\current" 2^>nul ^| findstr /i "Print Name:"') do (
                set "eu_raw_target=%%B"
                for %%X in ("!eu_raw_target!") do set "EU_ACTIVE_%%T=%%~nxX"
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
echo Please select an option:
echo.
echo %cGRAY%--- Installed Versions ---%cRESET%
for /l %%i in (1,1,!eco_count!) do (
    set "IS_ACTIVE="
    for /f "tokens=2*" %%A in ('fsutil reparsepoint query "!CANDIDATE_DIR!\current" 2^>nul ^| findstr /i "Print Name:"') do (
        set "TP=!CANDIDATE_DIR!\!ECO_VER_%%i!"
        if /i "%%B"=="!TP!" set "IS_ACTIVE= %cGREEN%[ACTIVE]%cRESET%"
    )
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

set "ALLOWED_CHOICES=123456789abcdefghijklmnopqrstuvwxyz"
set /a total_opts=eco_count+2
call set "VALID_CHOICES=%%ALLOWED_CHOICES:~0,!total_opts!%%"

choice /C !VALID_CHOICES! /N /M "Select an option: "
set "user_choice=!errorlevel!"

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

:EcoToolVersionMode
echo Please choose an option:
echo.
echo 1. Download and Install a new version
echo 2. Uninstall a version
echo 3. Go back
echo.
choice /C 123 /N /M "Select an option (1-3): "
set "user_choice=!errorlevel!"

if !user_choice!==3 goto :EcosystemSelectTool
if !user_choice!==1 (
    echo.
    set /p TARGET_VER="Enter version to install (or type 'latest'): "
    if "!TARGET_VER!"=="" set "TARGET_VER=latest"
    set "CLI_TARGET=!TARGET_VER!"
    call :InstallCandidate
    goto :EcosystemToolMenu
)
if !user_choice!==2 (
    echo.
    set /p TARGET_VER="Enter exact version to uninstall: "
    set "CLI_TARGET=!TARGET_VER!"
    call :UninstallCandidate
    pause
    goto :EcosystemToolMenu
)
goto :EcosystemToolMenu

:InstallEcosystemMenu
echo.
echo ============================================================
echo               Ecosystem Tool Downloader
echo ============================================================
echo Select Tool to Install:
echo 1. Maven
echo 2. Gradle
echo 3. Kotlin
echo 4. Scala
echo 5. Groovy
echo 6. Cancel
echo.
choice /C 123456 /N /M "Enter your choice (1-6): "
set "tool_choice=!errorlevel!"

if !tool_choice!==6 goto :eof
if !tool_choice!==1 set "TARGET_CANDIDATE=maven"
if !tool_choice!==2 set "TARGET_CANDIDATE=gradle"
if !tool_choice!==3 set "TARGET_CANDIDATE=kotlin"
if !tool_choice!==4 set "TARGET_CANDIDATE=scala"
if !tool_choice!==5 set "TARGET_CANDIDATE=groovy"

echo.
set /p TARGET_VER="Enter version to install (or type 'latest'): "
if "!TARGET_VER!"=="" set "TARGET_VER=latest"
set "CLI_TARGET=!TARGET_VER!"

rem Route to the Universal Candidate Engine
call :InstallCandidate
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
    echo 7. Cancel
    echo.
    choice /C 1234567 /N /M "Select vendor (1-7): "
    if !errorlevel!==7 goto :eof
    if !errorlevel!==1 set "CLI_VENDOR=Oracle"
    if !errorlevel!==2 set "CLI_VENDOR=Adoptium"
    if !errorlevel!==3 set "CLI_VENDOR=GraalVM"
    if !errorlevel!==4 set "CLI_VENDOR=Corretto"
    if !errorlevel!==5 set "CLI_VENDOR=Zulu"
    if !errorlevel!==6 set "CLI_VENDOR=Microsoft"
)

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
        echo              !EXISTING_PATH!
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

if !DL_VERSION! LEQ 16 (
    if /i "!CLI_VENDOR!"=="oracle" (
        echo.
        echo %cRED%[ ERROR  ]%cRESET% Oracle Java 16 and below are locked behind an authentication wall.
        echo            Please use Adoptium/GraalVM for these versions.
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
if "!API_URL!"=="" (
    echo %cRED%[ ERROR  ]%cRESET% Unknown or unsupported vendor: !CLI_VENDOR!
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)
goto :FetchAndExtract

:Resolve_Oracle
set "DL_VENDOR=Oracle"
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
goto :FetchAndExtract

:Resolve_Adoptium
set "DL_VENDOR=Adoptium"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying Adoptium API for latest JDK !DL_VERSION! release...
set "PS_CMD=try { $res = Invoke-RestMethod -Uri 'https://api.adoptium.net/v3/assets/feature_releases/!DL_VERSION!/ga?architecture=!SYS_ARCH!&image_type=jdk&jvm_impl=hotspot&os=windows&page=0&page_size=1' -UseBasicParsing; if ($res[0].binaries[0].package.link -and $res[0].binaries[0].package.checksum) { Write-Output ('API_URL='+$res[0].binaries[0].package.link); Write-Output ('API_SHA256='+$res[0].binaries[0].package.checksum) } else { exit 1 } } catch { Write-Output ('API_ERROR='+$_.Exception.Message); exit 1 }"
goto Run_API_Query

:Resolve_GraalVM
set "DL_VENDOR=GraalVM"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying GraalVM GitHub API for latest JDK !DL_VERSION! release...
set "PS_CMD=try { $res = Invoke-RestMethod -Uri 'https://api.github.com/repos/graalvm/graalvm-ce-builds/releases' -UseBasicParsing; $t = $null; foreach ($r in $res) { if ($r.tag_name -like 'jdk-!DL_VERSION!*') { $t = $r; break } }; if (-not $t) { exit 1 }; $u = $null; $s = $null; foreach ($a in $t.assets) { if ($a.name -match 'windows-(x64|amd64)_bin\.zip$') { $u = $a.browser_download_url }; if ($a.name -match 'windows-(x64|amd64)_bin\.zip\.sha256$') { $s = $a.browser_download_url } }; if ($u -and $s) { Write-Output ('API_URL='+$u); Write-Output ('API_SHA256_URL='+$s) } else { exit 1 } } catch { Write-Output ('API_ERROR='+$_.Exception.Message); exit 1 }"
goto Run_API_Query

:Resolve_Corretto
set "DL_VENDOR=Corretto"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Resolving Amazon Corretto JDK !DL_VERSION! URLs...
set "API_URL=https://corretto.aws/downloads/latest/amazon-corretto-!DL_VERSION!-x64-windows-jdk.zip"
set "API_SHA256_URL=https://corretto.aws/downloads/latest_sha256/amazon-corretto-!DL_VERSION!-x64-windows-jdk.zip"
set "API_SHA256="
goto :FetchAndExtract

:Resolve_Zulu
set "DL_VENDOR=Zulu"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying Azul Zulu API for latest JDK !DL_VERSION! release...
set "PS_CMD=try { $res = Invoke-RestMethod -Uri 'https://api.azul.com/zulu/download/community/v1.0/bundles/latest/?java_version=!DL_VERSION!&os=windows&arch=!ZULU_ARCH!&hw_bitness=64&ext=zip' -UseBasicParsing; if ($res.url -and $res.sha256_hash) { Write-Output ('API_URL='+$res.url); Write-Output ('API_SHA256='+$res.sha256_hash) } else { exit 1 } } catch { Write-Output ('API_ERROR='+$_.Exception.Message); exit 1 }"
goto Run_API_Query

:Resolve_Microsoft
set "DL_VENDOR=Microsoft"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Resolving Microsoft Build of OpenJDK !DL_VERSION! URLs...
set "API_URL=https://aka.ms/download-jdk/microsoft-jdk-!DL_VERSION!-windows-!SYS_ARCH!.zip"
set "API_SHA256_URL=https://aka.ms/download-jdk/microsoft-jdk-!DL_VERSION!-windows-!SYS_ARCH!.zip.sha256sum.txt"
set "API_SHA256="
goto :FetchAndExtract

:Run_API_Query
set "API_URL=" & set "API_SHA256=" & set "API_SHA256_URL=" & set "API_ERROR="
for /f "tokens=1,* delims==" %%A in ('powershell -NoProfile -Command "!PS_CMD!"') do (
    if "%%A"=="API_URL" set "API_URL=%%B"
    if "%%A"=="API_SHA256" set "API_SHA256=%%B"
    if "%%A"=="API_SHA256_URL" set "API_SHA256_URL=%%B"
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
set "PS_CMD=try { $res = Invoke-RestMethod -Uri 'https://api.adoptium.net/v3/info/available_releases' -UseBasicParsing -TimeoutSec 3; Write-Output ('LATEST_FEATURE='+$res.most_recent_feature_release); Write-Output ('LATEST_LTS='+$res.most_recent_lts) } catch { Write-Output 'LATEST_FEATURE=26'; Write-Output 'LATEST_LTS=25' }"
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
set "ADMIN_BAT=%TEMP%\jvm_admin_!RANDOM!.bat"
(
    echo @echo off
    echo if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"
    echo if exist "!DEST_DIR!\!NEW_FOLDER!" rmdir /s /q "!DEST_DIR!\!NEW_FOLDER!"
    echo move /y "!EXTRACT_DIR!\!NEW_FOLDER!" "!DEST_DIR!\" ^>nul
    echo if not exist "!EXTRACT_DIR!\!NEW_FOLDER!" rmdir /s /q "!EXTRACT_DIR!"
) > "!ADMIN_BAT!"

echo %cBLUE%[  INFO  ]%cRESET% Requesting administrative privileges to move files...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c \"!ADMIN_BAT!\"' -Verb RunAs -WindowStyle Hidden -Wait"
del "!ADMIN_BAT!"

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
setlocal enabledelayedexpansion

if /i "!SWITCH_MODE!"=="DIRECT" (
    echo           - Reading current system PATH...
    set "ORIGINAL_PATH="
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do (
        set "ORIGINAL_PATH=%%B"
    )
    if not defined ORIGINAL_PATH (
        for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
            set "ORIGINAL_PATH=%%B"
        )
    )
) else (
    echo            - Reading current USER PATH...
    set "ORIGINAL_PATH="
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
        set "ORIGINAL_PATH=%%B"
    )
    
    rem Check for Machine-level legacy pollution
    set "LEGACY_POLLUTION=0"
    reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v JAVA_HOME >nul 2>&1
    if not errorlevel 1 set "LEGACY_POLLUTION=1"
    
    if "!LEGACY_POLLUTION!"=="1" (
        echo.
        echo %cYELLOW%[ WARNING]%cRESET% Legacy system-level Java variables detected.
        echo %cBLUE%[ ACTION ]%cRESET% Requesting Administrator privileges to scrub legacy override...
        
        set "SYS_PATH="
        for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
        
        set PURGE_PATHS="C:\Program Files\Common Files\Oracle\Java\javapath" "C:\Program Files (x86)\Common Files\Oracle\Java\javapath" "C:\ProgramData\Oracle\Java\javapath"
        for /l %%k in (1,1,!JDK_COUNT!) do set PURGE_PATHS=!PURGE_PATHS! "!JDK_PATH_%%k!\bin"
        
        if defined SYS_PATH (
            for %%P in (!PURGE_PATHS!) do (
                set "SYS_PATH=!SYS_PATH:%%~P;=!"
                set "SYS_PATH=!SYS_PATH:;%%~P=!"
                set "SYS_PATH=!SYS_PATH:%%~P=!"
            )
            set "SYS_PATH=!SYS_PATH:;;=;!"
        )
        set "SAFE_SYS_PATH=!SYS_PATH:'=''!"
        
        set "ELEVATE_SCRIPT=%TEMP%\jvm_scrub_!RANDOM!.ps1"
        echo [Environment]::SetEnvironmentVariable^('JAVA_HOME', $null, 'Machine'^) > "!ELEVATE_SCRIPT!"
        echo [Environment]::SetEnvironmentVariable^('Path', '!SAFE_SYS_PATH!', 'Machine'^) >> "!ELEVATE_SCRIPT!"
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""!ELEVATE_SCRIPT!""' -Verb RunAs -Wait" 2>nul
        if exist "!ELEVATE_SCRIPT!" del "!ELEVATE_SCRIPT!"
        echo %cGREEN%[   OK   ]%cRESET% Legacy environment scrubbed successfully.
        echo.
    )
)

if not defined ORIGINAL_PATH (
    set "ORIGINAL_PATH=%PATH%"
)

echo            - De-bloating Phantom Oracle paths...

for %%P in ("C:\Program Files\Common Files\Oracle\Java\javapath" "C:\Program Files (x86)\Common Files\Oracle\Java\javapath" "C:\ProgramData\Oracle\Java\javapath" "%LOCALAPPDATA%\DiamTek\JVM\current\bin" "%CURRENT_JDK_PATH%\bin") do (
    set "ORIGINAL_PATH=!ORIGINAL_PATH:%%~P;=!"
    set "ORIGINAL_PATH=!ORIGINAL_PATH:;%%~P=!"
    set "ORIGINAL_PATH=!ORIGINAL_PATH:%%~P=!"
)
set "ORIGINAL_PATH=!ORIGINAL_PATH:;;=;!"

echo !ORIGINAL_PATH! | findstr /i "%%JAVA_HOME%%\bin" >nul
if errorlevel 1 (
    echo           - Adding %%JAVA_HOME%%\bin to the front of PATH...
    if "!ORIGINAL_PATH!"=="" (
        set "NEW_PATH=%%JAVA_HOME%%\bin"
    ) else (
        set "NEW_PATH=%%JAVA_HOME%%\bin;!ORIGINAL_PATH!"
    )
) else (
    echo           - %%JAVA_HOME%%\bin is already cleanly in PATH.
    set "NEW_PATH=!ORIGINAL_PATH!"
)

echo.
if /i "!SWITCH_MODE!"=="DIRECT" (
    echo %cBLUE%[ ACTION ]%cRESET% Requesting Administrator privileges to update Registry...
    
    rem Scrub any conflicting User-level JAVA_HOME that might override the Machine-level variable
    reg delete "HKCU\Environment" /v JAVA_HOME /f >nul 2>&1
    
    set "SAFE_JDK_PATH=!CURRENT_JDK_PATH:'=''!"
    set "SAFE_NEW_PATH=!NEW_PATH:'=''!"
    
    set "ELEVATE_SCRIPT=%TEMP%\jvm_elevate_!RANDOM!.ps1"
    echo [Environment]::SetEnvironmentVariable^('JAVA_HOME', '!SAFE_JDK_PATH!', 'Machine'^) > "!ELEVATE_SCRIPT!"
    echo [Environment]::SetEnvironmentVariable^('Path', '!SAFE_NEW_PATH!', 'Machine'^) >> "!ELEVATE_SCRIPT!"
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""!ELEVATE_SCRIPT!""' -Verb RunAs -Wait"
    
    if exist "!ELEVATE_SCRIPT!" del "!ELEVATE_SCRIPT!"
    
    echo %cGREEN%[   OK   ]%cRESET% JAVA_HOME and SYSTEM PATH updated successfully via UAC
) else (
    echo %cBLUE%[ ACTION ]%cRESET% Updating USER PATH...
    powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('Path', $env:NEW_PATH, 'User')"
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to update USER PATH!
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% USER PATH updated successfully
    )
)

echo.
echo %cGREEN%[   OK   ]%cRESET% PATH update complete!
endlocal
goto :eof


rem ============================================================
rem CLEAR JAVA ENVIRONMENT
rem ============================================================
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

rem Clean SYSTEM PATH
echo %cBLUE%[ ACTION ]%cRESET% Cleaning SYSTEM PATH...
set "SYS_PATH="
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
if defined SYS_PATH (
    for %%P in (!PURGE_PATHS!) do (
        set "SYS_PATH=!SYS_PATH:%%~P;=!"
        set "SYS_PATH=!SYS_PATH:;%%~P=!"
        set "SYS_PATH=!SYS_PATH:%%~P=!"
    )
    set "SYS_PATH=!SYS_PATH:;;=;!"
    
    echo %cBLUE%[ ACTION ]%cRESET% Requesting Administrator privileges to clear Machine Registry...
    set "SAFE_SYS_PATH=!SYS_PATH:'=''!"
    set "ELEVATE_SCRIPT=%TEMP%\jvm_elevate_!RANDOM!.ps1"
    echo [Environment]::SetEnvironmentVariable^('JAVA_HOME', $null, 'Machine'^) > "!ELEVATE_SCRIPT!"
    echo [Environment]::SetEnvironmentVariable^('Path', '!SAFE_SYS_PATH!', 'Machine'^) >> "!ELEVATE_SCRIPT!"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""!ELEVATE_SCRIPT!""' -Verb RunAs -Wait" 2>nul
    if exist "!ELEVATE_SCRIPT!" del "!ELEVATE_SCRIPT!"
)

rem Clean USER PATH
echo %cBLUE%[ ACTION ]%cRESET% Cleaning USER PATH...
set "USR_PATH="
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
if defined USR_PATH (
    set "ECO_PURGE="%%MAVEN_HOME%%\bin" "%%GRADLE_HOME%%\bin" "%%KOTLIN_HOME%%\bin" "%%SCALA_HOME%%\bin" "%%GROOVY_HOME%%\bin""
    for %%P in (!PURGE_PATHS! !ECO_PURGE!) do (
        set "USR_PATH=!USR_PATH:%%~P;=!"
        set "USR_PATH=!USR_PATH:;%%~P=!"
        set "USR_PATH=!USR_PATH:%%~P=!"
    )
    set "USR_PATH=!USR_PATH:;;=;!"
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

for %%P in (!PURGE_PATHS! !SESS_ECO_PURGE!) do (
    set "CLEAN_PATH=!CLEAN_PATH:%%~P;=!"
    set "CLEAN_PATH=!CLEAN_PATH:;%%~P=!"
    set "CLEAN_PATH=!CLEAN_PATH:%%~P=!"
)

set "CLEAN_PATH=!CLEAN_PATH:;;=;!"

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
set "HAS_CUSTOM=0"

for /l %%k in (1,1,!JDK_COUNT!) do (
    if /i "!JDK_VENDOR_%%k!"=="Oracle" set "HAS_ORACLE=1"
    if /i "!JDK_VENDOR_%%k!"=="Adoptium" set "HAS_ADOPTIUM=1"
    if /i "!JDK_VENDOR_%%k!"=="GraalVM" set "HAS_GRAALVM=1"
    if /i "!JDK_VENDOR_%%k!"=="Corretto" set "HAS_CORRETTO=1"
    if /i "!JDK_VENDOR_%%k!"=="Zulu" set "HAS_ZULU=1"
    if /i "!JDK_VENDOR_%%k!"=="Microsoft" set "HAS_MICROSOFT=1"
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
if "!NEEDS_RESCAN!"=="1" (
    set "NEEDS_RESCAN=0"
    goto :eof
)
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

for /l %%k in (1,1,!JDK_COUNT!) do (
    for %%V in (Oracle Adoptium GraalVM Corretto Zulu Microsoft) do (
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
for %%V in (Oracle Adoptium GraalVM Corretto Zulu Microsoft) do (
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
echo %cBLUE%[  INFO  ]%cRESET% Checking vendor API for updates...

set "UPDATE_RESULT=" & set "LOCAL_VER=" & set "REMOTE_VER="

set "UPDATE_CHECKER_PS1=%TEMP%\jvm_update_!RANDOM!.ps1"
(
    echo param^(
    echo     [Parameter^(Mandatory=$true^)][string]$Vendor,
    echo     [Parameter^(Mandatory=$true^)][string]$Major,
    echo     [Parameter^(Mandatory=$true^)][string]$LocalPath
    echo ^)
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
set "PS_CMD=$req = [Net.HttpWebRequest]::Create('https://download.oracle.com/java/!UP_MAJOR!/latest/jdk-!UP_MAJOR!_windows-x64_bin.zip'); $req.Method = 'HEAD'; try { $res = $req.GetResponse(); $res.LastModified.ToString('yyyy-MM-dd') } catch { 'ERROR|' + $_.Exception.Message }"
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
echo %cBLUE%[ ACTION ]%cRESET% Terminating any active Java processes...
taskkill /f /im java.exe >nul 2>&1
taskkill /f /im javaw.exe >nul 2>&1

echo %cBLUE%[ ACTION ]%cRESET% Deleting directory and scrubbing environment variables...
set "ADMIN_BAT=%TEMP%\jvm_admin_!RANDOM!.bat"
(
    echo @echo off
    echo setlocal enabledelayedexpansion
    echo taskkill /f /im java.exe ^>nul 2^>^&1
    echo taskkill /f /im javaw.exe ^>nul 2^>^&1
    echo rmdir /s /q "!DEL_PATH!"
    echo if not exist "%LOCALAPPDATA%\DiamTek\JVM\current\bin\java.exe" ^(
    echo     if exist "%LOCALAPPDATA%\DiamTek\JVM\current" rmdir "%LOCALAPPDATA%\DiamTek\JVM\current"
    echo     reg delete "HKCU\Environment" /v JAVA_HOME /f ^>nul 2^>^&1
    echo ^)
    echo set "SYS_PATH="
    echo for /f "tokens=2*" %%%%A in ^('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^^^>nul'^) do set "SYS_PATH=%%%%B"
    echo if defined SYS_PATH ^(
    echo     set "SYS_PATH=^^!SYS_PATH:!DEL_PATH!\bin;=^^!"
    echo     set "SYS_PATH=^^!SYS_PATH:;!DEL_PATH!\bin=^^!"
    echo     set "SYS_PATH=^^!SYS_PATH:;;=;^^!"
    echo     setx Path "^^!SYS_PATH^^!" /M ^>nul
    echo ^)
) > "!ADMIN_BAT!"

echo %cBLUE%[  INFO  ]%cRESET% Requesting administrative privileges to apply changes...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/v:on /c \"!ADMIN_BAT!\"' -Verb RunAs -WindowStyle Hidden -Wait"
del "!ADMIN_BAT!"

if exist "!DEL_PATH!" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to completely delete directory.
    echo             A file might be locked or in use by another program.
    pause
    goto :eof
)

echo.
echo %cGREEN%[   OK   ]%cRESET% !DEL_NAME! was successfully uninstalled!
set "NEEDS_RESCAN=1"
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

echo Please choose an option:
echo.

if "!IN_PATH!"=="1" (
    echo 1. Remove JVM from User PATH ^(Global Command^) %cGREEN%[INSTALLED]%cRESET%
) else (
    echo 1. Install JVM to User PATH ^(Global Command^)
)
if /i "!SWITCH_MODE!"=="DIRECT" (
    echo 2. Architecture: %cRED%[Registry Mode]%cRESET% ^(UAC Required^) - Click to use Symlink
) else (
    echo 2. Architecture: %cGREEN%[Symlink Mode]%cRESET% ^(UAC Free^) - Click to use Registry
)
echo 3. About JVM ^& Updates
echo 4. Back to Main Menu
echo.

choice /C 1234 /N /M "Enter your choice (1-4): "
set "sub_choice=!errorlevel!"

if !sub_choice!==4 goto :eof
if !sub_choice!==3 (
    call :AboutMenu
    goto :SettingsMenu
)
if !sub_choice!==2 (
    if /i "!SWITCH_MODE!"=="DIRECT" (
        set "SWITCH_MODE=SYMLINK"
        echo.
        echo %cBLUE%[ ACTION ]%cRESET% Scrubbing Machine Registry to prevent Legacy override...
        set "SYS_PATH="
        for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
        
        set PURGE_PATHS="C:\Program Files\Common Files\Oracle\Java\javapath" "C:\Program Files (x86)\Common Files\Oracle\Java\javapath" "C:\ProgramData\Oracle\Java\javapath"
        for /l %%k in (1,1,!JDK_COUNT!) do set PURGE_PATHS=!PURGE_PATHS! "!JDK_PATH_%%k!\bin"
        
        if defined SYS_PATH (
            for %%P in (!PURGE_PATHS!) do (
                set "SYS_PATH=!SYS_PATH:%%~P;=!"
                set "SYS_PATH=!SYS_PATH:;%%~P=!"
                set "SYS_PATH=!SYS_PATH:%%~P=!"
            )
            set "SYS_PATH=!SYS_PATH:;;=;!"
        )
        set "SAFE_SYS_PATH=!SYS_PATH:'=''!"
        
        set "ELEVATE_SCRIPT=%TEMP%\jvm_scrub_!RANDOM!.ps1"
        echo [Environment]::SetEnvironmentVariable^('JAVA_HOME', $null, 'Machine'^) > "!ELEVATE_SCRIPT!"
        echo [Environment]::SetEnvironmentVariable^('Path', '!SAFE_SYS_PATH!', 'Machine'^) >> "!ELEVATE_SCRIPT!"
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""!ELEVATE_SCRIPT!""' -Verb RunAs -Wait" 2>nul
        if exist "!ELEVATE_SCRIPT!" del "!ELEVATE_SCRIPT!"
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

set "NEW_PATH=!USER_PATH!"
for %%D in ("!SCRIPT_DIR!") do (
    set "NEW_PATH=!NEW_PATH:;%%~D=!"
    set "NEW_PATH=!NEW_PATH:%%~D;=!"
    set "NEW_PATH=!NEW_PATH:%%~D=!"
)

reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Registry write failed. Run as Administrator.
) else (
    setx JVM_BROADCAST 1 >nul 2>&1
    reg delete "HKCU\Environment" /v JVM_BROADCAST /f >nul 2>&1
    echo %cGREEN%[   OK   ]%cRESET% User PATH successfully updated.
)

echo.
echo ============================================================
echo %cGREEN%[   OK   ]%cRESET% Removal Complete!
echo %cBLUE%[  INFO  ]%cRESET% You will no longer be able to launch 'jvm' globally.
echo ============================================================
echo.
echo Press any key to return...
pause >nul
goto :eof


rem ============================================================
rem GLOBAL COMMAND INSTALLER (Native & Safe via Temp PS1)
rem ============================================================
:InstallGlobalCommand
rem cls
echo ============================================================
echo                Global Command Installation
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
    echo %cGREEN%[   OK   ]%cRESET% The Java Version Manager is already installed in your system PATH!
    echo              You can run 'jvm' from any terminal.
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

set "USER_PATH=!USER_PATH:"=!"
set "SCRIPT_DIR=!SCRIPT_DIR:"=!"

if not defined USER_PATH (
    set "NEW_PATH=!SCRIPT_DIR!"
) else (
    if "!USER_PATH:~-1!"==";" set "USER_PATH=!USER_PATH:~0,-1!"
    set "NEW_PATH=!USER_PATH!;!SCRIPT_DIR!"
)

if "!NEW_PATH:~-1!"=="\" set "NEW_PATH=!NEW_PATH:~0,-1!"

rem Write safe REG_EXPAND_SZ path update
reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Registry write failed. Run as Administrator.
) else (
    setx JVM_BROADCAST 1 >nul 2>&1
    reg delete "HKCU\Environment" /v JVM_BROADCAST /f >nul 2>&1
    echo %cGREEN%[   OK   ]%cRESET% User PATH successfully updated.
)

rem Write a clean temporary PowerShell script to configure the $PROFILE safely
set "INSTALL_PS1=%TEMP%\jvm_setup_!RANDOM!.ps1"

echo $profileCode = @' > "!INSTALL_PS1!"
echo # ^>^>^> jvm ^>^>^> >> "!INSTALL_PS1!"
echo function jvm { >> "!INSTALL_PS1!"
echo     jvm.bat $args; >> "!INSTALL_PS1!"
echo     $sessionFile = "$env:TEMP\.jvm_session_target"; >> "!INSTALL_PS1!"
echo     if (Test-Path $sessionFile) { >> "!INSTALL_PS1!"
echo         $lines = Get-Content $sessionFile; >> "!INSTALL_PS1!"
echo         $newPaths = @(); >> "!INSTALL_PS1!"
echo         foreach ($line in $lines) { >> "!INSTALL_PS1!"
echo             if ($line -match '^^([^=]+)=(.*)$') { >> "!INSTALL_PS1!"
echo                 $key = $matches[1]; $val = $matches[2]; >> "!INSTALL_PS1!"
echo                 [Environment]::SetEnvironmentVariable($key, $val, 'Process'); >> "!INSTALL_PS1!"
echo                 $newPaths += "$val\bin"; >> "!INSTALL_PS1!"
echo             } elseif (-not [string]::IsNullOrWhiteSpace($line)) { >> "!INSTALL_PS1!"
echo                 $env:JAVA_HOME = $line; >> "!INSTALL_PS1!"
echo                 $newPaths += "$line\bin"; >> "!INSTALL_PS1!"
echo             } >> "!INSTALL_PS1!"
echo         } >> "!INSTALL_PS1!"
echo         if ($newPaths.Count -gt 0) { $env:Path = ($newPaths -join ';') + ';' + $env:Path; } >> "!INSTALL_PS1!"
echo         Remove-Item $sessionFile -Force; >> "!INSTALL_PS1!"
echo     } else { >> "!INSTALL_PS1!"
echo         $vars = @('JAVA_HOME', 'MAVEN_HOME', 'GRADLE_HOME', 'KOTLIN_HOME', 'SCALA_HOME', 'GROOVY_HOME'); >> "!INSTALL_PS1!"
echo         foreach ($v in $vars) { >> "!INSTALL_PS1!"
echo             $val = [System.Environment]::GetEnvironmentVariable($v, 'User'); >> "!INSTALL_PS1!"
echo             if ([string]::IsNullOrEmpty($val)) { $val = [System.Environment]::GetEnvironmentVariable($v, 'Machine'); } >> "!INSTALL_PS1!"
echo             [Environment]::SetEnvironmentVariable($v, $val, 'Process'); >> "!INSTALL_PS1!"
echo         } >> "!INSTALL_PS1!"
echo         $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User'); >> "!INSTALL_PS1!"
echo     } >> "!INSTALL_PS1!"
echo } >> "!INSTALL_PS1!"
echo # ^<^<^< jvm ^<^<^< >> "!INSTALL_PS1!"
echo '@ >> "!INSTALL_PS1!"
echo $p = $PROFILE >> "!INSTALL_PS1!"
echo if (-not (Test-Path $p)) { New-Item -Type File -Path $p -Force ^| Out-Null } >> "!INSTALL_PS1!"
echo $profContent = Get-Content $p -ErrorAction SilentlyContinue ^| Out-String >> "!INSTALL_PS1!"
echo if ($profContent -notmatch '# ^>^>^> jvm ^>^>^>') { >> "!INSTALL_PS1!"
echo     Add-Content -Path $p -Value "`n$profileCode`n" >> "!INSTALL_PS1!"
echo } else { >> "!INSTALL_PS1!"
echo     $profContent = $profContent -replace '(?s)# ^>^>^> jvm ^>^>^>.*?# ^<^<^< jvm ^<^<^<', $profileCode >> "!INSTALL_PS1!"
echo     Set-Content -Path $p -Value $profContent >> "!INSTALL_PS1!"
echo } >> "!INSTALL_PS1!"

powershell -NoProfile -ExecutionPolicy Bypass -File "!INSTALL_PS1!"
pwsh -NoProfile -ExecutionPolicy Bypass -File "!INSTALL_PS1!" 2>nul
if exist "!INSTALL_PS1!" del "!INSTALL_PS1!" >nul 2>&1

echo.
echo ============================================================
echo %cGREEN%[   OK   ]%cRESET% Installation Complete!
echo %cBLUE%[  INFO  ]%cRESET% You can now type 'jvm' from any new command prompt or the Windows Run dialog.
echo ============================================================
echo.
echo Press any key to return...
pause >nul
goto :eof
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
                for /f "tokens=2* delims=:" %%P in ('fsutil reparsepoint query "%%d" 2^>nul ^| findstr /c:"Print Name:"') do (
                    set "RAW_TARGET=%%P:%%Q"
                    for /f "tokens=* delims= " %%A in ("!RAW_TARGET!") do set "LINK_TARGET=%%A"
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
rem JVM Version / About Menu
rem ============================================================
:AboutMenu
rem cls
echo ============================================================
echo                     Java Version Manager
echo ============================================================
echo.
echo Version: !JVM_VERSION!
echo Build:   !JVM_BUILD!
echo.
echo Developed by DiamTek / Alexéy Shishkin
echo Licensed under the GNU AGPL v3.0
echo.
echo ============================================================
echo.
echo %cBLUE%[ ACTION ]%cRESET% Checking for updates...

rem Fetch latest build number from GitHub main branch and compare using PowerShell [version]
set "PS_SCRIPT=$local = [version]'!JVM_BUILD!'; $req = [Net.HttpWebRequest]::Create('https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/jvm.bat'); $req.Method = 'GET'; try { $res = $req.GetResponse(); $stream = $res.GetResponseStream(); $reader = New-Object System.IO.StreamReader($stream); $content = $reader.ReadToEnd(); if ($content -match 'set \x22JVM_BUILD=(.*?)\x22') { $remoteStr = $matches[1]; try { $remote = [version]$remoteStr; if ($remote -gt $local) { Write-Output ('{0}|UPDATE' -f $remoteStr) } else { Write-Output ('{0}|OK' -f $remoteStr) } } catch { Write-Output ('{0}|INVALID_REMOTE' -f $remoteStr) } } else { Write-Output 'UNKNOWN|UNKNOWN' }; $reader.Close(); $res.Close() } catch { Write-Output 'ERROR|ERROR' }"
powershell -NoProfile -ExecutionPolicy Bypass -Command "!PS_SCRIPT!" > "%TEMP%\jvm_remote_build.txt" 2>nul
set "REMOTE_BUILD=UNKNOWN"
set "UPDATE_FLAG=ERROR"
if exist "%TEMP%\jvm_remote_build.txt" (
    for /f "tokens=1,2 delims=|" %%A in (%TEMP%\jvm_remote_build.txt) do (
        set "REMOTE_BUILD=%%A"
        set "UPDATE_FLAG=%%B"
    )
    del "%TEMP%\jvm_remote_build.txt" >nul 2>&1
)

if "!UPDATE_FLAG!"=="ERROR" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to connect to GitHub. Please check your internet connection.
    echo.
    echo Press any key to return...
    pause >nul
    goto :eof
)

if "!UPDATE_FLAG!"=="UNKNOWN" (
    echo %cYELLOW%[ WARNING]%cRESET% Could not parse remote build version.
    echo.
    echo Press any key to return...
    pause >nul
    goto :eof
)

if "!UPDATE_FLAG!"=="INVALID_REMOTE" (
    echo %cYELLOW%[ WARNING]%cRESET% Remote build '!REMOTE_BUILD!' is not a valid Semantic Version.
    echo.
    echo Press any key to return...
    pause >nul
    goto :eof
)

if "!UPDATE_FLAG!"=="UPDATE" (
    echo %cYELLOW%[ UPDATE ]%cRESET% A newer version of Java Version Manager is available!
    echo            Local Build:  !JVM_BUILD!
    echo            Remote Build: !REMOTE_BUILD!
    echo.
    choice /C yn /N /M "Would you like to download and install this update? (y/N): "
    if !errorlevel! EQU 1 (
        call :SelfUpdate
    )
    goto :eof
) else (
    echo %cGREEN%[   OK   ]%cRESET% You are running the latest version!
    echo.
    echo Press any key to return...
    pause >nul
    goto :eof
)

rem ============================================================
rem Self-Updater
rem ============================================================
:SelfUpdate
if "!CLI_COMMAND!"=="self-update" if "!FORCE_YES!" NEQ "1" (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking for updates...
    
    set "PS_SCRIPT=$local = [version]'!JVM_BUILD!'; $req = [Net.HttpWebRequest]::Create('https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/jvm.bat'); $req.Method = 'GET'; try { $res = $req.GetResponse(); $stream = $res.GetResponseStream(); $reader = New-Object System.IO.StreamReader($stream); $content = $reader.ReadToEnd(); if ($content -match 'set \x22JVM_BUILD=(.*?)\x22') { $remoteStr = $matches[1]; try { $remote = [version]$remoteStr; if ($remote -gt $local) { Write-Output ('{0}|UPDATE' -f $remoteStr) } else { Write-Output ('{0}|OK' -f $remoteStr) } } catch { Write-Output ('{0}|INVALID_REMOTE' -f $remoteStr) } } else { Write-Output 'UNKNOWN|UNKNOWN' }; $reader.Close(); $res.Close() } catch { Write-Output 'ERROR|ERROR' }"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "!PS_SCRIPT!" > "%TEMP%\jvm_remote_build.txt" 2>nul
    set "REMOTE_BUILD=UNKNOWN"
    set "UPDATE_FLAG=ERROR"
    if exist "%TEMP%\jvm_remote_build.txt" (
        for /f "tokens=1,2 delims=|" %%A in (%TEMP%\jvm_remote_build.txt) do (
            set "REMOTE_BUILD=%%A"
            set "UPDATE_FLAG=%%B"
        )
        del "%TEMP%\jvm_remote_build.txt" >nul 2>&1
    )

    if "!UPDATE_FLAG!"=="ERROR" (
        echo %cRED%[ ERROR  ]%cRESET% Failed to connect to GitHub. Please check your internet connection.
        goto :eof
    )
    if "!UPDATE_FLAG!"=="UNKNOWN" (
        echo %cYELLOW%[ WARNING]%cRESET% Could not parse remote build version.
        goto :eof
    )
    if "!UPDATE_FLAG!"=="INVALID_REMOTE" (
        echo %cYELLOW%[ WARNING]%cRESET% Remote build '!REMOTE_BUILD!' is not a valid Semantic Version.
        goto :eof
    )
    if "!UPDATE_FLAG!"=="OK" (
        echo %cGREEN%[   OK   ]%cRESET% You are already running the latest version ^(!JVM_BUILD!^).
        goto :eof
    )
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Connecting to GitHub repository...

set "DL_URL=https://raw.githubusercontent.com/DiamTek/Java-Version-Manager-Windows/main/jvm.bat"
set "DL_ZIP=%TEMP%\jvm_new.bat"
set "DL_EXTRACT="
set "DL_CHKSUM_URL="
set "DL_CHKSUM_VAL="
set "DL_STRIP_ROOT=0"

call :ExecuteSharedDownloader
if !errorlevel! NEQ 0 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Failed to download the latest update.
    pause
    goto :eof
)

rem Sanitize LF line endings and hidden spaces after download to prevent the 'cho' bug
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c = [IO.File]::ReadAllText('%TEMP%\jvm_new.bat'); $c = $c.Replace([char]160, ' ') -replace '(?<!\r)\n', [Environment]::NewLine; [IO.File]::WriteAllText('%TEMP%\jvm_new.bat', $c, (New-Object System.Text.UTF8Encoding $false))" 2>nul

for %%I in ("%TEMP%\jvm_new.bat") do set "NEW_SIZE=%%~zI"
if !NEW_SIZE! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Downloaded file is empty.
    pause
    goto :eof
)

findstr /C:"rem END OF SCRIPT" "%TEMP%\jvm_new.bat" >nul 2>&1
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Downloaded file failed integrity check. The file may be corrupted or truncated.
    pause
    goto :eof
)

echo %cBLUE%[ ACTION ]%cRESET% Generating background updater...
set "UPDATER_SCRIPT=%TEMP%\jvm_updater.bat"
(
echo @echo off
echo echo.
echo echo %cBLUE%[ ACTION ]%cRESET% Overwriting main script...
echo copy /Y "%%TEMP%%\jvm_new.bat" "%~f0" ^>nul
echo if errorlevel 1 ^(
echo     echo %cRED%[ ERROR  ]%cRESET% Failed to overwrite jvm.bat!
echo     pause
echo     exit /b 1
echo ^)
echo del "%%TEMP%%\jvm_new.bat" ^>nul
echo echo %cGREEN%[   OK   ]%cRESET% Java Version Manager successfully updated!
echo echo.
echo timeout /t 2 /nobreak ^>nul
echo "%~f0"
) > "!UPDATER_SCRIPT!"

echo %cGREEN%[   OK   ]%cRESET% Update downloaded! Initiating handoff...
"!UPDATER_SCRIPT!"

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
    if /i "%%W"=="open" set "CLI_VENDOR=Oracle"
    if /i "%%W"=="graal" set "CLI_VENDOR=GraalVM"
    if /i "%%W"=="graalce" set "CLI_VENDOR=GraalVM"
    if /i "%%W"=="oracle" set "CLI_VENDOR=Oracle"
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
for /f "tokens=2*" %%P in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    set "USR_PATH=%%Q"
)
if "!USR_PATH!"=="" set "USR_PATH=%PATH%"

echo !USR_PATH! | findstr /i "%%!CANDIDATE_ENV_VAR!%%\bin" >nul
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
echo !PATH! | findstr /i "!SYMLINK_PATH!\bin" >nul
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

if not defined TARGET_VER (
    echo %cRED%[ ERROR  ]%cRESET% No version specified. Usage: jvm install !TARGET_CANDIDATE! latest
    exit /b 1
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
)
if /i "!TARGET_CANDIDATE!"=="groovy" (
    set "DOWNLOAD_URL=https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/apache-groovy-binary-!TARGET_VER!.zip"
    set "CHECKSUM_URL=https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/apache-groovy-binary-!TARGET_VER!.zip.sha256"
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
    echo %cRED%[ ERROR  ]%cRESET% Please specify the version to uninstall. Usage: jvm uninstall !TARGET_CANDIDATE! ^<version^>
    exit /b 1
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
for /f "tokens=2*" %%A in ('fsutil reparsepoint query "!SYMLINK_PATH!" 2^>nul ^| findstr /i "Print Name:"') do (
    if /i "%%B"=="!TARGET_PATH!" (
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
for /f "delims=" %%V in ('powershell -NoProfile -Command "Get-ChildItem -Path '%%C' -Directory | Where-Object { $_.Name -ne 'current' } | Sort-Object { [version]($_.Name -replace '-.*','') } -Descending | Select-Object -ExpandProperty Name"') do (
        set "V_NAME=%%V"
        set "IS_ACTIVE="
        for /f "tokens=2*" %%A in ('fsutil reparsepoint query "%%C\current" 2^>nul ^| findstr /i "Print Name:"') do (
            if /i "%%B"=="%%~fC\%%V" set "IS_ACTIVE= %cGREEN%[ACTIVE]%cRESET%"
        )
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
if /i "!TARGET_CANDIDATE!"=="maven" set "PS_RESOLVE_LATEST=$url='https://api.github.com/repos/apache/maven/releases/latest'; try { ((Invoke-RestMethod -Uri $url -UseBasicParsing).tag_name).Replace('maven-','') } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="gradle" set "PS_RESOLVE_LATEST=$url='https://services.gradle.org/versions/current'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing).version } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="kotlin" set "PS_RESOLVE_LATEST=$url='https://api.github.com/repos/JetBrains/kotlin/releases/latest'; try { ((Invoke-RestMethod -Uri $url -UseBasicParsing).tag_name).TrimStart('v') } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="scala" set "PS_RESOLVE_LATEST=$url='https://api.github.com/repos/scala/scala3/releases/latest'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing).tag_name } catch { 'ERROR' }"
if /i "!TARGET_CANDIDATE!"=="groovy" set "PS_RESOLVE_LATEST=$url='https://api.sdkman.io/2/candidates/default/groovy'; try { (Invoke-RestMethod -Uri $url -UseBasicParsing) } catch { 'ERROR' }"

set "LATEST_VER=ERROR"
for /f "delims=" %%V in ('powershell -NoProfile -Command "!PS_RESOLVE_LATEST!"') do (
    set "LATEST_VER=%%V"
)
exit /b 0

rem ============================================================
rem Universal Downloader & Extractor (PowerShell)
rem ============================================================
:ExecuteSharedDownloader
set "PS_SCRIPT=%TEMP%\jvm_dl_!RANDOM!.ps1"
(
    echo $ErrorActionPreference = 'Stop'
    echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    echo try {
    echo     Write-Host '[ ACTION ] Downloading from !DL_URL! ...' -ForegroundColor Cyan
    echo     $url = '!DL_URL!'
    echo     $out = '!DL_ZIP!'
    echo     $request = [System.Net.WebRequest]::Create^($url^)
    echo     $response = $request.GetResponse^(^)
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
    echo     if ^('!DL_CHKSUM_URL!' -ne '' -or '!DL_CHKSUM_VAL!' -ne ''^) {
    echo         $cryptoType = '!DL_CHKSUM_TYPE!'
    echo         Write-Host "[ ACTION ] Verifying $cryptoType checksum..." -ForegroundColor Cyan
    echo         if ^('!DL_CHKSUM_URL!' -ne ''^) {
    echo             try {
    echo                 $expectedHash = ^(Invoke-RestMethod -Uri '!DL_CHKSUM_URL!' -UseBasicParsing^).Trim^(^)
    echo             } catch {
    echo                 if ^('!DL_CHKSUM_URL!' -match '\.sha512$'^) {
    echo                     Write-Host "[ WARNING] SHA512 checksum not found, falling back to SHA1..." -ForegroundColor Yellow
    echo                     $fallbackUrl = '!DL_CHKSUM_URL!' -replace '\.sha512$', '.sha1'
    echo                     $expectedHash = ^(Invoke-RestMethod -Uri $fallbackUrl -UseBasicParsing^).Trim^(^)
    echo                     $cryptoType = 'SHA1'
    echo                 } else { throw $_ }
    echo             }
    echo             $expectedHash = ^($expectedHash -split ' '^)[0]
    echo         } else {
    echo             $expectedHash = '!DL_CHKSUM_VAL!'
    echo         }
    echo         $crypto = [System.Security.Cryptography.HashAlgorithm]::Create^($cryptoType^)
    echo         $fs2 = [System.IO.File]::OpenRead^('!DL_ZIP!'^)
    echo         $hashBytes = $crypto.ComputeHash^($fs2^)
    echo         $fs2.Close^(^)
    echo         $actualHash = [System.BitConverter]::ToString^($hashBytes^).Replace^('-', ''^).ToLower^(^)
    echo         if ^($actualHash -ne $expectedHash^) {
    echo             Write-Host '[ ERROR  ] Checksum mismatch! Download corrupted or compromised.' -ForegroundColor Red
    echo             Write-Host "           Expected: $expectedHash" -ForegroundColor Red
    echo             Write-Host "           Actual:   $actualHash" -ForegroundColor Red
    echo             exit 1
    echo         }
    echo         Write-Host '[   OK   ] Checksum verified successfully.' -ForegroundColor Green
    echo         Write-Host ""
    echo     }
    echo     if ^('!DL_EXTRACT!' -ne ''^) {
    echo         Write-Host '[ ACTION ] Extracting archive...' -ForegroundColor Cyan
    echo         Add-Type -AssemblyName System.IO.Compression.FileSystem
    echo         $zip = [System.IO.Compression.ZipFile]::OpenRead^('!DL_ZIP!'^)
    echo         $entries = $zip.Entries
    echo         $totalEntries = $entries.Count
    echo         $extracted = 0
    echo         $lastPercent = -1
    echo         foreach ^($entry in $entries^) {
    echo             $destinationPath = [System.IO.Path]::GetFullPath^([System.IO.Path]::Combine^('!DL_EXTRACT!', $entry.FullName^)^)
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

rem END OF SCRIPT