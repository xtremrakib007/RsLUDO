class_name SnlBoards
extends RefCounted
## The boards players can choose from. Each layout is original to RS Ludo.
## To add a board, add one more SnlBoard.create(...) line below.


static func all() -> Array[SnlBoard]:
	var boards: Array[SnlBoard] = [
		SnlBoard.create("easy", "Easy Climb", "Lots of ladders, a few small snakes",
			{3: 22, 8: 30, 20: 41, 28: 55, 36: 57, 51: 72, 63: 84, 71: 92},
			{25: 5, 47: 26, 62: 43, 87: 66, 95: 75}),
		SnlBoard.create("classic", "Classic", "A balanced race to 100",
			{4: 25, 13: 46, 33: 49, 42: 63, 50: 69, 62: 81, 74: 92},
			{27: 5, 40: 3, 43: 18, 54: 31, 66: 45, 76: 58, 89: 53, 99: 41}),
		SnlBoard.create("long_snakes", "Long Snakes", "Big snakes near the top",
			{6: 27, 15: 37, 32: 53, 47: 68, 58: 78, 70: 91},
			{34: 12, 48: 9, 65: 24, 79: 39, 82: 38, 88: 52, 94: 56, 97: 61}),
		SnlBoard.create("ladders", "Ladder Party", "Ladders everywhere",
			{2: 19, 5: 35, 11: 29, 16: 45, 24: 44, 31: 52, 39: 60, 48: 67, 56: 77, 61: 83, 72: 93, 80: 98},
			{37: 17, 59: 41, 69: 50, 86: 64, 96: 74}),
		SnlBoard.create("tricky", "Tricky Finish", "Careful in the last rows",
			{3: 39, 10: 32, 26: 47, 44: 64, 57: 76, 67: 85},
			{21: 4, 30: 8, 46: 25, 52: 29, 62: 37, 74: 53, 87: 68, 91: 70, 93: 72, 98: 78, 99: 80}),
	]
	return boards


## Returns the first board for an unknown id.
static func get_board(board_id: String) -> SnlBoard:
	var boards := all()
	for board in boards:
		if board.id == board_id:
			return board
	return boards[0]


static func index_of(board_id: String) -> int:
	var boards := all()
	for i in boards.size():
		if boards[i].id == board_id:
			return i
	return 0
