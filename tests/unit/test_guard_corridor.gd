extends TestCase
## The guard corridor (three guards on roofs over a pit) cleared four
## different ways by scripted play: fighting, coins, shoves, and backstabs.

const GAPS := [[200.0, 240.0], [540.0, 580.0], [880.0, 920.0], [1220.0, 1260.0]]

var level: Node2D
var vin: Vin


func _load() -> void:
	level = (load("res://levels/test/guard_corridor.tscn") as PackedScene).instantiate()
	add(level)
	vin = level.get_node("Vin")
	vin.scripted = true
	await physics_frames(3)


func _guards() -> Array[Guard]:
	var out: Array[Guard] = []
	for i in 3:
		out.append(level.get_node("Guard%d" % (i + 1)) as Guard)
	return out


func _all_dead() -> bool:
	return _guards().all(func(g): return g.dead())


## One frame of walking toward x, jumping any gap on the way.
func _walk_toward(x: float) -> void:
	var dx := x - vin.global_position.x
	vin.controls.move.x = signf(dx) if absf(dx) > 3.0 else 0.0
	vin.controls.jump_pressed = false
	vin.controls.jump_held = not vin.is_on_floor()
	if vin.is_on_floor() and vin.controls.move.x != 0.0:
		for gap in GAPS:
			var edge: float = gap[0] if vin.controls.move.x > 0.0 else gap[1]
			var ahead := (edge - vin.global_position.x) * vin.controls.move.x
			var target_past: bool = (x - edge) * vin.controls.move.x > 0.0
			if target_past and ahead > 0.0 and ahead < 14.0:
				vin.controls.jump_pressed = true
				vin.controls.jump_held = true


func _segment_end_before(g: Guard) -> float:
	var best := -INF
	for gap in GAPS:
		if gap[0] < g.global_position.x:
			best = maxf(best, gap[0])
	return best - 8.0


func test_cleared_by_fighting() -> void:
	await _load()
	vin.toggle_pewter_now(true)
	for frame in 3000:
		if _all_dead():
			break
		vin.toggle_pewter_now(true)
		var g := _guards().filter(func(g): return not g.dead())[0] as Guard
		var dx := g.global_position.x - vin.global_position.x
		if absf(dx) < 22.0 and vin.is_on_floor():
			vin.controls.move.x = 0.0
			vin.facing = int(signf(dx)) if dx != 0.0 else 1
			if frame % 10 == 0:
				vin.controls.dagger_pressed = true
				vin.controls.dagger_released = true
		else:
			_walk_toward(g.global_position.x)
		await physics_frames(1)
	assert_true(_all_dead(), "all three guards killed in melee")


func test_cleared_with_coins() -> void:
	await _load()
	for g in _guards():
		var stand := _segment_end_before(g)
		for f in 400:
			if absf(vin.global_position.x - stand) < 4.0 and vin.is_on_floor():
				break
			_walk_toward(stand)
			await physics_frames(1)
		vin.controls.move.x = 0.0
		for shot in 6:
			if g.dead():
				break
			vin.controls.aim_active = true
			vin.controls.aim_point = g.chest_position()
			vin.controls.coin_pressed = true
			await physics_frames(3)
			var coins := tree.get_nodes_in_group("coins")
			var coin := coins[-1] as Coin
			vin.controls.aim_point = coin.global_position
			vin.controls.push_pressed = true
			vin.controls.push_held = true
			for f in 30:
				if not is_instance_valid(coin):
					break
				vin.controls.aim_point = coin.global_position
				await physics_frames(1)
			vin.controls.push_held = false
			await physics_frames(10)
		assert_true(g.dead(), "%s shot down" % g.name)


func test_cleared_by_shoving_guards_off_the_roofs() -> void:
	await _load()
	for g in _guards():
		var stand := _segment_end_before(g)
		for f in 400:
			if absf(vin.global_position.x - stand) < 4.0 and vin.is_on_floor():
				break
			_walk_toward(stand)
			await physics_frames(1)
		vin.controls.move.x = 0.0
		await physics_frames(10)
		vin.controls.aim_active = true
		vin.controls.aim_point = g.breastplate.global_position
		vin.controls.flare_held = true
		vin.controls.push_pressed = true
		vin.controls.push_held = true
		for f in 30:
			if g.velocity.x > 420.0 or g.dead():
				break
			vin.controls.aim_point = g.breastplate.global_position
			await physics_frames(1)
		vin.controls.push_held = false
		vin.controls.flare_held = false
		for f in 120:
			if g.dead():
				break
			await physics_frames(1)
		assert_true(g.dead(), "%s fell to his death" % g.name)
		assert_false(vin.is_dead(), "Vin kept her footing")


func test_cleared_by_backstabs() -> void:
	await _load()
	for g in _guards():
		var stand := _segment_end_before(g)
		for f in 400:
			if absf(vin.global_position.x - stand) < 4.0 and vin.is_on_floor():
				break
			_walk_toward(stand)
			await physics_frames(1)
		vin.controls.move.x = 0.0
		# Wait for him to turn his back.
		for f in 600:
			if g.facing == 1 and g.global_position.x < g.home.x - 20.0:
				break
			await physics_frames(1)
		for f in 300:
			var dx := g.global_position.x - vin.global_position.x
			if dx > 0.0 and dx < 26.0 and vin.is_on_floor():
				vin.controls.move.x = 0.0
				vin.facing = 1
				vin.controls.dagger_pressed = true
				await physics_frames(2)
				break
			_walk_toward(g.global_position.x)
			await physics_frames(1)
		assert_true(g.dead(), "%s killed unaware" % g.name)
		assert_eq(g.last_hit_kind, Hit.Kind.BACKSTAB)
