#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
source "$PROJECT_DIR/scripts/bundle-config.sh"
OUTPUT_DIR="${MONITORSHOT_BUILD_OUTPUT_DIR:?Define MONITORSHOT_BUILD_OUTPUT_DIR antes de compilar}"
APP_DIR="$OUTPUT_DIR/$MONITORSHOT_APP_BUNDLE_NAME"
mkdir -p "$PROJECT_DIR/.build/ModuleCache" "$OUTPUT_DIR"
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/ModuleCache"

zsh "$PROJECT_DIR/scripts/generate-icon.sh"

STAGING="$(mktemp -d "$PROJECT_DIR/.build/package.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
BUNDLE="$STAGING/$MONITORSHOT_APP_BUNDLE_NAME"
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
  -o "$BUNDLE/Contents/MacOS/$MONITORSHOT_EXECUTABLE_NAME"

cp "$PROJECT_DIR/Resources/Info.plist" "$BUNDLE/Contents/Info.plist"
if [[ -n "${MONITORSHOT_APP_VERSION:-}" ]]; then
  [[ "$MONITORSHOT_APP_VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || { print 'MONITORSHOT_APP_VERSION debe tener formato X.Y.Z' >&2; exit 1; }
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $MONITORSHOT_APP_VERSION" "$BUNDLE/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $MONITORSHOT_APP_VERSION" "$BUNDLE/Contents/Info.plist"
fi
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"

if [[ -e "$APP_DIR" ]]; then mv "$APP_DIR" "$STAGING/previous.app"; fi
mv "$BUNDLE" "$APP_DIR"
print "$APP_DIR"
