#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h}"
exec zsh "$PROJECT_DIR/scripts/build-app.sh"
