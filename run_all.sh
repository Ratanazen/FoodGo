#!/bin/bash

echo "🚀 Starting FoodGo Combined Environment (Backend + Frontend)..."

# Kill existing processes on ports 8000 and 8080 to prevent conflicts
fuser -k 8000/tcp 2>/dev/null
fuser -k 8080/tcp 2>/dev/null

echo "📦 Preparing Django Backend..."
cd backend
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "../.venv/bin/activate" ]; then
    source ../.venv/bin/activate
elif [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
fi

echo "🔄 Running database migrations..."
python manage.py migrate --noinput

echo "🌱 Seeding demo accounts and full food menu..."
python manage.py seed_full_menu

echo "⚡ Starting Daphne ASGI / HTTP server on 0.0.0.0:8000..."
python manage.py runserver 0.0.0.0:8000 &
BACKEND_PID=$!
cd ..

echo "📱 Starting Flutter Web Frontend on 0.0.0.0:8080..."
cd foodgo_flutter
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 &
FRONTEND_PID=$!
cd ..

echo ""
echo "============================================================"
echo "✅ FOODGO FULL ENVIRONMENT IS RUNNING!"
echo "============================================================"
echo "   🌐 Backend API:      http://127.0.0.1:8000"
echo "   🛠️  Admin Portal:    http://127.0.0.1:8000/admin/"
echo "   📱 Flutter Web App:  http://127.0.0.1:8080"
echo "============================================================"
echo "👥 DEMO LOGIN CREDENTIALS:"
echo "   Customer:         customer1  / customer123 (Wallet: $100)"
echo "   Restaurant Owner: owner      / owner123"
echo "   Delivery Driver:  driver1    / driver123"
echo "   System Admin:     admin      / admin123"
echo "============================================================"
echo "Press Ctrl+C to stop both servers."

trap "echo 'Stopping all...'; kill $BACKEND_PID 2>/dev/null; kill $FRONTEND_PID 2>/dev/null; exit" INT
wait
