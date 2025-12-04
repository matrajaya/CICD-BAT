@echo off
setlocal enabledelayedexpansion

:: ==========================================
:: LOAD CONFIG FILE
:: ==========================================
set "CONFIG_FILE=%~dp0cicd.config"

if not exist "%CONFIG_FILE%" (
    echo [ERROR] File config tidak ditemukan: %CONFIG_FILE%
    pause
    exit /b 1
)

for /f "usebackq tokens=1,2 delims==" %%a in ("%CONFIG_FILE%") do (
    set "KEY=%%a"
    set "VAL=%%b"
    set "!KEY!=!VAL!"
)


:: ==========================================
:: READ PARAMETER
:: ==========================================
set "DEPLOY_WEB=1"
set "DEPLOY_SERVICE=1"

if /I "%1"=="web" (
    set "DEPLOY_SERVICE=0"
)
if /I "%1"=="service" (
    set "DEPLOY_WEB=0"
)

echo PARAMETER: %1
echo Deploy Web     = %DEPLOY_WEB%
echo Deploy Service = %DEPLOY_SERVICE%
echo.


:: ==========================================
:: CONFIG FIXED PATHS
:: ==========================================
set "WEB_SOURCE=%~dp0web"
set "SERVICE_SOURCE=%~dp0service"

set "BACKUP_DIR=%~dp0backup"
set "LOG_FILE=%~dp0deploy-log.txt"


:: ==========================================
:: TIMESTAMP
:: ==========================================
for /f "tokens=1-4 delims=/ " %%a in ("%date%") do set TODAY=%%a-%%b-%%c
for /f "tokens=1-2 delims=: " %%a in ("%time%") do set NOW=%%a-%%b

set "STAMP=%TODAY%_%NOW%"
set "BACKUP_WEB=%BACKUP_DIR%\WEB_%STAMP%"
set "BACKUP_SERVICE=%BACKUP_DIR%\SERVICE_%STAMP%"


echo ================================
echo       CI/CD DEPLOY STARTED
echo ================================
echo [%date% %time%] Deploy started >> "%LOG_FILE%"

mkdir "%BACKUP_DIR%" >nul 2>&1



:: ==========================================
:: BACKUP (SEBELUM STOP POOL)
:: ==========================================
echo Creating backup...
echo [%date% %time%] Creating backup... >> "%LOG_FILE%"

if %DEPLOY_WEB%==1 (
    mkdir "%BACKUP_WEB%"
    robocopy "%WEB_TARGET%" "%BACKUP_WEB%" /E /R:1 /W:1 >> "%LOG_FILE%"
)

if %DEPLOY_SERVICE%==1 (
    mkdir "%BACKUP_SERVICE%"
    robocopy "%SERVICE_TARGET%" "%BACKUP_SERVICE%" /E /R:1 /W:1 >> "%LOG_FILE%"
)

echo Backup done.
echo [%date% %time%] Backup completed >> "%LOG_FILE%"



:: ==========================================
:: STOP POOLS
:: ==========================================
echo.
echo Stopping App Pools...

if %DEPLOY_WEB%==1 (
    %windir%\system32\inetsrv\appcmd stop apppool /apppool.name:"%APP_POOL_WEB%" >> "%LOG_FILE%" 2>&1
)

if %DEPLOY_SERVICE%==1 (
    %windir%\system32\inetsrv\appcmd stop apppool /apppool.name:"%APP_POOL_SERVICE%" >> "%LOG_FILE%" 2>&1
)



:: ==========================================
:: COPY FILES
:: ==========================================
set WEB_STATUS=0
set SERVICE_STATUS=0

if %DEPLOY_WEB%==1 (
    echo Replacing Web files...
    robocopy "%WEB_SOURCE%" "%WEB_TARGET%" /E /R:1 /W:1 /IS /IT >> "%LOG_FILE%"
    set WEB_STATUS=!ERRORLEVEL!
)

if %DEPLOY_SERVICE%==1 (
    echo Replacing Service files...
    robocopy "%SERVICE_SOURCE%" "%SERVICE_TARGET%" /E /R:1 /W:1 /IS /IT >> "%LOG_FILE%"
    set SERVICE_STATUS=!ERRORLEVEL!
)



:: ==========================================
:: CHECK DEPLOY RESULT
:: ==========================================
echo.
echo Checking deploy result...

if %DEPLOY_WEB%==1 (
    if !WEB_STATUS! GEQ 8 (
        echo [ERROR] WEB DEPLOY FAILED — Performing rollback
        goto ROLLBACK
    )
)

if %DEPLOY_SERVICE%==1 (
    if !SERVICE_STATUS! GEQ 8 (
        echo [ERROR] SERVICE DEPLOY FAILED — Performing rollback
        goto ROLLBACK
    )
)



:: ==========================================
:: START POOLS (SUCCESS)
:: ==========================================
echo.
echo Starting App Pools...

if %DEPLOY_WEB%==1 (
    %windir%\system32\inetsrv\appcmd start apppool /apppool.name:"%APP_POOL_WEB%" >> "%LOG_FILE%"
)

if %DEPLOY_SERVICE%==1 (
    %windir%\system32\inetsrv\appcmd start apppool /apppool.name:"%APP_POOL_SERVICE%" >> "%LOG_FILE%"
)

echo.
echo ================================
echo       DEPLOYMENT SUCCESS
echo ================================
echo [%date% %time%] Deploy success >> "%LOG_FILE%"
pause
exit /b



:: ==========================================
:: ROLLBACK SECTION
:: ==========================================
:ROLLBACK
echo Rolling back to previous version...
echo [%date% %time%] Rolling back... >> "%LOG_FILE%"

if %DEPLOY_WEB%==1 (
    robocopy "%BACKUP_WEB%" "%WEB_TARGET%" /E /R:1 /W:1 /IS /IT >> "%LOG_FILE%"
)

if %DEPLOY_SERVICE%==1 (
    robocopy "%BACKUP_SERVICE%" "%SERVICE_TARGET%" /E /R:1 /W:1 /IS /IT >> "%LOG_FILE%"
)

echo Starting App Pools (after rollback)...

if %DEPLOY_WEB%==1 (
    %windir%\system32\inetsrv\appcmd start apppool /apppool.name:"%APP_POOL_WEB%" >> "%LOG_FILE%"
)

if %DEPLOY_SERVICE%==1 (
    %windir%\system32\inetsrv\appcmd start apppool /apppool.name:"%APP_POOL_SERVICE%" >> "%LOG_FILE%"
)

echo.
echo ======================================
echo   DEPLOY FAILED — ROLLBACK DONE
echo ======================================
echo [%date% %time%] Deploy failed, rollback applied >> "%LOG_FILE%"
pause
exit /b
