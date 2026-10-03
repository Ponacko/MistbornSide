extends SceneTree
## Loads and compiles every GDScript in the project; exits 1 if any fails.

func _initialize() -> void:
	var bad := 0
	var files := _find("res://")
	for path in files:
		if path == get_script().resource_path:
			continue
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate():
			print("check: FAILED %s" % path)
			bad += 1
	print("check: %d scripts, %d failed" % [files.size(), bad])
	quit(1 if bad > 0 else 0)


func _find(dir_path: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	for sub in dir.get_directories():
		if sub.begins_with("."):
			continue
		out.append_array(_find(dir_path.path_join(sub)))
	for f in dir.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	return out
