extends BaseScreen
## Local (pass-and-play) match screen. The LocalMatch decides everything; this
## screen shows the board, plays back the rules' events as animations and
## collects taps (dice and pawns). Offline matches can be paused.

const DICE_ROLL_TIME := 0.6
const AUTO_MOVE_DELAY := 0.3
## Space used by everything except the board (header, player rows, dice panel, gaps, margins).
const NON_BOARD_HEIGHT := 680.0

var board: BoardView
var local_match: LocalMatch
var _config: MatchConfig
var _busy := false
var _dice: DiceFace
var _dice_button: Button
var _dice_pulse: Tween
var _turn_label: Label
var _hint_label: Label
var _panels: Dictionary = {}
var _home_labels: Dictionary = {}
var _banner: PanelContainer
var _banner_label: Label
var _pause_layer: Control
var _pause_panel: Control


func build() -> void:
	_config = AppState.match_config
	if _config == null:
		_config = MatchConfig.create(ClassicMode.ID, 4)
		AppState.match_config = _config
	local_match = LocalMatch.new(_config)
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

	content.add_child(UIKit.spacer())
	content.add_child(_corner_row(0, 1))
	board = BoardView.new()
	board.setup(_config.seats(), local_match.snakes)
	board.pawn_tapped.connect(_on_pawn_tapped)
	content.add_child(board)
	content.add_child(_corner_row(3, 2))
	content.add_child(_dice_panel())
	# Spare height on tall phones goes equally above and below the play area.
	content.add_child(UIKit.spacer())

	_build_banner()
	_build_pause_menu()
	resized.connect(_fit_board)
	_fit_board()
	board.sync(local_match.state)
	_refresh_ui()
	_start_dice_pulse()


# --- Layout -------------------------------------------------------------

func _fit_board() -> void:
	var side := minf(size.x - 72.0, size.y - NON_BOARD_HEIGHT)
	board.custom_minimum_size = Vector2(0, maxf(side, 280.0))


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
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(UIKit.color_dot(player.color(), 40))
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	var name_label := UIKit.title(player.display_name, 26)
	name_label.custom_minimum_size = Vector2(180, 0)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	texts.add_child(name_label)
	var home := UIKit.label("", 20, Palette.TEXT_MUTED)
	texts.add_child(home)
	row.add_child(texts)
	panel.add_child(row)
	_panels[seat] = panel
	_home_labels[seat] = home
	return panel


func _dice_panel() -> Control:
	var panel := UIKit.card(Palette.PANEL, 28, 16)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	_turn_label = UIKit.title("", 34)
	_turn_label.clip_text = true
	_turn_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	texts.add_child(_turn_label)
	_hint_label = UIKit.label("", 24, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	texts.add_child(_hint_label)
	row.add_child(texts)

	_dice_button = Button.new()
	_dice_button.custom_minimum_size = Vector2(124, 124)
	_dice_button.focus_mode = Control.FOCUS_NONE
	UIKit.style_button(_dice_button, Color(0, 0, 0, 0), Palette.TEXT, 0, 24)
	_dice = DiceFace.new()
	_dice.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dice_button.add_child(_dice)
	UIKit.ignore_mouse_recursive(_dice_button)
	UIKit.add_press_feedback(_dice_button)
	_dice_button.pressed.connect(_on_dice_pressed)
	row.add_child(_dice_button)
	panel.add_child(row)
	return panel


# --- Turn flow ----------------------------------------------------------

func _on_dice_pressed() -> void:
	if _busy or is_paused() or local_match.state.phase != MatchState.Phase.AWAITING_ROLL:
		return
	_busy = true
	_stop_dice_pulse()
	var events := local_match.roll()
	await _animate_dice(local_match.state.last_roll)
	await _play_events(events)
	_busy = false
	_after_events()


func _on_pawn_tapped(seat: int, pawn: int) -> void:
	if _busy or is_paused():
		return
	for candidate in local_match.legal_moves():
		if candidate.seat == seat and candidate.pawn == pawn:
			_perform_move(candidate)
			return


func _perform_move(chosen: LudoMove) -> void:
	_busy = true
	board.set_selectable([] as Array[Vector2i])
	var events := local_match.move(chosen)
	await _play_events(events)
	_busy = false
	_after_events()


## Decides what the player does next once all animations have finished.
func _after_events() -> void:
	_refresh_ui()
	var state := local_match.state
	if state.phase == MatchState.Phase.GAME_OVER:
		_finish_match()
		return
	if state.phase == MatchState.Phase.AWAITING_ROLL:
		_start_dice_pulse()
		return
	var moves := local_match.legal_moves()
	if _all_same_move(moves):
		# Only one real choice: move it automatically.
		_busy = true
		await _wait(AUTO_MOVE_DELAY)
		_perform_move(moves[0])
		return
	var ids: Array[Vector2i] = []
	for candidate in moves:
		ids.append(Vector2i(candidate.seat, candidate.pawn))
	board.set_selectable(ids)


## True when every legal move ends the same way (e.g. several pawns in base and a six).
func _all_same_move(moves: Array[LudoMove]) -> bool:
	for candidate in moves:
		if candidate.from != moves[0].from or candidate.to != moves[0].to:
			return false
	return not moves.is_empty()


func _play_events(events: Array[GameEvent]) -> void:
	for event in events:
		var d := event.data
		match event.type:
			GameEvent.Type.PAWN_MOVED:
				await board.animate_move(d["seat"], d["pawn"], d["from"], d["to"])
			GameEvent.Type.PAWN_CAPTURED:
				_show_banner("%s captured %s!" % [_name(d["seat"]), _name(d["victim_seat"])], Palette.seat_color(d["seat"]))
				await board.animate_to_base(d["victim_seat"], d["victim_pawn"])
			GameEvent.Type.SNAKE_BITE:
				_show_banner("Snake bite! %s" % _bite_text(d["penalty"]), Palette.SNAKE_BODY)
				await _wait(0.35)
				await board.animate_move(d["seat"], d["pawn"], d["from"], d["to"])
			GameEvent.Type.PAWN_FINISHED:
				_show_banner("Pawn home!", Palette.seat_color(d["seat"]))
				await _wait(0.4)
			GameEvent.Type.PLAYER_FINISHED:
				_show_banner("%s brought all pawns home!" % _name(d["seat"]), Palette.seat_color(d["seat"]))
				await _wait(0.8)
			GameEvent.Type.EXTRA_TURN:
				_show_banner("Roll again!", Palette.ACCENT)
				await _wait(0.35)
			GameEvent.Type.NO_MOVES:
				_show_banner("No moves", Palette.TEXT_MUTED)
				await _wait(0.7)
			GameEvent.Type.THREE_SIXES:
				_show_banner("Three sixes - turn over", Palette.TEXT_MUTED)
				await _wait(0.9)
			GameEvent.Type.TURN_SKIPPED:
				_show_banner("%s misses a turn" % _name(d["seat"]), Palette.TEXT_MUTED)
				await _wait(0.8)
	board.sync(local_match.state)


func _finish_match() -> void:
	AppState.last_ranking = local_match.ranking()
	await _wait(1.2)
	SceneRouter.goto("result")


# --- Dice ---------------------------------------------------------------

func _animate_dice(value: int) -> void:
	var tween := create_tween()
	tween.tween_method(_spin_dice, 0.0, 1.0, DICE_ROLL_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	_dice.rotation = 0.0
	_dice.value = value
	var pop := create_tween()
	pop.tween_property(_dice, "scale", Vector2(1.15, 1.15), 0.08)
	pop.tween_property(_dice, "scale", Vector2.ONE, 0.12)
	await pop.finished


func _spin_dice(t: float) -> void:
	_dice.rotation = t * TAU * 2.0
	if int(t * 30.0) % 2 == 0:
		_dice.value = randi_range(1, 6)


func _start_dice_pulse() -> void:
	_stop_dice_pulse()
	_dice_pulse = create_tween().set_loops()
	_dice_pulse.tween_property(_dice, "scale", Vector2(1.08, 1.08), 0.45).set_trans(Tween.TRANS_SINE)
	_dice_pulse.tween_property(_dice, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)


func _stop_dice_pulse() -> void:
	if _dice_pulse != null and _dice_pulse.is_valid():
		_dice_pulse.kill()
	_dice.scale = Vector2.ONE


# --- Status -------------------------------------------------------------

func _refresh_ui() -> void:
	var state := local_match.state
	var seat := state.current_seat()
	var player := _config.player_at_seat(seat)
	_turn_label.text = "%s's turn" % player.display_name
	_turn_label.add_theme_color_override("font_color", player.color().lightened(0.25))
	_dice.pip_color = player.color().darkened(0.15)
	_dice.queue_redraw()
	match state.phase:
		MatchState.Phase.AWAITING_ROLL:
			_hint_label.text = "Tap the dice to roll"
		MatchState.Phase.AWAITING_MOVE:
			_hint_label.text = "Tap a glowing pawn to move it %d" % state.last_roll
		_:
			_hint_label.text = "Match over"
	for s in _panels:
		var panel: PanelContainer = _panels[s]
		var color := Palette.seat_color(s)
		if s == seat and state.phase != MatchState.Phase.GAME_OVER:
			panel.add_theme_stylebox_override("panel", UIKit.flat_style(Color(color, 0.28), 22, color, 4, 12))
		else:
			panel.add_theme_stylebox_override("panel", UIKit.flat_style(Palette.PANEL, 22, Palette.PANEL_BORDER, 2, 12))
		(_home_labels[s] as Label).text = "Home %d/4" % state.pawns_finished(s)


func _name(seat: int) -> String:
	var player := _config.player_at_seat(seat)
	return player.display_name if player != null else Palette.seat_name(seat)


func _bite_text(penalty: int) -> String:
	match penalty:
		LudoRulesConfig.SnakePenalty.MOVE_BACK_STEPS:
			return "Back %d squares" % local_match.rules.snake_penalty_steps
		LudoRulesConfig.SnakePenalty.SKIP_NEXT_TURN:
			return "Miss a turn"
	return "Back to base"


func _build_banner() -> void:
	_banner = PanelContainer.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.anchor_left = 0.1
	_banner.anchor_right = 0.9
	_banner.anchor_top = 0.45
	_banner.anchor_bottom = 0.45
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner_label = UIKit.title("", 38, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_child(_banner_label)
	_banner.modulate.a = 0.0
	add_child(_banner)


func _show_banner(text: String, color: Color) -> void:
	_banner_label.text = text
	_banner.add_theme_stylebox_override("panel", UIKit.flat_style(Color(0.04, 0.05, 0.13, 0.92), 26, color, 4, 22))
	_banner.pivot_offset = _banner.size * 0.5
	_banner.scale = Vector2(0.85, 0.85)
	var tween := _banner.create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(_banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.9)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.25)


## Waits using a tween owned by this screen, so nothing resumes after the screen closes.
func _wait(seconds: float) -> void:
	var tween := create_tween()
	tween.tween_interval(seconds)
	await tween.finished


# --- Pause (offline only) -------------------------------------------------

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
	# Pausing freezes animations too; the match continues exactly where it was.
	board.process_mode = Node.PROCESS_MODE_DISABLED if _pause_layer.visible else Node.PROCESS_MODE_INHERIT
	if _pause_layer.visible:
		_pause_panel.pivot_offset = _pause_panel.size * 0.5
		_pause_panel.scale = Vector2(0.9, 0.9)
		var tween := create_tween()
		tween.tween_property(_pause_panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func handle_back() -> void:
	_toggle_pause()
