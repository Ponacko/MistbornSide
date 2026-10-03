@tool
class_name MetalProp
extends Node2D
## Fixed metal in the level: pick a style and place it. Each style has the mass
## DESIGN.md 5.2 implies; the metal source is created at runtime.

enum Style { NAIL, BRACKET, LAMP_POST, GATE, PLATE, HINGE, SPIRE }

const MASS := {
	Style.NAIL: 0.05, Style.BRACKET: 6.0, Style.LAMP_POST: 300.0, Style.GATE: 800.0,
	Style.PLATE: 60.0, Style.HINGE: 1.5, Style.SPIRE: 2000.0,
}

@export var style := Style.BRACKET:
	set(value):
		style = value
		queue_redraw()
## Draw only the metal, not the post or gate around it (for art passes).
@export var metal_only := false

var source: MetalSource


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	source = MetalSource.new()
	source.mass = MASS[style]
	source.kind = MetalSource.Kind.ANCHORED
	add_child(source)


func _draw() -> void:
	var metal := Color(0.42, 0.45, 0.5)
	var dark := Color(0.2, 0.2, 0.22)
	match style:
		Style.NAIL:
			draw_rect(Rect2(-1, -1, 2, 2), metal)
		Style.HINGE:
			draw_rect(Rect2(-2, -3, 4, 6), metal)
		Style.BRACKET:
			draw_rect(Rect2(-6, -1, 12, 3), metal)
			draw_rect(Rect2(-6, -1, 2, 8), metal)
		Style.LAMP_POST:
			if not metal_only:
				draw_rect(Rect2(-1, 0, 3, 80), dark)
			draw_rect(Rect2(-4, -6, 9, 7), metal)
		Style.GATE:
			for i in 6:
				draw_rect(Rect2(-15 + i * 6, -24, 2, 48), metal)
			draw_rect(Rect2(-16, -24, 32, 2), metal)
			draw_rect(Rect2(-16, 22, 32, 2), metal)
		Style.PLATE:
			draw_rect(Rect2(-12, -3, 24, 6), metal)
		Style.SPIRE:
			draw_colored_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(0, -40), Vector2(4, 0)]), metal)
