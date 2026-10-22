extends Node2D
var vin: Vin
var f := 0
func _ready():
	StoryFlags.set_flag("m04_intro", true)
	var lvl = load("res://levels/missions/m04_eight_metals/m04_eight_metals.tscn").instantiate()
	add_child(lvl)
	vin = lvl.get_node("Vin")
	vin.scripted = true
func _physics_process(_d):
	f += 1
	var box = get_tree().get_first_node_in_group("dialogue_box")
	if box and box.is_open(): box.next()
	if f == 30:
		vin.global_position = Vector2(1240, -201)
		vin.reset_physics_interpolation()
