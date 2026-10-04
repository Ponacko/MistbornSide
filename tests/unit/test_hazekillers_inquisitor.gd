extends TestCase

const FLOOR := Rect2(-1600, 0, 4000, 32)


func _squad(w: TestWorld, at: Vector2, count: int) -> HazekillerSquad:
	var s := HazekillerSquad.new()
	s.position = at
	s.count = count
	w.add_child(s)
	return s


func test_squad_of_four_to_eight_engages_as_a_group() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-400, -1))
	var s := _squad(w, Vector2(0, -1), 6)
	await physics_frames(2)
	assert_eq(s.members.size(), 6)
	s.members[0].notice()
	await physics_frames(2)
	for m in s.members:
		assert_true(m.aware, "%s alerted with the squad" % m.name)


func test_hazekillers_carry_no_metal() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-100, -1))
	var s := _squad(w, Vector2(0, -1), 4)
	await physics_frames(2)
	for m in s.members:
		assert_eq(m.find_children("*", "MetalSource", true, false).size(), 0, "no metal")
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = s.members[0].chest_position()
	await physics_frames(2)
	assert_eq(w.vin.allomancy.target, null, "nothing to Push or Pull")


func test_shield_blocks_coins_from_the_front_but_not_behind() -> void:
	var w := TestWorld.create(self, [FLOOR])
	var s := _squad(w, Vector2(0, -1), 4)
	await physics_frames(2)
	var h: Hazekiller = s.members[0]
	h.facing = 1
	assert_false(h.take_hit(Hit.make(Hit.Kind.COIN, 100.0, Vector2.LEFT, null)), "blocked from the front")
	assert_near(h.health.current, h.max_health, 0.001)
	assert_true(h.take_hit(Hit.make(Hit.Kind.COIN, 100.0, Vector2.RIGHT, null)), "hit from behind")


func test_two_pewter_heavies_break_a_shield() -> void:
	var w := TestWorld.create(self, [FLOOR])
	var s := _squad(w, Vector2(0, -1), 4)
	await physics_frames(2)
	var h: Hazekiller = s.members[0]
	h.facing = 1
	h.take_hit(Hit.make(Hit.Kind.HEAVY, 70.0, Vector2.LEFT, null, false))
	assert_true(h.has_shield, "one heavy is not enough")
	h.take_hit(Hit.make(Hit.Kind.HEAVY, 70.0, Vector2.LEFT, null, false))
	assert_false(h.has_shield, "shield broken")
	assert_true(h.take_hit(Hit.make(Hit.Kind.COIN, 100.0, Vector2.LEFT, null)), "coins land now")


func test_daggers_beat_a_hazekiller() -> void:
	var w := TestWorld.create(self, [FLOOR])
	var s := _squad(w, Vector2(0, -1), 4)
	await physics_frames(2)
	var h: Hazekiller = s.members[0]
	h.facing = 1
	for i in 6:
		h.take_hit(Hit.make(Hit.Kind.DAGGER, 34.0, Vector2.LEFT, null))
	assert_true(h.dead(), "daggers get through")


func _route() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for x in range(0, 2400, 40):
		pts.append(Vector2(x, -1))
	return pts


func _bendal(w: TestWorld) -> Bendal:
	var b := Bendal.new()
	b.route = _route()
	w.add_child(b)
	return b


func test_bendal_follows_the_route_and_closes_on_a_stalled_vin() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(500, -1))
	var b := _bendal(w)
	b.start()
	await physics_frames(60)
	assert_gt(b.global_position.x, 100.0, "running the route")
	var gap_then := w.vin.global_position.x - b.global_position.x
	await physics_frames(60)
	assert_lt(w.vin.global_position.x - b.global_position.x, gap_then - 100.0, "closing on her")


func test_bendal_axe_removes_most_of_her_health() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(40, -1))
	var b := _bendal(w)
	b.start()
	var hit := false
	for i in 120:
		await physics_frames(1)
		if w.vin.health.current < 100.0:
			hit = true
			break
	assert_true(hit, "struck")
	assert_lt(w.vin.health.current, 40.0, "most of her health gone")


func test_bendal_cannot_be_pushed_and_parts_the_mists() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-200, -1))
	var b := _bendal(w)
	b.global_position = Vector2(-120, -1)
	await physics_frames(2)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = b.chest_position() + Vector2(0, -8)
	await physics_frames(2)
	assert_eq(w.vin.allomancy.target, null, "spikes inside his body cannot be targeted")
	var lines := w.vin.allomancy.lines.filter(func(l): return l.inside_body)
	assert_gt(lines.size(), 0, "but Vin sees their lines")
	assert_lt(MistField.density_factor(b.chest_position()), 0.05, "the mists part around him")


func test_bendal_pushes_her_coins_back_at_her() -> void:
	var w := TestWorld.create(self, [FLOOR], Vector2(-300, -1))
	var b := _bendal(w)
	b.global_position = Vector2(-100, -1)
	await physics_frames(2)
	w.vin.controls.aim_active = true
	w.vin.controls.aim_point = b.chest_position()
	w.vin.controls.coin_pressed = true
	await physics_frames(2)
	var coin := tree.get_nodes_in_group("coins")[0] as Coin
	w.vin.controls.push_pressed = true
	w.vin.controls.push_held = true
	for i in 6:
		w.vin.controls.aim_point = coin.global_position
		await physics_frames(1)
	w.vin.controls.push_held = false
	var returned := false
	for i in 40:
		await physics_frames(1)
		if is_instance_valid(coin) and coin.thrower == b:
			returned = true
			break
	assert_true(returned, "Bendal took the coin")
	assert_true(b.health.current >= b.max_health, "unhurt")
