extends BaseScreen
## "Choose Board" for Snakes & Ladders: preview each board, flip with the arrows
## (or swipe), then Select.

var board_preview: SnlBoardView
var _boards: Array[SnlBoard] = []
var _index := 0
var _title: Label
var _tagline: Label
var _counter: Label
var _swipe_start := Vector2.ZERO


func build() -> void:
	if AppState.match_config == null:
		AppState.match_config = MatchConfig.create(SnakesLaddersMode.ID, 2)
	_boards = SnlBoards.all()
	_index = SnlBoards.index_of(AppState.match_config.board_id)
	add_header("Choose Board")

	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 4)
	_title = UIKit.title("", 44, Palette.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	_tagline = UIKit.label("", 26, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	names.add_child(_title)
	names.add_child(_tagline)
	content.add_child(names)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	var previous := _arrow_button(true)
	previous.pressed.connect(_step.bind(-1))
	row.add_child(previous)
	board_preview = SnlBoardView.new()
	board_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_preview.setup(_boards[_index], [] as Array[int])
	board_preview.gui_input.connect(_on_preview_input)
	row.add_child(board_preview)
	var next := _arrow_button(false)
	next.pressed.connect(_step.bind(1))
	row.add_child(next)
	content.add_child(row)
	board_preview.mouse_filter = Control.MOUSE_FILTER_STOP

	_counter = UIKit.label("", 24, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(_counter)
	var select := UIKit.button("Select")
	select.pressed.connect(_select)
	content.add_child(select)
	_show_board()


func _arrow_button(left: bool) -> Button:
	var b := Button.new()
	b.text = "<" if left else ">"
	b.custom_minimum_size = Vector2(64, 120)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	UIKit.style_button(b, Palette.PANEL_STRONG, Palette.ACCENT, 2, 20)
	b.add_theme_font_size_override("font_size", 48)
	b.add_theme_font_override("font", UIKit.title_font())
	UIKit.add_press_feedback(b)
	return b


func current_board() -> SnlBoard:
	return _boards[_index]


func _step(delta: int) -> void:
	_index = posmod(_index + delta, _boards.size())
	_show_board()


func _show_board() -> void:
	var board := current_board()
	_title.text = board.title
	_tagline.text = "%s\n%d ladders, %d snakes" % [board.tagline, board.ladders.size(), board.snakes.size()]
	_counter.text = "Board %d of %d" % [_index + 1, _boards.size()]
	board_preview.setup(board, [] as Array[int])
	board_preview.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(board_preview, "modulate:a", 1.0, 0.18)


func _on_preview_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press == null or press.button_index != MOUSE_BUTTON_LEFT:
		return
	if press.pressed:
		_swipe_start = press.position
	elif absf(press.position.x - _swipe_start.x) > 80.0:
		_step(-1 if press.position.x > _swipe_start.x else 1)


func _select() -> void:
	AppState.match_config.board_id = current_board().id
	SceneRouter.goto("lobby")


func handle_back() -> void:
	SceneRouter.goto("player_select")
