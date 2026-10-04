class_name DroppedWeapon
extends RigidBody2D
## A torn-away or dropped spear: loose dynamic metal.

func _ready() -> void:
	mass = 2.0
	collision_layer = Layers.METAL
	collision_mask = Layers.WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 2)
	shape.shape = rect
	add_child(shape)
	var s := MetalSource.new()
	s.kind = MetalSource.Kind.DYNAMIC
	s.mass = 2.0
	add_child(s)
	add_to_group("dropped_weapons")


func _draw() -> void:
	draw_line(Vector2(-11, 0), Vector2(8, 0), Color(0.45, 0.33, 0.22), 2.0)
	draw_line(Vector2(8, 0), Vector2(11, 0), Color(0.7, 0.72, 0.76), 2.0)
