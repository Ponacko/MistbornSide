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
