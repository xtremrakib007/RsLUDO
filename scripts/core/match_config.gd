class_name MatchConfig
extends RefCounted
## Everything needed to start a match: mode, players and rules.
## Built by the setup screens and read by the game screen (and later the rules engine).

const SUPPORTED_PLAYER_COUNTS := [2, 4]

var mode_id: String = ""
var players: Array[LudoPlayer] = []
var rules: LudoRulesConfig


## Seats used for a player count. Two players sit opposite each other.
static func seats_for_count(count: int) -> Array[int]:
	var seats: Array[int] = []
	match count:
		2:
			seats = [0, 2]
		4:
			seats = [0, 1, 2, 3]
	return seats


## Returns null when the mode is unknown or the player count is not supported.
static func create(p_mode_id: String, count: int) -> MatchConfig:
	var mode := ModeRegistry.get_mode(p_mode_id)
	if mode == null or not (count in SUPPORTED_PLAYER_COUNTS):
		return null
	var config := MatchConfig.new()
	config.mode_id = p_mode_id
	config.rules = mode.default_rules()
	for seat in seats_for_count(count):
		config.players.append(LudoPlayer.new(seat, "%s Player" % Palette.seat_name(seat)))
	return config


func player_count() -> int:
	return players.size()


func seats() -> Array[int]:
	var result: Array[int] = []
	for player in players:
		result.append(player.seat)
	return result


func player_at_seat(seat: int) -> LudoPlayer:
	for player in players:
		if player.seat == seat:
			return player
	return null
