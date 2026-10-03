@tool
class_name MistInterior
extends Node2D
## A room the mists will not enter (DESIGN.md 12.3). Position is the top-left
## corner; the mists fade out softly across its edges and doorways.

@export var size := Vector2(128, 64):
	set(value):
		size = value
		queue_redraw()


func _enter_tree() -> void:
	add_to_group("mist_interiors")


func rect() -> Rect2:
	return Rect2(global_position, size)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.8, 1.0, 0.15))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.8, 1.0, 0.6), false, 1.0)
