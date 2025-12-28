#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCODEGEN="$ROOT_DIR/tools/xcodegen/xcodegen/bin/xcodegen"

if [[ ! -x "$XCODEGEN" ]]; then
  echo "xcodegen not found. Run: ./scripts/bootstrap_xcodegen.sh" >&2
  exit 1
fi

"$XCODEGEN" --spec "$ROOT_DIR/project.yml"
