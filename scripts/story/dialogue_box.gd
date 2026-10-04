class_name DialogueBox
extends CanvasLayer
## The visual-novel frame for dialogue scenes: portrait, speaker, line,
## choices. Vin waits while it is open. Space, E or a click advance; 1 to 4
## pick a choice.

signal closed

const KIND_COLORS := {"soothe": Color(0.55, 0.75, 1.0), "riot": Color(1.0, 0.55, 0.45)}

var runner := DialogueRunner.new()
var _canvas: Control
var _shown := 0.0
var _vin: Vin


func _ready() -> void:
	add_to_group("dialogue_box")
	layer = CanvasLayers.DIALOGUE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_box)
	add_child(_canvas)
	visible = false


func play_file(path: String, node_id := "") -> bool:
	if not runner.load_file(path):
		return false
	runner.start(node_id)
	_open()
	return true


func is_open() -> bool:
	return visible


func next() -> void:
	if not is_open():
		return
	var line_len: int = str(runner.current().get("text", "")).length()
	if _shown < line_len:
		_shown = line_len
		return
	runner.advance()
	_shown = 0.0
	_after_step()


func pick(index: int) -> void:
	var c: Array = runner.current().get("choices", [])
	if index < c.size():
		runner.choose(index)
		_shown = 0.0
		_after_step()


func _open() -> void:
	visible = true
	_shown = 0.0
	_vin = get_tree().get_first_node_in_group("player") as Vin
	if _vin:
		_vin.lock_input(self)


func _after_step() -> void:
	if runner.finished:
		visible = false
		if _vin:
			_vin.unlock_input(self)
		closed.emit()


func _process(delta: float) -> void:
	if visible:
		_shown += TimeController.real_delta(delta) * 45.0
		_canvas.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			pick(event.keycode - KEY_1)
		elif event.keycode in [KEY_SPACE, KEY_E, KEY_ENTER]:
			next()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		next()
		get_viewport().set_input_as_handled()


func _draw_box() -> void:
	var beat := runner.current()
	if beat.is_empty():
		return
	var frame := Rect2(16, 262, 608, 86)
	_canvas.draw_rect(frame, Color(0.03, 0.035, 0.05, 0.92))
	_canvas.draw_rect(frame, Color(0.45, 0.5, 0.6, 0.6), false, 1.0)
	Portraits.draw_bust(_canvas, Rect2(24, 270, 70, 70), str(beat.portrait))
	var font := ThemeDB.fallback_font
	_canvas.draw_string(font, Vector2(104, 282), str(beat.speaker), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.8, 0.6))
	var text := str(beat.text).substr(0, int(_shown))
	_canvas.draw_multiline_string(font, Vector2(104, 298), text, HORIZONTAL_ALIGNMENT_LEFT, 500, 9, 3, Color(0.88, 0.88, 0.92))
	var y := 318.0
	var i := 0
	for c in beat.choices:
		var kind := str(c.kind)
		var tag := "[%s] " % kind.capitalize() if kind != "" else ""
		var col: Color = KIND_COLORS.get(kind, Color(0.85, 0.85, 0.9))
		_canvas.draw_string(font, Vector2(112 + i * 250, y), "%d  %s%s" % [i + 1, tag, c.text], HORIZONTAL_ALIGNMENT_LEFT, 240, 9, col)
		i += 1
