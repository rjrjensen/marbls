extends Node
## Headless test runner: finds every tests/**/test_*.gd, runs each test_*
## method on a fresh instance, and exits non-zero on any failure.
##
## Runs as a scene (tests/test_runner.tscn) rather than a bare script so that
## autoloads such as SignalBus exist, exactly like in the game.
## Run with scripts/test.sh (it also fails the run on any script error).
## Optional filter: godot --headless res://tests/test_runner.tscn -- <substring>

const TEST_ROOT := "res://tests"


func _ready() -> void:
	# Deferred so tests can add nodes to the (no longer busy) scene tree.
	_run_all.call_deferred()


func _run_all() -> void:
	var filter: String = ""
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		filter = args[0]

	var passed: int = 0
	var failed: int = 0
	for path: String in _find_test_files(TEST_ROOT):
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			print("FAIL %s: could not load script" % path)
			failed += 1
			continue
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var full_name: String = "%s::%s" % [path.get_file().get_basename(), method_name]
			if filter != "" and not full_name.contains(filter):
				continue
			var test_case := script.new() as TestCase
			test_case.call(method_name)
			if test_case.failures.is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL %s" % full_name)
				for failure: String in test_case.failures:
					print("    " + failure)

	print("\n%d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 or passed == 0 else 0)


func _find_test_files(dir_path: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub: String in dir.get_directories():
		found.append_array(_find_test_files(dir_path.path_join(sub)))
	for file: String in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_runner.gd" and file != "test_case.gd":
			found.append(dir_path.path_join(file))
	found.sort()
	return found
