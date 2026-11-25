class_name LudoRules
extends RefCounted
## The Ludo rules as pure functions over MatchState. No nodes, drawing or timing.
## Every rule option comes from LudoRulesConfig. Snake Ludo passes a SnakeLayout.


## Where a pawn at `from` would go with `roll`, or -2 if it cannot move.
static func target_progress(rules: LudoRulesConfig, from: int, roll: int) -> int:
	if from == MatchState.IN_BASE:
		return 0 if rules.start_rolls.has(roll) else -2
	if from >= BoardLayout.FINISH_PROGRESS:
		return -2
	var to := from + roll
	if to > BoardLayout.FINISH_PROGRESS:
		if rules.exact_roll_to_finish:
			return -2
		to = BoardLayout.FINISH_PROGRESS
	return to


static func legal_moves(state: MatchState, rules: LudoRulesConfig, roll: int) -> Array[LudoMove]:
	var moves: Array[LudoMove] = []
	if state.phase == MatchState.Phase.GAME_OVER:
		return moves
	var seat := state.current_seat()
	for pawn in BoardLayout.PAWNS_PER_PLAYER:
		var from := state.pawn_progress(seat, pawn)
		var to := target_progress(rules, from, roll)
		if to < 0:
			continue
		if rules.blocks_enabled and _path_blocked(state, seat, from, to):
			continue
		moves.append(LudoMove.new(seat, pawn, from, to))
	return moves


## Records a dice roll for the current player.
static func apply_roll(state: MatchState, rules: LudoRulesConfig, roll: int) -> Array[GameEvent]:
	var events: Array[GameEvent] = []
	if state.phase != MatchState.Phase.AWAITING_ROLL:
		push_warning("Roll ignored: not waiting for a roll.")
		return events
	var seat := state.current_seat()
	state.last_roll = roll
	events.append(GameEvent.new(GameEvent.Type.ROLLED, {"seat": seat, "value": roll}))
	if roll == 6:
		state.consecutive_sixes += 1
	else:
		state.consecutive_sixes = 0
	if roll == 6 and rules.max_consecutive_sixes > 0 and state.consecutive_sixes >= rules.max_consecutive_sixes:
		events.append(GameEvent.new(GameEvent.Type.THREE_SIXES, {"seat": seat}))
		_end_turn(state, events)
		return events
	if legal_moves(state, rules, roll).is_empty():
		events.append(GameEvent.new(GameEvent.Type.NO_MOVES, {"seat": seat}))
		_end_turn(state, events)
		return events
	state.phase = MatchState.Phase.AWAITING_MOVE
	return events


## Moves a pawn. Only a move from legal_moves() is accepted.
static func apply_move(state: MatchState, rules: LudoRulesConfig, move: LudoMove, snakes: SnakeLayout = null) -> Array[GameEvent]:
	var events: Array[GameEvent] = []
	if state.phase != MatchState.Phase.AWAITING_MOVE:
		push_warning("Move ignored: not waiting for a move.")
		return events
	var chosen: LudoMove = null
	for legal in legal_moves(state, rules, state.last_roll):
		if legal.seat == move.seat and legal.pawn == move.pawn:
			chosen = legal
	if chosen == null:
		push_warning("Move ignored: %s is not legal." % move)
		return events

	var seat := chosen.seat
	var pawn := chosen.pawn
	state.set_pawn_progress(seat, pawn, chosen.to)
	events.append(GameEvent.new(GameEvent.Type.PAWN_MOVED, {"seat": seat, "pawn": pawn, "from": chosen.from, "to": chosen.to}))

	var extra_turn := state.last_roll == 6 and rules.extra_turn_on_six
	var bitten := false
	var track_index := BoardLayout.progress_to_track_index(seat, chosen.to)
	if track_index >= 0:
		if rules.snakes_enabled and snakes != null and snakes.is_mouth(track_index):
			bitten = true
			_apply_snake_bite(state, rules, seat, pawn, track_index, events)
		elif _capture(state, rules, seat, pawn, track_index, events) and rules.extra_turn_on_capture:
			extra_turn = true

	if chosen.to == BoardLayout.FINISH_PROGRESS:
		events.append(GameEvent.new(GameEvent.Type.PAWN_FINISHED, {"seat": seat, "pawn": pawn}))
		if rules.extra_turn_on_finish:
			extra_turn = true
		if state.has_finished(seat):
			state.finish_order.append(seat)
			events.append(GameEvent.new(GameEvent.Type.PLAYER_FINISHED, {"seat": seat, "place": state.finish_order.size()}))
			if _is_game_over(state, rules):
				state.phase = MatchState.Phase.GAME_OVER
				events.append(GameEvent.new(GameEvent.Type.GAME_OVER, {"winner": state.finish_order[0], "ranking": ranking(state)}))
				return events
			extra_turn = false

	if bitten:
		extra_turn = false
	if extra_turn:
		state.phase = MatchState.Phase.AWAITING_ROLL
		events.append(GameEvent.new(GameEvent.Type.EXTRA_TURN, {"seat": seat}))
	else:
		_end_turn(state, events)
	return events


## Finished players first (in finishing order), then the rest by progress.
static func ranking(state: MatchState) -> Array[int]:
	var result: Array[int] = state.finish_order.duplicate()
	var rest: Array[int] = []
	for seat in state.seats:
		if not result.has(seat):
			rest.append(seat)
	rest.sort_custom(func(a: int, b: int) -> bool: return state.score(a) > state.score(b))
	result.append_array(rest)
	return result


static func _is_game_over(state: MatchState, rules: LudoRulesConfig) -> bool:
	if not rules.play_until_one_left:
		return true
	return state.seats.size() - state.finish_order.size() <= 1


## Sends opponents on this square back to base. Returns true if anyone was captured.
static func _capture(state: MatchState, rules: LudoRulesConfig, seat: int, pawn: int, track_index: int, events: Array[GameEvent]) -> bool:
	if rules.safe_squares_enabled and BoardLayout.is_safe_index(track_index):
		return false
	var captured := false
	for occupant in state.pawns_at_track_index(track_index):
		if occupant.x == seat:
			continue
		state.set_pawn_progress(occupant.x, occupant.y, MatchState.IN_BASE)
		events.append(GameEvent.new(GameEvent.Type.PAWN_CAPTURED, {
			"seat": seat, "pawn": pawn, "victim_seat": occupant.x, "victim_pawn": occupant.y, "track_index": track_index,
		}))
		captured = true
	return captured


static func _apply_snake_bite(state: MatchState, rules: LudoRulesConfig, seat: int, pawn: int, track_index: int, events: Array[GameEvent]) -> void:
	var from := state.pawn_progress(seat, pawn)
	var to := from
	match rules.snake_penalty:
		LudoRulesConfig.SnakePenalty.RETURN_TO_BASE:
			to = MatchState.IN_BASE
		LudoRulesConfig.SnakePenalty.MOVE_BACK_STEPS:
			to = maxi(0, from - rules.snake_penalty_steps)
		LudoRulesConfig.SnakePenalty.SKIP_NEXT_TURN:
			state.skip_turns[seat] = int(state.skip_turns.get(seat, 0)) + 1
	state.set_pawn_progress(seat, pawn, to)
	events.append(GameEvent.new(GameEvent.Type.SNAKE_BITE, {
		"seat": seat, "pawn": pawn, "track_index": track_index, "from": from, "to": to, "penalty": rules.snake_penalty,
	}))


## True if an opponent block (2+ pawns of one colour) stands on a square the pawn would step on.
static func _path_blocked(state: MatchState, seat: int, from: int, to: int) -> bool:
	var first := 0 if from == MatchState.IN_BASE else from + 1
	for p in range(first, mini(to, BoardLayout.LAST_TRACK_PROGRESS) + 1):
		var track_index := BoardLayout.progress_to_track_index(seat, p)
		var counts := {}
		for occupant in state.pawns_at_track_index(track_index):
			if occupant.x != seat:
				counts[occupant.x] = int(counts.get(occupant.x, 0)) + 1
		for rival in counts:
			if int(counts[rival]) >= 2:
				return true
	return false


static func _end_turn(state: MatchState, events: Array[GameEvent]) -> void:
	var from_seat := state.current_seat()
	state.consecutive_sixes = 0
	state.phase = MatchState.Phase.AWAITING_ROLL
	var count := state.seats.size()
	for i in count:
		state.turn_index = (state.turn_index + 1) % count
		var seat := state.current_seat()
		if state.finish_order.has(seat):
			continue
		var skips := int(state.skip_turns.get(seat, 0))
		if skips > 0:
			state.skip_turns[seat] = skips - 1
			events.append(GameEvent.new(GameEvent.Type.TURN_SKIPPED, {"seat": seat}))
			continue
		break
	events.append(GameEvent.new(GameEvent.Type.TURN_PASSED, {"from": from_seat, "to": state.current_seat()}))
