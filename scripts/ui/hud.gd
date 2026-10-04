class_name Hud
extends CanvasLayer
## The in-game HUD (DESIGN.md 12.5), minimal and quiet: eight thin metal
## vials along the bottom left, atium beads beside them, the coin count, a
## thin health bar that fades away when full, and a faint warm (pewter) or
## cool (tin) tint at the screen edge instead of toggle icons.

const VIAL_SIZE := Vector2(4, 22)
const VIAL_GAP := 3.0
const ORIGIN := Vector2(10, 330)
const METAL_COLORS := {
	MetalReserves.Metal.STEEL: Color(0.62, 0.78, 0.95),
	MetalReserves.Metal.IRON: Color(0.55, 0.6, 0.72),
	MetalReserves.Metal.TIN: Color(0.85, 0.88, 0.92),
	MetalReserves.Metal.PEWTER: Color(0.78, 0.72, 0.6),
	MetalReserves.Metal.ZINC: Color(0.7, 0.85, 0.8),
	MetalReserves.Metal.BRASS: Color(0.9, 0.75, 0.4),
	MetalReserves.Metal.COPPER: Color(0.85, 0.5, 0.3),
	MetalReserves.Metal.BRONZE: Color(0.75, 0.55, 0.3),
}
const PEWTER_TINT := Color(0.95, 0.6, 0.3, 0.16)
const TIN_TINT := Color(0.5, 0.7, 1.0, 0.16)

var vin: Vin
## 0..1: the health bar shows when hurt and fades out once healed.
var health_alpha := 0.0
## Which metals the HUD shows; a story beat (the first vial) reveals them.
var revealed_metals := 8
var _canvas: Control


func _ready() -> void:
	layer = CanvasLayers.HUD
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_hud)
	add_child(_canvas)


func _process(delta: float) -> void:
	if not is_instance_valid(vin):
		vin = get_tree().get_first_node_in_group("player") as Vin
	if vin:
		var real := TimeController.real_delta(delta)
		var hurt := vin.health.current < vin.health.max_health - 0.5
		health_alpha = move_toward(health_alpha, 1.0 if hurt else 0.0, real * (6.0 if hurt else 1.2))
	_canvas.queue_redraw()


## The screen-edge tint for burning pewter (warm) and tin (cool).
func edge_tint() -> Color:
	if vin == null:
		return Color(0, 0, 0, 0)
	if vin.pewter_on and vin.tin_on:
		return PEWTER_TINT.lerp(TIN_TINT, 0.5)
	if vin.pewter_on:
		return PEWTER_TINT
	if vin.tin_on:
		return TIN_TINT
	return Color(0, 0, 0, 0)


func _draw_hud() -> void:
	if vin == null:
		return
	var size := _canvas.size
	var tint := edge_tint()
	if tint.a > 0.0:
		for i in 6:
			var inset := i * 4.0
			_canvas.draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0), Color(tint, tint.a * (1.0 - i / 6.0)), false, 4.0)
	var x := ORIGIN.x
	var shown := 0
	for m in MetalReserves.Metal.values():
		if shown >= revealed_metals:
			break
		_vial(Vector2(x, ORIGIN.y), vin.reserves.fraction(m), METAL_COLORS[m])
		x += VIAL_SIZE.x + VIAL_GAP
		shown += 1
	x += 4.0
	for i in vin.atium_beads:
		_canvas.draw_circle(Vector2(x + 2.5, ORIGIN.y + VIAL_SIZE.y - 3), 2.5, Color(0.9, 0.92, 0.95))
		_canvas.draw_circle(Vector2(x + 2.0, ORIGIN.y + VIAL_SIZE.y - 3.5), 0.8, Color(1, 1, 1))
		x += 7.0
	x += 4.0
	var font := ThemeDB.fallback_font
	_canvas.draw_rect(Rect2(x, ORIGIN.y + VIAL_SIZE.y - 5, 5, 4), Color(0.8, 0.55, 0.35))
	_canvas.draw_string(font, Vector2(x + 8, ORIGIN.y + VIAL_SIZE.y), str(vin.pouch.count), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.85, 0.85, 0.9, 0.85))
	if health_alpha > 0.01:
		var w := 90.0
		var at := Vector2(ORIGIN.x, ORIGIN.y - 8)
		_canvas.draw_rect(Rect2(at, Vector2(w, 2)), Color(0.1, 0.1, 0.12, 0.6 * health_alpha))
		_canvas.draw_rect(Rect2(at, Vector2(w * vin.health.fraction(), 2)), Color(0.75, 0.2, 0.2, 0.9 * health_alpha))
	if CourseClock.started:
		var text := "%d:%05.2f" % [int(CourseClock.elapsed) / 60, fmod(CourseClock.elapsed, 60.0)]
		_canvas.draw_string(font, Vector2(560, 14), text, HORIZONTAL_ALIGNMENT_RIGHT, 72, 8, Color(0.9, 0.9, 0.95, 0.9 if CourseClock.running else 0.5))


func _vial(at: Vector2, fill: float, color: Color) -> void:
	var outline := Color(0.75, 0.8, 0.85, 0.5)
	_canvas.draw_rect(Rect2(at, VIAL_SIZE), Color(0.05, 0.06, 0.08, 0.6))
	var h := roundf(VIAL_SIZE.y * fill)
	_canvas.draw_rect(Rect2(at.x, at.y + VIAL_SIZE.y - h, VIAL_SIZE.x, h), color)
	_canvas.draw_rect(Rect2(at, VIAL_SIZE), outline, false, 1.0)
