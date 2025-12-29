#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/DoodleGuess.xcodeproj"
SCHEME="DoodleGuess"
BUNDLE_ID="com.matthewlam.doodleguess"
LOG_DIR="$ROOT_DIR/logs"

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") start   # build, install, launch, start logs on booted sims
  $(basename "$0") stop    # stop log capture started by this script
USAGE
}

booted_sims() {
  python3 - <<'PY'
import json, subprocess
out = subprocess.check_output(["xcrun", "simctl", "list", "devices", "booted", "-j"]) 
info = json.loads(out)
for _, devices in info.get("devices", {}).items():
    for device in devices:
        if device.get("state") == "Booted":
            print(device.get("udid"))
PY
}

build_app() {
  local udid="$1"
  if [[ -x "$ROOT_DIR/scripts/generate_xcodeproj.sh" ]]; then
    "$ROOT_DIR/scripts/generate_xcodeproj.sh" >/dev/null
  fi
  xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -destination "platform=iOS Simulator,id=$udid" build >/dev/null
}

app_path() {
  local udid="$1"
  xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -destination "platform=iOS Simulator,id=$udid" -showBuildSettings | \
    awk -F ' = ' '/TARGET_BUILD_DIR/ {dir=$2} /FULL_PRODUCT_NAME/ {name=$2} END {print dir"/"name}'
}

start_logs() {
  local udid="$1"
  mkdir -p "$LOG_DIR"
  local log_file="$LOG_DIR/${udid}.log"
  local pid_file="$LOG_DIR/${udid}.pid"

  xcrun simctl spawn "$udid" log stream --style syslog --predicate 'process == "DoodleGuess"' >"$log_file" 2>&1 &
  echo $! >"$pid_file"
}

stop_logs() {
  if [[ ! -d "$LOG_DIR" ]]; then
    echo "No logs directory found."
    return 0
  fi

  local stopped=0
  for pid_file in "$LOG_DIR"/*.pid; do
    [[ -f "$pid_file" ]] || continue
    local pid
    pid=$(cat "$pid_file")
    if kill "$pid" >/dev/null 2>&1; then
      stopped=1
    fi
    rm -f "$pid_file"
  done

  if [[ $stopped -eq 1 ]]; then
    echo "Log capture stopped. Logs are in $LOG_DIR"
  else
    echo "No running log capture found."
  fi
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    start)
      mapfile -t sims < <(booted_sims)
      if [[ ${#sims[@]} -eq 0 ]]; then
        echo "No booted simulators found. Boot at least one simulator first."
        exit 1
      fi

      build_app "${sims[0]}"
      local path
      path=$(app_path "${sims[0]}")

      for udid in "${sims[@]}"; do
        xcrun simctl install "$udid" "$path" >/dev/null
        xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null
        start_logs "$udid"
      done

      echo "Launched on ${#sims[@]} simulator(s). Logs in $LOG_DIR"
      ;;
    stop)
      stop_logs
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
