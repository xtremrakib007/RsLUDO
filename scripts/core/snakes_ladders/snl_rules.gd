class_name SnlRules
extends Resource
## House rules for Snakes & Ladders. Defaults are the traditional game.

## A pawn must land exactly on 100; a bigger roll means it stays put.
@export var exact_finish: bool = true
## Rolling a six gives another roll.
@export var extra_turn_on_six: bool = true
## This many sixes in a row ends the turn without moving. 0 disables the rule.
@export var max_consecutive_sixes: int = 3
## Pawns wait off the board until they roll a six.
@export var six_to_start: bool = false


func summary() -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("Roll a six to start" if six_to_start else "Everyone starts straight away")
	lines.append("Ladders take you up, snakes take you down")
	lines.append("Passing a snake is safe; only landing on its head counts")
	if extra_turn_on_six:
		lines.append("A six gives another roll")
	if max_consecutive_sixes > 0:
		lines.append("%d sixes in a row ends the turn" % max_consecutive_sixes)
	if exact_finish:
		lines.append("Exact roll needed to reach 100")
	lines.append("First to reach 100 wins")
	return lines


func to_dict() -> Dictionary:
	return {
		"exact_finish": exact_finish,
		"extra_turn_on_six": extra_turn_on_six,
		"max_consecutive_sixes": max_consecutive_sixes,
		"six_to_start": six_to_start,
	}


static func from_dict(data: Dictionary) -> SnlRules:
	var rules := SnlRules.new()
	rules.exact_finish = bool(data.get("exact_finish", rules.exact_finish))
	rules.extra_turn_on_six = bool(data.get("extra_turn_on_six", rules.extra_turn_on_six))
	rules.max_consecutive_sixes = int(data.get("max_consecutive_sixes", rules.max_consecutive_sixes))
	rules.six_to_start = bool(data.get("six_to_start", rules.six_to_start))
	return rules
