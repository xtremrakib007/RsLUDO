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
	AppState.pending_mode_id = SnakeMode.ID
	await _shot("player_select", out_dir, func() -> void: pass)
	AppState.match_config = MatchConfig.create(SnakeMode.ID, 4)
	await _shot("lobby", out_dir, func() -> void: pass)
	await _shot("game", out_dir, _setup_midgame, "game_snake_4p")
	AppState.match_config = MatchConfig.create(ClassicMode.ID, 2)
	await _shot("game", out_dir, _setup_choice, "game_classic_2p_choice")
	AppState.last_ranking = [2, 0] as Array[int]
	await _shot("result", out_dir, func() -> void: pass)
	get_tree().quit()


func _shot(screen_id: String, out_dir: String, setup: Callable, file_name: String = "") -> void:
	var packed: PackedScene = load(SceneRouterScript.SCREENS[screen_id])
	var screen := packed.instantiate()
	get_tree().root.add_child(screen)
	await get_tree().process_frame
	_current = screen
	setup.call()
	for i in 40:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var path := out_dir.path_join((file_name if not file_name.is_empty() else screen_id) + ".png")
	image.save_png(path)
	print("saved ", path)
	if OS.get_environment("SCREENSHOT_LOG") == "1":
		# Small JPEG copy in the log, for reviewers who cannot download artifacts.
		var small := image.duplicate() as Image
		small.resize(image.get_width() / 2, image.get_height() / 2, Image.INTERPOLATE_BILINEAR)
		print("SHOT %s %s" % [path.get_file().get_basename(), Marshalls.raw_to_base64(small.save_jpg_to_buffer(0.7))])
	screen.queue_free()
	await get_tree().process_frame


var _current: Node


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


## Two pawns that can move: shows the glowing choice.
func _setup_choice() -> void:
	var m: LocalMatch = _current.get("local_match")
	m.state.set_pawn_progress(0, 0, 5)
	m.state.set_pawn_progress(0, 1, 20)
	m.dice.queue_rolls([3] as Array[int])
	_current.call("_on_dice_pressed")
