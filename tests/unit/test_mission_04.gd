extends TestCase
## Mission 4 played start to finish by script, beat by beat.

var level: Node2D
var bot: MissionBot


func _beat(ok: bool, what: String) -> bool:
	assert_true(ok, what)
	return ok


func test_mission_4_plays_through_all_seven_beats() -> void:
	StoryFlags.clear()
	level = (load("res://levels/missions/m04_eight_metals/m04_eight_metals.tscn") as PackedScene).instantiate()
	add(level)
	bot = MissionBot.new(self, level)
	var vin := bot.vin
	var kel: Kelsier = level.get_node("Kelsier")
	var hud: Hud = level.get_node("Hud")
	await bot.wait(2)
	# Beat 1: the shop. No cloak until the intro is done, then eight vials.
	assert_false(vin.wears_cloak, "no cloak before Kelsier hands it over")
	await bot.wait_talk()
	assert_true(vin.wears_cloak, "the mistcloak is on")
	await bot.wait(150)
	assert_eq(hud.revealed_metals, 8, "eight reserves appeared")
	# Beat 2: tin, gated on the toggle.
	if not _beat(await bot.walk_to(420.0), "up on the roof"):
		return
	await bot.wait_talk()
	await bot.walk_to(470.0)
	assert_lt(vin.global_position.x, 478.0, "tin gate holds")
	vin.controls.toggle_tin = true
	await bot.wait(3)
	assert_true(vin.tin_on, "tin")
	await bot.walk_to(560.0)
	await bot.wait_talk()
	vin.controls.toggle_tin = true
	await bot.wait(3)
	# Beat 3: pewter, gated, then the gap.
	await bot.walk_to(650.0)
	await bot.wait_talk()
	vin.controls.toggle_pewter = true
	await bot.wait(3)
	assert_true(vin.pewter_on, "pewter")
	await bot.run_jump(700.0)
	if not _beat(vin.global_position.x > 845.0 and vin.is_on_floor(), "made the pewter gap"):
		return
	await bot.wait_talk()
	vin.controls.toggle_pewter = true
	# Beat 4: the coin, demonstrated by Kelsier first.
	await bot.walk_to(1000.0)
	await bot.wait_talk()
	assert_gt(vin.pouch.count, 0, "Kelsier handed over clips")
	for i in 120:
		if kel.global_position.y < -150.0 and not kel.performing:
			break
		await bot.frame()
	assert_lt(kel.global_position.y, -150.0, "Kelsier showed the coin jump")
	await bot.walk_to(1080.0)
	await bot.coin_jump_up(1130.0)
	if not _beat(vin.global_position.y < -195.0, "coin-jumped up to roof 3"):
		return
	# Beat 5: Pull across the street.
	await bot.walk_to(1300.0)
	await bot.wait_talk()
	await bot.walk_to(1340.0)
	var lamp := (level.get_node("Metal/StreetLamp") as Node2D).global_position
	var far := (level.get_node("Metal/FarBracket") as Node2D).global_position
	if not _beat(await bot.pull_hang(lamp, far), "pulled across the street"):
		return
	assert_gt(vin.global_position.x, 1650.0, "on roof 4")
	# Beat 6: the run to the wall.
	await bot.walk_to(1720.0)
	await bot.wait_talk()
	await bot.run_jump(1900.0)
	if not _beat(vin.global_position.x > 1950.0, "onto roof 5"):
		return
	await bot.walk_to(2060.0)
	await bot.push_launch((level.get_node("Metal/Gate") as Node2D).global_position, 2420.0)
	if not _beat(vin.global_position.x > 2420.0, "gate launch to roof 6"):
		return
	await bot.walk_to(2598.0)
	await bot.climb((level.get_node("Metal/Grate") as Node2D).global_position, (level.get_node("Metal/WallPlate") as Node2D).global_position, -540.0, 2650.0)
	if not _beat(vin.global_position.y < -530.0, "atop the city wall"):
		return
	# Beat 7: the end.
	await bot.walk_to(2790.0)
	await bot.wait_talk()
	await bot.wait(5)
	assert_true(StoryFlags.get_flag("mission_04_done"), "mission complete")
	var seconds := bot.frames / 60.0
	print("    mission 4 bot run: %.1f s" % seconds)
	assert_lt(seconds, 180.0, "a replay fits in three minutes")
