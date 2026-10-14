#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h}"
source "$PROJECT_DIR/scripts/bundle-config.sh"
export MONITORSHOT_BUILD_OUTPUT_DIR="$PROJECT_DIR/dist"
zsh "$PROJECT_DIR/scripts/build-app.sh"
APP="$PROJECT_DIR/dist/$MONITORSHOT_APP_BUNDLE_NAME"
codesign --force --sign - --identifier "$MONITORSHOT_BUNDLE_ID" "$APP"
codesign --verify --deep --strict "$APP"
print "Build local (firma ad hoc): $APP"
