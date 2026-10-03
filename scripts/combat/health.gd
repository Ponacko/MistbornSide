class_name Health
extends RefCounted
## Hit points for anything that can be hurt.

signal changed(current: float)
signal died

var max_health := 100.0
var current := 100.0


func _init(maximum := 100.0) -> void:
	max_health = maximum
	current = maximum


func is_dead() -> bool:
	return current <= 0.0


func damage(amount: float) -> void:
	if is_dead():
		return
	current = maxf(current - amount, 0.0)
	changed.emit(current)
	if current <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	if is_dead():
		return
	current = minf(current + amount, max_health)
	changed.emit(current)


func reset(value := -1.0) -> void:
	current = max_health if value < 0.0 else value
	changed.emit(current)


func fraction() -> float:
	return current / max_health
