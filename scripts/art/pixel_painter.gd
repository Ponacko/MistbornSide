class_name PixelPainter
extends RefCounted
## A small pixel canvas with a metal mask: discs, capsules, polygons and
## ellipses stamped into an Image, then an outline, edge shading, and a
## normal map from a rounded height field. Shared by the character sprites
## and the dialogue portraits.

var w: int
var h: int
## Pixel that coordinates are relative to.
var origin: Vector2
var color: Image
var metal: Image
var any_metal := false


func _init(width: int, height: int, origin_px: Vector2) -> void:
	w = width
	h = height
	origin = origin_px
	color = Image.create(w, h, false, Image.FORMAT_RGBA8)
	metal = Image.create(w, h, false, Image.FORMAT_L8)


func px(p: Vector2, c: Color, is_metal := false) -> void:
	var q := (p + origin).round()
	if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
		return
	color.set_pixel(int(q.x), int(q.y), Color(c.r, c.g, c.b, 1.0))
	metal.set_pixel(int(q.x), int(q.y), Color.WHITE if is_metal else Color.BLACK)
	any_metal = any_metal or is_metal


func filled(p: Vector2) -> bool:
	var q := (p + origin).round()
	if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
		return false
	return color.get_pixel(int(q.x), int(q.y)).a > 0.5


func disc(center: Vector2, r: float, c: Color, is_metal := false) -> void:
	for y in range(floori(-r), ceili(r) + 1):
		for x in range(floori(-r), ceili(r) + 1):
			if x * x + y * y <= r * r + 0.5:
				px(center + Vector2(x, y), c, is_metal)


func ellipse(center: Vector2, rx: float, ry: float, c: Color, is_metal := false) -> void:
	for y in range(floori(-ry), ceili(ry) + 1):
		for x in range(floori(-rx), ceili(rx) + 1):
			if (x * x) / (rx * rx) + (y * y) / (ry * ry) <= 1.0 + 0.5 / maxf(rx, ry):
				px(center + Vector2(x, y), c, is_metal)


## A capsule from a to b.
func line(a: Vector2, b: Vector2, half_width: float, c: Color, is_metal := false) -> void:
	var steps := maxi(int(a.distance_to(b) * 2.0), 1)
	for i in steps + 1:
		disc(a.lerp(b, float(i) / steps), half_width, c, is_metal)


func poly(points: PackedVector2Array, c: Color, is_metal := false) -> void:
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	for y in range(floori(r.position.y), ceili(r.end.y) + 1):
		for x in range(floori(r.position.x), ceili(r.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), points):
				px(Vector2(x, y), c, is_metal)


## A quad of half-width `hw` along a to b: a limb segment with square ends.
func bar(a: Vector2, b: Vector2, hw: float, c: Color, is_metal := false) -> void:
	var n := (b - a).normalized().orthogonal() * hw
	poly(PackedVector2Array([a + n, b + n, b - n, a - n]), c, is_metal)
	disc(a, hw * 0.95, c, is_metal)
	disc(b, hw * 0.95, c, is_metal)


## One-pixel dark outline around everything drawn so far.
func outline(edge := Color(0.03, 0.03, 0.04)) -> void:
	var src: Image = color.duplicate()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixel(q.x, q.y).a > 0.5:
					color.set_pixel(x, y, Color(edge, 1.0))
					break


## Edge shading, light from above and in front (+x): top and front edges
## of each shape lighter, back edges darker. Metal is left to its specular.
func shade(amount := 0.18) -> void:
	var src: Image = color.duplicate()
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a < 0.5 or metal.get_pixel(x, y).r > 0.5:
				continue
			var same_right := x + 1 < w and src.get_pixel(x + 1, y).a > 0.5 and src.get_pixel(x + 1, y).is_equal_approx(c)
			var same_left := x > 0 and src.get_pixel(x - 1, y).a > 0.5 and src.get_pixel(x - 1, y).is_equal_approx(c)
			var same_up := y > 0 and src.get_pixel(x, y - 1).a > 0.5 and src.get_pixel(x, y - 1).is_equal_approx(c)
			if not same_up or not same_right:
				color.set_pixel(x, y, c.lightened(amount))
			elif not same_left:
				color.set_pixel(x, y, c.darkened(amount * 1.2))


## Normal map from a rounded height field: higher away from the edges.
func normal_map() -> Image:
	var height := PackedFloat32Array()
	height.resize(w * h)
	for y in h:
		for x in w:
			height[y * w + x] = 3.0 if color.get_pixel(x, y).a > 0.5 else 0.0
	for pass_i in 3:
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var i := y * w + x
				if height[i] > 0.0:
					height[i] = minf(height[i], minf(minf(height[i - 1], height[i + 1]), minf(height[i - w], height[i + w])) + 1.0)
	var normal := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if color.get_pixel(x, y).a < 0.5:
				continue
			var i := y * w + x
			var n := Vector3((height[i - 1] - height[i + 1]) * 0.6, (height[i - w] - height[i + w]) * 0.6, 1.0).normalized()
			normal.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
	return normal


func specular_map() -> Image:
	var spec := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var m := metal.get_pixel(x, y).r
			spec.set_pixel(x, y, Color(m, m, m, 1.0))
	return spec


func to_canvas_texture() -> CanvasTexture:
	var tex := CanvasTexture.new()
	tex.diffuse_texture = ImageTexture.create_from_image(color)
	tex.normal_texture = ImageTexture.create_from_image(normal_map())
	if any_metal:
		tex.specular_texture = ImageTexture.create_from_image(specular_map())
		tex.specular_shininess = 0.7
	return tex
