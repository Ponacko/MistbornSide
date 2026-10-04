class_name Portraits
## Placeholder busts for the dialogue frame, drawn with the same palette as
## the characters' sprites until the art pass supplies portrait crops.

const LOOKS := {
	"vin": [Color(0.86, 0.72, 0.62), Color(0.08, 0.07, 0.08), Color(0.3, 0.3, 0.34)],
	"kelsier": [Color(0.86, 0.73, 0.6), Color(0.86, 0.76, 0.45), Color(0.22, 0.22, 0.26)],
	"camon": [Color(0.8, 0.65, 0.55), Color(0.3, 0.25, 0.2), Color(0.45, 0.35, 0.25)],
	"sazed": [Color(0.7, 0.55, 0.45), Color(0.7, 0.55, 0.45), Color(0.5, 0.25, 0.2)],
}


static func draw_bust(canvas: CanvasItem, rect: Rect2, who: String) -> void:
	var look: Array = LOOKS.get(who, [Color(0.8, 0.7, 0.6), Color(0.3, 0.3, 0.3), Color(0.35, 0.35, 0.4)])
	canvas.draw_rect(rect, Color(0.06, 0.07, 0.1))
	var c := rect.get_center()
	canvas.draw_rect(Rect2(c + Vector2(-18, 8), Vector2(36, rect.size.y / 2.0 - 8)), look[2])
	canvas.draw_rect(Rect2(c + Vector2(-11, -20), Vector2(22, 28)), look[0])
	canvas.draw_rect(Rect2(c + Vector2(-12, -22), Vector2(24, 7)), look[1])
	canvas.draw_rect(Rect2(c + Vector2(-6, -8), Vector2(3, 3)), Color.BLACK)
	canvas.draw_rect(Rect2(c + Vector2(4, -8), Vector2(3, 3)), Color.BLACK)
	canvas.draw_rect(Rect2(rect.position, rect.size), Color(0.6, 0.65, 0.75, 0.6), false, 1.0)
