extends Node
## Autoload "CourseClock": times a course from Vin's first input to the goal.

var elapsed := 0.0
var running := false
var started := false


func _physics_process(delta: float) -> void:
	if not started:
		var vin := get_tree().get_first_node_in_group("player") as Vin
		if vin and (vin.controls.move != Vector2.ZERO or vin.controls.jump_held or vin.controls.push_held or vin.controls.pull_held):
			started = true
			running = true
	if running:
		elapsed += TimeController.real_delta(delta)


func stop() -> void:
	running = false


func reset_for_test() -> void:
	elapsed = 0.0
	running = false
	started = false
