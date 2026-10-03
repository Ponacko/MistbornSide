class_name Hazard
extends Area2D
## A test hazard (embers, broken glass): hurts whatever stands in it.

@export var damage := 20.0
@export var interval := 0.6
@export var size := Vector2(24, 12)

var _cooldown := {}


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.PLAYER | Layers.ENEMY
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	add_child(shape)


func _physics_process(delta: float) -> void:
	for k in _cooldown.keys():
		_cooldown[k] -= delta
	for body in get_overlapping_bodies():
		if body.has_method("take_hit") and _cooldown.get(body, 0.0) <= 0.0:
			_cooldown[body] = interval
			body.take_hit(Hit.make(Hit.Kind.HAZARD, damage, (body.global_position - global_position).normalized(), self, true))


func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), Color(0.9, 0.35, 0.1, 0.8))
