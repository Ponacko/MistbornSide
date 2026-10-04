class_name CharacterSprite
extends Sprite2D
## Draws a character from CharacterArt: set `state` and `facing` each frame;
## multi-frame states animate on their own.

@export var who := "vin"
@export var fps := 10.0

var state := "idle"
var facing := 1
var frame_index := 0
var _t := 0.0
var _key := ""


func _ready() -> void:
	centered = false
	offset = -CharacterArt.ORIGIN
	_refresh()


func show_state(new_state: String, new_facing: int) -> void:
	if new_state != state:
		state = new_state
		_t = 0.0
		frame_index = 0
	facing = new_facing
	_refresh()


func _process(delta: float) -> void:
	var n := CharacterArt.frame_count(who, state)
	if n > 1:
		_t += delta
		frame_index = int(_t * fps) % n
	_refresh()


func _refresh() -> void:
	var key := "%s/%s/%d" % [who, state, frame_index]
	if key != _key:
		_key = key
		texture = CharacterArt.texture(who, state, frame_index)
	flip_h = facing < 0
