extends TestCase

const FLOOR := Rect2(-1600, 0, 4000, 32)


func _hold_tab(w: TestWorld, frames: int) -> void:
	for i in frames:
		w.vin.controls.atium_held = true
		await physics_frames(1)
	w.vin.controls.atium_held = false
	await physics_frames(1)


func test_a_held_tab_burns_a_bead_and_a_tap_does_not() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	w.vin.atium_beads = 2
	await physics_frames(2)
	await _hold_tab(w, 5)
	assert_false(w.vin.atium.burning, "a tap is not enough")
	assert_eq(w.vin.atium_beads, 2)
	await _hold_tab(w, int(Game.tuning.atium_confirm_time * 60) + 3)
	assert_true(w.vin.atium.burning, "burning")
	assert_eq(w.vin.atium_beads, 1, "a bead spent")


func test_a_bead_lasts_the_tuned_duration_and_changes_the_rules_only_while_burning() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	w.vin.atium_beads = 1
	await physics_frames(2)
	await _hold_tab(w, int(Game.tuning.atium_confirm_time * 60) + 3)
	assert_near(Engine.time_scale, Game.tuning.atium_time_scale, 0.001, "time slows a little")
	assert_gt(w.vin.dodge_window_scale, 1.5, "generous dodge")
	assert_true(w.vin.counter_aim, "counters auto-aim")
	var game_seconds := Game.tuning.atium_duration * Game.tuning.atium_time_scale
	await physics_frames(int(game_seconds * 60 / Game.tuning.atium_time_scale * 0.9))
	assert_true(w.vin.atium.burning, "still burning near the end")
	await physics_frames(int(game_seconds * 60 * 0.3) + 30)
	assert_false(w.vin.atium.burning, "burnt out")
	assert_near(Engine.time_scale, 1.0, 0.001)
	assert_near(w.vin.dodge_window_scale, 1.0, 0.001)
	assert_false(w.vin.counter_aim)


func test_pressing_again_stops_and_loses_the_remainder() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	w.vin.atium_beads = 1
	await physics_frames(2)
	await _hold_tab(w, int(Game.tuning.atium_confirm_time * 60) + 3)
	await physics_frames(30)
	await _hold_tab(w, 2)
	assert_false(w.vin.atium.burning, "stopped")
	assert_eq(w.vin.atium_beads, 0, "the remainder is gone")


func test_bead_pickup_adds_to_the_hud_count() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var bead := AtiumBead.new()
	bead.position = Vector2(30, -12)
	w.add_child(bead)
	await physics_frames(2)
	w.vin.controls.move.x = 1.0
	await physics_frames(30)
	assert_eq(w.vin.atium_beads, 1, "picked up")


func test_enemies_cast_shadows_ahead_and_projectiles_draw_paths() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-300, -1))
	var g := Guard.new()
	g.position = Vector2(0, -1)
	g.patrol_distance = 200.0
	w.add_child(g)
	w.vin.atium_beads = 1
	await physics_frames(20)
	assert_eq(w.vin.atium.shadows().size(), 0, "nothing without atium")
	await _hold_tab(w, int(Game.tuning.atium_confirm_time * 60) + 3)
	var shadows := w.vin.atium.shadows()
	assert_eq(shadows.size(), 1, "one shadow per enemy")
	var ahead: Vector2 = shadows[0].pos
	assert_near(ahead.x, g.global_position.x + g.velocity.x * Game.tuning.atium_lookahead, 6.0, "about 1.2 s ahead")
	var c := Coin.new()
	c.thrower = g
	c.position = Vector2(-100, -30)
	w.add_child(c)
	c.linear_velocity = Vector2(-600, 0)
	await physics_frames(1)
	assert_eq(w.vin.atium.projectile_paths().size(), 1, "the coin's path is drawn")


func test_atium_reveals_the_gap_in_bendals_attack() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(40, -1))
	w.vin.atium_beads = 1
	w.vin.toggle_pewter_now(true)
	var b := Bendal.new()
	var route := PackedVector2Array()
	for x in range(0, 600, 40):
		route.append(Vector2(x, -1))
	b.route = route
	w.add_child(b)
	await physics_frames(2)
	await _hold_tab(w, int(Game.tuning.atium_confirm_time * 60) + 3)
	b.start()
	var saw_strike := false
	var saw_safe := false
	for i in 120:
		await physics_frames(1)
		for s in w.vin.atium.shadows():
			if s.node == b:
				saw_strike = saw_strike or s.attacking
				saw_safe = saw_safe or (s.safe and b.phase == Bendal.Phase.ATTACKING)
	assert_true(saw_strike, "his coming strokes show")
	assert_true(saw_safe, "the recovery after them shows before it comes")
