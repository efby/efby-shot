#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
source "$PROJECT_DIR/scripts/bundle-config.sh"
APP="${1:-$PROJECT_DIR/../../outputs/$MONITORSHOT_APP_BUNDLE_NAME}"
ENTITLEMENTS="$PROJECT_DIR/Resources/MonitorShot.entitlements"
SIGN_IDENTITY="${MONITORSHOT_SIGN_IDENTITY:-Developer ID Application: EFBY SERVICIOS INFORMATICOS LIMITADA (FYU5QTGXLB)}"

[[ -d "$APP" ]] || { print "No existe: $APP" >&2; exit 1 }
[[ -f "$ENTITLEMENTS" ]] || { print "Faltan entitlements: $ENTITLEMENTS" >&2; exit 1 }

security find-identity -v -p codesigning | grep -F "$SIGN_IDENTITY" >/dev/null || {
  print "No se encontró la identidad en el llavero: $SIGN_IDENTITY" >&2
  exit 1
}

codesign --force --deep --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$SIGN_IDENTITY" \
  "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"
print "Firmado: $APP"
