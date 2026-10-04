class_name Guard
extends Enemy
## A keep guard: spear and breastplate, both carried metal (DESIGN.md 6.3).
## Patrols, notices Vin on contact, then hunts and strikes. A Push on his
## breastplate shoves his whole body; a hard Pull on his spear tears it away.

@export var armoured := true
## Carries a lantern: lights Vin up near him and swings it at her when
## suspicious, blinding a tin-burner.
@export var carries_lantern := false

var breastplate: MetalSource
var spear: MetalSource
var has_spear := true
var _windup := 0.0
var _cooldown := 0.0
var _grip_strain := 0.0
var lantern: Lantern
var _flash_cooldown := 0.0


func _ready() -> void:
	super._ready()
	if armoured:
		breastplate = MetalSource.new()
		breastplate.kind = MetalSource.Kind.CARRIED
		breastplate.mass = 8.0
		breastplate.position = Vector2(0, -30)
		add_child(breastplate)
	if carries_lantern:
		lantern = Lantern.new()
		lantern.radius = 80.0
		lantern.metal = true
		add_child(lantern)
	spear = MetalSource.new()
	spear.kind = MetalSource.Kind.CARRIED
	spear.mass = 2.0
	add_child(spear)
	_place_spear()


func _place_spear() -> void:
	if spear:
		spear.position = Vector2(facing * 11.0, -26.0)


func damage_scale(hit: Hit) -> float:
	if armoured and hit.kind == Hit.Kind.COIN:
		return 0.5
	return 1.0


func think(delta: float) -> void:
	var t := Game.tuning
	_cooldown = maxf(_cooldown - delta, 0.0)
	_grip_strain = maxf(_grip_strain - t.guard_grip * delta, 0.0)
	_flash_cooldown = maxf(_flash_cooldown - delta, 0.0)
	var v := vin()
	if lantern:
		lantern.position = Vector2(-facing * 8.0, -22.0)
		if v and suspicion.stage != Suspicion.Stage.IDLE and _flash_cooldown <= 0.0:
			var dx := (v.global_position.x - global_position.x) * facing
			if dx > -4.0 and dx < 100.0 and absf(v.global_position.y - global_position.y) < 40.0:
				_flash_cooldown = 4.0
				lantern.flash()
	var alive := v != null and not v.health.is_dead()
	if alive and not aware and v.global_position.distance_to(global_position) < t.guard_contact_distance:
		notice()
	if _windup > 0.0:
		desired_speed = 0.0
		_windup -= delta
		if _windup <= 0.0:
			_strike(v, t)
	elif aware and alive and suspicion.last_stimulus != Vector2.INF and v.global_position.distance_to(global_position) > 340.0:
		_investigate()
	elif aware and alive:
		face_toward(v.global_position.x)
		var dx := v.global_position.x - global_position.x
		if absf(dx) <= t.guard_reach and absf(v.global_position.y - global_position.y) < 30.0:
			desired_speed = 0.0
			if _cooldown <= 0.0:
				_windup = t.guard_windup
		elif absf(dx) < 320.0 and _floor_ahead():
			desired_speed = signf(dx) * chase_speed
		else:
			desired_speed = 0.0
	elif suspicion.stage == Suspicion.Stage.SUSPICIOUS:
		_investigate()
	else:
		_patrol()
	_place_spear()


func winding_up() -> bool:
	return _windup > 0.0


func _will_strike(seconds: float) -> bool:
	var v := vin()
	if v == null or not aware:
		return false
	return absf(v.global_position.x - global_position.x) <= Game.tuning.guard_reach + chase_speed * seconds and _cooldown < seconds


func _strike(v: Vin, t: Tuning) -> void:
	_cooldown = t.guard_cooldown
	NoiseBus.emit(global_position, 0.6, NoiseBus.Kind.FIGHT)
	if v == null:
		return
	var dx := v.global_position.x - global_position.x
	if dx * facing >= -4.0 and absf(dx) <= t.guard_reach + 6.0 and absf(v.global_position.y - global_position.y) < 30.0:
		var damage := t.guard_spear_damage if has_spear else t.guard_spear_damage * 0.4
		v.take_hit(Hit.make(Hit.Kind.SPEAR, damage, Vector2(facing, 0), self, true))


func receive_push(impulse: Vector2, source: MetalSource) -> Vector2:
	if source == spear and has_spear and not dead():
		var toward_vin := v_dir()
		var pull := impulse.dot(toward_vin)
		if pull > 0.0:
			_grip_strain += pull * 2.0
			if _grip_strain > Game.tuning.guard_grip:
				return _disarm(impulse)
	return super.receive_push(impulse, source)


func v_dir() -> Vector2:
	var v := vin()
	if v == null:
		return Vector2.ZERO
	return (v.chest_position() - spear.global_position).normalized()


## The grip check failed: the spear flies loose toward whoever Pulled it.
func _disarm(impulse: Vector2) -> Vector2:
	has_spear = false
	var at := spear.global_position
	spear.queue_free()
	spear = null
	var loose := DroppedWeapon.new()
	loose.position = at
	loose.linear_velocity = impulse.normalized() * 320.0
	get_parent().add_child.call_deferred(loose)
	notice()
	return impulse


func on_death() -> void:
	if has_spear and spear:
		var at := spear.global_position
		spear.queue_free()
		spear = null
		has_spear = false
		var loose := DroppedWeapon.new()
		loose.position = at
		get_parent().add_child.call_deferred(loose)


func art_who() -> String:
	return "guard" + ("" if armoured else "_bare") + ("" if has_spear else "_unarmed")


func art_state() -> String:
	if not dead() and _stagger <= 0.0:
		if _windup > 0.0:
			return "windup"
		if _cooldown > Game.tuning.guard_cooldown - 0.2:
			return "strike"
	return super.art_state()
