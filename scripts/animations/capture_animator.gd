class_name CaptureAnimator
extends RefCounted
## Plays the capture sequence when the rules report PAWN_CAPTURED (and only then):
##   1. the camera zooms into the fight; the two pawns step apart, grow and face off
##   2. the attacker raises its arm and a cartoon prop appears in its hand
##   3. a random attack with charge-up, impact flash, shockwave, debris and board shake:
##      toy blaster (ZAP!), sword combo (SWISH!), hammer smash (BONK!) or magic wand (POOF!)
##   4. a short freeze on impact, then the opponent is knocked flying, spinning, back
##      to its base while the camera zooms out, with a big K.O.!
## celebrate() is the attacker's happy jump afterwards. Family-friendly: no blood.

enum Style { BLASTER, SWORD, HAMMER, WAND }

const STYLE_NAMES := ["Blaster", "Sword", "Hammer", "Magic wand"]
const ZOOM := 1.7


## A random style, never the same one twice in a row.
static func pick_style(rng: RandomNumberGenerator, previous: int = -1) -> int:
	var style := rng.randi_range(0, Style.size() - 1)
	if style == previous:
		style = (style + 1 + rng.randi_range(0, Style.size() - 2)) % Style.size()
	return style


static func prop_for(style: int) -> int:
	match style:
		Style.BLASTER:
			return PawnToken.Prop.BLASTER
		Style.SWORD:
			return PawnToken.Prop.SWORD
		Style.HAMMER:
			return PawnToken.Prop.HAMMER
	return PawnToken.Prop.WAND


## `home` is where the opponent lands (its base slot), in the host's coordinates.
static func play(host: Control, attacker: PawnToken, victim: PawnToken, style: int, cell: float, home: Vector2) -> void:
	var centre := victim.position
	var gap := Vector2(cell * 0.9, 0)
	var big := cell * 0.75
	attacker.z_index = 5
	victim.z_index = 5

	# 1. Zoom in on the fight; step apart, grow, face off.
	host.pivot_offset = centre
	var tween := host.create_tween().set_parallel()
	tween.tween_property(host, "scale", Vector2(ZOOM, ZOOM), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(attacker, "position", centre - gap, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(victim, "position", centre + gap, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(attacker, "radius", big, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(victim, "radius", big, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	attacker.facing = 1.0
	victim.facing = -1.0
	var target := victim.position + Vector2(0, -big * 1.1)

	# 2. Crouch, arm up, prop pops into the hand.
	attacker.prop = prop_for(style)
	attacker.prop_scale = 0.0
	attacker.prop_angle = 0.0
	tween = host.create_tween()
	tween.tween_property(attacker, "squash", Vector2(1.1, 0.88), 0.1)
	tween.tween_property(attacker, "squash", Vector2.ONE, 0.12)
	tween.parallel().tween_property(attacker, "arm_raise", 1.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(attacker, "prop_scale", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

	# 3. The attack.
	match style:
		Style.BLASTER:
			var beam_color := Color.from_hsv(randf(), 0.65, 1.0)
			await _effect(host, CaptureEffect.Kind.CHARGE, attacker.hand_position(), attacker.hand_position(), beam_color, cell, "", 0.45)
			tween = host.create_tween()
			tween.tween_property(attacker, "position", centre - gap * 1.25, 0.06)
			tween.tween_property(attacker, "position", centre - gap, 0.18)
			_effect(host, CaptureEffect.Kind.FLASH, attacker.hand_position(), attacker.hand_position(), Color.WHITE, cell * 0.6, "", 0.2)
			await _effect(host, CaptureEffect.Kind.BEAM, attacker.hand_position(), target, beam_color, cell, "", 0.35)
			_impact(host, target, beam_color, cell, "ZAP!", 1.0)
		Style.SWORD:
			_effect(host, CaptureEffect.Kind.SPEEDLINES, centre, centre, Color.WHITE, cell, "", 0.4)
			tween = host.create_tween()
			tween.tween_property(attacker, "position", centre - gap * 0.35, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await tween.finished
			for i in 3:
				tween = host.create_tween()
				var from_angle := -1.4 if i % 2 == 0 else 1.2
				tween.tween_property(attacker, "prop_angle", -from_angle, 0.1).from(from_angle)
				var slash := CaptureEffect.create(CaptureEffect.Kind.SLASH, target, target, Color("bfe9ff"), cell * 0.9)
				slash.angle = i * 1.1
				_run(host, slash, 0.3)
				_shake(host, 0.012, 0.12)
				await tween.finished
			_impact(host, target, Color("ffe066"), cell, "SWISH!", 0.8)
			tween = host.create_tween()
			tween.tween_property(attacker, "position", centre - gap, 0.15)
		Style.HAMMER:
			tween = host.create_tween()
			tween.tween_property(attacker, "prop_angle", -2.3, 0.35).from(0.0).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(attacker, "squash", Vector2(0.92, 1.1), 0.35)
			tween.tween_interval(0.1)
			tween.tween_property(attacker, "prop_angle", 1.0, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(attacker, "squash", Vector2(1.12, 0.9), 0.07)
			await tween.finished
			attacker.squash = Vector2.ONE
			victim.squash = Vector2(1.7, 0.3)
			_effect(host, CaptureEffect.Kind.SHOCKWAVE, victim.position, victim.position, Color("ffcf70"), cell * 1.2, "", 0.5)
			_impact(host, target, Color("ff9f43"), cell, "BONK!", 1.3)
		_:
			tween = host.create_tween()
			tween.tween_property(attacker, "prop_angle", 0.6, 0.3).from(-0.6).set_trans(Tween.TRANS_SINE)
			await tween.finished
			await _effect(host, CaptureEffect.Kind.CHARGE, attacker.hand_position(), attacker.hand_position(), Color("d9a7ff"), cell, "", 0.3)
			await _effect(host, CaptureEffect.Kind.SPARKLES, attacker.hand_position(), target, Color.WHITE, cell, "", 0.4)
			_effect(host, CaptureEffect.Kind.POOF, target, target, Color.WHITE, cell * 1.3, "", 0.7)
			_impact(host, target, Color("d9a7ff"), cell, "POOF!", 0.9)

	# 4. Freeze for a beat, opponent reacts, then gets knocked flying home.
	victim.knocked_out = true
	var base := victim.position
	tween = host.create_tween()
	tween.tween_property(victim, "squash", Vector2(1.3, 0.65), 0.05)
	tween.tween_interval(0.14)
	for i in 4:
		tween.tween_property(victim, "position", base + Vector2(cell * 0.1 * (1 if i % 2 == 0 else -1), 0), 0.04)
	tween.tween_property(victim, "squash", Vector2.ONE, 0.1)
	await tween.finished

	tween = host.create_tween().set_parallel()
	tween.tween_property(attacker, "prop_scale", 0.0, 0.2)
	tween.tween_property(attacker, "arm_raise", 0.0, 0.25)
	await knockback(host, victim, home, cell, true)
	reset_pose(attacker)
	victim.dizzy = false
	victim.knocked_out = false
	victim.squash = Vector2.ONE
	victim.z_index = 0


## Sends a pawn flying in a high, spinning arc to `home`, zooming the camera back out.
static func knockback(host: Control, pawn: PawnToken, home: Vector2, cell: float, zoom_out: bool) -> void:
	var start := pawn.position
	_effect(host, CaptureEffect.Kind.BURST, start + Vector2(0, -cell), start + Vector2(0, -cell), Color("ff5d5d"), cell * 2.2, "K.O.!", 1.0)
	var flight := host.create_tween().set_parallel()
	pawn.fly_start = start
	pawn.fly_end = home
	pawn.fly_height = cell * 3.0 + start.distance_to(home) * 0.25
	flight.tween_method(pawn.set_fly, 0.0, 1.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flight.tween_property(pawn, "radius", cell * 0.52, 0.85)
	if zoom_out:
		flight.tween_property(host, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.15)
	await flight.finished
	pawn.rotation = 0.0
	pawn.position = home
	host.rotation = 0.0
	_effect(host, CaptureEffect.Kind.DUST, home + Vector2(0, cell * 0.4), home + Vector2(0, cell * 0.4), Color.WHITE, cell, "", 0.4)
	var land := host.create_tween()
	land.tween_property(pawn, "squash", Vector2(1.3, 0.7), 0.06)
	land.tween_property(pawn, "squash", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await land.finished


## Impact: flash, shockwave, debris, comic burst and a board shake.
static func _impact(host: Control, at: Vector2, color: Color, cell: float, word: String, strength: float) -> void:
	_effect(host, CaptureEffect.Kind.FLASH, at, at, Color.WHITE, cell * strength, "", 0.25)
	_effect(host, CaptureEffect.Kind.SHOCKWAVE, at, at, color, cell * strength, "", 0.45)
	_effect(host, CaptureEffect.Kind.DEBRIS, at, at, color, cell * strength, "", 0.8)
	_effect(host, CaptureEffect.Kind.BURST, at, at, color, cell * 1.9, word, 0.9)
	_shake(host, 0.03 * strength, 0.3)


## Shakes the board by wobbling its rotation for a moment.
static func _shake(host: Control, amount: float, duration: float) -> void:
	var tween := host.create_tween()
	var steps := 6
	for i in steps:
		var fade := 1.0 - float(i) / steps
		tween.tween_property(host, "rotation", amount * fade * (1.0 if i % 2 == 0 else -1.0), duration / steps)
	tween.tween_property(host, "rotation", 0.0, duration / steps)


## A happy double jump with confetti.
static func celebrate(host: Node, pawn: PawnToken, cell: float) -> void:
	_effect(host, CaptureEffect.Kind.CONFETTI, pawn.position, pawn.position + Vector2(0, -cell * 0.8), Color.WHITE, cell, "", 1.0)
	var tween := host.create_tween()
	for i in 2:
		tween.tween_property(pawn, "arm_raise", 1.0, 0.08)
		tween.parallel().tween_property(pawn, "lift", cell * 0.5, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(pawn, "lift", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(pawn, "squash", Vector2(1.15, 0.85), 0.07).set_delay(0.07)
		tween.tween_property(pawn, "squash", Vector2.ONE, 0.08)
	tween.tween_property(pawn, "arm_raise", 0.0, 0.12)
	await tween.finished
	pawn.lift = 0.0
	pawn.z_index = 0


## Clears every capture-only pose, so nothing is left in the pawn's hand.
static func reset_pose(pawn: PawnToken) -> void:
	pawn.prop = PawnToken.Prop.NONE
	pawn.prop_scale = 1.0
	pawn.prop_angle = 0.0
	pawn.arm_raise = 0.0
	pawn.squash = Vector2.ONE


static func _effect(host: Node, kind: int, from: Vector2, to: Vector2, color: Color, size_px: float, text: String, duration: float) -> void:
	await _run(host, CaptureEffect.create(kind, from, to, color, size_px, text), duration)


## Adds an effect to the board, runs it, and frees it when done.
static func _run(host: Node, effect: CaptureEffect, duration: float) -> void:
	host.add_child(effect)
	var tween := host.create_tween()
	tween.tween_property(effect, "progress", 1.0, duration)
	tween.tween_callback(effect.queue_free)
	await tween.finished
