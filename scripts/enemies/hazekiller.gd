class_name Hazekiller
extends Enemy
## A trained anti-Allomancer (DESIGN.md 6.3): wooden shield and staff, no
## metal at all, so Push and Pull find nothing. The shield stops coins from
## the front and blunts daggers; two pewter heavies break it. Fights as a
## squad, a couple at a time.

var squad: HazekillerSquad
var has_shield := true
var slot := 0
var _shield_hp := 2
var _windup := 0.0
var _cooldown := 0.0
var _attacking := false


func _init() -> void:
	max_health = 90.0
	chase_speed = 105.0


func damage_scale(hit: Hit) -> float:
	var from_front := hit.direction.x * facing < 0.0
	if not has_shield or not from_front:
		return 1.0
	match hit.kind:
		Hit.Kind.COIN:
			return 0.0
		Hit.Kind.HEAVY:
			_shield_hp -= 1
			if _shield_hp <= 0:
				has_shield = false
				NoiseBus.emit(global_position, 0.8, NoiseBus.Kind.BREAK)
			return 0.0
		Hit.Kind.DAGGER, Hit.Kind.DASH:
			return 0.5
	return 1.0


func think(delta: float) -> void:
	var t := Game.tuning
	_cooldown = maxf(_cooldown - delta, 0.0)
	var v := vin()
	var alive := v != null and not v.is_dead()
	if alive and not aware and v.global_position.distance_to(global_position) < t.guard_contact_distance:
		notice()
	if _windup > 0.0:
		desired_speed = 0.0
		_windup -= delta
		if _windup <= 0.0:
			_strike(v, t)
		return
	if aware and alive:
		# Spread around her: each member takes a slot either side.
		var side := -1.0 if slot % 2 == 0 else 1.0
		var ring := t.hazekiller_reach * 0.8 + 18.0 * floorf(slot / 2.0)
		var spot := v.global_position.x + side * ring
		face_toward(v.global_position.x)
		var dx := v.global_position.x - global_position.x
		if absf(dx) <= t.hazekiller_reach and absf(v.global_position.y - global_position.y) < 30.0:
			desired_speed = 0.0
			if _cooldown <= 0.0 and (squad == null or squad.take_attack_token(self)):
				_attacking = true
				_windup = t.hazekiller_windup
		elif absf(spot - global_position.x) > 6.0 and _floor_ahead():
			desired_speed = signf(spot - global_position.x) * chase_speed
		else:
			desired_speed = 0.0
	elif suspicion.stage == Suspicion.Stage.SUSPICIOUS:
		_investigate()
	else:
		_patrol()


func winding_up() -> bool:
	return _windup > 0.0


func _strike(v: Vin, t: Tuning) -> void:
	_cooldown = t.hazekiller_cooldown
	_attacking = false
	if squad:
		squad.release_attack_token(self)
	NoiseBus.emit(global_position, 0.6, NoiseBus.Kind.FIGHT)
	if v == null:
		return
	var dx := v.global_position.x - global_position.x
	if dx * facing >= -4.0 and absf(dx) <= t.hazekiller_reach + 6.0 and absf(v.global_position.y - global_position.y) < 30.0:
		v.take_hit(Hit.make(Hit.Kind.STAFF, t.hazekiller_staff_damage, Vector2(facing, 0), self, true))


func on_death() -> void:
	if squad:
		squad.release_attack_token(self)


func _draw() -> void:
	if dead():
		draw_rect(Rect2(-20, -8, 40, 8), Color(0.3, 0.26, 0.2))
		return
	draw_rect(Rect2(-HALF_WIDTH, -HEIGHT, HALF_WIDTH * 2.0, HEIGHT), Color(0.24, 0.22, 0.2))
	draw_rect(Rect2(-HALF_WIDTH + 1, -HEIGHT, HALF_WIDTH * 2.0 - 2, 9), Color(0.75, 0.6, 0.5))
	var staff_tip := Vector2(facing * (26.0 if _windup <= 0.0 else 12.0), -30)
	draw_line(Vector2(-facing * 8.0, -20), staff_tip, Color(0.5, 0.38, 0.24), 2.0)
	if has_shield:
		draw_rect(Rect2(facing * 6.0 - 2.0, -36, 5, 22), Color(0.55, 0.4, 0.25))
	_draw_suspicion()
