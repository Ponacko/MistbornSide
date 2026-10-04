class_name TargetDummy
extends StaticBody2D
## A straw target for practice: dies to any lethal hit.

signal died

var dead := false


func _ready() -> void:
	collision_layer = Layers.ENEMY
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 40)
	shape.shape = rect
	shape.position = Vector2(0, -20)
	add_child(shape)
	add_to_group("hittable")


func take_hit(_hit: Hit) -> bool:
	if dead:
		return false
	dead = true
	rotation = deg_to_rad(80)
	position.y -= 4
	died.emit()
	return true


func _draw() -> void:
	var c := Color(0.55, 0.45, 0.3) if not dead else Color(0.35, 0.3, 0.2)
	draw_rect(Rect2(-7, -40, 14, 40), c)
	draw_circle(Vector2(0, -44), 5, c)
