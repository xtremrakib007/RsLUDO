class_name SnakeLayout
extends RefCounted
## Where the snakes lie on the Snake Ludo board.
## Only the mouth square matters to the rules: a pawn that stops exactly on a
## mouth is bitten. The body squares are decoration; walking over them is safe.

## Track index of each snake's mouth.
var mouths: Array[int] = []
## For each snake, the track squares its body lies over (tail first).
var bodies: Array = []
var colors: Array[Color] = []


## One snake per quarter, same position in each, so every seat faces the same board.
static func standard() -> SnakeLayout:
	var layout := SnakeLayout.new()
	for quarter in BoardLayout.SEAT_COUNT:
		var base := quarter * BoardLayout.SEGMENT_LENGTH
		var body: Array[int] = [base + 3, base + 4, base + 5]
		layout.add_snake(base + 6, body, Palette.snake_color(quarter))
	return layout


func add_snake(mouth: int, body: Array[int], color: Color) -> void:
	mouths.append(posmod(mouth, BoardLayout.TRACK_LENGTH))
	bodies.append(body.duplicate())
	colors.append(color)


func is_mouth(track_index: int) -> bool:
	return mouths.has(posmod(track_index, BoardLayout.TRACK_LENGTH))


func snake_count() -> int:
	return mouths.size()
