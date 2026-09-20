#!/bin/bash
set -e

FLUTTER_VERSION="3.24.5"
FLUTTER_DIR="$PWD/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Installing Flutter $FLUTTER_VERSION..."
  git clone https://github.com/flutter/flutter.git \
    -b "$FLUTTER_VERSION" --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
export PUB_CACHE="$PWD/.pub-cache"

git config --global --add safe.directory "$FLUTTER_DIR"

echo "Flutter version:"
flutter --version

echo "Enabling web..."
flutter config --enable-web

echo "Cleaning..."
flutter clean

echo "Getting packages..."
flutter pub get

echo "Building web..."
flutter build web --release
