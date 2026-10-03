class_name TargetScorer
## Picks the metal source to highlight (DESIGN.md 5.5). Candidates are
## dictionaries {source, pos, mass, kind, id} so scoring is testable without
## a scene.


class Context:
	var origin := Vector2.ZERO
	var feet := Vector2.ZERO
	var aim_point := Vector2.ZERO
	var aim_active := false
	var falling := false
	var on_floor := false
	var facing := 1
	var last_id: Variant = null
	## How close to the cursor a source must be to be picked by aim.
	var snap_radius := 48.0
	## Pixels of cursor distance forgiven per tenfold of mass over a clip.
	var mass_weight := 4.0
	var cycle_radius := 96.0
	## Steepest angle from straight down (degrees) that counts as "below".
	var below_cone := 50.0


static func cursor_score(c: Dictionary, ctx: Context) -> float:
	var bonus := ctx.mass_weight * log(maxf(c.mass, 0.01) / 0.01) / log(10.0)
	return (c.pos as Vector2).distance_to(ctx.aim_point) - bonus


static func pick(candidates: Array, ctx: Context) -> Dictionary:
	if candidates.is_empty():
		return {}
	if ctx.aim_active:
		var r := ranked(candidates, ctx, ctx.snap_radius)
		return r[0] if not r.is_empty() else {}
	return _heuristic(candidates, ctx)


## Candidates within radius of the aim point (cycle radius by default), best first.
static func ranked(candidates: Array, ctx: Context, radius := -1.0) -> Array:
	var limit := ctx.cycle_radius if radius < 0.0 else radius
	var limit2 := limit * limit
	var scored := []
	for c in candidates:
		if (c.pos as Vector2).distance_squared_to(ctx.aim_point) <= limit2:
			scored.append([cursor_score(c, ctx), c])
	scored.sort_custom(func(a, b): return a[0] < b[0])
	return scored.map(func(p): return p[1])


static func _heuristic(candidates: Array, ctx: Context) -> Dictionary:
	if ctx.falling:
		var below := _nearest(candidates.filter(func(c):
			if c.kind != MetalSource.Kind.ANCHORED:
				return false
			var d: Vector2 = c.pos - ctx.feet
			return d.y > 0.0 and rad_to_deg(Vector2.DOWN.angle_to(d.normalized())) <= ctx.below_cone
		), ctx.feet)
		if not below.is_empty():
			return below
	if ctx.on_floor:
		var at_feet := _nearest(candidates.filter(func(c):
			return c.kind == MetalSource.Kind.DYNAMIC and (c.pos as Vector2).distance_to(ctx.feet) < 24.0
		), ctx.feet)
		if not at_feet.is_empty():
			return at_feet
		var ahead := _nearest(candidates.filter(func(c): return ((c.pos as Vector2).x - ctx.origin.x) * ctx.facing > 0.0), ctx.origin)
		if not ahead.is_empty():
			return ahead
	if ctx.last_id != null:
		for c in candidates:
			if c.id == ctx.last_id:
				return c
	return _nearest(candidates, ctx.origin)


static func _nearest(candidates: Array, to: Vector2) -> Dictionary:
	var best := {}
	var best_d := INF
	for c in candidates:
		var d := (c.pos as Vector2).distance_squared_to(to)
		if d < best_d:
			best_d = d
			best = c
	return best
