@echo off
:: Java Version Manager (JVM) - Copyright (c) 2026 DiamTek
:: Licensed under the MIT License. See the LICENSE file for details.
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
if errorlevel 1 (
    echo %cBLUE%[  INFO  ]%cRESET% Java may not work until you restart command prompt.
) else (
    echo %cGREEN%[   OK   ]%cRESET% Java is working correctly!
)
echo.
echo %cBLUE%[  INFO  ]%cRESET% System PATH has been updated with %%JAVA_HOME%%\bin
echo             Open a new command prompt for changes to take full effect globally.
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

echo %cBLUE%[ ACTION ]%cRESET% Scanning for Java installations...
echo.

set JDK_COUNT=0
set "LATEST_VER_NUM=0"
set "LATEST_JDK_PATH="
set "LATEST_JDK_NAME="

set "LOCATIONS[0]=C:\Program Files\Java"
set "LOCATIONS[1]=C:\Program Files (x86)\Java"
set "LOCATIONS[2]=C:\Java"

:: Find all JDK folders
for /l %%i in (0,1,2) do (
    if exist "!LOCATIONS[%%i]!" (
        pushd "!LOCATIONS[%%i]!" 2>nul
        if not errorlevel 1 (
            for /d %%j in (jdk*) do (
                if exist "%%j\bin\java.exe" (
                    set /a JDK_COUNT+=1
                    set "JDK_PATH_!JDK_COUNT!=!LOCATIONS[%%i]!\%%j"
                    set "JDK_NAME_!JDK_COUNT!=%%j"
                    
                    :: Parse version to find the latest
                    set "FOLDER=%%j"
                    set "VER="
                    for /f "tokens=2 delims=-." %%v in ("!FOLDER!") do set "VER=%%v"
                    if not defined VER (
                        if "!FOLDER:~0,3!"=="jdk" set "VER=!FOLDER:~3,2!"
                    )
                    set /a "NUM_VER=!VER!" 2>nul
                    
                    :: Store the major version specifically for the menu display
                    set "JDK_MAJOR_!JDK_COUNT!=!NUM_VER!"
                    
                    if !NUM_VER! GTR !LATEST_VER_NUM! (
                        set "LATEST_VER_NUM=!NUM_VER!"
                        set "LATEST_JDK_PATH=!LOCATIONS[%%i]!\%%j"
                        set "LATEST_JDK_NAME=!FOLDER!"
                    )
                )
            )
            popd
        )
    )
)

if !JDK_COUNT!==0 (
    echo %cYELLOW%[ WARNING]%cRESET% No Java installations found in common locations.
    echo             You can use the download option below to install one.
    echo.
) else (
    echo Please choose an option:
    for /l %%k in (1,1,!JDK_COUNT!) do (
        set "ACTIVE_TAG="
        if /i "!JDK_PATH_%%k!"=="!JAVA_HOME!" set "ACTIVE_TAG= %cGREEN%[ACTIVE]%cRESET%"
        echo %%k. Set Java to JDK !JDK_MAJOR_%%k! ^(!JDK_NAME_%%k!^)  [!JDK_PATH_%%k!]!ACTIVE_TAG!
    )
)

:: Build dynamic menu options based on installation count
set /a CURRENT_OPT=!JDK_COUNT!

:: Only show "Switch to Latest" if there is more than 1 installation
set LATEST_OPT=0
if !JDK_COUNT! GTR 1 (
    set /a CURRENT_OPT+=1
    set "LATEST_OPT=!CURRENT_OPT!"
    echo !LATEST_OPT!. Switch to the latest JDK ^(JDK !LATEST_VER_NUM!^)
)

set /a CURRENT_OPT+=1
set "UPDATE_OPT=!CURRENT_OPT!"
if !JDK_COUNT! GTR 0 (
    echo !UPDATE_OPT!. Check for Updates for installed JDKs
) else (
    set "UPDATE_OPT=0"
    set /a CURRENT_OPT-=1
)

set /a CURRENT_OPT+=1
set "DL_OPT=!CURRENT_OPT!"
echo !DL_OPT!. Download and Install a new JDK version (Oracle)

set /a CURRENT_OPT+=1
set "UNINSTALL_OPT=!CURRENT_OPT!"
if !JDK_COUNT! GTR 0 (
    echo !UNINSTALL_OPT!. Uninstall a JDK and clean environment variables
) else (
    set "UNINSTALL_OPT=0"
    set /a CURRENT_OPT-=1
)

set /a CURRENT_OPT+=1
set "EXIT_OPT=!CURRENT_OPT!"
echo !EXIT_OPT!. Exit
echo.

:GET_CHOICE_DYN
:: Use robust CHOICE command if options are 9 or fewer
if !EXIT_OPT! GTR 9 goto GET_CHOICE_MANUAL

set "CHOICE_KEYS="
for /l %%k in (1,1,!EXIT_OPT!) do set "CHOICE_KEYS=!CHOICE_KEYS!%%k"

choice /C !CHOICE_KEYS! /N /M "Enter your choice (1-!EXIT_OPT!): "
set "choice=!errorlevel!"

:: If user presses Ctrl+C and tells Windows 'N', quietly loop back
if !choice!==0 (
    echo.
    goto GET_CHOICE_DYN
)
goto PROCESS_CHOICE

:GET_CHOICE_MANUAL
:: Fallback for extreme amounts of JDKs
set choice=
set /p choice="Enter your choice (1-!EXIT_OPT!): "
if "!choice!"=="" goto GET_CHOICE_MANUAL
echo !choice!| findstr /r "^[0-9]*$" >nul
if errorlevel 1 goto GET_CHOICE_MANUAL
if !choice! LSS 1 goto GET_CHOICE_MANUAL
if !choice! GTR !EXIT_OPT! goto GET_CHOICE_MANUAL

:PROCESS_CHOICE
if !choice!==!EXIT_OPT! goto DO_EXIT
if !choice!==!DL_OPT! goto DO_DL
if "!UPDATE_OPT!" NEQ "0" if !choice!==!UPDATE_OPT! goto DO_UPDATE
if "!UNINSTALL_OPT!" NEQ "0" if !choice!==!UNINSTALL_OPT! goto DO_UNINSTALL
if "!LATEST_OPT!" NEQ "0" if !choice!==!LATEST_OPT! goto DO_LATEST

:: Otherwise it is a standard numbered choice
set "SEL_PATH=!JDK_PATH_%choice%!"
goto APPLY_SELECTION

:DO_EXIT
echo.
echo %cBLUE%[  INFO  ]%cRESET% Exiting Java Version Manager...
timeout /t 1 >nul
endlocal
set "CURRENT_JDK_PATH="
goto :eof

:DO_DL
call :DownloadJDK
goto RESCAN_MENU

:DO_UPDATE
call :UpdateJDKs
goto RESCAN_MENU

:DO_UNINSTALL
call :UninstallJDK
goto RESCAN_MENU

:DO_LATEST
set "SEL_PATH=!LATEST_JDK_PATH!"
goto APPLY_SELECTION

:APPLY_SELECTION
:: Safely pass the variable out of setlocal back to the main script
for /f "delims=" %%A in ("!SEL_PATH!") do (
    endlocal & set "CURRENT_JDK_PATH=%%A"
)
goto :eof


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
echo %cBLUE%[ ACTION ]%cRESET% Reading current system PATH...

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

echo %cBLUE%[ ACTION ]%cRESET% De-bloating Phantom Oracle paths...

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
    echo %cBLUE%[  INFO  ]%cRESET% Adding %%JAVA_HOME%%\bin to the front of system PATH...
    set "NEW_PATH=%%JAVA_HOME%%\bin;!ORIGINAL_PATH!"
) else (
    echo %cBLUE%[  INFO  ]%cRESET% %%JAVA_HOME%%\bin is already cleanly in system PATH.
    set "NEW_PATH=!ORIGINAL_PATH!"
)

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

echo %cGREEN%[   OK   ]%cRESET% PATH update complete!
endlocal
goto :eof