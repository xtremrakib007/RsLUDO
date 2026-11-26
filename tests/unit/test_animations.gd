extends "res://tests/test_case.gd"
## Capture animation rules from the brief: it plays only after a successful
## capture, the prop appears only during it, and never while walking.

const SceneRouterScript := preload("res://scripts/autoload/scene_router.gd")


func _wait_seconds(seconds: float) -> void:
	await tree.create_timer(seconds).timeout


func _open_ludo(count: int) -> Node:
	AppState.match_config = MatchConfig.create(ClassicMode.ID, count)
	var scene: PackedScene = load(SceneRouterScript.SCREENS["game"])
	var screen := scene.instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	return screen


func test_styles_are_random_and_do_not_repeat() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var seen := {}
	var previous := -1
	for i in 200:
		var style := CaptureAnimator.pick_style(rng, previous)
		assert_true(style >= 0 and style < CaptureAnimator.Style.size(), "style %d in range" % style)
		assert_true(style != previous, "style changes every capture")
		seen[style] = true
		previous = style
	assert_eq(seen.size(), CaptureAnimator.Style.size(), "every style gets used")


func test_each_style_has_its_own_prop() -> void:
	var props := {}
	for style in CaptureAnimator.Style.size():
		var prop := CaptureAnimator.prop_for(style)
		assert_true(prop != PawnToken.Prop.NONE, "style %d shows a prop" % style)
		props[prop] = true
	assert_eq(props.size(), CaptureAnimator.Style.size(), "different prop per style")


func test_prop_shows_only_during_the_capture_sequence() -> void:
	var board := BoardView.new()
	board.size = Vector2(600, 600)
	tree.root.add_child(board)
	await tree.process_frame
	var attacker := board.pawn_node(0, 0)
	var victim := board.pawn_node(1, 0)
	assert_eq(attacker.prop, PawnToken.Prop.NONE, "no prop before")
	for style in CaptureAnimator.Style.size():
		CaptureAnimator.play(board, attacker, victim, style, board.cell_size())
		await _wait_seconds(0.5)
		assert_true(attacker.prop != PawnToken.Prop.NONE, "style %d: prop in hand during the attack" % style)
		await _wait_seconds(2.0)
		assert_eq(attacker.prop, PawnToken.Prop.NONE, "style %d: prop gone afterwards" % style)
		assert_eq(attacker.arm_raise, 0.0, "style %d: arm back down" % style)
		assert_false(victim.dizzy, "style %d: victim recovered" % style)
	board.queue_free()
	await tree.process_frame


func test_capture_on_screen_plays_the_animation() -> void:
	var screen: Node = await _open_ludo(4)
	var local_match: LocalMatch = screen.get("local_match")
	local_match.state.set_pawn_progress(1, 0, 2)
	local_match.state.set_pawn_progress(0, 0, 12)
	(screen.get("board") as BoardView).sync(local_match.state)
	local_match.dice.queue_rolls([3] as Array[int])
	screen.call("_on_dice_pressed")
	await _wait_seconds(7.0)
	assert_eq(screen.get("captures_played"), 1, "one capture animation")
	assert_eq(local_match.state.pawn_progress(1, 0), MatchState.IN_BASE, "victim back in base")
	var board: BoardView = screen.get("board")
	assert_eq(board.pawn_node(0, 0).prop, PawnToken.Prop.NONE, "prop put away after the capture")
	var base_slot := board.grid_to_local(BoardLayout.base_slot_points(1)[0])
	assert_true(board.pawn_node(1, 0).position.distance_to(base_slot) < board.cell_size(), "victim drawn in its base")
	screen.queue_free()
	await tree.process_frame


func test_no_animation_and_no_prop_without_a_capture() -> void:
	var screen: Node = await _open_ludo(4)
	var local_match: LocalMatch = screen.get("local_match")
	local_match.state.set_pawn_progress(0, 0, 12)
	(screen.get("board") as BoardView).sync(local_match.state)
	local_match.dice.queue_rolls([3] as Array[int])
	screen.call("_on_dice_pressed")
	# Check during the walk too: the pawn never holds a prop while walking.
	await _wait_seconds(1.2)
	var board: BoardView = screen.get("board")
	assert_eq(board.pawn_node(0, 0).prop, PawnToken.Prop.NONE, "no prop while walking")
	await _wait_seconds(1.5)
	assert_eq(screen.get("captures_played"), 0, "no capture animation")
	assert_eq(local_match.state.pawn_progress(0, 0), 15)
	screen.queue_free()
	await tree.process_frame


func test_snake_swallows_the_pawn_and_it_pops_out_at_the_tail() -> void:
	var view := SnlBoardView.new()
	view.size = Vector2(600, 660)
	view.setup(SnlBoard.create("t", "T", "", {}, {27: 5}), [0] as Array[int])
	tree.root.add_child(view)
	await tree.process_frame
	var state := SnlState.create([0] as Array[int])
	state.set_position(0, 27)
	view.sync(state)
	var pawn := view.pawn_node(0)
	view.animate_slide(0, 27, 5)
	await _wait_seconds(0.2)
	assert_eq(view.snake_head, 27, "the snake on 27 is animating")
	assert_true(view.snake_mouth > 0.5, "mouth opens wide")
	await _wait_seconds(0.55)
	assert_false(pawn.visible, "pawn swallowed")
	await _wait_seconds(0.5)
	assert_true(view.snake_bulge > 0.0 and view.snake_bulge < 1.0, "bulge travelling down the body")
	await _wait_seconds(1.3)
	assert_true(pawn.visible, "pawn popped out")
	assert_eq(pawn.scale, Vector2.ONE, "back to full size")
	assert_true(pawn.position.distance_to(view.square_center(5)) < view.cell_size(), "at the snake's tail")
	assert_eq(view.snake_head, -1, "snake back to normal")
	assert_eq(view.snake_bulge, -1.0, "no bulge left")
	assert_eq(view.snake_mouth, 0.0, "mouth closed")
	view.queue_free()
	await tree.process_frame
