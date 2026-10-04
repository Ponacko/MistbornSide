class_name CharacterSprite
extends Sprite2D
## Draws a character from CharacterArt: set `state` and `facing` each frame;
## multi-frame states animate at their own rate. A soft ground shadow sits
## under the feet so the figure stands on the roof instead of floating.

@export var who := "vin"
## Draw the ground shadow (off while hanging or dead, handled by state).
@export var ground_shadow := true

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
		frame_index = int(_t * CharacterArt.fps(state)) % n
	_refresh()
	queue_redraw()


func _refresh() -> void:
	var key := "%s/%s/%d" % [who, state, frame_index]
	if key != _key:
		_key = key
		texture = CharacterArt.texture(who, state, frame_index)
	flip_h = facing < 0


func _draw() -> void:
	if not ground_shadow or state in ["ledge_hang", "bracket_hang", "jump", "fall", "leap", "plunge", "dead"]:
		return
	# The sprite offset puts the feet at the node origin; squash a circle
	# there into a shadow.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.3))
	draw_circle(Vector2(0, 1.0 / 0.3), 7.0, Color(0, 0, 0, 0.3))
