extends TestCase

const FLOOR := Rect2(-400, 0, 800, 32)


class FakeAttractor:
	extends Node2D
	var mist_strength := 1.0
	var mist_phase := 0.0


func test_wind_swirls_around_and_toward_an_active_attractor() -> void:
	var a := FakeAttractor.new()
	add(a)
	MistField.add_attractor(a)
	var p := Vector2(40, 0)
	var w := MistField.wind_at(p) - MistField.base_wind(p)
	assert_lt(w.x, 0.0, "drawn inward")
	assert_gt(absf(w.y), 1.0, "swirls tangentially")
	a.mist_strength = 0.0
	var calm := MistField.wind_at(p) - MistField.base_wind(p)
	assert_lt(calm.length(), 0.01, "no swirl when not burning")
	MistField.remove_attractor(a)


func test_repeller_pushes_wind_out_and_clears_density() -> void:
	var r := MistRepeller.new()
	r.radius = 60.0
	r.position = Vector2(100, 0)
	add(r)
	await physics_frames(1)
	var w := MistField.wind_at(Vector2(130, 0)) - MistField.base_wind(Vector2(130, 0))
	assert_gt(w.x, 0.0, "pushed away")
	assert_lt(MistField.density_factor(Vector2(100, 0)), 0.05, "a hole in the fog")
	assert_near(MistField.density_factor(Vector2(400, 0)), 1.0, 0.001, "untouched far away")


func test_vin_attracts_the_mists_while_burning_and_settles_after() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(0, -1))
	var a := w.anchor(Vector2(0, -1), 300.0)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = a.global_position
	await physics_frames(2)
	assert_near(w.vin.mist_strength, 0.0, 0.001)
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	await physics_frames(60)
	assert_gt(w.vin.mist_strength, 0.8, "mists gather while she Pushes")
	w.vin.controls.push_held = false
	await physics_frames(180)
	assert_lt(w.vin.mist_strength, 0.1, "settles when she stops")


func test_density_bake_pools_near_floors_and_masks_interiors() -> void:
	var w := TestWorld.create(self, [FLOOR, Rect2(100, -64, 80, 8)])
	var interior := MistInterior.new()
	interior.position = Vector2(100, -56)
	interior.size = Vector2(80, 56)
	w.add_child(interior)
	await physics_frames(2)
	var bake := MistBake.bake(w, Rect2(-400, -200, 800, 240), 8.0)
	var near_floor := MistBake.sample(bake, Vector2(-100, -4))
	var high := MistBake.sample(bake, Vector2(-100, -150))
	assert_gt(near_floor.r, high.r + 0.5, "pools near the floor")
	assert_lt(MistBake.sample(bake, Vector2(140, -28)).g, 0.1, "masked inside")
	assert_gt(MistBake.sample(bake, Vector2(-200, -28)).g, 0.9, "open air")
