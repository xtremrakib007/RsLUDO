class_name MatchState
extends RefCounted
## Plain data describing a match in progress. Changed only by LudoRules.
## Pawn positions are seat-relative progress values (see BoardLayout):
## IN_BASE (-1), 0..50 track, 51..55 home column, 56 finished.

enum Phase { AWAITING_ROLL, AWAITING_MOVE, GAME_OVER }

const IN_BASE := -1

var seats: Array[int] = []
## seat -> Array of 4 progress values.
var progress: Dictionary = {}
var turn_index: int = 0
var phase: int = Phase.AWAITING_ROLL
var last_roll: int = 0
var consecutive_sixes: int = 0
## Seats in the order they brought all four pawns home.
var finish_order: Array[int] = []


static func create(p_seats: Array[int]) -> MatchState:
	var state := MatchState.new()
	state.seats = p_seats.duplicate()
	for seat in state.seats:
		var pawns: Array = []
		for i in BoardLayout.PAWNS_PER_PLAYER:
			pawns.append(IN_BASE)
		state.progress[seat] = pawns
	return state


func current_seat() -> int:
	return seats[turn_index]


func pawn_progress(seat: int, pawn: int) -> int:
	return progress[seat][pawn]


func set_pawn_progress(seat: int, pawn: int, value: int) -> void:
	progress[seat][pawn] = value


func pawns_finished(seat: int) -> int:
	var count := 0
	for i in BoardLayout.PAWNS_PER_PLAYER:
		if pawn_progress(seat, i) == BoardLayout.FINISH_PROGRESS:
			count += 1
	return count


func has_finished(seat: int) -> bool:
	return pawns_finished(seat) == BoardLayout.PAWNS_PER_PLAYER


## Pawns standing on a main-track square, as Vector2i(seat, pawn).
func pawns_at_track_index(track_index: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for seat in seats:
		for i in BoardLayout.PAWNS_PER_PLAYER:
			var p := pawn_progress(seat, i)
			if BoardLayout.progress_to_track_index(seat, p) == track_index:
				result.append(Vector2i(seat, i))
	return result


## Higher is closer to winning. Used to rank players who did not finish.
func score(seat: int) -> int:
	var total := 0
	for i in BoardLayout.PAWNS_PER_PLAYER:
		total += pawn_progress(seat, i) + 1
	return total
