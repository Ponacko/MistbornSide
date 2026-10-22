extends Node2D
## Jumps Vin through a list of spots and holds, for before/after renders.
var vin: Vin
var f := 0
var spots := []
func _ready():
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://.shots/tour.json"))
	var path: String = cfg.level
	var lvl = load(path).instantiate()
	add_child(lvl)
	vin = lvl.get_node("Vin")
	vin.scripted = true
	for k in StoryFlags._flags.keys(): pass
	for sp in cfg.spots:
		spots.append(Vector2(sp[0], sp[1]))
	if cfg.has("flags"):
		for fl in cfg.flags:
			StoryFlags.set_flag(fl)
func _physics_process(_d):
	f += 1
	var box = get_tree().get_first_node_in_group("dialogue_box")
	if box and box.is_open(): box.next()
	var i := f / 40
	if f % 40 == 1 and i < spots.size():
		vin.global_position = spots[i]
		vin.reset_physics_interpolation()
		vin.velocity = Vector2.ZERO
