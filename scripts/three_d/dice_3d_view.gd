class_name Dice3DView
extends SubViewportContainer
## A premium 3D dice in its own little 3D scene: a glossy rounded cube in the
## player's colour with inset white pips, lit by key, fill and rim lights.
## While waiting it floats and turns gently over a soft coloured glow. A roll
## winds up, tosses the dice spinning into the air, lands with a squash and a
## ripple, bounces once, and settles with a wobble showing the value on top.
## The view is larger than its button so the dice has room to jump.

signal impact(strength: float)

## Euler rotation that brings each face to the top. Opposite faces add up to 7.
const FACE_ROTATIONS := {
	1: Vector3(0, 0, 0),
	6: Vector3(PI, 0, 0),
	2: Vector3(0, 0, PI / 2.0),
	5: Vector3(0, 0, -PI / 2.0),
	3: Vector3(-PI / 2.0, 0, 0),
	4: Vector3(PI / 2.0, 0, 0),
}
## Face value -> [normal, u axis, v axis] in the cube's own space.
const FACES := {
	1: [Vector3.UP, Vector3.RIGHT, Vector3.BACK],
	6: [Vector3.DOWN, Vector3.RIGHT, Vector3.BACK],
	2: [Vector3.RIGHT, Vector3.UP, Vector3.BACK],
	5: [Vector3.LEFT, Vector3.UP, Vector3.BACK],
	3: [Vector3.BACK, Vector3.RIGHT, Vector3.UP],
	4: [Vector3.FORWARD, Vector3.RIGHT, Vector3.UP],
}
## Pip positions on a face, from -1 to 1.
const PIPS := {
	1: [Vector2(0, 0)],
	2: [Vector2(-1, -1), Vector2(1, 1)],
	3: [Vector2(-1, -1), Vector2(0, 0), Vector2(1, 1)],
	4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
	5: [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)],
	6: [Vector2(-1, -1), Vector2(-1, 0), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 0), Vector2(1, 1)],
}
const TOSS_HEIGHT := 1.35

var value: int = 6:
	set(v):
		value = clampi(v, 1, 6)
		if _cube != null:
			_cube.basis = Basis.from_euler(FACE_ROTATIONS[value])
## The cube's colour (the current player's colour).
var body_color: Color = Color("f2f0e8"):
	set(c):
		body_color = c
		_apply_colors()
var pip_color: Color = Color.WHITE:
	set(c):
		pip_color = c
		_apply_colors()

var _viewport: SubViewport
var _holder: Node3D
var _cube: Node3D
var _shadow: MeshInstance3D
var _glow: MeshInstance3D
var _ripple: MeshInstance3D
var _pip_material: StandardMaterial3D
var _socket_material: StandardMaterial3D
var _body_material: StandardMaterial3D
var _glow_material: StandardMaterial3D
var _ripple_material: StandardMaterial3D
var _final_rotation: Quaternion
var _spin_axis: Vector3 = Vector3.UP
var _spins: float = 3.0
var _waiting := false
var _rolling := false
var _time := 0.0
var _wobble_axis := Vector3.RIGHT


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_scene()


func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	value = value


func _process(delta: float) -> void:
	_time += delta
	if _rolling:
		_update_shadow()
		return
	# Waiting for a tap: float, turn a little, and pulse the glow.
	var w := 1.0 if _waiting else 0.0
	_holder.position.y = lerpf(_holder.position.y, w * (0.12 + sin(_time * 3.0) * 0.08), minf(1.0, delta * 8.0))
	_holder.rotation.y = lerpf(_holder.rotation.y, w * sin(_time * 1.6) * 0.35, minf(1.0, delta * 6.0))
	_glow_material.albedo_color.a = lerpf(_glow_material.albedo_color.a, w * (0.35 + 0.2 * sin(_time * 4.0)), minf(1.0, delta * 8.0))
	_update_shadow()


## Shows that the dice is waiting to be tapped (float + glow).
func set_waiting(on: bool) -> void:
	_waiting = on


## Winds up, tosses, lands, bounces and settles with `result` on top.
func roll_to(result: int) -> void:
	_rolling = true
	_waiting = false
	_glow_material.albedo_color.a = 0.0
	_holder.rotation = Vector3.ZERO
	value = clampi(result, 1, 6)
	_final_rotation = Basis.from_euler(FACE_ROTATIONS[value]).get_rotation_quaternion()
	_spin_axis = Vector3(randf_range(-1.0, 1.0), randf_range(0.4, 1.0), randf_range(-1.0, 1.0)).normalized()
	_spins = randf_range(2.2, 3.0)
	_roll_step(0.0)

	# Wind-up squash.
	var t := create_tween()
	t.tween_property(_holder, "scale", Vector3(1.15, 0.8, 1.15), 0.07).set_trans(Tween.TRANS_QUAD)
	t.tween_property(_holder, "scale", Vector3(0.9, 1.12, 0.9), 0.06)
	await t.finished

	# Toss and spin; the spin finishes during the bounce.
	var spin := create_tween()
	spin.tween_method(_roll_step, 0.0, 1.0, 0.78).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t = create_tween()
	t.tween_property(_holder, "position:y", TOSS_HEIGHT, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_holder, "scale", Vector3.ONE, 0.12)
	t.tween_property(_holder, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished

	# First impact: squash, ripple, then one smaller bounce.
	impact.emit(1.0)
	_play_ripple(1.0)
	t = create_tween()
	t.tween_property(_holder, "scale", Vector3(1.18, 0.78, 1.18), 0.05)
	t.tween_property(_holder, "scale", Vector3.ONE, 0.08)
	t.tween_property(_holder, "position:y", 0.32, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_holder, "position:y", 0.0, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	impact.emit(0.4)
	_play_ripple(0.5)
	# The spin may already be over; only wait if it is still turning.
	if spin.is_running():
		await spin.finished

	# Settle with a small springy wobble.
	_cube.basis = Basis(_final_rotation)
	_wobble_axis = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	t = create_tween()
	t.tween_method(_wobble, 0.18, 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await t.finished
	_holder.basis = Basis()
	_rolling = false


## The value on the face currently pointing up.
func top_face() -> int:
	var best := 1
	var best_up := -2.0
	for face_value in FACES:
		var normal: Vector3 = FACES[face_value][0]
		var up := (_cube.basis * normal).y
		if up > best_up:
			best_up = up
			best = face_value
	return best


func _wobble(angle: float) -> void:
	_holder.basis = Basis(_wobble_axis, angle)


func _roll_step(t: float) -> void:
	var remaining := pow(1.0 - clampf(t, 0.0, 1.0), 2.0)
	_cube.basis = Basis(_final_rotation * Quaternion(_spin_axis, _spins * TAU * remaining))


func _update_shadow() -> void:
	var height := clampf(_holder.position.y / TOSS_HEIGHT, 0.0, 1.0)
	_shadow.scale = Vector3.ONE * (1.0 - 0.45 * height)
	(_shadow.material_override as StandardMaterial3D).albedo_color.a = 0.35 * (1.0 - 0.6 * height)


func _play_ripple(strength: float) -> void:
	_ripple.scale = Vector3.ONE * 0.4
	_ripple_material.albedo_color = Color(body_color.lightened(0.4), 0.7 * strength)
	var t := create_tween().set_parallel()
	t.tween_property(_ripple, "scale", Vector3.ONE * (1.2 + 0.8 * strength), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_ripple_material, "albedo_color:a", 0.0, 0.35)


func _apply_colors() -> void:
	if _body_material == null:
		return
	_body_material.albedo_color = body_color
	_socket_material.albedo_color = body_color.darkened(0.45)
	_pip_material.albedo_color = pip_color
	_glow_material.albedo_color = Color(body_color.lightened(0.2), _glow_material.albedo_color.a)


func _build_scene() -> void:
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.size = Vector2i(320, 320)
	add_child(_viewport)

	var world := Node3D.new()
	_viewport.add_child(world)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.85, 0.88, 1.0)
	environment.ambient_light_energy = 0.3
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	world.add_child(world_env)

	# Key light (warm), fill (cool) and a rim light from behind for a shiny edge.
	_add_light(world, Vector3(-55, 35, 0), Color(1.0, 0.96, 0.9), 1.05)
	_add_light(world, Vector3(-20, -120, 0), Color(0.75, 0.82, 1.0), 0.35)
	_add_light(world, Vector3(-15, 180, 0), Color(1, 1, 1), 0.6)

	var camera := Camera3D.new()
	camera.fov = 30.0
	var eye := Vector3(0, 4.2, 3.6)
	camera.transform = Transform3D(Basis.looking_at(Vector3(0, 0.45, 0) - eye, Vector3.UP), eye)
	world.add_child(camera)

	_glow = _flat_disc(world, 0.95, -0.54, Color(1, 1, 1, 0.0))
	_glow_material = _glow.material_override as StandardMaterial3D
	_shadow = _flat_disc(world, 0.6, -0.53, Color(0, 0, 0, 0.35))
	_ripple = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.62
	ring.outer_radius = 0.7
	ring.rings = 32
	_ripple.mesh = ring
	_ripple_material = _unshaded(Color(1, 1, 1, 0.0))
	_ripple.material_override = _ripple_material
	_ripple.position = Vector3(0, -0.52, 0)
	world.add_child(_ripple)

	_holder = Node3D.new()
	world.add_child(_holder)
	_cube = Node3D.new()
	_holder.add_child(_cube)

	_body_material = StandardMaterial3D.new()
	_body_material.roughness = 0.18
	_body_material.metallic_specular = 0.8
	_body_material.rim_enabled = true
	_body_material.rim = 0.35
	_body_material.rim_tint = 0.6
	_socket_material = StandardMaterial3D.new()
	_socket_material.roughness = 0.5
	_pip_material = StandardMaterial3D.new()
	_pip_material.roughness = 0.25
	_pip_material.metallic_specular = 0.7
	_apply_colors()
	_build_rounded_cube(_body_material)
	_build_pips()


func _add_light(world: Node3D, degrees: Vector3, color: Color, energy: float) -> void:
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z))
	light.light_color = color
	light.light_energy = energy
	world.add_child(light)


func _unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	return material


func _flat_disc(world: Node3D, radius: float, y: float, color: Color) -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.01
	mesh.radial_segments = 40
	disc.mesh = mesh
	disc.material_override = _unshaded(color)
	disc.position = Vector3(0, y, 0)
	world.add_child(disc)
	return disc


## A 1 x 1 x 1 cube with rounded edges: three crossing boxes, 12 edge cylinders, 8 corner spheres.
func _build_rounded_cube(material: Material) -> void:
	var r := 0.11
	var inner := 1.0 - r * 2.0
	for box_size in [Vector3(1, inner, inner), Vector3(inner, 1, inner), Vector3(inner, inner, 1)]:
		var box := BoxMesh.new()
		box.size = box_size
		_add_mesh(box, Vector3.ZERO, Vector3.ZERO, material)
	var h := inner * 0.5
	var edge := CylinderMesh.new()
	edge.top_radius = r
	edge.bottom_radius = r
	edge.height = inner
	edge.radial_segments = 16
	for a in [-1.0, 1.0]:
		for b in [-1.0, 1.0]:
			_add_mesh(edge, Vector3(a * h, 0, b * h), Vector3.ZERO, material)
			_add_mesh(edge, Vector3(0, a * h, b * h), Vector3(0, 0, PI / 2.0), material)
			_add_mesh(edge, Vector3(a * h, b * h, 0), Vector3(PI / 2.0, 0, 0), material)
	var corner := SphereMesh.new()
	corner.radius = r
	corner.height = r * 2.0
	corner.radial_segments = 16
	corner.rings = 8
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				_add_mesh(corner, Vector3(x * h, y * h, z * h), Vector3.ZERO, material)


## Each pip is a white dot sitting in a darker hollow, like real dice.
func _build_pips() -> void:
	var socket := SphereMesh.new()
	socket.radius = 0.12
	socket.height = 0.24
	socket.radial_segments = 16
	socket.rings = 8
	var pip := SphereMesh.new()
	pip.radius = 0.088
	pip.height = 0.176
	pip.radial_segments = 16
	pip.rings = 8
	for face_value in FACES:
		var axes: Array = FACES[face_value]
		var normal: Vector3 = axes[0]
		var u: Vector3 = axes[1]
		var v: Vector3 = axes[2]
		for spot in PIPS[face_value]:
			var p: Vector2 = spot
			var at := u * p.x * 0.25 + v * p.y * 0.25
			var flatten := Vector3.ONE - normal.abs() * 0.82
			var hole := _add_mesh(socket, normal * 0.497 + at, Vector3.ZERO, _socket_material)
			hole.scale = flatten
			var dot := _add_mesh(pip, normal * 0.502 + at, Vector3.ZERO, _pip_material)
			dot.scale = Vector3.ONE - normal.abs() * 0.7


func _add_mesh(mesh: Mesh, position_3d: Vector3, rotation_3d: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position_3d
	node.rotation = rotation_3d
	node.material_override = material
	_cube.add_child(node)
	return node
