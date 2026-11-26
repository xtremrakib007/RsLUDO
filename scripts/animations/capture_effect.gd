class_name CaptureEffect
extends Node2D
## One short visual effect drawn in code. `progress` runs 0 -> 1 (tweened by
## CaptureAnimator) and the animator frees it afterwards. Cartoon style, no gore.

enum Kind { BEAM, SLASH, SPARKLES, BURST, CONFETTI, POOF, CHARGE, FLASH, SHOCKWAVE, DEBRIS, SPEEDLINES, DUST }

var kind: int = Kind.BURST
var from_point: Vector2 = Vector2.ZERO
var to_point: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE
var size_px: float = 40.0
var text: String = ""
## Extra angle for slashes (radians).
var angle: float = 0.0
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
	effect.z_index = 20
	return effect


## Repeatable pseudo-random number in 0..1 for particle i.
static func _rand(i: int, salt: int) -> float:
	return fposmod(sin(float(i * 12.9898 + salt * 78.233)) * 43758.5453, 1.0)


func _fade(from_t: float) -> float:
	return 1.0 - clampf((progress - from_t) / (1.0 - from_t), 0.0, 1.0)


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
		Kind.CHARGE:
			_draw_charge()
		Kind.FLASH:
			_draw_flash()
		Kind.SHOCKWAVE:
			_draw_shockwave()
		Kind.DEBRIS:
			_draw_debris()
		Kind.SPEEDLINES:
			_draw_speedlines()
		Kind.DUST:
			_draw_dust()


func _draw_beam() -> void:
	var reach := clampf(progress * 3.0, 0.0, 1.0)
	var fade := _fade(0.6)
	var tip := from_point.lerp(to_point, reach)
	var width := size_px * 0.4 * (1.0 + 0.15 * sin(progress * 60.0))
	draw_line(from_point, tip, Color(color, 0.3 * fade), width * 2.6, true)
	draw_line(from_point, tip, Color(color, 0.95 * fade), width, true)
	draw_line(from_point, tip, Color(1, 1, 1, fade), width * 0.4, true)
	for i in 4:
		var t := fposmod(progress * 3.0 + i / 4.0, 1.0) * reach
		var p := from_point.lerp(to_point, t)
		draw_arc(p, width * 1.0, 0.0, TAU, 20, Color.from_hsv(fposmod(t + i * 0.25, 1.0), 0.7, 1.0, fade), width * 0.25, true)
	draw_circle(from_point, width * (1.2 - progress * 0.6) * fade, Color(1, 1, 1, fade))


func _draw_slash() -> void:
	var sweep := clampf(progress * 2.0, 0.0, 1.0)
	var fade := _fade(0.45)
	var start := -2.4 + angle
	var end := start + 2.8 * sweep
	var r := size_px
	for i in 4:
		var w := r * (0.24 - i * 0.05)
		draw_arc(to_point, r * (1.0 - i * 0.07), start, end, 28, Color(color.lerp(Color.WHITE, i * 0.3), fade * (1.0 - i * 0.15)), w, true)
	# Sparks flying off the end of the slash.
	for i in 6:
		var a := end + (_rand(i, 3) - 0.5) * 1.2
		var d := r * (1.0 + progress * 1.2 * (0.5 + _rand(i, 4)))
		draw_circle(to_point + Vector2.from_angle(a) * d, r * 0.06 * fade, Color(1, 0.95, 0.6, fade))


func _draw_sparkles() -> void:
	var fade := _fade(0.8)
	for i in 9:
		var t := clampf(progress * 1.3 - i * 0.04, 0.0, 1.0)
		var p := from_point.lerp(to_point, t) + Vector2(sin(t * 9.0 + i), cos(t * 7.0 + i * 2.0)) * size_px * 0.4
		_star(p, size_px * (0.18 + 0.06 * (i % 3)), Color.from_hsv(fposmod(i * 0.13, 1.0), 0.6, 1.0, fade))


func _draw_burst() -> void:
	var pop := clampf(progress * 5.0, 0.0, 1.0)
	var fade := _fade(0.75)
	var r := size_px * (0.5 + 0.6 * pop)
	var points := PackedVector2Array()
	for i in 16:
		var rr := r if i % 2 == 0 else r * 0.6
		var a := i * TAU / 16.0 + 0.2
		points.append(to_point + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(points, Color(color, fade))
	points.append(points[0])
	draw_polyline(points, Color(Palette.TEXT_DARK, fade), maxf(2.0, size_px * 0.06), true)
	if not text.is_empty():
		var font := UIKit.title_font()
		var font_size := maxi(8, int(size_px * 0.5 * (0.6 + 0.4 * pop)))
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var pos := to_point + Vector2(-width * 0.5, font_size * 0.35)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(2, font_size / 5), Color(Color.WHITE, fade))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(Palette.TEXT_DARK, fade))


func _draw_confetti() -> void:
	var fade := _fade(0.7)
	for i in 24:
		var a := i * TAU / 24.0 + i * 0.37
		var speed := 0.6 + _rand(i, 1) * 0.8
		var p := to_point + Vector2(cos(a), sin(a) - 0.5) * size_px * 1.8 * progress * speed + Vector2(0, size_px * 1.4 * progress * progress)
		var c := Color(Palette.seat_color(i % 4), fade) if i % 3 != 0 else Color(Palette.ACCENT, fade)
		draw_set_transform(p, progress * 10.0 + i, Vector2.ONE)
		draw_rect(Rect2(Vector2(-size_px * 0.07, -size_px * 0.04), Vector2(size_px * 0.14, size_px * 0.08)), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_poof() -> void:
	var fade := 1.0 - clampf(progress, 0.0, 1.0)
	for i in 8:
		var a := i * TAU / 8.0
		var p := to_point + Vector2(cos(a), sin(a)) * size_px * 0.6 * progress
		draw_circle(p, size_px * (0.28 + 0.25 * progress), Color(0.95, 0.95, 1.0, 0.85 * fade))


func _draw_charge() -> void:
	# Energy gathering at a point: particles spiral in, a glow grows.
	var glow := size_px * 0.45 * progress
	draw_circle(to_point, glow * 1.8, Color(color, 0.25 * progress))
	draw_circle(to_point, glow, Color(color, 0.6 * progress))
	draw_circle(to_point, glow * 0.45, Color(1, 1, 1, progress))
	for i in 10:
		var a := i * TAU / 10.0 + progress * 6.0
		var d := size_px * 1.6 * (1.0 - fposmod(progress * 1.5 + _rand(i, 2), 1.0))
		draw_circle(to_point + Vector2.from_angle(a) * d, size_px * 0.06, Color(color.lightened(0.4), 0.9))


func _draw_flash() -> void:
	var fade := 1.0 - progress
	draw_circle(to_point, size_px * (0.4 + 1.6 * progress), Color(1, 1, 1, 0.85 * fade))


func _draw_shockwave() -> void:
	var fade := 1.0 - progress
	var r := size_px * (0.2 + 2.2 * progress)
	draw_arc(to_point, r, 0.0, TAU, 48, Color(color, fade), size_px * 0.18 * fade + 1.0, true)
	draw_arc(to_point, r * 0.75, 0.0, TAU, 40, Color(1, 1, 1, 0.6 * fade), size_px * 0.08 * fade + 1.0, true)


func _draw_debris() -> void:
	# Chunks and stars thrown out with gravity.
	var fade := _fade(0.65)
	for i in 14:
		var a := -PI + _rand(i, 5) * PI
		var speed := size_px * (1.2 + _rand(i, 6) * 1.8)
		var p := to_point + Vector2.from_angle(a) * speed * progress + Vector2(0, size_px * 2.5 * progress * progress)
		if i % 3 == 0:
			_star(p, size_px * 0.14, Color(Palette.ACCENT, fade))
		else:
			draw_set_transform(p, progress * 12.0 + i, Vector2.ONE)
			draw_rect(Rect2(Vector2(-size_px * 0.06, -size_px * 0.06), Vector2(size_px * 0.12, size_px * 0.12)), Color(color.darkened(_rand(i, 7) * 0.4), fade))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_speedlines() -> void:
	var fade := 1.0 - progress
	for i in 12:
		var a := i * TAU / 12.0 + _rand(i, 8) * 0.3
		var inner := size_px * (1.2 + _rand(i, 9) * 0.6)
		var outer := inner + size_px * (1.0 + _rand(i, 10))
		draw_line(to_point + Vector2.from_angle(a) * inner, to_point + Vector2.from_angle(a) * outer, Color(1, 1, 1, 0.7 * fade), size_px * 0.05, true)


func _draw_dust() -> void:
	var fade := 1.0 - progress
	for i in 6:
		var side := -1.0 if i % 2 == 0 else 1.0
		var p := to_point + Vector2(side * size_px * (0.3 + progress * (0.6 + _rand(i, 11))), -size_px * 0.2 * progress * _rand(i, 12))
		draw_circle(p, size_px * (0.12 + 0.18 * progress), Color(0.9, 0.85, 0.75, 0.7 * fade))


func _star(centre: Vector2, outer: float, c: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var rr := outer if i % 2 == 0 else outer * 0.45
		var a := -PI / 2.0 + i * PI / 5.0
		points.append(centre + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(points, c)
