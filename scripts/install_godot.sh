#!/usr/bin/env bash
# Installs the pinned Godot editor binary (it also runs headless) if missing,
# and prints its path. Downloads from the official mirror, not GitHub.
#
#   GODOT="$(scripts/install_godot.sh)"
set -euo pipefail
VERSION="${GODOT_VERSION:-4.7.2}"
DEST_DIR="${GODOT_DIR:-$HOME/.local/share/godot}"
BIN="$DEST_DIR/Godot_v${VERSION}-stable_linux.x86_64"

if [ ! -x "$BIN" ]; then
	mkdir -p "$DEST_DIR"
	tmp_zip="$(mktemp --suffix=.zip)"
	curl -fsSL --retry 3 -o "$tmp_zip" \
		"https://downloads.godotengine.org/?version=${VERSION}&flavor=stable&slug=linux.x86_64.zip&platform=linux.64"
	unzip -oq "$tmp_zip" -d "$DEST_DIR"
	rm -f "$tmp_zip"
	chmod +x "$BIN"
fi
echo "$BIN"
