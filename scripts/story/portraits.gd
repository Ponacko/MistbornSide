class_name Portraits
## Portrait busts for the dialogue frame, rendered by PortraitArt.

const ALIASES := {"bendal": "inquisitor"}


static func draw_bust(canvas: CanvasItem, rect: Rect2, who: String) -> void:
	canvas.draw_rect(rect, Color(0.06, 0.07, 0.1))
	var tex := PortraitArt.texture(ALIASES.get(who, who))
	canvas.draw_texture_rect(tex, Rect2(rect.position, Vector2(PortraitArt.SIZE, PortraitArt.SIZE)), false)
	canvas.draw_rect(rect, Color(0.6, 0.65, 0.75, 0.6), false, 1.0)
