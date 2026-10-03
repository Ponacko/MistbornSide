extends TestCase


func _panel() -> TuningPanel:
	var p := TuningPanel.new()
	add(p)
	return p


func test_every_exported_tunable_gets_an_editor() -> void:
	var p := _panel()
	var names := TuningPanel.tunable_names()
	assert_gt(names.size(), 60, "the panel covers the whole Tuning resource")
	for n in names:
		assert_true(p.has_editor(n), "editor for %s" % n)
	for required in ["push_reach_tiles", "line_range", "steelsight_window", "coin_pouch_size", "pewter_speed", "vision_radius", "anchor_cone_degrees"]:
		assert_true(names.has(required), required)


func test_editing_a_value_changes_the_live_tuning() -> void:
	var p := _panel()
	p.set_value("push_reach_tiles", 9.0)
	assert_near(Game.tuning.push_reach_tiles, 9.0, 0.0001)
	p.set_value("wall_jump_speed", Vector2(200, 300))
	assert_eq(Game.tuning.wall_jump_speed, Vector2(200, 300))


func test_save_load_and_reset_presets() -> void:
	var p := _panel()
	p.set_value("pewter_speed", 1.75)
	p.save_preset("test_preset", "user://test_presets")
	p.reset_to_defaults()
	assert_near(Game.tuning.pewter_speed, Tuning.new().pewter_speed, 0.0001, "reset")
	assert_true(p.load_preset("user://test_presets/test_preset.tres"), "loaded")
	assert_near(Game.tuning.pewter_speed, 1.75, 0.0001, "restored")
	assert_true(TuningPanel.list_presets(["user://test_presets"]).has("user://test_presets/test_preset.tres"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_presets/test_preset.tres"))


func test_checkpoint_respawn_restores_position_reserves_and_pouch() -> void:
	var w := TestWorld.create(self, [Rect2(-400, 0, 800, 32)], Vector2(0, -1))
	await physics_frames(2)
	Checkpoints.reach(w.vin, Vector2(-100, -1))
	w.vin.reserves.set_amount(MetalReserves.Metal.STEEL, 10.0)
	w.vin.pouch.count = 3
	w.vin.global_position = Vector2(300, -200)
	Checkpoints.respawn(w.vin)
	await physics_frames(1)
	assert_lt(w.vin.global_position.distance_to(Vector2(-100, -1)), 2.0, "back at the checkpoint")
	assert_near(w.vin.reserves.amount(MetalReserves.Metal.STEEL), MetalReserves.FULL, 0.001, "reserves restored")
	assert_eq(w.vin.pouch.count, Game.tuning.coin_pouch_size, "pouch restored")


func test_kill_zone_returns_vin_to_the_checkpoint() -> void:
	var w := TestWorld.create(self, [Rect2(-400, 0, 200, 32)], Vector2(-300, -1))
	var zone := KillZone.new()
	zone.position = Vector2(-400, 150)
	zone.size = Vector2(1000, 40)
	w.add_child(zone)
	await physics_frames(2)
	Checkpoints.reach(w.vin, Vector2(-300, -1))
	w.vin.global_position = Vector2(100, -50)
	await physics_frames(60)
	assert_lt(w.vin.global_position.distance_to(Vector2(-300, -1)), 4.0, "respawned")
