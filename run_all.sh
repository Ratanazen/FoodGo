#!/bin/bash

echo "🚀 Starting FoodGo Combined Environment (Backend + Frontend)..."

# Kill existing processes on ports 8000 and 8080 to prevent conflicts
fuser -k 8000/tcp 2>/dev/null
fuser -k 8080/tcp 2>/dev/null

echo "📦 Starting Django Backend (Daphne / WebSockets) on 0.0.0.0:8000..."
cd backend
source venv/bin/activate 2>/dev/null || true
python manage.py runserver 0.0.0.0:8000 &
BACKEND_PID=$!
cd ..

echo "📱 Starting Flutter Web Frontend on 0.0.0.0:8080..."
cd foodgo_flutter
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 &
FRONTEND_PID=$!
cd ..

echo "✅ Both servers are spinning up!"
echo "   - Backend API: http://127.0.0.1:8000"
echo "   - Flutter App: http://127.0.0.1:8080"
echo "Press Ctrl+C to stop both."

trap "echo 'Stopping all...'; kill $BACKEND_PID; kill $FRONTEND_PID; exit" INT
wait
