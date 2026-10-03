class_name PushPreview
## The weight rule as two arrows (DESIGN.md 5.5): how the motion of a Push on
## this source would split between Vin and the metal.


## push_dir: direction the Push would drive the source. Returns {vin, target}
## shares between 0 and 1.
static func shares(source: MetalSource, push_dir: Vector2, vin_mass: float) -> Dictionary:
	if source.kind == MetalSource.Kind.ANCHORED or source.inside_body:
		return {"vin": 1.0, "target": 0.0}
	if source.body is Coin and (source.body as Coin).is_supported():
		var t := Game.tuning
		var c := AnchorCone.classify(push_dir, (source.body as Coin).ground_normal, t.anchor_cone_degrees, t.coin_partial_lift)
		if c.anchored:
			return {"vin": 1.0, "target": 0.0}
		return {"vin": c.lift, "target": 1.0 - c.lift}
	var m := source.push_mass()
	if is_inf(m):
		return {"vin": 1.0, "target": 0.0}
	return {"vin": m / (vin_mass + m), "target": vin_mass / (vin_mass + m)}
