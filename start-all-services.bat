@echo off
setlocal EnableDelayedExpansion

REM ================================================================
REM  Healthcare Platform — Full Start Script (Windows)
REM  Branch : main
REM
REM  Steps:
REM    [1]  Stop running services (ports 7081-7085, 5001)
REM    [2]  Git pull latest code from branch main
REM    [3]  Compile Frontend  (npm ci + tsc)
REM    [4]  Compile Backend   (mvn package -DskipTests)
REM    [5]  Verify Flyway migration scripts
REM    [6]  Start Backend services
REM    [7]  Start Frontend dev server (port 5001)
REM    [8]  Open all URLs in Chrome
REM
REM  Port Map:
REM    7081  patient-service
REM    7082  clinical-service
REM    7083  billing-service
REM    7084  portal-service
REM    7085  audit-service
REM    5001  healthcare-ui (Vite)
REM    5432  PostgreSQL (healthdb)
REM ================================================================

REM ── Project root = folder containing this .bat file ──────────────
set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%

set BACKEND=%ROOT%\backend
set FRONTEND=%ROOT%\healthcare-ui
set BRANCH=main
set LOG_DIR=%ROOT%\logs
set TIMESTAMP=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

echo.
echo  ================================================================
echo   Healthcare Platform — Full Deployment Script
echo   Branch : %BRANCH%
echo   Time   : %date% %time%
echo  ================================================================
echo.

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set RUNLOG=%LOG_DIR%\start_%TIMESTAMP%.log
echo  Log file: %RUNLOG%
echo.

REM ════════════════════════════════════════════════════════════════
REM  STEP 1 — Stop running services on ports 7081-7085 and 5001
REM ════════════════════════════════════════════════════════════════
echo  [STEP 1/7]  Stopping existing services...
echo  ---------------------------------------------------------------

for %%P in (7081 7082 7083 7084 7085 5001) do (
    echo   Checking port %%P ...
    for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr /r ":%%P " ^| findstr "LISTENING"') do (
        if not "%%a"=="" (
            echo   [KILL] PID %%a is using port %%P — terminating...
            taskkill /F /PID %%a >nul 2>&1
            if !errorlevel! equ 0 (
                echo   [OK]   Port %%P freed.
            ) else (
                echo   [WARN] Could not kill PID %%a — may need admin rights.
            )
        )
    )
)

for %%S in ("patient-service" "clinical-service" "billing-service" "portal-service" "audit-service" "healthcare-ui") do (
    taskkill /FI "WINDOWTITLE eq %%~S*" /F >nul 2>&1
)

timeout /t 3 /nobreak >nul
echo   All old processes cleared.
echo.

REM ════════════════════════════════════════════════════════════════
REM  STEP 2 — Git pull latest from branch main
REM ════════════════════════════════════════════════════════════════
echo  [STEP 2/7]  Git pull — branch: %BRANCH%
echo  ---------------------------------------------------------------
cd /d "%ROOT%"

git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] git not found in PATH. Install Git from https://git-scm.com
    pause & exit /b 1
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set CURRENT_BRANCH=%%B
echo   Current branch: %CURRENT_BRANCH%

if /i not "%CURRENT_BRANCH%"=="%BRANCH%" (
    echo   Switching from %CURRENT_BRANCH% to %BRANCH% ...
    git checkout %BRANCH% >> "%RUNLOG%" 2>&1
    if %errorlevel% neq 0 (
        echo   [ERROR] Could not checkout branch %BRANCH%. See log: %RUNLOG%
        pause & exit /b 1
    )
    echo   [OK] Switched to branch %BRANCH%.
) else (
    echo   Already on branch %BRANCH%.
)

git stash >> "%RUNLOG%" 2>&1

echo   Pulling latest from origin/%BRANCH% ...
git pull origin %BRANCH% >> "%RUNLOG%" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] git pull failed. Check network or resolve conflicts. See log: %RUNLOG%
    pause & exit /b 1
)
echo   [OK] Code is up to date.
echo.

REM ════════════════════════════════════════════════════════════════
REM  STEP 3 — Compile Frontend
REM ════════════════════════════════════════════════════════════════
echo  [STEP 3/7]  Compiling Frontend (npm ci + tsc --noEmit)...
echo  ---------------------------------------------------------------
cd /d "%FRONTEND%"

node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] Node.js not found. Install from https://nodejs.org (v18+)
    pause & exit /b 1
)
for /f "delims=" %%V in ('node --version') do set NODE_VER=%%V
for /f "delims=" %%V in ('npm --version') do set NPM_VER=%%V
echo   Node: %NODE_VER%   npm: v%NPM_VER%

echo   Installing / updating npm dependencies (ci)...
npm ci >> "%RUNLOG%" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] npm ci failed. See log: %RUNLOG%
    pause & exit /b 1
)
echo   [OK] npm dependencies installed.

echo   Running TypeScript type check...
npx tsc --noEmit >> "%RUNLOG%" 2>&1
if %errorlevel% neq 0 (
    echo   [WARN] TypeScript type errors detected. See log: %RUNLOG%
    echo          Continuing — fix TS errors before next release.
) else (
    echo   [OK] TypeScript compilation clean.
)
echo.

REM ════════════════════════════════════════════════════════════════
REM  STEP 4 — Compile Backend
REM ════════════════════════════════════════════════════════════════
echo  [STEP 4/7]  Compiling Backend (mvn package -DskipTests)...
echo  ---------------------------------------------------------------
cd /d "%BACKEND%"

mvn --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] Maven not found. Install Maven 3.9+ and add to PATH.
    pause & exit /b 1
)

echo   Installing healthcare-common to local Maven repo...
mvn install -DskipTests -pl healthcare-common -q >> "%RUNLOG%" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] healthcare-common install failed. See log: %RUNLOG%
    pause & exit /b 1
)
echo   [OK] healthcare-common installed.

echo   Compiling all backend modules...
mvn package -DskipTests -q >> "%RUNLOG%" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] Backend Maven build failed. See log: %RUNLOG%
    pause & exit /b 1
)
echo   [OK] Backend build successful.
echo.

REM ════════════════════════════════════════════════════════════════
REM  STEP 5 — Verify Flyway Migration Scripts
REM ════════════════════════════════════════════════════════════════
echo  [STEP 5/7]  Verifying Flyway migration scripts...
echo  ---------------------------------------------------------------

set MIGRATION_DIR=%BACKEND%\patient-service\src\main\resources\db\migration
echo   Migration path: %MIGRATION_DIR%

if not exist "%MIGRATION_DIR%" (
    echo   [ERROR] Migration directory not found: %MIGRATION_DIR%
    pause & exit /b 1
)

set MIGRATE_COUNT=0
for %%F in ("%MIGRATION_DIR%\V*.sql") do set /a MIGRATE_COUNT+=1
echo   Found %MIGRATE_COUNT% Flyway versioned migration file(s).

if %MIGRATE_COUNT% gtr 0 (
    echo   Listing migration files:
    for %%F in ("%MIGRATION_DIR%\V*.sql") do echo     %%~nxF
    set BAD_FILES=0
    for %%F in ("%MIGRATION_DIR%\*.sql") do (
        echo %%~nxF | findstr /r "^V[0-9][0-9]*__.*\.sql$" >nul 2>&1
        if !errorlevel! neq 0 (
            echo   [WARN] Non-standard filename: %%~nxF
            set /a BAD_FILES+=1
        )
    )
    if !BAD_FILES! equ 0 (
        echo   [OK] All migration filenames follow Flyway naming convention.
    )
) else (
    echo   [WARN] No Flyway migration files found.
)
echo.

REM ════════════════════════════════════════════════════════════════
REM  STEP 6 — Start Backend Services
REM ════════════════════════════════════════════════════════════════
echo  [STEP 6/7]  Starting Backend Services...
echo  ---------------------------------------------------------------

set RUN=mvn spring-boot:run "-Dspring-boot.run.profiles=local"

echo   [1/5] patient-service    (port 7081)...
start "patient-service   :7081" /min cmd /k "cd /d "%BACKEND%\patient-service" && %RUN%"
timeout /t 8 /nobreak >nul

echo   [2/5] clinical-service   (port 7082)...
start "clinical-service  :7082" /min cmd /k "cd /d "%BACKEND%\clinical-service" && %RUN%"
timeout /t 5 /nobreak >nul

echo   [3/5] billing-service    (port 7083)...
start "billing-service   :7083" /min cmd /k "cd /d "%BACKEND%\billing-service" && %RUN%"
timeout /t 5 /nobreak >nul

echo   [4/5] portal-service     (port 7084)...
start "portal-service    :7084" /min cmd /k "cd /d "%BACKEND%\portal-service" && %RUN%"
timeout /t 5 /nobreak >nul

echo   [5/5] audit-service      (port 7085)...
start "audit-service     :7085" /min cmd /k "cd /d "%BACKEND%\audit-service" && %RUN%"

echo.
echo   All 5 backend service windows opened.
echo   Waiting 60 seconds for services to fully initialize...
echo.
timeout /t 60 /nobreak >nul

REM ════════════════════════════════════════════════════════════════
REM  STEP 7 — Start Frontend Dev Server
REM ════════════════════════════════════════════════════════════════
echo  [STEP 7/7]  Starting Frontend (Vite dev server — port 5001)...
echo  ---------------------------------------------------------------
start "healthcare-ui     :5001" /min cmd /k "cd /d "%FRONTEND%" && npm run dev"

echo   Waiting for Vite dev server to be ready on port 5001...
set /a WAIT_COUNT=0
:WAIT_LOOP
netstat -aon 2>nul | findstr /r ":5001 " | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 goto VITE_READY
set /a WAIT_COUNT+=1
if %WAIT_COUNT% geq 30 (
    echo   [WARN] Vite may still be starting. Opening browser anyway...
    goto VITE_READY
)
echo   Still waiting... (%WAIT_COUNT%/30)
timeout /t 3 /nobreak >nul
goto WAIT_LOOP

:VITE_READY
echo   [OK] Frontend is ready.
echo.

REM ════════════════════════════════════════════════════════════════
REM  OPEN ALL URLs IN CHROME
REM ════════════════════════════════════════════════════════════════
echo  [BONUS]  Opening all URLs in Google Chrome...
echo  ---------------------------------------------------------------

set CHROME="C:\Program Files\Google\Chrome\Application\chrome.exe"
if not exist %CHROME% set CHROME="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

if exist %CHROME% (
    echo   Opening Login Page         ^> http://localhost:5001/login/admin
    start "" %CHROME% --new-tab "http://localhost:5001/login/admin"
    timeout /t 1 /nobreak >nul
    echo   Opening patient-service    ^> http://localhost:7081/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7081/swagger-ui.html"
    timeout /t 1 /nobreak >nul
    echo   Opening clinical-service   ^> http://localhost:7082/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7082/swagger-ui.html"
    timeout /t 1 /nobreak >nul
    echo   Opening billing-service    ^> http://localhost:7083/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7083/swagger-ui.html"
    timeout /t 1 /nobreak >nul
    echo   Opening portal-service     ^> http://localhost:7084/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7084/swagger-ui.html"
    timeout /t 1 /nobreak >nul
    echo   Opening audit-service      ^> http://localhost:7085/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7085/swagger-ui.html"
) else (
    echo   [WARN] Chrome not found. Opening with default browser...
    start "" "http://localhost:5001/login/admin"
)
echo   [OK] All URLs opened.
echo.

REM ════════════════════════════════════════════════════════════════
REM  DONE — Summary
REM ════════════════════════════════════════════════════════════════
echo.
echo  ================================================================
echo   All services are running!
echo  ================================================================
echo.
echo   LAYER       SERVICE              PORT    URL
echo   ────────────────────────────────────────────────────────────────
echo   Backend     patient-service      7081    http://localhost:7081/swagger-ui.html
echo   Backend     clinical-service     7082    http://localhost:7082/swagger-ui.html
echo   Backend     billing-service      7083    http://localhost:7083/swagger-ui.html
echo   Backend     portal-service       7084    http://localhost:7084/swagger-ui.html
echo   Backend     audit-service        7085    http://localhost:7085/swagger-ui.html
echo   Frontend    healthcare-ui        5001    http://localhost:5001
echo   Database    PostgreSQL           5432    healthdb
echo.
echo   Login URL  : http://localhost:5001/login/admin
echo   Run log    : %RUNLOG%
echo.
echo   (Each service runs in its own minimized window.)
echo  ================================================================
echo.
pause
