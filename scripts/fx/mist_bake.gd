class_name MistBake
## Bakes a level's static mist density map once: R is floor pooling (1 right
## above a floor, fading with height), G is open air (0 inside interiors,
## blurred so the mists dissipate at doorways).

const POOL_DEPTH := 64.0
const BLUR_CELLS := 2


static func bake(world: Node2D, bounds: Rect2, cell: float) -> Dictionary:
	var w := ceili(bounds.size.x / cell)
	var h := ceili(bounds.size.y / cell)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var space := world.get_world_2d().direct_space_state
	var interiors: Array[Rect2] = []
	for n in world.get_tree().get_nodes_in_group("mist_interiors"):
		interiors.append((n as MistInterior).rect())
	var open := PackedFloat32Array()
	open.resize(w * h)
	for y in h:
		for x in w:
			var p := bounds.position + Vector2(x + 0.5, y + 0.5) * cell
			var q := PhysicsRayQueryParameters2D.create(p, p + Vector2(0, POOL_DEPTH), Layers.WORLD)
			q.hit_from_inside = false
			var hit := space.intersect_ray(q)
			var pool := 0.0
			if not hit.is_empty():
				pool = 1.0 - (hit.position.y - p.y) / POOL_DEPTH
			img.set_pixel(x, y, Color(pool, 1.0, 0.0, 1.0))
			var inside := false
			for r in interiors:
				if r.has_point(p):
					inside = true
					break
			open[y * w + x] = 0.0 if inside else 1.0
	open = _blur(open, w, h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			c.g = open[y * w + x]
			img.set_pixel(x, y, c)
	return {"image": img, "bounds": bounds, "cell": cell}


static func sample(bake_data: Dictionary, world_pos: Vector2) -> Color:
	var img: Image = bake_data.image
	var b: Rect2 = bake_data.bounds
	var cell: float = bake_data.cell
	var p := ((world_pos - b.position) / cell).floor()
	if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
		return Color(0, 1, 0, 1)
	return img.get_pixel(int(p.x), int(p.y))


static func _blur(values: PackedFloat32Array, w: int, h: int) -> PackedFloat32Array:
	var out := values.duplicate()
	for pass_i in 2:
		var src := out.duplicate()
		for y in h:
			for x in w:
				var sum := 0.0
				var n := 0
				for dy in range(-BLUR_CELLS, BLUR_CELLS + 1):
					for dx in range(-BLUR_CELLS, BLUR_CELLS + 1):
						var xx := clampi(x + dx, 0, w - 1)
						var yy := clampi(y + dy, 0, h - 1)
						sum += src[yy * w + xx]
						n += 1
				out[y * w + x] = sum / n
		# Keep the core of an interior fully clear after blurring.
		for i in out.size():
			if values[i] == 0.0:
				out[i] = minf(out[i], src[i] * 0.5)
	return out
