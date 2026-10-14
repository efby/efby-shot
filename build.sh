#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h}"
source "$PROJECT_DIR/scripts/bundle-config.sh"
export MONITORSHOT_BUILD_OUTPUT_DIR="$PROJECT_DIR/dist"
zsh "$PROJECT_DIR/scripts/build-app.sh"
APP="$PROJECT_DIR/dist/$MONITORSHOT_APP_BUNDLE_NAME"
SIGN_IDENTITY="${MONITORSHOT_SIGN_IDENTITY:-Developer ID Application: EFBY SERVICIOS INFORMATICOS LIMITADA (FYU5QTGXLB)}"
if security find-identity -v -p codesigning | grep -F "$SIGN_IDENTITY" >/dev/null; then
  zsh "$PROJECT_DIR/scripts/sign-app.sh" "$APP"
  print "Build local con identidad EFBY estable: $APP"
else
  codesign --force --sign - --identifier "$MONITORSHOT_BUNDLE_ID" "$APP"
  print -u2 "Aviso: firma ad hoc; macOS puede pedir el permiso de captura otra vez después de recompilar."
fi
codesign --verify --deep --strict "$APP"
print "Build local: $APP"
