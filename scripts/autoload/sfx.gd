extends Node
## Plays sound effects: Sfx.play("dice"). Sounds are made by SoundSynth the first
## time they are needed. To use a recorded sound instead, put a file named
## <sound>.ogg or <sound>.wav in res://assets/sounds/ and it is used automatically.
##
## Volume: an overall level plus three groups (each its own audio bus), set by
## the player with sliders and saved on the device.

const SETTINGS_PATH := "user://settings.cfg"
const VOICES := 10

## Volume groups: id -> [bus name, label shown to players].
const GROUPS := {
	"moves": ["Moves", "Dice & moves"],
	"battle": ["Battle", "Battles & snakes"],
	"jingles": ["Jingles", "Jingles"],
}
## Which group each sound belongs to (anything not listed is a jingle).
const SOUND_GROUPS := {
	"click": "moves", "dice": "moves", "dice_land": "moves", "dice_move": "moves", "step": "moves",
	"charge": "battle", "zap": "battle", "gunshot": "battle", "katana_draw": "battle", "katana_slash": "battle",
	"swish": "battle", "bonk": "battle", "poof": "battle", "impact": "battle", "ko": "battle", "whoosh": "battle",
	"thud": "battle", "hiss": "battle", "gulp": "battle", "slide": "battle", "pop": "battle",
}
const DEFAULT_VOLUME := 0.8

## Sound on/off (the overall mute).
var enabled: bool = true
## "master" and each group id -> 0.0 .. 1.0
var volumes: Dictionary = {}
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for group in GROUPS:
		_ensure_bus(GROUPS[group][0])
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	volumes["master"] = DEFAULT_VOLUME
	for group in GROUPS:
		volumes[group] = DEFAULT_VOLUME
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		enabled = bool(cfg.get_value("audio", "sound", true))
		for key in volumes.keys():
			volumes[key] = clampf(float(cfg.get_value("audio", "volume_" + key, DEFAULT_VOLUME)), 0.0, 1.0)
	_apply_volumes()


## Plays a sound. `pitch_spread` adds a little random pitch variation (0.1 = +/-10%).
func play(sound_name: String, volume_db: float = 0.0, pitch_spread: float = 0.0) -> void:
	if not enabled:
		return
	var stream := get_stream(sound_name)
	if stream == null:
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.bus = bus_for(sound_name)
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)
	player.play()


func bus_for(sound_name: String) -> StringName:
	var group: String = SOUND_GROUPS.get(sound_name, "jingles")
	return StringName(GROUPS[group][0])


func get_stream(sound_name: String) -> AudioStream:
	if not _streams.has(sound_name):
		var recorded := _recorded(sound_name)
		if recorded != null:
			_streams[sound_name] = recorded
		elif SoundSynth.RECIPES.has(sound_name):
			_streams[sound_name] = SoundSynth.build(sound_name)
		else:
			push_warning("Unknown sound: %s" % sound_name)
			return null
	return _streams[sound_name]


func set_enabled(value: bool) -> void:
	enabled = value
	_apply_volumes()
	_save()


## key: "master" or a group id. value: 0.0 (silent) .. 1.0 (loudest).
func set_volume(key: String, value: float) -> void:
	if not volumes.has(key):
		return
	volumes[key] = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_save()


func get_volume(key: String) -> float:
	return float(volumes.get(key, DEFAULT_VOLUME))


func _apply_volumes() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master, not enabled or get_volume("master") <= 0.0)
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(get_volume("master"), 0.0001)))
	for group in GROUPS:
		var index := AudioServer.get_bus_index(GROUPS[group][0])
		if index < 0:
			continue
		var level := get_volume(group)
		AudioServer.set_bus_mute(index, level <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "sound", enabled)
	for key in volumes:
		cfg.set_value("audio", "volume_" + key, volumes[key])
	cfg.save(SETTINGS_PATH)


func _recorded(sound_name: String) -> AudioStream:
	for extension in ["ogg", "wav", "mp3"]:
		var path := "res://assets/sounds/%s.%s" % [sound_name, extension]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null
