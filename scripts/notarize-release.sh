#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
source "$PROJECT_DIR/scripts/bundle-config.sh"
DIST="$PROJECT_DIR/dist"
APP="$DIST/$MONITORSHOT_APP_BUNDLE_NAME"
ZIP="$DIST/MonitorShot-notarize.zip"
DMG="$DIST/MonitorShot-macOS26.dmg"
ZIP_RELEASE="$DIST/MonitorShot-macOS26.zip"
PROFILE="${MONITORSHOT_NOTARY_PROFILE:?Define MONITORSHOT_NOTARY_PROFILE (perfil de xcrun notarytool store-credentials).}"
NOTARY_OPTIONS=(--keychain-profile "$PROFILE")
if [[ -n "${MONITORSHOT_NOTARY_KEYCHAIN:-}" ]]; then
  NOTARY_OPTIONS+=(--keychain "$MONITORSHOT_NOTARY_KEYCHAIN")
fi

[[ -d "$APP" ]] || { print "Compila y firma antes: zsh release.sh" >&2; exit 1 }
xcrun notarytool history "${NOTARY_OPTIONS[@]}" --output-format json >/dev/null

notarize() {
  local artifact="$1" result="$2"
  xcrun notarytool submit "$artifact" "${NOTARY_OPTIONS[@]}" --wait --timeout 30m --output-format json > "$result"
  python3 - "$result" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as response_file:
    response = json.load(response_file)
if response.get("status") != "Accepted":
    raise SystemExit("Apple no aceptó la notarización. ID: " + response.get("id", "desconocido"))
print("Notarización Accepted: " + response["id"])
PY
}

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
print "Enviando .app a notarización…"
notarize "$ZIP" "$DIST/MonitorShot-app-notary.json"

xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

rm -f "$DMG"
hdiutil create -volname "EFBY Monitor Shot" -srcfolder "$APP" -ov -format UDZO "$DMG" >/dev/null
print "Enviando DMG a notarización…"
notarize "$DMG" "$DIST/MonitorShot-dmg-notary.json"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
hdiutil verify "$DMG"

MOUNT="$(mktemp -d "$DIST/MonitorShot-mount.XXXXXX")"
trap 'hdiutil detach "$MOUNT" >/dev/null 2>&1 || true; rmdir "$MOUNT" 2>/dev/null || true' EXIT
hdiutil attach "$DMG" -readonly -nobrowse -mountpoint "$MOUNT" >/dev/null
codesign --verify --deep --strict "$MOUNT/$MONITORSHOT_APP_BUNDLE_NAME"
xcrun stapler validate "$MOUNT/$MONITORSHOT_APP_BUNDLE_NAME"
spctl --assess --type execute --verbose=2 "$MOUNT/$MONITORSHOT_APP_BUNDLE_NAME"
hdiutil detach "$MOUNT" >/dev/null
rmdir "$MOUNT"
trap - EXIT

rm -f "$ZIP_RELEASE"
ditto -c -k --keepParent "$APP" "$ZIP_RELEASE"
(cd "$DIST" && shasum -a 256 "${DMG:t}" > "${DMG:t}.sha256")

print "Listo:"
print "  $APP"
print "  $DMG"
print "  $ZIP_RELEASE"
