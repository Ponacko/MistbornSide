extends TestCase

const DT := 1.0 / 60.0
const SHOULDER := Vector2(0, -36)


func _cloak() -> Mistcloak:
	var c := Mistcloak.new()
	add(c)
	c.reset(SHOULDER)
	return c


func _run(c: Mistcloak, frames: int, velocity: Vector2, moving := true) -> void:
	var anchor := SHOULDER
	for i in frames:
		if moving:
			anchor += velocity * DT
		c.step(DT, anchor, velocity, 1)


func _tips_relative(c: Mistcloak) -> Array:
	var out := []
	for chain in c.chains:
		out.append(chain.points[-1] - chain.points[0])
	return out


func test_twelve_chains_of_six_points() -> void:
	var c := _cloak()
	assert_eq(c.chains.size(), 12)
	for chain in c.chains:
		assert_eq(chain.points.size(), 6)


func test_settles_hanging_down_when_standing() -> void:
	var c := _cloak()
	_run(c, 180, Vector2.ZERO, false)
	for tip in _tips_relative(c):
		assert_gt(tip.y, 10.0, "hangs below the shoulders")
	assert_lt(c.motion(), 0.5, "settled")


func test_fans_wide_and_trails_down_on_a_launch() -> void:
	var standing := _cloak()
	_run(standing, 120, Vector2.ZERO, false)
	var calm_spread := _spread(standing)
	var c := _cloak()
	_run(c, 20, Vector2(80, -650))
	for tip in _tips_relative(c):
		assert_gt(tip.y, 5.0, "trails below during the launch")
	assert_gt(_spread(c), calm_spread * 1.8, "fans wide")


func test_trails_above_on_a_fall() -> void:
	var c := _cloak()
	_run(c, 30, Vector2(0, 520))
	var above := 0
	for tip in _tips_relative(c):
		if tip.y < 0.0:
			above += 1
	assert_gt(above, 9, "most tassels stream upward")


func test_never_explodes_under_violent_motion() -> void:
	var c := _cloak()
	var anchor := SHOULDER
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 600:
		var v := Vector2(rng.randf_range(-1500, 1500), rng.randf_range(-1500, 1500))
		anchor += v * DT
		if i % 97 == 0:
			anchor += Vector2(900, -400)
		c.step(DT, anchor, v, 1 if v.x > 0 else -1)
	for chain in c.chains:
		for j in range(1, chain.points.size()):
			var p: Vector2 = chain.points[j]
			assert_true(is_finite(p.x) and is_finite(p.y), "finite")
			var seg := p.distance_to(chain.points[j - 1])
			assert_lt(seg, Mistcloak.SEGMENT * 1.6, "segments hold their length")


func test_mist_wind_moves_the_cloak_while_vin_stands_still() -> void:
	var c := _cloak()
	_run(c, 120, Vector2.ZERO, false)
	var before := _tips_relative(c)
	var swirl := Node2D.new()
	swirl.set_script(load("res://tests/helpers/fake_attractor.gd"))
	swirl.position = SHOULDER + Vector2(30, 10)
	add(swirl)
	MistField.add_attractor(swirl)
	_run(c, 60, Vector2.ZERO, false)
	var moved := 0.0
	var after := _tips_relative(c)
	for i in after.size():
		moved = maxf(moved, (after[i] - before[i]).length())
	assert_gt(moved, 2.0, "wind moved the tassels")


func test_one_flag_hides_the_cloak_for_valette() -> void:
	var w := TestWorld.create(self, [Rect2(-200, 0, 400, 32)], Vector2(0, -1))
	await physics_frames(2)
	assert_true(w.vin.cloak.visible)
	w.vin.wears_cloak = false
	await physics_frames(1)
	assert_false(w.vin.cloak.visible, "hidden")
	w.vin.wears_cloak = true
	await physics_frames(1)
	assert_true(w.vin.cloak.visible, "back on")


func _spread(c: Mistcloak) -> float:
	var xs := _tips_relative(c).map(func(t): return t.x)
	return xs.max() - xs.min()
