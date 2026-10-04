class_name PixelTextures
## Procedural pixel-art surface textures with matching normal maps, so
## lanterns light them convincingly (ADR 0003). Each is a 32x32 tile from a
## seeded generator: slate roofs, brick, dressed stone, plaster, planks.
## A stand-in for hand-painted tiles: the look follows the world-and-visuals
## note (near-black blues and greys, ash) and the normal-map pipeline is the
## real one.

enum Style { GREY, SLATE, BRICK, STONE, PLASTER, WOOD, IRON }

const SIZE := 32

static var _cache := {}


static func texture(style: Style) -> CanvasTexture:
	if _cache.has(style):
		return _cache[style]
	var height := Image.create(SIZE, SIZE, false, Image.FORMAT_RF)
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + style
	for y in SIZE:
		for x in SIZE:
			var r := _sample(style, x, y, rng)
			albedo.set_pixel(x, y, r[0])
			height.set_pixel(x, y, Color(r[1], 0, 0))
	var tex := CanvasTexture.new()
	tex.diffuse_texture = ImageTexture.create_from_image(albedo)
	tex.normal_texture = ImageTexture.create_from_image(_normals(height))
	tex.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_cache[style] = tex
	return tex


## [albedo, height] for one pixel.
static func _sample(style: Style, x: int, y: int, rng: RandomNumberGenerator) -> Array:
	var n := rng.randf()
	match style:
		Style.SLATE:
			var row := y / 6
			var off := 4 if row % 2 == 1 else 0
			var col := (x + off) / 8
			var in_y := y % 6
			var edge := in_y == 5 or (x + off) % 8 == 7
			var shade := 0.18 + 0.05 * ((col * 7 + row * 3) % 4) / 3.0 + n * 0.03
			var c := Color(shade * 0.85, shade * 0.9, shade * 1.15)
			if edge:
				c = c.darkened(0.45)
			return [c, 0.2 if edge else 0.5 + in_y * 0.08]
		Style.BRICK:
			var row := y / 5
			var off := 5 if row % 2 == 1 else 0
			var mortar := y % 5 == 4 or (x + off) % 10 == 9
			var tone := 0.3 + 0.08 * (((x + off) / 10 + row) % 3) / 2.0 + n * 0.04
			var c := Color(tone * 1.05, tone * 0.78, tone * 0.68) if not mortar else Color(0.17, 0.17, 0.19)
			return [c, 0.15 if mortar else 0.7 + n * 0.1]
		Style.STONE:
			var row := y / 11
			var off := 8 if row % 2 == 1 else 0
			var joint := y % 11 == 10 or (x + off) % 16 == 15
			var tone := 0.27 + 0.05 * n + 0.03 * float(((x + off) / 16 + row) % 2)
			var c := Color(tone, tone * 1.0, tone * 1.06) if not joint else Color(0.12, 0.12, 0.14)
			return [c, 0.1 if joint else 0.6 + n * 0.15]
		Style.PLASTER:
			var tone := 0.33 + n * 0.05 + (0.06 if (x * 13 + y * 7) % 23 == 0 else 0.0)
			return [Color(tone * 1.02, tone * 0.98, tone * 0.92), 0.5 + n * 0.1]
		Style.WOOD:
			var plank := x / 6
			var seam := x % 6 == 5
			var grain := 0.04 * sin(y * 0.9 + plank * 2.0)
			var tone := 0.24 + grain + n * 0.03 + 0.03 * (plank % 2)
			var c := Color(tone * 1.2, tone * 0.92, tone * 0.7) if not seam else Color(0.1, 0.08, 0.07)
			return [c, 0.2 if seam else 0.55 + grain * 3.0]
		Style.IRON:
			var rivet := (x % 8 == 3 and y % 8 == 3)
			var tone := 0.32 + n * 0.04
			return [Color(tone, tone * 1.04, tone * 1.12) if not rivet else Color(0.5, 0.52, 0.56), 0.9 if rivet else 0.5]
	var g := 0.33 + n * 0.02
	return [Color(g, g * 1.01, g * 1.1), 0.5]


static func _normals(height: Image) -> Image:
	var out := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var l := height.get_pixel((x - 1 + SIZE) % SIZE, y).r
			var r := height.get_pixel((x + 1) % SIZE, y).r
			var u := height.get_pixel(x, (y - 1 + SIZE) % SIZE).r
			var d := height.get_pixel(x, (y + 1) % SIZE).r
			var n := Vector3((l - r) * 2.0, (u - d) * 2.0, 1.0).normalized()
			out.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	return out
