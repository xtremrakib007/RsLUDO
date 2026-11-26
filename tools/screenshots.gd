extends Node
## Renders key screens to PNG files for visual review (needs a real renderer, not --headless).
##   xvfb-run godot --path . res://tools/screenshots.tscn
## Images are written to the folder in the SCREENSHOT_DIR environment variable (default user://screenshots).

const SceneRouterScript := preload("res://scripts/autoload/scene_router.gd")


func _ready() -> void:
	# Wait until the scene tree has finished starting before adding screens.
	await get_tree().process_frame
	SceneRouter.navigation_enabled = false
	var out_dir := OS.get_environment("SCREENSHOT_DIR")
	if out_dir.is_empty():
		out_dir = OS.get_user_data_dir().path_join("screenshots")
	DirAccess.make_dir_recursive_absolute(out_dir)
	AppState.guest_name = "Guest 0427"

	await _shot("home", out_dir, func() -> void: pass)
	await _shot("settings", out_dir, func() -> void: pass)
	AppState.pending_mode_id = SnakesLaddersMode.ID
	await _shot("player_select", out_dir, func() -> void: pass)
	AppState.match_config = MatchConfig.create(SnakesLaddersMode.ID, 4)
	await _shot("board_select", out_dir, func() -> void: pass)
	AppState.match_config.board_id = "classic"
	await _shot("lobby", out_dir, func() -> void: pass)
	await _shot("snl_game", out_dir, _setup_snl, "snl_game_4p")
	AppState.match_config = MatchConfig.create(ClassicMode.ID, 4)
	await _shot("game", out_dir, _setup_midgame, "game_classic_4p")
	AppState.match_config = MatchConfig.create(ClassicMode.ID, 2)
	await _shot("game", out_dir, _setup_choice, "game_classic_2p_choice")
	AppState.match_config = MatchConfig.create(ClassicMode.ID, 4)
	_capture_style = CaptureAnimator.Style.BLASTER
	await _shot("game", out_dir, _setup_capture, "capture_blaster", 0, 1.25)
	AppState.match_config = MatchConfig.create(ClassicMode.ID, 4)
	_capture_style = CaptureAnimator.Style.HAMMER
	await _shot("game", out_dir, _setup_capture, "capture_hammer", 0, 1.3)
	AppState.match_config = MatchConfig.create(ClassicMode.ID, 4)
	_capture_style = CaptureAnimator.Style.SWORD
	await _shot("game", out_dir, _setup_capture, "capture_knockout", 0, 2.05)
	AppState.match_config = MatchConfig.create(SnakesLaddersMode.ID, 2)
	AppState.match_config.board_id = "classic"
	await _shot("snl_game", out_dir, _setup_snake_bite, "snake_mouth_open", 0, 0.45)
	await _shot("snl_game", out_dir, _setup_snake_bite, "snake_bulge", 0, 1.25)
	AppState.match_config = MatchConfig.create(ClassicMode.ID, 2)
	AppState.last_ranking = [2, 0] as Array[int]
	await _shot("result", out_dir, func() -> void: pass)
	get_tree().quit()


func _shot(screen_id: String, out_dir: String, setup: Callable, file_name: String = "", frames: int = 40, seconds: float = 0.0) -> void:
	var packed: PackedScene = load(SceneRouterScript.SCREENS[screen_id])
	var screen := packed.instantiate()
	get_tree().root.add_child(screen)
	await get_tree().process_frame
	_current = screen
	setup.call()
	if seconds > 0.0:
		var until := Time.get_ticks_msec() + int(seconds * 1000.0)
		while Time.get_ticks_msec() < until:
			await get_tree().process_frame
	else:
		for i in frames:
			await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var path := out_dir.path_join(OS.get_environment("SCREENSHOT_PREFIX") + (file_name if not file_name.is_empty() else screen_id) + ".png")
	image.save_png(path)
	print("saved ", path)
	screen.queue_free()
	await get_tree().process_frame


var _current: Node
var _capture_style: int = 0


## Pawns spread around the board, two sharing a square, one in a home column.
func _setup_midgame() -> void:
	var m: LocalMatch = _current.get("local_match")
	m.state.set_pawn_progress(0, 0, 4)
	m.state.set_pawn_progress(0, 1, 30)
	m.state.set_pawn_progress(1, 0, 10)
	m.state.set_pawn_progress(1, 1, 10)
	m.state.set_pawn_progress(2, 0, 53)
	m.state.set_pawn_progress(3, 0, 0)
	m.state.set_pawn_progress(3, 1, 22)
	var board: BoardView = _current.get("board")
	board.sync(m.state)


## Snakes & Ladders pawns spread over the board, two sharing a square.
func _setup_snl() -> void:
	var m: SnlMatch = _current.get("snl_match")
	m.state.set_position(0, 23)
	m.state.set_position(1, 23)
	m.state.set_position(2, 58)
	var board: SnlBoardView = _current.get("board")
	board.sync(m.state)
	board.queue_redraw()
	_current.call("_refresh_ui")


## Starts a capture (blaster) so the picture shows the attack in progress.
func _setup_capture() -> void:
	var board: BoardView = _current.get("board")
	var m: LocalMatch = _current.get("local_match")
	m.state.set_pawn_progress(0, 0, 14)
	m.state.set_pawn_progress(1, 0, 1)
	board.sync(m.state)
	CaptureAnimator.play(board, board.pawn_node(0, 0), board.pawn_node(1, 0), _capture_style, board.cell_size(), board.base_position(1, 0))


## Red stands on the head of the snake 54 -> 31 and gets eaten.
func _setup_snake_bite() -> void:
	var m: SnlMatch = _current.get("snl_match")
	var board: SnlBoardView = _current.get("board")
	m.state.set_position(0, 54)
	m.state.set_position(2, 12)
	board.sync(m.state)
	board.animate_slide(0, 54, 31)


## Two pawns that can move: shows the glowing choice.
func _setup_choice() -> void:
	var m: LocalMatch = _current.get("local_match")
	m.state.set_pawn_progress(0, 0, 5)
	m.state.set_pawn_progress(0, 1, 20)
	m.dice.queue_rolls([3] as Array[int])
	_current.call("_on_dice_pressed")
