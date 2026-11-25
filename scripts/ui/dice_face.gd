class_name DiceFace
extends Control
## A dice face (1-6) drawn in code. Reused by the board's dice in Phase 2.

const _PIPS := {
	1: [Vector2(0.5, 0.5)],
	2: [Vector2(0.27, 0.27), Vector2(0.73, 0.73)],
	3: [Vector2(0.27, 0.27), Vector2(0.5, 0.5), Vector2(0.73, 0.73)],
	4: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	5: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.5, 0.5), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	6: [Vector2(0.27, 0.24), Vector2(0.27, 0.5), Vector2(0.27, 0.76), Vector2(0.73, 0.24), Vector2(0.73, 0.5), Vector2(0.73, 0.76)],
}

@export_range(1, 6) var value: int = 6:
	set(v):
		value = clampi(v, 1, 6)
		queue_redraw()
var face_color: Color = Color.WHITE
var pip_color: Color = Palette.TEXT_DARK


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(func() -> void: pivot_offset = size * 0.5)


func _draw() -> void:
	var side := minf(size.x, size.y)
	if side <= 0.0:
		return
	var origin := (size - Vector2(side, side)) * 0.5
	var radius := int(side * 0.2)
	draw_style_box(UIKit.flat_style(Color(0, 0, 0, 0.3), radius), Rect2(origin + Vector2(0, side * 0.06), Vector2(side, side)))
	draw_style_box(UIKit.flat_style(face_color, radius, face_color.darkened(0.15), maxi(2, int(side * 0.03))), Rect2(origin, Vector2(side, side)))
	for p in _PIPS[value]:
		var pip: Vector2 = p
		draw_circle(origin + pip * side, side * 0.085, pip_color)
