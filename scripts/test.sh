#!/usr/bin/env bash
# Runs the headless test suite. Fails on test failures *and* on any script
# error Godot prints (parse errors, runtime errors inside tests).
#
#   scripts/test.sh              # all tests
#   scripts/test.sh move_gen     # only tests whose name contains "move_gen"
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

# Import first so class_name types are registered in .godot/.
import_log=$("$GODOT" --headless --import 2>&1)
if grep -qE "SCRIPT ERROR|Parse Error|ERROR: Failed to load script" <<<"$import_log"; then
	echo "$import_log"
	echo "Script errors during import."
	exit 1
fi

test_log=$("$GODOT" --headless --script res://tests/test_runner.gd -- "$@" 2>&1)
status=$?
echo "$test_log"
if grep -qE "SCRIPT ERROR|Parse Error|ERROR: Failed to load script" <<<"$test_log"; then
	echo "Script errors while running tests."
	exit 1
fi
exit $status
