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


func _open_game(mode_id: String, count: int) -> Node:
	AppState.match_config = MatchConfig.create(mode_id, count)
	var game_scene: PackedScene = load(SceneRouterScript.SCREENS["game"])
	var screen := game_scene.instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	return screen


func _wait_seconds(seconds: float) -> void:
	await tree.create_timer(seconds).timeout


func test_rolling_a_six_starts_a_pawn_on_screen() -> void:
	var screen: Node = await _open_game(ClassicMode.ID, 4)
	var local_match: LocalMatch = screen.get("local_match")
	local_match.dice.queue_rolls([6] as Array[int])
	screen.call("_on_dice_pressed")
	# Four equal choices (all pawns in base): the screen moves one automatically.
	await _wait_seconds(2.5)
	var started := 0
	for pawn in BoardLayout.PAWNS_PER_PLAYER:
		if local_match.state.pawn_progress(0, pawn) == 0:
			started += 1
	assert_eq(started, 1, "one pawn left base")
	assert_eq(local_match.state.current_seat(), 0, "six gives another roll")
	assert_eq(local_match.state.phase, MatchState.Phase.AWAITING_ROLL)
	var board: BoardView = screen.get("board")
	var expected := board.grid_to_local(BoardLayout.progress_point(0, 0))
	var moved := 0
	for pawn in BoardLayout.PAWNS_PER_PLAYER:
		if board.pawn_node(0, pawn).position.distance_to(expected) < board.cell_size():
			moved += 1
	assert_eq(moved, 1, "the pawn is drawn on the start square")
	screen.queue_free()
	await tree.process_frame


func test_tapping_a_pawn_moves_it() -> void:
	var screen: Node = await _open_game(ClassicMode.ID, 2)
	var local_match: LocalMatch = screen.get("local_match")
	local_match.state.set_pawn_progress(0, 0, 5)
	local_match.state.set_pawn_progress(0, 1, 20)
	local_match.dice.queue_rolls([3] as Array[int])
	screen.call("_on_dice_pressed")
	await _wait_seconds(1.5)
	assert_eq(local_match.state.phase, MatchState.Phase.AWAITING_MOVE, "two different moves: player must choose")
	var board: BoardView = screen.get("board")
	assert_true(board.pawn_node(0, 1).highlighted, "movable pawn glows")
	assert_false(board.pawn_node(0, 2).highlighted, "pawn in base does not glow")
	board.pawn_tapped.emit(0, 1)
	await _wait_seconds(1.5)
	assert_eq(local_match.state.pawn_progress(0, 1), 23, "tapped pawn moved 3")
	assert_eq(local_match.state.pawn_progress(0, 0), 5, "other pawn stayed")
	assert_eq(local_match.state.current_seat(), 2, "turn passed")
	screen.queue_free()
	await tree.process_frame


func test_winning_shows_the_result_screen() -> void:
	var screen: Node = await _open_game(ClassicMode.ID, 2)
	var local_match: LocalMatch = screen.get("local_match")
	for pawn in 3:
		local_match.state.set_pawn_progress(0, pawn, BoardLayout.FINISH_PROGRESS)
	local_match.state.set_pawn_progress(0, 3, 55)
	local_match.dice.queue_rolls([1] as Array[int])
	SceneRouter.last_requested = ""
	screen.call("_on_dice_pressed")
	await _wait_seconds(4.5)
	assert_eq(local_match.state.phase, MatchState.Phase.GAME_OVER)
	assert_eq(AppState.last_ranking, [0, 2] as Array[int], "red first, yellow second")
	assert_eq(SceneRouter.last_requested, "result", "result screen requested")
	screen.queue_free()
	await tree.process_frame


func test_snake_mode_draws_snakes_and_classic_does_not() -> void:
	var snake_screen: Node = await _open_game(SnakeMode.ID, 4)
	var snake_board: BoardView = snake_screen.get("board")
	assert_not_null(snake_board.snakes, "snake board has snakes")
	assert_eq(snake_board.snakes.snake_count(), 4)
	snake_screen.queue_free()
	var classic_screen: Node = await _open_game(ClassicMode.ID, 4)
	var classic_board: BoardView = classic_screen.get("board")
	assert_true(classic_board.snakes == null, "classic board has no snakes")
	classic_screen.queue_free()
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
