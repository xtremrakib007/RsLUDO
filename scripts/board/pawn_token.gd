class_name PawnToken
extends Node2D
## A pawn drawn as a small cartoon person: shoes, legs with knees, trousers,
## shaded shirt with belt and collar, arms with elbows, a face with eyebrows,
## blinking eyes and a smile, and a hairstyle per colour.
## Poses for animation: a proper walk cycle (knees, arm swing, bob, lean),
## a raised arm holding a prop (only during a capture), squash, facing,
## dizzy stars, a knocked-out face, and a gentle idle bounce.
## Animations (board moves, CaptureAnimator) only set these properties.

enum Prop { NONE, BLASTER, SWORD, HAMMER, WAND }

var seat: int = 0:
	set(value):
		seat = value
		queue_redraw()
## Roughly half a board square. The figure is about 2 x radius tall.
var radius: float = 20.0:
	set(value):
		radius = maxf(value, 1.0)
		queue_redraw()
## Glowing ring showing this pawn can be moved.
var highlighted: bool = false:
	set(value):
		highlighted = value
		if not value:
			lift = 0.0
		queue_redraw()
## Height above the ground while hopping or flying, in pixels.
var lift: float = 0.0
## 1 faces right, -1 faces left.
var facing: float = 1.0
## 0 = arm down, 1 = front arm raised forward (holding the prop).
var arm_raise: float = 0.0
## What the front hand holds. Only capture animations set this; walking never does.
var prop: int = Prop.NONE
var prop_scale: float = 1.0
## Extra rotation of the held prop (for swings), radians.
var prop_angle: float = 0.0
## Body squash from the feet (hit reactions, landing).
var squash: Vector2 = Vector2.ONE
var dizzy: bool = false
## Knocked out: X eyes, no stars (used while flying back to base).
var knocked_out: bool = false
## Progress through the current walking step (0..1); 0 when standing.
var walk_t: float = 0.0
## Counts steps so the legs alternate.
var step_index: int = 0
## Ladder climbing: arms reach up alternately while > 0.
var climb_t: float = 0.0
var _time: float = 0.0
## Flight path used by set_fly() (knockback after a capture).
var fly_start: Vector2 = Vector2.ZERO
var fly_end: Vector2 = Vector2.ZERO
var fly_height: float = 0.0

const HAIR_COLORS := [Color("5a2e1a"), Color("1d1d26"), Color("c47a2c"), Color("2b1a12")]
const PANTS_COLOR := Color("34405e")
const SHOE_COLOR := Color("2a2230")


func _ready() -> void:
	_time = seat * 0.7


func _process(delta: float) -> void:
	_time += delta
	if highlighted:
		lift = absf(sin(_time * 4.5)) * radius * 0.3
	queue_redraw()


## Hop curve for one step: t goes 0 -> 1 over the step.
func set_hop(t: float) -> void:
	var clamped := clampf(t, 0.0, 1.0)
	lift = sin(clamped * PI) * radius * 0.35
	walk_t = clamped if clamped < 1.0 else 0.0
	# A little squash as the foot lands.
	var landing := clampf((clamped - 0.85) / 0.15, 0.0, 1.0)
	squash = Vector2(1.0 + 0.08 * sin(landing * PI), 1.0 - 0.08 * sin(landing * PI))


## Called once before each step so legs alternate.
func next_step(direction_x: float) -> void:
	step_index += 1
	if absf(direction_x) > 0.5:
		facing = signf(direction_x)


## Position along a high, spinning arc from fly_start to fly_end (t = 0..1).
func set_fly(t: float) -> void:
	position = fly_start.lerp(fly_end, t) + Vector2(0, -sin(t * PI) * fly_height)
	rotation = t * TAU * 2.0


func set_climb(t: float) -> void:
	climb_t = t


## Where the front hand is, in the parent's coordinates.
func hand_position() -> Vector2:
	return position + _body_transform() * _hand_local()


func _walking() -> bool:
	return walk_t > 0.0 and walk_t < 1.0


func _stride() -> float:
	return 1.0 if step_index % 2 == 0 else -1.0


func _body_transform() -> Transform2D:
	var r := radius
	var bob := 0.0
	if lift == 0.0 and not _walking():
		bob = sin(_time * 2.4) * r * 0.03
	elif _walking():
		bob = -absf(sin(walk_t * TAU)) * r * 0.06
	var lean := 0.1 * facing if _walking() else 0.0
	return Transform2D(lean, Vector2(facing * squash.x, squash.y), 0.0, Vector2(0, r * 0.95 - lift + bob))


# Joint positions (feet at y = 0, figure about 2r tall, facing +x).
func _shoulder(front: bool) -> Vector2:
	return Vector2(radius * (0.3 if front else -0.22), -radius * 1.12)


func _front_arm_angle() -> float:
	if climb_t > 0.0:
		return -PI * 0.5 + sin(climb_t * TAU * 3.0) * 0.5
	var swing := -cos(walk_t * PI) * 0.55 * _stride() if _walking() else 0.0
	var down := PI * 0.5 + swing
	return lerpf(down, -PI * 0.15, clampf(arm_raise, 0.0, 1.0))


func _back_arm_angle() -> float:
	if climb_t > 0.0:
		return -PI * 0.5 - sin(climb_t * TAU * 3.0) * 0.5
	var swing := cos(walk_t * PI) * 0.55 * _stride() if _walking() else 0.0
	return PI * 0.5 + swing


func _hand_local() -> Vector2:
	var angle := _front_arm_angle()
	var elbow := _shoulder(true) + Vector2.from_angle(angle) * radius * 0.32
	return elbow + Vector2.from_angle(angle - 0.25 * (1.0 - arm_raise)) * radius * 0.3


func _draw() -> void:
	var r := radius
	var shirt := Palette.seat_color(seat)
	var shirt_dark := shirt.darkened(0.25)
	var shirt_light := shirt.lightened(0.25)
	var outline := shirt.darkened(0.55)
	var skin := Palette.skin_tone(seat)
	var skin_dark := skin.darkened(0.18)
	var line_width := maxf(1.2, r * 0.06)

	if highlighted:
		var pulse := 0.5 + 0.5 * sin(_time * 6.0)
		var ring := r * (1.05 + 0.15 * pulse)
		draw_circle(Vector2(0, r * 0.25), ring, Color(Palette.ACCENT, 0.4))
		draw_arc(Vector2(0, r * 0.25), ring, 0.0, TAU, 40, Palette.ACCENT, maxf(3.0, r * 0.18), true)
		draw_arc(Vector2(0, r * 0.25), ring + r * 0.12, 0.0, TAU, 40, Color(1, 1, 1, 0.8), maxf(1.5, r * 0.06), true)

	# Ground shadow, smaller while in the air.
	var shadow_scale := 1.0 - clampf(lift / (r * 2.0), 0.0, 0.6)
	draw_set_transform(Vector2(0, r * 0.95), 0.0, Vector2(shadow_scale, 0.3 * shadow_scale))
	draw_circle(Vector2.ZERO, r * 0.6, Color(0, 0, 0, 0.3))

	var body_xf := _body_transform()
	draw_set_transform_matrix(body_xf)

	# Back arm, back leg, then front leg (so the front leg overlaps).
	_draw_arm(_shoulder(false), _back_arm_angle(), shirt_dark, skin_dark, false)
	_draw_leg(-1.0, r)
	_draw_leg(1.0, r)

	# Torso: shaded shirt, collar and belt.
	var torso := PackedVector2Array([
		Vector2(-r * 0.32, -r * 0.6), Vector2(-r * 0.36, -r * 1.05), Vector2(-r * 0.22, -r * 1.2),
		Vector2(r * 0.22, -r * 1.2), Vector2(r * 0.38, -r * 1.05), Vector2(r * 0.34, -r * 0.6),
	])
	draw_colored_polygon(torso, shirt)
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.32, -r * 0.6), Vector2(-r * 0.36, -r * 1.05), Vector2(-r * 0.22, -r * 1.2), Vector2(-r * 0.12, -r * 1.2), Vector2(-r * 0.16, -r * 0.6)]), shirt_dark)
	draw_line(Vector2(r * 0.18, -r * 1.05), Vector2(r * 0.2, -r * 0.7), shirt_light, r * 0.07, true)
	draw_rect(Rect2(Vector2(-r * 0.33, -r * 0.68), Vector2(r * 0.67, r * 0.1)), Color("3a2a1e"))
	draw_rect(Rect2(Vector2(-r * 0.05, -r * 0.69), Vector2(r * 0.1, r * 0.12)), Color("e2b23a"))
	var torso_outline := torso.duplicate()
	torso_outline.append(torso[0])
	draw_polyline(torso_outline, outline, line_width, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.14, -r * 1.2), Vector2(0, -r * 1.06), Vector2(r * 0.14, -r * 1.2)]), shirt_light)

	# Neck and head.
	draw_rect(Rect2(Vector2(-r * 0.08, -r * 1.3), Vector2(r * 0.16, r * 0.14)), skin_dark)
	_draw_head(Vector2(0, -r * 1.62), r * 0.4, skin, skin_dark, outline, line_width)

	# Front arm, with the prop in its hand during a capture.
	_draw_arm(_shoulder(true), _front_arm_angle(), shirt, skin, true)
	if prop != Prop.NONE and prop_scale > 0.01:
		var prop_xf := body_xf * Transform2D(_front_arm_angle() + prop_angle, Vector2(prop_scale, prop_scale), 0.0, _hand_local())
		draw_set_transform_matrix(prop_xf)
		_draw_prop(r)
		draw_set_transform_matrix(body_xf)

	if dizzy:
		var head := Vector2(0, -r * 1.62)
		for i in 3:
			var a := _time * 5.0 + i * TAU / 3.0
			var p := head + Vector2(cos(a) * r * 0.5, -r * 0.5 + sin(a) * r * 0.14)
			_draw_star(p, r * 0.13, Palette.ACCENT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_leg(side: float, r: float) -> void:
	# side -1 = back leg, 1 = front leg. During a step one leg swings forward and bends.
	var hip := Vector2(side * r * 0.12, -r * 0.62)
	var swing := 0.0
	var bend := 0.0
	if _walking():
		var forward := side * _stride()
		swing = -cos(walk_t * PI) * 0.45 * forward
		bend = sin(walk_t * PI) * 0.8 if forward > 0.0 else 0.0
	var thigh_dir := Vector2.from_angle(PI * 0.5 - swing)
	var knee := hip + thigh_dir * r * 0.32
	var shin_dir := Vector2.from_angle(PI * 0.5 - swing + bend)
	var foot := knee + shin_dir * r * 0.3
	var pants := PANTS_COLOR if side > 0 else PANTS_COLOR.darkened(0.2)
	draw_line(hip, knee, pants, r * 0.2, true)
	draw_line(knee, foot, pants, r * 0.18, true)
	draw_circle(knee, r * 0.09, pants)
	var shoe := PackedVector2Array([foot + Vector2(-r * 0.09, -r * 0.06), foot + Vector2(r * 0.2, -r * 0.05), foot + Vector2(r * 0.22, r * 0.04), foot + Vector2(-r * 0.1, r * 0.04)])
	draw_colored_polygon(shoe, SHOE_COLOR if side > 0 else SHOE_COLOR.lightened(0.1))


func _draw_arm(shoulder: Vector2, angle: float, sleeve: Color, skin: Color, front: bool) -> void:
	var r := radius
	var elbow := shoulder + Vector2.from_angle(angle) * r * 0.32
	var forearm_angle := angle - (0.25 * (1.0 - arm_raise) if front else -0.25)
	var hand := elbow + Vector2.from_angle(forearm_angle) * r * 0.3
	draw_line(shoulder, elbow, sleeve, r * 0.17, true)
	draw_circle(shoulder, r * 0.1, sleeve)
	draw_line(elbow, hand, skin, r * 0.13, true)
	draw_circle(hand, r * 0.09, skin)


func _draw_head(centre: Vector2, head_r: float, skin: Color, skin_dark: Color, outline: Color, line_width: float) -> void:
	var hair: Color = HAIR_COLORS[seat % HAIR_COLORS.size()]
	# Back hair (ponytail / long hair) behind the head.
	if seat == 1:
		draw_circle(centre + Vector2(-head_r * 1.0, head_r * 0.1), head_r * 0.38, hair)
	if seat == 3:
		for i in 5:
			draw_circle(centre + Vector2(-head_r * 0.9 + i * head_r * 0.15, -head_r * 0.2 + (i % 2) * head_r * 0.2), head_r * 0.35, hair)
	# Ear, face with a shaded side.
	draw_circle(centre + Vector2(-head_r * 0.85, head_r * 0.1), head_r * 0.2, skin_dark)
	draw_circle(centre, head_r, skin)
	draw_arc(centre, head_r * 0.92, PI * 0.55, PI * 1.25, 16, skin_dark, head_r * 0.15, true)
	draw_arc(centre, head_r, 0.0, TAU, 32, skin_dark.darkened(0.3), line_width, true)
	# Hair styles per colour.
	match seat:
		0:
			draw_arc(centre, head_r * 0.9, PI * 1.05, PI * 1.98, 16, hair, head_r * 0.4, true)
			for i in 4:
				var base := centre + Vector2(-head_r * 0.6 + i * head_r * 0.4, -head_r * 0.85)
				draw_colored_polygon(PackedVector2Array([base + Vector2(-head_r * 0.2, 0), base + Vector2(0, -head_r * 0.4), base + Vector2(head_r * 0.2, 0)]), hair)
		1:
			draw_arc(centre, head_r * 0.92, PI * 0.95, PI * 2.05, 18, hair, head_r * 0.42, true)
		2:
			# Cap in a contrasting colour.
			draw_arc(centre, head_r * 0.92, PI * 1.0, PI * 2.0, 18, Color("2f7fe0"), head_r * 0.5, true)
			draw_line(centre + Vector2(head_r * 0.2, -head_r * 0.55), centre + Vector2(head_r * 1.25, -head_r * 0.45), Color("2f7fe0"), head_r * 0.18, true)
			draw_arc(centre + Vector2(-head_r * 0.7, -head_r * 0.1), head_r * 0.25, PI * 0.5, PI * 1.5, 8, hair, head_r * 0.2, true)
		_:
			for i in 6:
				draw_circle(centre + Vector2(-head_r * 0.7 + i * head_r * 0.28, -head_r * 0.75 - (i % 2) * head_r * 0.1), head_r * 0.3, hair)
	# Face, looking the way the pawn faces (+x).
	var eye_y := centre.y + head_r * 0.05
	if knocked_out or dizzy:
		for ex in [head_r * 0.05, head_r * 0.5]:
			var e := Vector2(centre.x + ex, eye_y)
			draw_line(e + Vector2(-1, -1) * head_r * 0.12, e + Vector2(1, 1) * head_r * 0.12, Palette.TEXT_DARK, line_width, true)
			draw_line(e + Vector2(-1, 1) * head_r * 0.12, e + Vector2(1, -1) * head_r * 0.12, Palette.TEXT_DARK, line_width, true)
		draw_circle(centre + Vector2(head_r * 0.3, head_r * 0.5), head_r * 0.13, Color("7a2a2a"))
		return
	var blink := fmod(_time + seat * 1.3, 3.7) < 0.12
	for ex in [head_r * 0.05, head_r * 0.5]:
		var e := Vector2(centre.x + ex, eye_y)
		if blink:
			draw_line(e + Vector2(-head_r * 0.12, 0), e + Vector2(head_r * 0.12, 0), Palette.TEXT_DARK, line_width, true)
		else:
			draw_circle(e, head_r * 0.17, Color.WHITE)
			draw_circle(e + Vector2(head_r * 0.06, head_r * 0.02), head_r * 0.1, Palette.TEXT_DARK)
			draw_circle(e + Vector2(head_r * 0.1, -head_r * 0.04), head_r * 0.035, Color.WHITE)
		# Eyebrows: angry while attacking.
		var tilt := 0.12 if arm_raise > 0.5 else -0.04
		draw_line(e + Vector2(-head_r * 0.14, -head_r * (0.26 + tilt)), e + Vector2(head_r * 0.14, -head_r * (0.26 - tilt)), hair, line_width * 1.1, true)
	draw_circle(centre + Vector2(head_r * 0.42, head_r * 0.3), head_r * 0.08, skin_dark)
	if arm_raise > 0.5:
		draw_arc(centre + Vector2(head_r * 0.3, head_r * 0.52), head_r * 0.18, 0.1, PI - 0.1, 8, Palette.TEXT_DARK, line_width, true)
	else:
		draw_arc(centre + Vector2(head_r * 0.3, head_r * 0.45), head_r * 0.2, 0.3, PI - 0.3, 8, Color("8a3a3a"), line_width, true)
	draw_circle(centre + Vector2(head_r * 0.62, head_r * 0.35), head_r * 0.1, Color(1.0, 0.45, 0.45, 0.35))


## Props point along +x from the hand. Bright toy colours: cartoon, not realistic weapons.
func _draw_prop(r: float) -> void:
	match prop:
		Prop.BLASTER:
			draw_rect(Rect2(Vector2(-r * 0.05, -r * 0.13), Vector2(r * 0.45, r * 0.24)), Color("8e5bd6"))
			draw_rect(Rect2(Vector2(r * 0.38, -r * 0.07), Vector2(r * 0.25, r * 0.12)), Color("3dd6c4"))
			draw_circle(Vector2(r * 0.65, -r * 0.01), r * 0.08, Color("f6c026"))
			draw_rect(Rect2(Vector2(-r * 0.02, r * 0.08), Vector2(r * 0.12, r * 0.2)), Color("5a3a9a"))
			draw_circle(Vector2(r * 0.16, -r * 0.16), r * 0.06, Color("e8413c"))
		Prop.SWORD:
			var blade := PackedVector2Array([Vector2(r * 0.12, -r * 0.06), Vector2(r * 0.95, -r * 0.04), Vector2(r * 1.08, 0), Vector2(r * 0.95, r * 0.04), Vector2(r * 0.12, r * 0.06)])
			draw_colored_polygon(blade, Color("dfe8f2"))
			draw_polyline(blade, Color("7a8aa0"), maxf(1.0, r * 0.035), true)
			draw_line(Vector2(r * 0.1, -r * 0.18), Vector2(r * 0.1, r * 0.18), Color("f6c026"), r * 0.08, true)
			draw_line(Vector2(-r * 0.1, 0), Vector2(r * 0.08, 0), Color("8a4b1f"), r * 0.11, true)
		Prop.HAMMER:
			draw_line(Vector2(-r * 0.08, 0), Vector2(r * 0.65, 0), Color("c98a45"), r * 0.1, true)
			draw_rect(Rect2(Vector2(r * 0.6, -r * 0.28), Vector2(r * 0.34, r * 0.56)), Color("e8413c"))
			draw_rect(Rect2(Vector2(r * 0.6, -r * 0.28), Vector2(r * 0.34, r * 0.1)), Color("f6c026"))
			draw_rect(Rect2(Vector2(r * 0.6, r * 0.18), Vector2(r * 0.34, r * 0.1)), Color("f6c026"))
		Prop.WAND:
			draw_line(Vector2(-r * 0.05, 0), Vector2(r * 0.6, 0), Palette.TEXT_DARK, r * 0.08, true)
			draw_line(Vector2(r * 0.48, 0), Vector2(r * 0.6, 0), Color.WHITE, r * 0.08, true)
			_draw_star(Vector2(r * 0.7, 0), r * 0.22, Palette.ACCENT)


func _draw_star(centre: Vector2, outer: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var rr := outer if i % 2 == 0 else outer * 0.45
		var a := -PI / 2.0 + i * PI / 5.0
		points.append(centre + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(points, color)
