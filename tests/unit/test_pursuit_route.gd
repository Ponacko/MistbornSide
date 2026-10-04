extends TestCase
## The authored pursuit route: a competent run escapes Bendal; a stalled
## run dies.

var level: Node2D
var vin: Vin


func _load() -> void:
	level = (load("res://levels/test/pursuit_route.tscn") as PackedScene).instantiate()
	add(level)
	vin = level.get_node("Vin")
	vin.scripted = true
	await physics_frames(3)


func test_a_competent_run_escapes() -> void:
	await _load()
	var escape: CourseGoal = level.get_node("Escape")
	vin.toggle_pewter_now(true)
	vin.controls.move.x = 1.0
	var deaths := [0]
	vin.died.connect(func(): deaths[0] += 1)
	for f in 60 * 40:
		vin.toggle_pewter_now(true)
		vin.controls.jump_pressed = false
		vin.controls.jump_held = not vin.is_on_floor()
		for gap in level.get_meta("gaps"):
			var ahead: float = gap.x - vin.global_position.x
			if vin.is_on_floor() and ahead > 0.0 and ahead < 18.0:
				vin.controls.jump_pressed = true
				vin.controls.jump_held = true
		await physics_frames(1)
		if escape.done or deaths[0] > 0:
			break
	assert_eq(deaths[0], 0, "she was not caught")
	assert_true(escape.done, "escaped")


func test_a_stalled_run_dies() -> void:
	await _load()
	var deaths := [0]
	vin.died.connect(func(): deaths[0] += 1)
	for f in 60 * 30:
		await physics_frames(1)
		if deaths[0] > 0:
			break
	assert_gt(deaths[0], 0, "Bendal caught her")
