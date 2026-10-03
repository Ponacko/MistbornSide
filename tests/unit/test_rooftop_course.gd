extends TestCase
## Scripted solutions to each traversal problem on the grey-box rooftop
## course: proof that every problem can be crossed with the default tuning.

var level: Node2D
var vin: Vin


func _load(at: Vector2) -> void:
	level = (load("res://levels/greybox/greybox.tscn") as PackedScene).instantiate()
	add(level)
	vin = level.get_node("Vin")
	vin.scripted = true
	vin.global_position = at
	vin.reset_physics_interpolation()
	await physics_frames(3)


func _aim(at: Vector2, moved := false) -> void:
	vin.controls.aim_active = true
	vin.controls.aim_point = at
	vin.controls.aim_moved = moved


func _src(name: String) -> Vector2:
	return (level.get_node("Metal/" + name) as Node2D).global_position


func _on_roof(x_min: float, x_max: float, top: float) -> bool:
	return vin.is_on_floor() and vin.global_position.x > x_min and vin.global_position.x < x_max and absf(vin.global_position.y - top) < 2.0


func _until(frames: int, cond: Callable) -> bool:
	for i in frames:
		await physics_frames(1)
		if cond.call():
			return true
	return false


func test_problem_1_pull_up_to_a_high_bracket() -> void:
	await _load(Vector2(250, -161))
	_aim(_src("P1_HighBracket"))
	vin.controls.pull_pressed = true
	vin.controls.pull_held = true
	assert_true(await _until(120, func(): return vin.state == Vin.State.BRACKET_HANG), "hanging from the bracket")
	vin.controls.jump_pressed = true
	vin.controls.jump_held = true
	vin.controls.move.x = 1.0
	await physics_frames(2)
	vin.controls.pull_held = false
	assert_true(await _until(120, func(): return _on_roof(320, 560, -320)), "on roof 1")


func test_problem_2_pull_across_the_street_and_retarget() -> void:
	await _load(Vector2(530, -321))
	_aim(_src("P2_StreetLamp"))
	vin.controls.pull_pressed = true
	vin.controls.pull_held = true
	assert_true(await _until(120, func(): return vin.state == Vin.State.BRACKET_HANG), "at the street lamp")
	_aim(_src("P2_FarBracket"), true)
	assert_true(await _until(120, func(): return vin.state == Vin.State.BRACKET_HANG and vin.chest_position().distance_to(_src("P2_FarBracket")) < 4.0), "retargeted to the far bracket")
	vin.controls.jump_pressed = true
	vin.controls.jump_held = true
	vin.controls.move.x = 1.0
	await physics_frames(2)
	vin.controls.pull_held = false
	assert_true(await _until(120, func(): return _on_roof(900, 1140, -300)), "on roof 2")


func test_problem_3_push_off_the_gate_across_the_gap() -> void:
	await _load(Vector2(1010, -301))
	vin.facing = 1
	_aim(_src("P3_Gate"))
	vin.controls.jump_pressed = true
	vin.controls.jump_held = true
	vin.controls.push_pressed = true
	vin.controls.push_held = true
	vin.controls.move.x = 1.0
	await physics_frames(25)
	vin.controls.push_held = false
	assert_true(await _until(180, func(): return _on_roof(1420, 1700, -300)), "on roof 3")


func test_problem_4_climb_the_wall_off_the_grate_and_plate() -> void:
	await _load(Vector2(1648, -301))
	_aim(_src("P4_Grate"))
	vin.controls.push_pressed = true
	vin.controls.push_held = true
	assert_true(await _until(120, func(): return vin.global_position.y < _src("P4_WallPlate").y - 10.0), "risen above the wall plate")
	vin.controls.move.x = 1.0
	assert_true(await _until(60, func(): return vin.global_position.x > _src("P4_WallPlate").x - 8.0), "steered over the plate")
	vin.controls.move.x = 0.0
	_aim(_src("P4_WallPlate"), true)
	assert_true(await _until(180, func(): return vin.global_position.y < -630.0), "risen above the wall top")
	vin.controls.move.x = 1.0
	assert_true(await _until(60, func(): return vin.global_position.x > 1708.0), "over the roof")
	vin.controls.push_held = false
	assert_true(await _until(120, func(): return _on_roof(1700, 1900, -620)), "on roof 4")


func test_problem_5_coin_jump_up_the_step() -> void:
	await _load(Vector2(1860, -621))
	vin.controls.move.y = 1.0
	vin.controls.coin_pressed = true
	await physics_frames(2)
	vin.controls.move.y = 0.0
	await physics_frames(30)
	var coin: Coin = tree.get_nodes_in_group("coins")[0]
	_aim(coin.global_position)
	vin.controls.push_pressed = true
	vin.controls.push_held = true
	assert_true(await _until(90, func(): return vin.global_position.y < -750.0), "launched above the step")
	vin.controls.move.x = 1.0
	assert_true(await _until(180, func(): return _on_roof(1900, 2150, -740)), "on roof 5")


func test_problem_5_fails_when_not_standing_over_the_coin() -> void:
	await _load(Vector2(1860, -621))
	vin.controls.move.y = 1.0
	vin.controls.coin_pressed = true
	await physics_frames(2)
	vin.controls.move.y = 0.0
	await physics_frames(30)
	var coin: Coin = tree.get_nodes_in_group("coins")[0]
	vin.global_position = coin.global_position + Vector2(-34, -1)
	vin.reset_physics_interpolation()
	await physics_frames(5)
	_aim(coin.global_position)
	vin.controls.push_pressed = true
	vin.controls.push_held = true
	await physics_frames(60)
	assert_gt(vin.global_position.y, -700.0, "a skidding coin does not lift her high enough")


func test_problem_6_push_off_the_spire_while_falling() -> void:
	await _load(Vector2(2040, -741))
	vin.controls.aim_active = false
	vin.controls.move.x = 1.0
	assert_true(await _until(120, func(): return vin.global_position.x > 2135.0), "at the edge")
	vin.controls.jump_pressed = true
	vin.controls.jump_held = true
	assert_true(await _until(120, func(): return vin.global_position.x > 2250.0), "over the gap")
	vin.controls.push_pressed = true
	vin.controls.push_held = true
	assert_true(await _until(240, func(): return _on_roof(2500, 2900, -760)), "on the city wall")


func test_the_goal_records_a_time() -> void:
	await _load(Vector2(2780, -761))
	vin.controls.move.x = 1.0
	var goal: CourseGoal = level.get_node("Goal")
	assert_true(await _until(60, func(): return goal.done), "finished")
