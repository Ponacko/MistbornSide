extends SceneTree
func _initialize():
	for p in ProjectSettings.get_property_list():
		if "hdr_2d" in p.name or "glow" in p.name and "rendering" in p.name: print(p.name)
	for m in ClassDB.class_get_property_list("Environment", true):
		if "glow" in m.name: print("Environment.", m.name)
	for m in ClassDB.class_get_property_list("PointLight2D", true):
		if "shadow" in m.name: print("PointLight2D.", m.name)
	for m in ClassDB.class_get_property_list("Light2D", true):
		if "shadow" in m.name: print("Light2D.", m.name)
	quit()
