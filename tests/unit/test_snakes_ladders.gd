extends "res://tests/test_case.gd"
## Snakes & Ladders boards and rules.


## A small fixed board for rule tests: ladder 4 -> 14, snake 17 -> 7.
func _test_board() -> SnlBoard:
	return SnlBoard.create("test", "Test", "", {4: 14}, {17: 7})


func _new_match(count: int = 2) -> SnlMatch:
	var m := SnlMatch.new(MatchConfig.create(SnakesLaddersMode.ID, count), Dice.new(5))
	m.board = _test_board()
	return m


func _roll(m: SnlMatch, value: int) -> Array[GameEvent]:
	m.dice.queue_rolls([value] as Array[int])
	return m.roll()


# --- Board --------------------------------------------------------------

func test_squares_snake_back_and_forth() -> void:
	assert_eq(SnlBoard.cell_of(1), Vector2i(0, 9), "1 is bottom-left")
	assert_eq(SnlBoard.cell_of(10), Vector2i(9, 9), "10 is bottom-right")
	assert_eq(SnlBoard.cell_of(11), Vector2i(9, 8), "11 is above 10")
	assert_eq(SnlBoard.cell_of(20), Vector2i(0, 8), "20 is above 1")
	assert_eq(SnlBoard.cell_of(91), Vector2i(9, 0), "91 is top-right")
	assert_eq(SnlBoard.cell_of(100), Vector2i(0, 0), "100 is top-left")
	var seen := {}
	for square in range(1, 101):
		seen[SnlBoard.cell_of(square)] = true
	assert_eq(seen.size(), 100, "every square has its own cell")


func test_there_are_five_valid_boards() -> void:
	var boards := SnlBoards.all()
	assert_eq(boards.size(), 5, "five boards")
	var ids := {}
	for board in boards:
		assert_true(board.validate().is_empty(), "%s: %s" % [board.id, ", ".join(board.validate())])
		assert_true(board.ladders.size() >= 5, "%s has ladders" % board.id)
		assert_true(board.snakes.size() >= 5, "%s has snakes" % board.id)
		assert_false(board.title.is_empty(), "%s has a title" % board.id)
		ids[board.id] = true
	assert_eq(ids.size(), 5, "board ids are unique")
	assert_eq(SnlBoards.get_board("unknown").id, boards[0].id, "unknown id falls back to the first board")


func test_invalid_boards_are_reported() -> void:
	var bad := SnlBoard.create("bad", "Bad", "", {10: 5, 20: 30}, {30: 40, 100: 2})
	assert_true(bad.validate().size() >= 4, "downward ladder, upward snake, reused square, snake on 100")


# --- Moving -------------------------------------------------------------

func test_pawns_start_off_the_board_and_walk_the_roll() -> void:
	var m := _new_match()
	assert_eq(m.state.position_of(0), SnlState.OFF_BOARD)
	var events := _roll(m, 3)
	assert_eq(m.state.position_of(0), 3, "a three goes to square 3")
	var moved := GameEvent.first(events, GameEvent.Type.PAWN_MOVED)
	assert_eq(moved.data["from"], 0)
	assert_eq(moved.data["to"], 3)
	assert_eq(m.state.current_seat(), 2, "turn passes to the other player")


func test_ladder_bottom_climbs_to_the_top() -> void:
	var m := _new_match()
	var events := _roll(m, 4)
	assert_eq(GameEvent.count(events, GameEvent.Type.LADDER_CLIMB), 1)
	assert_eq(m.state.position_of(0), 14, "climbed 4 -> 14")


func test_snake_head_slides_to_the_tail() -> void:
	var m := _new_match()
	m.state.set_position(0, 14)
	var events := _roll(m, 3)
	assert_eq(GameEvent.count(events, GameEvent.Type.SNAKE_SLIDE), 1)
	assert_eq(m.state.position_of(0), 7, "slid 17 -> 7")


func test_passing_a_snake_head_is_safe() -> void:
	var m := _new_match()
	m.state.set_position(0, 15)
	var events := _roll(m, 4)
	assert_eq(GameEvent.count(events, GameEvent.Type.SNAKE_SLIDE), 0, "walked past 17")
	assert_eq(m.state.position_of(0), 19)


func test_landing_on_a_snake_tail_or_ladder_top_does_nothing() -> void:
	var m := _new_match()
	m.state.set_position(0, 5)
	var events := _roll(m, 2)
	assert_eq(m.state.position_of(0), 7, "snake tail")
	assert_eq(events.size(), 3, "rolled, moved, turn passed")
	m.state.set_position(2, 10)
	events = _roll(m, 4)
	assert_eq(m.state.position_of(2), 14, "ladder top")
	assert_eq(GameEvent.count(events, GameEvent.Type.LADDER_CLIMB), 0)


func test_six_gives_another_roll() -> void:
	var m := _new_match()
	var events := _roll(m, 6)
	assert_eq(GameEvent.count(events, GameEvent.Type.EXTRA_TURN), 1)
	assert_eq(m.state.current_seat(), 0)


func test_three_sixes_end_the_turn() -> void:
	var m := _new_match()
	_roll(m, 6)
	_roll(m, 6)
	var events := _roll(m, 6)
	assert_eq(GameEvent.count(events, GameEvent.Type.THREE_SIXES), 1)
	assert_eq(m.state.position_of(0), 12, "third six does not move")
	assert_eq(m.state.current_seat(), 2)


func test_six_to_start_house_rule() -> void:
	var m := _new_match()
	m.rules.six_to_start = true
	var events := _roll(m, 4)
	assert_eq(GameEvent.count(events, GameEvent.Type.NO_MOVES), 1, "needs a six")
	assert_eq(m.state.position_of(0), SnlState.OFF_BOARD)
	_roll(m, 2)
	_roll(m, 6)
	assert_eq(m.state.position_of(0), 1, "a six puts the pawn on square 1")


# --- Winning ------------------------------------------------------------

func test_exact_roll_needed_for_100() -> void:
	var m := _new_match()
	m.state.set_position(0, 97)
	var events := _roll(m, 5)
	assert_eq(GameEvent.count(events, GameEvent.Type.NO_MOVES), 1, "a five overshoots")
	assert_eq(m.state.position_of(0), 97, "stays on 97")
	_roll(m, 1)
	events = _roll(m, 3)
	assert_eq(m.state.position_of(0), 100)
	var over := GameEvent.first(events, GameEvent.Type.GAME_OVER)
	assert_not_null(over, "reaching 100 wins")
	if over != null:
		assert_eq(over.data["winner"], 0)
	assert_eq(m.state.phase, SnlState.Phase.GAME_OVER)
	assert_true(_roll(m, 2).is_empty(), "no rolls after the game ends")


func test_ranking_orders_by_progress() -> void:
	var m := _new_match(4)
	m.state.set_position(1, 40)
	m.state.set_position(2, 60)
	m.state.set_position(3, 20)
	m.state.set_position(0, 98)
	_roll(m, 2)
	assert_eq(m.ranking(), [0, 2, 1, 3] as Array[int])


func test_restart_puts_everyone_back_at_start() -> void:
	var m := _new_match(4)
	_roll(m, 5)
	_roll(m, 3)
	m.restart()
	for seat in m.state.seats:
		assert_eq(m.state.position_of(seat), SnlState.OFF_BOARD)
	assert_eq(m.state.current_seat(), 0)
	assert_eq(m.state.phase, SnlState.Phase.AWAITING_ROLL)


func test_real_boards_apply_their_ladders_and_snakes() -> void:
	for board in SnlBoards.all():
		for bottom in board.ladders:
			assert_eq(board.destination(int(bottom)), int(board.ladders[bottom]), "%s ladder %d" % [board.id, bottom])
		for head in board.snakes:
			assert_eq(board.destination(int(head)), int(board.snakes[head]), "%s snake %d" % [board.id, head])
		assert_eq(board.destination(100), 100)
