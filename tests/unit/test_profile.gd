extends "res://tests/test_case.gd"
## Profile, statistics and game history (stored on the device).

const SceneRouterScript := preload("res://scripts/autoload/scene_router.gd")

var _saved_name: String
var _saved_seat: int
var _saved_history: Array


func _keep() -> void:
	_saved_name = AppState.guest_name
	_saved_seat = AppState.avatar_seat
	_saved_history = AppState.history.duplicate(true)


func _restore() -> void:
	AppState.guest_name = _saved_name
	AppState.history = _saved_history
	AppState.set_profile(_saved_name if not _saved_name.is_empty() else "Guest", _saved_seat)


func test_profile_name_and_colour_are_saved() -> void:
	_keep()
	AppState.set_profile("  Rakib  ", 2)
	assert_eq(AppState.guest_name, "Rakib", "trimmed name")
	assert_eq(AppState.avatar_seat, 2)
	var cfg := ConfigFile.new()
	cfg.load("user://profile.cfg")
	assert_eq(cfg.get_value("profile", "guest_name"), "Rakib", "saved name")
	assert_eq(cfg.get_value("profile", "avatar_seat"), 2, "saved colour")
	AppState.set_profile("", 1)
	assert_eq(AppState.guest_name, "Rakib", "an empty name keeps the old one")
	AppState.set_profile("A very long name indeed", 0)
	assert_eq(AppState.guest_name.length(), 14, "name limited to 14 characters")
	_restore()


func test_finished_matches_are_recorded_and_counted() -> void:
	_keep()
	AppState.history = []
	AppState.set_profile("Rakib", 0)
	var classic := MatchConfig.create(ClassicMode.ID, 2)
	classic.players[0].display_name = "Rakib"
	AppState.record_match(classic, [0, 2] as Array[int])
	var snl := MatchConfig.create(SnakesLaddersMode.ID, 4)
	snl.board_id = "tricky"
	AppState.record_match(snl, [3, 0, 1, 2] as Array[int])
	assert_eq(AppState.matches_played(), 2)
	assert_eq(AppState.matches_played(ClassicMode.ID), 1)
	assert_eq(AppState.matches_played(SnakesLaddersMode.ID), 1)
	assert_eq(AppState.wins(), 1, "one win as Rakib")
	var newest: Dictionary = AppState.history[0]
	assert_eq(newest["mode_id"], SnakesLaddersMode.ID, "newest first")
	assert_eq(newest["board_id"], "tricky")
	assert_eq(newest["winner_name"], "Blue Player")
	for i in 60:
		AppState.record_match(classic, [2, 0] as Array[int])
	assert_eq(AppState.history.size(), 50, "history keeps the last 50 matches")
	_restore()


func test_history_screen_lists_matches() -> void:
	_keep()
	AppState.history = []
	AppState.record_match(MatchConfig.create(ClassicMode.ID, 2), [2, 0] as Array[int])
	AppState.record_match(MatchConfig.create(SnakesLaddersMode.ID, 2), [0, 2] as Array[int])
	var scene: PackedScene = load(SceneRouterScript.SCREENS["history"])
	var screen := scene.instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	assert_eq(screen.call("entry_count"), 2, "two match cards")
	screen.queue_free()
	await tree.process_frame
	_restore()


func test_profile_screen_saves_name_and_colour() -> void:
	_keep()
	var scene: PackedScene = load(SceneRouterScript.SCREENS["profile"])
	var screen := scene.instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	var edit: LineEdit = screen.get("name_edit")
	edit.text = "Tester"
	screen.call("_choose", 3)
	screen.call("save")
	assert_eq(AppState.guest_name, "Tester")
	assert_eq(AppState.avatar_seat, 3)
	screen.queue_free()
	await tree.process_frame
	_restore()
