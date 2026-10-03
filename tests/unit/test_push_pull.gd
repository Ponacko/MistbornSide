extends TestCase

const FLOOR := Rect2(-800, 0, 1600, 32)


func _hold_push(w: TestWorld, target: MetalSource, flare := false) -> void:
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = target.global_position
	w.vin.controls.push_held = true
	w.vin.controls.push_pressed = true
	w.vin.controls.flare_held = flare


func test_push_off_an_anchor_below_launches_vin_to_the_reach_height() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var anchor := w.anchor(Vector2(0, -1), 0.01)
	await physics_frames(2)
	var start := w.vin.global_position.y
	_hold_push(w, anchor)
	await physics_frames(int(Game.tuning.push_reach_time * 60.0))
	var h := start - w.vin.global_position.y
	assert_near(h, Game.tuning.push_reach_tiles * Tuning.TILE, 10.0, "reach height")


func test_holding_push_over_an_anchor_settles_into_a_hover() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var anchor := w.anchor(Vector2(0, -1), 300.0)
	await physics_frames(2)
	_hold_push(w, anchor)
	await physics_frames(300)
	var y0 := w.vin.global_position.y
	await physics_frames(30)
	assert_lt(absf(w.vin.velocity.y), 8.0, "nearly still")
	assert_lt(absf(w.vin.global_position.y - y0), 4.0, "holding height")
	assert_lt(w.vin.global_position.y, -100.0, "in the air")


func test_releasing_stops_the_force_without_killing_momentum() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var anchor := w.anchor(Vector2(0, -1), 300.0)
	await physics_frames(2)
	_hold_push(w, anchor)
	await physics_frames(10)
	w.vin.controls.push_held = false
	await physics_frames(1)
	var v := w.vin.velocity.y
	assert_lt(v, -100.0, "still rising after release")
	assert_false(w.vin.allomancy.force_active, "no force after release")


func test_pull_brings_vin_to_a_bracket_across_a_gap() -> void:
	var w := TestWorld.create(self, [Rect2(-200, 0, 200, 32), Rect2(260, 0, 200, 32)], Vector2(-20, -1))
	var bracket := w.anchor(Vector2(240, -60), 6.0)
	await physics_frames(2)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = bracket.global_position
	w.vin.controls.pull_held = true
	w.vin.controls.pull_pressed = true
	await physics_frames(90)
	assert_lt(w.vin.chest_position().distance_to(bracket.global_position), 16.0, "at the bracket")
	assert_eq(w.vin.state, Vin.State.BRACKET_HANG, "clinging")


func test_dynamic_source_and_vin_move_by_mass_ratio() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var crate := RigidBody2D.new()
	crate.mass = 45.0
	crate.gravity_scale = 0.0
	crate.position = Vector2(80, -30)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	crate.add_child(shape)
	var s := MetalSource.new()
	s.kind = MetalSource.Kind.DYNAMIC
	s.mass = 45.0
	crate.add_child(s)
	w.add_child(crate)
	await physics_frames(2)
	_hold_push(w, s)
	await physics_frames(4)
	w.vin.controls.push_held = false
	await physics_frames(1)
	assert_gt(crate.linear_velocity.x, 20.0, "crate pushed away")
	assert_lt(w.vin.velocity.x, -20.0, "Vin pushed back")
	assert_near(crate.linear_velocity.x, -w.vin.velocity.x, crate.linear_velocity.x * 0.35, "about equal for equal masses")


func test_flare_pushes_harder_and_drains_faster() -> void:
	var heights := []
	var drains := []
	for flare in [false, true]:
		var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
		var anchor := w.anchor(Vector2(0, -1), 300.0)
		await physics_frames(2)
		var before := w.vin.reserves.amount(MetalReserves.Metal.STEEL)
		_hold_push(w, anchor, flare)
		await physics_frames(20)
		heights.append(-w.vin.global_position.y)
		drains.append(before - w.vin.reserves.amount(MetalReserves.Metal.STEEL))
		free_nodes()
		await physics_frames(1)
	assert_gt(heights[1], heights[0] * 1.2, "flare higher")
	assert_near(drains[1], drains[0] * 4.0, drains[0] * 0.3, "flare drains 4x")


func test_empty_steel_disables_push_without_a_fail_state() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var anchor := w.anchor(Vector2(0, -1), 300.0)
	await physics_frames(2)
	w.vin.reserves.set_amount(MetalReserves.Metal.STEEL, 0.0)
	w.vin.reserves.set_amount(MetalReserves.Metal.IRON, 0.0)
	_hold_push(w, anchor)
	await physics_frames(20)
	assert_near(w.vin.global_position.y, -0.0, 2.0, "did not move")
	assert_true(w.vin.allomancy.lines.is_empty(), "no lines without steel or iron")
	w.vin.controls.push_held = false
	w.vin.controls.move.x = 1.0
	await physics_frames(10)
	assert_gt(w.vin.velocity.x, 50.0, "can still run")


func test_vial_pickup_refills_reserves() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	w.vin.reserves.set_amount(MetalReserves.Metal.STEEL, 5.0)
	var vial := VialPickup.new()
	vial.position = Vector2(30, -10)
	w.add_child(vial)
	await physics_frames(2)
	w.vin.controls.move.x = 1.0
	await physics_frames(30)
	assert_near(w.vin.reserves.amount(MetalReserves.Metal.STEEL), MetalReserves.FULL, 0.5, "refilled")
	assert_false(is_instance_valid(vial) and vial.is_inside_tree(), "vial consumed")


func test_hover_off_centre_stays_over_the_anchor() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(4, -1))
	var anchor := w.anchor(Vector2(0, -1), 300.0)
	await physics_frames(2)
	_hold_push(w, anchor)
	await physics_frames(300)
	assert_lt(absf(w.vin.global_position.x), 40.0, "not flung sideways")
	assert_lt(absf(w.vin.velocity.x), 10.0, "settled")
