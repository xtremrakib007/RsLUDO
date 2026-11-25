extends BaseScreen
## Game board screen. Phase 1 shows the board with every pawn in its base and a
## working pause menu. Dice, turns and moves are added in Phase 2.

var board: BoardView
var _config: MatchConfig
var _pause_layer: Control
var _pause_panel: Control


func build() -> void:
	_config = AppState.match_config
	if _config == null:
		_config = MatchConfig.create(ClassicMode.ID, 4)
		AppState.match_config = _config
	var mode := ModeRegistry.get_mode(_config.mode_id)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	var pause := IconButton.new(IconButton.Icon.PAUSE)
	pause.pressed.connect(_toggle_pause)
	header.add_child(pause)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(UIKit.title(mode.title, 38))
	titles.add_child(UIKit.label("%d players - pass and play" % _config.player_count(), 22, Palette.TEXT_MUTED))
	header.add_child(titles)
	content.add_child(header)

	# Player panels sit next to their own base corner.
	content.add_child(_corner_row(0, 1))
	board = BoardView.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(0, 480)
	board.setup(_config.seats())
	content.add_child(board)
	content.add_child(_corner_row(3, 2))

	var status := UIKit.card(Palette.PANEL, 24, 18)
	status.add_child(UIKit.label("Board preview: dice, turns and pawn moves are added in Phase 2.", 24, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
	content.add_child(status)

	_build_pause_menu()


func _corner_row(left_seat: int, right_seat: int) -> Control:
	var row := HBoxContainer.new()
	row.add_child(_player_panel(left_seat))
	row.add_child(UIKit.spacer(false))
	row.add_child(_player_panel(right_seat))
	return row


func _player_panel(seat: int) -> Control:
	var player := _config.player_at_seat(seat)
	if player == null:
		var empty := Control.new()
		empty.custom_minimum_size = Vector2(0, 76)
		return empty
	var panel := UIKit.card(Palette.PANEL, 22, 12)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(UIKit.color_dot(player.color(), 40))
	var name_label := UIKit.title(player.display_name, 26)
	name_label.custom_minimum_size = Vector2(190, 0)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_label)
	panel.add_child(row)
	return panel


func _build_pause_menu() -> void:
	_pause_layer = Control.new()
	_pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.visible = false
	add_child(_pause_layer)

	var dim := ColorRect.new()
	dim.color = Palette.OVERLAY
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_layer.add_child(dim)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(centre)
	var panel := UIKit.card(Palette.BG_TOP, 32, 32)
	panel.custom_minimum_size = Vector2(540, 0)
	centre.add_child(panel)
	_pause_panel = panel

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	box.add_child(UIKit.title("Paused", 54, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var resume := UIKit.button("Resume")
	resume.pressed.connect(_toggle_pause)
	box.add_child(resume)
	var restart := UIKit.button("Restart Match", UIKit.ButtonKind.SECONDARY)
	restart.pressed.connect(SceneRouter.goto.bind("game"))
	box.add_child(restart)
	var quit := UIKit.button("Quit to Home", UIKit.ButtonKind.GHOST)
	quit.pressed.connect(SceneRouter.goto.bind("home"))
	box.add_child(quit)


func is_paused() -> bool:
	return _pause_layer.visible


func _toggle_pause() -> void:
	_pause_layer.visible = not _pause_layer.visible
	if _pause_layer.visible:
		_pause_panel.pivot_offset = _pause_panel.size * 0.5
		_pause_panel.scale = Vector2(0.9, 0.9)
		var tween := create_tween()
		tween.tween_property(_pause_panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func handle_back() -> void:
	_toggle_pause()
