extends TestCase

const FLOOR := Rect2(-800, 0, 1600, 32)


func _guard(w: TestWorld, at: Vector2, armoured := true) -> Guard:
	var g := Guard.new()
	g.position = at
	g.armoured = armoured
	w.add_child(g)
	return g


func test_guard_patrols_back_and_forth() -> void:
	var w := TestWorld.create(self, [FLOOR])
	var g := _guard(w, Vector2(0, -1))
	g.patrol_distance = 40.0
	await physics_frames(2)
	var xs := []
	for i in 240:
		await physics_frames(1)
		xs.append(g.global_position.x)
	assert_gt(xs.max(), 30.0, "walked right")
	assert_lt(xs.min(), -30.0, "walked left")


func test_guard_notices_on_contact_and_attacks() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(10, -1))
	var g := _guard(w, Vector2(0, -1))
	g.patrol_distance = 0.0
	await physics_frames(90)
	assert_true(g.aware, "noticed")
	assert_lt(w.vin.health.current, 100.0, "struck Vin")


func test_backstab_kills_an_unaware_guard_and_a_frontal_stab_does_not() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-30, -1))
	var g := _guard(w, Vector2(0, -1))
	g.patrol_distance = 0.0
	g.facing = 1
	await physics_frames(2)
	w.vin.facing = 1
	w.vin.controls.dagger_pressed = true
	await physics_frames(2)
	assert_true(g.dead(), "backstab kills")
	var g2 := _guard(w, Vector2(200, -1))
	g2.patrol_distance = 0.0
	g2.facing = -1
	w.vin.global_position = Vector2(180, -1)
	await physics_frames(10)
	w.vin.facing = 1
	w.vin.controls.dagger_pressed = true
	await physics_frames(2)
	assert_false(g2.dead(), "a single frontal stab does not kill")


func test_coins_kill_unarmoured_in_one_and_armoured_in_two() -> void:
	var w := TestWorld.create(self, [FLOOR])
	var bare := _guard(w, Vector2(0, -1), false)
	var plated := _guard(w, Vector2(200, -1), true)
	await physics_frames(2)
	bare.take_hit(Hit.make(Hit.Kind.COIN, 100.0, Vector2.RIGHT, null))
	plated.take_hit(Hit.make(Hit.Kind.COIN, 100.0, Vector2.RIGHT, null))
	assert_true(bare.dead(), "one coin")
	assert_false(plated.dead(), "armour holds one")
	plated.take_hit(Hit.make(Hit.Kind.COIN, 100.0, Vector2.RIGHT, null))
	assert_true(plated.dead(), "two coins")


func test_dagger_combo_kills_a_guard() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-20, -1))
	var g := _guard(w, Vector2(0, -1))
	g.patrol_distance = 0.0
	g.facing = -1
	w.vin.toggle_pewter_now(true)
	await physics_frames(2)
	w.vin.facing = 1
	for i in 3:
		w.vin.controls.dagger_pressed = true
		w.vin.controls.dagger_released = true
		await physics_frames(int(Game.tuning.dagger_swing_time * 60) + 2)
	assert_true(g.dead(), "three hits")


func test_guard_dies_from_a_fall() -> void:
	var w := TestWorld.create(self, [Rect2(-100, -200, 200, 32), FLOOR])
	var g := _guard(w, Vector2(0, -201))
	g.patrol_distance = 0.0
	await physics_frames(2)
	g.global_position = Vector2(150, -201)
	await physics_frames(90)
	assert_true(g.dead(), "fell to his death")


func test_pushing_the_breastplate_shoves_the_guard_by_body_mass() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-60, -1))
	var g := _guard(w, Vector2(0, -1))
	g.patrol_distance = 0.0
	await physics_frames(2)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = g.breastplate.global_position
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	await physics_frames(6)
	w.vin.controls.push_held = false
	await physics_frames(1)
	assert_gt(g.velocity.x, 30.0, "guard shoved back")
	assert_lt(w.vin.velocity.x, -30.0, "Vin slides back")
	assert_gt(g.velocity.x, -w.vin.velocity.x, "Vin braces on the ground and slides only a little")


func test_pulling_the_spear_disarms_on_a_failed_grip_check() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-120, -1))
	var g := _guard(w, Vector2(0, -1))
	g.patrol_distance = 0.0
	await physics_frames(2)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = g.spear.global_position
	w.vin.controls.pull_pressed = true
	w.vin.controls.pull_held = true
	await physics_frames(40)
	assert_false(g.has_spear, "disarmed")
	assert_eq(tree.get_nodes_in_group("dropped_weapons").size(), 1, "the spear flew loose")


func test_dodge_roll_has_invulnerability_frames() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	w.vin.controls.dodge_pressed = true
	await physics_frames(3)
	assert_eq(w.vin.state, Vin.State.DODGE)
	assert_false(w.vin.take_hit(Hit.make(Hit.Kind.SPEAR, 34.0, Vector2.LEFT, null)), "invulnerable")
	await physics_frames(40)
	assert_true(w.vin.take_hit(Hit.make(Hit.Kind.SPEAR, 34.0, Vector2.LEFT, null)), "vulnerable again")


func test_heavy_attack_needs_pewter_and_breaks_through() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-20, -1))
	var g := _guard(w, Vector2(0, -1))
	g.patrol_distance = 0.0
	g.facing = -1
	g.aware = true
	await physics_frames(2)
	w.vin.facing = 1
	w.vin.toggle_pewter_now(true)
	w.vin.controls.dagger_pressed = true
	w.vin.controls.dagger_held = true
	await physics_frames(int(Game.tuning.heavy_hold_time * 60) + 4)
	w.vin.controls.dagger_held = false
	w.vin.controls.dagger_released = true
	await physics_frames(2)
	assert_eq(g.last_hit_kind, Hit.Kind.HEAVY, "heavy landed")


func test_dash_stab_and_plunge() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-120, -1))
	var g := _guard(w, Vector2(0, -1))
	g.patrol_distance = 0.0
	g.facing = -1
	g.aware = true
	await physics_frames(2)
	w.vin.controls.move.x = 1.0
	await physics_frames(25)
	w.vin.controls.dagger_pressed = true
	await physics_frames(20)
	assert_eq(g.last_hit_kind, Hit.Kind.DASH, "dash stab")
	var g2 := _guard(w, Vector2(400, -1))
	g2.patrol_distance = 0.0
	g2.aware = true
	w.vin.controls.move.x = 0.0
	w.vin.global_position = Vector2(400, -150)
	w.vin.reset_physics_interpolation()
	await physics_frames(1)
	w.vin.controls.move.y = 1.0
	w.vin.controls.dagger_pressed = true
	await physics_frames(40)
	assert_true(g2.dead(), "plunge kills")


func test_death_returns_vin_to_the_checkpoint_restored() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	Checkpoints.reach(w.vin, Vector2(-200, -1))
	w.vin.pouch.count = 2
	w.vin.reserves.set_amount(MetalReserves.Metal.PEWTER, 5.0)
	w.vin.take_hit(Hit.make(Hit.Kind.AXE, 500.0, Vector2.RIGHT, null, false))
	await physics_frames(int(Game.tuning.death_respawn_delay * 60) + 5)
	assert_lt(w.vin.global_position.distance_to(Vector2(-200, -1)), 2.0, "at the checkpoint")
	assert_near(w.vin.health.current, 100.0, 0.001)
	assert_eq(w.vin.pouch.count, Game.tuning.coin_pouch_size)
	assert_near(w.vin.reserves.amount(MetalReserves.Metal.PEWTER), MetalReserves.FULL, 0.001)
