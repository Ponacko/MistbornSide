extends TestCase

const FLOOR := Rect2(-800, 0, 1600, 32)


func test_anchor_cone_classifies_push_directions() -> void:
	var up := Vector2.UP
	assert_true(AnchorCone.classify(Vector2.DOWN, up, 35.0).anchored, "straight down")
	assert_true(AnchorCone.classify(Vector2.DOWN.rotated(deg_to_rad(30)), up, 35.0).anchored, "inside the cone")
	var skid := AnchorCone.classify(Vector2.DOWN.rotated(deg_to_rad(60)), up, 35.0)
	assert_false(skid.anchored, "outside the cone")
	assert_gt(skid.lift, 0.0, "partial lift")
	assert_lt(skid.lift, 1.0, "partial lift")
	assert_eq(AnchorCone.classify(Vector2.UP, up, 35.0).lift, 0.0, "pushing away from the surface gives no lift")


func test_flick_and_drop_spend_coins_from_a_finite_pouch() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	var start := w.vin.pouch.count
	assert_eq(start, Game.tuning.coin_pouch_size)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = Vector2(200, -100)
	w.vin.controls.coin_pressed = true
	await physics_frames(2)
	assert_eq(w.vin.pouch.count, start - 1, "flick")
	var flicked := _coins()[0] as Coin
	assert_gt(flicked.linear_velocity.x, 50.0, "flicked toward the cursor")
	w.vin.controls.move.y = 1.0
	w.vin.controls.coin_pressed = true
	await physics_frames(2)
	assert_eq(w.vin.pouch.count, start - 2, "drop")
	w.vin.pouch.count = 0
	w.vin.controls.coin_pressed = true
	await physics_frames(2)
	assert_eq(_coins().size(), 2, "empty pouch throws nothing")


func test_flick_with_no_aim_goes_straight_down() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -200))
	w.vin.controls.aim_active = false
	w.vin.controls.coin_pressed = true
	await physics_frames(2)
	var c := _coins()[0] as Coin
	assert_gt(c.linear_velocity.y, 50.0, "downward")
	assert_lt(absf(c.linear_velocity.x), 5.0, "not sideways")


func test_drop_and_push_launches_vin_to_the_tuned_height() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	w.vin.controls.move.y = 1.0
	w.vin.controls.coin_pressed = true
	await physics_frames(20)
	w.vin.controls.move.y = 0.0
	await physics_frames(10)
	var coin := _coins()[0] as Coin
	var start := w.vin.global_position.y
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = coin.global_position
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	await physics_frames(int(Game.tuning.push_reach_time * 60.0))
	assert_near(start - w.vin.global_position.y, Game.tuning.push_reach_tiles * Tuning.TILE, 14.0, "reach")
	assert_lt(coin.global_position.distance_to(Vector2(coin.global_position.x, -2)), 4.0, "coin stayed down")


func test_sideways_push_on_a_resting_coin_skids_it_and_barely_lifts_vin() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var coin := _spawn_coin(w, Vector2(40, -4))
	await physics_frames(40)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = coin.global_position
	w.vin.controls.push_held = true
	await physics_frames(10)
	assert_gt(coin.global_position.x, 50.0, "coin skidded away")
	assert_gt(w.vin.global_position.y, -30.0, "Vin barely lifted")


func test_push_coyote_time_keeps_a_coin_that_just_left_the_ground_anchored() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(300, -1))
	var coin := _spawn_coin(w, Vector2(0, -4))
	await physics_frames(40)
	assert_true(coin.is_anchored_for(Vector2.DOWN), "resting")
	coin.linear_velocity = Vector2(0, -150)
	await physics_frames(3)
	assert_true(coin.is_anchored_for(Vector2.DOWN), "still anchored a few frames after leaving")
	await physics_frames(12)
	assert_false(coin.is_anchored_for(Vector2.DOWN), "no longer anchored in the air")


func test_pushed_airborne_coin_kills_a_target_dummy() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var dummy := TargetDummy.new()
	dummy.position = Vector2(200, 0)
	w.add_child(dummy)
	await physics_frames(2)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = Vector2(200, -60)
	w.vin.controls.coin_pressed = true
	await physics_frames(3)
	var coin := _coins()[0] as Coin
	w.vin.controls.aim_point = coin.global_position
	w.vin.controls.push_held = true
	for i in 40:
		await physics_frames(1)
		w.vin.controls.aim_point = coin.global_position
	assert_true(dummy.dead, "dummy killed")


func test_spray_fires_a_fan_of_coins() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	var start := w.vin.pouch.count
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = Vector2(300, -30)
	w.vin.controls.push_held = true
	w.vin.controls.coin_pressed = true
	await physics_frames(2)
	var coins := _coins()
	assert_eq(coins.size(), Game.tuning.coin_spray_count)
	assert_eq(w.vin.pouch.count, start - Game.tuning.coin_spray_count)
	var angles := coins.map(func(c): return (c as Coin).linear_velocity.angle())
	angles.sort()
	assert_gt(angles[-1] - angles[0], deg_to_rad(15.0), "fanned out")
	for c in coins:
		assert_gt((c as Coin).linear_velocity.length(), Game.tuning.coin_lethal_speed, "lethal speed")


func test_holding_pull_with_no_target_recalls_coins_and_catches_them_in_flight() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var a := _spawn_coin(w, Vector2(120, -4))
	var b := _spawn_coin(w, Vector2(-90, -4))
	var flying := _spawn_coin(w, Vector2(60, -120))
	flying.linear_velocity = Vector2(200, -50)
	w.vin.pouch.count = 10
	await physics_frames(2)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = Vector2(0, -300)
	w.vin.controls.pull_held = true
	w.vin.controls.pull_pressed = true
	await physics_frames(90)
	assert_eq(w.vin.pouch.count, 13, "three coins re-pouched")
	assert_false(is_instance_valid(a) or is_instance_valid(b) or is_instance_valid(flying), "coins gone from the world")


func test_coin_budget_merges_settled_coins_into_piles() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-700, -1))
	for i in 90:
		_spawn_coin(w, Vector2(-200 + (i % 30) * 14, -10 - (i / 30) * 10))
	await physics_frames(180)
	var coins := _coins()
	var total := 0
	for c in coins:
		total += (c as Coin).count
	assert_true(coins.size() <= Game.tuning.coin_max_active, "within budget: %d" % coins.size())
	assert_eq(total, 90, "no coins lost")


func _spawn_coin(w: TestWorld, at: Vector2) -> Coin:
	var c := Coin.new()
	c.position = at
	w.add_child(c)
	return c


func _coins() -> Array:
	return tree.get_nodes_in_group("coins")


func test_sixty_flying_coins_stay_within_the_frame_budget() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(-800, -400, 32, 400), Rect2(768, -400, 32, 400)], Vector2(-100, -1))
	for i in 60:
		var c := _spawn_coin(w, Vector2(-300 + i * 10, -100 - (i % 5) * 20))
		c.linear_velocity = Vector2.from_angle(i * 0.7) * 600.0
	await physics_frames(5)
	var worst := 0
	var total := 0
	for i in 120:
		var t0 := Time.get_ticks_usec()
		await physics_frames(1)
		var spent := Time.get_ticks_usec() - t0
		worst = maxi(worst, spent)
		total += spent
	# Whole headless frames, Vin's Allomancy over all sixty lines included.
	assert_lt(total / 120.0 / 1000.0, 6.0, "average frame ms")
	assert_lt(worst / 1000.0, 16.6, "worst frame ms")
