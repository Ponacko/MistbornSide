extends Node2D
var vin: Vin
var f := 0
func _ready():
	var lvl = load("res://levels/greybox/greybox.tscn").instantiate()
	add_child(lvl)
	vin = lvl.get_node("Vin")
	vin.scripted = true
	vin.position = Vector2(-60, -1)
func _physics_process(_d):
	f += 1
	if f == 5: vin.controls.toggle_tin = true
