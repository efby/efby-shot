#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
mkdir -p "$PROJECT_DIR/.build/ModuleCache"
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/ModuleCache"

# Both generated assets are versioned. A fresh checkout gives them similar
# timestamps, so comparing mtimes would needlessly regenerate the icon during
# every CI release (and can fail on some iconutil versions).
if [[ "${1:-}" != "--force" && -f "$PROJECT_DIR/Resources/AppIcon.png" \
   && -f "$PROJECT_DIR/Resources/AppIcon.icns" ]]; then
  exit 0
fi

swift -module-cache-path "$CLANG_MODULE_CACHE_PATH" \
  "$PROJECT_DIR/Tools/generate_app_icon.swift" \
  "$PROJECT_DIR/Resources/Brand/EfbyLogo.ai" \
  "$PROJECT_DIR/Resources/AppIcon.png"

STAGING="$(mktemp -d "$PROJECT_DIR/.build/icon.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ICONSET="$STAGING/AppIcon.iconset"
mkdir -p "$ICONSET"
for SIZE in 16 32 128 256 512; do
  sips -z "$SIZE" "$SIZE" "$PROJECT_DIR/Resources/AppIcon.png" \
    --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
  DOUBLE_SIZE=$((SIZE * 2))
  sips -z "$DOUBLE_SIZE" "$DOUBLE_SIZE" "$PROJECT_DIR/Resources/AppIcon.png" \
    --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$PROJECT_DIR/Resources/AppIcon.icns"
