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

[[ -d "$APP" ]] || { print "Compila y firma antes: zsh release.sh" >&2; exit 1 }

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
print "Enviando .app a notarización…"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

xcrun stapler staple "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

rm -f "$DMG"
hdiutil create -volname "EFBY Monitor Shot" -srcfolder "$APP" -ov -format UDZO "$DMG" >/dev/null
print "Enviando DMG a notarización…"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

rm -f "$ZIP_RELEASE"
ditto -c -k --keepParent "$APP" "$ZIP_RELEASE"

print "Listo:"
print "  $APP"
print "  $DMG"
print "  $ZIP_RELEASE"
