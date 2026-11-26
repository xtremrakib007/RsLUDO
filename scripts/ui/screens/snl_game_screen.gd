extends MatchScreen
## Snakes & Ladders (pass and play). Tap the dice; the pawn walks, then climbs a
## ladder or slides down a snake if it stopped on one. There is never a choice
## to make, so no pawn tapping is needed.

## Space used by everything except the board (header, player rows, dice panel, gaps, margins).
const NON_BOARD_HEIGHT := 680.0

var board: SnlBoardView
var snl_match: SnlMatch


func build() -> void:
	_setup_match(SnakesLaddersMode.ID)
	snl_match = SnlMatch.new(_config)

	content.add_child(UIKit.spacer())
	content.add_child(_corner_row(0, 1))
	board = SnlBoardView.new()
	board.setup(snl_match.board, _config.seats())
	content.add_child(board)
	content.add_child(_corner_row(3, 2))
	content.add_child(_dice_panel())
	content.add_child(UIKit.spacer())

	_finish_setup()
	resized.connect(_fit_board)
	_fit_board()
	board.sync(snl_match.state)
	_refresh_ui()
	_start_dice_pulse()


func _subtitle() -> String:
	return "%s - %d players" % [snl_match_board_title(), _config.player_count()]


func snl_match_board_title() -> String:
	return SnlBoards.get_board(_config.board_id).title


func _fit_board() -> void:
	var width := minf(size.x, MAX_CONTENT_WIDTH) - 72.0
	var height := minf(width / SnlBoard.SIZE * (SnlBoard.SIZE + SnlBoardView.START_ROWS), size.y - NON_BOARD_HEIGHT)
	board.custom_minimum_size = Vector2(0, maxf(height, 300.0))


func _pausable() -> Node:
	return board


func _on_dice_pressed() -> void:
	if _busy or is_paused() or snl_match.state.phase != SnlState.Phase.AWAITING_ROLL:
		return
	_busy = true
	_stop_dice_pulse()
	var events := snl_match.roll()
	await _animate_dice(snl_match.state.last_roll)
	await _play_events(events)
	_busy = false
	_refresh_ui()
	if snl_match.state.phase == SnlState.Phase.GAME_OVER:
		_finish_match(snl_match.ranking())
	else:
		_start_dice_pulse()


func _play_events(events: Array[GameEvent]) -> void:
	for event in events:
		var d := event.data
		match event.type:
			GameEvent.Type.PAWN_MOVED:
				await board.animate_walk(d["seat"], d["from"], d["to"])
			GameEvent.Type.LADDER_CLIMB:
				_show_banner("Ladder! Up to %d" % d["to"], Palette.ACCENT)
				await _wait(0.25)
				await board.animate_climb(d["seat"], d["to"])
			GameEvent.Type.SNAKE_SLIDE:
				_show_banner("GULP! Down to %d" % d["to"], Palette.SNAKE_BODY)
				await board.animate_slide(d["seat"], d["from"], d["to"])
			GameEvent.Type.PLAYER_FINISHED:
				Sfx.play("win")
				Sfx.play("yay", -3.0)
				_show_banner("%s reached 100!" % _name(d["seat"]), Palette.seat_color(d["seat"]))
				await CaptureAnimator.celebrate(board, board.pawn_node(d["seat"]), board.cell_size())
				await _wait(0.4)
			GameEvent.Type.EXTRA_TURN:
				Sfx.play("extra")
				_show_banner("Roll again!", Palette.ACCENT)
				await _wait(0.35)
			GameEvent.Type.NO_MOVES:
				Sfx.play("no_move")
				_show_banner("Need exactly %d to reach 100" % (SnlBoard.LAST_SQUARE - snl_match.state.position_of(d["seat"])), Palette.TEXT_MUTED)
				await _wait(0.8)
			GameEvent.Type.THREE_SIXES:
				Sfx.play("no_move")
				_show_banner("Three sixes - turn over", Palette.TEXT_MUTED)
				await _wait(0.9)
	board.sync(snl_match.state)


func _refresh_ui() -> void:
	var state := snl_match.state
	_refresh_panels(state.current_seat(), state.phase == SnlState.Phase.GAME_OVER)
	_hint_label.text = "Match over" if state.phase == SnlState.Phase.GAME_OVER else "Tap the dice to roll"


func _panel_status(seat: int) -> String:
	var square := snl_match.state.position_of(seat)
	return "Square %d" % square if square > SnlState.OFF_BOARD else "At start"
