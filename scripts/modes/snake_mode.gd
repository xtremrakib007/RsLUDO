class_name SnakeMode
extends GameMode

const ID := "snake"


func _init() -> void:
	id = ID
	title = "Snake Ludo"
	tagline = "Watch out for the snakes"
	description = "Classic Ludo with cartoon snakes on the board. Walking past a snake is fine, but stop exactly on a snake's mouth and it bites, sending your pawn back."
	accent = Palette.SNAKE_ACCENT


func default_rules() -> LudoRulesConfig:
	return LudoRulesConfig.snake()


func snake_layout() -> SnakeLayout:
	return SnakeLayout.standard()
