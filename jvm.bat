@echo off
:: Java Version Manager
:: Copyright (C) 2026 DiamTek / Alexéy Shishkin
::
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU Affero General Public License as
:: published by the Free Software Foundation, either version 3 of the
:: License, or (at your option) any later version.
::
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU Affero General Public License for more details.
::
:: You should have received a copy of the GNU Affero General Public License
:: along with this program.  If not, see <https://www.gnu.org/licenses/>.

setlocal enabledelayedexpansion

:: Cleanup self-updater artifact if it exists
if exist "%TEMP%\jvm_updater.bat" del "%TEMP%\jvm_updater.bat" >nul 2>&1

title Java Version Manager

set "JVM_VERSION=0.6.0"
set "JVM_BUILD=20260830.1"

:: Generate ESC character for ANSI color codes
for /F "delims=#" %%a in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"
set "cRED=%ESC%[91m"
set "cGREEN=%ESC%[92m"
set "cYELLOW=%ESC%[93m"
set "cBLUE=%ESC%[96m"
set "cGRAY=%ESC%[90m"
set "cRESET=%ESC%[0m"

:: Define base JDK search locations BEFORE delayed expansion to prevent exclamation mark corruption
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

:: Parse .java-version and establish mode BEFORE changing directories or checking UAC!
set "SILENT_MODE=0"
set "CLI_TARGET="
set "SESSION_MODE=0"
set "ORIGINAL_ARGS=%*"
set "SCRIPT_PATH=%~f0"

set "SWITCH_MODE=SYMLINK"
if exist "%USERPROFILE%\.jvm\mode.txt" (
    set /p SWITCH_MODE=<"%USERPROFILE%\.jvm\mode.txt"
)
if "!SWITCH_MODE!"=="" set "SWITCH_MODE=SYMLINK"

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
:PARSE_CLI_ARGS
if "%~1"=="" goto :PARSE_DONE
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

:: If a target was provided via CLI, set variables
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
        if not "%FORCE_GLOBAL%"=="1" set "SESSION_MODE=1"
        set "SILENT_MODE=1"
        set "SKIP_HEADER=1"
    )
)

if /i "%CLI_COMMAND%"=="clear" set "SKIP_HEADER=1"

:: Check if the script is running as Administrator
if "%SESSION_MODE%"=="1" goto :SKIP_ADMIN_CHECK
if defined CLI_COMMAND (
    if /i "%CLI_COMMAND%"=="list" goto :SKIP_ADMIN_CHECK
    if /i "%CLI_COMMAND%"=="env" goto :SKIP_ADMIN_CHECK
)
if defined CLI_COMMAND (
    if /i "%CLI_COMMAND%"=="list" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="env" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="update" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="self-update" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="version" set "SKIP_HEADER=1"
)
:: By default, run everything inline without Admin. We only elevate for specific file/registry operations.
goto :SKIP_ADMIN_CHECK

:SKIP_ADMIN_CHECK

:: CRITICAL: Set the working directory to the script's location
cd /d "%~dp0"
:MAIN_LOOP
:: Clear the variable before calling the menu to ensure a clean state
set "CURRENT_JDK_PATH="

:: Reload config in case it was changed inside a setlocal block
if exist "%USERPROFILE%\.jvm\mode.txt" (
    set /p SWITCH_MODE=<"%USERPROFILE%\.jvm\mode.txt"
)
if "%SWITCH_MODE%"=="" set "SWITCH_MODE=SYMLINK"

if defined SWITCH_MODE_OVERRIDE (
    set "SWITCH_MODE=%SWITCH_MODE_OVERRIDE%"
)

:: Jump straight to the menu function to prevent screen clearing issues
call :ShowDynamicMenu %*

:: If CURRENT_JDK_PATH is not set, the user chose the Exit option
if not defined CURRENT_JDK_PATH (
    exit /B 0
)

if "%CURRENT_JDK_PATH%"=="CLEAR" (
    call :ClearJavaEnvironment
    set "PATH=%CLEAN_PATH%"
    set "JAVA_HOME="
    set "CURRENT_JDK_PATH="
    goto MAIN_LOOP
)

if "%SESSION_MODE%"=="1" (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Session mode active. Setting Java to %CURRENT_JDK_PATH%...
    echo %CURRENT_JDK_PATH%> "%TEMP%\.jvm_session_target"
    echo %cGREEN%[   OK   ]%cRESET% Session target saved.
    
    :: Update local session for verification
    set "JAVA_HOME=%CURRENT_JDK_PATH%"
    set "PATH=%CURRENT_JDK_PATH%\bin;%PATH%"
    goto :VERIFICATION
)

echo.
set "JVM_DIR=%USERPROFILE%\.jvm"
set "CURRENT_SYMLINK=%USERPROFILE%\.jvm\current"

if /i "%SWITCH_MODE%"=="DIRECT" (
    echo %cBLUE%[ ACTION ]%cRESET% Setting Java to %CURRENT_JDK_PATH%...
    echo %cBLUE%[  INFO  ]%cRESET% Setting JAVA_HOME to: %CURRENT_JDK_PATH%
    
    :: Output session target so the parent PowerShell window can sync immediately
    echo %CURRENT_JDK_PATH%> "%TEMP%\.jvm_session_target"
    
    :: Deferring registry update to UpdateSystemPath to do both in one UAC prompt
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
    
    echo %CURRENT_SYMLINK%> "%TEMP%\.jvm_session_target"
    
    :: Ensure JAVA_HOME permanently points to the junction in the USER registry (bypasses UAC)
    if /i not "%JAVA_HOME%"=="%CURRENT_SYMLINK%" (
        echo.
        echo %cBLUE%[  INFO  ]%cRESET% Setting JAVA_HOME to: %CURRENT_SYMLINK%
        setx JAVA_HOME "%CURRENT_SYMLINK%" >nul
        if errorlevel 1 (
            echo %cRED%[ ERROR  ]%cRESET% Failed to set JAVA_HOME in registry
            pause
            goto MAIN_LOOP
        )
        echo %cGREEN%[   OK   ]%cRESET% JAVA_HOME set successfully via Symlink Mode.
    )
    
    set "SYMLINK_OR_DIRECT=%CURRENT_SYMLINK%"
)

:: Ensure system PATH permanently uses %JAVA_HOME%\bin
echo.
echo %cBLUE%[ ACTION ]%cRESET% Ensuring system PATH uses %%JAVA_HOME%%\bin...
call :UpdateSystemPath


:: Clean the current session PATH dynamically to prevent duplicates
setlocal enabledelayedexpansion
set "CLEAN_PATH=!PATH!"

:: Strip the OLD Java Home if it exists
if defined JAVA_HOME (
    set "CLEAN_PATH=!CLEAN_PATH:%JAVA_HOME%\bin;=!"
    set "CLEAN_PATH=!CLEAN_PATH:;%JAVA_HOME%\bin=!"
)
:: Strip the NEW path just in case to prevent doubling up
set "CLEAN_PATH=!CLEAN_PATH:%SYMLINK_OR_DIRECT%\bin;=!"
set "CLEAN_PATH=!CLEAN_PATH:;%SYMLINK_OR_DIRECT%\bin=!"
:: Strip the hardcoded JDK path just in case
set "CLEAN_PATH=!CLEAN_PATH:%CURRENT_JDK_PATH%\bin;=!"
set "CLEAN_PATH=!CLEAN_PATH:;%CURRENT_JDK_PATH%\bin=!"
:: Remove double semicolons
set "CLEAN_PATH=!CLEAN_PATH:;;=;!"

:: Export the clean path back to the main session and apply at the front
for /f "delims=" %%A in ("!CLEAN_PATH!") do (
    endlocal & set "PATH=%SYMLINK_OR_DIRECT%\bin;%%A"
)

:: Finally update the local JAVA_HOME
set "JAVA_HOME=%SYMLINK_OR_DIRECT%"


:VERIFICATION
:: Verify the changes
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


:: ============================================================
:: FUNCTIONS
:: ============================================================

:: Function to dynamically scan and display menu
:ShowDynamicMenu
setlocal enabledelayedexpansion

:RESCAN_MENU
if "!SKIP_HEADER!"=="0" (
    cls
    echo ============================================================
    echo                     Java Version Manager
    echo ============================================================
    echo.

    :: Display current Java info HERE so it survives the 'cls'
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



set JDK_COUNT=0
set "LATEST_VER_NUM=0"
set "LATEST_LTS_NUM=0"
set "LATEST_JDK_PATH="
set "LATEST_JDK_NAME="
set "ORACLE_LATEST_FEATURE=26"
set "ORACLE_LATEST_LTS=25"

:: The LOCATIONS array is populated at the top of the script to prevent delayed expansion corruption

:: Find all JDK folders
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
                        
                        :: Parse version to find the latest
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
                                for /f "tokens=1 delims=." %%V in ("!VER_STR!") do set "VER=%%V"
                            )
                        )
                        set "NUM_VER=0"
                        set /a "NUM_VER=!VER!" 2>nul
                        set "JDK_VENDOR_!JDK_COUNT!=!VENDOR_STR!"
                        
                        if /i "%%j"=="current" (
                            for %%D in ("!LOCATIONS[%%i]!") do set "APP_NAME=%%~nxD"
                            set "JDK_NAME_!JDK_COUNT!=Scoop !APP_NAME! (!NUM_VER!)"
                            set "LATEST_JDK_NAME_CANDIDATE=Scoop !APP_NAME!"
                        ) else (
                            set "JDK_NAME_!JDK_COUNT!=%%j"
                            set "LATEST_JDK_NAME_CANDIDATE=%%j"
                        )
                        
                        :: Store the major version specifically for the menu display
                        set "JDK_MAJOR_!JDK_COUNT!=!NUM_VER!"
                        
                        if !NUM_VER! GTR !LATEST_VER_NUM! (
                            set "LATEST_VER_NUM=!NUM_VER!"
                            set "LATEST_JDK_PATH=!LOCATIONS[%%i]!\%%j"
                            set "LATEST_JDK_NAME=!LATEST_JDK_NAME_CANDIDATE!"
                        )
                        
                        :: Track highest LTS version
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

:: Sort JDKs by major version (descending)
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

if defined CLI_COMMAND (
    if /i "!CLI_COMMAND!"=="list" (
        echo. 
        echo %cBLUE%[  INFO  ]%cRESET% Installed JDKs:
        echo ============================================================
        for /l %%k in (1,1,!JDK_COUNT!) do (
            set "ACTIVE_TAG="
            if /i "!JDK_PATH_%%k!"=="!JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
            echo  %%k. JDK !JDK_MAJOR_%%k! ^(!JDK_NAME_%%k!^) - !JDK_VENDOR_%%k!!ACTIVE_TAG!
            echo     Path: !JDK_PATH_%%k!
            echo.
        )
        echo ============================================================
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
    if defined CLI_COMMAND (
    if /i "%CLI_COMMAND%"=="list" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="env" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="update" set "SKIP_HEADER=1"
)
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
                echo             Usage: jvm update ^<version_number^>
                echo             Usage: jvm update --all [--vendor ^<name^>]
            )
        ) else if /i "!CLI_TARGET!"=="--all" (
            if defined CLI_VENDOR (
                echo %cBLUE%[ ACTION ]%cRESET% Automatically updating all !CLI_VENDOR! JDKs...
                echo.
                for /l %%k in (1,1,!JDK_COUNT!) do (
                    if /i "!JDK_VENDOR_%%k!"=="!CLI_VENDOR!" call :ProcessSingleUpdate %%k
                )
            ) else (
                echo %cBLUE%[ ACTION ]%cRESET% Automatically updating ALL JDKs...
                for /l %%k in (1,1,!JDK_COUNT!) do call :ProcessSingleUpdate %%k
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
            echo             Usage: jvm uninstall ^<version_number^>
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
                if not exist "%USERPROFILE%\.jvm\current\bin\java.exe" (
                    if exist "%USERPROFILE%\.jvm\current" rmdir "%USERPROFILE%\.jvm\current"
                    reg delete "HKCU\Environment" /v JAVA_HOME /f >nul 2^>^&1
                )
                set "SYS_PATH="
                for /f "tokens=2 delims==" %%A in ('wmic environment where "name='Path' and username='<system>'" get VariableValue /value 2^^^>nul') do set "SYS_PATH=%%A"
                if defined SYS_PATH (
                    set "SYS_PATH=!SYS_PATH:%DEL_PATH%\bin;=!"
                    set "SYS_PATH=!SYS_PATH:;%DEL_PATH%\bin=!"
                    set "SYS_PATH=!SYS_PATH:;;=;!"
                    setx Path "!SYS_PATH!" /M >nul
                )
                set "USR_PATH="
                for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^^^>nul') do set "USR_PATH=%%B"
                if defined USR_PATH (
                    set "USR_PATH=!USR_PATH:%DEL_PATH%\bin;=!"
                    set "USR_PATH=!USR_PATH:;%DEL_PATH%\bin=!"
                    set "USR_PATH=!USR_PATH:;;=;!"
                    setx Path "!USR_PATH!" >nul
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
                powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath \"$env:SCRIPT_PATH\" -WorkingDirectory \"$env:WORK_DIR\" -ArgumentList '--admin-run', \"$env:UAC_ARGS\" -Verb RunAs -WindowStyle Hidden -Wait"
                
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

if defined CLI_COMMAND (
    if /i "%CLI_COMMAND%"=="list" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="env" set "SKIP_HEADER=1"
    if /i "%CLI_COMMAND%"=="update" set "SKIP_HEADER=1"
)
if defined CLI_TARGET (
    echo %cBLUE%[ INFO ]%cRESET% Target JDK !CLI_TARGET! detected...
    :: Resolve Semantic Aliases
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
            :: Return to MAIN_LOOP to apply the changes
            for /f "delims=" %%P in ("!CURRENT_JDK_PATH!") do (
                endlocal & set "CURRENT_JDK_PATH=%%P"
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
    :: Safety catch: If we are hidden and CLI_TARGET was empty, abort so we don't hang!
    goto :eof
)

:: Show main menu
echo Please choose an option:
echo.
echo 1. Path ^& Environment Management
echo 2. Version Management
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

if !choice!==1 (
    call :PathEnvironmentMenu
    if defined CURRENT_JDK_PATH (
        for /f "delims=" %%P in ("!CURRENT_JDK_PATH!") do (
            endlocal & set "CURRENT_JDK_PATH=%%P"
        )
        goto :eof
    )
    goto RESCAN_MENU
)

if !choice!==2 (
    call :VersionMenu
    goto RESCAN_MENU
)

:: Catch-all to prevent falling through if choice errors out
goto RESCAN_MENU


:: ============================================================
:: JDK UPDATER 
:: ============================================================
:UpdateJDKs
cls
echo ============================================================
echo                     JDK Update Checker
echo ============================================================
echo.

set "TARGET_IDX="

if not "%~1"=="" (
    set "TARGET_IDX=%~1"
    for %%A in (!TARGET_IDX!) do (
        call :ProcessSingleUpdate %%A
    )
    goto FINISH_UPDATE
)

if !JDK_COUNT!==0 (
    echo %cYELLOW%[ WARNING]%cRESET% No JDKs found to update.
    pause
    goto :eof
)

echo %cBLUE%[ ACTION ]%cRESET% Select vendor to check for updates:
echo.
set /a U_OPT=0
set "OPT_ALL="
set "OPT_U_ORACLE="
set "OPT_U_ADOPTIUM="
set "OPT_U_GRAALVM="
set "OPT_U_CORRETTO="
set "OPT_U_ZULU="
set "OPT_U_MICROSOFT="

set "HAS_ORACLE=0"
set "HAS_ADOPTIUM=0"
set "HAS_GRAALVM=0"
set "HAS_CORRETTO=0"
set "HAS_ZULU=0"
set "HAS_MICROSOFT=0"

for /l %%k in (1,1,!JDK_COUNT!) do (
    if /i "!JDK_VENDOR_%%k!"=="Oracle" set "HAS_ORACLE=1"
    if /i "!JDK_VENDOR_%%k!"=="Adoptium" set "HAS_ADOPTIUM=1"
    if /i "!JDK_VENDOR_%%k!"=="GraalVM" set "HAS_GRAALVM=1"
    if /i "!JDK_VENDOR_%%k!"=="Corretto" set "HAS_CORRETTO=1"
    if /i "!JDK_VENDOR_%%k!"=="Zulu" set "HAS_ZULU=1"
    if /i "!JDK_VENDOR_%%k!"=="Microsoft" set "HAS_MICROSOFT=1"
)

set /a U_OPT+=1
set "OPT_ALL=!U_OPT!"
echo !OPT_ALL!. All Installed JDKs

if "!HAS_ORACLE!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_ORACLE=!U_OPT!"
    echo !OPT_U_ORACLE!. Oracle
)
if "!HAS_ADOPTIUM!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_ADOPTIUM=!U_OPT!"
    echo !OPT_U_ADOPTIUM!. Adoptium
)
if "!HAS_GRAALVM!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_GRAALVM=!U_OPT!"
    echo !OPT_U_GRAALVM!. GraalVM
)
if "!HAS_CORRETTO!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_CORRETTO=!U_OPT!"
    echo !OPT_U_CORRETTO!. Corretto
)
if "!HAS_ZULU!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_ZULU=!U_OPT!"
    echo !OPT_U_ZULU!. Zulu
)
if "!HAS_MICROSOFT!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_MICROSOFT=!U_OPT!"
    echo !OPT_U_MICROSOFT!. Microsoft
)

set /a U_OPT+=1
set "OPT_U_CANCEL=!U_OPT!"
echo !OPT_U_CANCEL!. Cancel

set "U_KEYS="
for /l %%k in (1,1,!U_OPT!) do set "U_KEYS=!U_KEYS!%%k"

echo.
choice /C !U_KEYS! /N /M "Select option (1-!U_OPT!): "
set "v_choice=!errorlevel!"

if !v_choice!==!OPT_U_CANCEL! goto :eof

if !v_choice!==!OPT_ALL! (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking ALL JDKs for updates...
    for /l %%k in (1,1,!JDK_COUNT!) do call :ProcessSingleUpdate %%k
    goto FINISH_UPDATE
)

if defined OPT_U_ORACLE if !v_choice!==!OPT_U_ORACLE! (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking Oracle JDKs for updates...
    for /l %%k in (1,1,!JDK_COUNT!) do (
        if /i "!JDK_VENDOR_%%k!"=="Oracle" call :ProcessSingleUpdate %%k
    )
    goto FINISH_UPDATE
)
if defined OPT_U_ADOPTIUM if !v_choice!==!OPT_U_ADOPTIUM! (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking Adoptium JDKs for updates...
    for /l %%k in (1,1,!JDK_COUNT!) do (
        if /i "!JDK_VENDOR_%%k!"=="Adoptium" call :ProcessSingleUpdate %%k
    )
    goto FINISH_UPDATE
)
if defined OPT_U_GRAALVM if !v_choice!==!OPT_U_GRAALVM! (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking GraalVM JDKs for updates...
    for /l %%k in (1,1,!JDK_COUNT!) do (
        if /i "!JDK_VENDOR_%%k!"=="GraalVM" call :ProcessSingleUpdate %%k
    )
    goto FINISH_UPDATE
)
if defined OPT_U_CORRETTO if !v_choice!==!OPT_U_CORRETTO! (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking Corretto JDKs for updates...
    for /l %%k in (1,1,!JDK_COUNT!) do (
        if /i "!JDK_VENDOR_%%k!"=="Corretto" call :ProcessSingleUpdate %%k
    )
    goto FINISH_UPDATE
)
if defined OPT_U_ZULU if !v_choice!==!OPT_U_ZULU! (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking Zulu JDKs for updates...
    for /l %%k in (1,1,!JDK_COUNT!) do (
        if /i "!JDK_VENDOR_%%k!"=="Zulu" call :ProcessSingleUpdate %%k
    )
    goto FINISH_UPDATE
)
if defined OPT_U_MICROSOFT if !v_choice!==!OPT_U_MICROSOFT! (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking Microsoft JDKs for updates...
    for /l %%k in (1,1,!JDK_COUNT!) do (
        if /i "!JDK_VENDOR_%%k!"=="Microsoft" call :ProcessSingleUpdate %%k
    )
    goto FINISH_UPDATE
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

set "UPDATE_RESULT="
set "LOCAL_VER="
set "REMOTE_VER="

for /f "tokens=1,* delims=|" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.gemini\antigravity\brain\1d94625a-4bc1-4f01-8d91-aa2a8ccf6e22\scratch\UpdateChecker.ps1" -Vendor "!UP_VENDOR!" -Major "!UP_MAJOR!" -LocalPath "!UP_PATH!"') do (
    if "%%A"=="ORACLE_LEGACY" goto :Update_OracleLegacy
    if "%%A"=="LOCAL" set "LOCAL_VER=%%B"
    if "%%A"=="REMOTE" set "REMOTE_VER=%%B"
    if "%%A"=="RESULT" set "UPDATE_RESULT=%%B"
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
set "PS_CMD=$req = [Net.HttpWebRequest]::Create('https://download.oracle.com/java/!UP_MAJOR!/latest/jdk-!UP_MAJOR!_windows-x64_bin.zip'); $req.Method = 'HEAD'; try { $res = $req.GetResponse(); $res.LastModified.ToString('yyyy-MM-dd') } catch { 'UNKNOWN' }"
for /f "delims=" %%I in ('powershell -NoProfile -Command "!PS_CMD!"') do set "REMOTE_DATE=%%I"
set "LOCAL_DATE=UNKNOWN"
if exist "!UP_PATH!\release" (
    for /f "tokens=2 delims==" %%A in ('findstr "JAVA_VERSION_DATE" "!UP_PATH!\release"') do (
        set "LOCAL_DATE=%%~A"
    )
)
echo %cBLUE%[  INFO  ]%cRESET% Local Build Date : !LOCAL_DATE!
echo %cBLUE%[  INFO  ]%cRESET% Remote Build Date: !REMOTE_DATE!

if "!REMOTE_DATE!"=="UNKNOWN" (
    echo %cRED%[ ERROR  ]%cRESET% Could not connect to Oracle servers.
    goto :eof
)
if "!LOCAL_DATE!"=="!REMOTE_DATE!" (
    echo %cGREEN%[   OK   ]%cRESET% You are already running the latest build of JDK !UP_MAJOR!!
    goto :eof
)
if "!LOCAL_DATE!" NEQ "UNKNOWN" (
    if "!LOCAL_DATE!" GTR "!REMOTE_DATE!" (
        echo %cGREEN%[   OK   ]%cRESET% Your local build is newer than the current Oracle release!
        goto :eof
    )
)
if defined CLI_COMMAND (
    if /i "!CLI_TARGET!"=="" (
        echo %cYELLOW%[ UPDATE ]%cRESET% A newer build is available! Run 'jvm update !UP_MAJOR!' to install.
        goto :eof
    )
    echo %cYELLOW%[ UPDATE ]%cRESET% A newer build is available!
) else (
    echo %cYELLOW%[ UPDATE ]%cRESET% A newer build is available!
    choice /C yn /N /M "Would you like to download and install this update? (y/N): "
    if !errorlevel! NEQ 1 goto :eof
)

:TriggerUpdateDownload
echo.
echo %cGREEN%[ DOWNLOAD ]%cRESET% Fetching newest JDK !UP_MAJOR! from !UP_VENDOR!...
set "CLI_VENDOR=!UP_VENDOR!"
set "DL_VERSION=!UP_MAJOR!"
set "IS_UPDATER=1"
goto :Resolve_!UP_VENDOR!
:UninstallJDK
cls
echo ============================================================
echo                     JDK Uninstaller
echo ============================================================
echo.
echo %cBLUE%[ ACTION ]%cRESET% Select vendor to uninstall from:
echo.
set /a U_OPT=0
set "OPT_U_ORACLE="
set "OPT_U_ADOPTIUM="
set "OPT_U_GRAALVM="
set "OPT_U_CORRETTO="
set "OPT_U_ZULU="
set "OPT_U_MICROSOFT="

set "HAS_ORACLE=0"
set "HAS_ADOPTIUM=0"
set "HAS_GRAALVM=0"
set "HAS_CORRETTO=0"
set "HAS_ZULU=0"
set "HAS_MICROSOFT=0"

for /l %%k in (1,1,!JDK_COUNT!) do (
    if /i "!JDK_VENDOR_%%k!"=="Oracle" set "HAS_ORACLE=1"
    if /i "!JDK_VENDOR_%%k!"=="Adoptium" set "HAS_ADOPTIUM=1"
    if /i "!JDK_VENDOR_%%k!"=="GraalVM" set "HAS_GRAALVM=1"
    if /i "!JDK_VENDOR_%%k!"=="Corretto" set "HAS_CORRETTO=1"
    if /i "!JDK_VENDOR_%%k!"=="Zulu" set "HAS_ZULU=1"
    if /i "!JDK_VENDOR_%%k!"=="Microsoft" set "HAS_MICROSOFT=1"
)

if "!HAS_ORACLE!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_ORACLE=!U_OPT!"
    echo !OPT_U_ORACLE!. Oracle
)
if "!HAS_ADOPTIUM!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_ADOPTIUM=!U_OPT!"
    echo !OPT_U_ADOPTIUM!. Adoptium
)
if "!HAS_GRAALVM!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_GRAALVM=!U_OPT!"
    echo !OPT_U_GRAALVM!. GraalVM
)
if "!HAS_CORRETTO!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_CORRETTO=!U_OPT!"
    echo !OPT_U_CORRETTO!. Corretto
)
if "!HAS_ZULU!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_ZULU=!U_OPT!"
    echo !OPT_U_ZULU!. Zulu
)
if "!HAS_MICROSOFT!"=="1" (
    set /a U_OPT+=1
    set "OPT_U_MICROSOFT=!U_OPT!"
    echo !OPT_U_MICROSOFT!. Microsoft
)

set /a U_OPT+=1
set "OPT_U_CANCEL=!U_OPT!"
echo !OPT_U_CANCEL!. Cancel

set "U_KEYS="
for /l %%k in (1,1,!U_OPT!) do set "U_KEYS=!U_KEYS!%%k"

echo.
choice /C !U_KEYS! /N /M "Select vendor (1-!U_OPT!): "
set "v_choice=!errorlevel!"

if !v_choice!==!OPT_U_CANCEL! goto :eof

if defined OPT_U_ORACLE if !v_choice!==!OPT_U_ORACLE! set "TARGET_VENDOR=Oracle"
if defined OPT_U_ADOPTIUM if !v_choice!==!OPT_U_ADOPTIUM! set "TARGET_VENDOR=Adoptium"
if defined OPT_U_GRAALVM if !v_choice!==!OPT_U_GRAALVM! set "TARGET_VENDOR=GraalVM"
if defined OPT_U_CORRETTO if !v_choice!==!OPT_U_CORRETTO! set "TARGET_VENDOR=Corretto"
if defined OPT_U_ZULU if !v_choice!==!OPT_U_ZULU! set "TARGET_VENDOR=Zulu"
if defined OPT_U_MICROSOFT if !v_choice!==!OPT_U_MICROSOFT! set "TARGET_VENDOR=Microsoft"

:UninstallJDK_Vendor
cls
echo ============================================================
echo                     JDK Uninstaller
echo ============================================================
echo.
echo Please select a !TARGET_VENDOR! JDK to PERMANENTLY remove from your system:

set "U_JDK_MAP="
set /a U_NUM=0
for /l %%k in (1,1,!JDK_COUNT!) do (
    if /i "!JDK_VENDOR_%%k!"=="!TARGET_VENDOR!" (
        set /a U_NUM+=1
        set "ACTIVE_TAG="
        if /i "!JDK_PATH_%%k!"=="!JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
        echo !U_NUM!. Remove %cBLUE%JDK !JDK_MAJOR_%%k! ^(!JDK_NAME_%%k!^)%cRESET%  %cGRAY%[!JDK_PATH_%%k!]%cRESET%!ACTIVE_TAG!
        
        :: We need a map from the submenu option to the global JDK index
        set "U_MAP_!U_NUM!=%%k"
    )
)
set /a U_CANCEL=!U_NUM! + 1
echo.
echo !U_CANCEL!. Back to Menu
echo.

:GET_U_CHOICE
if !U_CANCEL! GTR 9 goto GET_U_CHOICE_MANUAL

set "U_CHOICE_KEYS="
for /l %%k in (1,1,!U_CANCEL!) do set "U_CHOICE_KEYS=!U_CHOICE_KEYS!%%k"

choice /C !U_CHOICE_KEYS! /N /M "Enter your choice (1-!U_CANCEL!): "
set "u_choice=!errorlevel!"

if !u_choice!==0 (
    echo.
    goto GET_U_CHOICE
)
goto PROCESS_U_CHOICE

:GET_U_CHOICE_MANUAL
set u_choice=
set /p u_choice="Enter your choice (1-!U_CANCEL!): "
if "!u_choice!"=="" goto GET_U_CHOICE_MANUAL
set "u_choice=!u_choice: =!"
set "NUM_TEST="
for /f "delims=0123456789" %%A in ("!u_choice!") do set "NUM_TEST=%%A"
if defined NUM_TEST goto GET_U_CHOICE_MANUAL
if !u_choice! LSS 1 goto GET_U_CHOICE_MANUAL
if !u_choice! GTR !U_CANCEL! goto GET_U_CHOICE_MANUAL

:PROCESS_U_CHOICE
if !u_choice!==!U_CANCEL! goto UninstallJDK

:: Get the global JDK index from the map
set "GLOBAL_IDX=!U_MAP_%u_choice%!"
set "DEL_PATH=!JDK_PATH_%GLOBAL_IDX%!"
set "DEL_NAME=!JDK_NAME_%GLOBAL_IDX%!"

echo.
echo %cYELLOW%[ WARNING ]%cRESET% You are about to permanently delete:
echo             !DEL_PATH!
echo             This action cannot be undone.

choice /C yn /N /M "Are you sure you want to proceed? (y/N): "
if !errorlevel! NEQ 1 goto CANCEL_UNINSTALL

echo.
echo %cBLUE%[ ACTION ]%cRESET% Terminating any active Java processes...
taskkill /f /im java.exe >nul 2>&1
taskkill /f /im javaw.exe >nul 2>&1

echo %cBLUE%[ ACTION ]%cRESET% Deleting directory and scrubbing environment variables...
set "ADMIN_BAT=%TEMP%\jvm_admin_!RANDOM!.bat"
(
    echo @echo off
    echo taskkill /f /im java.exe ^>nul 2^>^&1
    echo taskkill /f /im javaw.exe ^>nul 2^>^&1
    echo rmdir /s /q "!DEL_PATH!"
    echo if not exist "%USERPROFILE%\.jvm\current\bin\java.exe" ^(
    echo     if exist "%USERPROFILE%\.jvm\current" rmdir "%USERPROFILE%\.jvm\current"
    echo     reg delete "HKCU\Environment" /v JAVA_HOME /f ^>nul 2^>^&1
    echo ^)
    echo set "SYS_PATH="
    echo for /f "tokens=2 delims==" %%%%A in ^('wmic environment where "name='Path' and username='<system>'" get VariableValue /value 2^^^>nul'^) do set "SYS_PATH=%%%%A"
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

:CANCEL_UNINSTALL
echo.
echo %cBLUE%[  INFO  ]%cRESET% Uninstallation cancelled. Returning to menu...
timeout /t 2 >nul
goto :eof




:: ============================================================
:: JDK DOWNLOADER
:: ============================================================
:: ============================================================
:: JDK INSTALLATION ROUTER (Interactive)
:: ============================================================
:InstallWizard
echo.
echo ============================================================
echo                   JDK Installation Wizard
echo ============================================================
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
set "v_choice=!errorlevel!"

if !v_choice!==7 goto :eof
if !v_choice!==1 set "CLI_VENDOR=Oracle"
if !v_choice!==2 set "CLI_VENDOR=Adoptium"
if !v_choice!==3 set "CLI_VENDOR=GraalVM"
if !v_choice!==4 set "CLI_VENDOR=Corretto"
if !v_choice!==5 set "CLI_VENDOR=Zulu"
if !v_choice!==6 set "CLI_VENDOR=Microsoft"

echo.
echo ============================================================
echo                   !CLI_VENDOR! Downloader
echo ============================================================
echo Select Release Type:
echo 1. Latest Feature Release
echo 2. LTS Releases
echo 3. Specific Version
echo 4. Cancel
echo.
choice /C 1234 /N /M "Enter your choice (1-4): "
set "dl_choice=!errorlevel!"

if !dl_choice!==4 goto :eof
if !dl_choice!==1 set "DL_VERSION=!ORACLE_LATEST_FEATURE!"
if !dl_choice!==2 (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Select LTS Release to Install:
    echo 1. JDK !ORACLE_LATEST_LTS! ^(Latest^)
    echo 2. JDK 21
    echo 3. JDK 17 ^(Legacy^)
    choice /C 123 /N /M "Select version (1-3): "
    if !errorlevel! EQU 1 set "DL_VERSION=!ORACLE_LATEST_LTS!"
    if !errorlevel! EQU 2 set "DL_VERSION=21"
    if !errorlevel! EQU 3 set "DL_VERSION=17"
)
if !dl_choice!==3 (
    echo.
    set /p DL_VERSION="Enter the major version number to download (e.g., 21): "
    set "DL_VERSION=!DL_VERSION: =!"
    set "NUM_TEST="
    for /f "delims=0123456789" %%A in ("!DL_VERSION!") do set "NUM_TEST=%%A"
    if defined NUM_TEST (
        echo %cRED%[ ERROR  ]%cRESET% Invalid version number. Must be numeric.
        pause
        goto :eof
    )
    if "!DL_VERSION!"=="" (
        echo %cRED%[ ERROR  ]%cRESET% Invalid version number. Must be numeric.
        pause
        goto :eof
    )
)

:DownloadJDK_Headless
if "!CLI_VENDOR!"=="" set "CLI_VENDOR=oracle"

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
set "PS_API_SCRIPT=%TEMP%\api_query_!RANDOM!.ps1"
(
    echo $ErrorActionPreference = 'Stop'
    echo try {
    echo     $res = Invoke-RestMethod -Uri 'https://api.adoptium.net/v3/assets/feature_releases/!DL_VERSION!/ga?architecture=x64^&image_type=jdk^&jvm_impl=hotspot^&os=windows^&page=0^&page_size=1' -UseBasicParsing
    echo     $url = $res[0].binaries[0].package.link
    echo     $sha = $res[0].binaries[0].package.checksum
    echo     if ^($url -and $sha^) {
    echo         Write-Output "API_URL=$url"
    echo         Write-Output "API_SHA256=$sha"
    echo     } else { exit 1 }
    echo } catch { exit 1 }
) > "!PS_API_SCRIPT!"
goto Run_API_Query

:Resolve_GraalVM
set "DL_VENDOR=GraalVM"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Querying GraalVM GitHub API for latest JDK !DL_VERSION! release...
set "PS_API_SCRIPT=%TEMP%\api_query_!RANDOM!.ps1"
(
    echo $ErrorActionPreference = 'Stop'
    echo try {
    echo     $res = Invoke-RestMethod -Uri 'https://api.github.com/repos/graalvm/graalvm-ce-builds/releases' -UseBasicParsing
    echo     $targetTag = $null
    echo     foreach ^($release in $res^) {
    echo         if ^($release.tag_name -like "jdk-!DL_VERSION!*"^) {
    echo             $targetTag = $release
    echo             break
    echo         }
    echo     }
    echo     if ^(-not $targetTag^) { exit 1 }
    echo     $url = $null
    echo     $sha_url = $null
    echo     foreach ^($asset in $targetTag.assets^) {
    echo         if ^($asset.name -match 'windows-(x64^|amd64^)_bin\.zip$'^) { $url = $asset.browser_download_url }
    echo         if ^($asset.name -match 'windows-(x64^|amd64^)_bin\.zip\.sha256$'^) { $sha_url = $asset.browser_download_url }
    echo     }
    echo     if ^($url -and $sha_url^) {
    echo         Write-Output "API_URL=$url"
    echo         Write-Output "API_SHA256_URL=$sha_url"
    echo     } else { exit 1 }
    echo } catch { exit 1 }
) > "!PS_API_SCRIPT!"
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
set "PS_API_SCRIPT=%TEMP%\api_query_!RANDOM!.ps1"
(
    echo $ErrorActionPreference = 'Stop'
    echo try {
    echo     $res = Invoke-RestMethod -Uri 'https://api.azul.com/zulu/download/community/v1.0/bundles/latest/?java_version=!DL_VERSION!^&os=windows^&arch=x86^&hw_bitness=64^&ext=zip' -UseBasicParsing
    echo     if ^($res.url -and $res.sha256_hash^) {
    echo         Write-Output "API_URL=$($res.url)"
    echo         Write-Output "API_SHA256=$($res.sha256_hash)"
    echo     } else { exit 1 }
    echo } catch { exit 1 }
) > "!PS_API_SCRIPT!"
goto Run_API_Query

:Resolve_Microsoft
set "DL_VENDOR=Microsoft"
echo.
echo %cBLUE%[ ACTION ]%cRESET% Resolving Microsoft Build of OpenJDK !DL_VERSION! URLs...
set "API_URL=https://aka.ms/download-jdk/microsoft-jdk-!DL_VERSION!-windows-x64.zip"
set "API_SHA256_URL=https://aka.ms/download-jdk/microsoft-jdk-!DL_VERSION!-windows-x64.zip.sha256sum.txt"
set "API_SHA256="
goto :FetchAndExtract

:Run_API_Query
set "API_URL="
set "API_SHA256="
set "API_SHA256_URL="
for /f "tokens=1,* delims==" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_API_SCRIPT!"') do (
    if "%%A"=="API_URL" set "API_URL=%%B"
    if "%%A"=="API_SHA256" set "API_SHA256=%%B"
    if "%%A"=="API_SHA256_URL" set "API_SHA256_URL=%%B"
)
if exist "!PS_API_SCRIPT!" del "!PS_API_SCRIPT!"

if "!API_URL!"=="" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to find !DL_VENDOR! JDK !DL_VERSION!. The version might not exist.
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)
goto :FetchAndExtract

:FetchAndExtract
setlocal enabledelayedexpansion
set "ZIP_PATH=%TEMP%\jdk_!DL_VENDOR!_!DL_VERSION!_download.zip"
set "EXTRACT_DIR=%TEMP%\jdk_!DL_VENDOR!_!DL_VERSION!_extract"
set "DEST_DIR=C:\Program Files\Java"

if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!"

set "PS_SCRIPT=%TEMP%\dl_jdk_!RANDOM!.ps1"
(
    echo $ErrorActionPreference = 'Stop'
    echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    echo try {
    echo     Write-Host '[  INFO  ] Requesting download from !DL_VENDOR!... ^(This may take a minute^)' -ForegroundColor Cyan
    echo     $url = '!API_URL!'
    echo     $out = '!ZIP_PATH!'
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
    echo             $percent = [math]::Round^( ^($downloaded / $totalLength^) * 100 ^)
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
    echo     Write-Host "`n"
    echo     Write-Host '[  INFO  ] Verifying SHA256 checksum...' -ForegroundColor Cyan
    echo     if ^('!API_SHA256_URL!' -ne ''^) {
    echo         $expectedHash = ^(Invoke-RestMethod -Uri '!API_SHA256_URL!' -UseBasicParsing^).Trim^(^)
    echo         $expectedHash = ^($expectedHash -split ' '^)[0]
    echo     } elseif ^('!API_SHA256!' -ne ''^) {
    echo         $expectedHash = '!API_SHA256!'
    echo     }
    echo     $sha256 = [System.Security.Cryptography.SHA256]::Create^(^)
    echo     $fs2 = [System.IO.File]::OpenRead^($out^)
    echo     $hashBytes = $sha256.ComputeHash^($fs2^)
    echo     $fs2.Close^(^)
    echo     $actualHash = [System.BitConverter]::ToString^($hashBytes^).Replace^('-', ''^).ToLower^(^)
    echo     if ^($actualHash -ne $expectedHash^) {
    echo         Write-Host '[ ERROR  ] Checksum mismatch! Download corrupted or compromised.' -ForegroundColor Red
    echo         Write-Host "           Expected: $expectedHash" -ForegroundColor Red
    echo         Write-Host "           Actual:   $actualHash" -ForegroundColor Red
    echo         exit 1
    echo     }
    echo     Write-Host '[   OK   ] Checksum verified successfully.' -ForegroundColor Green
    echo     Write-Host ""
    echo     Write-Host '[  INFO  ] Extracting files locally...' -ForegroundColor Cyan
    echo     Add-Type -AssemblyName System.IO.Compression.FileSystem
    echo     $zip = [System.IO.Compression.ZipFile]::OpenRead^('!ZIP_PATH!'^)
    echo     $entries = $zip.Entries
    echo     $totalEntries = $entries.Count
    echo     $extracted = 0
    echo     $lastPercent = -1
    echo     foreach ^($entry in $entries^) {
    echo         $destinationPath = [System.IO.Path]::GetFullPath^([System.IO.Path]::Combine^('!EXTRACT_DIR!', $entry.FullName^)^)
    echo         if ^([string]::IsNullOrEmpty^($entry.Name^)^) {
    echo             [System.IO.Directory]::CreateDirectory^($destinationPath^) ^| Out-Null
    echo         } else {
    echo             [System.IO.Directory]::CreateDirectory^([System.IO.Path]::GetDirectoryName^($destinationPath^)^) ^| Out-Null
    echo             [System.IO.Compression.ZipFileExtensions]::ExtractToFile^($entry, $destinationPath, $true^)
    echo         }
    echo         $extracted++
    echo         $percent = [math]::Round^(^($extracted / $totalEntries^) * 100^)
    echo         if ^($percent -ne $lastPercent^) {
    echo             $bar = '[' + ^('=' * [math]::Floor^($percent / 2^)^) + ^(' ' * ^(50 - [math]::Floor^($percent / 2^)^)^) + ']'
    echo             Write-Host "`r[ ACTION ] Extracting: $bar $percent%% ($extracted / $totalEntries) " -NoNewline -ForegroundColor Cyan
    echo             $lastPercent = $percent
    echo         }
    echo     }
    echo     $zip.Dispose^(^)
    echo     Write-Host ""
    echo     Remove-Item '!ZIP_PATH!'
    echo } catch {
    echo     Write-Host '[ ERROR  ] Download failed! !DL_VENDOR! API might be unreachable.' -ForegroundColor Red
    echo     Write-Host '[ DETAIL ] ' $_.Exception.Message -ForegroundColor Yellow
    echo     if ^(Test-Path '!ZIP_PATH!'^) { Remove-Item '!ZIP_PATH!' -ErrorAction SilentlyContinue }
    echo     exit 1
    echo }
) > "!PS_SCRIPT!"

powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!"
set PS_EXIT_CODE=!errorlevel!

if exist "!PS_SCRIPT!" del "!PS_SCRIPT!"

if !PS_EXIT_CODE! NEQ 0 (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% The installation failed.
    if "!CLI_COMMAND!"=="" pause
    goto :eof
)

set "NEW_FOLDER="
for /d %%D in ("!EXTRACT_DIR!\*") do set "NEW_FOLDER=%%~nxD"

if not defined NEW_FOLDER (
    echo.
    echo %cRED%[ ERROR  ]%cRESET% Could not locate the extracted JDK folder.
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
    echo rmdir /s /q "!EXTRACT_DIR!"
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
    goto :eof
)
endlocal
goto :eof


:: ============================================================
:: PATH UPDATER
:: ============================================================
:UpdateSystemPath
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
    echo           - Reading current USER PATH...
    set "ORIGINAL_PATH="
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
        set "ORIGINAL_PATH=%%B"
    )
)

if not defined ORIGINAL_PATH (
    set "ORIGINAL_PATH=%PATH%"
)

echo           - De-bloating Phantom Oracle paths...

set "ORIGINAL_PATH=!ORIGINAL_PATH:C:\Program Files\Common Files\Oracle\Java\javapath;=!"
set "ORIGINAL_PATH=!ORIGINAL_PATH:C:\Program Files\Common Files\Oracle\Java\javapath=!"
set "ORIGINAL_PATH=!ORIGINAL_PATH:C:\Program Files (x86)\Common Files\Oracle\Java\javapath;=!"
set "ORIGINAL_PATH=!ORIGINAL_PATH:C:\Program Files (x86)\Common Files\Oracle\Java\javapath=!"
set "ORIGINAL_PATH=!ORIGINAL_PATH:C:\ProgramData\Oracle\Java\javapath;=!"
set "ORIGINAL_PATH=!ORIGINAL_PATH:C:\ProgramData\Oracle\Java\javapath=!"

:: Always scrub both junction and exact path from ORIGINAL_PATH to prevent duplicates
set "ORIGINAL_PATH=!ORIGINAL_PATH:%USERPROFILE%\.jvm\current\bin;=!"
set "ORIGINAL_PATH=!ORIGINAL_PATH:;%USERPROFILE%\.jvm\current\bin=!"
set "ORIGINAL_PATH=!ORIGINAL_PATH:%CURRENT_JDK_PATH%\bin;=!"
set "ORIGINAL_PATH=!ORIGINAL_PATH:;%CURRENT_JDK_PATH%\bin=!"

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
    
    :: Scrub any conflicting User-level JAVA_HOME that might override the Machine-level variable
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
    setx Path "!NEW_PATH!" >nul
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


:: ============================================================
:: CLEAR JAVA ENVIRONMENT
:: ============================================================
:ClearJavaEnvironment
setlocal enabledelayedexpansion
cls
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
echo %cBLUE%[ ACTION ]%cRESET% Removing JAVA_HOME from registry...
reg delete "HKCU\Environment" /v JAVA_HOME /f >nul 2>&1

:: Clean SYSTEM PATH
echo %cBLUE%[ ACTION ]%cRESET% Cleaning SYSTEM PATH...
set "SYS_PATH="
for /f "tokens=2 delims==" %%A in ('wmic environment where "name='Path' and username='<system>'" get VariableValue /value 2^>nul') do set "SYS_PATH=%%A"
if not defined SYS_PATH (
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
)
if defined SYS_PATH (
    :: Remove %%JAVA_HOME%%\bin and %JAVA_HOME%\bin
    set "SYS_PATH=!SYS_PATH:%%JAVA_HOME%%\bin;=!"
    set "SYS_PATH=!SYS_PATH:;%%JAVA_HOME%%\bin=!"
    set "SYS_PATH=!SYS_PATH:%JAVA_HOME%\bin;=!"
    set "SYS_PATH=!SYS_PATH:;%JAVA_HOME%\bin=!"
    
    :: Remove any scanned JDK bin directories to be absolutely clean
    for /l %%k in (1,1,!JDK_COUNT!) do (
        for /f "delims=" %%V in ("!JDK_PATH_%%k!\bin") do (
            set "SYS_PATH=!SYS_PATH:%%V;=!"
            set "SYS_PATH=!SYS_PATH:;%%V=!"
        )
    )
    
    :: De-bloat Phantom Oracle paths too
    set "SYS_PATH=!SYS_PATH:C:\Program Files\Common Files\Oracle\Java\javapath;=!"
    set "SYS_PATH=!SYS_PATH:C:\Program Files\Common Files\Oracle\Java\javapath=!"
    set "SYS_PATH=!SYS_PATH:C:\Program Files (x86)\Common Files\Oracle\Java\javapath;=!"
    set "SYS_PATH=!SYS_PATH:C:\Program Files (x86)\Common Files\Oracle\Java\javapath=!"
    set "SYS_PATH=!SYS_PATH:C:\ProgramData\Oracle\Java\javapath;=!"
    set "SYS_PATH=!SYS_PATH:C:\ProgramData\Oracle\Java\javapath=!"
    
    set "SYS_PATH=!SYS_PATH:;;=;!"
    
    echo %cBLUE%[ ACTION ]%cRESET% Requesting Administrator privileges to clear Machine Registry...
    set "SAFE_SYS_PATH=!SYS_PATH:'=''!"
    
    set "ELEVATE_SCRIPT=%TEMP%\jvm_elevate_!RANDOM!.ps1"
    echo [Environment]::SetEnvironmentVariable^('JAVA_HOME', $null, 'Machine'^) > "!ELEVATE_SCRIPT!"
    echo [Environment]::SetEnvironmentVariable^('Path', '!SAFE_SYS_PATH!', 'Machine'^) >> "!ELEVATE_SCRIPT!"
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""!ELEVATE_SCRIPT!""' -Verb RunAs -Wait" 2>nul
    
    if exist "!ELEVATE_SCRIPT!" del "!ELEVATE_SCRIPT!"
)

:: Clean USER PATH
echo %cBLUE%[ ACTION ]%cRESET% Cleaning USER PATH...
set "USR_PATH="
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
if defined USR_PATH (
    set "USR_PATH=!USR_PATH:%%JAVA_HOME%%\bin;=!"
    set "USR_PATH=!USR_PATH:;%%JAVA_HOME%%\bin=!"
    set "USR_PATH=!USR_PATH:%JAVA_HOME%\bin;=!"
    set "USR_PATH=!USR_PATH:;%JAVA_HOME%\bin=!"
    for /l %%k in (1,1,!JDK_COUNT!) do (
        for /f "delims=" %%V in ("!JDK_PATH_%%k!\bin") do (
            set "USR_PATH=!USR_PATH:%%V;=!"
            set "USR_PATH=!USR_PATH:;%%V=!"
        )
    )
    set "USR_PATH=!USR_PATH:C:\Program Files\Common Files\Oracle\Java\javapath;=!"
    set "USR_PATH=!USR_PATH:C:\Program Files\Common Files\Oracle\Java\javapath=!"
    set "USR_PATH=!USR_PATH:C:\Program Files (x86)\Common Files\Oracle\Java\javapath;=!"
    set "USR_PATH=!USR_PATH:C:\Program Files (x86)\Common Files\Oracle\Java\javapath=!"
    set "USR_PATH=!USR_PATH:C:\ProgramData\Oracle\Java\javapath;=!"
    set "USR_PATH=!USR_PATH:C:\ProgramData\Oracle\Java\javapath=!"
    
    set "USR_PATH=!USR_PATH:;;=;!"
    setx Path "!USR_PATH!" >nul
)

:: Clean active session variables
echo %cBLUE%[ ACTION ]%cRESET% Cleaning current session environment...
set "CLEAN_PATH=!PATH!"
set "CLEAN_PATH=!CLEAN_PATH:%%JAVA_HOME%%\bin;=!"
set "CLEAN_PATH=!CLEAN_PATH:;%%JAVA_HOME%%\bin=!"
if defined CURRENT_JDK_PATH (
    set "CLEAN_PATH=!CLEAN_PATH:%CURRENT_JDK_PATH%\bin;=!"
    set "CLEAN_PATH=!CLEAN_PATH:;%CURRENT_JDK_PATH%\bin=!"
)
for /l %%k in (1,1,!JDK_COUNT!) do (
    for /f "delims=" %%V in ("!JDK_PATH_%%k!\bin") do (
        set "CLEAN_PATH=!CLEAN_PATH:%%V;=!"
        set "CLEAN_PATH=!CLEAN_PATH:;%%V=!"
    )
)
set "CLEAN_PATH=!CLEAN_PATH:C:\Program Files\Common Files\Oracle\Java\javapath;=!"
set "CLEAN_PATH=!CLEAN_PATH:C:\Program Files\Common Files\Oracle\Java\javapath=!"
set "CLEAN_PATH=!CLEAN_PATH:C:\Program Files (x86)\Common Files\Oracle\Java\javapath;=!"
set "CLEAN_PATH=!CLEAN_PATH:C:\Program Files (x86)\Common Files\Oracle\Java\javapath=!"
set "CLEAN_PATH=!CLEAN_PATH:C:\ProgramData\Oracle\Java\javapath;=!"
set "CLEAN_PATH=!CLEAN_PATH:C:\ProgramData\Oracle\Java\javapath=!"
set "CLEAN_PATH=!CLEAN_PATH:;;=;!"

:: Export active session path
for /f "delims=" %%A in ("!CLEAN_PATH!") do (
    endlocal & set "CLEAN_PATH=%%A"
)
echo %cGREEN%[   OK   ]%cRESET% Java environment variables cleared.
echo            Open a new command prompt to see changes take full effect.
echo.
echo Press any key to return to the menu...
pause >nul
goto :eof


:: ============================================================
:: PATH & ENVIRONMENT SUB-MENU
:: ============================================================
:PathEnvironmentMenu
cls
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
set "HAS_ADOPTIUM=0"
set "HAS_GRAALVM=0"

for /l %%k in (1,1,!JDK_COUNT!) do (
    if /i "!JDK_VENDOR_%%k!"=="Oracle" set "HAS_ORACLE=1"
    if /i "!JDK_VENDOR_%%k!"=="Adoptium" set "HAS_ADOPTIUM=1"
    if /i "!JDK_VENDOR_%%k!"=="GraalVM" set "HAS_GRAALVM=1"
    if /i "!JDK_VENDOR_%%k!"=="Corretto" set "HAS_CORRETTO=1"
    if /i "!JDK_VENDOR_%%k!"=="Zulu" set "HAS_ZULU=1"
    if /i "!JDK_VENDOR_%%k!"=="Microsoft" set "HAS_MICROSOFT=1"
    if /i "!JDK_VENDOR_%%k!"=="Adoptium" set "HAS_ADOPTIUM=1"
    if /i "!JDK_VENDOR_%%k!"=="GraalVM" set "HAS_GRAALVM=1"
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

echo.
echo %cGRAY%--- Global Actions ---%cRESET%
set /a P_OPT+=1
set "OPT_P_LATEST=!P_OPT!"
set "LATEST_ACTIVE_TAG="
if /i "!LATEST_JDK_PATH!"=="!JAVA_HOME!" set "LATEST_ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
echo !OPT_P_LATEST!. Switch to the latest %cBLUE%JDK ^(JDK !LATEST_VER_NUM!^)%cRESET%!LATEST_ACTIVE_TAG!

set /a P_OPT+=1
set "OPT_P_CLEAR=!P_OPT!"
echo !OPT_P_CLEAR!. Clear Java from Environment Variables (De-activate)

set /a P_OPT+=1
set "OPT_P_CANCEL=!P_OPT!"
echo.
echo !OPT_P_CANCEL!. Back to Main Menu

set "P_KEYS="
for /l %%k in (1,1,!P_OPT!) do set "P_KEYS=!P_KEYS!%%k"

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

:PathEnvironmentMenu_Vendor
cls
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
        if /i "!JDK_PATH_%%k!"=="!JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
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
for /f "delims=0123456789" %%A in ("!p_choice!") do set "NUM_TEST=%%A"
if defined NUM_TEST goto GET_P_CHOICE_MANUAL
if !p_choice! LSS 1 goto GET_P_CHOICE_MANUAL
if !p_choice! GTR !P_CANCEL! goto GET_P_CHOICE_MANUAL

:PROCESS_P_CHOICE
if !p_choice!==!P_CANCEL! goto PathEnvironmentMenu

set "GLOBAL_IDX=!P_MAP_%p_choice%!"
set "CURRENT_JDK_PATH=!JDK_PATH_%GLOBAL_IDX%!"
goto :eof


:: ============================================================
:: VERSION MANAGEMENT SUB-MENU
:: ============================================================
:VersionMenu
if "!NEEDS_RESCAN!"=="1" (
    set "NEEDS_RESCAN=0"
    goto :eof
)
cls
echo ============================================================
echo                       Version Management
echo ============================================================
echo.
echo Please choose an option:
echo.
echo 1. Check for Updates for installed JDKs
echo 2. Download and Install a new JDK version
echo 3. Uninstall a JDK and clean environment variables
echo 4. Back to Main Menu
echo.

choice /C 1234 /N /M "Enter your choice (1-4): "
set "sub_choice=!errorlevel!"

if !sub_choice!==4 goto :eof
if !sub_choice!==1 (
    call :UpdateJDKs
    goto VersionMenu
)
if !sub_choice!==2 (
    call :InstallWizard
    goto VersionMenu
)
if !sub_choice!==3 (
    call :UninstallJDK
    goto VersionMenu
)

goto VersionMenu

:: ============================================================
:: SETTINGS MENU
:: ============================================================
:SettingsMenu
cls
echo ============================================================
echo                         Settings
echo ============================================================
echo.

set "SCRIPT_DIR=%~dp0"
if "!SCRIPT_DIR:~-1!"=="\" set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"

set "IN_PATH=0"
set "USER_PATH="
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    set "USER_PATH=%%B"
)

echo ;!USER_PATH!; | findstr /i /c:";!SCRIPT_DIR!;" >nul
if not errorlevel 1 set "IN_PATH=1"

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
echo 3. JVM Version
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
    ) else (
        set "SWITCH_MODE=DIRECT"
    )
    if not exist "%USERPROFILE%\.jvm" mkdir "%USERPROFILE%\.jvm"
    echo !SWITCH_MODE!> "%USERPROFILE%\.jvm\mode.txt"
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

:: ============================================================
:: GLOBAL COMMAND REMOVER
:: ============================================================
:RemoveGlobalCommand
cls
echo ============================================================
echo               Global Command Removal
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

setx Path "!NEW_PATH!" >nul
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to update User PATH via setx. Attempting registry fallback...
    reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Registry fallback failed. Run as Admin.
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% User PATH successfully updated via registry.
    )
) else (
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


:: ============================================================
:: GLOBAL COMMAND INSTALLER
:: ============================================================
:InstallGlobalCommand
cls
echo ============================================================
echo               Global Command Installation
echo ============================================================
echo.
echo %cBLUE%[ ACTION ]%cRESET% Scanning User PATH for JVM directory...

set "USER_PATH="
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    set "USER_PATH=%%B"
)

echo ;!USER_PATH!; | findstr /i /c:";!SCRIPT_DIR!;" >nul
if not errorlevel 1 (
    echo.
    echo %cGREEN%[   OK   ]%cRESET% The Java Version Manager is already installed in your system PATH!
    echo             You can run 'jvm' from any terminal.
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

:: Ensure no rogue double quotes corrupt the string!
set "USER_PATH=!USER_PATH:"=!"
set "SCRIPT_DIR=!SCRIPT_DIR:"=!"

if not defined USER_PATH (
    set "NEW_PATH=!SCRIPT_DIR!"
) else (
    :: Remove trailing semicolon from USER_PATH if it exists
    if "!USER_PATH:~-1!"==";" set "USER_PATH=!USER_PATH:~0,-1!"
    set "NEW_PATH=!USER_PATH!;!SCRIPT_DIR!"
)

:: Strip the trailing backslash from SCRIPT_DIR in NEW_PATH to prevent escaping the closing quote
if "!NEW_PATH:~-1!"=="\" set "NEW_PATH=!NEW_PATH:~0,-1!"

setx Path "!NEW_PATH!" >nul
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to update User PATH via setx. Attempting registry fallback...
    reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Registry fallback failed. Run as Admin.
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% User PATH successfully updated via registry.
    )
) else (
    echo %cGREEN%[   OK   ]%cRESET% User PATH successfully updated.
)

set "B64_PAYLOAD=JABqAHYAbQBCAGEAdAAgAD0AIAAoAEcAZQB0AC0AQwBvAG0AbQBhAG4AZAAgAGoAdgBtAC4AYgBhAHQAIAAtAEUAcgByAG8AcgBBAGMAdABpAG8AbgAgAFMAaQBsAGUAbgB0AGwAeQBDAG8AbgB0AGkAbgB1AGUAKQAuAFMAbwB1AHIAYwBlAAoAaQBmACAAKAAkAGoAdgBtAEIAYQB0ACkAIAB7AAoAIAAgACAAIAAkAGMAbwBkAGUAIAA9ACAAQAAiAAoAZgB1AG4AYwB0AGkAbwBuACAAagB2AG0AIAB7AAoAIAAgACAAIAAmACAAJwAkAGoAdgBtAEIAYQB0ACcAIABgACQAYQByAGcAcwA7AAoAIAAgACAAIABgACQAcwBlAHMAcwBpAG8AbgBGAGkAbABlACAAPQAgACIAYAAkAGUAbgB2ADoAVABFAE0AUABcAC4AagB2AG0AXwBzAGUAcwBzAGkAbwBuAF8AdABhAHIAZwBlAHQAIgA7AAoAIAAgACAAIABpAGYAIAAoAFQAZQBzAHQALQBQAGEAdABoACAAYAAkAHMAZQBzAHMAaQBvAG4ARgBpAGwAZQApACAAewAKACAAIAAgACAAIAAgACAAIABgACQAZQBuAHYAOgBKAEEAVgBBAF8ASABPAE0ARQAgAD0AIABHAGUAdAAtAEMAbwBuAHQAZQBuAHQAIABgACQAcwBlAHMAcwBpAG8AbgBGAGkAbABlACAAfAAgAFMAZQBsAGUAYwB0AC0ATwBiAGoAZQBjAHQAIAAtAEYAaQByAHMAdAAgADEAOwAKACAAIAAgACAAIAAgACAAIABSAGUAbQBvAHYAZQAtAEkAdABlAG0AIABgACQAcwBlAHMAcwBpAG8AbgBGAGkAbABlACAALQBGAG8AcgBjAGUAOwAKACAAIAAgACAAIAAgACAAIABgACQAZQBuAHYAOgBQAGEAdABoACAAPQAgACIAYAAkAGUAbgB2ADoASgBBAFYAQQBfAEgATwBNAEUAXABiAGkAbgA7AGAAJABlAG4AdgA6AFAAYQB0AGgAIgAKACAAIAAgACAAfQAgAGUAbABzAGUAIAB7AAoAIAAgACAAIAAgACAAIAAgAGAAJABlAG4AdgA6AEoAQQBWAEEAXwBIAE8ATQBFACAAPQAgAFsAUwB5AHMAdABlAG0ALgBFAG4AdgBpAHIAbwBuAG0AZQBuAHQAXQA6ADoARwBlAHQARQBuAHYAaQByAG8AbgBtAGUAbgB0AFYAYQByAGkAYQBiAGwAZQAoACcASgBBAFYAQQBfAEgATwBNAEUAJwAsACAAJwBNAGEAYwBoAGkAbgBlACcAKQA7AAoAIAAgACAAIAAgACAAIAAgAGAAJABlAG4AdgA6AFAAYQB0AGgAIAA9ACAAWwBTAHkAcwB0AGUAbQAuAEUAbgB2AGkAcgBvAG4AbQBlAG4AdABdADoAOgBHAGUAdABFAG4AdgBpAHIAbwBuAG0AZQBuAHQAVgBhAHIAaQBhAGIAbABlACgAJwBQAGEAdABoACcALAAgACcATQBhAGMAaABpAG4AZQAnACkAIAArACAAJwA7ACcAIAArACAAWwBTAHkAcwB0AGUAbQAuAEUAbgB2AGkAcgBvAG4AbQBlAG4AdABdADoAOgBHAGUAdABFAG4AdgBpAHIAbwBuAG0AZQBuAHQAVgBhAHIAaQBhAGIAbABlACgAJwBQAGEAdABoACcALAAgACcAVQBzAGUAcgAnACkACgAgACAAIAAgAH0ACgB9AAoAIgBAAAoAIAAgACAAIAAkAHAAIAA9ACAAJABQAFIATwBGAEkATABFAAoAIAAgACAAIABpAGYAIAAoACEAKABUAGUAcwB0AC0AUABhAHQAaAAgACQAcAApACkAIAB7ACAATgBlAHcALQBJAHQAZQBtACAALQBUAHkAcABlACAARgBpAGwAZQAgAC0AUABhAHQAaAAgACQAcAAgAC0ARgBvAHIAYwBlACAAPgAgACQAbgB1AGwAbAAgAH0ACgAgACAAIAAgACQAYwBvAG4AdABlAG4AdAAgAD0AIABHAGUAdAAtAEMAbwBuAHQAZQBuAHQAIAAkAHAAIAAtAEUAcgByAG8AcgBBAGMAdABpAG8AbgAgAFMAaQBsAGUAbgB0AGwAeQBDAG8AbgB0AGkAbgB1AGUAIAB8ACAATwB1AHQALQBTAHQAcgBpAG4AZwAKACAAIAAgACAAaQBmACAAKAAkAGMAbwBuAHQAZQBuAHQAIAAtAG4AbwB0AG0AYQB0AGMAaAAgACcAZgB1AG4AYwB0AGkAbwBuACAAagB2AG0AIABcAHsAJwApACAAewAKACAAIAAgACAAIAAgACAAIABBAGQAZAAtAEMAbwBuAHQAZQBuAHQAIAAtAFAAYQB0AGgAIAAkAHAAIAAtAFYAYQBsAHUAZQAgACQAYwBvAGQAZQAKACAAIAAgACAAfQAgAGUAbABzAGUAIAB7AAoAIAAgACAAIAAgACAAIAAgACQAYwBvAG4AdABlAG4AdAAgAD0AIAAkAGMAbwBuAHQAZQBuAHQAIAAtAHIAZQBwAGwAYQBjAGUAIAAnAGYAdQBuAGMAdABpAG8AbgAgAGoAdgBtACAAXAB7AC4AKgA/AFwAfQAnACwAIAAkAGMAbwBkAGUACgAgACAAIAAgACAAIAAgACAAUwBlAHQALQBDAG8AbgB0AGUAbgB0ACAALQBQAGEAdABoACAAJABwACAALQBWAGEAbAB1AGUAIAAkAGMAbwBuAHQAZQBuAHQACgAgACAAIAAgAH0ACgB9AA=="
powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand "!B64_PAYLOAD!"
pwsh -NoProfile -ExecutionPolicy Bypass -EncodedCommand "!B64_PAYLOAD!" 2>nul

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

    :: Resolve absolute path
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

:: ============================================================
:: JVM Version / About Menu
:: ============================================================
:AboutMenu
cls
echo ============================================================
echo                     Java Version Manager
echo ============================================================
echo.
echo Version: !JVM_VERSION!
echo Build:   !JVM_BUILD!
echo.
echo Developed by DiamTek / Alexey Shishkin
echo Licensed under the GNU AGPL v3.0
echo.
echo ============================================================
echo.
echo %cBLUE%[ ACTION ]%cRESET% Checking for updates...

:: Fetch latest build number from GitHub main branch and compare using PowerShell [version]
set "PS_SCRIPT=$local = [version]'!JVM_BUILD!'; $req = [Net.HttpWebRequest]::Create('https://raw.githubusercontent.com/Diamond-Industries/Java-Version-Manager-Windows/main/jvm.bat'); $req.Method = 'GET'; try { $res = $req.GetResponse(); $stream = $res.GetResponseStream(); $reader = New-Object System.IO.StreamReader($stream); $content = $reader.ReadToEnd(); if ($content -match 'set \x22JVM_BUILD=([^\x22]+)\x22') { $remoteStr = $matches[1]; try { $remote = [version]$remoteStr; if ($remote -gt $local) { Write-Output ('{0}|UPDATE' -f $remoteStr) } else { Write-Output ('{0}|OK' -f $remoteStr) } } catch { Write-Output ('{0}|INVALID_REMOTE' -f $remoteStr) } } else { Write-Output 'UNKNOWN|UNKNOWN' }; $reader.Close(); $res.Close() } catch { Write-Output 'ERROR|ERROR' }"
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

:: ============================================================
:: Self-Updater
:: ============================================================
:SelfUpdate
echo.
echo %cBLUE%[ ACTION ]%cRESET% Connecting to GitHub repository...
echo            Fetching latest jvm.bat...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Diamond-Industries/Java-Version-Manager-Windows/main/jvm.bat' -OutFile '%TEMP%\jvm_new.bat' -UseBasicParsing" 2>nul
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to download the latest update.
    pause
    goto :eof
)

for %%I in ("%TEMP%\jvm_new.bat") do set "NEW_SIZE=%%~zI"
if !NEW_SIZE! EQU 0 (
    echo %cRED%[ ERROR  ]%cRESET% Downloaded file is empty.
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

:: ============================================================
:: Parse contents of .java-version file
:: ============================================================
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