#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCODEGEN="$ROOT_DIR/tools/xcodegen/xcodegen/bin/xcodegen"
GOOGLE_SERVICE_INFO_PLIST="$ROOT_DIR/GoogleService-Info.plist"

if [[ ! -x "$XCODEGEN" ]]; then
  echo "xcodegen not found. Run: ./scripts/bootstrap_xcodegen.sh" >&2
  exit 1
fi

# Ensure GoogleService-Info.plist exists for XcodeGen spec validation.
if [[ ! -f "$GOOGLE_SERVICE_INFO_PLIST" ]]; then
  cat > "$GOOGLE_SERVICE_INFO_PLIST" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>GOOGLE_APP_ID</key>
  <string>1:000000000000:ios:0000000000000000</string>
  <key>GCM_SENDER_ID</key>
  <string>000000000000</string>
  <key>PROJECT_ID</key>
  <string>doodleguess-placeholder</string>
  <key>API_KEY</key>
  <string>placeholder</string>
</dict>
</plist>
EOF
fi

"$XCODEGEN" --spec "$ROOT_DIR/project.yml"
