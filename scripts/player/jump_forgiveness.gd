class_name JumpForgiveness
extends RefCounted
## Coyote time and jump buffering. Call tick() once per physics frame, press()
## when the jump button goes down, then consume() to ask whether to jump now.

var coyote_time: float
var buffer_time: float
var _since_floor := INF
var _since_press := INF


func _init(coyote: float, buffer: float) -> void:
	coyote_time = coyote
	buffer_time = buffer


func tick(delta: float, on_floor: bool) -> void:
	_since_press += delta
	if on_floor:
		_since_floor = 0.0
	else:
		_since_floor += delta


func press() -> void:
	_since_press = 0.0


func consume() -> bool:
	if _since_press <= buffer_time and _since_floor <= coyote_time:
		_since_press = INF
		_since_floor = INF
		return true
	return false


## True while a buffered press is still waiting to be used.
func has_buffered_press() -> bool:
	return _since_press <= buffer_time


func clear_press() -> void:
	_since_press = INF
