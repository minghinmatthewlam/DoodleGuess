#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/tools/xcodegen"
ZIP_PATH="$TOOLS_DIR/xcodegen.zip"

mkdir -p "$TOOLS_DIR"

curl -L -o "$ZIP_PATH" https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip
unzip -o "$ZIP_PATH" -d "$TOOLS_DIR"

if [[ ! -x "$TOOLS_DIR/xcodegen/bin/xcodegen" ]]; then
  echo "xcodegen binary not found after unzip." >&2
  exit 1
fi

"$TOOLS_DIR/xcodegen/bin/xcodegen" --version
