class_name ModeArt
extends Control
## Small illustration for a game mode, drawn in code (replaceable by artwork later).

var mode_id: String = ClassicMode.ID


func _init(p_mode_id: String = ClassicMode.ID) -> void:
	mode_id = p_mode_id
	custom_minimum_size = Vector2(150, 150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	draw_style_box(UIKit.flat_style(Palette.BOARD_BG, int(side * 0.18)), Rect2(origin, Vector2(side, side)))
	if mode_id == SnakeMode.ID:
		_draw_snake(origin, side)
	else:
		_draw_mini_board(origin, side)


func _draw_mini_board(origin: Vector2, side: float) -> void:
	var pad := side * 0.1
	var quarter := (side - pad * 2.0) * 0.4
	var corners := [Vector2(pad, pad), Vector2(side - pad - quarter, pad), Vector2(side - pad - quarter, side - pad - quarter), Vector2(pad, side - pad - quarter)]
	for seat in 4:
		var corner: Vector2 = corners[seat]
		draw_style_box(UIKit.flat_style(Palette.seat_color(seat), int(side * 0.06)), Rect2(origin + corner, Vector2(quarter, quarter)))
		draw_circle(origin + corner + Vector2(quarter, quarter) * 0.5, quarter * 0.22, Color.WHITE)
	var c := origin + Vector2(side, side) * 0.5
	var h := side * 0.11
	draw_colored_polygon(PackedVector2Array([c, c + Vector2(-h, -h), c + Vector2(-h, h)]), Palette.seat_color(0))
	draw_colored_polygon(PackedVector2Array([c, c + Vector2(-h, -h), c + Vector2(h, -h)]), Palette.seat_color(1))
	draw_colored_polygon(PackedVector2Array([c, c + Vector2(h, -h), c + Vector2(h, h)]), Palette.seat_color(2))
	draw_colored_polygon(PackedVector2Array([c, c + Vector2(-h, h), c + Vector2(h, h)]), Palette.seat_color(3))


func _draw_snake(origin: Vector2, side: float) -> void:
	var points := PackedVector2Array()
	var segments := 28
	for i in segments + 1:
		var t := float(i) / segments
		var x := side * (0.14 + t * 0.62)
		var y := side * (0.6 + sin(t * TAU * 1.25) * 0.18)
		points.append(origin + Vector2(x, y))
	var width := side * 0.13
	draw_polyline(points, Palette.SNAKE_BODY.darkened(0.4), width + side * 0.03, true)
	draw_polyline(points, Palette.SNAKE_BODY, width, true)
	# Scales: lighter belly dots along the body.
	for i in range(2, segments - 1, 3):
		draw_circle(points[i], width * 0.18, Palette.SNAKE_BELLY)
	var head := points[segments] + Vector2(side * 0.05, -side * 0.02)
	draw_circle(head, width * 0.85, Palette.SNAKE_BODY.darkened(0.4))
	draw_circle(head, width * 0.75, Palette.SNAKE_BODY)
	draw_circle(head + Vector2(width * 0.15, -width * 0.3), width * 0.2, Color.WHITE)
	draw_circle(head + Vector2(width * 0.2, -width * 0.3), width * 0.1, Palette.TEXT_DARK)
	# Friendly forked tongue.
	var tongue_start := head + Vector2(width * 0.7, width * 0.15)
	var tongue_end := tongue_start + Vector2(width * 0.55, 0)
	var tongue_color := Color("e8413c")
	draw_line(tongue_start, tongue_end, tongue_color, maxf(2.0, side * 0.015), true)
	draw_line(tongue_end, tongue_end + Vector2(width * 0.2, -width * 0.15), tongue_color, maxf(2.0, side * 0.015), true)
	draw_line(tongue_end, tongue_end + Vector2(width * 0.2, width * 0.15), tongue_color, maxf(2.0, side * 0.015), true)
