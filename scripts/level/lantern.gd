@tool
class_name Lantern
extends Node2D
## A warm lantern: a 2D light, a metal housing (it can be Pushed), and a
## pool of light that exposes Vin to guards (DESIGN.md 6.4).

@export var radius := 110.0:
	set(value):
		radius = value
		_update_light()
@export var energy := 1.3
@export var color := Color(1.0, 0.66, 0.32)
## Lanterns hang from metal; the housing is a metal source.
@export var metal := true
## Seconds between flashes (a lamplighter unshuttering); 0 never flashes.
@export var flash_interval := 0.0

var _flash_timer := 0.0
var _flash_glow := 0.0

var light: PointLight2D

static var _texture: GradientTexture2D


func _ready() -> void:
	light = PointLight2D.new()
	light.texture = _light_texture()
	light.color = color
	light.energy = energy
	light.shadow_enabled = false
	add_child(light)
	_update_light()
	if Engine.is_editor_hint():
		return
	add_to_group("lights")
	if metal:
		var s := MetalSource.new()
		s.mass = 3.0
		add_child(s)


func _update_light() -> void:
	if light:
		light.texture_scale = radius / 64.0


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or light == null:
		return
	if flash_interval > 0.0:
		_flash_timer += delta
		if _flash_timer >= flash_interval:
			_flash_timer = 0.0
			flash()
	_flash_glow = move_toward(_flash_glow, 0.0, delta * 4.0)
	light.energy = energy + _flash_glow * 3.0


## Unshutters the lantern at full blaze: blinds a tin-burner who sees it.
func flash() -> void:
	_flash_glow = 1.0
	var vin := get_tree().get_first_node_in_group("player") as Vin
	if vin and vin.chest_position().distance_to(global_position) < radius * 1.5:
		var q := PhysicsRayQueryParameters2D.create(global_position, vin.chest_position(), Layers.WORLD)
		if get_world_2d().direct_space_state.intersect_ray(q).is_empty():
			vin.senses.flash(global_position)


## True if a point is lit by this lantern.
func lights_point(p: Vector2) -> bool:
	return visible and p.distance_to(global_position) < radius * 0.8


static func _light_texture() -> GradientTexture2D:
	if _texture == null:
		_texture = GradientTexture2D.new()
		_texture.width = 128
		_texture.height = 128
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.4, Color(1, 1, 1, 0.45))
		_texture.gradient = g
	return _texture


func _draw() -> void:
	draw_rect(Rect2(-3, -5, 6, 8), Color(0.2, 0.18, 0.16))
	draw_rect(Rect2(-2, -4, 4, 5), Color(1.0, 0.8, 0.45))
	draw_line(Vector2(0, -5), Vector2(0, -10), Color(0.3, 0.3, 0.32), 1.0)
