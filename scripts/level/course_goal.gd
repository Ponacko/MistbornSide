class_name CourseGoal
extends Area2D
## The end of a timed course: records the time it took from the first move.

signal finished(seconds: float)

@export var size := Vector2(32, 64)

var done := false


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, -size.y / 2.0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	add_to_group("course_goal")


func _on_body_entered(body: Node) -> void:
	if body is Vin and not done:
		done = true
		finished.emit(CourseClock.elapsed)
		CourseClock.stop()
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-1, -40, 2, 40), Color(0.6, 0.6, 0.65))
	draw_colored_polygon(PackedVector2Array([Vector2(1, -40), Vector2(16, -34), Vector2(1, -28)]), Color(0.9, 0.85, 0.5) if done else Color(0.7, 0.3, 0.25))
