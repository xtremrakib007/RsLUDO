extends BaseScreen
## Home: choose Classic or Snake Ludo. Online features are shown as
## "coming soon" and do nothing else; there is no fake online functionality.

const EXIT_CONFIRM_MS := 2000
const ONLINE_FEATURES := ["Quick Match", "Create Room", "Join Room", "Friends"]

var _last_back_ms: int = -EXIT_CONFIRM_MS


func build() -> void:
	content.add_child(_profile_header())

	content.add_child(UIKit.section_label("Play on this device"))
	for mode in ModeRegistry.all_modes():
		var card := ModeCard.new(mode)
		card.pressed.connect(_open_mode.bind(mode.id))
		content.add_child(card)

	content.add_child(UIKit.section_label("Online - coming soon"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	for feature in ONLINE_FEATURES:
		grid.add_child(_coming_soon_tile(feature))
	content.add_child(grid)

	content.add_child(UIKit.spacer())

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 18)
	for item in ["Profile", "Settings", "Rules"]:
		var b := UIKit.button(item, UIKit.ButtonKind.SECONDARY, 90)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 28)
		b.pressed.connect(SceneRouter.goto.bind(item.to_lower()))
		bottom.add_child(b)
	content.add_child(bottom)


func _profile_header() -> Control:
	# The whole header is a button that opens the profile.
	var header := Button.new()
	header.custom_minimum_size = Vector2(0, 112)
	header.focus_mode = Control.FOCUS_NONE
	UIKit.style_button(header, Color(0, 0, 0, 0), Palette.TEXT, 0, 24)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 20)
	var avatar := PawnPreview.new(AppState.avatar_seat)
	avatar.custom_minimum_size = Vector2(96, 108)
	row.add_child(avatar)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var display_name: String = AppState.guest_name if AppState.has_profile() else "Guest"
	names.add_child(UIKit.title(display_name, 38))
	names.add_child(UIKit.label("%d games  -  %d wins  -  tap to edit" % [AppState.matches_played(), AppState.wins()], 22, Palette.TEXT_MUTED))
	row.add_child(names)
	header.add_child(row)
	UIKit.ignore_mouse_recursive(header)
	UIKit.add_press_feedback(header)
	header.pressed.connect(SceneRouter.goto.bind("profile"))
	return header


func _coming_soon_tile(feature: String) -> Button:
	var tile := UIKit.button(feature, UIKit.ButtonKind.SECONDARY, 110)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_font_size_override("font_size", 28)
	tile.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UIKit.flat_style(Palette.ACCENT, 12, Color(0, 0, 0, 0), 0, 6))
	badge.add_child(UIKit.title("SOON", 16, Palette.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.offset_left = -80.0
	badge.offset_right = -12.0
	badge.offset_top = 10.0
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tile.add_child(badge)
	UIKit.ignore_mouse_recursive(tile)
	tile.pressed.connect(show_toast.bind("%s needs online play, which is coming in a future update." % feature))
	return tile


func _open_mode(mode_id: String) -> void:
	AppState.pending_mode_id = mode_id
	SceneRouter.goto("player_select")


func handle_back() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_back_ms < EXIT_CONFIRM_MS:
		get_tree().quit()
		return
	_last_back_ms = now
	show_toast("Press back again to exit.")
