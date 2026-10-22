extends Node2D
func _ready():
	var lvl = load("res://levels/test/guard_corridor.tscn").instantiate()
	add_child(lvl)
	var vin: Vin = lvl.get_node("Vin")
	vin.scripted = true
	vin.global_position = Vector2(330, -1)
	var k := Kelsier.new(); k.position = Vector2(300, -1); k.hold_position = true; lvl.add_child(k)
	var o := Obligator.new(); o.position = Vector2(460, -1); o.patrol_distance = 0; lvl.add_child(o)
	var b := Bendal.new(); b.position = Vector2(500, -1); b.hold_ground = true; lvl.add_child(b)
	var s := HazekillerSquad.new(); s.position = Vector2(250, -1); s.count = 4; lvl.add_child(s)
