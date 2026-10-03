class_name PushPhysics
## Delivers one frame's Push or Pull impulse to a metal source and returns the
## impulse the target actually took, so Vin can receive its equal and
## opposite.


## impulse: vector applied to the target (away from Vin for a Push).
static func deliver(source: MetalSource, impulse: Vector2, vin_mass: float, t: Tuning) -> Vector2:
	var magnitude := impulse.length()
	if magnitude == 0.0:
		return Vector2.ZERO
	var dir := impulse / magnitude
	match source.kind:
		MetalSource.Kind.ANCHORED:
			return impulse
		MetalSource.Kind.DYNAMIC:
			var rb := source.body as RigidBody2D
			if rb == null:
				return impulse
			if rb.has_method("push_mass_override"):
				var override: float = rb.push_mass_override(dir)
				if is_inf(override):
					return impulse
			var along := rb.linear_velocity.dot(dir)
			var cap := maxf(t.projectile_max_speed - along, 0.0)
			var r := ForceModel.split(magnitude, vin_mass, rb.mass, cap)
			rb.apply_central_impulse(dir * r.target_dv * rb.mass)
			return dir * r.target_dv * rb.mass
		MetalSource.Kind.CARRIED:
			if source.body and source.body.has_method("receive_push"):
				return source.body.receive_push(impulse, source)
			return impulse
	return impulse
