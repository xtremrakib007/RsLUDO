class_name SnakeArt
extends RefCounted
## Draws a friendly cartoon snake along a list of points (tail first, head last).
## Placeholder art drawn in code; it can be replaced by sprites later.


## mouth_open: 0 closed .. 1 wide open. bulge: -1 none, else 0 (at the head) .. 1 (at the tail),
## a swallowed character travelling down the body, drawn in bulge_color.
static func draw_snake(canvas: CanvasItem, anchors: Array[Vector2], cell: float, color: Color, mouth_open: float = 0.0, bulge: float = -1.0, bulge_color: Color = Color.WHITE) -> void:
	if anchors.size() < 2:
		return
	var path := _wiggle(_smooth(anchors), cell)
	var count := path.size()
	var outline := color.darkened(0.45)
	var belly := color.lightened(0.45)
	var bulge_index := (1.0 - bulge) * (count - 1) if bulge >= 0.0 else -100.0

	# Body: overlapping circles that grow from the tail to the neck, swelling where the bulge is.
	for pass_index in 2:
		for k in count:
			var r := _radius(k, count, cell) * _swell(k, bulge_index)
			if pass_index == 0:
				canvas.draw_circle(path[k], r + cell * 0.04, outline)
			else:
				canvas.draw_circle(path[k], r, color)
	if bulge >= 0.0:
		# A hint of the swallowed character's colour inside the bulge.
		var i := clampi(roundi(bulge_index), 0, count - 1)
		var swollen := _radius(i, count, cell) * _swell(i, bulge_index)
		canvas.draw_circle(path[i], swollen * 0.75, Color(bulge_color, 0.8))
		canvas.draw_circle(path[i] + Vector2(-swollen * 0.2, -swollen * 0.25), swollen * 0.2, Color(1, 1, 1, 0.5))
	# Scales and a lighter belly stripe.
	for k in range(2, count - 3, 2):
		var r := _radius(k, count, cell) * _swell(k, bulge_index)
		canvas.draw_circle(path[k], r * 0.32, belly)
		if k % 4 == 0:
			canvas.draw_circle(path[k] + _normal(path, k) * r * 0.55, r * 0.22, outline.lerp(color, 0.4))

	# Head, turned the way the body was going; it grows a little as the mouth opens.
	var direction := head_direction(path)
	var head := path[count - 1] + direction * cell * 0.08
	var open := clampf(mouth_open, 0.0, 1.0)
	canvas.draw_set_transform(head, direction.angle(), Vector2(1.25, 1.0) * (1.0 + 0.6 * open))
	var head_r := cell * 0.27
	canvas.draw_circle(Vector2.ZERO, head_r + cell * 0.04, outline)
	canvas.draw_circle(Vector2.ZERO, head_r, color)
	if open > 0.02:
		# Cartoon open mouth: pink inside, tongue, two little white fangs.
		var jaw := head_r * 1.05 * open
		var mouth := PackedVector2Array([Vector2(-head_r * 0.15, 0), Vector2(head_r * 1.25, -jaw), Vector2(head_r * 1.35, 0), Vector2(head_r * 1.25, jaw)])
		canvas.draw_colored_polygon(mouth, Color("b8325a"))
		canvas.draw_polyline(PackedVector2Array([mouth[1], mouth[0], mouth[3]]), outline, maxf(1.5, cell * 0.04), true)
		canvas.draw_circle(Vector2(head_r * 0.55, 0), head_r * 0.3 * open, Color("f06d8f"))
		for side in [-1.0, 1.0]:
			var base := Vector2(head_r * 0.95, jaw * 0.8 * side)
			var fang := PackedVector2Array([base + Vector2(-head_r * 0.1, 0), base + Vector2(head_r * 0.1, 0), base + Vector2(0, -head_r * 0.3 * side * open)])
			canvas.draw_colored_polygon(fang, Color.WHITE)
	for side in [-1.0, 1.0]:
		var eye := Vector2(head_r * 0.1, head_r * (0.5 + 0.15 * open) * side)
		canvas.draw_circle(eye, head_r * (0.32 + 0.08 * open), Color.WHITE)
		canvas.draw_circle(eye + Vector2(head_r * 0.08, 0), head_r * 0.16, Palette.TEXT_DARK)
	if open <= 0.02:
		canvas.draw_circle(Vector2(head_r * 0.75, -head_r * 0.2), head_r * 0.07, outline)
		canvas.draw_circle(Vector2(head_r * 0.75, head_r * 0.2), head_r * 0.07, outline)
		var tongue_color := Color("e8413c")
		var tip := Vector2(head_r * 1.55, 0)
		var width := maxf(1.5, cell * 0.045)
		canvas.draw_line(Vector2(head_r * 0.95, 0), tip, tongue_color, width, true)
		canvas.draw_line(tip, tip + Vector2(head_r * 0.25, -head_r * 0.2), tongue_color, width, true)
		canvas.draw_line(tip, tip + Vector2(head_r * 0.25, head_r * 0.2), tongue_color, width, true)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Which way the head points (along the end of the body path).
static func head_direction(path: PackedVector2Array) -> Vector2:
	var count := path.size()
	return (path[count - 1] - path[maxi(count - 4, 0)]).normalized()


## Where a swallowed character disappears: just inside the open mouth.
static func mouth_point(anchors: Array[Vector2], cell: float) -> Vector2:
	var path := body_path(anchors, cell)
	return path[path.size() - 1] + head_direction(path) * cell * 0.45


static func _swell(k: int, bulge_index: float) -> float:
	var d := (k - bulge_index) / 3.0
	return 1.0 + 1.8 * exp(-d * d)


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
