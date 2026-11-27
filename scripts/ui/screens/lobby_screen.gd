extends BaseScreen
## Local game lobby: for each player choose a colour, a name and Human or Bot,
## review the rules, then start. Bots play like strong human players.

const MAX_NAME_LENGTH := 14

var _config: MatchConfig
var _rows_box: VBoxContainer
var _name_edits: Array[LineEdit] = []
var _message: Label


func build() -> void:
	_config = AppState.match_config
	if _config == null:
		_config = MatchConfig.create(ClassicMode.ID, 4)
		AppState.match_config = _config
	var mode := ModeRegistry.get_mode(_config.mode_id)
	add_header("Game Lobby")
	content.add_child(UIKit.label("%s  -  %d players" % [mode.title, _config.player_count()], 26, Palette.TEXT_MUTED))

	# Player 1 defaults to the profile name, so wins count in the profile.
	var first: LudoPlayer = _config.players[0]
	if AppState.has_profile() and not first.is_bot() and first.display_name == MatchConfig.default_name(first.seat, first.control_type):
		first.display_name = AppState.guest_name

	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 12)
	content.add_child(_rows_box)
	_message = UIKit.label("", 22, Palette.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, true)
	content.add_child(_message)
	_rebuild_rows()

	var rules_card := UIKit.card()
	var rules_box := VBoxContainer.new()
	rules_box.add_theme_constant_override("separation", 6)
	rules_box.add_child(UIKit.section_label("Rules for this match"))
	for line in mode.rules_summary(_config):
		rules_box.add_child(UIKit.label("-  " + line, 22, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	rules_card.add_child(rules_box)
	content.add_child(rules_card)

	content.add_child(UIKit.spacer())
	var start := UIKit.button("Start Match")
	start.pressed.connect(_start)
	content.add_child(start)


func _rebuild_rows() -> void:
	_keep_typed_names()
	for child in _rows_box.get_children():
		child.queue_free()
	_name_edits.clear()
	for i in _config.players.size():
		_rows_box.add_child(_player_row(i))


func _player_row(index: int) -> Control:
	var player: LudoPlayer = _config.players[index]
	var row_card := UIKit.card(Palette.PANEL, 22, 12)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var preview := PawnPreview.new(player.seat)
	preview.custom_minimum_size = Vector2(70, 96)
	row.add_child(preview)

	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation", 8)
	# Colour choice: tap a colour; colours other players have are dimmed.
	var colours := HBoxContainer.new()
	colours.add_theme_constant_override("separation", 8)
	for seat in BoardLayout.SEAT_COUNT:
		colours.add_child(_colour_button(index, seat))
	fields.add_child(colours)
	var edit := LineEdit.new()
	edit.text = player.display_name
	edit.placeholder_text = MatchConfig.default_name(player.seat, player.control_type)
	edit.max_length = MAX_NAME_LENGTH
	edit.select_all_on_focus = true
	edit.text_submitted.connect(func(_text: String) -> void: edit.release_focus())
	fields.add_child(edit)
	_name_edits.append(edit)
	row.add_child(fields)

	var kind := UIKit.button("Bot" if player.is_bot() else "Human", UIKit.ButtonKind.SECONDARY, 72)
	kind.custom_minimum_size = Vector2(120, 72)
	kind.add_theme_font_size_override("font_size", 26)
	if player.is_bot():
		UIKit.style_button(kind, Color(Palette.CLASSIC_ACCENT, 0.5), Palette.TEXT, 2, 22, Palette.CLASSIC_ACCENT)
	kind.pressed.connect(_toggle_bot.bind(index))
	row.add_child(kind)
	row_card.add_child(row)
	return row_card


func _colour_button(index: int, seat: int) -> Button:
	var player: LudoPlayer = _config.players[index]
	var taken := false
	for other in _config.players:
		if other != player and other.seat == seat:
			taken = true
	var b := Button.new()
	b.custom_minimum_size = Vector2(46, 46)
	b.focus_mode = Control.FOCUS_NONE
	var color := Palette.seat_color(seat)
	if player.seat == seat:
		UIKit.style_button(b, color, Palette.TEXT, 4, 23, Color.WHITE)
	elif taken:
		UIKit.style_button(b, Color(color, 0.25), Palette.TEXT, 0, 23)
	else:
		UIKit.style_button(b, color.darkened(0.15), Palette.TEXT, 0, 23)
	b.pressed.connect(_choose_colour.bind(index, seat))
	return b


func _choose_colour(index: int, seat: int) -> void:
	_keep_typed_names()
	if _config.players[index].seat == seat:
		return
	if not _config.set_player_seat(index, seat):
		_message.text = "%s already has that colour." % _holder_name(seat)
		return
	_message.text = ""
	_rebuild_rows()


func _toggle_bot(index: int) -> void:
	_keep_typed_names()
	var player: LudoPlayer = _config.players[index]
	var target := LudoPlayer.ControlType.LOCAL_HUMAN if player.is_bot() else LudoPlayer.ControlType.COMPUTER
	if not _config.set_player_control(index, target):
		_message.text = "At least one person has to play."
		return
	_message.text = ""
	_rebuild_rows()


func _holder_name(seat: int) -> String:
	var holder := _config.player_at_seat(seat)
	return holder.display_name if holder != null else Palette.seat_name(seat)


## Copies names typed so far into the players, so rebuilding rows keeps them.
func _keep_typed_names() -> void:
	for i in mini(_name_edits.size(), _config.players.size()):
		var entered: String = _name_edits[i].text.strip_edges()
		if not entered.is_empty():
			_config.players[i].display_name = entered


func _start() -> void:
	_keep_typed_names()
	for player in _config.players:
		if player.display_name.strip_edges().is_empty():
			player.display_name = MatchConfig.default_name(player.seat, player.control_type)
	_config.sort_by_seat()
	SceneRouter.goto(ModeRegistry.get_mode(_config.mode_id).game_screen)


func handle_back() -> void:
	var mode := ModeRegistry.get_mode(_config.mode_id)
	SceneRouter.goto("board_select" if mode != null and mode.has_board_choice else "player_select")
