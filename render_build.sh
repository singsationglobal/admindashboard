#!/bin/bash
set -e

FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

echo "Flutter version:"
flutter --version

echo "Cleaning previous build artifacts..."
flutter clean

echo "Getting packages..."
flutter pub get

echo "Building web app..."
flutter build web --release
