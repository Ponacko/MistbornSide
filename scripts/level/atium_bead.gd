class_name AtiumBead
extends Area2D
## A bead of atium: rare, precious, one burn of future-sight.

func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.PLAYER
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(func(b):
		if b is Vin:
			(b as Vin).atium_beads += 1
			queue_free())


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color(0.92, 0.94, 0.98))
	draw_circle(Vector2(-1, -1), 1.0, Color.WHITE)
