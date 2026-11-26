class_name PawnToken
extends Node2D
## A pawn drawn as a small cartoon person, with simple poses for animation:
## walking legs and arms, a raised arm holding a prop (only during a capture),
## squash, facing direction, dizzy stars, and a gentle idle bounce.
## Animations (board moves, CaptureAnimator) only set these properties.

enum Prop { NONE, BLASTER, SWORD, HAMMER, WAND }

var seat: int = 0:
	set(value):
		seat = value
		queue_redraw()
## Roughly half a board square.
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
## Height above the ground while hopping or jumping, in pixels.
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
## Progress through the current walking step (0..1); 0 when standing.
var walk_t: float = 0.0
## Counts steps so the legs alternate.
var step_index: int = 0
## Ladder climbing: arms reach up alternately while > 0.
var climb_t: float = 0.0
var _time: float = 0.0


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
	lift = sin(clamped * PI) * radius * 0.6
	walk_t = clamped if clamped < 1.0 else 0.0


## Called once before each step so legs alternate.
func next_step(direction_x: float) -> void:
	step_index += 1
	if absf(direction_x) > 0.5:
		facing = signf(direction_x)


func set_climb(t: float) -> void:
	climb_t = t


## Where the front hand is, in the parent's coordinates.
func hand_position() -> Vector2:
	return position + _body_transform() * _hand_local()


func _body_transform() -> Transform2D:
	var r := radius
	var bob := sin(_time * 2.4) * r * 0.035 if lift == 0.0 else 0.0
	return Transform2D(0.0, Vector2(facing * squash.x, squash.y), 0.0, Vector2(0, r * 0.95 - lift + bob))


## Arm angles (radians, 0 = pointing right/forward, PI/2 = straight down).
func _front_arm_angle() -> float:
	if climb_t > 0.0:
		return -PI * 0.5 + sin(climb_t * TAU * 3.0) * 0.5
	var down := PI * 0.5 - sin(walk_t * PI) * _stride() * 0.9
	return lerpf(down, -PI * 0.2, clampf(arm_raise, 0.0, 1.0))


func _back_arm_angle() -> float:
	if climb_t > 0.0:
		return -PI * 0.5 - sin(climb_t * TAU * 3.0) * 0.5
	return PI * 0.5 + sin(walk_t * PI) * _stride() * 0.9


func _stride() -> float:
	return 1.0 if step_index % 2 == 0 else -1.0


func _shoulder(front: bool) -> Vector2:
	var r := radius
	return Vector2(r * (0.36 if front else -0.36), -r * 0.82)


func _hand_local() -> Vector2:
	return _shoulder(true) + Vector2.from_angle(_front_arm_angle()) * radius * 0.48


func _draw() -> void:
	var r := radius
	var body_color := Palette.seat_color(seat)
	var outline := body_color.darkened(0.45)
	var skin := Palette.skin_tone(seat)
	var line_width := maxf(1.5, r * 0.09)

	if highlighted:
		var pulse := 0.5 + 0.5 * sin(_time * 6.0)
		var ring := r * (1.05 + 0.15 * pulse)
		draw_circle(Vector2(0, r * 0.25), ring, Color(Palette.ACCENT, 0.4))
		draw_arc(Vector2(0, r * 0.25), ring, 0.0, TAU, 40, Palette.ACCENT, maxf(3.0, r * 0.18), true)
		draw_arc(Vector2(0, r * 0.25), ring + r * 0.12, 0.0, TAU, 40, Color(1, 1, 1, 0.8), maxf(1.5, r * 0.06), true)

	# Ground shadow (squashed circle), smaller while in the air.
	var shadow_scale := 1.0 - clampf(lift / (r * 1.4), 0.0, 0.5)
	draw_set_transform(Vector2(0, r * 0.95), 0.0, Vector2(shadow_scale, 0.3 * shadow_scale))
	draw_circle(Vector2.ZERO, r * 0.72, Color(0, 0, 0, 0.28))

	# Everything below is drawn relative to the feet (y = 0 at the ground).
	var body_xf := _body_transform()
	draw_set_transform_matrix(body_xf)

	# Legs and feet, swinging while walking.
	var swing := sin(walk_t * PI) * r * 0.2 * _stride()
	var leg_color := outline.lerp(Palette.TEXT_DARK, 0.4)
	for side in [-1.0, 1.0]:
		var hip := Vector2(side * r * 0.22, -r * 0.3)
		var foot := Vector2(side * r * 0.24 + swing * side, -r * 0.04 - absf(swing) * 0.4 * (1.0 if side > 0 else 0.0))
		draw_line(hip, foot, leg_color, r * 0.17, true)
		draw_circle(foot + Vector2(r * 0.06, 0), r * 0.1, leg_color)

	# Back arm (behind the body).
	_draw_arm(_shoulder(false), _back_arm_angle(), body_color.darkened(0.2), skin)

	# Body.
	var body := PackedVector2Array([
		Vector2(-r * 0.55, -r * 0.22), Vector2(-r * 0.48, -r * 0.9), Vector2(-r * 0.3, -r * 1.07),
		Vector2(r * 0.3, -r * 1.07), Vector2(r * 0.48, -r * 0.9), Vector2(r * 0.55, -r * 0.22),
	])
	draw_colored_polygon(body, body_color)
	var body_outline := body.duplicate()
	body_outline.append(body[0])
	draw_polyline(body_outline, outline, line_width, true)
	draw_line(Vector2(-r * 0.22, -r * 0.75), Vector2(-r * 0.3, -r * 0.35), body_color.lightened(0.35), line_width * 1.2, true)

	# Head, hair and eyes (pupils look the way the pawn faces).
	var head := Vector2(0, -r * 1.45)
	var head_r := r * 0.42
	draw_circle(head, head_r, skin)
	draw_arc(head, head_r * 0.92, PI * 1.05, PI * 1.95, 16, outline, head_r * 0.35, true)
	draw_arc(head, head_r, 0.0, TAU, 32, outline, line_width, true)
	if dizzy:
		for side in [-1.0, 1.0]:
			var e := head + Vector2(side * head_r * 0.35, head_r * 0.1)
			draw_line(e + Vector2(-1, -1) * head_r * 0.12, e + Vector2(1, 1) * head_r * 0.12, Palette.TEXT_DARK, line_width, true)
			draw_line(e + Vector2(-1, 1) * head_r * 0.12, e + Vector2(1, -1) * head_r * 0.12, Palette.TEXT_DARK, line_width, true)
	else:
		for side in [-1.0, 1.0]:
			draw_circle(head + Vector2(side * head_r * 0.35 + head_r * 0.08, head_r * 0.1), head_r * 0.12, Palette.TEXT_DARK)
	if arm_raise > 0.5 and not dizzy:
		# Determined little grin while attacking.
		draw_arc(head + Vector2(head_r * 0.1, head_r * 0.35), head_r * 0.25, 0.2, PI - 0.2, 8, Palette.TEXT_DARK, line_width * 0.8, true)

	# Front arm, with the prop in its hand during a capture.
	_draw_arm(_shoulder(true), _front_arm_angle(), body_color.darkened(0.1), skin)
	if prop != Prop.NONE and prop_scale > 0.01:
		var hand := _hand_local()
		var prop_xf := body_xf * Transform2D(_front_arm_angle() + prop_angle, Vector2(prop_scale, prop_scale), 0.0, hand)
		draw_set_transform_matrix(prop_xf)
		_draw_prop(r)
		draw_set_transform_matrix(body_xf)

	if dizzy:
		for i in 3:
			var a := _time * 5.0 + i * TAU / 3.0
			var p := head + Vector2(cos(a) * head_r * 1.2, -head_r * 1.1 + sin(a) * head_r * 0.35)
			_draw_star(p, r * 0.16, Palette.ACCENT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_arm(shoulder: Vector2, angle: float, sleeve: Color, skin: Color) -> void:
	var r := radius
	var hand := shoulder + Vector2.from_angle(angle) * r * 0.48
	draw_line(shoulder, hand, sleeve, r * 0.17, true)
	draw_circle(hand, r * 0.1, skin)


## Props point along +x from the hand. Bright toy colours: cartoon, not realistic.
func _draw_prop(r: float) -> void:
	match prop:
		Prop.BLASTER:
			draw_rect(Rect2(Vector2(-r * 0.05, -r * 0.16), Vector2(r * 0.55, r * 0.3)), Color("8e5bd6"))
			draw_rect(Rect2(Vector2(r * 0.45, -r * 0.08), Vector2(r * 0.3, r * 0.14)), Color("3dd6c4"))
			draw_circle(Vector2(r * 0.78, -r * 0.01), r * 0.09, Color("f6c026"))
			draw_rect(Rect2(Vector2(-r * 0.02, r * 0.1), Vector2(r * 0.14, r * 0.25)), Color("5a3a9a"))
			draw_circle(Vector2(r * 0.2, -r * 0.2), r * 0.07, Color("e8413c"))
		Prop.SWORD:
			var blade := PackedVector2Array([Vector2(r * 0.15, -r * 0.07), Vector2(r * 1.05, -r * 0.05), Vector2(r * 1.2, 0), Vector2(r * 1.05, r * 0.05), Vector2(r * 0.15, r * 0.07)])
			draw_colored_polygon(blade, Color("dfe8f2"))
			draw_polyline(blade, Color("7a8aa0"), maxf(1.0, r * 0.04), true)
			draw_line(Vector2(r * 0.12, -r * 0.22), Vector2(r * 0.12, r * 0.22), Color("f6c026"), r * 0.1, true)
			draw_line(Vector2(-r * 0.12, 0), Vector2(r * 0.1, 0), Color("8a4b1f"), r * 0.13, true)
		Prop.HAMMER:
			draw_line(Vector2(-r * 0.1, 0), Vector2(r * 0.75, 0), Color("c98a45"), r * 0.12, true)
			draw_rect(Rect2(Vector2(r * 0.7, -r * 0.32), Vector2(r * 0.4, r * 0.64)), Color("e8413c"))
			draw_rect(Rect2(Vector2(r * 0.7, -r * 0.32), Vector2(r * 0.4, r * 0.12)), Color("f6c026"))
			draw_rect(Rect2(Vector2(r * 0.7, r * 0.2), Vector2(r * 0.4, r * 0.12)), Color("f6c026"))
		Prop.WAND:
			draw_line(Vector2(-r * 0.05, 0), Vector2(r * 0.7, 0), Palette.TEXT_DARK, r * 0.09, true)
			draw_line(Vector2(r * 0.55, 0), Vector2(r * 0.7, 0), Color.WHITE, r * 0.09, true)
			_draw_star(Vector2(r * 0.8, 0), r * 0.25, Palette.ACCENT)


func _draw_star(centre: Vector2, outer: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var rr := outer if i % 2 == 0 else outer * 0.45
		var a := -PI / 2.0 + i * PI / 5.0
		points.append(centre + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(points, color)
