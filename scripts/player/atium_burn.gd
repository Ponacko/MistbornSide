class_name AtiumBurn
extends Node
## Atium (DESIGN.md 5.11): hold Tab to burn a bead for a few seconds of
## future-sight. Enemy shadows show their next action ahead of time,
## projectiles draw their paths, time slows slightly, the dodge window
## widens and counters auto-aim. Pressing again stops the burn; the rest of
## the bead is lost, as in the books.

signal started
signal ended

var vin: Vin
var burning := false
var time_left := 0.0
var _hold := 0.0
var _was_held := false
var _armed := true


func _init(owner_vin: Vin) -> void:
	vin = owner_vin
	name = "AtiumBurn"


func physics_update(delta: float) -> void:
	var t := Game.tuning
	var real := TimeController.real_delta(delta)
	var held := vin.controls.atium_held
	var pressed := held and not _was_held
	_was_held = held
	if burning:
		time_left -= real
		if pressed or time_left <= 0.0:
			stop()
			_armed = false
		return
	if not held:
		_hold = 0.0
		_armed = true
		return
	if not _armed:
		return
	_hold += real
	if _hold >= t.atium_confirm_time and vin.atium_beads > 0:
		_armed = false
		_start(t)


func _start(t: Tuning) -> void:
	vin.atium_beads -= 1
	burning = true
	time_left = t.atium_duration
	TimeController.set_factor(&"atium", t.atium_time_scale)
	vin.dodge_window_scale = t.atium_dodge_scale
	vin.counter_aim = true
	started.emit()


func stop() -> void:
	if not burning:
		return
	burning = false
	time_left = 0.0
	TimeController.clear_factor(&"atium")
	vin.dodge_window_scale = 1.0
	vin.counter_aim = false
	ended.emit()


## Each living enemy's forecast while burning.
func shadows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not burning:
		return out
	for n in vin.get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if not e.dead():
			out.append(e.forecast(Game.tuning.atium_lookahead))
	return out


## Paths of lethal projectiles not thrown by Vin: [[from, to]].
func projectile_paths() -> Array:
	var out := []
	if not burning:
		return out
	for n in vin.get_tree().get_nodes_in_group("coins"):
		var c := n as Coin
		if c.thrower != null and c.thrower != vin and c.is_lethal():
			out.append([c.global_position, c.global_position + c.linear_velocity * 0.6])
	return out
