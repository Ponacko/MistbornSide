extends SceneTree
## Writes the input map from DESIGN.md section 7.1 (keyboard and mouse, primary)
## and 7.2 (gamepad, parity target) into project.godot. Re-run after editing:
##   godot --headless --path . -s tools/setup_input_map.gd

const KEYS := {
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	"move_up": [KEY_W],
	"move_down": [KEY_S],
	"jump": [KEY_SPACE],
	"flare": [KEY_SHIFT],
	"target_cycle": [KEY_Q],
	"coin": [KEY_E],
	"dagger": [KEY_F],
	"dodge": [KEY_CTRL, KEY_C],
	"toggle_pewter": [KEY_1],
	"toggle_tin": [KEY_2],
	"toggle_copper": [KEY_3],
	"toggle_bronze": [KEY_4],
	"emotion": [KEY_R],
	"atium": [KEY_TAB],
	"duralumin": [KEY_V],
	"pause": [KEY_ESCAPE],
	"journal": [KEY_J],
	"interact": [],
	"target_cycle_back": [],
}

const MOUSE := {
	"push": [MOUSE_BUTTON_LEFT],
	"pull": [MOUSE_BUTTON_RIGHT],
	"target_cycle": [MOUSE_BUTTON_WHEEL_UP],
	"target_cycle_back": [MOUSE_BUTTON_WHEEL_DOWN],
}

const PAD_BUTTONS := {
	"jump": [JOY_BUTTON_A],
	"dagger": [JOY_BUTTON_X],
	"dodge": [JOY_BUTTON_B],
	"interact": [JOY_BUTTON_Y],
	"coin": [JOY_BUTTON_RIGHT_SHOULDER],
	"target_cycle": [JOY_BUTTON_LEFT_SHOULDER],
	"atium": [JOY_BUTTON_LEFT_SHOULDER],
	"toggle_pewter": [JOY_BUTTON_DPAD_UP],
	"toggle_tin": [JOY_BUTTON_DPAD_DOWN],
	"toggle_copper": [JOY_BUTTON_DPAD_LEFT],
	"toggle_bronze": [JOY_BUTTON_DPAD_RIGHT],
	"emotion": [JOY_BUTTON_LEFT_STICK],
	"duralumin": [JOY_BUTTON_RIGHT_STICK],
	"pause": [JOY_BUTTON_START],
	"journal": [JOY_BUTTON_BACK],
}

const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"push": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"pull": [JOY_AXIS_TRIGGER_LEFT, 1.0],
	"aim_left": [JOY_AXIS_RIGHT_X, -1.0],
	"aim_right": [JOY_AXIS_RIGHT_X, 1.0],
	"aim_up": [JOY_AXIS_RIGHT_Y, -1.0],
	"aim_down": [JOY_AXIS_RIGHT_Y, 1.0],
}


func _initialize() -> void:
	var names := {}
	for table in [KEYS, MOUSE, PAD_BUTTONS, PAD_AXES]:
		for action in table:
			names[action] = true
	for action: String in names:
		var events: Array[InputEvent] = []
		for key in KEYS.get(action, []):
			var e := InputEventKey.new()
			e.physical_keycode = key
			events.append(e)
		for button in MOUSE.get(action, []):
			var e := InputEventMouseButton.new()
			e.button_index = button
			events.append(e)
		for button in PAD_BUTTONS.get(action, []):
			var e := InputEventJoypadButton.new()
			e.button_index = button
			events.append(e)
		if PAD_AXES.has(action):
			var e := InputEventJoypadMotion.new()
			e.axis = PAD_AXES[action][0]
			e.axis_value = PAD_AXES[action][1]
			events.append(e)
		for e in events:
			e.device = -1
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": events})
	ProjectSettings.save()
	print("Input map written: %d actions" % names.size())
	quit()
