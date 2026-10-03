@tool
class_name Block
extends StaticBody2D
## A grey-box solid. Position is the top-left corner; size is in pixels.
## Designers place and resize these in the editor; collision follows.

@export var size := Vector2(64, 16):
	set(value):
		size = value
		_rebuild()
@export var color := Color(0.33, 0.34, 0.38):
	set(value):
		color = value
		queue_redraw()

var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		add_child(_shape)
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size / 2.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 2)), color.lightened(0.2))
