#!/usr/bin/env bash
# Plays AI-vs-AI games headless and prints win rates per personality.
#   scripts/simulate.sh [games=40] [players=4]
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --import >/dev/null 2>&1 || true
"$GODOT" --headless res://tools/simulate.tscn -- "${1:-40}" "${2:-4}" 2>&1 | grep -v "^Godot Engine"
