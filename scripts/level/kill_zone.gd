@tool
class_name KillZone
extends Area2D
## The street far below the roofs: falling into it returns Vin to her last
## checkpoint. Position is the top-left corner.

@export var size := Vector2(256, 32)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size / 2.0
	add_child(shape)
	body_entered.connect(func(body):
		if body is Vin:
			Checkpoints.respawn.call_deferred(body))


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.2, 0.25))
