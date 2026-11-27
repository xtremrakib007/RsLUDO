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
		AppState.match_config = MatchConfig.create(ClassicMode.ID, count)
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
	await _wait_seconds(3.2)
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
	await _wait_seconds(2.0)
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


func _open_snl(count: int, board_id: String) -> Node:
	AppState.match_config = MatchConfig.create(SnakesLaddersMode.ID, count)
	AppState.match_config.board_id = board_id
	var scene: PackedScene = load(SceneRouterScript.SCREENS["snl_game"])
	var screen := scene.instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	return screen


func test_snakes_and_ladders_screen_plays_a_ladder() -> void:
	var screen: Node = await _open_snl(2, "easy")
	var snl_match: SnlMatch = screen.get("snl_match")
	var board: SnlBoardView = screen.get("board")
	assert_eq(snl_match.board.id, "easy", "chosen board is used")
	assert_eq(board.pawn_count(), 2, "one pawn per player")
	snl_match.dice.queue_rolls([3] as Array[int])
	screen.call("_on_dice_pressed")
	await _wait_seconds(4.2)
	assert_eq(snl_match.state.position_of(0), 22, "rolled 3 onto the ladder 3 -> 22")
	assert_eq(snl_match.state.current_seat(), 2, "turn passed")
	var pawn_position := board.pawn_node(0).position
	assert_true(pawn_position.distance_to(board.square_center(22)) < board.cell_size(), "pawn drawn on 22")
	screen.queue_free()
	await tree.process_frame


func test_snakes_and_ladders_win_opens_results() -> void:
	var screen: Node = await _open_snl(4, "classic")
	var snl_match: SnlMatch = screen.get("snl_match")
	snl_match.state.set_position(0, 97)
	(screen.get("board") as SnlBoardView).sync(snl_match.state)
	snl_match.dice.queue_rolls([3] as Array[int])
	SceneRouter.last_requested = ""
	screen.call("_on_dice_pressed")
	await _wait_seconds(5.0)
	assert_eq(snl_match.state.phase, SnlState.Phase.GAME_OVER)
	assert_eq(AppState.last_ranking[0], 0, "red wins")
	assert_eq(SceneRouter.last_requested, "result")
	screen.queue_free()
	await tree.process_frame


func test_board_chooser_flips_and_selects() -> void:
	AppState.match_config = MatchConfig.create(SnakesLaddersMode.ID, 2)
	var scene: PackedScene = load(SceneRouterScript.SCREENS["board_select"])
	var screen := scene.instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	var first: SnlBoard = screen.call("current_board")
	screen.call("_step", 1)
	var second: SnlBoard = screen.call("current_board")
	assert_true(first.id != second.id, "right arrow shows the next board")
	screen.call("_step", -2)
	var last: SnlBoard = screen.call("current_board")
	assert_eq(last.id, SnlBoards.all()[4].id, "left from the first board wraps to the last")
	SceneRouter.last_requested = ""
	screen.call("_select")
	assert_eq(AppState.match_config.board_id, last.id, "selected board saved")
	assert_eq(SceneRouter.last_requested, "lobby")
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
