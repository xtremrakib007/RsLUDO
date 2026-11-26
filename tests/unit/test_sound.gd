extends "res://tests/test_case.gd"
## Sound effects are generated in code; check every one builds and the switch works.


func test_every_sound_builds() -> void:
	assert_true(SoundSynth.names().size() >= 20, "plenty of sounds")
	for sound_name in SoundSynth.names():
		var stream := SoundSynth.build(sound_name)
		assert_not_null(stream, "%s builds" % sound_name)
		var seconds := stream.data.size() / 2.0 / SoundSynth.RATE
		assert_true(seconds > 0.02 and seconds < 2.0, "%s is %.2f s long" % [sound_name, seconds])
		var loudest := 0
		for i in range(0, stream.data.size(), 2):
			loudest = maxi(loudest, absi(stream.data.decode_s16(i)))
		assert_true(loudest > 2000, "%s is audible" % sound_name)
		assert_true(loudest <= 32767, "%s does not clip" % sound_name)


func test_sounds_used_by_the_game_exist() -> void:
	for sound_name in ["click", "dice", "dice_land", "dice_move", "step", "charge", "zap", "swish", "bonk", "poof",
			"impact", "ko", "whoosh", "thud", "cheer", "climb", "hiss", "gulp", "slide", "pop", "extra", "no_move", "home", "win"]:
		assert_not_null(Sfx.get_stream(sound_name), "%s available" % sound_name)


func test_sound_switch_is_remembered() -> void:
	var before: bool = Sfx.enabled
	Sfx.set_enabled(false)
	assert_false(Sfx.enabled)
	Sfx.play("click")
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	assert_eq(cfg.get_value("audio", "sound", true), false, "saved off")
	Sfx.set_enabled(true)
	assert_eq(ConfigFile.new().load("user://settings.cfg"), OK)
	Sfx.play("click")
	Sfx.set_enabled(before)


func test_kill_sounds_exist() -> void:
	for sound_name in ["gunshot", "katana_draw", "katana_slash"]:
		assert_not_null(Sfx.get_stream(sound_name), "%s available" % sound_name)
		assert_eq(Sfx.bus_for(sound_name), &"Battle", "%s is a battle sound" % sound_name)
	assert_eq(Sfx.bus_for("dice"), &"Moves")
	assert_eq(Sfx.bus_for("win"), &"Jingles")


func test_volume_levels_apply_and_are_saved() -> void:
	var before := Sfx.get_volume("battle")
	Sfx.set_volume("battle", 0.25)
	var index := AudioServer.get_bus_index("Battle")
	assert_true(index > 0, "battle bus exists")
	assert_true(absf(AudioServer.get_bus_volume_db(index) - linear_to_db(0.25)) < 0.01, "bus volume set")
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	assert_true(absf(float(cfg.get_value("audio", "volume_battle", 0.0)) - 0.25) < 0.001, "volume saved")
	Sfx.set_volume("battle", 0.0)
	assert_true(AudioServer.is_bus_mute(index), "0% mutes the group")
	Sfx.set_volume("battle", before)


func test_settings_panel_sliders_change_volume() -> void:
	var panel := SoundSettingsPanel.new()
	tree.root.add_child(panel)
	await tree.process_frame
	var before := Sfx.get_volume("moves")
	var moves := panel.slider("moves")
	assert_not_null(moves, "moves slider")
	assert_not_null(panel.slider("master"), "all-sounds slider")
	moves.value = 40
	assert_true(absf(Sfx.get_volume("moves") - 0.4) < 0.001, "slider sets the volume")
	Sfx.set_volume("moves", before)
	panel.queue_free()
	await tree.process_frame
