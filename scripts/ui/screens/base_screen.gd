class_name BaseScreen
extends Control
## Common screen frame: background, margins, a vertical content column,
## headers and toasts. Screens override build() and handle_back().

## Widest the content column gets on tablets and in landscape; the rest is side margin.
const MAX_CONTENT_WIDTH := 860.0
const SIDE_MARGIN := 36

var content: VBoxContainer
var _margin: MarginContainer
var _toast: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin = margin
	resized.connect(_fit_width)
	_fit_width()
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_bottom", 44)
	add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	margin.add_child(content)
	build()


## Keeps the content column phone-shaped and centred on wide screens (iPad, landscape).
func _fit_width() -> void:
	if _margin == null:
		return
	var side := maxi(SIDE_MARGIN, int((size.x - MAX_CONTENT_WIDTH) * 0.5))
	_margin.add_theme_constant_override("margin_left", side)
	_margin.add_theme_constant_override("margin_right", side)


## Override to add the screen's controls to `content`.
func build() -> void:
	pass


## Called for the Android back button and Escape. Override per screen.
func handle_back() -> void:
	pass


func add_header(title_text: String, show_back: bool = true) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	if show_back:
		var back := IconButton.new(IconButton.Icon.BACK)
		back.pressed.connect(handle_back)
		row.add_child(back)
	var heading := UIKit.title(title_text, 44)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	content.add_child(row)
	return row


func show_toast(message: String) -> void:
	if is_instance_valid(_toast):
		_toast.queue_free()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.flat_style(Color(0.04, 0.05, 0.13, 0.95), 24, Palette.PANEL_BORDER, 2, 22))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(UIKit.label(message, 26, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true))
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -200.0
	panel.offset_bottom = -130.0
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.modulate.a = 0.0
	add_child(panel)
	_toast = panel
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(2.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(panel.queue_free)


func _build_background() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Palette.BG_TOP)
	gradient.set_color(1, Palette.BG_BOTTOM)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 8
	texture.height = 256
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	var bg := TextureRect.new()
	bg.texture = texture
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Soft glows in the four player colours.
	var decor := Control.new()
	decor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor.draw.connect(func() -> void:
		var s := decor.size
		var spots := [Vector2(0.0, 0.08), Vector2(1.0, 0.22), Vector2(1.0, 0.92), Vector2(0.0, 0.78)]
		for seat in 4:
			var spot: Vector2 = spots[seat]
			decor.draw_circle(spot * s, s.x * 0.32, Color(Palette.seat_color(seat), 0.09))
	)
	decor.resized.connect(decor.queue_redraw)
	add_child(decor)
