extends Node
## Autoload "SaveGame": story flags, settings and key bindings, saved to
## disk (no mid-mission saves beyond checkpoints, DESIGN.md 14).

const PATH := "user://save.json"


func _ready() -> void:
	load_save()


func save(path := PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"version": 1, "flags": StoryFlags.to_dict(), "settings": Settings.to_dict()}, "\t"))
	return true


func load_save(path := PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return false
	StoryFlags.from_dict(data.get("flags", {}))
	Settings.from_dict(data.get("settings", {}))
	return true
