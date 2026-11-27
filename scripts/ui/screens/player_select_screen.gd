extends BaseScreen
## Mode details, player count (2, 3 or 4) and how many of them are bots.

const COUNT_SUBTITLES := {2: "Head to head", 3: "Three-way race", 4: "Everyone plays"}

var _mode: GameMode
var _count: int = 4
var _bots: int = 0
var _options: Dictionary = {}
var _bot_row: HBoxContainer
var _bot_options: Dictionary = {}


func build() -> void:
	_mode = ModeRegistry.get_mode(AppState.pending_mode_id)
	if _mode == null:
		_mode = ModeRegistry.get_mode(ClassicMode.ID)
	add_header(_mode.title)

	var about := UIKit.card()
	var about_row := HBoxContainer.new()
	about_row.add_theme_constant_override("separation", 22)
	about_row.add_child(ModeArt.new(_mode.id))
	var text := UIKit.label(_mode.description, 26, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	about_row.add_child(text)
	about.add_child(about_row)
	content.add_child(about)

	content.add_child(UIKit.section_label("How many players?"))
	var options_row := HBoxContainer.new()
	options_row.add_theme_constant_override("separation", 18)
	for count in MatchConfig.SUPPORTED_PLAYER_COUNTS:
		var option := _count_option(count)
		options_row.add_child(option)
		_options[count] = option
	content.add_child(options_row)

	content.add_child(UIKit.section_label("How many are computer players?"))
	_bot_row = HBoxContainer.new()
	_bot_row.add_theme_constant_override("separation", 12)
	content.add_child(_bot_row)
	_refresh_options()

	content.add_child(UIKit.label("People share this device and take turns. Bots play like strong human players. You can pick colours and switch players between human and bot in the lobby.", 24, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
	content.add_child(UIKit.spacer())

	var next := UIKit.button("Continue")
	next.pressed.connect(_continue)
	content.add_child(next)


func _count_option(count: int) -> Button:
	var option := Button.new()
	option.custom_minimum_size = Vector2(0, 190)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.focus_mode = Control.FOCUS_NONE
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	option.add_child(box)
	box.add_child(UIKit.title("%d Players" % count, 32, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIKit.label(COUNT_SUBTITLES[count], 20, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 10)
	for seat in MatchConfig.seats_for_count(count):
		dots.add_child(UIKit.color_dot(Palette.seat_color(seat), 28))
	box.add_child(dots)
	UIKit.ignore_mouse_recursive(option)
	UIKit.add_press_feedback(option)
	option.pressed.connect(_select.bind(count))
	return option


func _select(count: int) -> void:
	_count = count
	_bots = mini(_bots, count - 1)
	_refresh_options()


func _select_bots(bots: int) -> void:
	_bots = bots
	_refresh_options()


## Bot choices: from none up to all but one player (someone has to play!).
func _rebuild_bot_options() -> void:
	for child in _bot_row.get_children():
		child.queue_free()
	_bot_options.clear()
	for bots in _count:
		var text := "No bots" if bots == 0 else ("1 bot" if bots == 1 else "%d bots" % bots)
		var b := UIKit.button(text, UIKit.ButtonKind.SECONDARY, 84)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(_select_bots.bind(bots))
		_bot_row.add_child(b)
		_bot_options[bots] = b


func _refresh_options() -> void:
	for count in _options:
		var option: Button = _options[count]
		if count == _count:
			UIKit.style_button(option, Color(Palette.ACCENT, 0.18), Palette.TEXT, 4, 30, Palette.ACCENT)
		else:
			UIKit.style_button(option, Palette.PANEL, Palette.TEXT, 2, 30)
	if _bot_options.size() != _count:
		_rebuild_bot_options()
	for bots in _bot_options:
		var b: Button = _bot_options[bots]
		if bots == _bots:
			UIKit.style_button(b, Color(Palette.ACCENT, 0.18), Palette.TEXT, 4, 26, Palette.ACCENT)
		else:
			UIKit.style_button(b, Palette.PANEL, Palette.TEXT, 2, 26)


func _continue() -> void:
	AppState.match_config = MatchConfig.create(_mode.id, _count, _bots)
	SceneRouter.goto("board_select" if _mode.has_board_choice else "lobby")


func handle_back() -> void:
	SceneRouter.goto("home")
