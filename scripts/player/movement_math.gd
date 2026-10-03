class_name MovementMath
## Vin's base movement rules as pure functions so they can be tested and tuned
## without a scene.


## Gravity for this frame. Falling is heavier; near the apex of a jump that is
## still held, gravity is reduced (Celeste's apex hang).
static func gravity(t: Tuning, vy: float, jump_held: bool) -> float:
	var g := t.jump_gravity()
	if jump_held and absf(vy) < t.apex_threshold:
		return g * t.apex_gravity_mult
	if vy > 0.0:
		return g * t.fall_gravity_mult
	return g


## Horizontal speed after one frame. Momentum above run speed is never
## clamped hard: on the ground friction bleeds it off, in the air only a light
## drag does, so a Push's speed survives a neutral stick (DESIGN.md 5.4).
static func horizontal(t: Tuning, vx: float, input_x: float, on_floor: bool, delta: float, max_speed := -1.0) -> float:
	var top := t.run_speed if max_speed < 0.0 else max_speed
	var target := input_x * top
	var over_speed := absf(vx) > top and (input_x == 0.0 or signf(input_x) == signf(vx))
	if over_speed:
		var drag := t.ground_decel if on_floor else t.air_drag
		return move_toward(vx, signf(vx) * top, drag * delta)
	if on_floor:
		var rate := t.ground_accel if input_x != 0.0 else t.ground_decel
		return move_toward(vx, target, rate * delta)
	if input_x == 0.0:
		return move_toward(vx, 0.0, t.air_drag * delta)
	return move_toward(vx, target, t.air_accel * delta)
