extends "res://tests/test_case.gd"


func test_modes_are_registered() -> void:
	assert_not_null(ModeRegistry.get_mode(ClassicMode.ID), "classic mode")
	assert_not_null(ModeRegistry.get_mode(SnakeMode.ID), "snake mode")
	assert_true(ModeRegistry.get_mode("unknown") == null, "unknown mode")
	assert_eq(ModeRegistry.all_modes().size(), 2, "mode count")
	for mode in ModeRegistry.all_modes():
		assert_false(mode.title.is_empty(), "%s has a title" % mode.id)
		assert_false(mode.description.is_empty(), "%s has a description" % mode.id)


func test_two_players_sit_opposite() -> void:
	var config := MatchConfig.create(ClassicMode.ID, 2)
	assert_not_null(config, "2-player config")
	assert_eq(config.player_count(), 2, "player count")
	assert_eq(config.seats(), [0, 2] as Array[int], "seats")
	assert_eq(config.players[0].display_name, "Red Player", "default name")
	assert_eq(config.players[1].display_name, "Yellow Player", "default name")
	assert_true(config.player_at_seat(1) == null, "seat 1 is empty")


func test_four_players_use_every_seat() -> void:
	var config := MatchConfig.create(SnakeMode.ID, 4)
	assert_not_null(config, "4-player config")
	assert_eq(config.seats(), [0, 1, 2, 3] as Array[int], "seats")
	for player in config.players:
		assert_eq(player.control_type, LudoPlayer.ControlType.LOCAL_HUMAN, "offline players are local")


func test_unsupported_setups_are_rejected() -> void:
	assert_true(MatchConfig.create(ClassicMode.ID, 3) == null, "3 players not supported yet")
	assert_true(MatchConfig.create(ClassicMode.ID, 1) == null, "1 player")
	assert_true(MatchConfig.create("unknown", 2) == null, "unknown mode")


func test_modes_get_their_own_rules() -> void:
	var classic := MatchConfig.create(ClassicMode.ID, 4)
	var snake := MatchConfig.create(SnakeMode.ID, 4)
	assert_false(classic.rules.snakes_enabled, "classic has no snakes")
	assert_true(snake.rules.snakes_enabled, "snake mode has snakes")
	assert_eq(snake.rules.snake_penalty, LudoRulesConfig.SnakePenalty.RETURN_TO_BASE, "default snake penalty")


func test_default_rules_are_traditional() -> void:
	var rules := LudoRulesConfig.classic()
	assert_eq(rules.start_rolls, [6] as Array[int], "six to start")
	assert_true(rules.extra_turn_on_six, "extra turn on six")
	assert_eq(rules.max_consecutive_sixes, 3, "three sixes rule")
	assert_true(rules.extra_turn_on_capture, "extra turn on capture")
	assert_true(rules.exact_roll_to_finish, "exact roll to finish")
	assert_true(rules.safe_squares_enabled, "safe squares")
	assert_true(rules.validate().is_empty(), "default rules are valid")
	assert_false(rules.summary().is_empty(), "rules summary")


func test_rules_round_trip_through_plain_data() -> void:
	var rules := LudoRulesConfig.snake()
	rules.start_rolls = [1, 6] as Array[int]
	rules.max_consecutive_sixes = 0
	rules.snake_penalty = LudoRulesConfig.SnakePenalty.MOVE_BACK_STEPS
	rules.snake_penalty_steps = 4
	var data := rules.to_dict()
	var copy := LudoRulesConfig.from_dict(data)
	assert_eq(copy.to_dict(), data, "round trip")
	assert_eq(copy.start_rolls, [1, 6] as Array[int], "start rolls survive")


func test_invalid_rules_are_reported() -> void:
	var rules := LudoRulesConfig.classic()
	rules.start_rolls = [7] as Array[int]
	rules.snake_penalty_steps = 0
	assert_eq(rules.validate().size(), 2, "two problems")
	rules.start_rolls = [] as Array[int]
	assert_true(rules.validate().size() >= 2, "empty start rolls")


func test_online_is_not_available_offline() -> void:
	assert_false(OnlineService.is_available(), "offline build has no online service")
