extends Node
## Plays sound effects: Sfx.play("dice"). Sounds are made by SoundSynth the first
## time they are needed. To use a recorded sound instead, put a file named
## <sound>.ogg or <sound>.wav in res://assets/sounds/ and it is used automatically.
## The on/off setting is saved on the device.

const SETTINGS_PATH := "user://settings.cfg"
const VOICES := 8

var enabled: bool = true
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		enabled = bool(cfg.get_value("audio", "sound", true))


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
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)
	player.play()


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
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "sound", value)
	cfg.save(SETTINGS_PATH)


func _recorded(sound_name: String) -> AudioStream:
	for extension in ["ogg", "wav", "mp3"]:
		var path := "res://assets/sounds/%s.%s" % [sound_name, extension]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null
