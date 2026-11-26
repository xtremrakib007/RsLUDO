class_name LudoRulesConfig
extends Resource
## House rules for a match. The rules engine (Phase 2) reads these values, so
## traditional variations can be supported by changing data, not code.
## Visual code must never decide rules; it only shows what the engine decided.

## Dice values that let a pawn leave its base.
@export var start_rolls: Array[int] = [6]
## Rolling a six gives another roll.
@export var extra_turn_on_six: bool = true
## Rolling this many sixes in a row forfeits the turn. 0 disables the rule.
@export var max_consecutive_sixes: int = 3
## Capturing an opponent gives another roll.
@export var extra_turn_on_capture: bool = true
## Moving a pawn into the finish gives another roll.
@export var extra_turn_on_finish: bool = true
## A pawn needs the exact number to reach the finish.
@export var exact_roll_to_finish: bool = true
## Pawns on safe squares (start and star squares) cannot be captured.
@export var safe_squares_enabled: bool = true
## Two pawns of one colour on a square form a block opponents cannot pass.
@export var blocks_enabled: bool = false
## Keep playing after the winner until only one player is left (decides every place).
@export var play_until_one_left: bool = false


static func classic() -> LudoRulesConfig:
	return LudoRulesConfig.new()


## Returns human-readable problems; empty when the rules are usable.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if start_rolls.is_empty():
		problems.append("At least one dice value must let a pawn start.")
	for value in start_rolls:
		if value < 1 or value > 6:
			problems.append("Start roll %d is not a dice value." % value)
	if max_consecutive_sixes < 0:
		problems.append("Consecutive sixes limit cannot be negative.")
	return problems


## Plain data for saving and (later) for the server to send the agreed rules.
func to_dict() -> Dictionary:
	var rolls: Array = []
	for value in start_rolls:
		rolls.append(value)
	return {
		"start_rolls": rolls,
		"extra_turn_on_six": extra_turn_on_six,
		"max_consecutive_sixes": max_consecutive_sixes,
		"extra_turn_on_capture": extra_turn_on_capture,
		"extra_turn_on_finish": extra_turn_on_finish,
		"exact_roll_to_finish": exact_roll_to_finish,
		"safe_squares_enabled": safe_squares_enabled,
		"blocks_enabled": blocks_enabled,
		"play_until_one_left": play_until_one_left,
	}


static func from_dict(data: Dictionary) -> LudoRulesConfig:
	var rules := LudoRulesConfig.new()
	if data.has("start_rolls"):
		var rolls: Array[int] = []
		for value in data["start_rolls"]:
			rolls.append(int(value))
		rules.start_rolls = rolls
	rules.extra_turn_on_six = bool(data.get("extra_turn_on_six", rules.extra_turn_on_six))
	rules.max_consecutive_sixes = int(data.get("max_consecutive_sixes", rules.max_consecutive_sixes))
	rules.extra_turn_on_capture = bool(data.get("extra_turn_on_capture", rules.extra_turn_on_capture))
	rules.extra_turn_on_finish = bool(data.get("extra_turn_on_finish", rules.extra_turn_on_finish))
	rules.exact_roll_to_finish = bool(data.get("exact_roll_to_finish", rules.exact_roll_to_finish))
	rules.safe_squares_enabled = bool(data.get("safe_squares_enabled", rules.safe_squares_enabled))
	rules.blocks_enabled = bool(data.get("blocks_enabled", rules.blocks_enabled))
	rules.play_until_one_left = bool(data.get("play_until_one_left", rules.play_until_one_left))
	return rules


## Short lines describing the rules, for the lobby and help screens.
func summary() -> PackedStringArray:
	var lines := PackedStringArray()
	var rolls := PackedStringArray()
	for value in start_rolls:
		rolls.append(str(value))
	lines.append("Roll %s to bring a pawn out" % " or ".join(rolls))
	if extra_turn_on_six:
		lines.append("A six gives another roll")
	if max_consecutive_sixes > 0:
		lines.append("%d sixes in a row ends the turn" % max_consecutive_sixes)
	if extra_turn_on_capture:
		lines.append("Capturing gives another roll")
	if safe_squares_enabled:
		lines.append("Star and start squares are safe")
	if exact_roll_to_finish:
		lines.append("Exact roll needed to finish")
	if blocks_enabled:
		lines.append("Two pawns of one colour block the way")
	if play_until_one_left:
		lines.append("Play on until every place is decided")
	else:
		lines.append("First player with all four pawns home wins")
	return lines
