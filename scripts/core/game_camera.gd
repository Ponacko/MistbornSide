class_name GameCamera
extends Camera2D
## Follows Vin with smoothing and a little look-ahead in her direction of travel.

@export var target_path: NodePath
@export var look_ahead := 0.18

var target: Node2D
var _shake := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	if target_path:
		target = get_node(target_path)
	make_current()
	if target is Vin:
		(target as Vin).hurt.connect(func(_h): shake(3.0))
		(target as Vin).allomancy.launched.connect(func(): shake(1.5))


func _physics_process(_delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("player")
		if target == null:
			return
	var v := Vector2.ZERO
	if target is CharacterBody2D:
		v = (target as CharacterBody2D).velocity
	global_position = target.global_position + Vector2(0, -40) + Vector2(v.x, v.y * 0.5) * look_ahead
	_shake = move_toward(_shake, 0.0, _delta * 12.0)
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * Settings.screen_shake


## A jolt of screen shake (hits, launches), scaled by the comfort setting.
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)
