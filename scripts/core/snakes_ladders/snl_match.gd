class_name SnlMatch
extends RefCounted
## An offline Snakes & Ladders match on this device.

var config: MatchConfig
var rules: SnlRules
var board: SnlBoard
var dice: Dice
var state: SnlState


func _init(p_config: MatchConfig, p_dice: Dice = null) -> void:
	config = p_config
	rules = config.snl_rules
	board = SnlBoards.get_board(config.board_id)
	dice = p_dice if p_dice != null else Dice.new()
	restart()


func restart() -> void:
	state = SnlState.create(config.seats())


func roll() -> Array[GameEvent]:
	return SnlEngine.apply_roll(state, rules, board, dice.roll())


func ranking() -> Array[int]:
	return SnlEngine.ranking(state)
