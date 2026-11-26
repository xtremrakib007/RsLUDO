class_name GameMode
extends RefCounted
## Describes a game mode: identity, presentation and default rules.
## `game_screen` is the screen that plays the mode; Ludo and Snakes & Ladders
## have separate rules engines and boards but share dice, players and screens.

var id: String = ""
var title: String = ""
var tagline: String = ""
var description: String = ""
var accent: Color = Color.WHITE
## Screen id (SceneRouter) that plays this mode.
var game_screen: String = "game"
## True when players pick a board before the lobby (Snakes & Ladders).
var has_board_choice: bool = false


func default_rules() -> LudoRulesConfig:
	return LudoRulesConfig.classic()


## Short rule lines for the lobby.
func rules_summary(config: MatchConfig) -> PackedStringArray:
	return config.rules.summary()

