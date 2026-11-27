class_name LudoBot
extends RefCounted
## A strong computer player for Classic Ludo. It scores every legal move like an
## experienced player would and picks the best one:
##   - capture, preferring opponents who are far along
##   - bring a pawn home / into the safe home column
##   - escape a pawn that an opponent could hit next roll
##   - avoid stopping where opponents can hit it; prefer safe squares
##   - bring new pawns out when it is useful, keep pawns moving forward
## Pure logic: no nodes or timing. The screen adds the human-like pauses.

const CAPTURE := 120.0
const CAPTURE_PROGRESS := 1.2
const FINISH := 90.0
const ENTER_HOME_COLUMN := 55.0
const START_PAWN := 48.0
const START_WHEN_NONE_OUT := 30.0
const SAFE_SQUARE := 22.0
const ESCAPE := 70.0
const DANGER := 85.0
const PROGRESS := 0.35
const LEAD_PAWN_BONUS := 0.1
const NEAR_HOME_EXACT := 6.0


## Picks the best move. `rng` breaks ties so the bot is not predictable.
static func choose_move(state: MatchState, rules: LudoRulesConfig, moves: Array[LudoMove], rng: RandomNumberGenerator = null) -> LudoMove:
	if moves.is_empty():
		return null
	var best: LudoMove = moves[0]
	var best_score := -INF
	for move in moves:
		var score := score_move(state, rules, move)
		if rng != null:
			score += rng.randf() * 0.5
		if score > best_score:
			best_score = score
			best = move
	return best


static func score_move(state: MatchState, rules: LudoRulesConfig, move: LudoMove) -> float:
	var seat := move.seat
	var score := 0.0
	var from_index := BoardLayout.progress_to_track_index(seat, move.from)
	var to_index := BoardLayout.progress_to_track_index(seat, move.to)

	# Starting a pawn.
	if move.from == MatchState.IN_BASE:
		score += START_PAWN
		if _pawns_out(state, seat) == 0:
			score += START_WHEN_NONE_OUT

	# Reaching home or the home column (both are completely safe).
	if move.to == BoardLayout.FINISH_PROGRESS:
		score += FINISH
	elif move.to > BoardLayout.LAST_TRACK_PROGRESS and move.from <= BoardLayout.LAST_TRACK_PROGRESS:
		score += ENTER_HOME_COLUMN

	# Capturing.
	if to_index >= 0 and not (rules.safe_squares_enabled and BoardLayout.is_safe_index(to_index)):
		for occupant in state.pawns_at_track_index(to_index):
			if occupant.x != seat:
				score += CAPTURE + state.pawn_progress(occupant.x, occupant.y) * CAPTURE_PROGRESS

	# Escaping danger where the pawn stands now.
	if from_index >= 0:
		score += ESCAPE * danger(state, rules, seat, from_index) * (0.5 + move.from / 100.0)

	# Danger where it would stop (worse for pawns that have come far).
	if to_index >= 0:
		if rules.safe_squares_enabled and BoardLayout.is_safe_index(to_index):
			score += SAFE_SQUARE
		else:
			score -= DANGER * danger(state, rules, seat, to_index) * (0.6 + move.to / 80.0)

	# Steady progress; slightly prefer moving pawns that are already ahead.
	score += (move.to - maxi(move.from, 0)) * PROGRESS
	score += maxi(move.from, 0) * LEAD_PAWN_BONUS
	# Inside the home column, getting close to the finish leaves easy exact rolls.
	if move.to > BoardLayout.LAST_TRACK_PROGRESS and move.to < BoardLayout.FINISH_PROGRESS:
		score += NEAR_HOME_EXACT * (move.to - BoardLayout.LAST_TRACK_PROGRESS) / 5.0
	return score


## Chance (0..1) that some opponent can land on this track square with its next roll.
static func danger(state: MatchState, rules: LudoRulesConfig, seat: int, track_index: int) -> float:
	if rules.safe_squares_enabled and BoardLayout.is_safe_index(track_index):
		return 0.0
	var safe_chance := 1.0
	for other in state.seats:
		if other == seat or state.finish_order.has(other):
			continue
		for pawn in BoardLayout.PAWNS_PER_PLAYER:
			var p := state.pawn_progress(other, pawn)
			if p == MatchState.IN_BASE:
				# A pawn in base can only hit the start square, with a starting roll.
				if track_index == BoardLayout.start_index(other):
					safe_chance *= 1.0 - rules.start_rolls.size() / 6.0
				continue
			if p > BoardLayout.LAST_TRACK_PROGRESS:
				continue
			var their_index := BoardLayout.progress_to_track_index(other, p)
			var distance := posmod(track_index - their_index, BoardLayout.TRACK_LENGTH)
			# They must reach it before turning into their own home column.
			if distance >= 1 and distance <= 6 and p + distance <= BoardLayout.LAST_TRACK_PROGRESS:
				safe_chance *= 5.0 / 6.0
	return 1.0 - safe_chance


static func _pawns_out(state: MatchState, seat: int) -> int:
	var count := 0
	for pawn in BoardLayout.PAWNS_PER_PLAYER:
		var p := state.pawn_progress(seat, pawn)
		if p != MatchState.IN_BASE and p != BoardLayout.FINISH_PROGRESS:
			count += 1
	return count
