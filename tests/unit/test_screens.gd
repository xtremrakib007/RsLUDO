extends "res://tests/test_case.gd"
## Smoke tests: every script compiles and every screen builds without errors.

const SceneRouterScript := preload("res://scripts/autoload/scene_router.gd")


func test_all_scripts_compile() -> void:
	var paths := PackedStringArray()
	_collect_scripts("res://scripts", paths)
	assert_true(paths.size() >= 20, "found %d scripts" % paths.size())
	for path in paths:
		var script: Script = load(path)
		assert_true(script != null and script.can_instantiate(), "%s compiles" % path)


func test_every_screen_builds() -> void:
	AppState.match_config = MatchConfig.create(ClassicMode.ID, 4)
	for screen_id in SceneRouterScript.SCREENS:
		var path: String = SceneRouterScript.SCREENS[screen_id]
		var packed: PackedScene = load(path)
		assert_not_null(packed, "%s loads" % path)
		if packed == null:
			continue
		var screen := packed.instantiate()
		tree.root.add_child(screen)
		await tree.process_frame
		assert_true(screen is BaseScreen, "%s is a BaseScreen" % screen_id)
		assert_true(screen.get_child_count() >= 3, "%s built its layout" % screen_id)
		screen.queue_free()
		await tree.process_frame


func test_game_board_places_pawns_for_each_player() -> void:
	for count in [2, 4]:
		AppState.match_config = MatchConfig.create(SnakeMode.ID, count)
		var game_scene: PackedScene = load(SceneRouterScript.SCREENS["game"])
		var screen := game_scene.instantiate()
		tree.root.add_child(screen)
		await tree.process_frame
		var board: BoardView = screen.get("board")
		assert_not_null(board, "game screen has a board")
		if board != null:
			assert_eq(board.pawn_count(), count * BoardLayout.PAWNS_PER_PLAYER, "%d-player pawn count" % count)
			assert_eq(board.active_seats, MatchConfig.seats_for_count(count), "active seats")
		assert_false(screen.call("is_paused"), "starts unpaused")
		screen.call("handle_back")
		assert_true(screen.call("is_paused"), "back button opens the pause menu")
		screen.call("handle_back")
		assert_false(screen.call("is_paused"), "back again resumes")
		screen.queue_free()
		await tree.process_frame


func test_board_geometry_scales_with_size() -> void:
	var board := BoardView.new()
	board.size = Vector2(600, 900)
	assert_eq(board.cell_size(), 40.0, "cell size uses the shorter side")
	assert_eq(board.board_origin(), Vector2(0, 150), "board is centred vertically")
	assert_eq(board.grid_to_local(Vector2(15, 15)), Vector2(600, 750), "board corner")
	board.free()


func _collect_scripts(dir_path: String, out: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
	for sub in DirAccess.get_directories_at(dir_path):
		_collect_scripts(dir_path.path_join(sub), out)
