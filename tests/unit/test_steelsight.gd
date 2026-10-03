extends TestCase

const DT := 1.0 / 60.0


func _t() -> Tuning:
	return Tuning.new()


func test_press_with_a_target_fires_at_once_without_slowing_time() -> void:
	var s := Steelsight.new()
	var t := _t()
	s.update(DT, true, true, true, t)
	assert_true(s.firing(), "fires on the press frame")
	assert_near(s.time_scale(t), 1.0, 0.0001)


func test_press_without_a_target_waits_out_the_buffer_then_slows_time() -> void:
	var s := Steelsight.new()
	var t := _t()
	s.update(DT, true, true, false, t)
	assert_false(s.firing())
	assert_near(s.time_scale(t), 1.0, 0.0001, "buffering at full speed")
	for i in t.push_buffer_frames:
		s.update(DT, false, true, false, t)
	assert_eq(s.phase, Steelsight.Phase.AIMING)
	assert_near(s.time_scale(t), t.steelsight_time_scale, 0.0001, "slowed")


func test_a_target_arriving_within_the_buffer_fires_without_steelsight() -> void:
	var s := Steelsight.new()
	var t := _t()
	s.update(DT, true, true, false, t)
	s.update(DT, false, true, false, t)
	s.update(DT, false, true, true, t)
	assert_true(s.firing())
	assert_near(s.time_scale(t), 1.0, 0.0001)


func _open(s: Steelsight, t: Tuning) -> void:
	s.update(DT, true, true, false, t)
	for i in t.push_buffer_frames:
		s.update(DT, false, true, false, t)


func test_steelsight_commits_when_a_target_highlights_and_ramps_time_back() -> void:
	var s := Steelsight.new()
	var t := _t()
	_open(s, t)
	s.update(DT, false, true, true, t)
	assert_true(s.firing(), "committed")
	s.update(0.05, false, true, true, t)
	var mid := s.time_scale(t)
	assert_gt(mid, t.steelsight_time_scale, "ramping")
	assert_lt(mid, 1.0, "ramping")
	s.update(t.steelsight_ramp, false, true, true, t)
	assert_near(s.time_scale(t), 1.0, 0.0001, "back to full speed after the ramp")


func test_steelsight_window_expires_and_commits() -> void:
	var s := Steelsight.new()
	var t := _t()
	_open(s, t)
	s.update(t.steelsight_window + 0.01, false, true, false, t)
	assert_true(s.firing(), "commits on expiry")
	s.update(DT, false, true, false, t)
	assert_gt(s.time_scale(t), t.steelsight_time_scale)


func test_release_during_steelsight_commits_a_tap() -> void:
	var s := Steelsight.new()
	var t := _t()
	_open(s, t)
	s.update(DT, false, false, true, t)
	assert_true(s.firing(), "tap fires on release")
	s.update(t.steelsight_tap_time + 0.01, false, false, true, t)
	assert_false(s.firing(), "tap ends")
	assert_eq(s.phase, Steelsight.Phase.IDLE)


func test_time_controller_scales_time_and_audio_together() -> void:
	TimeController.set_factor(&"test", 0.5)
	assert_near(Engine.time_scale, 0.5, 0.0001)
	assert_near(AudioServer.playback_speed_scale, 0.5, 0.0001)
	TimeController.set_factor(&"other", 0.5)
	assert_near(Engine.time_scale, 0.25, 0.0001, "factors multiply")
	TimeController.push_override(1.0)
	assert_near(Engine.time_scale, 1.0, 0.0001, "boss override wins")
	TimeController.pop_override()
	TimeController.clear_factor(&"test")
	TimeController.clear_factor(&"other")
	assert_near(Engine.time_scale, 1.0, 0.0001)
	assert_near(TimeController.real_delta(0.5 / 60.0), 0.5 / 60.0, 0.0001)


func test_arc_prediction_rises_under_a_push_and_falls_without() -> void:
	var t := _t()
	var anchor_below := Vector2(0, 10)
	var pushed := ArcPredictor.predict(Vector2.ZERO, Vector2.ZERO, anchor_below, 1.0, 1.0, 1.0, t)
	assert_lt(pushed[-1].y, -40.0, "rises")
	var free := ArcPredictor.predict(Vector2.ZERO, Vector2(100, 0), Vector2.INF, 0.0, 1.0, 1.0, t)
	assert_gt(free[-1].y, 40.0, "falls")
	assert_gt(free[-1].x, 40.0, "keeps momentum")
	assert_eq(pushed.size(), int(t.arc_preview_time * 60.0))
