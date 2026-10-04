extends Node
## Autoload "StoryFlags": what has happened in the story (choices made,
## prompts seen, cutscenes played). Lives across level loads and saves with
## the game.

signal changed(flag: String, value: Variant)

var _flags := {}


func get_flag(flag: String, default: Variant = false) -> Variant:
	return _flags.get(flag, default)


func set_flag(flag: String, value: Variant = true) -> void:
	_flags[flag] = value
	changed.emit(flag, value)


func has_flag(flag: String) -> bool:
	return _flags.has(flag)


func clear() -> void:
	_flags.clear()


func to_dict() -> Dictionary:
	return _flags.duplicate(true)


func from_dict(data: Dictionary) -> void:
	_flags = data.duplicate(true)


func save_to(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(_flags))
	return true


func load_from(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		_flags = data
		return true
	return false


func reset_for_test() -> void:
	_flags.clear()
