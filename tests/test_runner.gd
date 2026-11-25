extends Node
## Dependency-free test runner. Runs every tests/unit/test_*.gd suite.
##
##   godot --headless --path ludo-social res://tests/test_runner.tscn
##
## Exits with code 0 when every test passes, 1 otherwise.

const TEST_DIR := "res://tests/unit"


func _ready() -> void:
	# Let autoloads finish their _ready first.
	await get_tree().process_frame
	var exit_code: int = await _run_all()
	get_tree().quit(exit_code)


func _run_all() -> int:
	var passed := 0
	var failed := 0
	for path in _test_files():
		print("\n== %s" % path.get_file())
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			print("  FAIL  could not load suite")
			failed += 1
			continue
		var suite: Object = script.new()
		suite.set("tree", get_tree())
		for method in suite.get_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			suite.call("begin")
			await suite.call(method_name)
			var errors: Array = suite.call("end")
			if errors.is_empty():
				passed += 1
				print("  PASS  %s" % method_name)
			else:
				failed += 1
				print("  FAIL  %s" % method_name)
				for error in errors:
					print("        - %s" % error)
	print("\n%d passed, %d failed" % [passed, failed])
	return 0 if failed == 0 and passed > 0 else 1


func _test_files() -> PackedStringArray:
	var files := PackedStringArray()
	for file in DirAccess.get_files_at(TEST_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(TEST_DIR.path_join(file))
	files.sort()
	return files
