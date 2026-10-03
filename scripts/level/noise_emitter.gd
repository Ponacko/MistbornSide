class_name NoiseEmitter
extends Node2D
## Makes noise on a beat, optionally walking back and forth: a test stand-in
## for an unseen patrol's footsteps or voices behind a wall.

@export var kind := NoiseBus.Kind.FOOTSTEP
@export var loudness := 0.6
@export var interval := 0.45
@export var walk_distance := 0.0
@export var walk_speed := 30.0

var _timer := 0.0
var _origin := Vector2.ZERO
var _dir := 1.0


func _ready() -> void:
	_origin = position


func _physics_process(delta: float) -> void:
	if walk_distance > 0.0:
		position.x += _dir * walk_speed * delta
		if absf(position.x - _origin.x) > walk_distance:
			_dir = -_dir
	_timer -= delta
	if _timer <= 0.0:
		_timer = interval
		NoiseBus.emit(global_position, loudness, kind)
