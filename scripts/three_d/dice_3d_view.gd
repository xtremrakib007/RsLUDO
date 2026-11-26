class_name Dice3DView
extends SubViewportContainer
## A real 3D dice in its own little 3D scene: a white rounded cube with coloured
## pips that tumbles, bounces and lands showing the rolled value on top.
## Same small API as the old 2D DiceFace: `value`, `pip_color`, plus roll_to().

const ROLL_TIME := 0.9
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

var value: int = 6:
	set(v):
		value = clampi(v, 1, 6)
		if _cube != null:
			_cube.basis = Basis.from_euler(FACE_ROTATIONS[value])
## The cube's colour (the current player's colour).
var body_color: Color = Color("f2f0e8"):
	set(c):
		body_color = c
		if _body_material != null:
			_body_material.albedo_color = c
var pip_color: Color = Palette.TEXT_DARK:
	set(c):
		pip_color = c
		if _pip_material != null:
			_pip_material.albedo_color = c

var _viewport: SubViewport
var _holder: Node3D
var _cube: Node3D
var _shadow: MeshInstance3D
var _pip_material: StandardMaterial3D
var _body_material: StandardMaterial3D
var _final_rotation: Quaternion
var _spin_axis: Vector3 = Vector3.UP
var _spins: float = 3.0


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_scene()


func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	value = value


## Tumbles and bounces, then lands with `result` on top.
func roll_to(result: int) -> void:
	value = clampi(result, 1, 6)
	_final_rotation = Basis.from_euler(FACE_ROTATIONS[value]).get_rotation_quaternion()
	_spin_axis = Vector3(randf_range(-1.0, 1.0), randf_range(0.3, 1.0), randf_range(-1.0, 1.0)).normalized()
	_spins = randf_range(2.5, 3.5)
	_roll_step(0.0)
	var spin := create_tween()
	spin.tween_method(_roll_step, 0.0, 1.0, ROLL_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var bounce := create_tween()
	bounce.tween_property(_holder, "position:y", 0.9, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce.tween_property(_holder, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	bounce.tween_property(_holder, "position:y", 0.3, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce.tween_property(_holder, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await spin.finished
	_cube.basis = Basis(_final_rotation)


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


func _roll_step(t: float) -> void:
	var remaining := pow(1.0 - clampf(t, 0.0, 1.0), 2.0)
	_cube.basis = Basis(_final_rotation * Quaternion(_spin_axis, _spins * TAU * remaining))
	var height := _holder.position.y
	_shadow.scale = Vector3.ONE * (1.0 - 0.35 * clampf(height, 0.0, 1.0))


func _build_scene() -> void:
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.size = Vector2i(256, 256)
	add_child(_viewport)

	var world := Node3D.new()
	_viewport.add_child(world)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1, 1, 1)
	environment.ambient_light_energy = 0.35
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	world.add_child(world_env)

	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(35.0), 0.0)
	light.light_energy = 1.0
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(-120.0), 0.0)
	fill.light_energy = 0.35
	world.add_child(fill)
	world.add_child(light)

	var camera := Camera3D.new()
	camera.fov = 28.0
	var eye := Vector3(0, 3.6, 3.0)
	camera.transform = Transform3D(Basis.looking_at(Vector3(0, 0.35, 0) - eye, Vector3.UP), eye)
	world.add_child(camera)

	_shadow = MeshInstance3D.new()
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.62
	shadow_mesh.bottom_radius = 0.62
	shadow_mesh.height = 0.01
	_shadow.mesh = shadow_mesh
	var shadow_material := StandardMaterial3D.new()
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.albedo_color = Color(0, 0, 0, 0.3)
	_shadow.material_override = shadow_material
	_shadow.position = Vector3(0, -0.55, 0)
	world.add_child(_shadow)

	_holder = Node3D.new()
	world.add_child(_holder)
	_cube = Node3D.new()
	_holder.add_child(_cube)

	var body := StandardMaterial3D.new()
	body.albedo_color = body_color
	body.roughness = 0.4
	_body_material = body
	_pip_material = StandardMaterial3D.new()
	_pip_material.albedo_color = pip_color
	_pip_material.roughness = 0.5
	_build_rounded_cube(body)
	_build_pips()


## A 1 x 1 x 1 cube with rounded edges: three crossing boxes, 12 edge cylinders, 8 corner spheres.
func _build_rounded_cube(material: Material) -> void:
	var r := 0.09
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
	edge.radial_segments = 12
	for a in [-1.0, 1.0]:
		for b in [-1.0, 1.0]:
			_add_mesh(edge, Vector3(a * h, 0, b * h), Vector3.ZERO, material)
			_add_mesh(edge, Vector3(0, a * h, b * h), Vector3(0, 0, PI / 2.0), material)
			_add_mesh(edge, Vector3(a * h, b * h, 0), Vector3(PI / 2.0, 0, 0), material)
	var corner := SphereMesh.new()
	corner.radius = r
	corner.height = r * 2.0
	corner.radial_segments = 12
	corner.rings = 6
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				_add_mesh(corner, Vector3(x * h, y * h, z * h), Vector3.ZERO, material)


func _build_pips() -> void:
	var pip := SphereMesh.new()
	pip.radius = 0.1
	pip.height = 0.2
	pip.radial_segments = 12
	pip.rings = 6
	for face_value in FACES:
		var axes: Array = FACES[face_value]
		var normal: Vector3 = axes[0]
		var u: Vector3 = axes[1]
		var v: Vector3 = axes[2]
		for spot in PIPS[face_value]:
			var p: Vector2 = spot
			var node := _add_mesh(pip, normal * 0.5 + u * p.x * 0.25 + v * p.y * 0.25, Vector3.ZERO, _pip_material)
			# Flatten each pip so it sits on its face like a painted dot.
			node.scale = Vector3.ONE - normal.abs() * 0.6


func _add_mesh(mesh: Mesh, position_3d: Vector3, rotation_3d: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position_3d
	node.rotation = rotation_3d
	node.material_override = material
	_cube.add_child(node)
	return node
