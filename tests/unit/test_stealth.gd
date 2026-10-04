extends TestCase

const FLOOR := Rect2(-800, 0, 1600, 32)
const DT := 1.0 / 60.0


func test_suspicion_rises_through_three_stages_and_decays() -> void:
	var s := Suspicion.new()
	var t := Tuning.new()
	assert_eq(s.stage, Suspicion.Stage.IDLE)
	for i in 30:
		s.update(DT, 1.0, t)
	assert_eq(s.stage, Suspicion.Stage.SUSPICIOUS, "half a second in plain sight")
	for i in 60:
		s.update(DT, 1.0, t)
	assert_eq(s.stage, Suspicion.Stage.ALERTED, "seen for long enough")
	for i in int(t.alert_memory * 60) + 600:
		s.update(DT, 0.0, t)
	assert_eq(s.stage, Suspicion.Stage.IDLE, "forgets in time")


func test_noise_raises_suspicion() -> void:
	var s := Suspicion.new()
	s.hear(0.5, Vector2(10, 0))
	assert_eq(s.stage, Suspicion.Stage.SUSPICIOUS)
	assert_eq(s.last_stimulus, Vector2(10, 0))


func _guard(w: TestWorld, at: Vector2, facing := -1, lantern := false) -> Guard:
	var g := Guard.new()
	g.position = at
	g.patrol_distance = 0.0
	g.facing = facing
	g.carries_lantern = lantern
	w.add_child(g)
	return g


func _lantern(w: TestWorld, at: Vector2) -> Lantern:
	var l := Lantern.new()
	l.position = at
	l.metal = false
	w.add_child(l)
	return l


func test_guard_sees_vin_in_lantern_light_but_not_in_shadow() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-150, -1))
	var g := _guard(w, Vector2(0, -1))
	await physics_frames(60)
	assert_eq(g.suspicion.stage, Suspicion.Stage.IDLE, "hidden in shadow")
	_lantern(w, Vector2(-150, -40))
	await physics_frames(90)
	assert_eq(g.suspicion.stage, Suspicion.Stage.ALERTED, "seen in the light")


func test_guards_do_not_look_up_at_rooftops() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(-100, -150, 200, 16)], Vector2(-20, -151))
	var g := _guard(w, Vector2(60, -1))
	_lantern(w, Vector2(-20, -190))
	await physics_frames(120)
	assert_eq(g.suspicion.stage, Suspicion.Stage.IDLE, "rooftop advantage")


func test_noise_rings_alert_nearby_guards_and_tin_shows_them() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-100, -300))
	var g := _guard(w, Vector2(40, -1))
	var far := _guard(w, Vector2(700, -1))
	await physics_frames(2)
	w.vin.toggle_tin_now(true)
	await physics_frames(60)
	assert_gt(g.suspicion.level, 0.2, "the hard landing was heard")
	assert_eq(far.suspicion.stage, Suspicion.Stage.IDLE, "too far to hear")
	assert_gt(w.vin.senses.visible_rings().size(), 0, "tin shows the ring")


func _obligator(w: TestWorld, at: Vector2) -> Obligator:
	var o := Obligator.new()
	o.position = at
	o.patrol_distance = 0.0
	w.add_child(o)
	return o


func test_seeker_detects_burning_through_walls_unless_copper_is_on() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(-40, -120, 16, 120)], Vector2(-120, -1))
	var o := _obligator(w, Vector2(60, -1))
	await physics_frames(2)
	w.vin.toggle_pewter_now(true)
	w.vin.copper_on = true
	await physics_frames(120)
	assert_eq(o.suspicion.stage, Suspicion.Stage.IDLE, "copper hides the burning")
	w.vin.copper_on = false
	await physics_frames(120)
	assert_gt(o.suspicion.stage, Suspicion.Stage.IDLE, "detected through the wall")


func test_bronze_shows_allomancers_through_walls_labelled_after_listening() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(-40, -120, 16, 120)], Vector2(-120, -1))
	_obligator(w, Vector2(120, -1))
	await physics_frames(2)
	assert_eq(w.vin.senses.bronze_beacons().size(), 0, "nothing without bronze")
	w.vin.bronze_on = true
	await physics_frames(5)
	var beacons := w.vin.senses.bronze_beacons()
	assert_eq(beacons.size(), 1, "a beacon through the wall")
	assert_false(beacons[0].labelled, "not yet identified")
	await physics_frames(int(Game.tuning.bronze_listen_time * 60) + 5)
	beacons = w.vin.senses.bronze_beacons()
	assert_true(beacons[0].labelled, "identified")
	assert_eq(beacons[0].label, "Seeker")


func test_lantern_bearer_blinds_only_a_tin_burner() -> void:
	for tin in [false, true]:
		var w := TestWorld.create(self, [FLOOR], Vector2(-40, -1))
		var g := _guard(w, Vector2(0, -1), -1, true)
		await physics_frames(2)
		w.vin.toggle_tin_now(tin)
		g.suspicion.alert()
		var stunned := false
		for i in 120:
			await physics_frames(1)
			stunned = stunned or w.vin.stunned()
		assert_eq(stunned, tin, "blinded only with tin (tin=%s)" % tin)
		free_nodes()
		await physics_frames(1)


func test_alarm_bell_summons_reinforcements() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-300, -1))
	var bell := AlarmBell.new()
	bell.position = Vector2(100, -80)
	bell.reinforcements = [Vector2(300, -1), Vector2(340, -1)]
	w.add_child(bell)
	var g := _guard(w, Vector2(60, -1))
	await physics_frames(2)
	g.suspicion.alert()
	await physics_frames(int(Game.tuning.bell_delay * 60) + 10)
	assert_true(bell.rung, "rung")
	var guards := tree.get_nodes_in_group("enemies")
	assert_eq(guards.size(), 3, "two reinforcements")


func test_pushing_the_bell_silences_it() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var bell := AlarmBell.new()
	bell.position = Vector2(100, -80)
	bell.reinforcements = [Vector2(300, -1)]
	w.add_child(bell)
	var g := _guard(w, Vector2(400, -1))
	await physics_frames(2)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = bell.global_position
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	await physics_frames(3)
	w.vin.controls.push_held = false
	assert_true(bell.silenced, "silenced")
	g.suspicion.alert()
	await physics_frames(int(Game.tuning.bell_delay * 60) + 10)
	assert_false(bell.rung, "a silenced bell cannot ring")
