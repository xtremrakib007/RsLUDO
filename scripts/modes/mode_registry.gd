class_name ModeRegistry
extends RefCounted
## Lists the available game modes. Add new modes here.


static func all_modes() -> Array[GameMode]:
	var modes: Array[GameMode] = [ClassicMode.new(), SnakesLaddersMode.new()]
	return modes


## Returns null for an unknown id.
static func get_mode(mode_id: String) -> GameMode:
	for mode in all_modes():
		if mode.id == mode_id:
			return mode
	return null
