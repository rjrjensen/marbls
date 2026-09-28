#!/usr/bin/env bash
# Lints every GDScript file with gdlint (config: gdlintrc). Godot's own
# parser (typed-code-only warnings as errors) runs as part of scripts/test.sh.
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v gdlint >/dev/null 2>&1; then
	pip install --quiet "gdtoolkit==4.5.0"
fi
git ls-files -z --cached --others --exclude-standard '*.gd' | xargs -0 gdlint
