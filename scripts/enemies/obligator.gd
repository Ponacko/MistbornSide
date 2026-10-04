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


func _draw() -> void:
	if dead():
		draw_rect(Rect2(-20, -8, 40, 8), Color(0.35, 0.35, 0.37))
		return
	var robe := Color(0.45, 0.45, 0.48)
	draw_rect(Rect2(-HALF_WIDTH, -HEIGHT + 9, HALF_WIDTH * 2.0, HEIGHT - 9), robe)
	draw_rect(Rect2(-HALF_WIDTH + 1, -HEIGHT, HALF_WIDTH * 2.0 - 2, 9), Color(0.82, 0.7, 0.6))
	# Eye tattoos.
	draw_line(Vector2(facing * 1.0, -HEIGHT + 3), Vector2(facing * 5.0, -HEIGHT + 2), Color(0.2, 0.25, 0.4), 1.0)
	draw_line(Vector2(facing * 1.0, -HEIGHT + 5), Vector2(facing * 5.0, -HEIGHT + 6), Color(0.2, 0.25, 0.4), 1.0)
	_draw_suspicion()
