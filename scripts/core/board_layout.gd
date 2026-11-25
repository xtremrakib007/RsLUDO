class_name BoardLayout
extends RefCounted
## Pure geometry of the 15 x 15 Ludo board. No drawing and no game state.
##
## Grid cells are Vector2i(column, row) with (0, 0) at the top-left.
## Continuous "grid points" are Vector2 in the same units (a cell's centre is cell + 0.5).
##
## Seats go clockwise: 0 = top-left base, 1 = top-right, 2 = bottom-right, 3 = bottom-left.
## Pawns move clockwise. A pawn's "progress" counts steps from its own start square:
##   0..50  main track (51 squares)
##   51..55 its home column (5 squares)
##   56     finish (centre)
## The board is four identical quarters, so every seat's geometry is seat 0's
## geometry rotated by `seat` quarter turns.

const GRID_SIZE := 15
const SEAT_COUNT := 4
const TRACK_LENGTH := 52
const SEGMENT_LENGTH := 13
const HOME_COLUMN_LENGTH := 5
const PAWNS_PER_PLAYER := 4
const LAST_TRACK_PROGRESS := 50
const FINISH_PROGRESS := 56
## Track squares after a start square that are also safe (the "star" squares).
const STAR_OFFSET := 8

## Seat 0's quarter of the track, beginning at its start square, in walking order.
const _SEAT0_SEGMENT := [
	Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6),
	Vector2i(6, 5), Vector2i(6, 4), Vector2i(6, 3), Vector2i(6, 2), Vector2i(6, 1), Vector2i(6, 0),
	Vector2i(7, 0), Vector2i(8, 0),
]
const _SEAT0_HOME_COLUMN := [
	Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7),
]
const _SEAT0_BASE_SLOTS := [Vector2(2, 2), Vector2(4, 2), Vector2(4, 4), Vector2(2, 4)]
const _SEAT0_CENTRE_TRIANGLE := [Vector2(6, 6), Vector2(7.5, 7.5), Vector2(6, 9)]
const _SEAT0_FINISH_POINT := Vector2(6.55, 7.5)
const _BASE_ORIGINS := [Vector2i(0, 0), Vector2i(9, 0), Vector2i(9, 9), Vector2i(0, 9)]
const BASE_SIZE := 6
const CENTRE_RECT := Rect2i(6, 6, 3, 3)


## Rotates a cell clockwise (on screen) around the board centre.
static func rotate_cell(cell: Vector2i, quarter_turns: int) -> Vector2i:
	var c := cell
	for i in posmod(quarter_turns, 4):
		c = Vector2i(GRID_SIZE - 1 - c.y, c.x)
	return c


## Rotates a continuous grid point clockwise (on screen) around the board centre.
static func rotate_point(point: Vector2, quarter_turns: int) -> Vector2:
	var p := point
	for i in posmod(quarter_turns, 4):
		p = Vector2(GRID_SIZE - p.y, p.x)
	return p


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) + Vector2(0.5, 0.5)


static func is_valid_seat(seat: int) -> bool:
	return seat >= 0 and seat < SEAT_COUNT


## The 52 track squares in walking order; index 0 is seat 0's start square.
static func track_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for seat in SEAT_COUNT:
		for cell in _SEAT0_SEGMENT:
			cells.append(rotate_cell(cell, seat))
	return cells


static func track_cell(index: int) -> Vector2i:
	var i := posmod(index, TRACK_LENGTH)
	var quarter := floori(float(i) / SEGMENT_LENGTH)
	var base_cell: Vector2i = _SEAT0_SEGMENT[i % SEGMENT_LENGTH]
	return rotate_cell(base_cell, quarter)


static func start_index(seat: int) -> int:
	return seat * SEGMENT_LENGTH


## Returns the seat whose start square is at this track index, or -1.
static func seat_of_start_index(index: int) -> int:
	var i := posmod(index, TRACK_LENGTH)
	if i % SEGMENT_LENGTH == 0:
		return floori(float(i) / SEGMENT_LENGTH)
	return -1


## The last track square a seat walks on before turning into its home column.
static func home_entry_index(seat: int) -> int:
	return posmod(start_index(seat) + LAST_TRACK_PROGRESS, TRACK_LENGTH)


## Safe squares: every start square and the star square 8 steps after it.
static func safe_track_indices() -> Array[int]:
	var indices: Array[int] = []
	for seat in SEAT_COUNT:
		indices.append(start_index(seat))
		indices.append(start_index(seat) + STAR_OFFSET)
	indices.sort()
	return indices


static func is_safe_index(index: int) -> bool:
	return safe_track_indices().has(posmod(index, TRACK_LENGTH))


static func home_column_cells(seat: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in _SEAT0_HOME_COLUMN:
		cells.append(rotate_cell(cell, seat))
	return cells


static func base_rect(seat: int) -> Rect2i:
	var origin: Vector2i = _BASE_ORIGINS[seat]
	return Rect2i(origin, Vector2i(BASE_SIZE, BASE_SIZE))


## Where the four pawns of a seat wait inside their base (grid points).
static func base_slot_points(seat: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for p in _SEAT0_BASE_SLOTS:
		points.append(rotate_point(p, seat))
	return points


## The coloured triangle in the centre that a seat's pawns finish on.
static func centre_triangle(seat: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for p in _SEAT0_CENTRE_TRIANGLE:
		points.append(rotate_point(p, seat))
	return points


static func finish_point(seat: int) -> Vector2:
	return rotate_point(_SEAT0_FINISH_POINT, seat)


static func is_centre_cell(cell: Vector2i) -> bool:
	return CENTRE_RECT.has_point(cell)


static func is_valid_progress(progress: int) -> bool:
	return progress >= 0 and progress <= FINISH_PROGRESS


## Converts a seat-relative progress (0..56) to a track index, or -1 when the pawn
## is in its home column or finished.
static func progress_to_track_index(seat: int, progress: int) -> int:
	if progress < 0 or progress > LAST_TRACK_PROGRESS:
		return -1
	return posmod(start_index(seat) + progress, TRACK_LENGTH)


## Grid point (centre of the square) for a seat's pawn at the given progress.
static func progress_point(seat: int, progress: int) -> Vector2:
	assert(is_valid_progress(progress), "progress out of range: %d" % progress)
	if progress <= LAST_TRACK_PROGRESS:
		return cell_center(track_cell(start_index(seat) + progress))
	if progress < FINISH_PROGRESS:
		return cell_center(home_column_cells(seat)[progress - LAST_TRACK_PROGRESS - 1])
	return finish_point(seat)
