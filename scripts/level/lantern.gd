@tool
class_name Lantern
extends Node2D
## A warm lantern: a 2D light, a metal housing (it can be Pushed), and a
## pool of light that exposes Vin to guards (DESIGN.md 6.4).

@export var radius := 130.0:
	set(value):
		radius = value
		_update_light()
@export var energy := 4.5
@export var color := Color(1.0, 0.66, 0.32)
## Lanterns hang from metal; the housing is a metal source.
@export var metal := true
## Seconds between flashes (a lamplighter unshuttering); 0 never flashes.
@export var flash_interval := 0.0
## Flashes before stopping; 0 keeps flashing.
@export var flash_count := 0
## Flashing waits for this story flag (a lesson beat), if set.
@export var flash_after_flag := ""

var _flash_timer := 0.0
var _flash_glow := 0.0
var _flashes := 0

var light: PointLight2D

static var _texture: GradientTexture2D


func _ready() -> void:
	light = PointLight2D.new()
	light.texture = _light_texture()
	light.color = color
	light.energy = energy
	# Normal-mapped walls face the camera; the light must sit in front of
	# them (height) or it only grazes them.
	light.height = 90.0
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.shadow_filter_smooth = 2.0
	light.shadow_color = Color(0, 0, 0, 0.55)
	# Warmest at the core: the gradient's inner stop drives the pool's heart.
	light.blend_mode = Light2D.BLEND_MODE_ADD
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
	if flash_interval > 0.0 and (flash_after_flag == "" or StoryFlags.get_flag(flash_after_flag)) and (flash_count == 0 or _flashes < flash_count):
		_flash_timer += delta
		if _flash_timer >= flash_interval:
			_flash_timer = 0.0
			flash()
	_flash_glow = move_toward(_flash_glow, 0.0, delta * 4.0)
	light.energy = energy + _flash_glow * 3.0


## Unshutters the lantern at full blaze: blinds a tin-burner who sees it.
func flash() -> void:
	_flash_glow = 1.0
	_flashes += 1
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
		g.add_point(0.25, Color(1, 1, 1, 0.7))
		g.add_point(0.55, Color(1, 1, 1, 0.3))
		_texture.gradient = g
	return _texture


func _process(_delta: float) -> void:
	if light and not Engine.is_editor_hint():
		# A candle's slow flicker.
		var t := Time.get_ticks_msec() / 1000.0
		var flicker := 0.92 + 0.08 * sin(t * 7.3 + position.x) * sin(t * 3.1 + position.y)
		light.energy = (energy + _flash_glow * 3.0) * flicker
		queue_redraw()


func _draw() -> void:
	var iron := Color(0.18, 0.17, 0.17)
	# Bracket and chain.
	draw_line(Vector2(0, -6), Vector2(0, -14), iron, 1.0)
	draw_rect(Rect2(-1, -15, 2, 2), iron)
	# Housing: a small glass box with an iron cap and base.
	draw_rect(Rect2(-4, -6, 8, 2), iron)
	draw_rect(Rect2(-3, -4, 6, 7), Color(1.0, 0.75, 0.4, 0.55))
	draw_rect(Rect2(-4, 3, 8, 2), iron)
	draw_line(Vector2(-3, -4), Vector2(-3, 3), iron, 1.0)
	draw_line(Vector2(3, -4), Vector2(3, 3), iron, 1.0)
	# The flame itself, above white so it blooms.
	var glow := 1.4 + _flash_glow * 3.0
	draw_rect(Rect2(-1, -2, 2, 3), Color(1.0, 0.85, 0.5) * glow)
	draw_rect(Rect2(-2, -1, 4, 2), Color(1.0, 0.65, 0.3, 0.8) * glow)
