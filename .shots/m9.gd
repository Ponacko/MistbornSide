extends Node2D
var vin: Vin
var f := 0
var lvl
func _ready():
	lvl = load("res://levels/missions/m09_kredik_shaw/m09_kredik_shaw.tscn").instantiate()
	add_child(lvl)
	vin = lvl.get_node("Vin")
	vin.scripted = true
func _physics_process(_d):
	f += 1
	var box = get_tree().get_first_node_in_group("dialogue_box")
	if box and box.is_open() and f < 40: box.next()
	if f == 10:
		vin.global_position = Vector2(2120, -171)
		vin.reset_physics_interpolation()
	if f == 30: vin.controls.move.x = 1
	if f == 34: vin.controls.move.x = 0
	if f >= 50 and f < 80: vin.controls.atium_held = true
	if f == 80: vin.controls.atium_held = false
