@tool
class_name SoothingField
extends Node2D
## The Soothing stations of Kredik Shaw: a constant dampening of emotion
## that weighs on Vin (slower, greyer) unless her copper is on (DESIGN.md
## 5.9). Position is the top-left corner.

@export var size := Vector2(600, 160):
	set(value):
		size = value
		queue_redraw()

var _was_inside := false


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var vin := get_tree().get_first_node_in_group("player") as Vin
	if vin == null:
		return
	var inside := Rect2(global_position, size).has_point(vin.global_position + Vector2(0, -1))
	if inside:
		vin.soothed = not vin.copper_on
	elif _was_inside:
		vin.soothed = false
	_was_inside = inside


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.6, 1.0, 0.1))
