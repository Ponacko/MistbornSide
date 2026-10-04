class_name Logbook
extends Area2D
## The Lord Ruler's logbook (mission 9): the thing Vin came for.

signal taken


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 24)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(func(b):
		if b is Vin:
			taken.emit()
			queue_free())


func _draw() -> void:
	draw_rect(Rect2(-5, -7, 10, 13), Color(0.35, 0.18, 0.12))
	draw_rect(Rect2(-4, -6, 8, 11), Color(0.82, 0.76, 0.62))
	draw_line(Vector2(0, -6), Vector2(0, 5), Color(0.3, 0.2, 0.15), 1.0)
