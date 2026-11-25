class_name ClassicMode
extends GameMode

const ID := "classic"


func _init() -> void:
	id = ID
	title = "Classic Ludo"
	tagline = "The traditional race home"
	description = "Roll the dice, bring your four pawns out and race them around the board. Land on an opponent to send them back to base. First to bring all four home wins."
	accent = Palette.CLASSIC_ACCENT


func default_rules() -> LudoRulesConfig:
	return LudoRulesConfig.classic()
