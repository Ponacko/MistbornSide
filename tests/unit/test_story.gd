extends TestCase


func test_dialogue_plays_from_data_and_a_choice_changes_a_later_line() -> void:
	for pick in [0, 1]:
		StoryFlags.clear()
		var r := DialogueRunner.new()
		assert_true(r.load_file("res://data/dialogue/sample.json"), "loaded")
		r.start()
		assert_eq(r.current().speaker, "Kelsier")
		r.advance()
		r.advance()
		var c := r.current()
		assert_eq(c.choices.size(), 2, "a choice point")
		assert_eq(c.choices[0].kind, "soothe")
		assert_eq(c.choices[1].kind, "riot")
		r.choose(pick)
		r.advance()
		var later: String = r.current().text
		if pick == 0:
			assert_true(StoryFlags.get_flag("camon_soothed"), "soothe recorded")
			assert_true(later.begins_with("Gently"), "the soothed line")
		else:
			assert_true(StoryFlags.get_flag("camon_rioted"), "riot recorded")
			assert_true(later.begins_with("Subtle"), "the rioted line")
		r.advance()
		assert_true(r.finished, "scene over")


func test_story_flags_persist_across_a_level_reload_and_to_disk() -> void:
	StoryFlags.clear()
	StoryFlags.set_flag("met_kelsier", true)
	var a: Node = (load("res://levels/test/dialogue_sample.tscn") as PackedScene).instantiate()
	add(a)
	await physics_frames(2)
	a.free()
	var b: Node = (load("res://levels/test/dialogue_sample.tscn") as PackedScene).instantiate()
	add(b)
	await physics_frames(2)
	assert_true(StoryFlags.get_flag("met_kelsier"), "flags outlive the level")
	StoryFlags.save_to("user://test_flags.json")
	StoryFlags.clear()
	StoryFlags.load_from("user://test_flags.json")
	assert_true(StoryFlags.get_flag("met_kelsier"), "and the disk")


func test_dialogue_box_takes_control_and_gives_it_back() -> void:
	var w := TestWorld.create(self, [Rect2(-200, 0, 400, 32)], Vector2(0, -1))
	var box := DialogueBox.new()
	add(box)
	await physics_frames(2)
	box.play_file("res://data/dialogue/sample.json")
	assert_true(w.vin.input_locked(), "Vin waits while they talk")
	var guard := 0
	while box.is_open() and guard < 20:
		if box.runner.current().choices.size() > 0:
			box.pick(0)
		else:
			box.next()
		guard += 1
		await physics_frames(1)
	assert_false(box.is_open(), "closed")
	assert_false(w.vin.input_locked(), "control returned")


func test_prompt_gates_progress_until_the_action_and_never_shows_twice() -> void:
	StoryFlags.clear()
	var w := TestWorld.create(self, [Rect2(-200, 0, 400, 32)], Vector2(0, -1))
	var barrier := w.block(Rect2(60, -100, 16, 100))
	var p := TutorialPrompt.new()
	p.prompt_id = "tin_lesson"
	p.action = "toggle_tin"
	p.text = "Burn tin"
	p.gate_path = barrier.get_path()
	w.add_child(p)
	await physics_frames(2)
	p.show_prompt()
	assert_true(p.showing, "shown")
	assert_true(p.key_label().length() > 0, "names the key")
	w.vin.controls.move.x = 1.0
	await physics_frames(30)
	assert_lt(w.vin.global_position.x, 60.0, "the way is shut")
	w.vin.controls.toggle_tin = true
	await physics_frames(2)
	assert_false(p.showing, "satisfied")
	assert_false(is_instance_valid(barrier) and barrier.is_inside_tree(), "the way opens")
	var again := TutorialPrompt.new()
	again.prompt_id = "tin_lesson"
	again.action = "toggle_tin"
	w.add_child(again)
	again.show_prompt()
	assert_false(again.showing, "never shows twice")


func test_sample_cutscene_moves_camera_and_character_then_returns_control() -> void:
	var level: Node2D = (load("res://levels/test/dialogue_sample.tscn") as PackedScene).instantiate()
	add(level)
	var vin: Vin = level.get_node("Vin")
	vin.scripted = true
	var cut: Cutscene = level.get_node("Cutscene")
	var kel: Node2D = level.get_node("Kelsier")
	await physics_frames(2)
	var kel_start := kel.global_position
	cut.play()
	await physics_frames(10)
	assert_true(vin.input_locked(), "no control during the cutscene")
	var cam: Camera2D = level.get_node("Cutscene/CutsceneCamera")
	assert_true(cam.is_current(), "the cutscene camera is live")
	await cut.finished
	await physics_frames(1)
	assert_false(vin.input_locked(), "control back")
	assert_gt(kel.global_position.distance_to(kel_start), 40.0, "the character moved")
	assert_false(cam.is_current(), "game camera restored")


func test_hud_shows_health_only_when_hurt_and_edge_tints_for_pewter_and_tin() -> void:
	var w := TestWorld.create(self, [Rect2(-200, 0, 400, 32)], Vector2(0, -1))
	var hud := Hud.new()
	add(hud)
	await physics_frames(30)
	assert_lt(hud.health_alpha, 0.05, "full health bar fades away")
	w.vin.take_hit(Hit.make(Hit.Kind.HAZARD, 20.0, Vector2.RIGHT, null, true))
	await physics_frames(10)
	assert_gt(hud.health_alpha, 0.5, "shown when hurt")
	assert_eq(hud.edge_tint().a, 0.0, "no tint with nothing burning")
	w.vin.toggle_pewter_now(true)
	await physics_frames(2)
	var warm := hud.edge_tint()
	assert_gt(warm.r, warm.b, "pewter is a warm edge")
	w.vin.toggle_pewter_now(false)
	w.vin.toggle_tin_now(true)
	await physics_frames(2)
	var cool := hud.edge_tint()
	assert_gt(cool.b, cool.r, "tin is a cool edge")
