extends TestCase

const FLOOR := Rect2(-800, 0, 2400, 32)


func _kelsier(w: Node, at: Vector2, mode := Kelsier.Mode.COMPANION) -> Kelsier:
	var k := Kelsier.new()
	k.position = at
	k.mode = mode
	w.add_child(k)
	return k


func test_companion_follows_her_path_and_cannot_die() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(200, -40, 60, 40)], Vector2(0, -1))
	var k := _kelsier(w, Vector2(-40, -1))
	await physics_frames(2)
	w.vin.controls.move.x = 1.0
	var max_gap := 0.0
	for i in 240:
		if w.vin.is_on_floor() and absf(w.vin.global_position.x - 185.0) < 8.0:
			w.vin.controls.jump_pressed = true
			w.vin.controls.jump_held = true
		await physics_frames(1)
		max_gap = maxf(max_gap, k.global_position.distance_to(w.vin.global_position))
	assert_gt(k.global_position.x, 300.0, "came along, over the crate")
	assert_lt(max_gap, 140.0, "never fell far behind")
	assert_false(k.take_hit(Hit.make(Hit.Kind.AXE, 999.0, Vector2.RIGHT, null, false)), "cannot be hurt")


func test_companion_never_blocks_a_doorway() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(60, -200, 20, 150)], Vector2(0, -1))
	var k := _kelsier(w, Vector2(70, -1))
	k.hold_position = true
	await physics_frames(2)
	w.vin.controls.move.x = 1.0
	await physics_frames(60)
	assert_gt(w.vin.global_position.x, 120.0, "walked straight through him")


func test_companion_fights_the_nearest_guard() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var k := _kelsier(w, Vector2(-30, -1))
	var g := Guard.new()
	g.position = Vector2(120, -1)
	g.patrol_distance = 0.0
	w.add_child(g)
	await physics_frames(2)
	g.notice()
	for i in 600:
		await physics_frames(1)
		if g.dead():
			break
	assert_true(g.dead(), "Kelsier cut him down")
	assert_true(k.landed_blows > 0, "with his own daggers")


func test_markers_drive_a_demonstration_then_a_silhouette_wait() -> void:
	var level: Node2D = (load("res://levels/test/kelsier_markers.tscn") as PackedScene).instantiate()
	add(level)
	var vin: Vin = level.get_node("Vin")
	vin.scripted = true
	var k: Kelsier = level.get_node("Kelsier")
	await physics_frames(5)
	assert_eq(k.mode, Kelsier.Mode.DEMONSTRATOR)
	assert_eq(k.step_action(), KelsierMarker.Action.DEMONSTRATE, "waiting to show the coin jump")
	var roof_top := (level.get_node("Markers/1_CoinJump") as Node2D).global_position
	vin.controls.move.x = 1.0
	for i in 60:
		await physics_frames(1)
		if k.performing:
			break
	vin.controls.move.x = 0.0
	assert_true(k.performing, "demonstrating once Vin is close")
	assert_eq(tree.get_nodes_in_group("coins").size(), 1, "he dropped a coin")
	for i in 120:
		await physics_frames(1)
		if not k.performing:
			break
	assert_lt(k.global_position.distance_to(roof_top), 2.0, "landed on the higher roof")
	await physics_frames(90)
	assert_true(k.silhouette, "waits as a silhouette at the vantage point")
	var vantage := (level.get_node("Markers/2_Vantage") as Node2D).global_position
	assert_lt(k.global_position.distance_to(vantage), 2.0)
	vin.global_position = vantage + Vector2(-30, 0)
	vin.reset_physics_interpolation()
	await physics_frames(5)
	assert_eq(k.mode, Kelsier.Mode.COMPANION, "the next marker switches him to companion")
	assert_false(k.silhouette)
