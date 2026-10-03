class_name PewterBurn
extends RefCounted
## Decides the pewter crash (DESIGN.md 5.7): pewter running out while
## flared, or flaring continuously past the limit. There is deliberately no
## deferred "pewter debt" damage; the crash alone carries the idea.

var flare_time := 0.0


## on: pewter burning this frame; flared: Shift held; has_left: reserve
## remaining after this frame's burn. Returns true when Vin crashes.
func update(delta: float, on: bool, flared: bool, has_left: bool, t: Tuning) -> bool:
	if on and flared:
		flare_time += delta
	else:
		flare_time = 0.0
	if on and flared and not has_left:
		flare_time = 0.0
		return true
	if flare_time >= t.crash_flare_seconds:
		flare_time = 0.0
		return true
	return false
