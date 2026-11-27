class_name MatchScreen
extends BaseScreen
## Shared parts of an offline match screen: header, player panels, dice panel,
## message banner and the pause menu. Ludo and Snakes & Ladders extend this and
## add their own board and turn flow. Offline matches can be paused.


var _config: MatchConfig
var _mode: GameMode
var _busy := false
var _dice: Dice3DView
var _dice_button: Button
var _dice_pulse: Tween
## seat -> the spot next to that player's name card where the dice sits.
var _dice_slots: Dictionary = {}
var _dice_seat: int = -1
var _dice_moving := false
var _turn_label: Label
var _hint_label: Label
var _panels: Dictionary = {}
var _status_labels: Dictionary = {}
var _banner: PanelContainer
var _banner_label: Label
var _pause_layer: Control
var _pause_panel: Control


## Loads the match settings (or a default) and adds the header. Call first in build().
func _setup_match(default_mode_id: String) -> void:
	_config = AppState.match_config
	if _config == null or ModeRegistry.get_mode(_config.mode_id) == null:
		_config = MatchConfig.create(default_mode_id, 4)
		AppState.match_config = _config
	_mode = ModeRegistry.get_mode(_config.mode_id)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	var pause := IconButton.new(IconButton.Icon.PAUSE)
	pause.pressed.connect(_toggle_pause)
	header.add_child(pause)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(UIKit.title(_mode.title, 38))
	titles.add_child(UIKit.label(_subtitle(), 22, Palette.TEXT_MUTED))
	header.add_child(titles)
	content.add_child(header)


## Adds the overlay layers. Call last in build().
func _finish_setup() -> void:
	# The dice floats above the layout so it can fly between players.
	add_child(_dice_button)
	_build_banner()
	_build_pause_menu()


func _subtitle() -> String:
	var bots := _config.bot_count()
	if bots == 0:
		return "%d players - pass and play" % _config.player_count()
	return "%d players - %d %s" % [_config.player_count(), bots, "bot" if bots == 1 else "bots"]


# --- Player panels ------------------------------------------------------

func _corner_row(left_seat: int, right_seat: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_player_panel(left_seat))
	row.add_child(_dice_slot(left_seat))
	row.add_child(UIKit.spacer(false))
	row.add_child(_dice_slot(right_seat))
	row.add_child(_player_panel(right_seat))
	return row


## Empty space beside a player's card where the dice goes on their turn.
func _dice_slot(seat: int) -> Control:
	var slot := Control.new()
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _config.player_at_seat(seat) == null:
		return slot
	slot.custom_minimum_size = Vector2(96, 96)
	slot.item_rect_changed.connect(_snap_dice)
	_dice_slots[seat] = slot
	return slot


func _player_panel(seat: int) -> Control:
	var player := _config.player_at_seat(seat)
	if player == null:
		var empty := Control.new()
		empty.custom_minimum_size = Vector2(0, 76)
		return empty
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(UIKit.color_dot(player.color(), 32))
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	var name_label := UIKit.title(player.display_name, 24)
	name_label.custom_minimum_size = Vector2(128, 0)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	texts.add_child(name_label)
	var status := UIKit.label("", 20, Palette.TEXT_MUTED)
	texts.add_child(status)
	row.add_child(texts)
	panel.add_child(row)
	_panels[seat] = panel
	_status_labels[seat] = status
	return panel


## Highlights the current player and updates each panel's status line.
func _refresh_panels(current_seat: int, game_over: bool) -> void:
	var player := _config.player_at_seat(current_seat)
	_turn_label.text = "%s's turn" % player.display_name
	_turn_label.add_theme_color_override("font_color", player.color().lightened(0.25))
	_dice.body_color = player.color()
	_dice.pip_color = Color.WHITE
	if current_seat != _dice_seat:
		_move_dice_to(current_seat)
	for seat in _panels:
		var panel: PanelContainer = _panels[seat]
		var color := Palette.seat_color(seat)
		if seat == current_seat and not game_over:
			panel.add_theme_stylebox_override("panel", UIKit.flat_style(Color(color, 0.28), 22, color, 4, 12))
		else:
			panel.add_theme_stylebox_override("panel", UIKit.flat_style(Palette.PANEL, 22, Palette.PANEL_BORDER, 2, 12))
		(_status_labels[seat] as Label).text = _panel_status(seat)


## Second line of a player panel. Override per game.
func _panel_status(_seat: int) -> String:
	return ""


func _name(seat: int) -> String:
	var player := _config.player_at_seat(seat)
	return player.display_name if player != null else Palette.seat_name(seat)


# --- Dice ---------------------------------------------------------------

## Creates the dice. Whose turn it is shows on the player cards and by where the
## dice sits, so the old turn/hint card is kept hidden.
func _dice_panel() -> Control:
	var panel := UIKit.card(Palette.PANEL, 28, 16)
	panel.visible = false
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
	_dice_button.size = Vector2(96, 96)
	_dice_button.focus_mode = Control.FOCUS_NONE
	UIKit.style_button(_dice_button, Color(0, 0, 0, 0), Palette.TEXT, 0, 24)
	_dice = Dice3DView.new()
	# Larger than its button so the dice can jump without being cut off.
	_dice.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dice.offset_left = -70
	_dice.offset_right = 70
	_dice.offset_top = -100
	_dice.offset_bottom = 40
	_dice.impact.connect(func(strength: float) -> void: Sfx.play("dice_land", -6.0 - (1.0 - strength) * 8.0, 0.05))
	_dice_button.add_child(_dice)
	UIKit.ignore_mouse_recursive(_dice_button)
	UIKit.add_press_feedback(_dice_button)
	_dice_button.pressed.connect(_on_dice_pressed)
	panel.add_child(row)
	return panel


## Flies the dice to the spot beside this player's card, tumbling on the way.
func _move_dice_to(seat: int) -> void:
	var slot: Control = _dice_slots.get(seat)
	if slot == null:
		return
	var first := _dice_seat == -1
	_dice_seat = seat
	if first or not is_inside_tree():
		_snap_dice()
		return
	_dice_moving = true
	Sfx.play("dice_move", -6.0)
	var target := slot.global_position - global_position
	var tween := create_tween().set_parallel()
	tween.tween_property(_dice_button, "position", target, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_dice_button, "size", slot.size, 0.4)
	tween.tween_property(_dice_button, "rotation", TAU, 0.4).from(0.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	_dice_button.rotation = 0.0
	_dice_moving = false
	_snap_dice()


func _process(_delta: float) -> void:
	_snap_dice()


## Keeps the dice exactly on its slot (after layout changes).
func _snap_dice() -> void:
	if _dice_moving or _dice_button == null:
		return
	var slot: Control = _dice_slots.get(_dice_seat)
	if slot == null:
		return
	var target := slot.global_position - global_position
	if _dice_button.position != target or _dice_button.size != slot.size:
		_dice_button.position = target
		_dice_button.size = slot.size
		_dice_button.pivot_offset = slot.size * 0.5


## Override: what happens when the dice is tapped.
func _on_dice_pressed() -> void:
	pass


# --- Bots ---------------------------------------------------------------

var _bot_rng := RandomNumberGenerator.new()


func _is_bot(seat: int) -> bool:
	return _config.is_bot(seat)


## Waits like a person would: a varied pause, longer when `hard_choice`.
## Never continues while the game is paused.
func _bot_pause(hard_choice: bool = false) -> void:
	var seconds := _bot_rng.randf_range(0.55, 1.1)
	if hard_choice:
		seconds += _bot_rng.randf_range(0.3, 0.8)
	await _wait(seconds)
	while is_paused():
		await _wait(0.2)


## The bot "taps" the dice: the same press bounce a finger gives.
func _bot_tap_dice() -> void:
	_stop_dice_pulse()
	var tap := create_tween()
	tap.tween_property(_dice_button, "scale", Vector2(0.88, 0.88), 0.08)
	tap.tween_property(_dice_button, "scale", Vector2.ONE, 0.1)
	await tap.finished


func _animate_dice(value: int) -> void:
	Sfx.play("dice", -6.0, 0.04)
	await _dice.roll_to(value)
	_show_rolled_number(value)


func _start_dice_pulse() -> void:
	_dice.set_waiting(true)


func _stop_dice_pulse() -> void:
	_dice.set_waiting(false)


## The rolled number pops up over the dice and floats away; a six gets a golden burst.
func _show_rolled_number(value: int) -> void:
	var centre := _dice_button.position + _dice_button.size * 0.5
	var number := UIKit.title(str(value), 64, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	number.add_theme_color_override("font_outline_color", Palette.seat_color(_dice_seat) if _dice_seat >= 0 else Palette.TEXT_DARK)
	number.add_theme_constant_override("outline_size", 14)
	number.size = Vector2(120, 80)
	number.position = centre - Vector2(60, 110)
	number.pivot_offset = number.size * 0.5
	number.scale = Vector2(0.3, 0.3)
	number.z_index = 30
	add_child(number)
	var t := create_tween()
	t.tween_property(number, "scale", Vector2(1.2, 1.2), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(number, "scale", Vector2.ONE, 0.08)
	t.tween_interval(0.25)
	t.tween_property(number, "position:y", number.position.y - 60.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(number, "modulate:a", 0.0, 0.4)
	t.tween_callback(number.queue_free)
	if value == 6:
		Sfx.play("extra", -8.0)
		var burst := CaptureEffect.create(CaptureEffect.Kind.CONFETTI, centre, centre + Vector2(0, -30), Color.WHITE, 60.0)
		var ring := CaptureEffect.create(CaptureEffect.Kind.SHOCKWAVE, centre, centre, Palette.ACCENT, 45.0)
		for effect in [burst, ring]:
			add_child(effect)
			var et := create_tween()
			et.tween_property(effect, "progress", 1.0, 0.8)
			et.tween_callback(effect.queue_free)


# --- Messages and timing ------------------------------------------------

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


func _finish_match(ranking: Array[int]) -> void:
	AppState.last_ranking = ranking
	AppState.record_match(_config, ranking)
	await _wait(1.2)
	SceneRouter.goto("result")


# --- Pause (offline only) -------------------------------------------------

## Node whose animations freeze while paused (the board).
func _pausable() -> Node:
	return null


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
	box.add_child(SoundSettingsPanel.new())
	var restart := UIKit.button("Restart Match", UIKit.ButtonKind.SECONDARY)
	restart.pressed.connect(SceneRouter.goto.bind(_mode.game_screen))
	box.add_child(restart)
	var quit := UIKit.button("Quit to Home", UIKit.ButtonKind.GHOST)
	quit.pressed.connect(SceneRouter.goto.bind("home"))
	box.add_child(quit)


func is_paused() -> bool:
	return _pause_layer.visible


func _toggle_pause() -> void:
	_pause_layer.visible = not _pause_layer.visible
	var frozen := _pausable()
	if frozen != null:
		frozen.process_mode = Node.PROCESS_MODE_DISABLED if _pause_layer.visible else Node.PROCESS_MODE_INHERIT
	if _pause_layer.visible:
		_pause_panel.pivot_offset = _pause_panel.size * 0.5
		_pause_panel.scale = Vector2(0.9, 0.9)
		var tween := create_tween()
		tween.tween_property(_pause_panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func handle_back() -> void:
	_toggle_pause()
