class_name ScreenFx
extends CanvasLayer
## Full-screen feedback over the HUD layer below: the tin whiteout, the pewter
## crash vignette and a hurt flash.

var _canvas: Control
var _vin: Vin
var _hurt := 0.0
var _time := 0.0


func _ready() -> void:
	layer = CanvasLayers.FLASH
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_fx)
	add_child(_canvas)


func _process(delta: float) -> void:
	var real := TimeController.real_delta(delta)
	_time += real
	if not is_instance_valid(_vin):
		_vin = get_tree().get_first_node_in_group("player") as Vin
		if _vin:
			_vin.hurt.connect(func(_h): _hurt = 1.0)
	_hurt = move_toward(_hurt, 0.0, real * 3.0)
	_canvas.queue_redraw()


func _draw_fx() -> void:
	if _vin == null:
		return
	var size := _canvas.size
	var t := Game.tuning
	if _vin.crash_time_left > 0.0:
		var staggering := _vin.crash_time_left > t.crash_slow_seconds
		var strength := 0.55 if staggering else 0.25 * (_vin.crash_time_left / t.crash_slow_seconds)
		strength *= 0.8 + 0.2 * sin(_time * (8.0 if staggering else 3.0))
		_vignette(size, Color(0.25, 0.02, 0.02), strength)
	if _hurt > 0.0:
		_vignette(size, Color(0.6, 0.05, 0.05), _hurt * 0.4)
	if _vin.senses.whiteout > 0.0:
		var a := _vin.senses.whiteout * Settings.flash_intensity
		_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 0.96, a))


## A soft frame of colour, thickest at the edges.
func _vignette(size: Vector2, color: Color, strength: float) -> void:
	var bands := 8
	for i in bands:
		var inset := i * 6.0
		var c := Color(color, strength * (1.0 - float(i) / bands) * 0.5)
		var r := Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0)
		_canvas.draw_rect(r, c, false, 6.0)
