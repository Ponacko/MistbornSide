class_name MistLayer
extends CanvasLayer
## Full-screen mists over the world and under the blue lines. Bakes the
## level's density map on load, then feeds the shader the camera, the
## attractors and repellers from MistField, and the tin and Steelsight state.

const CELL := 8.0

@export var thickness := 0.35
## Level area to bake; empty means the bounds of every Block plus a margin.
@export var bounds := Rect2()

var thin := 0.0
var _rect: ColorRect
var _material: ShaderMaterial
var _time := 0.0
var _vin: Vin


func _ready() -> void:
	layer = CanvasLayers.MIST
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = load("res://art/shaders/mists.gdshader")
	_material.set_shader_parameter("noise_a", _noise(11, 0.012))
	_material.set_shader_parameter("noise_b", _noise(29, 0.02))
	_material.set_shader_parameter("thickness", thickness)
	_rect.material = _material
	add_child(_rect)
	_bake.call_deferred()


func _noise(seed_value: int, frequency: float) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.frequency = frequency
	n.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.noise = n
	tex.seamless = true
	tex.width = 256
	tex.height = 256
	return tex


func _bake() -> void:
	var level := get_parent() as Node2D
	if level == null:
		return
	var b := bounds if bounds.has_area() else _level_bounds(level)
	var data := MistBake.bake(level, b, CELL)
	_material.set_shader_parameter("density_map", ImageTexture.create_from_image(data.image))
	_material.set_shader_parameter("map_origin", b.position)
	_material.set_shader_parameter("map_size", b.size)


func _level_bounds(level: Node) -> Rect2:
	var r := Rect2()
	for b in level.find_children("*", "Block", true, false):
		var br := Rect2((b as Block).global_position, (b as Block).size)
		r = br if not r.has_area() else r.merge(br)
	return r.grow(160.0)


func _process(delta: float) -> void:
	_time += delta
	if not is_instance_valid(_vin):
		_vin = get_tree().get_first_node_in_group("player") as Vin
	var ct := get_viewport().get_canvas_transform()
	var inv := ct.affine_inverse()
	_material.set_shader_parameter("cam_origin", inv * Vector2.ZERO)
	_material.set_shader_parameter("cam_scale", 1.0 / ct.x.x)
	_material.set_shader_parameter("mist_time", _time)
	_material.set_shader_parameter("drift", MistField.DRIFT)
	var att := []
	for a in MistField.attractors:
		if is_instance_valid(a) and att.size() < 8 and a.mist_strength > 0.0:
			var p: Vector2 = a.chest_position() if a.has_method("chest_position") else a.global_position
			att.append(Vector4(p.x, p.y, a.mist_strength, a.mist_phase))
	var rep := []
	for r in MistField.repellers:
		if is_instance_valid(r) and rep.size() < 8:
			rep.append(Vector4(r.global_position.x, r.global_position.y, r.radius, 1.0))
	_material.set_shader_parameter("attractor_count", att.size())
	_material.set_shader_parameter("repeller_count", rep.size())
	if not att.is_empty():
		_material.set_shader_parameter("attractors", _pad(att))
	if not rep.is_empty():
		_material.set_shader_parameter("repellers", _pad(rep))
	if _vin:
		thin = _vin.senses.mist_thin()
		_material.set_shader_parameter("vision_center", _vin.chest_position())
		_material.set_shader_parameter("vision_radius", _vin.senses.vision_radius())
	_material.set_shader_parameter("thin", thin)
	var aiming := _vin != null and _vin.allomancy.steelsight.time_scale(Game.tuning) < 1.0
	_material.set_shader_parameter("blue_tint", 0.35 if aiming else 0.0)


func _pad(values: Array) -> PackedVector4Array:
	var out := PackedVector4Array(values)
	out.resize(8)
	return out
