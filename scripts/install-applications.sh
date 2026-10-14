#!/bin/zsh
# Opcional y desaconsejado por defecto: EFBY Monitor Shot debe ejecutarse desde dist/ o la carpeta que elijas.
# Solo copia a /Applications si pasas --confirm explícitamente.
set -euo pipefail
if [[ "${1:-}" != "--confirm" ]]; then
  print "No se copia a /Applications por defecto." >&2
  source "${0:A:h}/bundle-config.sh"
  print "Ejecuta la app desde: $(cd "${0:A:h:h}" && pwd)/dist/$MONITORSHOT_APP_BUNDLE_NAME" >&2
  print "Si realmente quieres copiarla: zsh $0 --confirm" >&2
  exit 1
fi
PROJECT_DIR="${0:A:h:h}"
source "$PROJECT_DIR/scripts/bundle-config.sh"
SRC="$PROJECT_DIR/dist/$MONITORSHOT_APP_BUNDLE_NAME"
DEST="/Applications/$MONITORSHOT_APP_BUNDLE_NAME"
[[ -d "$SRC" ]] || { print "Compila antes: zsh release.sh --skip-notarize" >&2; exit 1 }
ditto "$SRC" "$DEST"
print "Copia en $DEST (la copia de trabajo sigue en $SRC)"
