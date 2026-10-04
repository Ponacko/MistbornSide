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
	var bright := Color(0.6, 0.63, 0.7)
	var dark := Color(0.14, 0.14, 0.16)
	match style:
		Style.NAIL:
			draw_rect(Rect2(-1, -1, 2, 2), bright)
		Style.HINGE:
			draw_rect(Rect2(-2, -3, 4, 6), metal)
			draw_rect(Rect2(-1, -2, 1, 1), bright)
			draw_rect(Rect2(-1, 1, 1, 1), bright)
		Style.BRACKET:
			# A wall bracket: plate, arm and a curl at the end.
			draw_rect(Rect2(-7, -2, 3, 6), dark)
			draw_rect(Rect2(-6, -1, 12, 2), metal)
			draw_rect(Rect2(5, -3, 2, 4), metal)
			draw_rect(Rect2(6, -2, 1, 1), bright)
		Style.LAMP_POST:
			# Cast-iron post with a curled bracket and a dark lamp head.
			if not metal_only:
				draw_rect(Rect2(-1, 0, 3, 80), dark)
				draw_rect(Rect2(-3, 76, 7, 4), dark)
				draw_rect(Rect2(0, 0, 1, 80), Color(0.26, 0.26, 0.3))
			draw_rect(Rect2(-5, -5, 11, 2), metal)
			draw_rect(Rect2(-4, -12, 9, 7), dark)
			draw_rect(Rect2(-3, -11, 7, 5), Color(0.2, 0.2, 0.24))
			draw_rect(Rect2(-2, -14, 5, 2), metal)
			draw_rect(Rect2(-4, -12, 1, 7), bright)
		Style.GATE:
			for i in 6:
				draw_rect(Rect2(-15 + i * 6, -24, 2, 48), metal)
				draw_rect(Rect2(-15 + i * 6, -24, 1, 48), bright)
				draw_colored_polygon(PackedVector2Array([Vector2(-15 + i * 6, -24), Vector2(-14 + i * 6, -28), Vector2(-13 + i * 6, -24)]), bright)
			draw_rect(Rect2(-16, -22, 32, 2), metal)
			draw_rect(Rect2(-16, 0, 32, 2), metal)
			draw_rect(Rect2(-16, 22, 32, 2), metal)
		Style.PLATE:
			draw_rect(Rect2(-12, -3, 24, 6), metal)
			for x in [-10, -4, 2, 8]:
				draw_rect(Rect2(x, -2, 1, 1), bright)
				draw_rect(Rect2(x, 1, 1, 1), bright)
		Style.SPIRE:
			draw_colored_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(0, -40), Vector2(4, 0)]), metal)
			draw_colored_polygon(PackedVector2Array([Vector2(-1, 0), Vector2(0, -40), Vector2(1, 0)]), bright)
