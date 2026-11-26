class_name LudoMove
extends RefCounted
## One legal move: pawn `pawn` of `seat` goes from progress `from` to `to`.

var seat: int
var pawn: int
var from: int
var to: int


func _init(p_seat: int = 0, p_pawn: int = 0, p_from: int = 0, p_to: int = 0) -> void:
	seat = p_seat
	pawn = p_pawn
	from = p_from
	to = p_to


func is_start() -> bool:
	return from == MatchState.IN_BASE


func _to_string() -> String:
	return "Move(seat %d pawn %d: %d -> %d)" % [seat, pawn, from, to]
