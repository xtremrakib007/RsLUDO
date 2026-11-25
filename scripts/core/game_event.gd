class_name GameEvent
extends RefCounted
## Something that happened in a match. The rules produce events; the screen
## plays them back as animations. Visual effects (like the Phase 3 capture laser)
## are triggered only by these events, never by guessing from positions.

enum Type {
	ROLLED,           # {seat, value}
	NO_MOVES,         # {seat}
	THREE_SIXES,      # {seat}
	PAWN_MOVED,       # {seat, pawn, from, to}
	PAWN_CAPTURED,    # {seat, pawn, victim_seat, victim_pawn, track_index}
	SNAKE_BITE,       # {seat, pawn, track_index, from, to, penalty}
	PAWN_FINISHED,    # {seat, pawn}
	PLAYER_FINISHED,  # {seat, place}
	EXTRA_TURN,       # {seat}
	TURN_SKIPPED,     # {seat}
	TURN_PASSED,      # {from, to}
	GAME_OVER,        # {winner, ranking}
}

var type: int
var data: Dictionary


func _init(p_type: int = Type.ROLLED, p_data: Dictionary = {}) -> void:
	type = p_type
	data = p_data


static func count(events: Array[GameEvent], event_type: int) -> int:
	var n := 0
	for event in events:
		if event.type == event_type:
			n += 1
	return n


static func first(events: Array[GameEvent], event_type: int) -> GameEvent:
	for event in events:
		if event.type == event_type:
			return event
	return null


func _to_string() -> String:
	return "%s %s" % [Type.keys()[type], data]
