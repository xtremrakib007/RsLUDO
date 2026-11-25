class_name UIKit
extends RefCounted
## Small factory for consistently styled UI pieces.

enum ButtonKind { PRIMARY, SECONDARY, GHOST }

static var _title_font: FontVariation


static func flat_style(bg: Color, radius: int = 24, border: Color = Color(0, 0, 0, 0), border_width: int = 0, padding: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	if border_width > 0:
		style.border_color = border
		style.set_border_width_all(border_width)
	style.set_content_margin_all(padding)
	style.anti_aliasing = true
	return style


static func title_font() -> FontVariation:
	if _title_font == null:
		_title_font = FontVariation.new()
		_title_font.base_font = ThemeDB.fallback_font
		_title_font.variation_embolden = 0.9
	return _title_font


static func label(text: String, font_size: int = 28, color: Color = Palette.TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func title(text: String, font_size: int = 48, color: Color = Palette.TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text, font_size, color, align)
	l.add_theme_font_override("font", title_font())
	return l


static func section_label(text: String) -> Label:
	var l := label(text.to_upper(), 22, Palette.TEXT_MUTED)
	l.add_theme_font_override("font", title_font())
	return l


static func button(text: String, kind: int = ButtonKind.PRIMARY, min_height: int = 100) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_height)
	b.focus_mode = Control.FOCUS_NONE
	var bg := Palette.ACCENT
	var fg := Palette.TEXT_DARK
	var border_width := 0
	match kind:
		ButtonKind.SECONDARY:
			bg = Palette.PANEL_STRONG
			fg = Palette.TEXT
			border_width = 2
		ButtonKind.GHOST:
			bg = Color(0, 0, 0, 0)
			fg = Palette.TEXT_MUTED
	style_button(b, bg, fg, border_width)
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_font_override("font", title_font())
	add_press_feedback(b)
	return b


static func style_button(b: Button, bg: Color, fg: Color, border_width: int = 0, radius: int = 30, border: Color = Palette.PANEL_BORDER) -> void:
	b.add_theme_stylebox_override("normal", flat_style(bg, radius, border, border_width))
	b.add_theme_stylebox_override("hover", flat_style(bg.lightened(0.08), radius, border, border_width))
	b.add_theme_stylebox_override("pressed", flat_style(bg.darkened(0.12), radius, border, border_width))
	b.add_theme_stylebox_override("disabled", flat_style(Color(bg, bg.a * 0.4), radius))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.45))


## Slight shrink while a button is held down.
static func add_press_feedback(b: BaseButton) -> void:
	b.resized.connect(func() -> void: b.pivot_offset = b.size * 0.5)
	b.button_down.connect(func() -> void: _scale_to(b, 0.95))
	b.button_up.connect(func() -> void: _scale_to(b, 1.0))


static func _scale_to(control: Control, target: float) -> void:
	if not control.is_inside_tree():
		return
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(target, target), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func card(bg: Color = Palette.PANEL, radius: int = 28, padding: int = 24) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", flat_style(bg, radius, Palette.PANEL_BORDER, 2, padding))
	return panel


static func color_dot(color: Color, diameter: float = 32.0) -> Control:
	var dot := Control.new()
	dot.custom_minimum_size = Vector2(diameter, diameter)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.draw.connect(func() -> void:
		var r := minf(dot.size.x, dot.size.y) * 0.5
		dot.draw_circle(dot.size * 0.5, r, color)
		dot.draw_arc(dot.size * 0.5, r - 1.5, 0.0, TAU, 32, Color(1, 1, 1, 0.85), 3.0, true)
	)
	return dot


static func spacer(expand_vertical: bool = true) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand_vertical:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


## Lets clicks pass through every child so the parent button receives them.
static func ignore_mouse_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		ignore_mouse_recursive(child)
