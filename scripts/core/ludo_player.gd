class_name LudoPlayer
extends RefCounted
## One participant in a match. Online play (Phase 6) adds REMOTE players whose
## moves come from the server; the offline game only has LOCAL_HUMAN players.

enum ControlType { LOCAL_HUMAN, COMPUTER, REMOTE }

## Board seat 0..3 (see BoardLayout). The seat decides the colour.
var seat: int = 0
var display_name: String = ""
var control_type: int = ControlType.LOCAL_HUMAN


func _init(p_seat: int = 0, p_name: String = "", p_control: int = ControlType.LOCAL_HUMAN) -> void:
	seat = p_seat
	display_name = p_name
	control_type = p_control


func color() -> Color:
	return Palette.seat_color(seat)


func color_name() -> String:
	return Palette.seat_name(seat)
