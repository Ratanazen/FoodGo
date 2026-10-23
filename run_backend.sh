#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR/backend"

if [ -f "venv/bin/python" ]; then
    PYTHON_BIN="venv/bin/python"
elif [ -f "../.venv/bin/python" ]; then
    PYTHON_BIN="../.venv/bin/python"
else
    PYTHON_BIN="python3"
fi

echo "==> Using Python: $PYTHON_BIN"
echo "==> Running migrations..."
$PYTHON_BIN manage.py migrate --noinput || true

echo "==> Ensuring admin user..."
$PYTHON_BIN manage.py ensure_admin || true

echo "==> Starting FoodGo Django Backend on 0.0.0.0:8000..."
exec $PYTHON_BIN manage.py runserver 0.0.0.0:8000
