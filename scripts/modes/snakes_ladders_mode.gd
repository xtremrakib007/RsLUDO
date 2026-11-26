class_name SnakesLaddersMode
extends GameMode
## Traditional Snakes & Ladders on a 100-square board, one pawn per player.

const ID := "snakes_ladders"


func _init() -> void:
	id = ID
	title = "Snakes & Ladders"
	tagline = "Climb up, slide down, reach 100"
	description = "Roll and walk your character from 1 to 100. Land at the bottom of a ladder to climb up; land on a snake's head and slide down to its tail. First to reach 100 exactly wins."
	accent = Palette.SNAKE_ACCENT
	game_screen = "snl_game"
	has_board_choice = true


func rules_summary(config: MatchConfig) -> PackedStringArray:
	var lines := PackedStringArray(["Board: %s" % SnlBoards.get_board(config.board_id).title])
	lines.append_array(config.snl_rules.summary())
	return lines
