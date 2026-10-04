class_name BlueLines
extends Node2D
## Draws Vin's blue lines on their own canvas layer, above the mists and below
## the HUD (DESIGN.md 5.3).

const ARROW_MIN := 5.0
const ARROW_SPAN := 26.0

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
		# A coin can be pouched between the physics frame and this draw.
		if not is_instance_valid(line.source):
			continue
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
		var color := line_color(a)
		draw_line(chest, to, color, w * width_scale(), true)
		if is_target:
			_glyph(to, color)
			_preview_arrows(chest, to, line.source)
		elif allomancer.cycle_candidates.has(line.source):
			draw_arc(to, 3.0, 0.0, TAU, 8, Color(BlueLineStyle.COLOR, 0.6), 1.0, true)
	if allomancer.shows_arc():
		_arc(allomancer.predicted_arc())


func _arc(points: PackedVector2Array) -> void:
	var color := Color(BlueLineStyle.COLOR, 0.35)
	for i in range(0, points.size() - 1, 3):
		draw_line(points[i], points[i + 1], color, 1.0, true)


## Two arrows scaled by the mass ratio: long on whichever side will move.
func _preview_arrows(chest: Vector2, to: Vector2, source: MetalSource) -> void:
	var away := (to - chest).normalized()
	var pulling := allomancer.vin.controls.pull_held and not allomancer.vin.controls.push_held
	var on_target := -away if pulling else away
	var s := PushPreview.shares(source, on_target, Game.tuning.vin_mass)
	_arrow(chest, -on_target, ARROW_MIN + ARROW_SPAN * s.vin)
	_arrow(to, on_target, ARROW_MIN + ARROW_SPAN * s.target)


func _arrow(from: Vector2, dir: Vector2, length: float) -> void:
	var tip := from + dir * length
	var color := Color(0.85, 0.93, 1.0, 0.9)
	draw_line(from, tip, color, 1.0, true)
	draw_line(tip, tip - dir.rotated(0.5) * 4.0, color, 1.0, true)
	draw_line(tip, tip - dir.rotated(-0.5) * 4.0, color, 1.0, true)


## Line colour for an alpha, honouring the palette and high-contrast option.
static func line_color(alpha: float) -> Color:
	var c := Settings.palette_color(&"lines")
	if Settings.high_contrast_lines:
		c = c.lightened(0.35)
		alpha = clampf(alpha * 1.6 + 0.25, 0.0, 1.0)
	c.a = clampf(alpha, 0.0, 1.0)
	return c


static func width_scale() -> float:
	return Settings.line_thickness


func _glyph(at: Vector2, color: Color) -> void:
	var r := 4.0
	var pts := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0), at + Vector2(0, -r)])
	draw_polyline(pts, Color(color, 1.0), 1.0, true)
