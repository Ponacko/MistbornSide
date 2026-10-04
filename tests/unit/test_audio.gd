extends TestCase

const FLOOR := Rect2(-800, 0, 1600, 32)


func test_loops_are_seamless() -> void:
	for path in ["res://audio/ambience/night.wav", "res://audio/ambience/hum.wav", "res://audio/ambience/heartbeat.wav", "res://audio/music/night_city.wav", "res://audio/music/kredik_shaw.wav"]:
		var s := Audio.looped(path)
		assert_eq(s.loop_mode, AudioStreamWAV.LOOP_FORWARD, path)
		var data := s.data
		var n := data.size() / 2
		assert_eq(s.loop_end, n, "%s loops over its whole length" % path)
		var first := data.decode_s16(0)
		var last := data.decode_s16(data.size() - 2)
		assert_lt(absf(first - last), 2500.0, "%s has no click at the seam" % path)


func test_hum_follows_the_blue_lines_and_rises_with_flare() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(30)
	assert_lt(Audio.hum_volume(), -60.0, "silent with no metal near")
	var a := w.anchor(Vector2(0, -1), 300.0)
	await physics_frames(60)
	assert_gt(Audio.hum_volume(), -30.0, "humming with lines visible")
	var calm := Audio.hum_pitch()
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = a.global_position
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	w.vin.controls.flare_held = true
	await physics_frames(20)
	assert_gt(Audio.hum_pitch(), calm + 0.1, "rises with flare")


func test_pluck_on_lock_and_thump_on_launch() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	Audio.history.clear()
	var a := w.anchor(Vector2(0, -1), 300.0)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = a.global_position
	await physics_frames(3)
	assert_true(Audio.history.has("pluck"), "target lock plucks")
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	await physics_frames(3)
	assert_true(Audio.history.has("thump"), "launch thumps")


func test_coin_rings_on_landing() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-300, -1))
	Audio.history.clear()
	var c := Coin.new()
	c.position = Vector2(0, -120)
	w.add_child(c)
	await physics_frames(40)
	assert_true(Audio.history.has("coin_ring"), "rang")


func test_heartbeat_under_pewter_and_atium_thins_the_mix() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(20)
	assert_lt(Audio.heartbeat_volume(), -60.0)
	w.vin.toggle_pewter_now(true)
	await physics_frames(60)
	assert_gt(Audio.heartbeat_volume(), -20.0, "heartbeat")
	assert_false(Audio.atium_mix(), "normal mix")
	w.vin.atium_beads = 1
	for i in 30:
		w.vin.controls.atium_held = true
		await physics_frames(1)
	await physics_frames(2)
	assert_true(Audio.atium_mix(), "thin, reverberant mix under atium")


func test_steelsight_lowers_pitch_and_restores_it() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -200))
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = Vector2(400, -600)
	await physics_frames(2)
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	await physics_frames(Game.tuning.push_buffer_frames + 3)
	assert_lt(AudioServer.playback_speed_scale, 0.5, "pitch drops with time")
	w.vin.controls.push_held = false
	await physics_frames(40)
	assert_near(AudioServer.playback_speed_scale, 1.0, 0.01, "and comes back")


func test_tin_raises_ambience_and_brings_footsteps_through_walls() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(30)
	var quiet := Audio.ambience_volume()
	Audio.history.clear()
	NoiseBus.emit(Vector2(200, -10), 0.6, NoiseBus.Kind.FOOTSTEP)
	assert_false(Audio.history.has("footstep"), "unheard without tin")
	w.vin.toggle_tin_now(true)
	await physics_frames(60)
	assert_gt(Audio.ambience_volume(), quiet + 3.0, "ambience up")
	NoiseBus.emit(Vector2(200, -10), 0.6, NoiseBus.Kind.FOOTSTEP)
	NoiseBus.emit(Vector2(200, -10), 0.6, NoiseBus.Kind.VOICE)
	assert_true(Audio.history.has("footstep") and Audio.history.has("murmur"), "footsteps and voices")


func test_music_plays_per_area() -> void:
	var m4: Node = (load("res://levels/missions/m04_eight_metals/m04_eight_metals.tscn") as PackedScene).instantiate()
	add(m4)
	await physics_frames(2)
	assert_eq(Audio.current_track, "night_city")
	m4.free()
	var m9: Node = (load("res://levels/missions/m09_kredik_shaw/m09_kredik_shaw.tscn") as PackedScene).instantiate()
	add(m9)
	await physics_frames(2)
	assert_eq(Audio.current_track, "kredik_shaw")
