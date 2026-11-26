class_name Dice
extends RefCounted
## Six-sided dice. Offline games roll here; online games (Phase 6) will use the
## server's roll instead. Tests can fix the seed or queue exact values.

var _rng := RandomNumberGenerator.new()
var _queued: Array[int] = []


## A negative seed means a random seed.
func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


func roll() -> int:
	if not _queued.is_empty():
		var value: int = _queued.pop_front()
		return value
	return _rng.randi_range(1, 6)


## Makes the next rolls return these values (for tests and tutorials).
func queue_rolls(values: Array[int]) -> void:
	for value in values:
		assert(value >= 1 and value <= 6, "not a dice value: %d" % value)
		_queued.append(value)
