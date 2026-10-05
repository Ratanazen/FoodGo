#!/usr/bin/env bash
set -e

PORT="${PORT:-8000}"

echo "==> Running database migrations..."
python manage.py migrate --noinput || true

echo "==> Ensuring admin & demo accounts..."
python manage.py ensure_admin || true
python manage.py seed_full_menu || true

echo "==> Collecting static files..."
python manage.py collectstatic --noinput || true

echo "==> Starting Daphne ASGI server on 0.0.0.0:${PORT}..."
exec daphne --proxy-headers -b 0.0.0.0 -p "${PORT}" config.asgi:application
