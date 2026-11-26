class_name CaptureAnimator
extends RefCounted
## Plays the capture sequence when the rules report PAWN_CAPTURED (and only then):
##   1. the two pawns step apart and face each other
##   2. the attacker raises its arm and a cartoon prop appears in its hand
##   3. a random attack: toy blaster ZAP, sword SWISH, hammer BONK or wand POOF
##   4. the opponent reacts (squash, shake, dizzy stars)
##   5. the prop disappears (the caller then sends the opponent back to base)
## celebrate() is the attacker's happy jump afterwards. Family-friendly: no blood.

enum Style { BLASTER, SWORD, HAMMER, WAND }

const STYLE_NAMES := ["Blaster", "Sword", "Hammer", "Magic wand"]


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


static func play(host: Node, attacker: PawnToken, victim: PawnToken, style: int, cell: float) -> void:
	# 1. Step apart and face each other.
	var centre := victim.position
	var gap := Vector2(cell * 0.55, 0)
	var tween := host.create_tween().set_parallel()
	tween.tween_property(attacker, "position", centre - gap, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_property(victim, "position", centre + gap, 0.18).set_trans(Tween.TRANS_SINE)
	await tween.finished
	attacker.facing = 1.0
	victim.facing = -1.0
	var target := victim.position + Vector2(0, -cell * 0.35)

	# 2. Arm up, prop pops into the hand.
	attacker.prop = prop_for(style)
	attacker.prop_scale = 0.0
	attacker.prop_angle = 0.0
	tween = host.create_tween().set_parallel()
	tween.tween_property(attacker, "arm_raise", 1.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(attacker, "prop_scale", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

	# 3. The attack itself.
	match style:
		Style.BLASTER:
			await _effect(host, CaptureEffect.Kind.BEAM, attacker.hand_position(), target, Color.from_hsv(randf(), 0.6, 1.0), cell, "", 0.45)
			_effect(host, CaptureEffect.Kind.BURST, target, target, Color("7df9ff"), cell * 1.2, "ZAP!", 0.7)
		Style.SWORD:
			tween = host.create_tween().set_parallel()
			tween.tween_property(attacker, "position", centre - gap * 0.2, 0.1)
			tween.tween_property(attacker, "prop_angle", 1.1, 0.16).from(-1.3)
			await tween.finished
			_effect(host, CaptureEffect.Kind.SLASH, target, target, Color("bfe9ff"), cell * 0.75, "", 0.4)
			_effect(host, CaptureEffect.Kind.BURST, target, target, Color("ffe066"), cell * 1.1, "SWISH!", 0.7)
			tween = host.create_tween()
			tween.tween_property(attacker, "position", centre - gap, 0.14)
			await tween.finished
		Style.HAMMER:
			tween = host.create_tween()
			tween.tween_property(attacker, "prop_angle", -1.7, 0.18).from(0.0).set_trans(Tween.TRANS_SINE)
			tween.tween_property(attacker, "prop_angle", 0.9, 0.09).from(-1.7)
			await tween.finished
			victim.squash = Vector2(1.45, 0.45)
			_effect(host, CaptureEffect.Kind.BURST, target, target, Color("ff9f43"), cell * 1.2, "BONK!", 0.7)
		_:
			tween = host.create_tween()
			tween.tween_property(attacker, "prop_angle", 0.5, 0.25).from(-0.5).set_trans(Tween.TRANS_SINE)
			await tween.finished
			await _effect(host, CaptureEffect.Kind.SPARKLES, attacker.hand_position(), target, Color.WHITE, cell, "", 0.4)
			_effect(host, CaptureEffect.Kind.POOF, target, target, Color.WHITE, cell, "", 0.6)
			_effect(host, CaptureEffect.Kind.BURST, target, target, Color("d9a7ff"), cell * 1.1, "POOF!", 0.7)

	# 4. Hit reaction: squash, shake and dizzy stars.
	victim.dizzy = true
	var base := victim.position
	tween = host.create_tween()
	tween.tween_property(victim, "squash", Vector2(1.25, 0.7), 0.06)
	for i in 4:
		tween.tween_property(victim, "position", base + Vector2(cell * 0.08 * (1 if i % 2 == 0 else -1), 0), 0.05)
	tween.tween_property(victim, "position", base, 0.05)
	tween.tween_property(victim, "squash", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	await tween.finished

	# 5. Prop disappears, arm comes down.
	tween = host.create_tween().set_parallel()
	tween.tween_property(attacker, "prop_scale", 0.0, 0.15)
	tween.tween_property(attacker, "arm_raise", 0.0, 0.2)
	await tween.finished
	reset_pose(attacker)
	victim.dizzy = false
	victim.squash = Vector2.ONE


## A happy double jump with confetti.
static func celebrate(host: Node, pawn: PawnToken, cell: float) -> void:
	_effect(host, CaptureEffect.Kind.CONFETTI, pawn.position, pawn.position + Vector2(0, -cell * 0.6), Color.WHITE, cell, "", 0.9)
	var tween := host.create_tween()
	for i in 2:
		tween.tween_property(pawn, "arm_raise", 1.0, 0.08)
		tween.parallel().tween_property(pawn, "lift", cell * 0.45, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(pawn, "lift", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(pawn, "squash", Vector2(1.15, 0.85), 0.07).set_delay(0.07)
		tween.tween_property(pawn, "squash", Vector2.ONE, 0.08)
	tween.tween_property(pawn, "arm_raise", 0.0, 0.12)
	await tween.finished
	pawn.lift = 0.0


## Clears every capture-only pose, so nothing is left in the pawn's hand.
static func reset_pose(pawn: PawnToken) -> void:
	pawn.prop = PawnToken.Prop.NONE
	pawn.prop_scale = 1.0
	pawn.prop_angle = 0.0
	pawn.arm_raise = 0.0


## Adds an effect to the board, runs it, and frees it when done.
static func _effect(host: Node, kind: int, from: Vector2, to: Vector2, color: Color, size_px: float, text: String, duration: float) -> void:
	var effect := CaptureEffect.create(kind, from, to, color, size_px, text)
	host.add_child(effect)
	var tween := host.create_tween()
	tween.tween_property(effect, "progress", 1.0, duration)
	tween.tween_callback(effect.queue_free)
	await tween.finished
