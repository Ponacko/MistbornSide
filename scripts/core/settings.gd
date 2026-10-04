extends Node
## Autoload "Settings": player-facing comfort and accessibility options
## (DESIGN.md 7.3), saved with the game by SaveGame.

signal changed

## Steelsight: how slow time runs, how long the window stays open.
var steelsight_slow := 0.15
var steelsight_duration := 0.25
var buffer_frames := 6
## How far from the cursor a source can be and still be picked (aim cone).
var aim_cone := 48.0
## 0..1: how strongly heavier metal wins the target.
var aim_assist := 0.5
## With no aim input, pick a target by heuristic.
var auto_target := true
## Celeste-style assist: 20 percent slower time, half damage.
var assist_mode := false
## Push and Pull toggle on a tap instead of acting while held.
var toggle_push := false
## Keep the last target until a new one is chosen.
var sticky_target := false
## Blue lines show even with no steel or iron to burn.
var lines_always := false
var high_contrast_lines := false
var line_thickness := 1.0
## Colour-blind friendly palette for lines and suspicion icons.
var colorblind := false
var screen_shake := 1.0
## Scales full-screen flashes such as the tin whiteout (0 to 1).
var flash_intensity := 1.0
## Remapped keys: action -> physical keycode.
var bindings := {}

const KEYS := ["steelsight_slow", "steelsight_duration", "buffer_frames", "aim_cone", "aim_assist", "auto_target",
	"assist_mode", "toggle_push", "sticky_target", "lines_always", "high_contrast_lines", "line_thickness",
	"colorblind", "screen_shake", "flash_intensity"]

const PALETTES := {
	false: {&"suspicious": Color(0.95, 0.8, 0.3), &"alerted": Color(0.95, 0.35, 0.3), &"lines": Color(0.55, 0.78, 1.0)},
	true: {&"suspicious": Color(0.95, 0.9, 0.95), &"alerted": Color(0.95, 0.6, 0.1), &"lines": Color(0.45, 0.85, 0.95)},
}


func palette_color(key: StringName) -> Color:
	return PALETTES[colorblind][key]


## Pushes the options into the live tuning and the time controller.
func apply() -> void:
	var t := Game.tuning
	t.steelsight_time_scale = steelsight_slow
	t.steelsight_window = steelsight_duration
	t.push_buffer_frames = buffer_frames
	t.aim_snap_radius = aim_cone
	t.aim_mass_weight = 8.0 * aim_assist
	TimeController.set_factor(&"assist", 0.8 if assist_mode else 1.0)
	changed.emit()


func set_option(key: String, value: Variant) -> void:
	set(key, value)
	apply()


## Rebinds an action's keyboard key, keeping its mouse and pad bindings.
func rebind(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		return
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			InputMap.action_erase_event(action, e)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)
	bindings[action] = keycode


func binding(action: String) -> int:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return (e as InputEventKey).physical_keycode
	return 0


func to_dict() -> Dictionary:
	var d := {}
	for k in KEYS:
		d[k] = get(k)
	d["bindings"] = bindings.duplicate()
	return d


func from_dict(d: Dictionary) -> void:
	for k in KEYS:
		if d.has(k):
			set(k, type_convert(d[k], typeof(get(k))))
	for action in d.get("bindings", {}):
		rebind(action, int(d.bindings[action]) as Key)
	apply()


func reset_for_test() -> void:
	steelsight_slow = 0.15
	steelsight_duration = 0.25
	buffer_frames = 6
	aim_cone = 48.0
	aim_assist = 0.5
	auto_target = true
	assist_mode = false
	toggle_push = false
	sticky_target = false
	lines_always = false
	high_contrast_lines = false
	line_thickness = 1.0
	colorblind = false
	screen_shake = 1.0
	flash_intensity = 1.0
	bindings.clear()
