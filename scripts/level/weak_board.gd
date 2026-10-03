class_name WeakBoard
extends StaticBody2D
## Boards over a doorway: pewter shoulders through them. Position is the
## top-left corner.

signal broke

@export var size := Vector2(8, 48)

var broken := false


func _ready() -> void:
	collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size / 2.0
	add_child(shape)


## Called when Vin runs into the board. Breaks only for pewter.
func shoulder(by: Vin) -> bool:
	if broken or not by.pewter_on:
		return false
	broken = true
	NoiseBus.emit(global_position + size / 2.0, 1.0, NoiseBus.Kind.BREAK)
	broke.emit()
	queue_free()
	return true


func _draw() -> void:
	for i in 3:
		draw_rect(Rect2(0, i * size.y / 3.0 + 2, size.x, size.y / 3.0 - 4), Color(0.45, 0.32, 0.2))
