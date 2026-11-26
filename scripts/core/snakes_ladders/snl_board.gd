class_name SnlBoard
extends RefCounted
## One Snakes & Ladders board: 100 numbered squares plus where its snakes and
## ladders are. Square 1 is bottom-left; rows alternate direction ("boustrophedon"),
## so 10 is bottom-right, 11 is above it, and 100 is top-left.

const SIZE := 10
const LAST_SQUARE := 100

var id: String = ""
var title: String = ""
var tagline: String = ""
## Snake head square -> tail square (head is higher).
var snakes: Dictionary = {}
## Ladder bottom square -> top square.
var ladders: Dictionary = {}


static func create(p_id: String, p_title: String, p_tagline: String, p_ladders: Dictionary, p_snakes: Dictionary) -> SnlBoard:
	var board := SnlBoard.new()
	board.id = p_id
	board.title = p_title
	board.tagline = p_tagline
	board.ladders = p_ladders.duplicate()
	board.snakes = p_snakes.duplicate()
	return board


## Grid cell (column, row from the top) of a square 1..100.
static func cell_of(square: int) -> Vector2i:
	var index := clampi(square, 1, LAST_SQUARE) - 1
	var row_from_bottom := floori(float(index) / SIZE)
	var column := index % SIZE
	if row_from_bottom % 2 == 1:
		column = SIZE - 1 - column
	return Vector2i(column, SIZE - 1 - row_from_bottom)


## Where a pawn ends up after stopping on `square` (ladder top, snake tail, or the square itself).
func destination(square: int) -> int:
	if ladders.has(square):
		return int(ladders[square])
	if snakes.has(square):
		return int(snakes[square])
	return square


## Human-readable problems; empty when the board is playable.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	var used := {}
	for bottom in ladders:
		var top := int(ladders[bottom])
		if int(bottom) >= top:
			problems.append("Ladder %d -> %d must go up." % [bottom, top])
	for head in snakes:
		var tail := int(snakes[head])
		if int(head) <= tail:
			problems.append("Snake %d -> %d must go down." % [head, tail])
	for pair in [ladders, snakes]:
		for start in pair:
			for square in [int(start), int(pair[start])]:
				if square <= 1 or square >= LAST_SQUARE:
					problems.append("Square %d cannot hold a snake or ladder end." % square)
				if used.has(square):
					problems.append("Square %d is used twice." % square)
				used[square] = true
	return problems
