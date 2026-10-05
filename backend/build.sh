#!/usr/bin/env bash
# Exit on error
set -o errexit

echo "==> Installing Python dependencies..."
pip install --no-cache-dir -r requirements.txt

echo "==> Collecting static files..."
python manage.py collectstatic --noinput

echo "==> Running database migrations..."
python manage.py migrate --noinput

echo "==> Ensuring admin & demo accounts..."
python manage.py ensure_admin || true
python manage.py seed_full_menu || true

echo "==> Backend build completed successfully!"
