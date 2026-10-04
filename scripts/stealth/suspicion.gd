class_name Suspicion
extends RefCounted
## An enemy's three-stage awareness of Vin (DESIGN.md 6.4): idle,
## suspicious, alerted. Sight and noise raise it, time lowers it; an alerted
## enemy keeps hunting for a while after losing her.

signal stage_changed(stage: Stage)

enum Stage { IDLE, SUSPICIOUS, ALERTED }

var level := 0.0
var stage := Stage.IDLE
## Where the last sight or sound came from.
var last_stimulus := Vector2.INF
var _since := INF


## sight: 0..1 how plainly Vin is seen (or sensed) this frame.
func update(delta: float, sight: float, t: Tuning, at := Vector2.INF) -> void:
	if sight > 0.0:
		level += sight * t.see_rate * delta
		_since = 0.0
		if at != Vector2.INF:
			last_stimulus = at
	else:
		_since += delta
		var hold := t.alert_memory if stage == Stage.ALERTED else 0.5
		if _since > hold:
			level -= t.suspicion_decay * delta
	level = clampf(level, 0.0, 1.0)
	_restage(t)


func hear(amount: float, at: Vector2) -> void:
	level = clampf(level + amount, 0.0, 1.0)
	_since = 0.0
	last_stimulus = at
	_restage(Game.tuning)


func alert(at := Vector2.INF) -> void:
	level = 1.0
	_since = 0.0
	if at != Vector2.INF:
		last_stimulus = at
	_restage(Game.tuning)


## Soothing: dampens suspicion.
func calm(amount: float) -> void:
	level = clampf(level - amount, 0.0, 1.0)
	_restage(Game.tuning)


func _restage(t: Tuning) -> void:
	var next := Stage.IDLE
	if level >= 1.0 or (stage == Stage.ALERTED and level >= 0.5):
		next = Stage.ALERTED
	elif level >= t.suspicious_threshold:
		next = Stage.SUSPICIOUS
	if next != stage:
		stage = next
		stage_changed.emit(stage)
