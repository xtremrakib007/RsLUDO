class_name MatchConfig
extends RefCounted
## Everything needed to start a match: mode, players and rules.
## Built by the setup screens and read by the game screen (and later the rules engine).

const SUPPORTED_PLAYER_COUNTS := [2, 3, 4]

var mode_id: String = ""
var players: Array[LudoPlayer] = []
## Ludo rules (Classic Ludo).
var rules: LudoRulesConfig
## Snakes & Ladders rules and the chosen board.
var snl_rules: SnlRules = SnlRules.new()
var board_id: String = ""


## Seats used for a player count. Two players sit opposite each other.
static func seats_for_count(count: int) -> Array[int]:
	var seats: Array[int] = []
	match count:
		2:
			seats = [0, 2]
		3:
			seats = [0, 1, 2]
		4:
			seats = [0, 1, 2, 3]
	return seats


## Returns null when the mode is unknown or the player count is not supported.
## The last `bots` players are computer players (at least one human always plays).
static func create(p_mode_id: String, count: int, bots: int = 0) -> MatchConfig:
	var mode := ModeRegistry.get_mode(p_mode_id)
	if mode == null or not (count in SUPPORTED_PLAYER_COUNTS):
		return null
	var config := MatchConfig.new()
	config.mode_id = p_mode_id
	config.rules = mode.default_rules()
	config.board_id = SnlBoards.all()[0].id
	var seats := seats_for_count(count)
	var bot_count := clampi(bots, 0, count - 1)
	for i in seats.size():
		var control := LudoPlayer.ControlType.COMPUTER if i >= count - bot_count else LudoPlayer.ControlType.LOCAL_HUMAN
		config.players.append(LudoPlayer.new(seats[i], default_name(seats[i], control), control))
	return config


static func default_name(seat: int, control: int) -> String:
	if control == LudoPlayer.ControlType.COMPUTER:
		return "%s Bot" % Palette.seat_name(seat)
	return "%s Player" % Palette.seat_name(seat)


## Moves player `index` to another colour (seat). Fails if someone else has it.
func set_player_seat(index: int, seat: int) -> bool:
	if index < 0 or index >= players.size() or not BoardLayout.is_valid_seat(seat):
		return false
	for i in players.size():
		if i != index and players[i].seat == seat:
			return false
	var player: LudoPlayer = players[index]
	var had_default := player.display_name == default_name(player.seat, player.control_type)
	player.seat = seat
	if had_default:
		player.display_name = default_name(seat, player.control_type)
	return true


## Switches player `index` between human and computer. At least one human must remain.
func set_player_control(index: int, control: int) -> bool:
	if index < 0 or index >= players.size():
		return false
	var player: LudoPlayer = players[index]
	if control == LudoPlayer.ControlType.COMPUTER and player.control_type != control and human_count() <= 1:
		return false
	var had_default := player.display_name == default_name(player.seat, player.control_type)
	player.control_type = control
	if had_default:
		player.display_name = default_name(player.seat, control)
	return true


func human_count() -> int:
	var count := 0
	for player in players:
		if not player.is_bot():
			count += 1
	return count


func bot_count() -> int:
	return players.size() - human_count()


func is_bot(seat: int) -> bool:
	var player := player_at_seat(seat)
	return player != null and player.is_bot()


## Turn order follows the board clockwise, so players are kept sorted by seat.
func sort_by_seat() -> void:
	players.sort_custom(func(a: LudoPlayer, b: LudoPlayer) -> bool: return a.seat < b.seat)


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
