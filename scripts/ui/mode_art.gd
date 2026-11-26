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
	if mode_id == SnakesLaddersMode.ID:
		_draw_snakes_ladders(origin, side)
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


func _draw_snakes_ladders(origin: Vector2, side: float) -> void:
	# A small 5 x 5 board with one ladder and one snake.
	var pad := side * 0.08
	var cell := (side - pad * 2.0) / 5.0
	for row in 5:
		for col in 5:
			var color: Color = SnlBoardView.CELL_COLORS[row % SnlBoardView.CELL_COLORS.size()]
			if (row + col) % 2 == 1:
				color = color.darkened(0.08)
			draw_rect(Rect2(origin + Vector2(pad + col * cell, pad + row * cell), Vector2(cell, cell)), color)
	var a := origin + Vector2(pad + cell * 0.9, pad + cell * 4.3)
	var b := origin + Vector2(pad + cell * 2.1, pad + cell * 0.7)
	var across := (b - a).orthogonal().normalized() * cell * 0.28
	for i in range(1, 6):
		var p := a.lerp(b, i / 6.0)
		draw_line(p - across, p + across, SnlBoardView.LADDER_EDGE, maxf(2.0, side * 0.02), true)
	for s in [-1.0, 1.0]:
		draw_line(a + across * s, b + across * s, SnlBoardView.LADDER_WOOD, maxf(3.0, side * 0.03), true)
	var anchors: Array[Vector2] = [
		origin + Vector2(pad + cell * 3.2, pad + cell * 4.4),
		origin + Vector2(pad + cell * 4.3, pad + cell * 3.0),
		origin + Vector2(pad + cell * 3.0, pad + cell * 1.8),
		origin + Vector2(pad + cell * 3.9, pad + cell * 0.6),
	]
	SnakeArt.draw_snake(self, anchors, cell * 1.3, Palette.SNAKE_BODY)
