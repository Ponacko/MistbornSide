@tool
class_name Checkpoint
extends Area2D
## Touching it makes this the place Vin returns to. Position is the
## respawn point (her feet); size is the trigger area above it.

@export var size := Vector2(48, 64)

var _used := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, -size.y / 2.0)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Vin and not _used:
		_used = true
		Checkpoints.reach(body, global_position)


func _draw() -> void:
	draw_rect(Rect2(-1, -24, 2, 24), Color(0.5, 0.5, 0.55))
	draw_rect(Rect2(1, -24, 8, 6), Color(0.55, 0.62, 0.8) if not _used else Color(0.75, 0.85, 1.0))
