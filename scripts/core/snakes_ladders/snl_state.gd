class_name SnlState
extends RefCounted
## A Snakes & Ladders match in progress. Each player has one pawn.
## Position 0 means "not on the board yet"; 1..100 are squares.

enum Phase { AWAITING_ROLL, GAME_OVER }

const OFF_BOARD := 0

var seats: Array[int] = []
## seat -> square (0..100)
var positions: Dictionary = {}
var turn_index: int = 0
var phase: int = Phase.AWAITING_ROLL
var last_roll: int = 0
var consecutive_sixes: int = 0
var finish_order: Array[int] = []


static func create(p_seats: Array[int]) -> SnlState:
	var state := SnlState.new()
	state.seats = p_seats.duplicate()
	for seat in state.seats:
		state.positions[seat] = OFF_BOARD
	return state


func current_seat() -> int:
	return seats[turn_index]


func position_of(seat: int) -> int:
	return positions[seat]


func set_position(seat: int, square: int) -> void:
	positions[seat] = square
