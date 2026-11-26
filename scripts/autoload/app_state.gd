extends Node
## Session state shared between screens. No game rules live here.

const PROFILE_PATH := "user://profile.cfg"

## Local guest name; empty until the player chooses "Play as Guest".
var guest_name: String = ""
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


func _load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROFILE_PATH) == OK:
		guest_name = str(cfg.get_value("profile", "guest_name", ""))


func _save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "guest_name", guest_name)
	var err := cfg.save(PROFILE_PATH)
	if err != OK:
		push_warning("Could not save profile (error %d)." % err)
