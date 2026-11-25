extends BaseScreen
## Local game lobby: name each player, review the rules, start the match.

const MAX_NAME_LENGTH := 14

var _config: MatchConfig
var _name_edits: Array[LineEdit] = []


func build() -> void:
	_config = AppState.match_config
	if _config == null:
		_config = MatchConfig.create(ClassicMode.ID, 4)
		AppState.match_config = _config
	var mode := ModeRegistry.get_mode(_config.mode_id)
	add_header("Game Lobby")
	content.add_child(UIKit.label("%s  -  %d players  -  pass and play" % [mode.title, _config.player_count()], 26, Palette.TEXT_MUTED))

	for player in _config.players:
		content.add_child(_player_row(player))

	var rules_card := UIKit.card()
	var rules_box := VBoxContainer.new()
	rules_box.add_theme_constant_override("separation", 6)
	rules_box.add_child(UIKit.section_label("Rules for this match"))
	for line in _config.rules.summary():
		rules_box.add_child(UIKit.label("-  " + line, 24, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	rules_card.add_child(rules_box)
	content.add_child(rules_card)

	content.add_child(UIKit.spacer())
	var start := UIKit.button("Start Match")
	start.pressed.connect(_start)
	content.add_child(start)


func _player_row(player: LudoPlayer) -> Control:
	var row_card := UIKit.card(Palette.PANEL, 24, 14)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var preview := PawnPreview.new(player.seat)
	preview.custom_minimum_size = Vector2(80, 90)
	row.add_child(preview)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_child(UIKit.title(player.color_name().to_upper(), 20, player.color()))
	var edit := LineEdit.new()
	edit.text = player.display_name
	edit.placeholder_text = "%s Player" % player.color_name()
	edit.max_length = MAX_NAME_LENGTH
	edit.select_all_on_focus = true
	edit.text_submitted.connect(func(_text: String) -> void: edit.release_focus())
	fields.add_child(edit)
	_name_edits.append(edit)
	row.add_child(fields)
	row_card.add_child(row)
	return row_card


func _start() -> void:
	for i in _name_edits.size():
		var player: LudoPlayer = _config.players[i]
		var entered: String = _name_edits[i].text.strip_edges()
		player.display_name = entered if not entered.is_empty() else "%s Player" % player.color_name()
	SceneRouter.goto("game")


func handle_back() -> void:
	SceneRouter.goto("player_select")
