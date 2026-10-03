extends TestCase

const FLOOR := Rect2(-800, 0, 1600, 32)
const DT := 1.0 / 60.0


func test_crash_when_pewter_runs_out_while_flared() -> void:
	var p := PewterBurn.new()
	var t := Tuning.new()
	assert_false(p.update(DT, true, true, true, t), "still burning")
	assert_true(p.update(DT, true, true, false, t), "ran out while flared: crash")


func test_no_crash_when_pewter_runs_out_unflared() -> void:
	var p := PewterBurn.new()
	var t := Tuning.new()
	assert_false(p.update(DT, true, false, false, t))


func test_crash_after_long_continuous_flare() -> void:
	var p := PewterBurn.new()
	var t := Tuning.new()
	var crashed := false
	var elapsed := 0.0
	while elapsed < t.crash_flare_seconds + 1.0 and not crashed:
		crashed = p.update(0.1, true, true, true, t)
		elapsed += 0.1
	assert_true(crashed, "crashed")
	assert_near(elapsed, t.crash_flare_seconds, 0.15, "at the flare limit")


func test_letting_go_of_flare_resets_the_flare_clock() -> void:
	var p := PewterBurn.new()
	var t := Tuning.new()
	for i in 300:
		p.update(0.1, true, true, true, t)
	p.update(0.1, true, false, true, t)
	for i in 300:
		assert_false(p.update(0.1, true, true, true, t))


func test_toggles_burn_continuously_at_their_own_rates() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	w.vin.controls.toggle_pewter = true
	w.vin.controls.toggle_tin = true
	await physics_frames(1)
	assert_true(w.vin.pewter_on and w.vin.tin_on, "both on")
	await physics_frames(120)
	var pewter_used := MetalReserves.FULL - w.vin.reserves.amount(MetalReserves.Metal.PEWTER)
	var tin_used := MetalReserves.FULL - w.vin.reserves.amount(MetalReserves.Metal.TIN)
	assert_gt(tin_used, 0.0, "tin drains")
	assert_gt(pewter_used, tin_used * 2.0, "pewter drains fastest")
	w.vin.controls.toggle_pewter = true
	await physics_frames(1)
	var after := w.vin.reserves.amount(MetalReserves.Metal.PEWTER)
	await physics_frames(30)
	assert_near(w.vin.reserves.amount(MetalReserves.Metal.PEWTER), after, 0.0001, "off: no drain")


func test_pewter_raises_run_speed_and_jump_height() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	w.vin.controls.toggle_pewter = true
	w.vin.controls.move.x = 1.0
	await physics_frames(40)
	assert_near(w.vin.velocity.x, Game.tuning.run_speed * Game.tuning.pewter_speed, 2.0, "run speed")
	w.vin.controls.move.x = 0.0
	await physics_frames(30)
	var start := w.vin.global_position.y
	w.vin.controls.jump_pressed = true
	w.vin.controls.jump_held = true
	var top := start
	for i in 60:
		await physics_frames(1)
		top = minf(top, w.vin.global_position.y)
	var expected := Game.tuning.jump_height_tiles * Tuning.TILE * Game.tuning.pewter_jump
	assert_gt(start - top, expected - 3.0, "jump height")
	assert_lt(start - top, expected + 10.0, "jump height")


func test_pewter_halves_hazard_damage_and_ignores_light_stagger() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	w.vin.take_hit(Hit.make(Hit.Kind.HAZARD, 20.0, Vector2.RIGHT, null, true))
	assert_near(w.vin.health.current, 80.0, 0.001, "full damage without pewter")
	assert_eq(w.vin.state, Vin.State.STAGGER, "staggered")
	await physics_frames(60)
	w.vin.controls.toggle_pewter = true
	await physics_frames(1)
	var before := w.vin.health.current
	w.vin.take_hit(Hit.make(Hit.Kind.HAZARD, 20.0, Vector2.RIGHT, null, true))
	assert_near(before - w.vin.health.current, 10.0, 0.001, "half damage with pewter")
	assert_ne_state(w.vin, Vin.State.STAGGER)


func assert_ne_state(v: Vin, s: Vin.State) -> void:
	assert_true(v.state != s, "should not be in state %d" % s)


func test_hazard_area_hurts_vin_on_contact() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var h := Hazard.new()
	h.position = Vector2(30, -10)
	w.add_child(h)
	await physics_frames(2)
	w.vin.controls.move.x = 1.0
	await physics_frames(20)
	assert_lt(w.vin.health.current, 100.0, "hurt")


func test_only_pewter_shoulders_through_a_weak_board() -> void:
	for pewter in [false, true]:
		var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
		var board := WeakBoard.new()
		board.position = Vector2(40, -48)
		w.add_child(board)
		await physics_frames(2)
		if pewter:
			w.vin.controls.toggle_pewter = true
		w.vin.controls.move.x = 1.0
		await physics_frames(60)
		if pewter:
			assert_gt(w.vin.global_position.x, 60.0, "broke through")
			assert_false(is_instance_valid(board), "board gone")
		else:
			assert_lt(w.vin.global_position.x, 40.0, "blocked")
			assert_false(board.broken, "board intact")
		free_nodes()
		await physics_frames(1)


func test_pewter_crash_staggers_then_slows() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	w.vin.reserves.set_amount(MetalReserves.Metal.PEWTER, 0.2)
	w.vin.controls.toggle_pewter = true
	w.vin.controls.flare_held = true
	await physics_frames(20)
	assert_true(w.vin.crash_time_left > 0.0, "crashed")
	assert_eq(w.vin.state, Vin.State.STAGGER)
	assert_false(w.vin.pewter_on, "pewter went out")
	w.vin.controls.flare_held = false
	await physics_frames(int(Game.tuning.crash_stagger * 60) + 10)
	assert_ne_state(w.vin, Vin.State.STAGGER)
	w.vin.controls.move.x = 1.0
	await physics_frames(40)
	assert_near(w.vin.velocity.x, Game.tuning.run_speed * Game.tuning.crash_slow_speed, 2.0, "slowed")


func test_tin_thins_the_mists_lifts_darkness_and_reveals_concealed_metal() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var hidden := w.anchor(Vector2(80, -40), 2.0)
	hidden.concealed = true
	await physics_frames(2)
	assert_false(_line_sources(w).has(hidden), "concealed without tin")
	w.vin.controls.toggle_tin = true
	await physics_frames(60)
	assert_gt(w.vin.senses.tin_amount, 0.95, "tin fully up")
	assert_true(_line_sources(w).has(hidden), "glints with tin")
	assert_gt(w.vin.senses.vision_radius(), Game.tuning.vision_radius * 2.9, "visible radius triples")


func test_noise_rings_show_through_walls_only_with_tin() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(60, -200, 16, 200)], Vector2(0, -1))
	await physics_frames(2)
	NoiseBus.emit(Vector2(150, -10), 1.0, NoiseBus.Kind.FOOTSTEP)
	assert_eq(w.vin.senses.visible_rings().size(), 0, "no rings without tin")
	w.vin.controls.toggle_tin = true
	await physics_frames(2)
	NoiseBus.emit(Vector2(150, -20), 1.0, NoiseBus.Kind.VOICE)
	var rings := w.vin.senses.visible_rings()
	assert_eq(rings.size(), 2, "every recent noise shows, through the wall")
	assert_eq(rings[-1].kind, NoiseBus.Kind.VOICE)


func test_lantern_flash_whites_out_and_stuns_only_with_tin() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	w.vin.senses.flash(Vector2(30, -30))
	assert_false(w.vin.stunned(), "no stun without tin")
	w.vin.controls.toggle_tin = true
	await physics_frames(2)
	w.vin.senses.flash(Vector2(30, -30))
	assert_true(w.vin.stunned(), "stunned")
	assert_gt(w.vin.senses.whiteout, 0.9, "whited out")
	w.vin.controls.move.x = 1.0
	await physics_frames(20)
	assert_lt(absf(w.vin.velocity.x), 1.0, "no control while stunned")
	await physics_frames(int(Game.tuning.tin_flash_stun * 60))
	assert_false(w.vin.stunned(), "recovers")


func test_flaring_tin_pulses_a_reveal_and_clears_a_daze() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	w.vin.controls.toggle_tin = true
	await physics_frames(2)
	w.vin.senses.flash(Vector2(30, -30))
	assert_true(w.vin.stunned())
	w.vin.controls.flare_pressed = true
	await physics_frames(1)
	assert_false(w.vin.stunned(), "daze cleared")
	assert_gt(w.vin.senses.pulse, 0.5, "reveal pulse")


func test_no_deferred_pewter_debt_damage() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	w.vin.controls.toggle_pewter = true
	w.vin.controls.flare_held = true
	await physics_frames(120)
	w.vin.controls.flare_held = false
	w.vin.controls.toggle_pewter = true
	await physics_frames(600)
	assert_near(w.vin.health.current, 100.0, 0.001, "no delayed damage")


func _line_sources(w: TestWorld) -> Array:
	return w.vin.allomancy.lines.map(func(l): return l.source)
