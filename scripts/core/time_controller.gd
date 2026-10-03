extends Node
## Autoload "TimeController": the single owner of Engine.time_scale. Systems
## set named factors (Steelsight, atium, the assist preset) that multiply;
## a boss fight can push an override that wins over all of them. Audio pitch
## always follows time (DESIGN.md 14).

var _factors := {}
var _overrides: Array[float] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_factor(key: StringName, value: float) -> void:
	if is_equal_approx(value, 1.0):
		_factors.erase(key)
	else:
		_factors[key] = value
	_apply()


func clear_factor(key: StringName) -> void:
	_factors.erase(key)
	_apply()


func factor(key: StringName) -> float:
	return _factors.get(key, 1.0)


func push_override(scale: float) -> void:
	_overrides.append(scale)
	_apply()


func pop_override() -> void:
	if not _overrides.is_empty():
		_overrides.pop_back()
	_apply()


func effective() -> float:
	if not _overrides.is_empty():
		return _overrides[-1]
	var s := 1.0
	for v in _factors.values():
		s *= v
	return s


## Converts a scaled frame delta back to real seconds (HUD, cursor, timers
## that must run at full speed during Steelsight).
func real_delta(delta: float) -> float:
	return delta / maxf(Engine.time_scale, 0.0001)


func _apply() -> void:
	var s := effective()
	Engine.time_scale = s
	AudioServer.playback_speed_scale = s


func reset_for_test() -> void:
	_factors.clear()
	_overrides.clear()
	_apply()
