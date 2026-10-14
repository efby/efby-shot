#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
source "$PROJECT_DIR/scripts/bundle-config.sh"
SIGN_ONLY=0
SKIP_NOTARIZE=0

for arg in "$@"; do
  case "$arg" in
    --sign-only) SIGN_ONLY=1 ;;
    --skip-notarize) SKIP_NOTARIZE=1 ;;
  esac
done

if [[ "$SIGN_ONLY" -eq 0 ]]; then
  export MONITORSHOT_BUILD_OUTPUT_DIR="$PROJECT_DIR/dist"
  zsh "$PROJECT_DIR/scripts/build-app.sh"
fi

zsh "$PROJECT_DIR/scripts/sign-app.sh" "$PROJECT_DIR/dist/$MONITORSHOT_APP_BUNDLE_NAME"

if [[ "$SKIP_NOTARIZE" -eq 1 ]]; then
  print "Firma lista (notarización omitida con --skip-notarize)."
  exit 0
fi

if [[ -z "${MONITORSHOT_NOTARY_PROFILE:-}" ]]; then
  print "Falta MONITORSHOT_NOTARY_PROFILE. Ejemplo de configuración única:" >&2
  print '  xcrun notarytool store-credentials "EFBY-Notary" \' >&2
  print '    --apple-id "tu@correo" --team-id FYU5QTGXLB' >&2
  print '  export MONITORSHOT_NOTARY_PROFILE=EFBY-Notary' >&2
  print '  zsh release.sh' >&2
  exit 1
fi

zsh "$PROJECT_DIR/scripts/notarize-release.sh"
