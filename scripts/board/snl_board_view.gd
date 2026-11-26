class_name SnlBoardView
extends Control
## Draws a Snakes & Ladders board (squares 1-100, ladders, snakes) with a
## START strip underneath for pawns not yet on the board, and animates pawns
## walking, climbing and sliding. Presentation only: positions come from SnlState.

const HOP_TIME := 0.16
## Height of the START strip, in board squares.
const START_ROWS := 0.9
const CELL_COLORS := [Color("fde8b0"), Color("c8ecd9"), Color("cfe3fb"), Color("f8d2df"), Color("e4d8f7")]
const LADDER_WOOD := Color("c98a45")
const LADDER_EDGE := Color("7a4d1f")

var board: SnlBoard
var seats: Array[int] = []
var _pawns: Dictionary = {}
var _state: SnlState = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_rebuild_pawns()


func setup(p_board: SnlBoard, p_seats: Array[int]) -> void:
	board = p_board
	seats = p_seats.duplicate()
	if is_inside_tree():
		_rebuild_pawns()
	queue_redraw()


func pawn_node(seat: int) -> PawnToken:
	return _pawns.get(seat)


func pawn_count() -> int:
	return _pawns.size()


func cell_size() -> float:
	return minf(size.x / SnlBoard.SIZE, size.y / (SnlBoard.SIZE + START_ROWS))


func board_origin() -> Vector2:
	var cs := cell_size()
	var total := Vector2(SnlBoard.SIZE, SnlBoard.SIZE + START_ROWS) * cs
	return (size - total) * 0.5


func square_center(square: int) -> Vector2:
	var cs := cell_size()
	if square <= SnlState.OFF_BOARD:
		return board_origin() + Vector2(SnlBoard.SIZE * 0.5, SnlBoard.SIZE + START_ROWS * 0.5) * cs
	return board_origin() + (Vector2(SnlBoard.cell_of(square)) + Vector2(0.5, 0.5)) * cs


# --- Pawns --------------------------------------------------------------

func sync(state: SnlState) -> void:
	_state = state
	_layout_pawns()


## Walks a pawn forward one square at a time.
func animate_walk(seat: int, from: int, to: int) -> void:
	var node := pawn_node(seat)
	if node == null:
		return
	move_child(node, get_child_count() - 1)
	node.radius = _pawn_radius(1)
	for square in range(maxi(from + 1, 1), to + 1):
		var target := square_center(square) + _pawn_offset()
		node.next_step(target.x - node.position.x)
		var tween := create_tween()
		tween.tween_property(node, "position", target, HOP_TIME).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_method(node.set_hop, 0.0, 1.0, HOP_TIME)
		await tween.finished
	node.set_hop(0.0)


## Climbs a ladder in a straight line.
func animate_climb(seat: int, to: int) -> void:
	var node := pawn_node(seat)
	if node == null:
		return
	# Hand over hand up the ladder.
	var tween := create_tween()
	tween.tween_property(node, "position", square_center(to) + _pawn_offset(), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_method(node.set_climb, 0.01, 1.0, 0.8)
	await tween.finished
	node.set_climb(0.0)


## Slides down a snake, following its body from head to tail.
func animate_slide(seat: int, from: int, to: int) -> void:
	var node := pawn_node(seat)
	if node == null:
		return
	_slide_path = SnakeArt.body_path(_snake_anchors(from, to), cell_size())
	_slide_path.reverse()
	_slide_node = node
	# Arms up, "wheee", down the snake's back.
	node.arm_raise = 1.0
	node.dizzy = true
	var tween := create_tween()
	tween.tween_method(_slide_step, 0.0, 1.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	node.rotation = 0.0
	node.arm_raise = 0.0
	node.dizzy = false


var _slide_path := PackedVector2Array()
var _slide_node: PawnToken


func _slide_step(t: float) -> void:
	if _slide_node == null:
		return
	_slide_node.position = _point_along(_slide_path, t) + _pawn_offset()
	_slide_node.rotation = sin(t * TAU * 3.0) * 0.25


func _point_along(path: PackedVector2Array, t: float) -> Vector2:
	if path.size() < 2:
		return path[0] if path.size() == 1 else Vector2.ZERO
	var f := clampf(t, 0.0, 1.0) * (path.size() - 1)
	var i := mini(floori(f), path.size() - 2)
	return path[i].lerp(path[i + 1], f - i)


func _on_resized() -> void:
	_layout_pawns()
	queue_redraw()


func _rebuild_pawns() -> void:
	for seat in _pawns:
		(_pawns[seat] as PawnToken).queue_free()
	_pawns.clear()
	for seat in seats:
		var pawn := PawnToken.new()
		pawn.seat = seat
		add_child(pawn)
		_pawns[seat] = pawn
	_layout_pawns()


func _pawn_offset() -> Vector2:
	return Vector2(0, -cell_size() * 0.12)


func _pawn_radius(sharing: int) -> float:
	return cell_size() * (0.4 if sharing <= 1 else 0.3)


func _layout_pawns() -> void:
	var cs := cell_size()
	var groups := {}
	for seat in _pawns:
		var square := SnlState.OFF_BOARD if _state == null else _state.position_of(seat)
		if not groups.has(square):
			groups[square] = []
		groups[square].append(seat)
	for square in groups:
		var members: Array = groups[square]
		var count := members.size()
		for j in count:
			var node := pawn_node(members[j])
			var offset := Vector2.ZERO
			if square == SnlState.OFF_BOARD:
				# Waiting pawns stand side by side in the START strip.
				offset = Vector2((j - (count - 1) * 0.5) * cs * 1.1, 0)
				node.radius = cs * 0.38
			else:
				if count > 1:
					var angle := TAU * j / count - PI / 2.0
					offset = Vector2(cos(angle), sin(angle)) * cs * 0.2
				node.radius = _pawn_radius(count)
			node.position = square_center(square) + offset + _pawn_offset()


# --- Drawing ------------------------------------------------------------

func _draw() -> void:
	var cs := cell_size()
	if cs <= 0.0 or board == null:
		return
	var origin := board_origin()
	var side := cs * SnlBoard.SIZE
	var frame := Rect2(origin, Vector2(side, side)).grow(cs * 0.18)
	draw_style_box(UIKit.flat_style(Color(0, 0, 0, 0.3), int(cs * 0.4)), Rect2(frame.position + Vector2(0, cs * 0.15), frame.size))
	draw_style_box(UIKit.flat_style(Palette.BOARD_FRAME, int(cs * 0.4)), frame)
	_draw_squares(cs)
	_draw_start_strip(cs)
	for bottom in board.ladders:
		_draw_ladder(int(bottom), int(board.ladders[bottom]), cs)
	var index := 0
	for head in board.snakes:
		SnakeArt.draw_snake(self, _snake_anchors(int(head), int(board.snakes[head])), cs, Palette.snake_color(index))
		index += 1


func _draw_squares(cs: float) -> void:
	var font := UIKit.title_font()
	var font_size := maxi(8, int(cs * 0.27))
	for square in range(1, SnlBoard.LAST_SQUARE + 1):
		var cell := SnlBoard.cell_of(square)
		var rect := Rect2(board_origin() + Vector2(cell) * cs, Vector2(cs, cs))
		var base: Color = CELL_COLORS[(9 - cell.y) % CELL_COLORS.size()]
		var fill := base if (cell.x + cell.y) % 2 == 0 else base.darkened(0.07)
		draw_rect(rect, fill)
		draw_rect(rect, Color(Palette.BOARD_FRAME, 0.18), false, maxf(1.0, cs * 0.025))
		draw_string(font, rect.position + Vector2(cs * 0.08, cs * 0.3), str(square), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.TEXT_DARK)
		if square == SnlBoard.LAST_SQUARE:
			_draw_trophy(rect.get_center() + Vector2(0, cs * 0.12), cs * 0.3)


func _draw_start_strip(cs: float) -> void:
	var top_left := board_origin() + Vector2(0, (SnlBoard.SIZE + 0.15) * cs)
	var rect := Rect2(top_left, Vector2(SnlBoard.SIZE * cs, (START_ROWS - 0.15) * cs))
	draw_style_box(UIKit.flat_style(Color(1, 1, 1, 0.08), int(cs * 0.3), Palette.PANEL_BORDER, 2), rect)
	draw_string(UIKit.title_font(), rect.position + Vector2(cs * 0.25, rect.size.y * 0.62), "START", HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(8, int(cs * 0.3)), Palette.TEXT_MUTED)


func _draw_trophy(centre: Vector2, r: float) -> void:
	var gold := Color("f2b705")
	draw_circle(centre + Vector2(0, -r * 0.2), r * 0.6, gold)
	draw_rect(Rect2(centre + Vector2(-r * 0.12, r * 0.3), Vector2(r * 0.24, r * 0.35)), gold)
	draw_rect(Rect2(centre + Vector2(-r * 0.45, r * 0.62), Vector2(r * 0.9, r * 0.22)), gold.darkened(0.2))
	draw_arc(centre + Vector2(-r * 0.6, -r * 0.25), r * 0.25, PI * 0.5, PI * 1.5, 12, gold, r * 0.12, true)
	draw_arc(centre + Vector2(r * 0.6, -r * 0.25), r * 0.25, -PI * 0.5, PI * 0.5, 12, gold, r * 0.12, true)


func _draw_ladder(bottom: int, top: int, cs: float) -> void:
	var a := square_center(bottom)
	var b := square_center(top)
	var along := (b - a).normalized()
	a -= along * cs * 0.15
	b += along * cs * 0.15
	var across := Vector2(-along.y, along.x) * cs * 0.2
	var rail := maxf(2.0, cs * 0.08)
	# Shadow, rungs, then rails on top.
	draw_line(a + across + Vector2(2, 3), b + across + Vector2(2, 3), Color(0, 0, 0, 0.2), rail, true)
	draw_line(a - across + Vector2(2, 3), b - across + Vector2(2, 3), Color(0, 0, 0, 0.2), rail, true)
	var rungs := maxi(2, int(a.distance_to(b) / (cs * 0.32)))
	for i in range(1, rungs):
		var p := a.lerp(b, float(i) / rungs)
		draw_line(p - across, p + across, LADDER_EDGE, rail * 0.9, true)
		draw_line(p - across * 0.9, p + across * 0.9, LADDER_WOOD.lightened(0.15), rail * 0.5, true)
	for side in [-1.0, 1.0]:
		draw_line(a + across * side, b + across * side, LADDER_EDGE, rail * 1.35, true)
		draw_line(a + across * side, b + across * side, LADDER_WOOD, rail, true)


## Points a snake's body passes through, tail first and head last, with a gentle S-bend.
func _snake_anchors(head: int, tail: int) -> Array[Vector2]:
	var h := square_center(head)
	var t := square_center(tail)
	var normal := (h - t).orthogonal().normalized() * cell_size() * 0.55
	var anchors: Array[Vector2] = [t, t.lerp(h, 0.33) + normal, t.lerp(h, 0.66) - normal, h]
	return anchors
