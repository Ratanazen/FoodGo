#!/usr/bin/env bash
# Exit on error
set -o errexit

cd backend
echo "==> Installing Python dependencies..."
pip install --no-cache-dir -r requirements.txt

echo "==> Collecting static files..."
python manage.py collectstatic --noinput

echo "==> Running database migrations..."
python manage.py migrate --noinput

echo "==> Backend build completed successfully!"
