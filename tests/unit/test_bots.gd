extends "res://tests/test_case.gd"
## 3-player games, bots in the match setup, and the Ludo bot's play.

const SceneRouterScript := preload("res://scripts/autoload/scene_router.gd")


# --- Setup --------------------------------------------------------------

func test_three_player_games() -> void:
	var config := MatchConfig.create(ClassicMode.ID, 3)
	assert_not_null(config)
	assert_eq(config.seats(), [0, 1, 2] as Array[int])
	var m := LocalMatch.new(config, Dice.new(3))
	m.dice.queue_rolls([2, 2, 2] as Array[int])
	m.roll()
	assert_eq(m.state.current_seat(), 1)
	m.roll()
	assert_eq(m.state.current_seat(), 2)
	m.roll()
	assert_eq(m.state.current_seat(), 0, "turns go round three players")


func test_bots_fill_the_last_seats_and_a_human_remains() -> void:
	var config := MatchConfig.create(ClassicMode.ID, 4, 2)
	assert_eq(config.human_count(), 2)
	assert_eq(config.bot_count(), 2)
	assert_false(config.is_bot(0))
	assert_true(config.is_bot(3))
	assert_eq(config.player_at_seat(3).display_name, "Blue Bot")
	var all_bots := MatchConfig.create(ClassicMode.ID, 2, 5)
	assert_eq(all_bots.human_count(), 1, "at least one human")


func test_players_can_pick_free_colours() -> void:
	var config := MatchConfig.create(ClassicMode.ID, 2, 1)
	assert_false(config.set_player_seat(0, 2), "yellow is taken by the bot")
	assert_true(config.set_player_seat(1, 1), "bot moves to green")
	assert_eq(config.players[1].display_name, "Green Bot", "default name follows the colour")
	assert_true(config.set_player_seat(0, 3), "human moves to blue")
	config.sort_by_seat()
	assert_eq(config.seats(), [1, 3] as Array[int], "turn order follows the board")


func test_switching_between_human_and_bot() -> void:
	var config := MatchConfig.create(SnakesLaddersMode.ID, 2)
	assert_true(config.set_player_control(1, LudoPlayer.ControlType.COMPUTER))
	assert_eq(config.players[1].display_name, "Yellow Bot")
	assert_false(config.set_player_control(0, LudoPlayer.ControlType.COMPUTER), "the last human cannot become a bot")
	assert_true(config.set_player_control(1, LudoPlayer.ControlType.LOCAL_HUMAN))
	assert_eq(config.players[1].display_name, "Yellow Player")


# --- Bot decisions --------------------------------------------------------

func _match() -> LocalMatch:
	return LocalMatch.new(MatchConfig.create(ClassicMode.ID, 4), Dice.new(11))


func _bot_pick(m: LocalMatch, roll: int) -> LudoMove:
	m.dice.queue_rolls([roll] as Array[int])
	m.roll()
	return LudoBot.choose_move(m.state, m.rules, m.legal_moves())


func test_bot_captures() -> void:
	var m := _match()
	m.state.set_pawn_progress(1, 0, 2)  # track 15
	m.state.set_pawn_progress(0, 0, 12)  # can capture with a 3
	m.state.set_pawn_progress(0, 1, 30)  # could just move on
	var pick := _bot_pick(m, 3)
	assert_eq(pick.pawn, 0, "takes the capture")


func test_bot_runs_from_danger() -> void:
	var m := _match()
	m.state.set_pawn_progress(0, 0, 20)  # track 20
	m.state.set_pawn_progress(1, 0, 4)  # green on track 17, 3 behind red's pawn 0
	m.state.set_pawn_progress(0, 1, 40)  # track 40, nobody near
	var pick := _bot_pick(m, 1)
	assert_eq(pick.pawn, 0, "moves the threatened pawn (to the star square 21)")


func test_bot_avoids_stopping_in_front_of_an_opponent() -> void:
	var m := _match()
	m.state.set_pawn_progress(1, 0, 1)  # green on track 14
	m.state.set_pawn_progress(0, 0, 10)  # with a 5 would stop on 15, right in front of green
	m.state.set_pawn_progress(0, 1, 30)  # with a 5 goes to 35, safe from everyone
	var pick := _bot_pick(m, 5)
	assert_eq(pick.pawn, 1, "keeps away from the opponent")


func test_bot_brings_pawns_home() -> void:
	var m := _match()
	m.state.set_pawn_progress(0, 0, 52)
	m.state.set_pawn_progress(0, 1, 5)
	var pick := _bot_pick(m, 4)
	assert_eq(pick.pawn, 0, "finishes the pawn")


func test_bot_starts_a_pawn_when_none_are_out() -> void:
	var m := _match()
	var pick := _bot_pick(m, 6)
	assert_true(pick.is_start(), "brings a pawn out with a six")


## Plays a full 2-player game: seat 0 uses `bot_seat_zero` (bot or random), seat 2 the other.
func _play(seed_value: int, bot_seat: int) -> int:
	var m := LocalMatch.new(MatchConfig.create(ClassicMode.ID, 2), Dice.new(seed_value))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + 7
	for i in 3000:
		if m.state.phase == MatchState.Phase.GAME_OVER:
			break
		if m.state.phase == MatchState.Phase.AWAITING_ROLL:
			m.roll()
			continue
		var moves := m.legal_moves()
		var chosen: LudoMove = moves[rng.randi_range(0, moves.size() - 1)]
		if m.state.current_seat() == bot_seat:
			chosen = LudoBot.choose_move(m.state, m.rules, moves, rng)
		m.move(chosen)
	return m.ranking()[0] if m.state.phase == MatchState.Phase.GAME_OVER else -1


func test_hard_bot_beats_a_random_player_most_of_the_time() -> void:
	var games := 60
	var bot_wins := 0
	var finished := 0
	for g in games:
		# Alternate which side the bot plays so going first does not decide it.
		var bot_seat := 0 if g % 2 == 0 else 2
		var winner := _play(1000 + g, bot_seat)
		if winner >= 0:
			finished += 1
		if winner == bot_seat:
			bot_wins += 1
	assert_eq(finished, games, "every game finishes")
	print("        bot won %d of %d games against random play" % [bot_wins, games])
	assert_true(bot_wins >= games * 0.7, "bot wins at least 70%% (won %d of %d)" % [bot_wins, games])


func test_four_bots_finish_a_game() -> void:
	var m := LocalMatch.new(MatchConfig.create(ClassicMode.ID, 4), Dice.new(77))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 6000:
		if m.state.phase == MatchState.Phase.GAME_OVER:
			break
		if m.state.phase == MatchState.Phase.AWAITING_ROLL:
			m.roll()
		else:
			m.move(LudoBot.choose_move(m.state, m.rules, m.legal_moves(), rng))
	assert_eq(m.state.phase, MatchState.Phase.GAME_OVER, "a winner is found")


# --- Bots on screen -----------------------------------------------------

func test_bot_takes_its_turn_by_itself() -> void:
	AppState.match_config = MatchConfig.create(ClassicMode.ID, 2, 1)
	var scene: PackedScene = load(SceneRouterScript.SCREENS["game"])
	var screen := scene.instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	var local_match: LocalMatch = screen.get("local_match")
	local_match.dice.queue_rolls([2, 3] as Array[int])
	screen.call("_on_dice_pressed")  # the human rolls a 2: no moves
	await tree.create_timer(1.5).timeout
	assert_eq(local_match.state.current_seat(), 2, "bot's turn")
	screen.call("_on_dice_pressed")  # a human tap must not roll for the bot
	await tree.create_timer(4.0).timeout
	assert_eq(local_match.state.current_seat(), 0, "bot rolled a 3 by itself and the turn came back")
	screen.queue_free()
	await tree.process_frame
