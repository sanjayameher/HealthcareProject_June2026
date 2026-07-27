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
REM    7086  cds-service
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

REM ── Full paths to tools (bypasses PATH issues entirely) ─────────
set MVN=C:\SANJAYA\MAVEN\apache-maven-3.9.16-bin\apache-maven-3.9.16\bin\mvn.cmd
set NPM=C:\Program Files\nodejs\npm.cmd
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

for %%P in (7081 7082 7083 7084 7085 7086 5001) do (
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

for %%S in ("patient-service" "clinical-service" "billing-service" "portal-service" "audit-service" "cds-service" "healthcare-ui") do (
    taskkill /FI "WINDOWTITLE eq %%~S*" /F >nul 2>&1
)

ping -n 4 127.0.0.1 >nul 2>&1
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

echo   Pulling latest from origin/%BRANCH% ...
git pull origin %BRANCH% >> "%RUNLOG%" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] git pull failed. Check network or resolve conflicts. See log: %RUNLOG%
    pause & exit /b 1
)
echo   [OK] Code is up to date.

REM ── Re-apply local fixes that are not yet in git ────────────────
echo   Applying local service patches...
set NS_FILE=%BACKEND%\portal-service\src\main\java\com\healthcare\portal\service\NotificationService.java
(
echo package com.healthcare.portal.service;
echo.
echo import lombok.RequiredArgsConstructor;
echo import lombok.extern.slf4j.Slf4j;
echo import org.springframework.stereotype.Service;
echo.
echo import javax.sql.DataSource;
echo import java.sql.Connection;
echo import java.sql.PreparedStatement;
echo import java.util.UUID;
echo.
echo @Slf4j
echo @Service
echo @RequiredArgsConstructor
echo public class NotificationService {
echo.
echo     private final DataSource dataSource;
echo.
echo     public void notifyPatient(UUID patientId, String type, String title, String body^) {
echo         try ^(Connection conn = dataSource.getConnection^(^);
echo              PreparedStatement ps = conn.prepareStatement^(
echo                      "INSERT INTO dev.notifications " +
echo                      "(patient_id, channel, status, notification_type, title, body, scheduled_for, created_at, updated_at) " +
echo                      "VALUES (?, 'email'::dev.notification_channel, 'pending'::dev.notification_status, ?, ?, ?, NOW(), NOW(), NOW())"^)^) {
echo             ps.setObject^(1, patientId^);
echo             ps.setString^(2, type^);
echo             ps.setString^(3, title^);
echo             ps.setString^(4, body^);
echo             ps.executeUpdate^(^);
echo         } catch ^(Exception e^) {
echo             log.warn^("Could not save patient notification [patientId={}, type={}]: {}", patientId, type, e.getMessage^(^)^);
echo         }
echo     }
echo.
echo     public void notifyPractitioner^(UUID practitionerId, String type, String title, String body^) {
echo         log.info^("Practitioner notification [practitionerId={}, type={}, title={}]", practitionerId, type, title^);
echo     }
echo }
) > "%NS_FILE%"

REM ── Patch 2: Disable Flyway for patient-service local dev ────────
set PS_LOCAL=%BACKEND%\patient-service\src\main\resources\application-local.yml
(
echo # LOCAL DEVELOPER PROFILE — DO NOT USE IN PRODUCTION
echo # Run with: mvn spring-boot:run "-Dspring-boot.run.profiles=local"
echo.
echo spring:
echo   datasource:
echo     url: jdbc:postgresql://127.0.0.1:5432/healthdb
echo     username: postgres
echo     password: "Aman2011$"
echo     hikari:
echo       connection-init-sql: "SET search_path TO dev, public"
echo.
echo   jpa:
echo     hibernate:
echo       ddl-auto: none
echo     properties:
echo       hibernate:
echo         default_schema: dev
echo.
echo   flyway:
echo     enabled: false  # Schema already exists in DB - skip migrations for local dev
echo.
echo   autoconfigure:
echo     exclude:
echo       - org.springframework.boot.autoconfigure.security.oauth2.resource.servlet.OAuth2ResourceServerAutoConfiguration
echo       - org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration
echo       - org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration
echo       - org.springframework.boot.autoconfigure.kafka.KafkaAutoConfiguration
echo.
echo   cache:
echo     type: none
echo.
echo   kafka:
echo     bootstrap-servers: ""
echo.
echo   cloud:
echo     discovery:
echo       enabled: false
echo.
echo eureka:
echo   client:
echo     enabled: false
echo     register-with-eureka: false
echo     fetch-registry: false
echo.
echo healthcare:
echo   encryption:
echo     key: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
echo.
echo logging:
echo   level:
echo     com.healthcare: DEBUG
echo     org.springframework.security: WARN
echo     org.springframework.kafka: WARN
echo     com.netflix.eureka: OFF
echo     com.netflix.discovery: OFF
) > "%PS_LOCAL%"

REM ── Patch 3: Add hikari connection-init-sql to portal-service local yml ─
set PORTAL_LOCAL=%BACKEND%\portal-service\src\main\resources\application-local.yml
(
echo # LOCAL DEVELOPER PROFILE — DO NOT USE IN PRODUCTION
echo # Run with: mvn spring-boot:run "-Dspring-boot.run.profiles=local"
echo.
echo spring:
echo   datasource:
echo     url: jdbc:postgresql://127.0.0.1:5432/healthdb
echo     username: postgres
echo     password: "Aman2011$"
echo     hikari:
echo       connection-init-sql: "SET search_path TO dev, public"
echo.
echo   jpa:
echo     hibernate:
echo       ddl-auto: none
echo.
echo   autoconfigure:
echo     exclude:
echo       - org.springframework.boot.autoconfigure.security.oauth2.resource.servlet.OAuth2ResourceServerAutoConfiguration
echo       - org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration
echo       - org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration
echo       - org.springframework.boot.autoconfigure.kafka.KafkaAutoConfiguration
echo.
echo   cache:
echo     type: none
echo.
echo   kafka:
echo     bootstrap-servers: ""
echo.
echo   cloud:
echo     discovery:
echo       enabled: false
echo.
echo eureka:
echo   client:
echo     enabled: false
echo     register-with-eureka: false
echo     fetch-registry: false
echo.
echo healthcare:
echo   jwt:
echo     secret: "local-dev-jwt-secret-key-that-is-at-least-256-bits-long-for-hs256-algorithm"
echo     expiry-hours: 24
echo     password-reset-minutes: 15
echo   admin:
echo     seed-email: "admin@healthcare.local"
echo     seed-password: "Admin@1234"
echo   clinical:
echo     service-url: "http://localhost:7081"
echo.
echo logging:
echo   level:
echo     com.healthcare: DEBUG
echo     org.springframework.security: WARN
echo     org.springframework.kafka: WARN
echo     com.netflix.eureka: OFF
echo     com.netflix.discovery: OFF
) > "%PORTAL_LOCAL%"

echo   [OK] Local patches applied.
echo.

REM ════════════════════════════════════════════════════════════════
REM  STEP 3 — Install Frontend Dependencies
REM ════════════════════════════════════════════════════════════════
echo  [STEP 3/7]  Installing Frontend dependencies (npm install)...
echo  ---------------------------------------------------------------
cd /d "%FRONTEND%"

if not exist "%NPM%" (
    echo   [WARN] npm not found at %NPM% — skipping frontend install.
    echo          Start frontend manually: cd healthcare-ui ^& npm install ^& npm run dev
    echo.
    goto STEP4
)

echo   Running npm install...
call "%NPM%" install >> "%RUNLOG%" 2>&1
if %errorlevel% neq 0 (
    echo   [WARN] npm install had issues — continuing anyway. See log: %RUNLOG%
) else (
    echo   [OK] npm dependencies installed.
)
echo.

:STEP4

REM ════════════════════════════════════════════════════════════════
REM  STEP 4 — Compile Backend
REM ════════════════════════════════════════════════════════════════
echo  [STEP 4/7]  Compiling Backend (mvn package -DskipTests)...
echo  ---------------------------------------------------------------
cd /d "%BACKEND%"

if not exist "%MVN%" (
    echo   [ERROR] Maven not found at %MVN%
    echo          Please check the MVN path at the top of this bat file.
    pause & exit /b 1
)

echo   Installing healthcare-common to local Maven repo...
call "%MVN%" install -DskipTests -pl healthcare-common -q >> "%RUNLOG%" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] healthcare-common install failed. See log: %RUNLOG%
    pause & exit /b 1
)
echo   [OK] healthcare-common installed.

echo   Compiling all backend modules...
call "%MVN%" package -DskipTests -q >> "%RUNLOG%" 2>&1
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
for %%F in ("%MIGRATION_DIR%\V*.sql") do echo     %%~nxF
echo   [OK] Migration check complete.
echo.

REM ════════════════════════════════════════════════════════════════
REM  STEP 6 — Start Backend Services
REM ════════════════════════════════════════════════════════════════
echo  [STEP 6/7]  Starting Backend Services...
echo  ---------------------------------------------------------------

set RUN=call %MVN% spring-boot:run "-Dspring-boot.run.profiles=local"

echo   [1/6] patient-service    (port 7081)...
start "patient-service   :7081" /min cmd /k "cd /d "%BACKEND%\patient-service" && %RUN%"
ping -n 9 127.0.0.1 >nul 2>&1

echo   [2/6] clinical-service   (port 7082)...
start "clinical-service  :7082" /min cmd /k "cd /d "%BACKEND%\clinical-service" && %RUN%"
ping -n 6 127.0.0.1 >nul 2>&1

echo   [3/6] billing-service    (port 7083)...
start "billing-service   :7083" /min cmd /k "cd /d "%BACKEND%\billing-service" && %RUN%"
ping -n 6 127.0.0.1 >nul 2>&1

echo   [4/6] portal-service     (port 7084)...
start "portal-service    :7084" /min cmd /k "cd /d "%BACKEND%\portal-service" && %RUN%"
ping -n 6 127.0.0.1 >nul 2>&1

echo   [5/6] audit-service      (port 7085)...
start "audit-service     :7085" /min cmd /k "cd /d "%BACKEND%\audit-service" && %RUN%"
ping -n 6 127.0.0.1 >nul 2>&1

echo   [6/6] cds-service        (port 7086)...
start "cds-service       :7086" /min cmd /k "cd /d "%BACKEND%\cds-service" && %RUN%"

echo.
echo   All 6 backend service windows opened.
echo   Waiting 60 seconds for services to fully initialize...
echo.
ping -n 61 127.0.0.1 >nul 2>&1

REM ════════════════════════════════════════════════════════════════
REM  STEP 7 — Start Frontend Dev Server
REM ════════════════════════════════════════════════════════════════
echo  [STEP 7/7]  Starting Frontend (Vite dev server — port 5001)...
echo  ---------------------------------------------------------------
start "healthcare-ui     :5001" /min cmd /k "cd /d "%FRONTEND%" && "%NPM%" run dev"

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
ping -n 4 127.0.0.1 >nul 2>&1
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
    echo   Opening Admin Portal       ^> http://localhost:5001/login/admin
    start "" %CHROME% --new-tab "http://localhost:5001/login/admin"
    ping -n 2 127.0.0.1 >nul 2>&1
    echo   Opening Patient Portal     ^> http://localhost:5001/login/patient
    start "" %CHROME% --new-tab "http://localhost:5001/login/patient"
    ping -n 2 127.0.0.1 >nul 2>&1
    echo   Opening patient-service    ^> http://localhost:7081/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7081/swagger-ui.html"
    ping -n 2 127.0.0.1 >nul 2>&1
    echo   Opening clinical-service   ^> http://localhost:7082/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7082/swagger-ui.html"
    ping -n 2 127.0.0.1 >nul 2>&1
    echo   Opening billing-service    ^> http://localhost:7083/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7083/swagger-ui.html"
    ping -n 2 127.0.0.1 >nul 2>&1
    echo   Opening portal-service     ^> http://localhost:7084/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7084/swagger-ui.html"
    ping -n 2 127.0.0.1 >nul 2>&1
    echo   Opening audit-service      ^> http://localhost:7085/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7085/swagger-ui.html"
    ping -n 2 127.0.0.1 >nul 2>&1
    echo   Opening cds-service        ^> http://localhost:7086/swagger-ui.html
    start "" %CHROME% --new-tab "http://localhost:7086/swagger-ui.html"
) else (
    echo   [WARN] Chrome not found. Opening with default browser...
    start "" "http://localhost:5001/login/admin"
    start "" "http://localhost:5001/login/patient"
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
echo   Backend     cds-service          7086    http://localhost:7086/swagger-ui.html
echo   Frontend    healthcare-ui        5001    http://localhost:5001
echo   Database    PostgreSQL           5432    healthdb
echo.
echo   ────────────────────────────────────────────────────────────────────────
echo   PORTAL          URL                              CREDENTIALS (pre-filled)
echo   ────────────────────────────────────────────────────────────────────────
echo   Admin Portal    http://localhost:5001/login/admin    admin@healthcare.local / Admin@1234
echo   Patient Portal  http://localhost:5001/login/patient  john.smith@email.com   / Test@1234
echo   ────────────────────────────────────────────────────────────────────────
echo.
echo   Run log    : %RUNLOG%
echo.
echo   (Each service runs in its own minimized window.)
echo  ================================================================
echo.
pause
