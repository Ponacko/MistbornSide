class_name Steelsight
extends RefCounted
## When a Push or Pull fires (DESIGN.md 5.5). A press with a target fires at
## once. A press without one is buffered a few frames, then opens Steelsight:
## time slows while the player finds a target, and the Push commits when one
## highlights, when the window ends, or on release (a short tap). Time ramps
## back to full speed while the force already acts. All timings are real time.

enum Phase { IDLE, BUFFER, AIMING, FIRING }

var phase := Phase.IDLE
var _frames := 0
var _aim_time := 0.0
var _ramp_time := INF
var _ramp_from := 1.0
var _tap_left := 0.0


## real_delta: unscaled seconds. Call once per physics frame.
func update(real_delta: float, pressed: bool, held: bool, has_target: bool, t: Tuning, gamepad := false) -> void:
	_ramp_time += real_delta
	if pressed or (held and phase == Phase.IDLE):
		if has_target:
			_fire()
		else:
			phase = Phase.BUFFER
			_frames = 0
		return
	match phase:
		Phase.BUFFER:
			if not held:
				phase = Phase.IDLE
			elif has_target:
				_fire()
			else:
				_frames += 1
				if _frames >= t.push_buffer_frames:
					phase = Phase.AIMING
					_aim_time = 0.0
		Phase.AIMING:
			_aim_time += real_delta
			var window := t.steelsight_window_gamepad if gamepad else t.steelsight_window
			if not held:
				_commit(t, t.steelsight_tap_time)
			elif has_target or _aim_time >= window:
				_commit(t, 0.0)
		Phase.FIRING:
			_tap_left -= real_delta
			if not held and _tap_left <= 0.0:
				phase = Phase.IDLE


## True while the force may act.
func firing() -> bool:
	return phase == Phase.FIRING


func aiming() -> bool:
	return phase == Phase.AIMING


## Time scale this frame: slowed while aiming, ramping back after a commit.
func time_scale(t: Tuning) -> float:
	if phase == Phase.AIMING:
		return t.steelsight_time_scale
	if _ramp_time < t.steelsight_ramp:
		return lerpf(_ramp_from, 1.0, _ramp_time / t.steelsight_ramp)
	return 1.0


func cancel() -> void:
	phase = Phase.IDLE
	_tap_left = 0.0


func _fire() -> void:
	phase = Phase.FIRING
	_tap_left = 0.0


func _commit(t: Tuning, tap: float) -> void:
	phase = Phase.FIRING
	_tap_left = tap
	_ramp_from = t.steelsight_time_scale
	_ramp_time = 0.0
