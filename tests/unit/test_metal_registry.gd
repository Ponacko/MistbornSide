extends TestCase


func _source_at(pos: Vector2, mass := 1.0) -> MetalSource:
	var holder := Node2D.new()
	holder.position = pos
	var s := MetalSource.new()
	s.mass = mass
	holder.add_child(s)
	add(holder)
	return s


func test_placing_a_metal_source_registers_it_and_freeing_unregisters() -> void:
	var s := _source_at(Vector2(100, 0))
	await physics_frames(1)
	assert_true(MetalRegistry.query(Vector2.ZERO, 200.0).has(s), "registered")
	s.get_parent().free()
	await physics_frames(1)
	assert_eq(MetalRegistry.query(Vector2.ZERO, 200.0).size(), 0, "unregistered")


func test_query_returns_only_sources_within_radius() -> void:
	var near := _source_at(Vector2(150, 0))
	var far := _source_at(Vector2(900, 0))
	var diag := _source_at(Vector2(150, 150))
	await physics_frames(1)
	var found := MetalRegistry.query(Vector2.ZERO, 200.0)
	assert_true(found.has(near), "near found")
	assert_false(found.has(far), "far excluded")
	assert_false(found.has(diag), "outside the circle even if inside the cell")


func test_query_sees_sources_that_moved() -> void:
	var s := _source_at(Vector2(900, 0))
	await physics_frames(1)
	assert_false(MetalRegistry.query(Vector2.ZERO, 200.0).has(s))
	s.get_parent().position = Vector2(50, 0)
	await physics_frames(1)
	assert_true(MetalRegistry.query(Vector2.ZERO, 200.0).has(s), "moved into range")


func test_line_width_grows_with_mass() -> void:
	var clip := BlueLineStyle.width_for_mass(0.01)
	var bar := BlueLineStyle.width_for_mass(5.0)
	var gate := BlueLineStyle.width_for_mass(800.0)
	assert_lt(clip, bar)
	assert_lt(bar, gate)
	assert_lt(clip, 1.0, "a clip is a hair")


func test_line_alpha_falls_off_smoothly_and_dims_through_walls() -> void:
	var r := 400.0
	var a0 := BlueLineStyle.alpha(0.0, r, false)
	var a1 := BlueLineStyle.alpha(200.0, r, false)
	var a2 := BlueLineStyle.alpha(399.0, r, false)
	assert_gt(a0, a1)
	assert_gt(a1, a2)
	assert_lt(a2, 0.05, "nearly invisible at the edge of range")
	# No step anywhere along the falloff.
	var prev := a0
	for d in range(0, 400, 4):
		var a := BlueLineStyle.alpha(float(d), r, false)
		assert_lt(absf(prev - a), 0.03, "smooth at %d" % d)
		prev = a
	assert_lt(BlueLineStyle.alpha(100.0, r, true), BlueLineStyle.alpha(100.0, r, false) * 0.6, "dimmer through walls")
