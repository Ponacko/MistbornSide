class_name Hud
extends CanvasLayer
## The in-game HUD (DESIGN.md 12.5): thin metal vials along the bottom left.

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

var vin: Vin
var _canvas: Control


func _ready() -> void:
	layer = CanvasLayers.HUD
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_hud)
	add_child(_canvas)


func _process(_delta: float) -> void:
	if not is_instance_valid(vin):
		vin = get_tree().get_first_node_in_group("player") as Vin
	_canvas.queue_redraw()


func _draw_hud() -> void:
	if vin == null:
		return
	var x := ORIGIN.x
	for m in MetalReserves.Metal.values():
		_vial(Vector2(x, ORIGIN.y), vin.reserves.fraction(m), METAL_COLORS[m])
		x += VIAL_SIZE.x + VIAL_GAP


func _vial(at: Vector2, fill: float, color: Color) -> void:
	var outline := Color(0.75, 0.8, 0.85, 0.5)
	_canvas.draw_rect(Rect2(at, VIAL_SIZE), Color(0.05, 0.06, 0.08, 0.6))
	var h := roundf(VIAL_SIZE.y * fill)
	_canvas.draw_rect(Rect2(at.x, at.y + VIAL_SIZE.y - h, VIAL_SIZE.x, h), color)
	_canvas.draw_rect(Rect2(at, VIAL_SIZE), outline, false, 1.0)
