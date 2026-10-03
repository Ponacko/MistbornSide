extends TestCase


func test_gravity_and_launch_speed_reach_the_stated_height_at_the_stated_time() -> void:
	var g := JumpMath.gravity_for(52.0, 0.36)
	var v := JumpMath.launch_speed_for(52.0, 0.36)
	assert_near(v / g, 0.36, 0.0001, "time to apex")
	assert_near(v * v / (2.0 * g), 52.0, 0.001, "apex height")


func test_jump_buffer_accepts_a_press_shortly_before_landing() -> void:
	var f := JumpForgiveness.new(0.1, 0.1)
	f.tick(0.016, false)
	f.press()
	f.tick(0.05, false)
	assert_false(f.consume(), "still airborne")
	f.tick(0.016, true)
	assert_true(f.consume(), "buffered press fires on landing")


func test_jump_buffer_expires() -> void:
	var f := JumpForgiveness.new(0.1, 0.1)
	f.press()
	f.tick(0.2, false)
	f.tick(0.016, true)
	assert_false(f.consume())


func test_coyote_time_allows_jumping_just_after_leaving_the_ground() -> void:
	var f := JumpForgiveness.new(0.1, 0.1)
	f.tick(0.016, true)
	f.tick(0.06, false)
	f.press()
	assert_true(f.consume())


func test_coyote_time_expires_and_is_spent_by_a_jump() -> void:
	var f := JumpForgiveness.new(0.1, 0.1)
	f.tick(0.016, true)
	f.tick(0.2, false)
	f.press()
	assert_false(f.consume(), "too late")
	var g := JumpForgiveness.new(0.1, 0.1)
	g.tick(0.016, true)
	g.press()
	assert_true(g.consume())
	g.tick(0.016, false)
	g.press()
	assert_false(g.consume(), "no double jump from coyote")


func test_apex_gravity_reduced_only_near_apex_while_jump_held() -> void:
	var t := Tuning.new()
	var base := t.jump_gravity()
	assert_near(MovementMath.gravity(t, -5.0, true), base * t.apex_gravity_mult, 0.01, "apex held")
	assert_near(MovementMath.gravity(t, -5.0, false), base, 0.01, "apex released")
	assert_near(MovementMath.gravity(t, -200.0, true), base, 0.01, "rising fast")
	assert_near(MovementMath.gravity(t, 200.0, true), base * t.fall_gravity_mult, 0.01, "falling")


func test_horizontal_momentum_above_run_speed_is_kept_in_the_air() -> void:
	var t := Tuning.new()
	var vx := MovementMath.horizontal(t, 400.0, 1.0, false, 1.0 / 60.0)
	assert_gt(vx, 390.0, "air momentum persists when holding forward")
	var neutral := MovementMath.horizontal(t, 400.0, 0.0, false, 1.0 / 60.0)
	assert_gt(neutral, 390.0, "air momentum persists on neutral")
	var ground := MovementMath.horizontal(t, 400.0, 0.0, true, 1.0 / 60.0)
	assert_lt(ground, 400.0, "ground friction slows")
