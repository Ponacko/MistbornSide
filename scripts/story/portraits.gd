class_name Portraits
## Portrait busts for the dialogue frame: the character's own CharacterArt
## sprite, head and shoulders, scaled up on a dark card. Characters without
## a sprite (Camon, Sazed) get a palette-only placeholder bust.

const LOOKS := {
	"camon": [Color(0.8, 0.65, 0.55), Color(0.3, 0.25, 0.2), Color(0.45, 0.35, 0.25)],
	"sazed": [Color(0.7, 0.55, 0.45), Color(0.7, 0.55, 0.45), Color(0.5, 0.25, 0.2)],
}
const SPRITES := {"vin": "vin", "kelsier": "kelsier", "guard": "guard", "obligator": "obligator", "inquisitor": "inquisitor", "bendal": "inquisitor"}


static func draw_bust(canvas: CanvasItem, rect: Rect2, who: String) -> void:
	canvas.draw_rect(rect, Color(0.06, 0.07, 0.1))
	if SPRITES.has(who):
		var tex := CharacterArt.texture(SPRITES[who], "idle", 0)
		var zoom := 3.0
		# Head and shoulders: the top of the figure, feet at ORIGIN.
		var height := CharacterArt.silhouette_height(SPRITES[who], "idle")
		var top := CharacterArt.ORIGIN.y - height
		var src := Rect2(CharacterArt.ORIGIN.x - 11, top - 2, 22, 22)
		var dst := Rect2(rect.get_center() - src.size * zoom * 0.5 + Vector2(0, 6), src.size * zoom)
		canvas.draw_texture_rect_region(tex, dst, src)
	else:
		var look: Array = LOOKS.get(who, [Color(0.8, 0.7, 0.6), Color(0.3, 0.3, 0.3), Color(0.35, 0.35, 0.4)])
		var c := rect.get_center()
		canvas.draw_rect(Rect2(c + Vector2(-18, 8), Vector2(36, rect.size.y / 2.0 - 8)), look[2])
		canvas.draw_rect(Rect2(c + Vector2(-11, -20), Vector2(22, 28)), look[0])
		canvas.draw_rect(Rect2(c + Vector2(-12, -22), Vector2(24, 7)), look[1])
		canvas.draw_rect(Rect2(c + Vector2(-6, -8), Vector2(3, 3)), Color.BLACK)
		canvas.draw_rect(Rect2(c + Vector2(4, -8), Vector2(3, 3)), Color.BLACK)
	canvas.draw_rect(rect, Color(0.6, 0.65, 0.75, 0.6), false, 1.0)
