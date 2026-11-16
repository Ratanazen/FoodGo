#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AVD_NAME="${AVD_NAME:-Medium_Phone_API_37.0}"
MODE="run"
API_MODE="local"
HEADLESS=0

for arg in "$@"; do
    case "$arg" in
        --test)
            MODE="test"
            ;;
        --live)
            API_MODE="live"
            ;;
        --local)
            API_MODE="local"
            ;;
        --headless)
            HEADLESS=1
            ;;
        *)
            echo "Usage: $0 [--test] [--local|--live] [--headless]"
            exit 1
            ;;
    esac
done

PYTHON_BIN="$PROJECT_ROOT/backend/venv/bin/python"
if [ ! -x "$PYTHON_BIN" ]; then
    PYTHON_BIN="python3"
fi

BACKEND_PID=""
EMULATOR_PID=""

cleanup() {
    if [ -n "$BACKEND_PID" ] && kill -0 "$BACKEND_PID" 2>/dev/null; then
        kill "$BACKEND_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

if [ "$API_MODE" = "local" ]; then
    if ! curl -sf http://127.0.0.1:8000/api/health/ >/dev/null 2>&1; then
        echo "[BACKEND] Starting local Django backend on 0.0.0.0:8000..."
        (
            cd "$PROJECT_ROOT/backend"
            "$PYTHON_BIN" manage.py migrate --noinput
            "$PYTHON_BIN" manage.py ensure_admin
            "$PYTHON_BIN" manage.py seed_full_menu
            exec "$PYTHON_BIN" manage.py runserver 0.0.0.0:8000
        ) >/tmp/foodgo_backend.log 2>&1 &
        BACKEND_PID=$!

        for _ in $(seq 1 30); do
            if curl -sf http://127.0.0.1:8000/api/health/ >/dev/null 2>&1; then
                break
            fi
            sleep 1
        done
    else
        echo "[BACKEND] Reusing running backend on 127.0.0.1:8000"
    fi
    API_URL="http://10.0.2.2:8000/api/"
    WS_URL="ws://10.0.2.2:8000/ws/tracking/"
    PAYMENT_WS_URL="ws://10.0.2.2:8000/ws/payments/"
else
    API_URL="https://foodgo.rtnaeam611.workers.dev/api/"
    WS_URL="wss://foodgo-53pl.onrender.com/ws/tracking/"
    PAYMENT_WS_URL="wss://foodgo-53pl.onrender.com/ws/payments/"
fi

# Ensure an Android emulator is attached
DEVICE_ID="$(adb devices | awk 'NR>1 && $2=="device" && $1 ~ /^emulator-/ {print $1; exit}')"
if [ -z "$DEVICE_ID" ]; then
    echo "[EMULATOR] Launching AVD $AVD_NAME..."
    EMULATOR_BIN="${ANDROID_HOME:-$HOME/Android/Sdk}/emulator/emulator"
    if [ ! -x "$EMULATOR_BIN" ]; then
        EMULATOR_BIN="$(command -v emulator)"
    fi
    EMU_EXTRA_ARGS=()
    if [ "$HEADLESS" -eq 1 ]; then
        EMU_EXTRA_ARGS+=(-no-window -no-audio)
    fi
    QT_QPA_PLATFORM=xcb nohup "$EMULATOR_BIN" -avd "$AVD_NAME" \
        -no-boot-anim -no-snapshot -memory 2560 \
        -gpu "${EMU_GPU:-swiftshader_indirect}" \
        "${EMU_EXTRA_ARGS[@]}" \
        >/tmp/foodgo_emulator.log 2>&1 </dev/null &
    EMULATOR_PID=$!

    adb -e wait-for-device
    for _ in $(seq 1 90); do
        DEVICE_ID="$(adb devices | awk 'NR>1 && $2=="device" && $1 ~ /^emulator-/ {print $1; exit}')"
        if [ -n "$DEVICE_ID" ] && [ "$(adb -s "$DEVICE_ID" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
            break
        fi
        sleep 2
    done
    DEVICE_ID="$(adb devices | awk 'NR>1 && $2=="device" && $1 ~ /^emulator-/ {print $1; exit}')"
fi

if [ -z "$DEVICE_ID" ]; then
    echo "[ERROR] No booted Android emulator found."
    exit 1
fi

echo "[ADB] Targeting $DEVICE_ID (reverse tcp:8000 -> host:8000)"
adb -s "$DEVICE_ID" reverse tcp:8000 tcp:8000 || true

cd "$PROJECT_ROOT/foodgo_flutter"

if [ "$MODE" = "test" ]; then
    echo "[TEST] Running integration test on $DEVICE_ID against $API_URL"
    flutter test --no-pub -d "$DEVICE_ID" integration_test/app_emulator_e2e_test.dart \
        --dart-define="FOODGO_API_URL=$API_URL" \
        --dart-define="FOODGO_WS_URL=$WS_URL" \
        --dart-define="FOODGO_PAYMENT_WS_URL=$PAYMENT_WS_URL"
else
    echo "[RUN] Launching FoodGo on $DEVICE_ID against $API_URL"
    flutter run --no-pub -d "$DEVICE_ID" \
        --dart-define="FOODGO_API_URL=$API_URL" \
        --dart-define="FOODGO_WS_URL=$WS_URL" \
        --dart-define="FOODGO_PAYMENT_WS_URL=$PAYMENT_WS_URL"
fi
