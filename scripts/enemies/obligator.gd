class_name Obligator
extends Enemy
## A Seeker obligator (DESIGN.md 6.3): senses any metal Vin burns within his
## radius unless her copper is on, and raises the alarm rather than fight.

var _shout_cooldown := 0.0


func _init() -> void:
	seeker = true
	misting_label = "Seeker"
	max_health = 60.0
	walk_speed = 28.0


func think(delta: float) -> void:
	_shout_cooldown = maxf(_shout_cooldown - delta, 0.0)
	match suspicion.stage:
		Suspicion.Stage.ALERTED:
			# Shouts for the guards and keeps his distance.
			desired_speed = 0.0
			if suspicion.last_stimulus != Vector2.INF:
				face_toward(suspicion.last_stimulus.x)
			if _shout_cooldown <= 0.0:
				_shout_cooldown = 1.2
				NoiseBus.emit(global_position, 1.0, NoiseBus.Kind.VOICE)
		Suspicion.Stage.SUSPICIOUS:
			_investigate()
		_:
			_patrol()


func art_who() -> String:
	return "obligator"


func art_state() -> String:
	if not dead() and _stagger <= 0.0 and aware:
		return "alarm"
	return super.art_state()
