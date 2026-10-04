class_name PortraitArt
## Dialogue portraits drawn at portrait size (not a zoomed sprite): a bust
## with shoulders, neck, a shaped head, hair or helm, eyes with iris and
## highlight, brows, nose, mouth, cheek shading and each character's
## marks, following the world-and-visuals note. Cached per character.

const SIZE := 70
const ORIGIN := Vector2(35, 70)

const LOOKS := {
	"vin": {"skin": Color(0.86, 0.72, 0.62), "hair": Color(0.07, 0.06, 0.08), "eyes": Color(0.35, 0.3, 0.25), "cloth": Color(0.27, 0.27, 0.31),
		"hair_style": "short", "jaw": 0.86, "brow": "wary", "sash": true},
	"kelsier": {"skin": Color(0.86, 0.73, 0.6), "hair": Color(0.86, 0.76, 0.45), "eyes": Color(0.3, 0.45, 0.6), "cloth": Color(0.3, 0.3, 0.34),
		"hair_style": "spiky", "jaw": 1.0, "brow": "raised", "smile": true, "cloak": true},
	"camon": {"skin": Color(0.78, 0.62, 0.52), "hair": Color(0.3, 0.24, 0.18), "eyes": Color(0.3, 0.25, 0.2), "cloth": Color(0.42, 0.32, 0.24),
		"hair_style": "receding", "jaw": 1.12, "brow": "heavy", "beard": true, "scar": true},
	"sazed": {"skin": Color(0.66, 0.5, 0.4), "hair": Color(0.66, 0.5, 0.4), "eyes": Color(0.2, 0.15, 0.12), "cloth": Color(0.5, 0.22, 0.2),
		"hair_style": "bald", "jaw": 0.95, "long": true, "brow": "calm", "earrings": true, "vrobe": true},
	"guard": {"skin": Color(0.8, 0.66, 0.55), "hair": Color(0.3, 0.24, 0.18), "eyes": Color(0.3, 0.25, 0.2), "cloth": Color(0.45, 0.34, 0.27),
		"hair_style": "helm", "jaw": 1.02, "brow": "heavy", "breastplate": true},
	"obligator": {"skin": Color(0.82, 0.7, 0.6), "hair": Color(0.82, 0.7, 0.6), "eyes": Color(0.3, 0.3, 0.35), "cloth": Color(0.46, 0.46, 0.5),
		"hair_style": "bald", "jaw": 0.92, "brow": "calm", "tattoos": true},
	"inquisitor": {"skin": Color(0.72, 0.66, 0.65), "hair": Color(0.72, 0.66, 0.65), "eyes": Color(0, 0, 0), "cloth": Color(0.1, 0.09, 0.11),
		"hair_style": "bald", "jaw": 1.0, "brow": "none", "spikes": true},
}

const METAL := Color(0.62, 0.65, 0.7)
const METAL_BRIGHT := Color(0.82, 0.85, 0.9)

static var _cache := {}


static func texture(who: String) -> ImageTexture:
	var key := who if LOOKS.has(who) else "unknown"
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_render(key))
	return _cache[key]


static func _render(who: String) -> Image:
	var look: Dictionary = LOOKS.get(who, {"skin": Color(0.8, 0.7, 0.6), "hair": Color(0.3, 0.3, 0.3), "eyes": Color(0.3, 0.3, 0.3), "cloth": Color(0.35, 0.35, 0.4), "hair_style": "short", "jaw": 1.0, "brow": "calm"})
	var c := PixelPainter.new(SIZE, SIZE, ORIGIN)
	var skin: Color = look.skin
	var skin_d := skin.darkened(0.28)
	var cloth: Color = look.cloth
	var head_c := Vector2(0, -42)
	var rx := 11.5
	var ry := 14.0 if not look.get("long", false) else 15.5
	var jaw: float = look.jaw

	# Shoulders and clothing.
	c.poly(PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(19, -20), Vector2(8, -25), Vector2(-8, -25), Vector2(-19, -20)]), cloth)
	if look.get("cloak", false):
		c.poly(PackedVector2Array([Vector2(-32, 0), Vector2(-20, -22), Vector2(-14, -18), Vector2(-22, 0)]), cloth.darkened(0.3))
		c.poly(PackedVector2Array([Vector2(32, 0), Vector2(20, -22), Vector2(14, -18), Vector2(22, 0)]), cloth.darkened(0.3))
	if look.get("vrobe", false):
		for k in 3:
			var y0 := -22.0 + k * 7.0
			c.line(Vector2(-16, y0 + 6), Vector2(0, y0), 1.0, Color(0.85, 0.75, 0.55))
			c.line(Vector2(0, y0), Vector2(16, y0 + 6), 1.0, Color(0.85, 0.75, 0.55))
	if look.get("sash", false):
		c.line(Vector2(-14, -22), Vector2(10, -2), 2.0, Color(0.15, 0.14, 0.16))
		for k in 3:
			c.line(Vector2(-10 + k * 7, -19 + k * 6), Vector2(-9 + k * 7, -16 + k * 6), 1.0, Color(0.75, 0.85, 0.95))
	if look.get("breastplate", false):
		c.poly(PackedVector2Array([Vector2(-22, 0), Vector2(22, 0), Vector2(16, -19), Vector2(0, -24), Vector2(-16, -19)]), METAL, true)
		c.line(Vector2(-6, -18), Vector2(-4, -3), 1.2, METAL_BRIGHT, true)
	# Neck.
	c.poly(PackedVector2Array([Vector2(-5, -24), Vector2(5, -24), Vector2(5, -34), Vector2(-5, -34)]), skin_d)
	c.poly(PackedVector2Array([Vector2(-4, -26), Vector2(4, -26), Vector2(4, -34), Vector2(-4, -34)]), skin)
	# Head: cranium and jaw.
	c.ellipse(head_c, rx, ry, skin)
	c.ellipse(head_c + Vector2(0, ry * 0.45), rx * 0.78 * jaw, ry * 0.6, skin)
	if look.get("long", false):
		c.ellipse(head_c + Vector2(0, ry * 0.3), rx * 0.95, ry * 0.75, skin)
	# Ears.
	c.ellipse(head_c + Vector2(-rx - 0.5, 1), 2.0, 3.0, skin_d)
	c.ellipse(head_c + Vector2(rx + 0.5, 1), 2.0, 3.0, skin_d)
	c.ellipse(head_c + Vector2(-rx - 0.5, 1), 1.0, 2.0, skin)
	c.ellipse(head_c + Vector2(rx + 0.5, 1), 1.0, 2.0, skin)
	if look.get("earrings", false):
		c.px(head_c + Vector2(-rx - 1, 4), METAL_BRIGHT, true)
		c.px(head_c + Vector2(rx + 1, 4), METAL_BRIGHT, true)
	# Shadow down the left of the face (light from the right).
	for k in 4:
		c.line(head_c + Vector2(-rx + 1 + k, -ry * 0.3), head_c + Vector2(-rx * 0.5 + k, ry * 0.75), 0.6, skin.darkened(0.12 - k * 0.025))
	# Hair.
	var hair: Color = look.hair
	match look.hair_style:
		"short":
			c.ellipse(head_c + Vector2(0, -4), rx + 1.0, ry * 0.78, hair)
			c.ellipse(head_c + Vector2(0, 2), rx * 0.9, ry * 0.86, skin)
			# Fringe falling across the forehead, longer on one side.
			c.poly(PackedVector2Array([Vector2(-11, -52), Vector2(2, -54), Vector2(10, -50), Vector2(5, -46), Vector2(-3, -48), Vector2(-9, -44)]) , hair)
			c.line(head_c + Vector2(-rx + 1, -6), head_c + Vector2(-rx + 2, 6), 1.5, hair)
			c.line(head_c + Vector2(rx - 1, -6), head_c + Vector2(rx - 2, 2), 1.2, hair)
		"spiky":
			c.ellipse(head_c + Vector2(0, -5), rx + 1.0, ry * 0.7, hair)
			c.ellipse(head_c + Vector2(0, 2), rx * 0.92, ry * 0.86, skin)
			for k in 6:
				var x0 := -9.0 + k * 3.6
				c.line(head_c + Vector2(x0, -ry * 0.55), head_c + Vector2(x0 + 2.0, -ry - 3.0 - (k % 2) * 2.0), 1.1, hair)
			c.poly(PackedVector2Array([Vector2(-10, -51), Vector2(-2, -53), Vector2(4, -50), Vector2(-2, -47), Vector2(-8, -46)]), hair)
		"receding":
			c.ellipse(head_c + Vector2(0, -3), rx + 0.5, ry * 0.6, hair)
			c.ellipse(head_c + Vector2(0, -1), rx * 0.8, ry * 0.7, skin)
			c.line(head_c + Vector2(-rx, -4), head_c + Vector2(-rx + 1, 6), 1.6, hair)
			c.line(head_c + Vector2(rx, -4), head_c + Vector2(rx - 1, 6), 1.6, hair)
		"helm":
			c.ellipse(head_c + Vector2(0, -5), rx + 2.0, ry * 0.78, METAL, true)
			c.ellipse(head_c + Vector2(0, 3), rx * 0.86, ry * 0.8, skin)
			c.poly(PackedVector2Array([Vector2(-1.5, -52), Vector2(1.5, -52), Vector2(1.5, -37), Vector2(-1.5, -37)]), METAL.darkened(0.1), true)
			c.line(head_c + Vector2(-rx - 2, -2), head_c + Vector2(rx + 2, -2), 1.0, METAL.darkened(0.3), true)
			c.line(head_c + Vector2(-4, -ry - 2), head_c + Vector2(4, -ry - 2), 0.8, METAL_BRIGHT, true)
		"bald":
			c.ellipse(head_c + Vector2(3, -ry * 0.6), 3.0, 1.5, skin.lightened(0.2))
	# Beard.
	if look.get("beard", false):
		c.ellipse(head_c + Vector2(0, ry * 0.55), rx * 0.8, ry * 0.5, hair)
		c.ellipse(head_c + Vector2(0, ry * 0.3), rx * 0.42, 2.0, skin)
	# Eyes.
	var eye_y := head_c.y - 1.0
	for side: float in [-1.0, 1.0]:
		var ex := head_c.x + side * 5.0
		c.ellipse(Vector2(ex, eye_y), 2.6, 1.6, Color(0.95, 0.95, 0.97))
		if not look.get("spikes", false):
			c.disc(Vector2(ex + 0.3, eye_y), 1.3, look.eyes)
			c.px(Vector2(ex + 0.5, eye_y), Color(0.02, 0.02, 0.03))
			c.px(Vector2(ex - 0.5, eye_y - 1), Color(1, 1, 1))
		# Upper lid.
		c.line(Vector2(ex - 2.6, eye_y - 1.6), Vector2(ex + 2.6, eye_y - 1.6), 0.5, skin_d.darkened(0.4))
	if look.get("spikes", false):
		for side: float in [-1.0, 1.0]:
			var ex := head_c.x + side * 5.0
			c.disc(Vector2(ex, eye_y), 2.4, Color(0.2, 0.06, 0.06))
			c.disc(Vector2(ex, eye_y), 1.6, METAL, true)
			c.px(Vector2(ex - 0.5, eye_y - 0.5), METAL_BRIGHT, true)
			c.line(Vector2(ex, eye_y + 2), Vector2(ex + side * 0.5, eye_y + 8), 0.6, Color(0.3, 0.08, 0.08))
		# Head spikes seen past the skull.
		for dy: float in [-8.0, -3.0]:
			c.line(head_c + Vector2(-rx, dy), head_c + Vector2(-rx - 8, dy - 3), 1.2, METAL, true)
			c.line(head_c + Vector2(rx, dy), head_c + Vector2(rx + 8, dy - 3), 1.2, METAL, true)
	# Brows.
	var brow_c := hair.darkened(0.3) if look.hair_style != "bald" and look.hair_style != "helm" else skin_d.darkened(0.3)
	if look.get("tattoos", false):
		brow_c = skin_d.darkened(0.2)
	for side: float in [-1.0, 1.0]:
		var ex := head_c.x + side * 5.0
		match look.get("brow", "calm"):
			"wary":
				c.line(Vector2(ex - side * 2.5, eye_y - 4.5), Vector2(ex + side * 2.5, eye_y - 3.2), 0.7, brow_c)
			"raised":
				c.line(Vector2(ex - side * 2.5, eye_y - 3.5), Vector2(ex + side * 2.5, eye_y - 5.0), 0.7, brow_c)
			"heavy":
				c.line(Vector2(ex - 3.0, eye_y - 3.6), Vector2(ex + 3.0, eye_y - 3.6), 1.1, brow_c)
			"calm":
				c.line(Vector2(ex - 2.5, eye_y - 4.0), Vector2(ex + 2.5, eye_y - 4.0), 0.6, brow_c)
	if look.get("tattoos", false):
		var ink := Color(0.22, 0.26, 0.45)
		for side: float in [-1.0, 1.0]:
			var ex := head_c.x + side * 5.0
			c.line(Vector2(ex + side * 3.0, eye_y - 1), Vector2(ex + side * 7.0, eye_y - 4), 0.5, ink)
			c.line(Vector2(ex + side * 3.0, eye_y + 1), Vector2(ex + side * 7.0, eye_y + 3), 0.5, ink)
			c.line(Vector2(ex, eye_y + 2.5), Vector2(ex, eye_y + 6), 0.5, ink)
	# Nose and mouth.
	c.line(head_c + Vector2(-0.5, 0), head_c + Vector2(-0.5, 5), 0.5, skin_d)
	c.px(head_c + Vector2(-2, 5.5), skin_d)
	c.px(head_c + Vector2(1.5, 5.5), skin_d)
	var mouth_y := head_c.y + 9.0
	if look.get("smile", false):
		c.line(Vector2(-4, mouth_y - 1), Vector2(0, mouth_y + 0.5), 0.6, Color(0.45, 0.22, 0.2))
		c.line(Vector2(0, mouth_y + 0.5), Vector2(4, mouth_y - 1), 0.6, Color(0.45, 0.22, 0.2))
		c.line(Vector2(-2.5, mouth_y - 0.2), Vector2(2.5, mouth_y - 0.2), 0.4, Color(0.95, 0.93, 0.9))
	else:
		c.line(Vector2(-3, mouth_y), Vector2(3, mouth_y), 0.6, Color(0.45, 0.25, 0.22))
	if look.get("scar", false):
		c.line(head_c + Vector2(6, -6), head_c + Vector2(9, 4), 0.6, Color(0.9, 0.7, 0.65))

	c.shade(0.08)
	c.outline(Color(0.04, 0.04, 0.05))
	return c.color
