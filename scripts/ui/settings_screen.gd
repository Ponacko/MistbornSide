class_name SettingsScreen
extends CanvasLayer
## Every accessibility and comfort option from DESIGN.md 7.3, plus key
## remapping. Changes apply at once and are saved on close.

signal closed

const SLIDERS := {
	"steelsight_slow": ["Steelsight time scale", 0.05, 1.0, 0.05],
	"steelsight_duration": ["Steelsight window (s)", 0.1, 1.0, 0.05],
	"buffer_frames": ["Push buffer (frames)", 0, 15, 1],
	"aim_cone": ["Aim cone (px)", 16.0, 120.0, 4.0],
	"aim_assist": ["Aim assist strength", 0.0, 1.0, 0.1],
	"line_thickness": ["Line thickness", 0.5, 3.0, 0.25],
	"screen_shake": ["Screen shake", 0.0, 1.0, 0.1],
	"flash_intensity": ["Flash intensity", 0.0, 1.0, 0.1],
}
const TOGGLES := {
	"auto_target": "Auto-target with no aim input",
	"assist_mode": "Assist: slower time, half damage",
	"toggle_push": "Push and Pull toggle on tap",
	"sticky_target": "Sticky target",
	"lines_always": "Always show blue lines",
	"high_contrast_lines": "High-contrast lines",
	"colorblind": "Colour-blind palette",
}
const REBINDABLE := ["jump", "coin", "dagger", "dodge", "toggle_pewter", "toggle_tin", "toggle_copper", "toggle_bronze", "atium", "flare", "target_cycle"]

var _options := {}
var _rebinds := {}
var _waiting := ""


func _ready() -> void:
	layer = CanvasLayers.MENU + 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiKit.theme()
	add_child(root)
	var box := UiKit.centered_panel(root, 420)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	scroll.add_child(grid)
	for key in SLIDERS:
		var spec: Array = SLIDERS[key]
		grid.add_child(_label(spec[0]))
		var s := HSlider.new()
		s.min_value = spec[1]
		s.max_value = spec[2]
		s.step = spec[3]
		s.value = Settings.get(key)
		s.custom_minimum_size.x = 160
		var k: String = key
		s.value_changed.connect(func(v): Settings.set_option(k, int(v) if k == "buffer_frames" else v))
		grid.add_child(s)
		_options[key] = s
	for key in TOGGLES:
		grid.add_child(_label(TOGGLES[key]))
		var c := CheckBox.new()
		c.button_pressed = Settings.get(key)
		var k: String = key
		c.toggled.connect(func(on): Settings.set_option(k, on))
		grid.add_child(c)
		_options[key] = c
	for action in REBINDABLE:
		grid.add_child(_label("Key: " + action))
		var b := Button.new()
		b.text = OS.get_keycode_string(Settings.binding(action))
		b.pressed.connect(_start_rebind.bind(action, b))
		grid.add_child(b)
		_rebinds[action] = b
	box.add_child(UiKit.button("Back", close))


func _start_rebind(action: String, b: Button) -> void:
	_waiting = action
	b.text = "press a key"


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 200
	return l


func has_option(key: String) -> bool:
	return _options.has(key)


func has_rebind(action: String) -> bool:
	return _rebinds.has(action)


func _input(event: InputEvent) -> void:
	if _waiting != "" and event is InputEventKey and event.pressed:
		Settings.rebind(_waiting, (event as InputEventKey).physical_keycode)
		(_rebinds[_waiting] as Button).text = OS.get_keycode_string((event as InputEventKey).physical_keycode)
		_waiting = ""
		get_viewport().set_input_as_handled()


func close() -> void:
	SaveGame.save()
	closed.emit()
