extends TestCase

const FLOOR := Rect2(-800, 0, 1600, 32)


func test_title_and_mission_select_offer_only_the_slice() -> void:
	StoryFlags.clear()
	var title := TitleScreen.new()
	add(title)
	await process_frames(2)
	assert_true(title.has_button("New game"))
	assert_true(title.has_button("Missions"))
	assert_true(title.has_button("Settings"))
	var missions := GameFlow.missions()
	assert_eq(missions.size(), 2, "only the slice")
	assert_true(GameFlow.unlocked("04"))
	assert_false(GameFlow.unlocked("09"), "Kredik Shaw waits for Eight Metals")
	StoryFlags.set_flag("mission_04_done")
	assert_true(GameFlow.unlocked("09"))


func test_finishing_eight_metals_bridges_to_kredik_shaw() -> void:
	StoryFlags.clear()
	var card := GameFlow.bridge_card("04")
	assert_true(card != null, "a bridging card")
	assert_true(card.body.contains("Valette"), "it summarises the skipped chapters")
	card.free()
	assert_eq(GameFlow.next_mission("04"), "09")
	assert_eq(GameFlow.next_mission("09"), "")


func test_save_holds_story_flags_settings_and_bindings() -> void:
	StoryFlags.clear()
	StoryFlags.set_flag("mission_04_done")
	Settings.assist_mode = true
	Settings.line_thickness = 1.5
	Settings.rebind("coin", KEY_G)
	assert_true(SaveGame.save("user://test_save.json"))
	StoryFlags.clear()
	Settings.reset_for_test()
	Settings.rebind("coin", KEY_E)
	assert_true(SaveGame.load_save("user://test_save.json"))
	assert_true(StoryFlags.get_flag("mission_04_done"), "flags")
	assert_true(Settings.assist_mode, "settings")
	assert_near(Settings.line_thickness, 1.5, 0.001)
	assert_eq(Settings.binding("coin"), KEY_G, "bindings")
	Settings.rebind("coin", KEY_E)
	Settings.reset_for_test()


func test_steelsight_and_aim_options_feed_the_tuning() -> void:
	Settings.steelsight_slow = 0.3
	Settings.steelsight_duration = 0.5
	Settings.buffer_frames = 9
	Settings.aim_cone = 80.0
	Settings.apply()
	assert_near(Game.tuning.steelsight_time_scale, 0.3, 0.001)
	assert_near(Game.tuning.steelsight_window, 0.5, 0.001)
	assert_eq(Game.tuning.push_buffer_frames, 9)
	assert_near(Game.tuning.aim_snap_radius, 80.0, 0.001)
	Settings.reset_for_test()
	Settings.apply()


func test_auto_target_off_leaves_idle_aim_without_a_target() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	w.anchor(Vector2(60, -40))
	w.vin.controls.aim_active = false
	await physics_frames(3)
	assert_true(w.vin.allomancy.target != null, "heuristic target by default")
	Settings.auto_target = false
	await physics_frames(2)
	assert_eq(w.vin.allomancy.target, null, "no auto-target")
	Settings.reset_for_test()


func test_sticky_target_keeps_the_last_target() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var a := w.anchor(Vector2(60, -40))
	Settings.sticky_target = true
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = a.global_position
	await physics_frames(2)
	w.vin.controls.aim_point = Vector2(-300, -300)
	await physics_frames(2)
	assert_eq(w.vin.allomancy.target, a, "kept until changed")
	Settings.reset_for_test()


func test_assist_preset_slows_time_and_halves_damage() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	Settings.assist_mode = true
	Settings.apply()
	await physics_frames(2)
	assert_near(Engine.time_scale, 0.8, 0.001)
	w.vin.take_hit(Hit.make(Hit.Kind.HAZARD, 20.0, Vector2.RIGHT, null))
	assert_near(w.vin.health.current, 90.0, 0.001, "half damage")
	Settings.reset_for_test()
	Settings.apply()


func test_toggle_push_holds_on_a_tap() -> void:
	Settings.toggle_push = true
	var c := PlayerControls.new()
	c.apply_toggle_mode(true, true, false, false)
	assert_true(c.push_held, "tap turns it on")
	c.apply_toggle_mode(false, false, false, false)
	assert_true(c.push_held, "stays on")
	c.apply_toggle_mode(true, true, false, false)
	assert_false(c.push_held, "tap again turns it off")
	Settings.reset_for_test()


func test_line_options_change_how_lines_draw() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	w.anchor(Vector2(60, -40))
	w.vin.reserves.set_amount(MetalReserves.Metal.STEEL, 0.0)
	w.vin.reserves.set_amount(MetalReserves.Metal.IRON, 0.0)
	await physics_frames(2)
	assert_eq(w.vin.allomancy.lines.size(), 0, "hidden with no steel or iron")
	Settings.lines_always = true
	await physics_frames(2)
	assert_eq(w.vin.allomancy.lines.size(), 1, "always shown")
	var normal := BlueLines.line_color(0.5)
	Settings.high_contrast_lines = true
	assert_gt(BlueLines.line_color(0.5).a, normal.a, "higher contrast")
	Settings.line_thickness = 2.0
	assert_near(BlueLines.width_scale(), 2.0, 0.001)
	Settings.reset_for_test()


func test_remapping_changes_the_input_map() -> void:
	Settings.rebind("dagger", KEY_K)
	var found := false
	for e in InputMap.action_get_events("dagger"):
		if e is InputEventKey and e.physical_keycode == KEY_K:
			found = true
	assert_true(found, "rebound")
	Settings.rebind("dagger", KEY_F)


func test_pause_menu_pauses_and_resumes() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var menu := PauseMenu.new()
	add(menu)
	await process_frames(1)
	menu.open()
	assert_true(tree.paused)
	menu.close()
	assert_false(tree.paused)


func test_settings_screen_has_every_accessibility_option() -> void:
	var s := SettingsScreen.new()
	add(s)
	await process_frames(1)
	for key in ["steelsight_slow", "steelsight_duration", "buffer_frames", "aim_cone", "aim_assist", "auto_target",
			"assist_mode", "toggle_push", "sticky_target", "lines_always", "high_contrast_lines", "line_thickness",
			"colorblind", "screen_shake", "flash_intensity"]:
		assert_true(s.has_option(key), key)
	assert_true(s.has_rebind("dagger"), "remapping")


func test_game_flow_loads_a_mission_and_returns_to_the_title() -> void:
	StoryFlags.clear()
	GameFlow.start_mission("04")
	await process_frames(4)
	var scene := tree.current_scene as Mission
	assert_true(scene != null and scene.mission_id == "04", "mission 4 loaded")
	assert_true(scene.has_node("PauseMenu"), "pausable")
	GameFlow.to_title()
	await process_frames(3)
	assert_true(tree.current_scene is TitleScreen, "back at the title")
	tree.current_scene.queue_free()
	await process_frames(1)


func test_replaying_a_mission_resets_its_beats_but_keeps_completion() -> void:
	StoryFlags.clear()
	StoryFlags.set_flag("mission_04_done")
	StoryFlags.set_flag("prompt_seen_m04_tin")
	StoryFlags.set_flag("m04_wall")
	StoryFlags.set_flag("m09_logbook")
	StoryFlags.clear_mission("04")
	assert_false(StoryFlags.get_flag("prompt_seen_m04_tin"), "prompts show again on a replay")
	assert_false(StoryFlags.get_flag("m04_wall"), "the ending can fire again")
	assert_true(StoryFlags.get_flag("mission_04_done"), "completion kept")
	assert_true(StoryFlags.get_flag("m09_logbook"), "other missions untouched")


func test_a_wounded_respawn_has_enough_pewter_to_run() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	await physics_frames(2)
	w.vin.wound(10.0)
	w.vin.reserves.set_amount(MetalReserves.Metal.PEWTER, 2.0)
	Checkpoints.reach(w.vin, Vector2(0, -1))
	Checkpoints.respawn(w.vin)
	assert_gt(w.vin.reserves.amount(MetalReserves.Metal.PEWTER), 30.0, "not a death loop")
