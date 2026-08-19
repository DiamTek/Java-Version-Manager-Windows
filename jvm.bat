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
title Java Version Manager

:: Generate ESC character for ANSI color codes
for /F "delims=#" %%a in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"
set "cRED=%ESC%[91m"
set "cGREEN=%ESC%[92m"
set "cYELLOW=%ESC%[93m"
set "cBLUE=%ESC%[96m"
set "cRESET=%ESC%[0m"

:: Check if the script is running as Administrator
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo %cBLUE%[ INFO ]%cRESET% Requesting administrative privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /B
)

:: CRITICAL: Set the working directory to the script's location
cd /d "%~dp0"

:MAIN_LOOP
:: Clear the variable before calling the menu to ensure a clean state
set "CURRENT_JDK_PATH="

:: Jump straight to the menu function to prevent screen clearing issues
call :ShowDynamicMenu

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

echo.
echo %cBLUE%[ ACTION ]%cRESET% Setting Java to %CURRENT_JDK_PATH%...
echo %cBLUE%[  INFO  ]%cRESET% Setting JAVA_HOME to: %CURRENT_JDK_PATH%

:: Silenced the native Windows SUCCESS message to keep the UI clean
setx JAVA_HOME "%CURRENT_JDK_PATH%" /M >nul
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Failed to set JAVA_HOME in registry
    pause
    goto MAIN_LOOP
)
echo %cGREEN%[   OK   ]%cRESET% JAVA_HOME set successfully.

:: Update system PATH permanently AND current session
echo.
echo %cBLUE%[ ACTION ]%cRESET% Updating system PATH to use %%JAVA_HOME%%\bin...
call :UpdateSystemPath


:: Clean the current session PATH dynamically to prevent duplicates
setlocal enabledelayedexpansion
set "CLEAN_PATH=!PATH!"

:: Strip the OLD Java Home if it exists
if defined JAVA_HOME (
    set "CLEAN_PATH=!CLEAN_PATH:%JAVA_HOME%\bin;=!"
    set "CLEAN_PATH=!CLEAN_PATH:;%JAVA_HOME%\bin=!"
)
:: Strip the NEW Java Home just in case to prevent doubling up
set "CLEAN_PATH=!CLEAN_PATH:%CURRENT_JDK_PATH%\bin;=!"
set "CLEAN_PATH=!CLEAN_PATH:;%CURRENT_JDK_PATH%\bin=!"
:: Remove double semicolons
set "CLEAN_PATH=!CLEAN_PATH:;;=;!"

:: Export the clean path back to the main session and apply the new JDK at the front
for /f "delims=" %%A in ("!CLEAN_PATH!") do (
    endlocal & set "PATH=%CURRENT_JDK_PATH%\bin;%%A"
)

:: Finally update the local JAVA_HOME
set "JAVA_HOME=%CURRENT_JDK_PATH%"


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
java -version 2>&1
echo.
if errorlevel 1 (
    echo %cBLUE%[  INFO  ]%cRESET% Java may not work until you restart command prompt.
) else (
    echo %cGREEN%[   OK   ]%cRESET% Java is working correctly!
)
echo.
echo %cBLUE%[  INFO  ]%cRESET% System PATH has been updated with %%JAVA_HOME%%\bin
echo            Open a new command prompt for changes to take full effect globally.
echo.
echo ============================================================

echo.
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
java -version 2>nul
if errorlevel 1 (
    echo %cYELLOW%[ WARNING]%cRESET% Java is NOT in PATH or not installed
    echo %cBLUE%[  INFO  ]%cRESET% This is normal if Java was just removed from PATH
) else (
    echo %cGREEN%[   OK   ]%cRESET% Java is in PATH
    echo.
    java -version 2>&1
)
echo ============================================================
echo.



set JDK_COUNT=0
set "LATEST_VER_NUM=0"
set "LATEST_JDK_PATH="
set "LATEST_JDK_NAME="

set "LOCATIONS[0]=C:\Program Files\Java"
set "LOCATIONS[1]=C:\Program Files (x86)\Java"
set "LOCATIONS[2]=C:\Java"
set "LOCATIONS[3]=%USERPROFILE%\.jdks"
set "LOCATIONS[4]=%USERPROFILE%\.gradle\jdks"

set LOC_IDX=5
if exist "%USERPROFILE%\scoop\apps" (
    for /d %%A in ("%USERPROFILE%\scoop\apps\*") do (
        if exist "%%A\current\bin\java.exe" (
            set "LOCATIONS[!LOC_IDX!]=%%A"
            set /a LOC_IDX+=1
        )
    )
)
set /a MAX_LOC=!LOC_IDX!-1

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
                        if exist "%%j\release" (
                            for /f "tokens=2 delims==" %%R in ('findstr /b "JAVA_VERSION=" "%%j\release" 2^>nul') do (
                                set "VER_STR=%%~R"
                                for /f "tokens=1 delims=." %%V in ("!VER_STR!") do set "VER=%%V"
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
                    )
                )
            )
            popd
        )
    )
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
    echo %cBLUE%[  INFO  ]%cRESET% Exiting Java Version Manager...
    timeout /t 1 >nul
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
        :: A selection or action was applied, exit ShowDynamicMenu so main script runs it
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


:: ============================================================
:: JDK UPDATER 
:: ============================================================
:UpdateJDKs
cls
echo ============================================================
echo                     JDK Update Checker
echo ============================================================
echo.
echo Please select an option:
echo 1. Check ALL installed JDKs for updates

for /l %%k in (1,1,!JDK_COUNT!) do (
    set /a DISP_NUM=%%k + 1
    set "ACTIVE_TAG="
    if /i "!JDK_PATH_%%k!"=="!JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
    echo !DISP_NUM!. Check JDK !JDK_MAJOR_%%k! ^(!JDK_NAME_%%k!^) !ACTIVE_TAG!
)
set /a UP_CANCEL=!JDK_COUNT! + 2
echo.
echo !UP_CANCEL!. Cancel and return to menu
echo.

:GET_UP_CHOICE
set up_choice=
set /p up_choice="Enter your choice (1-!UP_CANCEL!): "
if "!up_choice!"=="" goto GET_UP_CHOICE
echo !up_choice!| findstr /r "^[0-9]*$" >nul
if errorlevel 1 goto GET_UP_CHOICE
if !up_choice! LSS 1 goto GET_UP_CHOICE
if !up_choice! GTR !UP_CANCEL! goto GET_UP_CHOICE

if !up_choice!==!UP_CANCEL! goto :eof

if !up_choice!==1 (
    echo.
    echo %cBLUE%[ ACTION ]%cRESET% Checking ALL JDKs for updates...
    for /l %%k in (1,1,!JDK_COUNT!) do (
        call :ProcessSingleUpdate %%k
    )
    echo.
    echo ------------------------------------------------------------
    echo %cGREEN%[   OK   ]%cRESET% All update checks complete!
    echo.
    echo Press any key to return to the menu...
    pause >nul
    goto :eof
) else (
    set /a REAL_IDX=!up_choice! - 1
    call :ProcessSingleUpdate !REAL_IDX!
    echo.
    pause >nul
    goto :eof
)

:ProcessSingleUpdate
set "UP_IDX=%1"
set "UP_PATH=!JDK_PATH_%UP_IDX%!"
set "UP_MAJOR=!JDK_MAJOR_%UP_IDX%!"
set "UP_NAME=!JDK_NAME_%UP_IDX%!"

echo.
echo ------------------------------------------------------------
echo %cBLUE%[ ACTION ]%cRESET% Analyzing !UP_NAME!...
echo %cBLUE%[  INFO  ]%cRESET% Checking server for updates...

:: Use PowerShell to get the Last-Modified header from the direct download URL
set "PS_CMD=$req = [Net.HttpWebRequest]::Create('https://download.oracle.com/java/!UP_MAJOR!/latest/jdk-!UP_MAJOR!_windows-x64_bin.zip'); $req.Method = 'HEAD'; try { $res = $req.GetResponse(); $res.LastModified.ToString('yyyy-MM-dd') } catch { 'UNKNOWN' }"
for /f "delims=" %%I in ('powershell -NoProfile -Command "!PS_CMD!"') do set "REMOTE_DATE=%%I"

:: Extract date from local release file
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

echo %cYELLOW%[ UPDATE ]%cRESET% A newer build is available!
choice /C yn /N /M "Would you like to download and install this update? (y/N): "
if !errorlevel! NEQ 1 goto :eof

:: Proceed with Update Pipeline
echo.
echo %cBLUE%[ ACTION ]%cRESET% Connecting to Oracle servers for JDK !UP_MAJOR!...
set "API_URL=https://download.oracle.com/java/!UP_MAJOR!/latest/jdk-!UP_MAJOR!_windows-x64_bin.zip"
set "ZIP_PATH=%TEMP%\jdk_!UP_MAJOR!_update.zip"
set "EXTRACT_DIR=%TEMP%\jdk_!UP_MAJOR!_extract"

if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!"

:: Run PowerShell Download and Extract
set "PS_SCRIPT=%TEMP%\up_jdk_!RANDOM!.ps1"
(
    echo $ErrorActionPreference = 'Stop'
    echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    echo try {
    echo     Write-Host '[  INFO  ] Downloading latest zip... ^(This may take a minute^)' -ForegroundColor Cyan
    echo     Invoke-WebRequest -Uri '!API_URL!' -OutFile '!ZIP_PATH!'
    echo     Write-Host '[  INFO  ] Extracting update files...' -ForegroundColor Cyan
    echo     Expand-Archive -Path '!ZIP_PATH!' -DestinationPath '!EXTRACT_DIR!' -Force
    echo     Remove-Item '!ZIP_PATH!'
    echo } catch {
    echo     Write-Host '[ ERROR  ] Update download failed!' -ForegroundColor Red
    echo     exit 1
    echo }
) > "!PS_SCRIPT!"

powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!"
set PS_EXIT_CODE=!errorlevel!
if exist "!PS_SCRIPT!" del "!PS_SCRIPT!"

if !PS_EXIT_CODE! NEQ 0 (
    echo %cRED%[ ERROR  ]%cRESET% Aborting update due to download failure.
    goto :eof
)

echo %cBLUE%[ ACTION ]%cRESET% Terminating active Java processes to prevent locked files...
taskkill /f /im java.exe >nul 2>&1
taskkill /f /im javaw.exe >nul 2>&1

:: Find the newly extracted folder name (e.g. jdk-21.0.3)
set "NEW_FOLDER="
for /d %%D in ("!EXTRACT_DIR!\jdk*") do set "NEW_FOLDER=%%~nxD"

if not defined NEW_FOLDER (
    echo %cRED%[ ERROR  ]%cRESET% Could not locate the extracted JDK folder.
    goto :eof
)

set "DEST_ROOT=C:\Program Files\Java"
set "NEW_FULL_PATH=!DEST_ROOT!\!NEW_FOLDER!"

echo %cBLUE%[ ACTION ]%cRESET% Removing old installation: !UP_NAME!...
rmdir /s /q "!UP_PATH!"

echo %cBLUE%[ ACTION ]%cRESET% Installing new version: !NEW_FOLDER!...
move /y "!EXTRACT_DIR!\!NEW_FOLDER!" "!DEST_ROOT!\" >nul
rmdir /s /q "!EXTRACT_DIR!"

:: Scrub old path from SYSTEM PATH registry
set "SYS_PATH="
for /f "tokens=2 delims==" %%A in ('wmic environment where "name='Path' and username='<system>'" get VariableValue /value 2^>nul') do set "SYS_PATH=%%A"
if not defined SYS_PATH (
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
)
if defined SYS_PATH (
    set "SYS_PATH=!SYS_PATH:%UP_PATH%\bin;=!"
    set "SYS_PATH=!SYS_PATH:;%UP_PATH%\bin=!"
    set "SYS_PATH=!SYS_PATH:;;=;!"
    setx Path "!SYS_PATH!" /M >nul
)

:: Scrub old path from USER PATH registry
set "USR_PATH="
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
if defined USR_PATH (
    set "USR_PATH=!USR_PATH:%UP_PATH%\bin;=!"
    set "USR_PATH=!USR_PATH:;%UP_PATH%\bin=!"
    set "USR_PATH=!USR_PATH:;;=;!"
    setx Path "!USR_PATH!" >nul
)

:: If the updated JDK was currently the active one, update JAVA_HOME
if /i "!JAVA_HOME!"=="!UP_PATH!" (
    echo %cBLUE%[ ACTION ]%cRESET% Patching registry to point to new directory...
    setx JAVA_HOME "!NEW_FULL_PATH!" /M >nul
    set "CURRENT_JDK_PATH=!NEW_FULL_PATH!"
    call :UpdateSystemPath
)

echo %cGREEN%[   OK   ]%cRESET% JDK !UP_MAJOR! successfully updated to the latest build ^(!REMOTE_DATE!^)!
goto :eof


:: ============================================================
:: JDK UNINSTALLER
:: ============================================================
:UninstallJDK
cls
echo ============================================================
echo                     JDK Uninstaller
echo ============================================================
echo.
echo Please select a JDK to PERMANENTLY remove from your system:
for /l %%k in (1,1,!JDK_COUNT!) do (
    set "ACTIVE_TAG="
    if /i "!JDK_PATH_%%k!"=="!JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
    echo %%k. Remove JDK !JDK_MAJOR_%%k! ^(!JDK_NAME_%%k!^)  [!JDK_PATH_%%k!]!ACTIVE_TAG!
)
set /a U_CANCEL=!JDK_COUNT! + 1
echo.
echo !U_CANCEL!. Cancel and return to menu
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
echo !u_choice!| findstr /r "^[0-9]*$" >nul
if errorlevel 1 goto GET_U_CHOICE_MANUAL
if !u_choice! LSS 1 goto GET_U_CHOICE_MANUAL
if !u_choice! GTR !U_CANCEL! goto GET_U_CHOICE_MANUAL

:PROCESS_U_CHOICE
if !u_choice!==!U_CANCEL! goto CANCEL_UNINSTALL

set "DEL_PATH=!JDK_PATH_%u_choice%!"
set "DEL_NAME=!JDK_NAME_%u_choice%!"

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

echo %cBLUE%[ ACTION ]%cRESET% Deleting directory !DEL_PATH!...
rmdir /s /q "!DEL_PATH!"
if exist "!DEL_PATH!" (
    echo %cRED%[ ERROR  ]%cRESET% Failed to completely delete directory. 
    echo             A file might be locked or in use by another program.
    pause
    goto :eof
)
echo %cGREEN%[   OK   ]%cRESET% Directory deleted successfully.

echo %cBLUE%[ ACTION ]%cRESET% Scrubbing environment variables...
if /i "!JAVA_HOME!"=="!DEL_PATH!" (
    echo %cBLUE%[  INFO  ]%cRESET% Target was set as JAVA_HOME. Removing from registry...
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v JAVA_HOME /f >nul 2>&1
    set "JAVA_HOME="
)

set "SYS_PATH="
for /f "tokens=2 delims==" %%A in ('wmic environment where "name='Path' and username='<system>'" get VariableValue /value 2^>nul') do set "SYS_PATH=%%A"
if defined SYS_PATH (
    set "SYS_PATH=!SYS_PATH:%DEL_PATH%\bin;=!"
    set "SYS_PATH=!SYS_PATH:;%DEL_PATH%\bin=!"
    set "SYS_PATH=!SYS_PATH:;;=;!"
    setx Path "!SYS_PATH!" /M >nul
    echo %cGREEN%[   OK   ]%cRESET% Cleaned target from SYSTEM PATH.
)

set "USR_PATH="
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
if defined USR_PATH (
    set "USR_PATH=!USR_PATH:%DEL_PATH%\bin;=!"
    set "USR_PATH=!USR_PATH:;%DEL_PATH%\bin=!"
    set "USR_PATH=!USR_PATH:;;=;!"
    setx Path "!USR_PATH!" >nul
    echo %cGREEN%[   OK   ]%cRESET% Cleaned target from USER PATH.
)

echo.
echo %cGREEN%[   OK   ]%cRESET% !DEL_NAME! was successfully uninstalled!
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
:DownloadJDK
echo.
echo ============================================================
echo                   Oracle JDK Downloader
echo ============================================================
echo %cBLUE%[  INFO  ]%cRESET% This will fetch the official Oracle JDK.
echo             Works with versions: 17, 21, 25, 26
echo.
set /p DL_VERSION="Enter the major version number to download (e.g., 21): "

:: Input validation
echo !DL_VERSION!| findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo %cRED%[ ERROR  ]%cRESET% Invalid version number. Must be numeric.
    pause
    goto :eof
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Connecting to Oracle servers for JDK !DL_VERSION!...
set "API_URL=https://download.oracle.com/java/!DL_VERSION!/latest/jdk-!DL_VERSION!_windows-x64_bin.zip"
set "ZIP_PATH=%TEMP%\jdk_!DL_VERSION!_download.zip"
set "DEST_DIR=C:\Program Files\Java"

if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"

set "PS_SCRIPT=%TEMP%\dl_jdk_!RANDOM!.ps1"
(
    echo $ErrorActionPreference = 'Stop'
    echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    echo try {
    echo     Write-Host '[  INFO  ] Requesting download from Oracle... ^(This may take a minute^)' -ForegroundColor Cyan
    echo     Invoke-WebRequest -Uri '!API_URL!' -OutFile '!ZIP_PATH!'
    echo     Write-Host '[  INFO  ] Extracting files to !DEST_DIR!...' -ForegroundColor Cyan
    echo     Expand-Archive -Path '!ZIP_PATH!' -DestinationPath '!DEST_DIR!' -Force
    echo     Write-Host '[ ACTION ] Cleaning up temp files...' -ForegroundColor Cyan
    echo     Remove-Item '!ZIP_PATH!'
    echo } catch {
    echo     Write-Host '[ ERROR  ] Download failed! Oracle might not offer a direct link for this version.' -ForegroundColor Red
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
    echo Press any key to return to the menu...
) else (
    echo.
    echo %cGREEN%[   OK   ]%cRESET% Oracle JDK !DL_VERSION! successfully installed!
    echo Press any key to return to the menu...
)
pause >nul
goto :eof


:: ============================================================
:: PATH UPDATER
:: ============================================================
:UpdateSystemPath
setlocal enabledelayedexpansion
echo           - Reading current system PATH...

set "ORIGINAL_PATH="

for /f "tokens=2 delims==" %%A in ('wmic environment where "name='Path' and username='<system>'" get VariableValue /value 2^>nul') do (
    set "ORIGINAL_PATH=%%A"
)
if not defined ORIGINAL_PATH (
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do (
        set "ORIGINAL_PATH=%%B"
    )
)
if not defined ORIGINAL_PATH (
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

set "ORIGINAL_PATH=!ORIGINAL_PATH:%CURRENT_JDK_PATH%\bin;=!"
set "ORIGINAL_PATH=!ORIGINAL_PATH:;%CURRENT_JDK_PATH%\bin=!"

set "ORIGINAL_PATH=!ORIGINAL_PATH:;;=;!"

set ORIGINAL_PATH | findstr /i "%%JAVA_HOME%%\bin" >nul
if errorlevel 1 (
    echo           - Adding %%JAVA_HOME%%\bin to the front of system PATH...
    set "NEW_PATH=%%JAVA_HOME%%\bin;!ORIGINAL_PATH!"
) else (
    echo           - %%JAVA_HOME%%\bin is already cleanly in system PATH.
    set "NEW_PATH=!ORIGINAL_PATH!"
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Updating SYSTEM PATH...
setx Path "!NEW_PATH!" /M >nul
if errorlevel 1 (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to update SYSTEM PATH!
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% SYSTEM PATH updated via registry
    )
) else (
    echo %cGREEN%[   OK   ]%cRESET% SYSTEM PATH updated successfully
)

echo.
echo %cBLUE%[ ACTION ]%cRESET% Also updating USER PATH...
setx Path "!NEW_PATH!" >nul
if errorlevel 1 (
    reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
    if errorlevel 1 (
        echo %cRED%[ ERROR  ]%cRESET% Failed to update USER PATH!
    ) else (
        echo %cGREEN%[   OK   ]%cRESET% USER PATH updated via registry
    )
) else (
    echo %cGREEN%[   OK   ]%cRESET% USER PATH updated successfully
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
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v JAVA_HOME /f >nul 2>&1
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
    setx Path "!SYS_PATH!" /M >nul
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
echo %cGREEN%[   OK   ]%cRESET% Java environment variables cleared!
echo             Open a new command prompt to see changes take full effect.
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
java -version 2>nul
if errorlevel 1 (
    echo %cYELLOW%[ WARNING]%cRESET% Java is NOT in PATH or not installed
    echo %cBLUE%[  INFO  ]%cRESET% This is normal if Java was just removed from PATH
) else (
    echo %cGREEN%[   OK   ]%cRESET% Java is in PATH
    echo.
    java -version 2>&1
)
echo ============================================================
echo.
if !JDK_COUNT! GTR 0 (
    echo Please choose an option:
    echo.
    for /l %%k in (1,1,!JDK_COUNT!) do (
        set "ACTIVE_TAG="
        if /i "!JDK_PATH_%%k!"=="!JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
        echo %%k. Set Java to JDK !JDK_MAJOR_%%k! ^(!JDK_NAME_%%k!^)  [!JDK_PATH_%%k!]!ACTIVE_TAG!
    )
) else (
    echo %cYELLOW%[ WARNING]%cRESET% No Java installations found.
)

:: Option numbers
set /a OPT_LATEST=0
set /a OPT_CLEAR=0
set /a OPT_BACK=0

set /a SUB_OPT=!JDK_COUNT!

if !JDK_COUNT! GTR 1 (
    set /a SUB_OPT+=1
    set "OPT_LATEST=!SUB_OPT!"
    set "LATEST_ACTIVE_TAG="
    if /i "!LATEST_JDK_PATH!"=="!JAVA_HOME!" set "LATEST_ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
    echo !OPT_LATEST!. Switch to the latest JDK ^(JDK !LATEST_VER_NUM!^)!LATEST_ACTIVE_TAG!
)

set /a SUB_OPT+=1
set "OPT_CLEAR=!SUB_OPT!"
echo !OPT_CLEAR!. Clear Java from Environment Variables (De-activate)

set /a SUB_OPT+=1
set "OPT_BACK=!SUB_OPT!"
echo !OPT_BACK!. Back to Main Menu
echo.

:GET_CHOICE_SUB1
if !OPT_BACK! GTR 9 goto GET_CHOICE_SUB1_MANUAL

set "CHOICE_KEYS="
for /l %%k in (1,1,!OPT_BACK!) do set "CHOICE_KEYS=!CHOICE_KEYS!%%k"

choice /C !CHOICE_KEYS! /N /M "Enter your choice (1-!OPT_BACK!): "
set "sub_choice=!errorlevel!"
if !sub_choice!==0 goto GET_CHOICE_SUB1
goto PROCESS_CHOICE_SUB1

:GET_CHOICE_SUB1_MANUAL
set sub_choice=
set /p sub_choice="Enter your choice (1-!OPT_BACK!): "
if "!sub_choice!"=="" goto GET_CHOICE_SUB1_MANUAL
echo !sub_choice!| findstr /r "^[0-9]*$" >nul
if errorlevel 1 goto GET_CHOICE_SUB1_MANUAL
if !sub_choice! LSS 1 goto GET_CHOICE_SUB1_MANUAL
if !sub_choice! GTR !OPT_BACK! goto GET_CHOICE_SUB1_MANUAL

:PROCESS_CHOICE_SUB1
if !sub_choice!==!OPT_BACK! goto :eof
if !sub_choice!==!OPT_CLEAR! (
    set "CURRENT_JDK_PATH=CLEAR"
    goto :eof
)
if "!OPT_LATEST!" NEQ "0" if !sub_choice!==!OPT_LATEST! (
    set "CURRENT_JDK_PATH=!LATEST_JDK_PATH!"
    goto :eof
)

:: Otherwise standard numbered choice
set "CURRENT_JDK_PATH=!JDK_PATH_%sub_choice%!"
goto :eof


:: ============================================================
:: VERSION MANAGEMENT SUB-MENU
:: ============================================================
:VersionMenu
cls
echo ============================================================
echo                       Version Management
echo ============================================================
echo.
echo Please choose an option:
echo.
echo 1. Check for Updates for installed JDKs
echo 2. Download and Install a new JDK version (Oracle)
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
    call :DownloadJDK
    goto VersionMenu
)
if !sub_choice!==3 (
    call :UninstallJDK
    goto VersionMenu
)

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
echo 2. Back to Main Menu
echo.

choice /C 12 /N /M "Enter your choice (1-2): "
set "sub_choice=!errorlevel!"

if !sub_choice!==2 goto :eof
if !sub_choice!==1 (
    if "!IN_PATH!"=="1" (
        call :RemoveGlobalCommand
    ) else (
        call :InstallGlobalCommand
    )
    goto SettingsMenu
)

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

if not defined USER_PATH (
    set "NEW_PATH=!SCRIPT_DIR!"
) else (
    :: Remove trailing semicolon from USER_PATH if it exists
    if "!USER_PATH:~-1!"==";" set "USER_PATH=!USER_PATH:~0,-1!"
    set "NEW_PATH=!USER_PATH!;!SCRIPT_DIR!"
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
echo %cGREEN%[   OK   ]%cRESET% Installation Complete!
echo %cBLUE%[  INFO  ]%cRESET% You can now type 'jvm' from any new command prompt or the Windows Run dialog.
echo ============================================================
echo.
echo Press any key to return...
pause >nul
goto :eof