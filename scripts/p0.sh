#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/DoodleGuess.xcodeproj"

# Fast format check first (fails fast if format issues)
echo "🔍 Checking format..."
if command -v swiftformat &> /dev/null; then
    if ! swiftformat "$ROOT_DIR" --lint --quiet 2>/dev/null; then
        echo "❌ Format issues found. Run: ./scripts/lint.sh --fix"
        exit 1
    fi
    echo "✓ Format OK"
else
    echo "⚠️  swiftformat not installed, skipping format check"
fi
DESTINATION="$(python3 - <<'PY'
import json
import re
import subprocess

data = json.loads(subprocess.check_output([
    "xcrun", "simctl", "list", "devices", "available", "-j"
]).decode("utf-8"))

def os_from_runtime(runtime):
    match = re.search(r"iOS-(\\d+)-(\\d+)", runtime)
    if match:
        return f"{match.group(1)}.{match.group(2)}"
    match = re.search(r"iOS-(\\d+)", runtime)
    if match:
        return match.group(1)
    return "latest"

for runtime, devices in data.get("devices", {}).items():
    for device in devices:
        name = device.get("name", "")
        if "iPhone" in name:
            os_version = os_from_runtime(runtime)
            print(f"platform=iOS Simulator,name={name},OS={os_version}")
            raise SystemExit(0)

for runtime, devices in data.get("devices", {}).items():
    for device in devices:
        name = device.get("name", "")
        if "iPad" in name:
            os_version = os_from_runtime(runtime)
            print(f"platform=iOS Simulator,name={name},OS={os_version}")
            raise SystemExit(0)

print("platform=iOS Simulator,name=Any iOS Simulator Device")
PY
)"

if [[ ! -d "$PROJECT" ]]; then
  echo "Missing DoodleGuess.xcodeproj. Run: ./scripts/generate_xcodeproj.sh" >&2
  exit 1
fi

xcodebuild -project "$PROJECT" -scheme DoodleGuess -destination "$DESTINATION" build
xcodebuild -project "$PROJECT" -scheme DoodleWidget -destination "$DESTINATION" build
xcodebuild -project "$PROJECT" -scheme DoodleGuess -destination "$DESTINATION" test -only-testing:DoodleGuessTests
