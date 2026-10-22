extends Node2D
var vin: Vin
var f := 0
var lvl
func _ready():
	lvl = load("res://levels/test/dialogue_sample.tscn").instantiate()
	add_child(lvl)
	vin = lvl.get_node("Vin")
	vin.scripted = true
func _physics_process(_d):
	f += 1
	vin.controls.move.x = 1.0 if f < 40 else 0.0
	if f == 60 or f == 70:
		var box = get_tree().get_first_node_in_group("dialogue_box")
		if box: box.next(); box.next()
