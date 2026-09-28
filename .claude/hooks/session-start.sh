#!/bin/bash
# Claude Code on the web: make sure Godot is installed so tests can run.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	exit 0
fi

cd "$CLAUDE_PROJECT_DIR"
GODOT_BIN="$(scripts/install_godot.sh)"
ln -sf "$GODOT_BIN" /usr/local/bin/godot 2>/dev/null || true
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
	echo "export GODOT=\"$GODOT_BIN\"" >> "$CLAUDE_ENV_FILE"
fi

# gdlint for scripts/lint.sh.
pip install --quiet "gdtoolkit==4.5.0" 2>/dev/null || true

# Register class_name types so the first test run is quick.
"$GODOT_BIN" --headless --import >/dev/null 2>&1 || true
