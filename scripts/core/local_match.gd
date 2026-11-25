class_name LocalMatch
extends RefCounted
## An offline match: owns the state, dice and rules for one game on this device.
## Online matches (Phase 6) will get the same events from the server instead.

var config: MatchConfig
var rules: LudoRulesConfig
var dice: Dice
var snakes: SnakeLayout = null
var state: MatchState


func _init(p_config: MatchConfig, p_dice: Dice = null) -> void:
	config = p_config
	rules = config.rules
	dice = p_dice if p_dice != null else Dice.new()
	var mode := ModeRegistry.get_mode(config.mode_id)
	if rules.snakes_enabled and mode != null:
		snakes = mode.snake_layout()
	restart()


## Puts every pawn back in its base and gives the first turn to the first seat.
func restart() -> void:
	state = MatchState.create(config.seats())


func roll() -> Array[GameEvent]:
	return LudoRules.apply_roll(state, rules, dice.roll())


func legal_moves() -> Array[LudoMove]:
	if state.phase != MatchState.Phase.AWAITING_MOVE:
		return [] as Array[LudoMove]
	return LudoRules.legal_moves(state, rules, state.last_roll)


func move(chosen: LudoMove) -> Array[GameEvent]:
	return LudoRules.apply_move(state, rules, chosen, snakes)


func ranking() -> Array[int]:
	return LudoRules.ranking(state)
