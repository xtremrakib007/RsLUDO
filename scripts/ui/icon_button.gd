class_name IconButton
extends Button
## Square button with a vector icon (no font glyphs needed).

enum Icon { BACK, PAUSE }

var icon_kind: int = Icon.BACK


func _init(kind: int = Icon.BACK) -> void:
	icon_kind = kind
	custom_minimum_size = Vector2(88, 88)
	focus_mode = Control.FOCUS_NONE
	UIKit.style_button(self, Palette.PANEL_STRONG, Palette.TEXT, 2, 26)


func _ready() -> void:
	UIKit.add_press_feedback(self)


func _draw() -> void:
	var c := size * 0.5
	var u := minf(size.x, size.y) * 0.17
	match icon_kind:
		Icon.BACK:
			var points := PackedVector2Array([c + Vector2(u * 0.45, -u), c + Vector2(-u * 0.55, 0), c + Vector2(u * 0.45, u)])
			draw_polyline(points, Palette.TEXT, u * 0.42, true)
		Icon.PAUSE:
			draw_rect(Rect2(c + Vector2(-u * 0.85, -u), Vector2(u * 0.6, u * 2.0)), Palette.TEXT)
			draw_rect(Rect2(c + Vector2(u * 0.25, -u), Vector2(u * 0.6, u * 2.0)), Palette.TEXT)
