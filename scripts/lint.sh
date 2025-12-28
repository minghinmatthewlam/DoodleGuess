#!/bin/bash
# Fast lint/format check for DoodleGuess
# Usage: ./scripts/lint.sh [--fix]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

FIX_MODE=false
if [[ "${1:-}" == "--fix" ]]; then
    FIX_MODE=true
fi

echo "🔍 Running Swift checks..."
START_TIME=$(date +%s.%N)

# Check if swiftformat is installed
if ! command -v swiftformat &> /dev/null; then
    echo -e "${RED}Error: swiftformat not installed. Run: brew install swiftformat${NC}"
    exit 1
fi

# Run SwiftFormat
if $FIX_MODE; then
    echo "  Formatting Swift files..."
    swiftformat . --quiet
    echo -e "  ${GREEN}✓ Formatted${NC}"
else
    echo "  Checking format..."
    if ! swiftformat . --lint --quiet 2>/dev/null; then
        echo -e "  ${RED}✗ Format issues found. Run: ./scripts/lint.sh --fix${NC}"
        # Show what would change
        swiftformat . --lint 2>&1 | head -20
        exit 1
    fi
    echo -e "  ${GREEN}✓ Format OK${NC}"
fi

END_TIME=$(date +%s.%N)
ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
echo -e "\n${GREEN}✓ All checks passed${NC} (${ELAPSED}s)"
