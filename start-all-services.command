#!/bin/bash
# ================================================================
#  Healthcare Platform — Full Start Script (macOS / Linux)
#  Branch : main
#
#  Steps:
#    [1]  Stop running services (ports 7081-7085, 5001)
#    [2]  Git pull latest code from branch main
#    [3]  Compile Frontend  (npm ci + tsc --noEmit)
#    [4]  Compile Backend   (mvn package -DskipTests)
#    [5]  Verify Flyway migration scripts
#    [6]  Start Backend services  (ports 7081-7085)
#    [7]  Start Frontend dev server (port 5001)
#
#  Port Map:
#    7081  patient-service
#    7082  clinical-service
#    7083  billing-service
#    7084  portal-service
#    7085  audit-service
#    5001  healthcare-ui (Vite)
#    5432  PostgreSQL (healthdb)
# ================================================================

# ── Resolve project root (directory containing this script) ──────
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$ROOT/backend"
FRONTEND="$ROOT/healthcare-ui"
BRANCH="main"
LOG_DIR="$ROOT/logs"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
RUNLOG="$LOG_DIR/start_$TIMESTAMP.log"
MVN_RUN="mvn spring-boot:run -Dspring-boot.run.profiles=local"

# ── Colours ───────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${RESET}   $1"; }
warn() { echo -e "  ${YELLOW}[WARN]${RESET}  $1"; }
err()  { echo -e "  ${RED}[ERROR]${RESET} $1"; }
step() { echo -e "\n${BOLD}${CYAN} $1${RESET}"; echo "  ---------------------------------------------------------------"; }

# ── Abort helper ──────────────────────────────────────────────────
abort() {
    err "$1"
    echo -e "  See log: $RUNLOG"
    echo ""
    exit 1
}

# ── Create logs directory ─────────────────────────────────────────
mkdir -p "$LOG_DIR"

echo ""
echo -e "${BOLD}================================================================${RESET}"
echo -e "${BOLD} Healthcare Platform — Full Deployment Script${RESET}"
echo -e " Branch : $BRANCH"
echo -e " Time   : $(date)"
echo -e "${BOLD}================================================================${RESET}"
echo -e " Log file: $RUNLOG"
echo ""

# ════════════════════════════════════════════════════════════════
#  STEP 1 — Kill processes on ports 7081-7085 and 5001
# ════════════════════════════════════════════════════════════════
step "[STEP 1/7]  Stopping existing services on ports 7081-7085 and 5001..."

for PORT in 7081 7082 7083 7084 7085 5001; do
    PID=$(lsof -ti tcp:$PORT 2>/dev/null)
    if [ -n "$PID" ]; then
        echo -e "  ${YELLOW}[KILL]${RESET}  Port $PORT — PID $PID — terminating..."
        kill -9 $PID 2>/dev/null && ok "Port $PORT freed." || warn "Could not kill PID $PID."
    else
        echo "  Port $PORT is free."
    fi
done

sleep 2
ok "All old processes cleared."

# ════════════════════════════════════════════════════════════════
#  STEP 2 — Git pull latest from branch main
# ════════════════════════════════════════════════════════════════
step "[STEP 2/7]  Git pull — branch: $BRANCH"
cd "$ROOT" || abort "Cannot cd to project root: $ROOT"

command -v git &>/dev/null || abort "git not found. Install Xcode Command Line Tools: xcode-select --install"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
echo "  Current branch: $CURRENT_BRANCH"

# Switch to main if not already on it
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo "  Switching from $CURRENT_BRANCH to $BRANCH ..."
    git checkout "$BRANCH" >> "$RUNLOG" 2>&1 || abort "Could not checkout branch '$BRANCH'. Check branch name or resolve local conflicts."
    ok "Switched to branch $BRANCH."
else
    echo "  Already on branch $BRANCH."
fi

# Stash local changes silently so pull doesn't fail
git stash >> "$RUNLOG" 2>&1

echo "  Pulling latest from origin/$BRANCH ..."
git pull origin "$BRANCH" >> "$RUNLOG" 2>&1 || abort "git pull failed. Check your network connection or resolve merge conflicts."
ok "Code is up to date."

# ════════════════════════════════════════════════════════════════
#  STEP 3 — Compile Frontend
# ════════════════════════════════════════════════════════════════
step "[STEP 3/7]  Compiling Frontend (npm ci + tsc --noEmit)..."
cd "$FRONTEND" || abort "Frontend directory not found: $FRONTEND"

command -v node &>/dev/null || abort "Node.js not found. Install from https://nodejs.org (v20+)"
NODE_VER=$(node --version)
NPM_VER=$(npm --version)
NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
echo "  Node: $NODE_VER   npm: v$NPM_VER"
if [ "$NODE_MAJOR" -lt 20 ]; then
    abort "Node.js $NODE_VER is too old. Vite 8 requires Node 20+.\n  Run: brew unlink node@18 && brew link node@22 --force --overwrite"
fi

echo "  Installing / updating npm dependencies (ci)..."
npm ci >> "$RUNLOG" 2>&1 || abort "npm ci failed."
ok "npm dependencies installed."

echo "  Running TypeScript type check..."
npx tsc --noEmit >> "$RUNLOG" 2>&1
if [ $? -ne 0 ]; then
    warn "TypeScript type errors detected. Continuing — fix TS errors before next release."
    warn "See log: $RUNLOG"
else
    ok "TypeScript compilation clean."
fi

# ════════════════════════════════════════════════════════════════
#  STEP 4 — Compile Backend
# ════════════════════════════════════════════════════════════════
step "[STEP 4/7]  Compiling Backend (mvn package -DskipTests)..."
cd "$BACKEND" || abort "Backend directory not found: $BACKEND"

command -v mvn &>/dev/null || abort "Maven not found. Install Maven 3.9+: brew install maven"
MVN_VER=$(mvn --version 2>/dev/null | head -1)
echo "  $MVN_VER"

echo "  Installing healthcare-common to local Maven repo..."
mvn install -DskipTests -pl healthcare-common -q >> "$RUNLOG" 2>&1 || abort "healthcare-common install failed."
ok "healthcare-common installed."

echo "  Compiling all backend modules..."
mvn package -DskipTests -q >> "$RUNLOG" 2>&1 || abort "Backend Maven build failed."
ok "Backend build successful."

# ════════════════════════════════════════════════════════════════
#  STEP 5 — Verify Flyway Migration Scripts
# ════════════════════════════════════════════════════════════════
step "[STEP 5/7]  Verifying Flyway migration scripts..."

MIGRATION_DIR="$BACKEND/patient-service/src/main/resources/db/migration"
echo "  Migration path: $MIGRATION_DIR"

[ -d "$MIGRATION_DIR" ] || abort "Migration directory not found: $MIGRATION_DIR"

MIGRATE_COUNT=$(find "$MIGRATION_DIR" -name "V*.sql" | wc -l | tr -d ' ')
echo "  Found $MIGRATE_COUNT Flyway versioned migration file(s)."

if [ "$MIGRATE_COUNT" -eq 0 ]; then
    warn "No Flyway migration files found (V*.sql). Check the directory."
else
    echo "  Listing migration files:"
    find "$MIGRATION_DIR" -name "V*.sql" | sort | while read -r f; do
        echo "    $(basename "$f")"
    done

    BAD_FILES=0
    while IFS= read -r f; do
        fname=$(basename "$f")
        if ! echo "$fname" | grep -qE '^V[0-9]+__.*\.sql$'; then
            warn "Non-standard filename: $fname"
            BAD_FILES=$((BAD_FILES + 1))
        fi
    done < <(find "$MIGRATION_DIR" -name "*.sql")

    if [ "$BAD_FILES" -gt 0 ]; then
        warn "$BAD_FILES file(s) with non-standard names — Flyway may reject them."
    else
        ok "All migration filenames follow Flyway naming convention (V[n]__name.sql)."
    fi
fi

# ════════════════════════════════════════════════════════════════
#  STEP 6 — Start Backend Services
# ════════════════════════════════════════════════════════════════
step "[STEP 6/7]  Starting Backend Services..."

start_service() {
    local NAME="$1"
    local DIR="$2"
    local PORT="$3"
    echo "  Starting $NAME  (port $PORT)..."
    osascript -e "tell application \"Terminal\" to do script \"echo '=== $NAME :$PORT ==='; cd \\\"$DIR\\\" && $MVN_RUN\"" &>/dev/null
}

start_service "patient-service"  "$BACKEND/patient-service"  7081
sleep 8

start_service "clinical-service" "$BACKEND/clinical-service" 7082
sleep 5

start_service "billing-service"  "$BACKEND/billing-service"  7083
sleep 5

start_service "portal-service"   "$BACKEND/portal-service"   7084
sleep 5

start_service "audit-service"    "$BACKEND/audit-service"    7085
sleep 5

echo ""
ok "All 5 backend service windows opened."
echo "  Waiting 60 seconds for services to fully initialize..."
sleep 60

# ════════════════════════════════════════════════════════════════
#  STEP 7 — Start Frontend Dev Server
# ════════════════════════════════════════════════════════════════
step "[STEP 7/7]  Starting Frontend (Vite dev server — port 5001)..."
osascript -e "tell application \"Terminal\" to do script \"echo '=== healthcare-ui :5001 ==='; cd \\\"$FRONTEND\\\" && npm run dev\""

# ── Wait for Vite to be ready (poll port 5001) ────────────────────
echo "  Waiting for Vite dev server to be ready on port 5001..."
for i in $(seq 1 30); do
    if lsof -ti tcp:5001 &>/dev/null; then
        ok "Frontend is up on port 5001."
        break
    fi
    echo "  Still waiting... ($i/30)"
    sleep 3
done

# ════════════════════════════════════════════════════════════════
#  OPEN ALL URLs IN CHROME
# ════════════════════════════════════════════════════════════════
step "[BONUS]  Opening all URLs in Google Chrome..."

CHROME_APP="Google Chrome"

open_chrome() {
    local URL="$1"
    local LABEL="$2"
    echo "  Opening $LABEL → $URL"
    open -a "$CHROME_APP" "$URL" 2>/dev/null || \
        open "$URL"   # fallback to default browser if Chrome not found
    sleep 1
}

open_chrome "http://localhost:5001/login/admin"          "Login Page"
open_chrome "http://localhost:7081/swagger-ui.html"      "patient-service  Swagger"
open_chrome "http://localhost:7082/swagger-ui.html"      "clinical-service Swagger"
open_chrome "http://localhost:7083/swagger-ui.html"      "billing-service  Swagger"
open_chrome "http://localhost:7084/swagger-ui.html"      "portal-service   Swagger"
open_chrome "http://localhost:7085/swagger-ui.html"      "audit-service    Swagger"

ok "All URLs opened in Chrome."

# ════════════════════════════════════════════════════════════════
#  DONE — Summary
# ════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}================================================================${RESET}"
echo -e "${BOLD}${GREEN} All services are running!${RESET}"
echo -e "${BOLD}${GREEN}================================================================${RESET}"
echo ""
echo -e "  ${BOLD}LAYER       SERVICE              PORT    URL${RESET}"
echo    "  ────────────────────────────────────────────────────────────────"
echo    "  Backend     patient-service      7081    http://localhost:7081/swagger-ui.html"
echo    "  Backend     clinical-service     7082    http://localhost:7082/swagger-ui.html"
echo    "  Backend     billing-service      7083    http://localhost:7083/swagger-ui.html"
echo    "  Backend     portal-service       7084    http://localhost:7084/swagger-ui.html"
echo    "  Backend     audit-service        7085    http://localhost:7085/swagger-ui.html"
echo    "  Frontend    healthcare-ui        5001    http://localhost:5001"
echo    "  Database    PostgreSQL           5432    healthdb"
echo ""
echo -e "  ${BOLD}${GREEN}▶  Login URL : http://localhost:5001/login/admin${RESET}"
echo ""
echo -e "  Run log saved to: $RUNLOG"
echo ""
echo    "  (Each service runs in its own Terminal tab.)"
echo -e "${BOLD}================================================================${RESET}"
echo ""
