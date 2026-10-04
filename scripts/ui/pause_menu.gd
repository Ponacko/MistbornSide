class_name PauseMenu
extends CanvasLayer
## Esc pauses: resume, settings, back to the title.

var _root: Control
var _box: VBoxContainer


func _ready() -> void:
	layer = CanvasLayers.MENU
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiKit.theme()
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_box = UiKit.centered_panel(_root, 180)
	var head := Label.new()
	head.text = "Paused"
	_box.add_child(head)
	_box.add_child(UiKit.button("Resume", close))
	_box.add_child(UiKit.button("Settings", _settings))
	_box.add_child(UiKit.button("Title screen", func(): GameFlow.to_title()))
	visible = false


func open() -> void:
	visible = true
	get_tree().paused = true
	(_box.get_node("Resume") as Button).grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func _settings() -> void:
	var s := SettingsScreen.new()
	s.closed.connect(s.queue_free)
	add_child(s)
