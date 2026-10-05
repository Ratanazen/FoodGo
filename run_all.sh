#!/usr/bin/env bash
set -e

# Always run from the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "============================================================"
echo "🚀 FoodGo: Starting Full Stack Environment"
echo "============================================================"

# Free ports 8000 and 8080 if already in use
echo "🧹 Freeing ports 8000 and 8080..."
if command -v fuser >/dev/null 2>&1; then
    fuser -k 8000/tcp 2>/dev/null || true
    fuser -k 8080/tcp 2>/dev/null || true
fi
if command -v lsof >/dev/null 2>&1; then
    lsof -ti:8000 | xargs -r kill -9 2>/dev/null || true
    lsof -ti:8080 | xargs -r kill -9 2>/dev/null || true
fi

# Detect Python in virtualenv or system
PYTHON_CMD="python"
if [ -f "$PROJECT_ROOT/backend/venv/bin/python" ]; then
    PYTHON_CMD="$PROJECT_ROOT/backend/venv/bin/python"
elif [ -f "$PROJECT_ROOT/backend/.venv/bin/python" ]; then
    PYTHON_CMD="$PROJECT_ROOT/backend/.venv/bin/python"
elif [ -f "$PROJECT_ROOT/.venv/bin/python" ]; then
    PYTHON_CMD="$PROJECT_ROOT/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
fi

echo "📦 Preparing Django Backend (using $PYTHON_CMD)..."
cd "$PROJECT_ROOT/backend"

echo "🔄 Running database migrations..."
$PYTHON_CMD manage.py migrate --noinput

echo "🌱 Ensuring demo accounts and full food menu are seeded..."
$PYTHON_CMD manage.py seed_full_menu

echo "⚡ Starting Daphne / Django server on 0.0.0.0:8000..."
$PYTHON_CMD manage.py runserver 0.0.0.0:8000 &
BACKEND_PID=$!

# Function to clean up child processes on exit
cleanup() {
    echo ""
    echo "🛑 Shutting down FoodGo services..."
    if [ -n "$BACKEND_PID" ]; then
        kill "$BACKEND_PID" 2>/dev/null || true
    fi
    if [ -n "$FRONTEND_PID" ]; then
        kill "$FRONTEND_PID" 2>/dev/null || true
    fi
    if command -v fuser >/dev/null 2>&1; then
        fuser -k 8000/tcp 2>/dev/null || true
        fuser -k 8080/tcp 2>/dev/null || true
    fi
    echo "👋 All services stopped cleanly."
    exit 0
}

trap cleanup INT TERM

# Start Flutter Web Frontend if Flutter is available
cd "$PROJECT_ROOT/foodgo_flutter"
if command -v flutter >/dev/null 2>&1; then
    echo "📱 Starting Flutter Web Frontend on 0.0.0.0:8080..."
    flutter pub get
    flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 &
    FRONTEND_PID=$!
else
    echo "⚠️ Flutter command not found in PATH. Backend is running standalone."
fi

cd "$PROJECT_ROOT"

echo ""
echo "============================================================"
echo "✅ FOODGO FULL ENVIRONMENT IS RUNNING!"
echo "============================================================"
echo "   🌐 Backend API:      http://127.0.0.1:8000"
echo "   📡 API Landing:      http://127.0.0.1:8000/api/"
echo "   🛠️  Admin Portal:    http://127.0.0.1:8000/admin/"
echo "   📱 Flutter Web App:  http://127.0.0.1:8080"
echo "============================================================"
echo "👥 DEMO LOGIN CREDENTIALS:"
echo "   Role              Username    Password     Details"
echo "   --------------------------------------------------------"
echo "   Customer:         customer1   customer123  (Wallet: $100.00)"
echo "   Restaurant Owner: owner       owner123     (Glass Burger)"
echo "   Restaurant Owner: owner2      owner123     (Crystal Pizza)"
echo "   Delivery Driver:  driver1     driver123    (Active status)"
echo "   System Admin:     admin       admin123     (Superuser)"
echo "============================================================"
echo "Press Ctrl+C to stop all servers."

wait
