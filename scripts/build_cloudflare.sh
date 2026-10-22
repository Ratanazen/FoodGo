#!/usr/bin/env bash
set -e

echo "=== Preparing Flutter SDK for Cloudflare Build ==="
if ! command -v flutter &> /dev/null; then
  if [ ! -d "/tmp/flutter" ]; then
    echo "Cloning Flutter stable SDK..."
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /tmp/flutter
  fi
  export PATH="/tmp/flutter/bin:$PATH"
fi

flutter --version

echo "=== Building FoodGo Flutter Web Application ==="
cd foodgo_flutter
flutter config --no-analytics
flutter pub get
flutter build web --release --base-href "/"
echo "=== FoodGo Web Build Complete ==="
