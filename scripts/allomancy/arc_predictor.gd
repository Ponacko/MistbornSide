class_name ArcPredictor
## Predicts Vin's path for the next fraction of a second under a Push or Pull
## on a fixed point, for the faint arc drawn during Steelsight.


## feet/velocity: Vin now. source: the metal (Vector2.INF for none).
## sign: +1 Push, -1 Pull. share: Vin's share of the motion (PushPreview).
static func predict(feet: Vector2, velocity: Vector2, source: Vector2, share: float, sign: float, flare: float, t: Tuning) -> PackedVector2Array:
	var out := PackedVector2Array()
	var p := feet
	var v := velocity
	var dt := 1.0 / 60.0
	var chest := Vector2(0, -ForceModel.CHEST_HEIGHT)
	var accel := t.push_accel() * flare * share
	for i in int(t.arc_preview_time * 60.0):
		var forced := false
		if source != Vector2.INF and share > 0.0:
			var d := source - (p + chest)
			var f := ForceModel.falloff(d.length(), t.line_range)
			if f > 0.0:
				var dir := -d.normalized() * sign
				v += dir * accel * f * dt
				if absf(dir.y) > 0.8:
					v.y = ForceModel.hover_damp(t, v.y, dt)
				forced = true
		var g := ForceModel.push_gravity(t, v.y) if forced else MovementMath.gravity(t, v.y, false)
		v.y = minf(v.y + g * dt, t.max_fall_speed)
		p += v * dt
		out.append(p)
	return out
