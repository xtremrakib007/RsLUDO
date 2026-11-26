class_name SnlEngine
extends RefCounted
## Snakes & Ladders rules as pure functions. A roll moves the pawn at once
## (there is never a choice), then a ladder or snake on the landing square applies.
## Only the landing square counts: passing a snake's head or a ladder does nothing.


static func apply_roll(state: SnlState, rules: SnlRules, board: SnlBoard, roll: int) -> Array[GameEvent]:
	var events: Array[GameEvent] = []
	if state.phase != SnlState.Phase.AWAITING_ROLL:
		push_warning("Roll ignored: the match is over.")
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

	var from := state.position_of(seat)
	var target := target_square(rules, from, roll)
	if target < 0:
		events.append(GameEvent.new(GameEvent.Type.NO_MOVES, {"seat": seat}))
	else:
		state.set_position(seat, target)
		events.append(GameEvent.new(GameEvent.Type.PAWN_MOVED, {"seat": seat, "pawn": 0, "from": from, "to": target}))
		var landed := board.destination(target)
		if landed > target:
			events.append(GameEvent.new(GameEvent.Type.LADDER_CLIMB, {"seat": seat, "from": target, "to": landed}))
		elif landed < target:
			events.append(GameEvent.new(GameEvent.Type.SNAKE_SLIDE, {"seat": seat, "from": target, "to": landed}))
		state.set_position(seat, landed)
		if landed == SnlBoard.LAST_SQUARE:
			state.finish_order.append(seat)
			state.phase = SnlState.Phase.GAME_OVER
			events.append(GameEvent.new(GameEvent.Type.PLAYER_FINISHED, {"seat": seat, "place": 1}))
			events.append(GameEvent.new(GameEvent.Type.GAME_OVER, {"winner": seat, "ranking": ranking(state)}))
			return events

	if roll == 6 and rules.extra_turn_on_six:
		events.append(GameEvent.new(GameEvent.Type.EXTRA_TURN, {"seat": seat}))
	else:
		_end_turn(state, events)
	return events


## Square a pawn would reach, or -1 if it cannot move this turn.
static func target_square(rules: SnlRules, from: int, roll: int) -> int:
	if from == SnlState.OFF_BOARD and rules.six_to_start:
		return 1 if roll == 6 else -1
	var target := from + roll
	if target > SnlBoard.LAST_SQUARE:
		if rules.exact_finish:
			return -1
		target = SnlBoard.LAST_SQUARE
	return target


## Winner first, then everyone else by how far up the board they are.
static func ranking(state: SnlState) -> Array[int]:
	var result: Array[int] = state.finish_order.duplicate()
	var rest: Array[int] = []
	for seat in state.seats:
		if not result.has(seat):
			rest.append(seat)
	rest.sort_custom(func(a: int, b: int) -> bool: return state.position_of(a) > state.position_of(b))
	result.append_array(rest)
	return result


static func _end_turn(state: SnlState, events: Array[GameEvent]) -> void:
	var from_seat := state.current_seat()
	state.consecutive_sixes = 0
	state.turn_index = (state.turn_index + 1) % state.seats.size()
	events.append(GameEvent.new(GameEvent.Type.TURN_PASSED, {"from": from_seat, "to": state.current_seat()}))
