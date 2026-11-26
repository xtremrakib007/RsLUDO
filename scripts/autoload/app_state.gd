extends Node
## Session state shared between screens. No game rules live here.

const PROFILE_PATH := "user://profile.cfg"
## How many finished matches are kept in the history.
const MAX_HISTORY := 50
const MAX_NAME_LENGTH := 14

## Local guest name; empty until the player chooses "Play as Guest".
var guest_name: String = ""
## Which character look (seat colour) the player chose for their profile.
var avatar_seat: int = 0
## Finished matches on this device, newest first. Each entry is a Dictionary:
## {time, mode_id, board_id, players: [{seat, name}], ranking: [seat, ...], winner_name}
var history: Array = []
## Mode chosen on the home screen, used by the player-count screen.
var pending_mode_id: String = ClassicMode.ID
## Match being set up or played.
var match_config: MatchConfig = null
## Seats in finishing order for the last finished match (result screen).
var last_ranking: Array[int] = []


func _ready() -> void:
	_load_profile()


func has_profile() -> bool:
	return not guest_name.is_empty()


func create_guest_profile() -> void:
	guest_name = "Guest %04d" % (randi() % 10000)
	_save_profile()


## Changes the player's name and character colour.
func set_profile(new_name: String, seat: int) -> void:
	var cleaned := new_name.strip_edges().left(MAX_NAME_LENGTH)
	if not cleaned.is_empty():
		guest_name = cleaned
	avatar_seat = clampi(seat, 0, 3)
	_save_profile()


## Remembers a finished match for the history and statistics.
func record_match(config: MatchConfig, ranking: Array[int]) -> void:
	if config == null or ranking.is_empty():
		return
	var players: Array = []
	for player in config.players:
		players.append({"seat": player.seat, "name": player.display_name})
	var winner := config.player_at_seat(ranking[0])
	var entry := {
		"time": int(Time.get_unix_time_from_system()),
		"mode_id": config.mode_id,
		"board_id": config.board_id,
		"players": players,
		"ranking": Array(ranking),
		"winner_name": winner.display_name if winner != null else "",
	}
	history.push_front(entry)
	if history.size() > MAX_HISTORY:
		history.resize(MAX_HISTORY)
	_save_profile()


func matches_played(mode_id: String = "") -> int:
	if mode_id.is_empty():
		return history.size()
	var count := 0
	for entry in history:
		if entry.get("mode_id", "") == mode_id:
			count += 1
	return count


## Matches won by a player using the profile name.
func wins() -> int:
	var count := 0
	for entry in history:
		if not guest_name.is_empty() and entry.get("winner_name", "") == guest_name:
			count += 1
	return count


func _load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROFILE_PATH) == OK:
		guest_name = str(cfg.get_value("profile", "guest_name", ""))
		avatar_seat = clampi(int(cfg.get_value("profile", "avatar_seat", 0)), 0, 3)
		var saved = cfg.get_value("profile", "history", [])
		history = saved if saved is Array else []


func _save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "guest_name", guest_name)
	cfg.set_value("profile", "avatar_seat", avatar_seat)
	cfg.set_value("profile", "history", history)
	var err := cfg.save(PROFILE_PATH)
	if err != OK:
		push_warning("Could not save profile (error %d)." % err)
