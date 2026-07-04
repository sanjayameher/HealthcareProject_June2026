@echo off
REM ============================================================
REM  Healthcare Platform — Start All Backend Services (local)
REM  Services start in dependency order. Each runs in its own
REM  minimized Command Prompt window.
REM
REM  Ports:
REM    8080 — api-gateway
REM    8081 — patient-service
REM    8082 — clinical-service
REM    8083 — billing-service
REM    8084 — portal-service
REM    8085 — audit-service
REM ============================================================

set BASE=c:\SANJAYA\PROJECT\HealthcareProject\backend
set MVN=mvn clean spring-boot:run "-Dspring-boot.run.profiles=local"

echo.
echo  Starting Healthcare Backend Services...
echo  ========================================

echo  [0/6] Installing healthcare-common to local Maven repo...
cd /d %BASE%
mvn install -DskipTests -pl healthcare-common -q
echo  healthcare-common installed OK.
echo.

echo  [1/6] patient-service    (port 8081) ...
start "patient-service   :8081" /min cmd /k "cd /d %BASE%\patient-service && %MVN%"
timeout /t 5 /nobreak >nul

echo  [2/6] clinical-service   (port 8082) ...
start "clinical-service  :8082" /min cmd /k "cd /d %BASE%\clinical-service && %MVN%"
timeout /t 3 /nobreak >nul

echo  [3/6] billing-service    (port 8083) ...
start "billing-service   :8083" /min cmd /k "cd /d %BASE%\billing-service && %MVN%"
timeout /t 3 /nobreak >nul

echo  [4/6] portal-service     (port 8084) ...
start "portal-service    :8084" /min cmd /k "cd /d %BASE%\portal-service && %MVN%"
timeout /t 3 /nobreak >nul

echo  [5/6] audit-service      (port 8085) ...
start "audit-service     :8085" /min cmd /k "cd /d %BASE%\audit-service && %MVN%"
timeout /t 3 /nobreak >nul

echo  [6/6] api-gateway        (port 8080) ...
start "api-gateway       :8080" /min cmd /k "cd /d %BASE%\api-gateway && %MVN%"

echo.
echo  ========================================
echo  All 6 services are starting up.
echo  Each service opens in a minimized window.
echo
echo  Wait ~60 seconds for all services to be ready.
echo  Then start the frontend:
echo    cd healthcare-ui
echo    npm run dev
echo
echo  Login at: http://localhost:3000/login/admin
echo  ========================================
echo.
pause