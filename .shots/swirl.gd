extends Node2D
var vin: Vin
func _ready():
	var lvl = load("res://levels/greybox/greybox.tscn").instantiate()
	add_child(lvl)
	vin = lvl.get_node("Vin")
	vin.scripted = true
	vin.position = Vector2(1120, -65)
	vin.controls.aim_active = true
func _physics_process(_d):
	vin.controls.aim_point = Vector2(1150, -150)
	vin.controls.push_held = true
