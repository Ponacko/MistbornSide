class_name PushPhysics
## Delivers one frame's Push or Pull impulse to a metal source and returns the
## impulse the target actually took, so Vin can receive its equal and
## opposite.


## impulse: vector applied to the target (away from Vin for a Push). Bodies
## with their own rules (coins on the ground, characters) implement
## receive_push(impulse, source) -> Vector2.
static func deliver(source: MetalSource, impulse: Vector2, vin_mass: float, t: Tuning) -> Vector2:
	if impulse == Vector2.ZERO:
		return Vector2.ZERO
	if source.body and source.body.has_method("receive_push"):
		return source.body.receive_push(impulse, source)
	match source.kind:
		MetalSource.Kind.DYNAMIC:
			if source.body is RigidBody2D:
				return dynamic(source.body, impulse, vin_mass, t)
	return impulse


## A free rigid body shares the impulse by mass, its speed change capped.
static func dynamic(rb: RigidBody2D, impulse: Vector2, vin_mass: float, t: Tuning) -> Vector2:
	var magnitude := impulse.length()
	var dir := impulse / magnitude
	var along := rb.linear_velocity.dot(dir)
	var cap := maxf(t.projectile_max_speed - along, 0.0)
	var r := ForceModel.split(magnitude, vin_mass, rb.mass, cap)
	rb.apply_central_impulse(dir * r.target_dv * rb.mass)
	return dir * r.target_dv * rb.mass
