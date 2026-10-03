class_name ForceModel
## The Steelpush and Ironpull force model (DESIGN.md 5.4):
##   F = F0 * flare * falloff(d),  falloff(d) = clamp(1 - (d / R)^2, 0, 1)
## applied as equal and opposite impulses each physics frame.

## Vertical distance from Vin's feet to her chest, where lines converge.
const CHEST_HEIGHT := 30.0
const STEP := 1.0 / 60.0


static func falloff(distance: float, push_range: float) -> float:
	return clampf(1.0 - pow(distance / push_range, 2.0), 0.0, 1.0)


## Splits one frame's impulse magnitude between Vin and the target. The
## target's speed change is capped (a coin cannot go faster than a bullet
## should); Vin receives exactly the momentum the target took, so momentum is
## conserved. An infinite target mass is an anchor: it takes nothing and Vin
## gets the whole impulse.
static func split(impulse: float, vin_mass: float, target_mass: float, target_dv_cap: float) -> Dictionary:
	if is_inf(target_mass):
		return {"vin_dv": impulse / vin_mass, "target_dv": 0.0}
	var dv := impulse / target_mass
	if dv > target_dv_cap:
		dv = maxf(target_dv_cap, 0.0)
	return {"vin_dv": dv * target_mass / vin_mass, "target_dv": dv}


## Gravity on Vin while a Push or Pull is acting on her.
static func push_gravity(t: Tuning, vy: float) -> float:
	var g := t.jump_gravity()
	return g * t.push_apex_gravity_mult if absf(vy) < t.apex_threshold else g


## Hover damping: bleeds vertical speed under a near-vertical Push so a held
## Push over an anchor settles instead of bobbing forever.
static func hover_damp(t: Tuning, vy: float, delta: float) -> float:
	return vy - vy * minf(t.hover_damping * delta, 1.0)


## Height Vin reaches after `time` seconds of a held Push off a coin at her
## feet, stepping exactly as the game does.
static func reference_height_at(t: Tuning, accel: float, time: float) -> float:
	var y := 0.0
	var vy := 0.0
	var steps := roundi(time / STEP)
	for i in steps:
		var a := accel * falloff(CHEST_HEIGHT + y, t.line_range)
		vy += a * STEP
		vy = hover_damp(t, vy, STEP)
		vy -= push_gravity(t, vy) * STEP
		y += vy * STEP
	return y


static func derive_push_accel(t: Tuning) -> float:
	var target := t.push_reach_tiles * Tuning.TILE
	var lo := 0.0
	var hi := t.jump_gravity() * 100.0
	for i in 50:
		var mid := (lo + hi) * 0.5
		if reference_height_at(t, mid, t.push_reach_time) < target:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5
