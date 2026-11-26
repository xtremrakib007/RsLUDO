extends MatchScreen
## Classic Ludo (pass and play). The LocalMatch decides everything; this screen
## shows the board, plays back the rules' events and collects taps.

const AUTO_MOVE_DELAY := 0.3
## Space used by everything except the board (header, player rows, dice panel, gaps, margins).
const NON_BOARD_HEIGHT := 680.0

var board: BoardView
var local_match: LocalMatch
## How many capture animations have played, and the last style (for tests).
var captures_played: int = 0
var last_capture_style: int = -1
var _rng := RandomNumberGenerator.new()


func build() -> void:
	_setup_match(ClassicMode.ID)
	local_match = LocalMatch.new(_config)
	_rng.randomize()

	content.add_child(UIKit.spacer())
	content.add_child(_corner_row(0, 1))
	board = BoardView.new()
	board.setup(_config.seats())
	board.pawn_tapped.connect(_on_pawn_tapped)
	content.add_child(board)
	content.add_child(_corner_row(3, 2))
	content.add_child(_dice_panel())
	# Spare height on tall phones goes equally above and below the play area.
	content.add_child(UIKit.spacer())

	_finish_setup()
	resized.connect(_fit_board)
	_fit_board()
	board.sync(local_match.state)
	_refresh_ui()
	_start_dice_pulse()


func _fit_board() -> void:
	var side := minf(minf(size.x, MAX_CONTENT_WIDTH) - 72.0, size.y - NON_BOARD_HEIGHT)
	board.custom_minimum_size = Vector2(0, maxf(side, 280.0))


func _pausable() -> Node:
	return board


# --- Turn flow ----------------------------------------------------------

func _on_dice_pressed() -> void:
	if _busy or is_paused() or local_match.state.phase != MatchState.Phase.AWAITING_ROLL:
		return
	_busy = true
	_stop_dice_pulse()
	var events := local_match.roll()
	await _animate_dice(local_match.state.last_roll)
	await _play_events(events)
	_busy = false
	_after_events()


func _on_pawn_tapped(seat: int, pawn: int) -> void:
	if _busy or is_paused():
		return
	for candidate in local_match.legal_moves():
		if candidate.seat == seat and candidate.pawn == pawn:
			_perform_move(candidate)
			return


func _perform_move(chosen: LudoMove) -> void:
	_busy = true
	board.set_selectable([] as Array[Vector2i])
	var events := local_match.move(chosen)
	await _play_events(events)
	_busy = false
	_after_events()


## Decides what the player does next once all animations have finished.
func _after_events() -> void:
	_refresh_ui()
	var state := local_match.state
	if state.phase == MatchState.Phase.GAME_OVER:
		_finish_match(local_match.ranking())
		return
	if state.phase == MatchState.Phase.AWAITING_ROLL:
		_start_dice_pulse()
		return
	var moves := local_match.legal_moves()
	if _all_same_move(moves):
		# Only one real choice: move it automatically.
		_busy = true
		await _wait(AUTO_MOVE_DELAY)
		_perform_move(moves[0])
		return
	var ids: Array[Vector2i] = []
	for candidate in moves:
		ids.append(Vector2i(candidate.seat, candidate.pawn))
	board.set_selectable(ids)


## True when every legal move ends the same way (e.g. several pawns in base and a six).
func _all_same_move(moves: Array[LudoMove]) -> bool:
	for candidate in moves:
		if candidate.from != moves[0].from or candidate.to != moves[0].to:
			return false
	return not moves.is_empty()


func _play_events(events: Array[GameEvent]) -> void:
	for event in events:
		var d := event.data
		match event.type:
			GameEvent.Type.PAWN_MOVED:
				await board.animate_move(d["seat"], d["pawn"], d["from"], d["to"])
			GameEvent.Type.PAWN_CAPTURED:
				await _play_capture(d["seat"], d["pawn"], d["victim_seat"], d["victim_pawn"])
			GameEvent.Type.PAWN_FINISHED:
				_show_banner("Pawn home!", Palette.seat_color(d["seat"]))
				await _wait(0.4)
			GameEvent.Type.PLAYER_FINISHED:
				_show_banner("%s brought all pawns home!" % _name(d["seat"]), Palette.seat_color(d["seat"]))
				for pawn in BoardLayout.PAWNS_PER_PLAYER:
					CaptureAnimator.celebrate(board, board.pawn_node(d["seat"], pawn), board.cell_size())
				await _wait(1.0)
			GameEvent.Type.EXTRA_TURN:
				_show_banner("Roll again!", Palette.ACCENT)
				await _wait(0.35)
			GameEvent.Type.NO_MOVES:
				_show_banner("No moves", Palette.TEXT_MUTED)
				await _wait(0.7)
			GameEvent.Type.THREE_SIXES:
				_show_banner("Three sixes - turn over", Palette.TEXT_MUTED)
				await _wait(0.9)
	board.sync(local_match.state)


## Random cartoon attack, opponent back to base, attacker celebrates.
## Runs only for a PAWN_CAPTURED event from the rules.
func _play_capture(seat: int, pawn: int, victim_seat: int, victim_pawn: int) -> void:
	var attacker := board.pawn_node(seat, pawn)
	var victim := board.pawn_node(victim_seat, victim_pawn)
	if attacker == null or victim == null:
		return
	last_capture_style = CaptureAnimator.pick_style(_rng, last_capture_style)
	captures_played += 1
	_show_banner("%s captured %s!" % [_name(seat), _name(victim_seat)], Palette.seat_color(seat))
	await CaptureAnimator.play(board, attacker, victim, last_capture_style, board.cell_size(), board.base_position(victim_seat, victim_pawn))
	await CaptureAnimator.celebrate(board, attacker, board.cell_size())


func _refresh_ui() -> void:
	var state := local_match.state
	_refresh_panels(state.current_seat(), state.phase == MatchState.Phase.GAME_OVER)
	match state.phase:
		MatchState.Phase.AWAITING_ROLL:
			_hint_label.text = "Tap the dice to roll"
		MatchState.Phase.AWAITING_MOVE:
			_hint_label.text = "Tap a glowing pawn to move it %d" % state.last_roll
		_:
			_hint_label.text = "Match over"


func _panel_status(seat: int) -> String:
	return "Home %d/4" % local_match.state.pawns_finished(seat)
