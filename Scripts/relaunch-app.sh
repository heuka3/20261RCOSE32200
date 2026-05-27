#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/Scripts/package-app.sh"
osascript -e 'tell application "Disturb Blocker" to quit' >/dev/null 2>&1 || true
open "$ROOT_DIR/.build/DisturbBlocker.app"
