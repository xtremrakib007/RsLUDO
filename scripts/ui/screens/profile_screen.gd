extends BaseScreen
## Profile: name, character colour and statistics for this device.

var name_edit: LineEdit
var _seat: int = 0
var _choices: Dictionary = {}
var _preview_holder: CenterContainer


func build() -> void:
	if not AppState.has_profile():
		AppState.create_guest_profile()
	_seat = AppState.avatar_seat
	add_header("Profile")

	_preview_holder = CenterContainer.new()
	content.add_child(_preview_holder)
	_show_preview()

	content.add_child(UIKit.section_label("Your name"))
	name_edit = LineEdit.new()
	name_edit.text = AppState.guest_name
	name_edit.max_length = 14
	name_edit.placeholder_text = "Your name"
	name_edit.text_submitted.connect(func(_t: String) -> void: name_edit.release_focus())
	content.add_child(name_edit)

	content.add_child(UIKit.section_label("Your character"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	for seat in BoardLayout.SEAT_COUNT:
		var choice := Button.new()
		choice.custom_minimum_size = Vector2(120, 140)
		choice.focus_mode = Control.FOCUS_NONE
		var preview := PawnPreview.new(seat)
		preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		choice.add_child(preview)
		UIKit.ignore_mouse_recursive(choice)
		UIKit.add_press_feedback(choice)
		choice.pressed.connect(_choose.bind(seat))
		row.add_child(choice)
		_choices[seat] = choice
	content.add_child(row)
	_refresh_choices()

	content.add_child(UIKit.section_label("Statistics on this device"))
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 14)
	stats.add_theme_constant_override("v_separation", 14)
	stats.add_child(_stat("Matches played", AppState.matches_played()))
	stats.add_child(_stat("Wins", AppState.wins()))
	stats.add_child(_stat("Classic Ludo", AppState.matches_played(ClassicMode.ID)))
	stats.add_child(_stat("Snakes & Ladders", AppState.matches_played(SnakesLaddersMode.ID)))
	content.add_child(stats)

	content.add_child(UIKit.spacer())
	var history := UIKit.button("Game History", UIKit.ButtonKind.SECONDARY)
	history.pressed.connect(func() -> void:
		save()
		SceneRouter.goto("history")
	)
	content.add_child(history)
	var done := UIKit.button("Save")
	done.pressed.connect(func() -> void:
		save()
		SceneRouter.goto("home")
	)
	content.add_child(done)


func save() -> void:
	AppState.set_profile(name_edit.text, _seat)


func _choose(seat: int) -> void:
	_seat = seat
	_refresh_choices()
	_show_preview()


func _show_preview() -> void:
	for child in _preview_holder.get_children():
		child.queue_free()
	var big := PawnPreview.new(_seat)
	big.custom_minimum_size = Vector2(170, 200)
	_preview_holder.add_child(big)


func _refresh_choices() -> void:
	for seat in _choices:
		var b: Button = _choices[seat]
		var color := Palette.seat_color(seat)
		if seat == _seat:
			UIKit.style_button(b, Color(color, 0.3), Palette.TEXT, 4, 24, color)
		else:
			UIKit.style_button(b, Palette.PANEL, Palette.TEXT, 2, 24)


func _stat(title: String, value: int) -> Control:
	var card := UIKit.card(Palette.PANEL, 22, 16)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_child(UIKit.title(str(value), 44, Palette.ACCENT))
	box.add_child(UIKit.label(title, 22, Palette.TEXT_MUTED))
	card.add_child(box)
	return card


func handle_back() -> void:
	save()
	SceneRouter.goto("home")
