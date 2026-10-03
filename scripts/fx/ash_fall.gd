class_name AshFall
extends CanvasLayer
## Black ash drifting down over the scene, between the mists and the lines.
## Flakes live in screen space, wrap at the edges, drift with the mist wind
## and shift with camera motion so they read as part of the world.

const COUNT := 160
const SCREEN := Vector2(640, 360)

var _flakes := PackedVector2Array()
var _speeds := PackedFloat32Array()
var _sizes := PackedFloat32Array()
var _canvas: Node2D
var _last_cam := Vector2.INF
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	layer = CanvasLayers.MIST + 1
	_rng.seed = 7
	for i in COUNT:
		_flakes.append(Vector2(_rng.randf() * SCREEN.x, _rng.randf() * SCREEN.y))
		_speeds.append(_rng.randf_range(14.0, 34.0))
		_sizes.append(1.0 if _rng.randf() < 0.7 else 2.0)
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_flakes)
	add_child(_canvas)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	var cam_pos := cam.get_screen_center_position() if cam else Vector2.ZERO
	var shift := Vector2.ZERO if _last_cam == Vector2.INF else cam_pos - _last_cam
	_last_cam = cam_pos
	var wind := MistField.base_wind(cam_pos)
	for i in COUNT:
		var p := _flakes[i]
		var sway := sin(MistField.time * 1.3 + i) * 4.0
		p += Vector2(wind.x * 0.8 + sway, _speeds[i]) * delta - shift
		p.x = fposmod(p.x, SCREEN.x)
		p.y = fposmod(p.y, SCREEN.y)
		_flakes[i] = p
	_canvas.queue_redraw()


func _draw_flakes() -> void:
	var c := Color(0.05, 0.05, 0.06, 0.85)
	for i in COUNT:
		_canvas.draw_rect(Rect2(_flakes[i].floor(), Vector2(_sizes[i], _sizes[i])), c)
