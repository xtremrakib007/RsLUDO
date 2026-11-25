extends RefCounted
## Base class for test suites. Methods named test_* are run by test_runner.gd.
## Test methods may use `await` (for example `await tree.process_frame`).

var tree: SceneTree
var _errors: Array[String] = []


func begin() -> void:
	_errors.clear()


func end() -> Array[String]:
	return _errors.duplicate()


func fail(message: String) -> void:
	_errors.append(message)


func assert_true(condition: bool, message: String = "expected true") -> void:
	if not condition:
		fail(message)


func assert_false(condition: bool, message: String = "expected false") -> void:
	if condition:
		fail(message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		fail("%s expected <%s> but got <%s>" % [message, str(expected), str(actual)])


func assert_not_null(value: Variant, message: String = "expected a value") -> void:
	if value == null:
		fail(message)


func chebyshev(a: Vector2i, b: Vector2i) -> int:
	var d := (b - a).abs()
	return maxi(d.x, d.y)
