class_name TestCase
extends RefCounted
## Base for test suites. Any method named test_* is a test; the runner makes a
## fresh instance per test. Assertions record failures instead of stopping.

var failures: Array[String] = []


func fail(message: String) -> void:
	failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail("expected true. " + message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		fail("expected false. " + message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		fail("expected %s, got %s. %s" % [var_to_str(expected), var_to_str(actual), message])


func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		fail("expected null, got %s. %s" % [value, message])


func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		fail("expected a value, got null. " + message)
