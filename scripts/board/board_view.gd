class_name BoardView
extends Control
## Draws the Ludo board and its pawns, plays move animations and reports taps on
## movable pawns. Pure presentation: positions come from MatchState and moves
## come from rules events; the board never decides anything itself.
## The board is always square and centred inside this control.

signal pawn_tapped(seat: int, pawn: int)

const HOP_TIME := 0.15
const RETURN_TIME := 0.45

var active_seats: Array[int] = [0, 1, 2, 3]
## Vector2i(seat, pawn) -> PawnToken
var _pawns: Dictionary = {}
var _state: MatchState = null
var _selectable: Array[Vector2i] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_rebuild_pawns()


## Choose which seats are playing. Unused bases are drawn faded and stay empty.
func setup(seats: Array[int]) -> void:
	active_seats = seats.duplicate()
	if is_inside_tree():
		_rebuild_pawns()
	queue_redraw()


func pawn_count() -> int:
	return _pawns.size()


func pawn_node(seat: int, pawn: int) -> PawnToken:
	return _pawns.get(Vector2i(seat, pawn))


func cell_size() -> float:
	return minf(size.x, size.y) / BoardLayout.GRID_SIZE


func board_origin() -> Vector2:
	var side := cell_size() * BoardLayout.GRID_SIZE
	return (size - Vector2(side, side)) * 0.5


## Converts a grid point (BoardLayout units) to this control's local position.
func grid_to_local(point: Vector2) -> Vector2:
	return board_origin() + point * cell_size()


func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(grid_to_local(Vector2(cell)), Vector2.ONE * cell_size())


# --- Pawns --------------------------------------------------------------

## Places every pawn where the match state says, spreading out pawns that share a square.
func sync(state: MatchState) -> void:
	_state = state
	_layout_pawns()


## Marks pawns the current player may move. Taps on them emit pawn_tapped.
func set_selectable(ids: Array[Vector2i]) -> void:
	_selectable = ids.duplicate()
	for id in _pawns:
		var pawn: PawnToken = _pawns[id]
		pawn.highlighted = _selectable.has(id)
		if pawn.highlighted:
			move_child(pawn, get_child_count() - 1)
	mouse_filter = Control.MOUSE_FILTER_IGNORE if _selectable.is_empty() else Control.MOUSE_FILTER_STOP


## Walks a pawn square by square between two progress values (any direction).
func animate_move(seat: int, pawn: int, from: int, to: int) -> void:
	var node := pawn_node(seat, pawn)
	if node == null or from == to:
		return
	if to == MatchState.IN_BASE:
		await animate_to_base(seat, pawn)
		return
	var steps: Array[int] = []
	if from == MatchState.IN_BASE:
		steps.append(0)
	elif to > from:
		for p in range(from + 1, to + 1):
			steps.append(p)
	else:
		for p in range(from - 1, to - 1, -1):
			steps.append(p)
	node.radius = cell_size() * 0.52
	move_child(node, get_child_count() - 1)
	for p in steps:
		var target := grid_to_local(BoardLayout.progress_point(seat, p)) + _pawn_offset()
		node.next_step(target.x - node.position.x)
		var tween := create_tween()
		tween.tween_property(node, "position", target, HOP_TIME).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_method(node.set_hop, 0.0, 1.0, HOP_TIME)
		await tween.finished
	node.set_hop(0.0)


## Sends a pawn back to its base slot after a capture.
func animate_to_base(seat: int, pawn: int) -> void:
	var node := pawn_node(seat, pawn)
	if node == null:
		return
	move_child(node, get_child_count() - 1)
	var target := grid_to_local(BoardLayout.base_slot_points(seat)[pawn]) + _pawn_offset()
	var tween := create_tween()
	tween.tween_property(node, "position", target, RETURN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(node, "rotation", TAU, RETURN_TIME)
	await tween.finished
	node.rotation = 0.0
	node.radius = cell_size() * 0.52


func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press == null or not press.pressed or press.button_index != MOUSE_BUTTON_LEFT or _selectable.is_empty():
		return
	var best := Vector2i(-1, -1)
	var best_distance := cell_size() * 1.2
	for id in _selectable:
		var node := pawn_node(id.x, id.y)
		if node == null:
			continue
		var distance := node.position.distance_to(press.position)
		if distance < best_distance:
			best_distance = distance
			best = id
	if best.x >= 0:
		accept_event()
		pawn_tapped.emit(best.x, best.y)


func _on_resized() -> void:
	_layout_pawns()
	queue_redraw()


func _rebuild_pawns() -> void:
	for id in _pawns:
		(_pawns[id] as PawnToken).queue_free()
	_pawns.clear()
	for seat in active_seats:
		for i in BoardLayout.PAWNS_PER_PLAYER:
			var pawn := PawnToken.new()
			pawn.seat = seat
			add_child(pawn)
			_pawns[Vector2i(seat, i)] = pawn
	_layout_pawns()


func _pawn_offset() -> Vector2:
	return Vector2(0, -cell_size() * 0.12)


func _grid_point_for(seat: int, pawn: int) -> Vector2:
	var p := MatchState.IN_BASE if _state == null else _state.pawn_progress(seat, pawn)
	if p == MatchState.IN_BASE:
		return BoardLayout.base_slot_points(seat)[pawn]
	return BoardLayout.progress_point(seat, p)


func _layout_pawns() -> void:
	var cs := cell_size()
	var groups := {}
	for id in _pawns:
		var point := _grid_point_for(id.x, id.y)
		if not groups.has(point):
			groups[point] = []
		groups[point].append(id)
	for point in groups:
		var members: Array = groups[point]
		var count := members.size()
		for j in count:
			var id: Vector2i = members[j]
			var node := pawn_node(id.x, id.y)
			var offset := Vector2.ZERO
			var radius := cs * 0.52
			if count > 1:
				var angle := TAU * j / count - PI / 2.0
				offset = Vector2(cos(angle), sin(angle)) * cs * 0.26
				radius = cs * 0.42
			node.position = grid_to_local(point) + offset + _pawn_offset()
			node.radius = radius


# --- Drawing ------------------------------------------------------------

func _seat_color(seat: int) -> Color:
	if active_seats.has(seat):
		return Palette.seat_color(seat)
	return Palette.inactive_seat_color(seat)


func _draw() -> void:
	var cs := cell_size()
	if cs <= 0.0:
		return
	var origin := board_origin()
	var side := cs * BoardLayout.GRID_SIZE
	var frame := Rect2(origin, Vector2(side, side)).grow(cs * 0.22)
	draw_style_box(UIKit.flat_style(Color(0, 0, 0, 0.3), int(cs * 0.6)), Rect2(frame.position + Vector2(0, cs * 0.18), frame.size))
	draw_style_box(UIKit.flat_style(Palette.BOARD_FRAME, int(cs * 0.6)), frame)
	draw_rect(Rect2(origin, Vector2(side, side)), Palette.BOARD_BG)
	for seat in BoardLayout.SEAT_COUNT:
		_draw_base(seat, cs)
	_draw_track(cs)
	_draw_home_columns(cs)
	_draw_centre(cs)


func _draw_base(seat: int, cs: float) -> void:
	var base := BoardLayout.base_rect(seat)
	var rect := Rect2(grid_to_local(Vector2(base.position)), Vector2(base.size) * cs)
	var color := _seat_color(seat)
	draw_rect(rect, color)
	draw_style_box(UIKit.flat_style(Color.WHITE, int(cs * 0.5)), rect.grow(-cs * 0.7))
	for point in BoardLayout.base_slot_points(seat):
		var centre := grid_to_local(point)
		draw_circle(centre, cs * 0.62, color.lightened(0.55))
		draw_arc(centre, cs * 0.62, 0.0, TAU, 32, color, maxf(2.0, cs * 0.1), true)


func _draw_track(cs: float) -> void:
	var track := BoardLayout.track_cells()
	for i in track.size():
		var cell: Vector2i = track[i]
		var rect := cell_rect(cell)
		var owner_seat := BoardLayout.seat_of_start_index(i)
		var fill := Color.WHITE
		if owner_seat >= 0:
			fill = _seat_color(owner_seat)
		draw_rect(rect, fill)
		draw_rect(rect, Palette.BOARD_LINE, false, maxf(1.0, cs * 0.04))
		if BoardLayout.is_safe_index(i):
			var star_color := Palette.STAR if owner_seat < 0 else Color(1, 1, 1, 0.9)
			_draw_star(rect.get_center(), cs * 0.34, star_color)
	# Arrow on each seat's last track square, pointing into its home column.
	for seat in BoardLayout.SEAT_COUNT:
		var entry := BoardLayout.track_cell(BoardLayout.home_entry_index(seat))
		var first: Vector2i = BoardLayout.home_column_cells(seat)[0]
		var direction := Vector2(first - entry)
		_draw_arrow(cell_rect(entry).get_center(), direction, cs * 0.3, _seat_color(seat))


func _draw_home_columns(cs: float) -> void:
	for seat in BoardLayout.SEAT_COUNT:
		var color := _seat_color(seat)
		for cell in BoardLayout.home_column_cells(seat):
			var rect := cell_rect(cell)
			draw_rect(rect, color)
			draw_rect(rect, Palette.BOARD_LINE, false, maxf(1.0, cs * 0.04))


func _draw_centre(cs: float) -> void:
	for seat in BoardLayout.SEAT_COUNT:
		var points := PackedVector2Array()
		for p in BoardLayout.centre_triangle(seat):
			points.append(grid_to_local(p))
		draw_colored_polygon(points, _seat_color(seat))
		points.append(points[0])
		draw_polyline(points, Color(1, 1, 1, 0.7), maxf(1.0, cs * 0.05), true)


func _draw_star(centre: Vector2, outer_radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := outer_radius if i % 2 == 0 else outer_radius * 0.45
		var angle := -PI / 2.0 + i * PI / 5.0
		points.append(centre + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)


func _draw_arrow(centre: Vector2, direction: Vector2, length: float, color: Color) -> void:
	var d := direction.normalized()
	var n := Vector2(-d.y, d.x)
	var points := PackedVector2Array([centre + d * length, centre - d * length * 0.6 + n * length * 0.75, centre - d * length * 0.6 - n * length * 0.75])
	draw_colored_polygon(points, color)
