extends TestCase

const FLOOR := Rect2(-800, 0, 2400, 32)


func test_arena_doors_seal_until_its_enemies_are_dead() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-100, -1))
	var arena := ArenaLock.new()
	arena.position = Vector2(0, 0)
	arena.size = Vector2(300, 120)
	w.add_child(arena)
	var g := Guard.new()
	g.position = Vector2(150, -1)
	g.patrol_distance = 0.0
	arena.add_child(g)
	await physics_frames(2)
	assert_false(arena.sealed)
	w.vin.global_position = Vector2(40, -1)
	await physics_frames(3)
	assert_true(arena.sealed, "sealed when she walks in")
	w.vin.global_position = Vector2(20, -1)
	w.vin.controls.move.x = -1.0
	await physics_frames(30)
	assert_gt(w.vin.global_position.x, -2.0, "cannot leave")
	g.die()
	await physics_frames(3)
	assert_false(arena.sealed, "opens when the fight is won")


func test_soothing_presses_on_vin_unless_copper_is_on() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var field := SoothingField.new()
	field.position = Vector2(-200, -100)
	field.size = Vector2(800, 120)
	w.add_child(field)
	await physics_frames(3)
	assert_true(w.vin.soothed, "the weight of the Soothing")
	w.vin.controls.move.x = 1.0
	await physics_frames(40)
	assert_lt(w.vin.velocity.x, Game.tuning.run_speed * 0.95, "slowed")
	w.vin.copper_on = true
	await physics_frames(3)
	assert_false(w.vin.soothed, "copper shields her emotions")


func test_wounded_vin_has_pinned_health_and_locked_draining_pewter() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	w.vin.wound(10.0)
	await physics_frames(2)
	assert_near(w.vin.health.current, 10.0, 0.001, "a sliver")
	assert_true(w.vin.pewter_on, "pewter forced on")
	w.vin.controls.toggle_pewter = true
	await physics_frames(2)
	assert_true(w.vin.pewter_on, "and cannot be turned off")
	var before := w.vin.reserves.amount(MetalReserves.Metal.PEWTER)
	await physics_frames(120)
	assert_lt(w.vin.reserves.amount(MetalReserves.Metal.PEWTER), before, "draining")
	assert_near(w.vin.health.current, 10.0, 0.001, "no regeneration")


func test_running_out_of_pewter_while_wounded_is_death() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var deaths := [0]
	await physics_frames(2)
	w.vin.died.connect(func(): deaths[0] += 1)
	w.vin.wound(10.0)
	w.vin.reserves.set_amount(MetalReserves.Metal.PEWTER, 0.05)
	await physics_frames(30)
	assert_eq(deaths[0], 1, "she collapses")


func test_logbook_pickup_signals() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var book := Logbook.new()
	book.position = Vector2(30, -10)
	w.add_child(book)
	var got := [false]
	book.taken.connect(func(): got[0] = true)
	await physics_frames(2)
	w.vin.controls.move.x = 1.0
	await physics_frames(30)
	assert_true(got[0], "taken")


func test_bendal_can_hold_his_ground() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-300, -1))
	var b := Bendal.new()
	b.hold_ground = true
	b.position = Vector2(100, -1)
	w.add_child(b)
	await physics_frames(2)
	b.start()
	await physics_frames(60)
	assert_near(b.global_position.x, 100.0, 0.5, "stays at his post")
