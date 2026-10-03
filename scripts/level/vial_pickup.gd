class_name VialPickup
extends Area2D
## A glass vial of metal flakes in alcohol: refills every basic metal.

func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.PLAYER
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Vin:
		(body as Vin).reserves.refill_all()
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-2, -6, 4, 9), Color(0.75, 0.85, 0.9, 0.7))
	draw_rect(Rect2(-2, -2, 4, 5), Color(0.6, 0.6, 0.65))
	draw_rect(Rect2(-1, -8, 2, 2), Color(0.4, 0.3, 0.2))
