extends TestCase

const FLOOR := Rect2(-400, 0, 1600, 32)


func test_vin_runs_at_run_speed() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(3)
	w.vin.controls.move.x = 1.0
	await physics_frames(40)
	assert_near(w.vin.velocity.x, Game.tuning.run_speed, 1.0, "run speed")
	assert_true(w.vin.is_on_floor(), "stays grounded")


func test_jump_reaches_tuned_height() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(3)
	var start_y := w.vin.global_position.y
	w.vin.controls.jump_pressed = true
	w.vin.controls.jump_held = true
	var top := start_y
	for i in 60:
		await physics_frames(1)
		top = minf(top, w.vin.global_position.y)
	var height := start_y - top
	# Apex gravity reduction can only add a few pixels on top of the tuned height.
	assert_gt(height, Game.tuning.jump_height_tiles * Tuning.TILE - 2.0, "jump height")
	assert_lt(height, Game.tuning.jump_height_tiles * Tuning.TILE + 8.0, "jump height")


func test_releasing_jump_early_cuts_height() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(3)
	var start_y := w.vin.global_position.y
	w.vin.controls.jump_pressed = true
	w.vin.controls.jump_held = true
	await physics_frames(4)
	w.vin.controls.jump_held = false
	var top := start_y
	for i in 40:
		await physics_frames(1)
		top = minf(top, w.vin.global_position.y)
	assert_lt(start_y - top, Game.tuning.jump_height_tiles * Tuning.TILE * 0.6, "short hop")


func test_coyote_jump_after_running_off_an_edge() -> void:
	var w := TestWorld.create(self, [Rect2(-400, 0, 400, 32)], Vector2(-20, -1))
	await physics_frames(3)
	w.vin.controls.move.x = 1.0
	while w.vin.is_on_floor():
		await physics_frames(1)
	await physics_frames(3)
	w.vin.controls.jump_pressed = true
	w.vin.controls.jump_held = true
	await physics_frames(1)
	assert_lt(w.vin.velocity.y, -100.0, "jumped in coyote window")


func test_ledge_grab_and_climb() -> void:
	# A wall with its top at y = -64; Vin jumps into it from the left.
	var w := TestWorld.create(self, [FLOOR, Rect2(40, -64, 200, 64)], Vector2(10, -1))
	await physics_frames(3)
	w.vin.controls.move.x = 1.0
	w.vin.controls.jump_pressed = true
	w.vin.controls.jump_held = true
	var grabbed := false
	for i in 90:
		await physics_frames(1)
		if w.vin.state == Vin.State.LEDGE_HANG:
			grabbed = true
			break
	assert_true(grabbed, "grabbed the ledge")
	w.vin.controls.move.x = 0.0
	w.vin.controls.jump_pressed = true
	await physics_frames(20)
	assert_near(w.vin.global_position.y, -64.0, 1.5, "climbed on top")
	assert_true(w.vin.is_on_floor(), "standing on the ledge")


func test_wall_slide_caps_fall_speed() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(40, -400, 32, 400)], Vector2(33, -300))
	w.vin.controls.move.x = 1.0
	await physics_frames(60)
	assert_true(w.vin.is_on_wall(), "against the wall")
	assert_near(w.vin.velocity.y, Game.tuning.wall_slide_speed, 1.0, "slide speed")


func test_wall_jump_kicks_away_from_the_wall() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(40, -400, 32, 400)], Vector2(33, -300))
	w.vin.controls.move.x = 1.0
	await physics_frames(30)
	w.vin.controls.jump_pressed = true
	await physics_frames(2)
	assert_lt(w.vin.velocity.x, -100.0, "moving away")
	assert_lt(w.vin.velocity.y, 0.0, "moving up")


func test_crouch_shrinks_and_cannot_stand_under_a_low_ceiling() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(30, -38, 200, 8)], Vector2(0, -1))
	await physics_frames(3)
	w.vin.controls.move = Vector2(0, 1)
	await physics_frames(2)
	assert_true(w.vin.crouching, "crouching")
	w.vin.controls.move = Vector2(1, 1)
	await physics_frames(50)
	assert_gt(w.vin.global_position.x, 40.0, "crawled under the ceiling")
	w.vin.controls.move = Vector2(0, 0)
	await physics_frames(5)
	assert_true(w.vin.crouching, "stays crouched under the ceiling")
