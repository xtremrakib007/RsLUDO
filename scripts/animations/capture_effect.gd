class_name CaptureEffect
extends Node2D
## One short visual effect drawn in code. `progress` runs 0 -> 1 (tweened by
## CaptureAnimator); the effect frees itself when told. Cartoon style only.

enum Kind { BEAM, SLASH, SPARKLES, BURST, CONFETTI, POOF }

var kind: int = Kind.BURST
var from_point: Vector2 = Vector2.ZERO
var to_point: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE
var size_px: float = 40.0
var text: String = ""
var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()


static func create(p_kind: int, p_from: Vector2, p_to: Vector2, p_color: Color, p_size: float, p_text: String = "") -> CaptureEffect:
	var effect := CaptureEffect.new()
	effect.kind = p_kind
	effect.from_point = p_from
	effect.to_point = p_to
	effect.color = p_color
	effect.size_px = p_size
	effect.text = p_text
	effect.z_index = 10
	return effect


func _draw() -> void:
	match kind:
		Kind.BEAM:
			_draw_beam()
		Kind.SLASH:
			_draw_slash()
		Kind.SPARKLES:
			_draw_sparkles()
		Kind.BURST:
			_draw_burst()
		Kind.CONFETTI:
			_draw_confetti()
		Kind.POOF:
			_draw_poof()


func _draw_beam() -> void:
	# The beam shoots out, then fades; rainbow rings travel along it.
	var reach := clampf(progress * 2.0, 0.0, 1.0)
	var fade := 1.0 - clampf((progress - 0.6) / 0.4, 0.0, 1.0)
	var tip := from_point.lerp(to_point, reach)
	var width := size_px * 0.35
	draw_line(from_point, tip, Color(color, 0.35 * fade), width * 2.2, true)
	draw_line(from_point, tip, Color(color, 0.9 * fade), width, true)
	draw_line(from_point, tip, Color(1, 1, 1, fade), width * 0.35, true)
	for i in 3:
		var t := fposmod(progress * 2.5 + i / 3.0, 1.0) * reach
		var p := from_point.lerp(to_point, t)
		draw_arc(p, width * 0.9, 0.0, TAU, 20, Color.from_hsv(fposmod(t + i * 0.3, 1.0), 0.7, 1.0, fade), width * 0.25, true)
	draw_circle(from_point, width * 0.8 * fade, Color(1, 1, 1, fade))


func _draw_slash() -> void:
	# A white crescent swoosh sweeping across the target.
	var sweep := clampf(progress * 1.6, 0.0, 1.0)
	var fade := 1.0 - clampf((progress - 0.55) / 0.45, 0.0, 1.0)
	var start := -2.4
	var end := start + 2.6 * sweep
	var r := size_px
	for i in 4:
		var w := r * (0.22 - i * 0.045)
		draw_arc(to_point, r * (1.0 - i * 0.07), start, end, 24, Color(color.lerp(Color.WHITE, i * 0.3), fade * (1.0 - i * 0.15)), w, true)


func _draw_sparkles() -> void:
	# Little stars flying from the wand to the target.
	var fade := 1.0 - clampf((progress - 0.8) / 0.2, 0.0, 1.0)
	for i in 7:
		var t := clampf(progress * 1.3 - i * 0.05, 0.0, 1.0)
		var p := from_point.lerp(to_point, t) + Vector2(sin(t * 9.0 + i), cos(t * 7.0 + i * 2.0)) * size_px * 0.35
		_star(p, size_px * (0.18 + 0.06 * (i % 3)), Color.from_hsv(fposmod(i * 0.13, 1.0), 0.6, 1.0, fade))


func _draw_burst() -> void:
	# Comic-book impact star with a word: ZAP! SWISH! BONK! POOF!
	var pop := clampf(progress * 4.0, 0.0, 1.0)
	var fade := 1.0 - clampf((progress - 0.7) / 0.3, 0.0, 1.0)
	var r := size_px * (0.6 + 0.5 * pop)
	var points := PackedVector2Array()
	for i in 16:
		var rr := r if i % 2 == 0 else r * 0.62
		var a := i * TAU / 16.0 + 0.2
		points.append(to_point + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(points, Color(color, fade))
	points.append(points[0])
	draw_polyline(points, Color(Palette.TEXT_DARK, fade), maxf(2.0, size_px * 0.06), true)
	if not text.is_empty():
		var font := UIKit.title_font()
		var font_size := int(size_px * 0.5 * (0.7 + 0.3 * pop))
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var pos := to_point + Vector2(-width * 0.5, font_size * 0.35)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(2, font_size / 6), Color(Color.WHITE, fade))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(Palette.TEXT_DARK, fade))


func _draw_confetti() -> void:
	var fade := 1.0 - clampf((progress - 0.7) / 0.3, 0.0, 1.0)
	for i in 18:
		var a := i * TAU / 18.0 + i * 0.37
		var speed := 0.6 + float(i % 4) * 0.2
		var p := to_point + Vector2(cos(a), sin(a) - 0.4) * size_px * 1.6 * progress * speed + Vector2(0, size_px * 1.2 * progress * progress)
		var c := Color(Palette.seat_color(i % 4), fade) if i % 3 != 0 else Color(Palette.ACCENT, fade)
		draw_rect(Rect2(p, Vector2(size_px * 0.14, size_px * 0.08)), c)


func _draw_poof() -> void:
	var fade := 1.0 - clampf(progress, 0.0, 1.0)
	for i in 6:
		var a := i * TAU / 6.0
		var p := to_point + Vector2(cos(a), sin(a)) * size_px * 0.5 * progress
		draw_circle(p, size_px * (0.25 + 0.2 * progress), Color(1, 1, 1, 0.8 * fade))


func _star(centre: Vector2, outer: float, c: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var rr := outer if i % 2 == 0 else outer * 0.45
		var a := -PI / 2.0 + i * PI / 5.0
		points.append(centre + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(points, c)
