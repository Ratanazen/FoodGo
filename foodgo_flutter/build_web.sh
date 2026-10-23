#!/usr/bin/env bash
# FoodGo Flutter Web Build Script for Vercel and CI
set -e

echo "==> Verifying web assets..."
if [ -d "build/web" ] && [ -f "build/web/index.html" ]; then
  echo "==> Prebuilt Flutter Web bundle detected at build/web. Ready for deployment."
  exit 0
fi

echo "==> Preparing Flutter SDK..."
if command -v flutter >/dev/null 2>&1; then
  FLUTTER_CMD="flutter"
else
  if [ ! -d "_flutter" ]; then
    echo "==> Cloning stable Flutter SDK..."
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git _flutter
  fi
  FLUTTER_CMD="./_flutter/bin/flutter"
fi

echo "==> Building Flutter Web Release bundle..."
"$FLUTTER_CMD" config --no-analytics
"$FLUTTER_CMD" pub get
"$FLUTTER_CMD" build web --release

echo "==> Flutter Web build completed successfully."
