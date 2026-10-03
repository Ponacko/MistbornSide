class_name BlueLines
extends Node2D
## Draws Vin's blue lines on their own canvas layer, above the mists and below
## the HUD (DESIGN.md 5.3).

var allomancer: Allomancer
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if allomancer == null:
		return
	var f := Engine.get_physics_interpolation_fraction()
	var chest := allomancer.interpolated_chest(f)
	var pulse := 0.75 + 0.25 * sin(_time * 6.0)
	for line in allomancer.lines:
		var to := allomancer.interpolated_position(line.id, f)
		var is_target: bool = line.source == allomancer.target
		var a: float = line.alpha
		var w: float = line.width
		if line.carried:
			a *= pulse
		if line.inside_body:
			a *= 0.35
		if is_target:
			a = maxf(a, 0.8) * 1.15
			w = w * 1.6 + 0.6
		var color := BlueLineStyle.COLOR
		color.a = clampf(a, 0.0, 1.0)
		draw_line(chest, to, color, w, true)
		if is_target:
			_glyph(to, color)


func _glyph(at: Vector2, color: Color) -> void:
	var r := 4.0
	var pts := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0), at + Vector2(0, -r)])
	draw_polyline(pts, Color(color, 1.0), 1.0, true)
