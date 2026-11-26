class_name SnakeArt
extends RefCounted
## Draws a friendly cartoon snake along a list of points (tail first, head last).
## Placeholder art drawn in code; it can be replaced by sprites later.


static func draw_snake(canvas: CanvasItem, anchors: Array[Vector2], cell: float, color: Color) -> void:
	if anchors.size() < 2:
		return
	var path := _wiggle(_smooth(anchors), cell)
	var count := path.size()
	var outline := color.darkened(0.45)
	var belly := color.lightened(0.45)

	# Body: overlapping circles that grow from the tail to the neck.
	for pass_index in 2:
		for k in count:
			var r := _radius(k, count, cell)
			if pass_index == 0:
				canvas.draw_circle(path[k], r + cell * 0.04, outline)
			else:
				canvas.draw_circle(path[k], r, color)
	# Scales and a lighter belly stripe.
	for k in range(2, count - 3, 2):
		var r := _radius(k, count, cell)
		canvas.draw_circle(path[k], r * 0.32, belly)
		if k % 4 == 0:
			canvas.draw_circle(path[k] + _normal(path, k) * r * 0.55, r * 0.22, outline.lerp(color, 0.4))

	# Head, turned the way the body was going.
	var direction := (path[count - 1] - path[maxi(count - 4, 0)]).normalized()
	var head := path[count - 1] + direction * cell * 0.08
	canvas.draw_set_transform(head, direction.angle(), Vector2(1.25, 1.0))
	var head_r := cell * 0.27
	canvas.draw_circle(Vector2.ZERO, head_r + cell * 0.04, outline)
	canvas.draw_circle(Vector2.ZERO, head_r, color)
	for side in [-1.0, 1.0]:
		var eye := Vector2(head_r * 0.2, head_r * 0.5 * side)
		canvas.draw_circle(eye, head_r * 0.32, Color.WHITE)
		canvas.draw_circle(eye + Vector2(head_r * 0.08, 0), head_r * 0.16, Palette.TEXT_DARK)
	canvas.draw_circle(Vector2(head_r * 0.75, -head_r * 0.2), head_r * 0.07, outline)
	canvas.draw_circle(Vector2(head_r * 0.75, head_r * 0.2), head_r * 0.07, outline)
	var tongue_color := Color("e8413c")
	var tip := Vector2(head_r * 1.55, 0)
	var width := maxf(1.5, cell * 0.045)
	canvas.draw_line(Vector2(head_r * 0.95, 0), tip, tongue_color, width, true)
	canvas.draw_line(tip, tip + Vector2(head_r * 0.25, -head_r * 0.2), tongue_color, width, true)
	canvas.draw_line(tip, tip + Vector2(head_r * 0.25, head_r * 0.2), tongue_color, width, true)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The snake's body line (tail to head), used to slide pawns down a snake.
static func body_path(anchors: Array[Vector2], cell: float) -> PackedVector2Array:
	return _wiggle(_smooth(anchors), cell)


static func _radius(k: int, count: int, cell: float) -> float:
	var f := float(k) / maxf(1.0, count - 1)
	return cell * lerpf(0.06, 0.2, f)


static func _smooth(anchors: Array[Vector2]) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n := anchors.size()
	var samples := 10
	for i in n - 1:
		var p0: Vector2 = anchors[maxi(i - 1, 0)]
		var p1: Vector2 = anchors[i]
		var p2: Vector2 = anchors[i + 1]
		var p3: Vector2 = anchors[mini(i + 2, n - 1)]
		for s in samples:
			points.append(p1.cubic_interpolate(p2, p0, p3, float(s) / samples))
	points.append(anchors[n - 1])
	return points


static func _wiggle(points: PackedVector2Array, cell: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var count := points.size()
	for k in count:
		var fade := float(k) / maxf(1.0, count - 1)
		var amplitude := cell * 0.16 * sin(fade * PI)
		result.append(points[k] + _normal(points, k) * sin(k * 0.55) * amplitude)
	return result


static func _normal(points: PackedVector2Array, k: int) -> Vector2:
	var a := points[maxi(k - 1, 0)]
	var b := points[mini(k + 1, points.size() - 1)]
	var d := (b - a).normalized()
	return Vector2(-d.y, d.x)
