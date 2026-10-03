extends TestCase

const FLOOR := Rect2(-800, 0, 1600, 32)


func test_push_with_a_highlighted_target_acts_on_the_press_frame() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var a := w.anchor(Vector2(0, -1), 300.0)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = a.global_position
	await physics_frames(2)
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	await physics_frames(1)
	assert_true(w.vin.allomancy.force_active, "no added latency")
	assert_near(Engine.time_scale, 1.0, 0.0001)


func test_push_with_no_target_opens_steelsight_and_commits_when_the_cursor_finds_one() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -200))
	var a := w.anchor(Vector2(80, -100), 300.0)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = Vector2(-200, -400)
	await physics_frames(2)
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	await physics_frames(Game.tuning.push_buffer_frames + 2)
	assert_near(Engine.time_scale, Game.tuning.steelsight_time_scale, 0.001, "slowed")
	w.vin.controls.aim_point = a.global_position
	w.vin.controls.aim_moved = true
	await physics_frames(2)
	assert_true(w.vin.allomancy.force_active, "committed")
	assert_gt(Engine.time_scale, Game.tuning.steelsight_time_scale, "ramping back")
	await physics_frames(40)
	assert_near(Engine.time_scale, 1.0, 0.001, "full speed again")


func test_moving_the_cursor_to_another_source_retargets_while_holding() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var a := w.anchor(Vector2(0, -1), 300.0)
	var b := w.anchor(Vector2(120, -60), 300.0)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = a.global_position
	await physics_frames(2)
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	await physics_frames(3)
	assert_eq(w.vin.allomancy.locked, a)
	w.vin.controls.aim_point = b.global_position
	w.vin.controls.aim_moved = true
	await physics_frames(2)
	assert_eq(w.vin.allomancy.locked, b, "retargeted without releasing")


func test_camera_drift_alone_does_not_retarget() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var a := w.anchor(Vector2(0, -1), 300.0)
	var b := w.anchor(Vector2(120, -60), 300.0)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = a.global_position
	await physics_frames(2)
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	await physics_frames(2)
	w.vin.controls.aim_point = b.global_position
	await physics_frames(2)
	assert_eq(w.vin.allomancy.locked, a, "no deliberate mouse motion")


func test_mouse_wheel_cycles_candidates_near_the_cursor() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var a := w.anchor(Vector2(100, -100), 5.0)
	var b := w.anchor(Vector2(120, -100), 5.0)
	var c := w.anchor(Vector2(140, -100), 5.0)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = Vector2(100, -100)
	await physics_frames(2)
	assert_eq(w.vin.allomancy.target, a)
	w.vin.controls.target_cycle = 1
	await physics_frames(1)
	assert_eq(w.vin.allomancy.target, b, "next")
	await physics_frames(2)
	assert_eq(w.vin.allomancy.target, b, "cycled pick sticks while the cursor is still")
	w.vin.controls.target_cycle = 1
	await physics_frames(1)
	assert_eq(w.vin.allomancy.target, c)
	w.vin.controls.target_cycle = 1
	await physics_frames(1)
	assert_eq(w.vin.allomancy.target, a, "wraps")
	assert_eq(w.vin.allomancy.cycle_candidates.size(), 3, "candidates shown for discovery")


func test_corner_correction_nudges_vin_past_a_ceiling_edge() -> void:
	# The ceiling's right edge overlaps Vin's left side by 3 pixels.
	var w := TestWorld.create(self, [FLOOR, Rect2(-100, -80, 97, 10)], Vector2(0, -1))
	await physics_frames(2)
	w.vin.controls.jump_pressed = true
	w.vin.controls.jump_held = true
	await physics_frames(20)
	assert_lt(w.vin.global_position.y - Vin.STAND_HEIGHT, -80.0, "head rose past the ceiling")
	assert_gt(w.vin.global_position.x, 2.0, "nudged right")


func test_corner_correction_lifts_vin_over_a_clipped_ledge() -> void:
	# Vin flies at the wall with her feet three pixels below its top.
	var w := TestWorld.create(self, [FLOOR, Rect2(40, -60, 200, 60)], Vector2(28, -57))
	w.vin.velocity = Vector2(240, 0)
	w.vin.controls.move.x = 1.0
	await physics_frames(6)
	assert_gt(w.vin.global_position.x, 40.0, "carried over the lip")
	assert_lt(w.vin.global_position.y, -59.0, "on top")
