extends "res://tests/test_case.gd"
## Classic and Snake Ludo rules (LudoRules via LocalMatch).

const FINISH := BoardLayout.FINISH_PROGRESS
const BASE := MatchState.IN_BASE


func _new_match(count: int = 4, mode_id: String = ClassicMode.ID) -> LocalMatch:
	return LocalMatch.new(MatchConfig.create(mode_id, count), Dice.new(7))


func _roll(m: LocalMatch, value: int) -> Array[GameEvent]:
	m.dice.queue_rolls([value] as Array[int])
	return m.roll()


## Moves the given pawn of the current player; fails the test if not legal.
func _move(m: LocalMatch, pawn: int) -> Array[GameEvent]:
	for candidate in m.legal_moves():
		if candidate.pawn == pawn:
			return m.move(candidate)
	fail("pawn %d has no legal move (roll %d)" % [pawn, m.state.last_roll])
	return [] as Array[GameEvent]


# --- Dice ---------------------------------------------------------------

func test_dice_rolls_one_to_six_and_every_face_appears() -> void:
	var dice := Dice.new(42)
	var seen := {}
	for i in 600:
		var value := dice.roll()
		assert_true(value >= 1 and value <= 6, "roll %d out of range" % value)
		seen[value] = true
	assert_eq(seen.size(), 6, "all six faces appear")


func test_dice_with_same_seed_repeat() -> void:
	var a := Dice.new(123)
	var b := Dice.new(123)
	for i in 20:
		assert_eq(a.roll(), b.roll(), "roll %d" % i)


func test_dice_queue_comes_first() -> void:
	var dice := Dice.new(1)
	dice.queue_rolls([6, 1, 3] as Array[int])
	assert_eq(dice.roll(), 6)
	assert_eq(dice.roll(), 1)
	assert_eq(dice.roll(), 3)


# --- Starting a pawn ----------------------------------------------------

func test_pawn_needs_a_six_to_start() -> void:
	var m := _new_match()
	var events := _roll(m, 3)
	assert_eq(GameEvent.count(events, GameEvent.Type.NO_MOVES), 1, "no moves without a six")
	assert_eq(m.state.current_seat(), 1, "turn passes to the next seat")
	assert_eq(m.state.pawn_progress(0, 0), BASE, "pawn stays in base")


func test_six_starts_a_pawn_and_gives_another_roll() -> void:
	var m := _new_match()
	_roll(m, 6)
	assert_eq(m.legal_moves().size(), 4, "any of the four pawns can start")
	var events := _move(m, 2)
	assert_eq(m.state.pawn_progress(0, 2), 0, "pawn on its start square")
	assert_eq(GameEvent.count(events, GameEvent.Type.EXTRA_TURN), 1, "six gives another roll")
	assert_eq(m.state.current_seat(), 0, "same player rolls again")
	assert_eq(m.state.phase, MatchState.Phase.AWAITING_ROLL)


func test_other_start_rolls_can_be_configured() -> void:
	var m := _new_match()
	m.rules.start_rolls = [1, 6] as Array[int]
	_roll(m, 1)
	assert_eq(m.legal_moves().size(), 4, "a one starts a pawn with this house rule")


# --- Legal movement -----------------------------------------------------

func test_pawn_moves_the_rolled_number_of_squares() -> void:
	var m := _new_match()
	m.state.set_pawn_progress(0, 0, 10)
	_roll(m, 4)
	var moves := m.legal_moves()
	assert_eq(moves.size(), 1, "only the pawn on the board can move")
	_move(m, 0)
	assert_eq(m.state.pawn_progress(0, 0), 14)
	assert_eq(m.state.current_seat(), 1, "turn passes after a normal move")


func test_moves_are_rejected_out_of_turn() -> void:
	var m := _new_match()
	m.state.set_pawn_progress(0, 0, 10)
	var events := m.move(LudoMove.new(0, 0, 10, 14))
	assert_true(events.is_empty(), "cannot move before rolling")
	_roll(m, 4)
	events = m.move(LudoMove.new(0, 1, BASE, 0))
	assert_true(events.is_empty(), "cannot move a base pawn with a four")
	assert_eq(m.state.pawn_progress(0, 0), 10, "nothing moved")


func test_exact_roll_needed_to_finish() -> void:
	var m := _new_match()
	m.state.set_pawn_progress(0, 0, 54)
	var events := _roll(m, 3)
	assert_eq(GameEvent.count(events, GameEvent.Type.NO_MOVES), 1, "a three overshoots the finish")
	m.state.turn_index = 0
	_roll(m, 2)
	_move(m, 0)
	assert_eq(m.state.pawn_progress(0, 0), FINISH, "a two finishes")


func test_exact_finish_can_be_turned_off() -> void:
	var m := _new_match()
	m.rules.exact_roll_to_finish = false
	m.state.set_pawn_progress(0, 0, 54)
	_roll(m, 5)
	_move(m, 0)
	assert_eq(m.state.pawn_progress(0, 0), FINISH, "overshoot still finishes")


# --- Home path ----------------------------------------------------------

func test_pawn_turns_into_its_home_column() -> void:
	var m := _new_match()
	m.state.set_pawn_progress(0, 0, 48)
	_roll(m, 5)
	_move(m, 0)
	assert_eq(m.state.pawn_progress(0, 0), 53, "inside the home column")
	assert_eq(BoardLayout.progress_to_track_index(0, 53), -1, "home column is off the shared track")
	assert_eq(BoardLayout.progress_point(0, 53), BoardLayout.cell_center(BoardLayout.home_column_cells(0)[2]))


func test_pawns_in_home_column_cannot_be_captured() -> void:
	var m := _new_match(2)
	# Seat 2's pawn is in its home column; seat 0 walks over the same area of the board.
	m.state.set_pawn_progress(2, 0, 52)
	m.state.set_pawn_progress(0, 0, 20)
	_roll(m, 5)
	var events := _move(m, 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.PAWN_CAPTURED), 0)
	assert_eq(m.state.pawn_progress(2, 0), 52)


# --- Captures and safe squares -----------------------------------------

func test_landing_on_an_opponent_captures_it() -> void:
	var m := _new_match()
	m.state.set_pawn_progress(1, 0, 2)  # seat 1 progress 2 = track 15
	m.state.set_pawn_progress(0, 0, 12)  # track 12
	_roll(m, 3)
	var events := _move(m, 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.PAWN_CAPTURED), 1, "one capture")
	var capture := GameEvent.first(events, GameEvent.Type.PAWN_CAPTURED)
	assert_eq(capture.data["victim_seat"], 1)
	assert_eq(capture.data["victim_pawn"], 0)
	assert_eq(m.state.pawn_progress(1, 0), BASE, "captured pawn returns to base")
	assert_eq(GameEvent.count(events, GameEvent.Type.EXTRA_TURN), 1, "capture gives another roll")
	assert_eq(m.state.current_seat(), 0)


func test_no_capture_event_without_an_opponent() -> void:
	# The Phase 3 laser plays only on PAWN_CAPTURED, so a plain move must never emit it.
	var m := _new_match()
	m.state.set_pawn_progress(0, 0, 12)
	_roll(m, 3)
	var events := _move(m, 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.PAWN_CAPTURED), 0)


func test_own_pawns_are_never_captured() -> void:
	var m := _new_match()
	m.state.set_pawn_progress(0, 1, 15)
	m.state.set_pawn_progress(0, 0, 12)
	_roll(m, 3)
	var events := _move(m, 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.PAWN_CAPTURED), 0)
	assert_eq(m.state.pawn_progress(0, 1), 15, "own pawn stays")


func test_safe_squares_protect_pawns() -> void:
	var m := _new_match()
	m.state.set_pawn_progress(1, 0, 8)  # seat 1 progress 8 = track 21, a star square
	assert_true(BoardLayout.is_safe_index(21))
	m.state.set_pawn_progress(0, 0, 18)
	_roll(m, 3)
	var events := _move(m, 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.PAWN_CAPTURED), 0, "no capture on a safe square")
	assert_eq(m.state.pawn_progress(1, 0), 8, "opponent stays")
	assert_eq(m.state.pawn_progress(0, 0), 21, "both pawns share the square")


func test_safe_squares_can_be_turned_off() -> void:
	var m := _new_match()
	m.rules.safe_squares_enabled = false
	m.state.set_pawn_progress(1, 0, 8)
	m.state.set_pawn_progress(0, 0, 18)
	_roll(m, 3)
	var events := _move(m, 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.PAWN_CAPTURED), 1)


func test_blocks_stop_opponents_when_enabled() -> void:
	var m := _new_match()
	m.state.set_pawn_progress(1, 0, 2)
	m.state.set_pawn_progress(1, 1, 2)  # two seat-1 pawns on track 15
	m.state.set_pawn_progress(0, 0, 12)
	_roll(m, 5)
	assert_eq(m.legal_moves().size(), 1, "without blocks the pawn may pass")
	var blocked := _new_match()
	blocked.rules.blocks_enabled = true
	blocked.state.set_pawn_progress(1, 0, 2)
	blocked.state.set_pawn_progress(1, 1, 2)
	blocked.state.set_pawn_progress(0, 0, 12)
	var events := _roll(blocked, 5)
	assert_eq(GameEvent.count(events, GameEvent.Type.NO_MOVES), 1, "the block cannot be passed")


# --- Turns --------------------------------------------------------------

func test_two_player_turns_alternate_between_opposite_seats() -> void:
	var m := _new_match(2)
	_roll(m, 2)
	assert_eq(m.state.current_seat(), 2)
	_roll(m, 2)
	assert_eq(m.state.current_seat(), 0)


func test_three_sixes_end_the_turn() -> void:
	var m := _new_match()
	m.state.set_pawn_progress(0, 0, 0)
	_roll(m, 6)
	_move(m, 0)
	_roll(m, 6)
	_move(m, 0)
	var events := _roll(m, 6)
	assert_eq(GameEvent.count(events, GameEvent.Type.THREE_SIXES), 1)
	assert_eq(m.state.current_seat(), 1, "turn passes")
	assert_eq(m.state.pawn_progress(0, 0), 12, "third six does not move")


# --- Winning ------------------------------------------------------------

func test_bringing_all_four_home_wins() -> void:
	var m := _new_match()
	for pawn in 3:
		m.state.set_pawn_progress(0, pawn, FINISH)
	m.state.set_pawn_progress(0, 3, 55)
	_roll(m, 1)
	var events := _move(m, 3)
	assert_eq(GameEvent.count(events, GameEvent.Type.PLAYER_FINISHED), 1)
	var over := GameEvent.first(events, GameEvent.Type.GAME_OVER)
	assert_not_null(over, "game over")
	if over != null:
		assert_eq(over.data["winner"], 0)
	assert_eq(m.state.phase, MatchState.Phase.GAME_OVER)
	assert_eq(m.ranking()[0], 0, "winner ranked first")
	assert_eq(m.ranking().size(), 4, "everyone is ranked")
	assert_true(_roll(m, 6).is_empty(), "no rolls after the game ends")


func test_three_pawns_home_is_not_a_win() -> void:
	var m := _new_match()
	for pawn in 2:
		m.state.set_pawn_progress(0, pawn, FINISH)
	m.state.set_pawn_progress(0, 2, 55)
	_roll(m, 1)
	var events := _move(m, 2)
	assert_eq(GameEvent.count(events, GameEvent.Type.PAWN_FINISHED), 1)
	assert_eq(GameEvent.count(events, GameEvent.Type.GAME_OVER), 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.EXTRA_TURN), 1, "finishing a pawn gives another roll")


func test_play_until_one_left_keeps_going() -> void:
	var m := _new_match()
	m.rules.play_until_one_left = true
	for pawn in 3:
		m.state.set_pawn_progress(0, pawn, FINISH)
	m.state.set_pawn_progress(0, 3, 55)
	_roll(m, 1)
	var events := _move(m, 3)
	assert_eq(GameEvent.count(events, GameEvent.Type.GAME_OVER), 0, "three players still racing")
	assert_eq(m.state.current_seat(), 1, "finished player is skipped")
	_roll(m, 2)
	_roll(m, 2)
	_roll(m, 2)
	assert_eq(m.state.current_seat(), 1, "seat 0 never gets another turn")


# --- Restart ------------------------------------------------------------

func test_restart_resets_everything() -> void:
	var m := _new_match()
	m.state.set_pawn_progress(0, 0, 30)
	_roll(m, 2)
	_move(m, 0)
	m.restart()
	assert_eq(m.state.current_seat(), 0, "first seat starts")
	assert_eq(m.state.phase, MatchState.Phase.AWAITING_ROLL)
	assert_true(m.state.finish_order.is_empty())
	for seat in m.state.seats:
		for pawn in BoardLayout.PAWNS_PER_PLAYER:
			assert_eq(m.state.pawn_progress(seat, pawn), BASE, "seat %d pawn %d in base" % [seat, pawn])


# --- Snake Ludo ---------------------------------------------------------

func test_snake_mouths_are_on_ordinary_squares() -> void:
	var snakes := SnakeLayout.standard()
	assert_eq(snakes.snake_count(), 4)
	for mouth in snakes.mouths:
		assert_false(BoardLayout.is_safe_index(mouth), "mouth %d is not a safe square" % mouth)
		for seat in BoardLayout.SEAT_COUNT:
			assert_true(mouth != BoardLayout.home_entry_index(seat), "mouth %d is not a home entry" % mouth)


func test_classic_mode_has_no_snakes() -> void:
	assert_true(_new_match(4, ClassicMode.ID).snakes == null)
	assert_not_null(_new_match(4, SnakeMode.ID).snakes)


func test_landing_on_a_snake_mouth_bites() -> void:
	var m := _new_match(4, SnakeMode.ID)
	assert_true(m.snakes.is_mouth(6), "snake mouth at track 6")
	m.state.set_pawn_progress(0, 0, 3)
	_roll(m, 3)
	var events := _move(m, 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.SNAKE_BITE), 1, "bitten on the mouth")
	assert_eq(m.state.pawn_progress(0, 0), BASE, "default penalty: back to base")
	assert_eq(m.state.current_seat(), 1, "turn passes")


func test_passing_over_a_snake_is_safe() -> void:
	var m := _new_match(4, SnakeMode.ID)
	m.state.set_pawn_progress(0, 0, 3)
	_roll(m, 5)
	var events := _move(m, 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.SNAKE_BITE), 0, "walking past the mouth")
	assert_eq(m.state.pawn_progress(0, 0), 8)


func test_landing_on_a_snake_body_is_safe() -> void:
	var m := _new_match(4, SnakeMode.ID)
	m.state.set_pawn_progress(0, 0, 1)
	_roll(m, 3)
	var events := _move(m, 0)
	assert_eq(m.state.pawn_progress(0, 0), 4, "track 4 is under the snake's body")
	assert_eq(GameEvent.count(events, GameEvent.Type.SNAKE_BITE), 0)


func test_same_square_does_not_bite_in_classic_mode() -> void:
	var m := _new_match(4, ClassicMode.ID)
	m.state.set_pawn_progress(0, 0, 3)
	_roll(m, 3)
	var events := _move(m, 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.SNAKE_BITE), 0)
	assert_eq(m.state.pawn_progress(0, 0), 6)


func test_snake_bite_cancels_the_extra_turn() -> void:
	var m := _new_match(4, SnakeMode.ID)
	m.state.set_pawn_progress(0, 0, 0)
	_roll(m, 6)
	var events := _move(m, 0)
	assert_eq(GameEvent.count(events, GameEvent.Type.SNAKE_BITE), 1)
	assert_eq(GameEvent.count(events, GameEvent.Type.EXTRA_TURN), 0, "no extra roll after a bite")
	assert_eq(m.state.current_seat(), 1)


func test_snake_bite_move_back_penalty() -> void:
	var m := _new_match(4, SnakeMode.ID)
	m.rules.snake_penalty = LudoRulesConfig.SnakePenalty.MOVE_BACK_STEPS
	m.rules.snake_penalty_steps = 4
	m.state.set_pawn_progress(0, 0, 3)
	_roll(m, 3)
	_move(m, 0)
	assert_eq(m.state.pawn_progress(0, 0), 2, "6 - 4 = 2")


func test_snake_bite_skip_turn_penalty() -> void:
	var m := _new_match(2, SnakeMode.ID)
	m.rules.snake_penalty = LudoRulesConfig.SnakePenalty.SKIP_NEXT_TURN
	m.state.set_pawn_progress(0, 0, 3)
	_roll(m, 3)
	_move(m, 0)
	assert_eq(m.state.pawn_progress(0, 0), 6, "pawn stays on the mouth")
	assert_eq(m.state.current_seat(), 2)
	var events := _roll(m, 2)
	assert_eq(GameEvent.count(events, GameEvent.Type.TURN_SKIPPED), 1, "seat 0 misses its turn")
	assert_eq(m.state.current_seat(), 2, "seat 2 plays again")
	_roll(m, 2)
	assert_eq(m.state.current_seat(), 0, "seat 0 is back after one missed turn")
