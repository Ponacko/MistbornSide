class_name VinCombat
extends Node
## Vin's melee (DESIGN.md 6.2): obsidian daggers in a three-hit combo, a
## dash stab out of a run, a plunge from the air, a backstab that kills the
## unaware, a pewter heavy strike (hold the dagger with pewter on), and a
## dodge roll with invulnerability frames.

var vin: Vin
var combo_step := 0
var swing_left := 0.0
var plunging := false
var _combo_timer := 0.0
var _hold := 0.0
var _holding := false
var _dodge_cooldown := 0.0
var _dash_hit := false


func _init(owner_vin: Vin) -> void:
	vin = owner_vin
	name = "VinCombat"


func physics_update(delta: float) -> void:
	var t := Game.tuning
	var c := vin.controls
	swing_left = maxf(swing_left - delta, 0.0)
	_combo_timer = maxf(_combo_timer - delta, 0.0)
	_dodge_cooldown = maxf(_dodge_cooldown - delta, 0.0)
	if _combo_timer <= 0.0:
		combo_step = 0
	if plunging:
		_update_plunge(t)
	if vin.state == Vin.State.DODGE:
		if vin.roll_strikes and not _dash_hit:
			_dash_hit = _strike(Hit.Kind.DASH, t.dash_damage, t.dagger_reach + 6.0, true)
		return
	if vin.state != Vin.State.NORMAL:
		_holding = false
		return
	if c.dodge_pressed and _dodge_cooldown <= 0.0:
		var dir := int(signf(c.move.x)) if c.move.x != 0.0 else vin.facing
		_dodge_cooldown = t.dodge_cooldown + t.dodge_time
		vin.start_roll(dir, t.dodge_speed, t.dodge_time, t.dodge_iframes * vin.dodge_window_scale, false)
		return
	# With pewter the dagger acts on release, so a hold can become the heavy.
	if c.dagger_pressed:
		_holding = true
		_hold = 0.0
		if not vin.pewter_on:
			_attack(t)
			_holding = false
	elif _holding and c.dagger_held:
		_hold += delta
	if _holding and (c.dagger_released or not c.dagger_held) and not c.dagger_pressed:
		_holding = false
		if vin.pewter_on and _hold >= t.heavy_hold_time:
			_heavy(t)
		else:
			_attack(t)
	elif _holding and c.dagger_pressed and c.dagger_released:
		_holding = false
		_attack(t)


func _attack(t: Tuning) -> void:
	if swing_left > 0.0:
		return
	var c := vin.controls
	if not vin.is_on_floor() and c.move.y > 0.5:
		plunging = true
		vin.velocity = Vector2(vin.velocity.x * 0.3, t.plunge_speed)
		return
	if vin.is_on_floor() and absf(vin.velocity.x) > t.run_speed * vin.speed_scale * 0.8:
		_dash_hit = false
		vin.start_roll(int(signf(vin.velocity.x)), t.dash_speed, t.dash_time, 0.0, true)
		return
	combo_step = combo_step % 3 + 1
	_combo_timer = t.combo_window + t.dagger_swing_time
	swing_left = t.dagger_swing_time
	_strike(Hit.Kind.DAGGER, t.dagger_damage, t.dagger_reach, true)


func _heavy(t: Tuning) -> void:
	swing_left = t.dagger_swing_time * 1.8
	combo_step = 0
	_strike(Hit.Kind.HEAVY, t.heavy_damage, t.dagger_reach + 4.0, false)


## Hits everything hittable in front of Vin; returns true if anything was hit.
## A dagger on an unaware enemy from behind is a backstab.
func _strike(kind: Hit.Kind, damage: float, reach: float, light: bool) -> bool:
	NoiseBus.emit(vin.global_position, 0.5, NoiseBus.Kind.FIGHT)
	if vin.counter_aim:
		_aim_counter(reach)
	var any := false
	for node in vin.get_tree().get_nodes_in_group("hittable"):
		var target := node as Node2D
		var dx := (target.global_position.x - vin.global_position.x) * vin.facing
		var dy := target.global_position.y - vin.global_position.y
		if dx < -4.0 or dx > reach or absf(dy) > 30.0:
			continue
		var hit := Hit.make(kind, damage, Vector2(vin.facing, 0), vin, light)
		if (kind == Hit.Kind.DAGGER or kind == Hit.Kind.DASH) and target is Enemy:
			var e := target as Enemy
			if e.is_unaware() and e.facing == vin.facing:
				hit = Hit.make(Hit.Kind.BACKSTAB, 1000.0, Vector2(vin.facing, 0), vin, false)
		target.take_hit(hit)
		any = true
	return any


## Atium counters: turn to the nearest enemy in reach on either side.
func _aim_counter(reach: float) -> void:
	var best: Node2D = null
	var best_d := reach + 10.0
	for node in vin.get_tree().get_nodes_in_group("hittable"):
		var n := node as Node2D
		var d := absf(n.global_position.x - vin.global_position.x)
		if d < best_d and absf(n.global_position.y - vin.global_position.y) < 30.0:
			best_d = d
			best = n
	if best:
		vin.facing = 1 if best.global_position.x >= vin.global_position.x else -1


func _update_plunge(t: Tuning) -> void:
	if vin.is_on_floor() or vin.state != Vin.State.NORMAL:
		plunging = false
		NoiseBus.emit(vin.global_position, 0.8, NoiseBus.Kind.LANDING)
		return
	vin.velocity.y = maxf(vin.velocity.y, t.plunge_speed)
	for node in vin.get_tree().get_nodes_in_group("hittable"):
		var target := node as Node2D
		var dx := absf(target.global_position.x - vin.global_position.x)
		var head := target.global_position.y - Enemy.HEIGHT
		if dx < 14.0 and vin.global_position.y > head - 6.0 and vin.global_position.y < target.global_position.y:
			target.take_hit(Hit.make(Hit.Kind.PLUNGE, t.plunge_damage, Vector2.DOWN, vin, false))
			plunging = false
			vin.velocity.y = -180.0
			return
