@echo off
cls
title Java Version Switcher

:: Check if the script is running as Administrator
openfiles >nul 2>nul
if %errorlevel% NEQ 0 (
    echo This script requires administrator privileges.
    echo Attempting to restart with elevated privileges...
    :: Relaunch the script as administrator
    powershell -Command "Start-Process cmd -ArgumentList '/c, %~s0' -Verb runAs"
    exit /B
)

:: Default Java version paths
set JDK17_PATH=C:\Program Files\Java\jdk-17
set JDK25_PATH=C:\Program Files\Java\jdk-25

echo ============================================================
echo              Java Version Switcher Tool
echo ============================================================
echo.

:: Check if JAVA_HOME is already set
if not defined JAVA_HOME (
    echo [  INFO  ] JAVA_HOME is not currently set.
    echo.
    call :DetectJavaInstallations
) else (
    echo [  INFO  ] Current JAVA_HOME: %JAVA_HOME%
    echo.
)

:: Display current Java info
echo Current Java information:
echo ============================================================
:: Try to run java command and capture any errors
java -version 2>nul
if errorlevel 1 (
    echo [WARNING] Java is NOT in PATH or not installed
    echo [  INFO  ] This is normal if Java was just removed from PATH
) else (
    echo [   OK   ] Java is in PATH
    echo.
    java -version 2>&1
)
echo.

:: Display options to the user
echo Please choose an option:
echo 1. Set Java to JDK 17
echo 2. Set Java to JDK 25
echo 3. Auto-detect and use latest JDK
echo 4. Exit without changes
echo.

:GET_CHOICE
set choice=
set /p choice="Enter your choice (1-4): "
if "%choice%"=="" goto GET_CHOICE

echo.

:: Process the user's choice
if "%choice%"=="1" (
    echo [ ACTION ] Setting Java to JDK 17...
    if exist "%JDK17_PATH%" (
        echo [  INFO  ] Setting JAVA_HOME to: %JDK17_PATH%
        setx JAVA_HOME "%JDK17_PATH%" /M
        if errorlevel 1 (
            echo [ ERROR  ] Failed to set JAVA_HOME in registry
            pause
            exit /B 1
        )
        echo [   OK   ] JAVA_HOME set to JDK 17.
        set CURRENT_JDK_PATH=%JDK17_PATH%
        set SELECTED_VERSION=17
    ) else (
        echo [ ERROR  ] JDK 17 not found at: %JDK17_PATH%
        echo [  INFO  ] Available Java installations:
        call :DetectJavaInstallations
        pause
        exit /B 1
    )
) else if "%choice%"=="2" (
    echo [ ACTION ] Setting Java to JDK 25...
    if exist "%JDK25_PATH%" (
        echo [  INFO  ] Setting JAVA_HOME to: %JDK25_PATH%
        setx JAVA_HOME "%JDK25_PATH%" /M
        if errorlevel 1 (
            echo [ ERROR  ] Failed to set JAVA_HOME in registry
            pause
            exit /B 1
        )
        echo [   OK   ] JAVA_HOME set to JDK 25.
        set CURRENT_JDK_PATH=%JDK25_PATH%
        set SELECTED_VERSION=25
    ) else (
        echo [ ERROR  ] JDK 25 not found at: %JDK25_PATH%
        echo [  INFO  ] Available Java installations:
        call :DetectJavaInstallations
        pause
        exit /B 1
    )
) else if "%choice%"=="3" (
    echo [ ACTION ] Auto-detecting Java installations...
    call :AutoDetectJava
    if errorlevel 1 (
        echo.
        echo [ ERROR  ] No Java installation detected in common locations.
        pause
        exit /B 1
    )
) else if "%choice%"=="4" (
    echo [  INFO  ] Exiting without changes...
    pause
    exit /B 0
) else (
    echo [ ERROR  ] Invalid choice: %choice%
    echo Please enter 1, 2, 3, or 4
    pause
    goto GET_CHOICE
)

:: Update system PATH permanently AND current session
if defined CURRENT_JDK_PATH (
    echo.
    echo [ ACTION ] Updating system PATH to use %%JAVA_HOME%%\bin...
    call :UpdateSystemPath
    
    :: Update local JAVA_HOME for current session
    set JAVA_HOME=%CURRENT_JDK_PATH%
    
    :: Update local PATH for current session
    set "PATH=%CURRENT_JDK_PATH%\bin;%PATH%"
)

:: Verify the changes
echo.
echo ============================================================
echo                     VERIFICATION
echo ============================================================
echo.
echo [  INFO  ] JAVA_HOME is now set to:
echo %JAVA_HOME%
echo.
echo [ ACTION ] Testing Java command...
echo ------------------------------------------------------------
java -version 2>&1
if errorlevel 1 (
    echo [  INFO  ] Java may not work until you restart command prompt.
) else (
    echo [   OK   ] Java is working correctly!
)
echo.
echo [  INFO  ] System PATH has been updated with %%JAVA_HOME%%\bin
echo           Open a new command prompt for changes to take full effect.
echo.
echo ============================================================

:: Pause and wait for the user to see the result
echo.
echo Press any key to exit...
pause >nul
exit /B

:: Function to auto-detect Java installations
:AutoDetectJava
setlocal enabledelayedexpansion
echo [ ACTION ] Scanning for Java installations...
echo.

:: Common Java installation locations
set "LOCATIONS[0]=C:\Program Files\Java"
set "LOCATIONS[1]=C:\Program Files (x86)\Java"
set "LOCATIONS[2]=%ProgramFiles%\Java"
set "LOCATIONS[3]=C:\Java"

:: Find all JDK folders
set JAVAS_FOUND=0
set LATEST_JDK=
set LATEST_VERSION=0

for /l %%i in (0,1,3) do (
    if exist "!LOCATIONS[%%i]!" (
        echo [  INFO  ] Checking: !LOCATIONS[%%i]!
        pushd "!LOCATIONS[%%i]!" 2>nul
        if not errorlevel 1 (
            for /d %%j in (jdk*) do (
                if exist "%%j\bin\java.exe" (
                    set /a JAVAS_FOUND+=1
                    echo   [   OK   ] Found: %%j
                    
                    :: Extract version number from folder name
                    set "FOLDER=%%j"
                    
                    :: Try to get version after dash (jdk-XX)
                    set "VER="
                    for /f "tokens=2 delims=-" %%v in ("!FOLDER!") do (
                        set "VER=%%v"
                    )
                    
                    :: If no dash, try to extract from jdkXX format
                    if not defined VER (
                        if "!FOLDER:~0,3!"=="jdk" (
                            set "VER=!FOLDER:~3!"
                        )
                    )
                    
                    if defined VER (
                        :: Get just the major version number
                        for /f "delims=." %%n in ("!VER!") do (
                            set "MAJOR_VER=%%n"
                        )
                        
                        :: Convert to number for comparison
                        set /a "MAJOR_NUM=!MAJOR_VER!" 2>nul
                        if not defined MAJOR_NUM set MAJOR_NUM=0
                        
                        echo   [  INFO  ] Detected version: !MAJOR_NUM!
                        
                        if !MAJOR_NUM! GTR !LATEST_VERSION! (
                            set "LATEST_VERSION=!MAJOR_NUM!"
                            set "LATEST_JDK=!LOCATIONS[%%i]!\%%j"
                        )
                    )
                )
            )
            popd
        )
    )
)

if !JAVAS_FOUND!==0 (
    echo.
    echo [ ERROR  ] No Java installations found.
    endlocal
    exit /B 1
)

echo.
echo [  INFO  ] Found !JAVAS_FOUND! Java installation(s).
if defined LATEST_JDK (
    echo.
    echo [ ACTION ] Using latest version: !LATEST_JDK!
    echo.
    setx JAVA_HOME "!LATEST_JDK!" /M
    if errorlevel 1 (
        echo [ ERROR  ] Failed to set JAVA_HOME in registry
        endlocal
        exit /B 1
    )
    echo [   OK   ] JAVA_HOME set to latest detected JDK.
    set CURRENT_JDK_PATH=!LATEST_JDK!
    set SELECTED_VERSION=!LATEST_VERSION!
    
    :: Pass the value back to main scope
    endlocal & (
        set CURRENT_JDK_PATH=%CURRENT_JDK_PATH%
        set SELECTED_VERSION=%SELECTED_VERSION%
    )
    exit /B 0
)

endlocal
exit /B 1

:: Function to detect existing Java installations for info display
:DetectJavaInstallations
setlocal enabledelayedexpansion
echo [ ACTION ] Scanning for existing Java installations...
echo.

set FOUND_ANY=0
set "PATHS[0]=C:\Program Files\Java"
set "PATHS[1]=C:\Program Files (x86)\Java"
set "PATHS[2]=%ProgramFiles%\Java"

for /l %%i in (0,1,2) do (
    if exist "!PATHS[%%i]!" (
        echo [  INFO  ] Checking: !PATHS[%%i]!
        pushd "!PATHS[%%i]!" 2>nul
        if not errorlevel 1 (
            set FOLDER_FOUND=0
            for /d %%j in (*) do (
                if exist "%%j\bin\java.exe" (
                    echo   [   OK   ] Found: %%j
                    set FOUND_ANY=1
                    set FOLDER_FOUND=1
                )
            )
            if !FOLDER_FOUND!==0 (
                echo   [  INFO  ] No JDK/JRE folders found
            )
            popd
        )
    )
)

if %FOUND_ANY%==0 (
    echo [  INFO  ] No existing Java installations found in common locations.
)

echo.
endlocal
goto :eof

:: SIMPLE Function to update system PATH (won't hang)
:UpdateSystemPath
setlocal enabledelayedexpansion

echo [ ACTION ] Reading current system PATH...

:: Try to get PATH using multiple methods
set "ORIGINAL_PATH="

:: Method 1: Try WMIC first (most reliable)
for /f "tokens=2 delims==" %%A in ('wmic environment where "name='Path' and username='<system>'" get VariableValue /value 2^>nul') do (
    set "ORIGINAL_PATH=%%A"
)

:: Method 2: Try registry if WMIC failed
if not defined ORIGINAL_PATH (
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do (
        set "ORIGINAL_PATH=%%B"
    )
)

:: Method 3: Try user PATH as last resort
if not defined ORIGINAL_PATH (
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
        set "ORIGINAL_PATH=%%B"
    )
)

:: Method 4: Fallback to current PATH (but remove the Java we just added)
if not defined ORIGINAL_PATH (
    echo [ WARNING ] Could not read PATH from registry, using current PATH...
    set "ORIGINAL_PATH=%PATH%"
    :: Remove the Java path we just added to current session
    set "ORIGINAL_PATH=!ORIGINAL_PATH:%CURRENT_JDK_PATH%\bin;=!"
    set "ORIGINAL_PATH=!ORIGINAL_PATH:;%CURRENT_JDK_PATH%\bin=!"
)

:: SIMPLE CHECK: If %JAVA_HOME%\bin is NOT in the original PATH, add it
if defined ORIGINAL_PATH (
    echo !ORIGINAL_PATH! | findstr /i "%%JAVA_HOME%%" >nul
    if errorlevel 1 (
        :: %JAVA_HOME%\bin NOT found, add it to the BEGINNING
        echo [  INFO  ] Adding %%JAVA_HOME%%\bin to system PATH...
        set "NEW_PATH=%%JAVA_HOME%%\bin;!ORIGINAL_PATH!"
    ) else (
        :: %JAVA_HOME%\bin already found
        echo [  INFO  ] %%JAVA_HOME%%\bin is already in system PATH
        set "NEW_PATH=!ORIGINAL_PATH!"
    )
) else (
    :: This should never happen, but just in case
    echo [ WARNING ] No PATH found, creating new one...
    set "NEW_PATH=%%JAVA_HOME%%\bin"
)

:: Update SYSTEM PATH
echo [ ACTION ] Updating SYSTEM PATH...
setx Path "!NEW_PATH!" /M >nul
if errorlevel 1 (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
    if errorlevel 1 (
        echo [ ERROR  ] Failed to update SYSTEM PATH!
    ) else (
        echo [   OK   ] SYSTEM PATH updated via registry
    )
) else (
    echo [   OK   ] SYSTEM PATH updated successfully
)

:: Also update USER PATH for consistency
echo [ ACTION ] Also updating USER PATH...
setx Path "!NEW_PATH!" >nul
if errorlevel 1 (
    reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
    if errorlevel 1 (
        echo [ ERROR  ] Failed to update USER PATH!
    ) else (
        echo [   OK   ] USER PATH updated via registry
    )
) else (
    echo [   OK   ] USER PATH updated successfully
)

echo [   OK   ] PATH update complete!

endlocal
goto :eof