class_name PawnToken
extends Node2D
## Placeholder pawn: a small cartoon person drawn in code.
## Phase 3 replaces the drawing with an animated character scene; the board
## only needs `seat`, `radius` and `position`, so the swap stays local.

var seat: int = 0:
	set(value):
		seat = value
		queue_redraw()
## Roughly half a board square.
var radius: float = 20.0:
	set(value):
		radius = maxf(value, 1.0)
		queue_redraw()


func _draw() -> void:
	var r := radius
	var body_color := Palette.seat_color(seat)
	var outline := body_color.darkened(0.45)
	var line_width := maxf(1.5, r * 0.09)

	# Ground shadow (squashed circle).
	draw_set_transform(Vector2(0, r * 0.9), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, r * 0.75, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Body.
	var body := PackedVector2Array([
		Vector2(-r * 0.62, r * 0.9), Vector2(-r * 0.5, r * 0.05), Vector2(-r * 0.3, -r * 0.12),
		Vector2(r * 0.3, -r * 0.12), Vector2(r * 0.5, r * 0.05), Vector2(r * 0.62, r * 0.9),
	])
	draw_colored_polygon(body, body_color)
	var body_outline := body.duplicate()
	body_outline.append(body[0])
	draw_polyline(body_outline, outline, line_width, true)
	# Shirt highlight.
	draw_line(Vector2(-r * 0.22, r * 0.2), Vector2(-r * 0.3, r * 0.7), body_color.lightened(0.35), line_width * 1.2, true)

	# Head, hair and eyes.
	var head := Vector2(0, -r * 0.5)
	var head_r := r * 0.42
	draw_circle(head, head_r, Palette.skin_tone(seat))
	draw_arc(head, head_r * 0.92, PI * 1.05, PI * 1.95, 16, outline, head_r * 0.35, true)
	draw_arc(head, head_r, 0.0, TAU, 32, outline, line_width, true)
	draw_circle(head + Vector2(-head_r * 0.35, head_r * 0.1), head_r * 0.12, Palette.TEXT_DARK)
	draw_circle(head + Vector2(head_r * 0.35, head_r * 0.1), head_r * 0.12, Palette.TEXT_DARK)
