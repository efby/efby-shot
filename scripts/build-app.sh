#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
OUTPUT_DIR="$PROJECT_DIR/dist"
APP_DIR="$OUTPUT_DIR/MonitorShot.app"
mkdir -p "$PROJECT_DIR/.build/ModuleCache" "$OUTPUT_DIR"
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/ModuleCache"

zsh "$PROJECT_DIR/scripts/generate-icon.sh"

STAGING="$(mktemp -d "$PROJECT_DIR/.build/package.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
BUNDLE="$STAGING/MonitorShot.app"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

swiftc -swift-version 6 -O -target arm64-apple-macos26.0 \
  -module-cache-path "$CLANG_MODULE_CACHE_PATH" \
  -framework AppKit -framework SwiftUI -framework ScreenCaptureKit \
  -framework ServiceManagement -framework Carbon \
  "$PROJECT_DIR"/Domain/*.swift \
  "$PROJECT_DIR"/Application/*.swift \
  "$PROJECT_DIR"/Infrastructure/*.swift \
  "$PROJECT_DIR"/Presentation/*.swift \
  "$PROJECT_DIR"/App/*.swift \
  -o "$BUNDLE/Contents/MacOS/MonitorShot"

cp "$PROJECT_DIR/Resources/Info.plist" "$BUNDLE/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"
codesign --force --sign - --identifier local.monitorshot.app "$BUNDLE"
codesign --verify --deep --strict "$BUNDLE"

if [[ -e "$APP_DIR" ]]; then mv "$APP_DIR" "$STAGING/previous.app"; fi
mv "$BUNDLE" "$APP_DIR"
print "$APP_DIR"
