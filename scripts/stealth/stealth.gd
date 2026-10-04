class_name Stealth
## Light and shadow (DESIGN.md 6.4): Vin is seen in lantern light, hidden in
## shadow.


static func is_lit(point: Vector2) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	for l in tree.get_nodes_in_group("lights"):
		if l.has_method("lights_point") and l.lights_point(point):
			return true
	return false
