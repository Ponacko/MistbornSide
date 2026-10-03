extends Label
## Frame-rate readout for grey-box testing (toggle with F3).

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	text = "%d fps" % Engine.get_frames_per_second()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		visible = not visible
