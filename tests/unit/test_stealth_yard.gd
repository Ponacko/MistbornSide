extends TestCase
## The stealth yard crossed by the rooftop route: unseen with copper on,
## felt by the Seeker without it.

var level: Node2D
var vin: Vin
var worst := Suspicion.Stage.IDLE


func _load() -> void:
	level = (load("res://levels/test/stealth_yard.tscn") as PackedScene).instantiate()
	add(level)
	vin = level.get_node("Vin")
	vin.scripted = true
	await physics_frames(3)


func _frame() -> void:
	await physics_frames(1)
	for e in tree.get_nodes_in_group("enemies"):
		worst = maxi(worst, (e as Enemy).suspicion.stage) as Suspicion.Stage


func _walk_to(x: float) -> void:
	for f in 300:
		var dx := x - vin.global_position.x
		if absf(dx) < 3.0:
			break
		vin.controls.move.x = signf(dx)
		await _frame()
	vin.controls.move.x = 0.0
	for f in 10:
		await _frame()


func _pull_up(bracket: String, roof_x: float) -> bool:
	vin.controls.aim_active = true
	vin.controls.aim_point = (level.get_node("Metal/" + bracket) as Node2D).global_position
	vin.controls.pull_pressed = true
	vin.controls.pull_held = true
	var hung := false
	for f in 150:
		await _frame()
		if vin.state == Vin.State.BRACKET_HANG:
			hung = true
			break
	if not hung:
		return false
	vin.controls.jump_pressed = true
	vin.controls.jump_held = true
	vin.controls.move.x = 1.0
	await _frame()
	vin.controls.pull_held = false
	for f in 120:
		await _frame()
		if vin.is_on_floor() and vin.global_position.x > roof_x:
			vin.controls.move.x = 0.0
			vin.controls.jump_held = false
			return true
	return false


func _cross() -> bool:
	await _walk_to(240.0)
	if not await _pull_up("BracketB", 405.0):
		return false
	await _walk_to(612.0)
	if not await _pull_up("BracketC", 825.0):
		return false
	await _walk_to(1092.0)
	if not await _pull_up("BracketD", 1255.0):
		return false
	await _walk_to(1385.0)
	return (level.get_node("Goal") as CourseGoal).done


func test_the_yard_can_be_crossed_unseen_with_copper() -> void:
	await _load()
	vin.copper_on = true
	vin.toggle_tin_now(true)
	assert_true(await _cross(), "reached the far roof")
	assert_true(worst < Suspicion.Stage.ALERTED, "no alert raised")
	assert_false((level.get_node("Bell") as AlarmBell).rung, "the bell stayed quiet")


func test_the_seeker_feels_the_same_route_without_copper() -> void:
	await _load()
	vin.copper_on = false
	vin.toggle_tin_now(true)
	await _cross()
	assert_gt(worst, Suspicion.Stage.IDLE, "the Seeker felt her burning tin and Pulls")
