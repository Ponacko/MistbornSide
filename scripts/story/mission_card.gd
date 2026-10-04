class_name MissionCard
extends CanvasLayer
## A title card over a dark band: mission titles, endings, and the bridging
## cards between missions.

signal dismissed

@export var text := ""
@export var subtitle := ""
@export var body := ""
## Seconds before it fades on its own; 0 waits for a key.
@export var hold := 3.0

var _t := 0.0
var _canvas: Control


func _ready() -> void:
	layer = CanvasLayers.DIALOGUE + 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_card)
	add_child(_canvas)


func _process(delta: float) -> void:
	_t += TimeController.real_delta(delta)
	_canvas.queue_redraw()
	if hold > 0.0 and _t > hold + 1.0:
		dismiss()


func _unhandled_input(event: InputEvent) -> void:
	if hold <= 0.0 and _t > 0.5 and (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		dismiss()
		get_viewport().set_input_as_handled()


func dismiss() -> void:
	if is_queued_for_deletion():
		return
	dismissed.emit()
	queue_free()


func _draw_card() -> void:
	var a := clampf(_t / 0.6, 0.0, 1.0)
	if hold > 0.0:
		a *= clampf(hold + 1.0 - _t, 0.0, 1.0)
	var size := _canvas.size
	var band := Rect2(0, size.y * 0.5 - 50, size.x, 100) if body == "" else Rect2(Vector2.ZERO, size)
	_canvas.draw_rect(band, Color(0.01, 0.01, 0.02, 0.85 * a))
	var font := ThemeDB.fallback_font
	var y := band.get_center().y - (10.0 if body == "" else 60.0)
	_canvas.draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color(0.9, 0.86, 0.75, a))
	_canvas.draw_string(font, Vector2(0, y + 18), subtitle, HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, Color(0.7, 0.72, 0.8, a))
	if body != "":
		_canvas.draw_multiline_string(font, Vector2(90, y + 44), body, HORIZONTAL_ALIGNMENT_CENTER, size.x - 180, 9, -1, Color(0.82, 0.82, 0.86, a))
