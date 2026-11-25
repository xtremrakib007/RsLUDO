class_name PawnPreview
extends Control
## Shows one pawn character inside normal UI layouts (lobby, welcome screen).

var seat: int = 0
var _token: PawnToken


func _init(p_seat: int = 0) -> void:
	seat = p_seat
	custom_minimum_size = Vector2(88, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_token = PawnToken.new()
	_token.seat = seat
	add_child(_token)
	resized.connect(_place)
	_place()


func _place() -> void:
	_token.radius = minf(size.x, size.y) * 0.4
	_token.position = size * 0.5
