class_name MissionBot
extends RefCounted
## Scripted play for mission tests: walks, jumps steps and gaps, talks
## through dialogue, and performs the Allomantic moves the beats teach.

var test: TestCase
var level: Node
var vin: Vin
var frames := 0
var log: PackedStringArray = []


func _init(t: TestCase, lvl: Node) -> void:
	test = t
	level = lvl
	vin = lvl.get_node("Vin")
	vin.scripted = true


func frame() -> void:
	await test.physics_frames(1)
	frames += 1
	var box := level.get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if box and box.is_open() and frames % 3 == 0:
		if box.runner.current().get("choices", []).size() > 0:
			box.pick(0)
		else:
			box.next()


func wait(n: int) -> void:
	for i in n:
		await frame()


func talking() -> bool:
	var box := level.get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	return box != null and box.is_open()


func wait_talk() -> void:
	await frame()
	for i in 1200:
		if not talking():
			return
		await frame()


## Walks to x, hopping up steps and over small gaps on the way.
func walk_to(x: float, limit := 900) -> bool:
	for i in limit:
		if talking():
			vin.controls.move.x = 0.0
			await frame()
			continue
		var dx := x - vin.global_position.x
		if absf(dx) < 3.0:
			break
		vin.controls.move.x = signf(dx)
		vin.controls.jump_held = not vin.is_on_floor()
		if (vin.is_on_floor() and vin.is_on_wall()) or vin.state == Vin.State.LEDGE_HANG:
			vin.controls.jump_pressed = true
			vin.controls.jump_held = true
		await frame()
	vin.controls.move.x = 0.0
	await wait(8)
	return absf(x - vin.global_position.x) < 6.0


## Runs off an edge at x and jumps, holding forward until landing.
func run_jump(edge: float, dir := 1.0) -> void:
	await walk_to(edge - dir * 70.0)
	for i in 120:
		vin.controls.move.x = dir
		if (vin.global_position.x - edge) * dir > -6.0 and vin.is_on_floor():
			vin.controls.jump_pressed = true
			vin.controls.jump_held = true
		await frame()
		if (vin.global_position.x - edge) * dir > 10.0 and vin.is_on_floor():
			break
	vin.controls.move.x = 0.0
	vin.controls.jump_held = false
	await wait(5)


func aim(at: Vector2, moved := false) -> void:
	vin.controls.aim_active = true
	vin.controls.aim_point = at
	vin.controls.aim_moved = moved


func nearest_coin() -> Coin:
	var best: Coin = null
	for c in level.get_tree().get_nodes_in_group("coins"):
		if best == null or c.global_position.distance_to(vin.global_position) < best.global_position.distance_to(vin.global_position):
			best = c
	return best


## Drop a clip, stand over it, Push: the coin jump.
func coin_jump_up(then_x: float) -> void:
	vin.controls.move.y = 1.0
	vin.controls.coin_pressed = true
	await frame()
	vin.controls.move.y = 0.0
	await wait(30)
	aim(nearest_coin().global_position)
	vin.controls.push_pressed = true
	vin.controls.push_held = true
	var start_y := vin.global_position.y
	for i in 90:
		await frame()
		if vin.global_position.y < start_y - 125.0:
			break
	vin.controls.move.x = signf(then_x - vin.global_position.x)
	for i in 90:
		await frame()
		if vin.is_on_floor() and vin.global_position.y < start_y - 50.0:
			break
	vin.controls.push_held = false
	vin.controls.move.x = 0.0
	await wait(5)


## Pull to an anchor and hang; optionally retarget to a second one; jump off.
func pull_hang(at: Vector2, then_at := Vector2.INF) -> bool:
	aim(at)
	vin.controls.pull_pressed = true
	vin.controls.pull_held = true
	var ok := false
	for i in 150:
		await frame()
		if vin.state == Vin.State.BRACKET_HANG:
			ok = true
			break
	if not ok:
		return false
	if then_at != Vector2.INF:
		aim(then_at, true)
		ok = false
		for i in 150:
			await frame()
			if vin.state == Vin.State.BRACKET_HANG and vin.chest_position().distance_to(then_at) < 4.0:
				ok = true
				break
		if not ok:
			return false
	vin.controls.jump_pressed = true
	vin.controls.jump_held = true
	vin.controls.move.x = 1.0
	await frame()
	vin.controls.pull_held = false
	for i in 120:
		await frame()
		if vin.is_on_floor():
			break
	vin.controls.move.x = 0.0
	vin.controls.jump_held = false
	await wait(5)
	return vin.is_on_floor()


## Push off an anchor behind her while jumping forward.
func push_launch(anchor: Vector2, land_x: float) -> void:
	aim(anchor)
	vin.controls.jump_pressed = true
	vin.controls.jump_held = true
	vin.controls.push_pressed = true
	vin.controls.push_held = true
	vin.controls.move.x = 1.0
	await wait(25)
	vin.controls.push_held = false
	for i in 180:
		await frame()
		if vin.is_on_floor() and vin.global_position.x > land_x:
			break
	vin.controls.move.x = 0.0
	vin.controls.jump_held = false
	await wait(5)


## Hover up off an anchor below, then off a wall plate, onto the roof.
func climb(grate: Vector2, plate: Vector2, roof_top: float, roof_x: float) -> void:
	aim(grate)
	vin.controls.push_pressed = true
	vin.controls.push_held = true
	for i in 120:
		await frame()
		if vin.global_position.y < plate.y - 10.0:
			break
	vin.controls.move.x = 1.0
	for i in 60:
		await frame()
		if vin.global_position.x > plate.x - 8.0:
			break
	vin.controls.move.x = 0.0
	aim(plate, true)
	for i in 180:
		await frame()
		if vin.global_position.y < roof_top - 10.0:
			break
	vin.controls.move.x = 1.0
	for i in 60:
		await frame()
		if vin.global_position.x > roof_x + 8.0:
			break
	vin.controls.push_held = false
	for i in 120:
		await frame()
		if vin.is_on_floor():
			break
	vin.controls.move.x = 0.0
	await wait(5)
