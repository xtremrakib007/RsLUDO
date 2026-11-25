class_name PawnToken
extends Node2D
## Placeholder pawn: a small cartoon person drawn in code.
## Phase 3 replaces the drawing with an animated character scene; the board
## only uses `seat`, `radius`, `position`, `highlighted` and `set_hop()`.

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
		set_process(value)
		queue_redraw()
## Height above the ground while hopping, in pixels.
var lift: float = 0.0


func _ready() -> void:
	set_process(highlighted)


func _process(_delta: float) -> void:
	queue_redraw()


## Hop curve for one step: t goes 0 -> 1 over the step.
func set_hop(t: float) -> void:
	lift = sin(clampf(t, 0.0, 1.0) * PI) * radius * 0.7
	queue_redraw()


func _draw() -> void:
	var r := radius
	var body_color := Palette.seat_color(seat)
	var outline := body_color.darkened(0.45)
	var line_width := maxf(1.5, r * 0.09)

	if highlighted:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
		draw_circle(Vector2(0, r * 0.2), r * (1.0 + 0.12 * pulse), Color(1, 1, 0.75, 0.35))
		draw_arc(Vector2(0, r * 0.2), r * (1.0 + 0.12 * pulse), 0.0, TAU, 40, Color(1, 1, 1, 0.95), maxf(2.0, r * 0.12), true)

	# Ground shadow (squashed circle), smaller while in the air.
	var shadow_scale := 1.0 - clampf(lift / (r * 1.4), 0.0, 0.5)
	draw_set_transform(Vector2(0, r * 0.9), 0.0, Vector2(shadow_scale, 0.32 * shadow_scale))
	draw_circle(Vector2.ZERO, r * 0.75, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2.ONE)

	# Body.
	var body := PackedVector2Array([
		Vector2(-r * 0.62, r * 0.9), Vector2(-r * 0.5, r * 0.05), Vector2(-r * 0.3, -r * 0.12),
		Vector2(r * 0.3, -r * 0.12), Vector2(r * 0.5, r * 0.05), Vector2(r * 0.62, r * 0.9),
	])
	draw_colored_polygon(body, body_color)
	var body_outline := body.duplicate()
	body_outline.append(body[0])
	draw_polyline(body_outline, outline, line_width, true)
	draw_line(Vector2(-r * 0.22, r * 0.2), Vector2(-r * 0.3, r * 0.7), body_color.lightened(0.35), line_width * 1.2, true)

	# Head, hair and eyes.
	var head := Vector2(0, -r * 0.5)
	var head_r := r * 0.42
	draw_circle(head, head_r, Palette.skin_tone(seat))
	draw_arc(head, head_r * 0.92, PI * 1.05, PI * 1.95, 16, outline, head_r * 0.35, true)
	draw_arc(head, head_r, 0.0, TAU, 32, outline, line_width, true)
	draw_circle(head + Vector2(-head_r * 0.35, head_r * 0.1), head_r * 0.12, Palette.TEXT_DARK)
	draw_circle(head + Vector2(head_r * 0.35, head_r * 0.1), head_r * 0.12, Palette.TEXT_DARK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
