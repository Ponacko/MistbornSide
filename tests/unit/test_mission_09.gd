extends TestCase
## Mission 9 played start to finish by script, and its no-fail stealth.

var level: Node2D
var bot: MissionBot


func _load() -> void:
	StoryFlags.clear()
	level = (load("res://levels/missions/m09_kredik_shaw/m09_kredik_shaw.tscn") as PackedScene).instantiate()
	add(level)
	bot = MissionBot.new(self, level)
	await bot.wait(2)


func _worst_outside() -> int:
	var worst := 0
	for n in ["YardGuard1", "YardGuard2", "Seeker"]:
		worst = maxi(worst, (level.get_node(n) as Enemy).suspicion.stage)
	return worst


func _fight_arena(arena: ArenaLock) -> bool:
	for f in 3000:
		var foes := arena.enemies()
		if foes.is_empty():
			return true
		bot.vin.toggle_pewter_now(true)
		var g: Enemy = foes[0]
		var dx := g.global_position.x - bot.vin.global_position.x
		if absf(dx) < 22.0:
			bot.vin.controls.move.x = 0.0
			bot.vin.facing = int(signf(dx)) if dx != 0.0 else 1
			if f % 10 == 0:
				bot.vin.controls.dagger_pressed = true
				bot.vin.controls.dagger_released = true
		else:
			bot.vin.controls.move.x = signf(dx)
		await bot.frame()
	return false


func test_being_seen_outside_rings_the_bell_instead_of_failing() -> void:
	await _load()
	await bot.wait_talk()
	(level.get_node("YardGuard2") as Enemy).suspicion.alert()
	await bot.wait(int(Game.tuning.bell_delay * 60) + 20)
	assert_true((level.get_node("Bell") as AlarmBell).rung, "the bell rang")
	assert_gt(level.get_tree().get_nodes_in_group("enemies").size(), 9, "reinforcements came")
	assert_false(bot.vin.is_dead(), "no mission failure")
	assert_false(StoryFlags.get_flag("mission_09_done"))


func test_interior_fights_cannot_be_walked_past() -> void:
	await _load()
	await bot.wait_talk()
	bot.vin.global_position = Vector2(1200, -171)
	bot.vin.reset_physics_interpolation()
	bot.vin.toggle_pewter_now(true)
	bot.vin.invulnerable = true
	await bot.walk_to(1700.0, 300)
	assert_true((level.get_node("Arena1") as ArenaLock).sealed, "the arena sealed")
	assert_lt(bot.vin.global_position.x, 1551.0, "held in until the guards fall")


func test_mission_9_plays_through() -> void:
	await _load()
	var vin := bot.vin
	await bot.wait_talk()
	vin.controls.toggle_copper = true
	await bot.wait(2)
	assert_true(vin.copper_on, "copper on")
	# 1. The yard, across the roofs, unseen.
	await bot.walk_to(240.0)
	assert_true(await bot.pull_hang((level.get_node("Metal/BracketB") as Node2D).global_position), "to roof B")
	await bot.walk_to(612.0)
	assert_true(await bot.pull_hang((level.get_node("Metal/BracketC") as Node2D).global_position), "to the balcony")
	assert_lt(_worst_outside(), Suspicion.Stage.ALERTED, "the yard never raised the alarm")
	# 2. The halls, fought beside Kelsier.
	await bot.walk_to(1150.0)
	await bot.wait_talk()
	await bot.walk_to(1240.0)
	await bot.wait_talk()
	for arena_name in ["Arena1", "Arena2"]:
		var arena: ArenaLock = level.get_node(arena_name)
		await bot.walk_to(arena.global_position.x + 30.0)
		assert_true(await _fight_arena(arena), "%s won" % arena_name)
	var kel: Kelsier = level.get_node("Kelsier")
	assert_gt(kel.landed_blows, 0, "Kelsier fought beside her")
	# 3. The chamber and the hut.
	await bot.walk_to(2010.0)
	await bot.wait_talk()
	# 4. Bendal: burn atium, slip past during his recovery, take the book.
	await bot.walk_to(2160.0)
	await bot.wait_talk()
	for i in 30:
		vin.controls.atium_held = true
		await bot.frame()
	vin.controls.atium_held = false
	assert_true(vin.atium.burning, "atium burning")
	var bendal: Bendal = level.get_node("Bendal")
	for i in 600:
		var safe := false
		for s in vin.atium.shadows():
			if s.node == bendal and s.safe:
				safe = true
		if safe or bendal.recovering():
			break
		await bot.frame()
	vin.toggle_pewter_now(true)
	await bot.walk_to(2360.0)
	assert_true(StoryFlags.get_flag("m09_logbook"), "the logbook taken")
	assert_true(vin.wounded, "the axe wound")
	# 5. The chase.
	var deaths := [0]
	vin.died.connect(func(): deaths[0] += 1)
	await bot.wait_talk()
	for gap in [2900.0, 3500.0, 4000.0]:
		await bot.run_jump(gap)
	await bot.walk_to(4260.0)
	await bot.wait_talk()
	await bot.wait(5)
	assert_eq(deaths[0], 0, "outran Bendal")
	assert_true(StoryFlags.get_flag("mission_09_done"), "collapsed at Sazed's carriage: mission complete")
	print("    mission 9 bot run: %.1f s" % (bot.frames / 60.0))
