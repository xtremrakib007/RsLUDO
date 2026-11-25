class_name GameMode
extends RefCounted
## Describes a game mode: identity, presentation and default rules.
## Both modes share one Ludo engine (Phase 2); a mode only changes rules data
## and adds its own board features (for Snake Ludo, the snakes in Phase 4).

var id: String = ""
var title: String = ""
var tagline: String = ""
var description: String = ""
var accent: Color = Color.WHITE


func default_rules() -> LudoRulesConfig:
	return LudoRulesConfig.classic()


## Snakes on the board for this mode, or null for none.
func snake_layout() -> SnakeLayout:
	return null
