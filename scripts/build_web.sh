#!/usr/bin/env bash
# Exports the web build to build/web, ready for Cloudflare Pages.
#
# Cloudflare Pages serves files up to 25 MiB, and Godot's engine (.wasm) is
# about 40 MB, so it's split into parts that a small script in the page
# (export_presets.cfg -> html/head_include) joins back together.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
PART_SIZE="${PART_SIZE:-20m}"

python3 scripts/fetch_export_templates.py >/dev/null
rm -rf build/web
mkdir -p build/web
"$GODOT" --headless --import >/dev/null 2>&1 || true
"$GODOT" --headless --export-release "Web" build/web/index.html

cd build/web
split -b "$PART_SIZE" -d -a 1 index.wasm index.wasm.part
rm index.wasm
parts=$(ls index.wasm.part* | wc -l)
sed -i.bak "s/__MARBLS_WASM_PARTS__/${parts}/" index.html && rm index.html.bak
grep -q "Number(\"${parts}\")" index.html || { echo "wasm loader not found in index.html"; exit 1; }

# Nothing may exceed Cloudflare's per-file limit.
too_big=$(find . -type f -size +25M)
if [ -n "$too_big" ]; then
	echo "Files over 25 MiB: $too_big"
	exit 1
fi
ls -la
