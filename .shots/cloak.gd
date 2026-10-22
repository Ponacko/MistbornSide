extends Node2D
var vin: Vin
var f := 0
func _ready():
	var lvl = load("res://levels/greybox/greybox.tscn").instantiate()
	add_child(lvl)
	lvl.get_node("Night").queue_free()
	vin = lvl.get_node("Vin")
	vin.scripted = true
	vin.position = Vector2(40, -1)
func _physics_process(_d):
	f += 1
	vin.controls.aim_active = true
	if f == 60:
		vin.controls.move.y = 1
		vin.controls.coin_pressed = true
	if f == 62: vin.controls.move.y = 0
	if f >= 80 and f < 125:
		vin.controls.aim_point = vin.global_position + Vector2(0, 30)
		vin.controls.push_held = true
		vin.controls.flare_held = true
	if f == 125:
		vin.controls.push_held = false
		vin.controls.flare_held = false
