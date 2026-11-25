extends Node
## Applies the shared UI theme to the whole app.


func _ready() -> void:
	get_tree().root.theme = build_theme()


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 28
	theme.set_color("font_color", "Label", Palette.TEXT)
	theme.set_stylebox("panel", "PanelContainer", UIKit.flat_style(Palette.PANEL, 28, Palette.PANEL_BORDER, 2, 24))
	theme.set_stylebox("normal", "LineEdit", UIKit.flat_style(Color(1, 1, 1, 0.10), 20, Palette.PANEL_BORDER, 2, 18))
	theme.set_stylebox("focus", "LineEdit", UIKit.flat_style(Color(1, 1, 1, 0.14), 20, Palette.ACCENT, 3, 18))
	theme.set_color("font_color", "LineEdit", Palette.TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", Palette.TEXT_MUTED)
	theme.set_color("caret_color", "LineEdit", Palette.ACCENT)
	theme.set_font_size("font_size", "LineEdit", 30)
	return theme
