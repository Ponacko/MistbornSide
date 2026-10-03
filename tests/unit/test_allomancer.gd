extends TestCase

const FLOOR := Rect2(-800, 0, 1600, 32)


func test_target_follows_the_cursor() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var a := w.anchor(Vector2(100, -120))
	var b := w.anchor(Vector2(-150, -80))
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = Vector2(95, -110)
	await physics_frames(2)
	assert_eq(w.vin.allomancy.target, a, "near a")
	w.vin.controls.aim_point = Vector2(-140, -90)
	await physics_frames(1)
	assert_eq(w.vin.allomancy.target, b, "near b")


func test_idle_cursor_still_highlights_one_source() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	w.anchor(Vector2(100, -120))
	w.anchor(Vector2(-150, -80))
	w.vin.controls.aim_active = false
	await physics_frames(3)
	assert_true(w.vin.allomancy.target != null, "a fallback target")


func test_lines_drawn_for_sources_in_range_only_and_dimmer_through_walls() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(60, -200, 16, 190)], Vector2(0, -1))
	var clear := w.anchor(Vector2(-100, -30))
	var walled := w.anchor(Vector2(110, -30))
	w.anchor(Vector2(2000, -30))
	await physics_frames(2)
	var by_source := {}
	for l in w.vin.allomancy.lines:
		by_source[l.source] = l
	assert_eq(by_source.size(), 2, "only sources in range")
	assert_false(by_source[clear].through_wall)
	assert_true(by_source[walled].through_wall)
	assert_lt(by_source[walled].alpha, by_source[clear].alpha, "walled line dimmer")


func test_inside_body_metal_is_never_targeted() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var spike := w.anchor(Vector2(60, -40))
	spike.inside_body = true
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = Vector2(60, -40)
	await physics_frames(2)
	assert_eq(w.vin.allomancy.target, null)


func test_lines_layer_sits_above_the_mists_and_below_the_hud() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var layer: CanvasLayer = w.vin.get_node("LinesLayer")
	assert_gt(layer.layer, CanvasLayers.MIST)
	assert_lt(layer.layer, CanvasLayers.HUD)


func test_sixty_sources_update_within_budget() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	for i in 60:
		w.anchor(Vector2(-300 + (i % 12) * 50, -40 - (i / 12) * 50), 0.5 + i)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = Vector2(20, -100)
	await physics_frames(2)
	var start := Time.get_ticks_usec()
	for i in 60:
		w.vin.allomancy.physics_update(1.0 / 60.0)
	var per_frame_ms := (Time.get_ticks_usec() - start) / 60.0 / 1000.0
	assert_eq(w.vin.allomancy.lines.size(), 60)
	assert_lt(per_frame_ms, 1.5, "ms per update")
