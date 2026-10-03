class_name Vin
extends CharacterBody2D
## The player character. Base movement (run, jump, ledge grab, wall slide,
## crouch) with Celeste-style forgiveness. The origin is at Vin's feet.

signal landed(fall_speed: float)
signal jumped

enum State { NORMAL, LEDGE_HANG, BRACKET_HANG }

const HALF_WIDTH := 6.0
const STAND_HEIGHT := 44.0
const CROUCH_HEIGHT := 26.0
const CHEST := Vector2(0, -30)
const LEDGE_REACH := 7.0
const LEDGE_HAND_Y := -40.0

## When true, controls are set by code (tests, cutscenes) instead of the device.
@export var scripted := false

var controls := PlayerControls.new()
var reserves := MetalReserves.new()
var allomancy: Allomancer
var body_mass: float:
	get:
		return Game.tuning.vin_mass
var state := State.NORMAL
var facing := 1
var crouching := false
## Multiplies run speed and jump height; pewter and the crash write to it.
var speed_scale := 1.0
var jump_scale := 1.0

var _forgiveness: JumpForgiveness
var _shape: CollisionShape2D
var _stand_rect := RectangleShape2D.new()
var _crouch_rect := RectangleShape2D.new()
var _ledge_cooldown := 0.0
var _wall_jump_lock := 0.0
var _was_on_floor := false
var _jump_held_since_jump := false
var _ledge_point := Vector2.ZERO
var _cling_source: MetalSource


func _ready() -> void:
	collision_layer = Layers.PLAYER
	collision_mask = Layers.WORLD
	floor_snap_length = 4.0
	_stand_rect.size = Vector2(HALF_WIDTH * 2.0, STAND_HEIGHT)
	_crouch_rect.size = Vector2(HALF_WIDTH * 2.0, CROUCH_HEIGHT)
	_shape = CollisionShape2D.new()
	_shape.shape = _stand_rect
	_shape.position = Vector2(0, -STAND_HEIGHT / 2.0)
	add_child(_shape)
	_forgiveness = JumpForgiveness.new(Game.tuning.coyote_time, Game.tuning.jump_buffer)
	add_to_group("player")
	allomancy = Allomancer.new(self)
	add_child(allomancy)
	var layer := CanvasLayer.new()
	layer.name = "LinesLayer"
	layer.layer = CanvasLayers.LINES
	layer.follow_viewport_enabled = true
	var lines_node := BlueLines.new()
	lines_node.allomancer = allomancy
	layer.add_child(lines_node)
	add_child(layer)


func _unhandled_input(event: InputEvent) -> void:
	if not scripted:
		controls.on_input_event(event)


func _physics_process(delta: float) -> void:
	if not scripted:
		controls.read_device(self, delta)
	var t := Game.tuning
	_forgiveness.coyote_time = t.coyote_time
	_forgiveness.buffer_time = t.jump_buffer
	_ledge_cooldown = maxf(_ledge_cooldown - delta, 0.0)
	_wall_jump_lock = maxf(_wall_jump_lock - delta, 0.0)

	allomancy.physics_update(delta)
	match state:
		State.NORMAL:
			_normal(delta, t)
		State.LEDGE_HANG:
			_ledge_hang()
		State.BRACKET_HANG:
			_bracket_hang()
	if scripted:
		controls.end_frame()


func chest_position() -> Vector2:
	return global_position + (Vector2(0, -18) if crouching else CHEST)


func _normal(delta: float, t: Tuning) -> void:
	var on_floor := is_on_floor()
	_forgiveness.tick(delta, on_floor)
	if controls.jump_pressed:
		_forgiveness.press()

	_update_crouch(on_floor)
	var input_x := 0.0 if _wall_jump_lock > 0.0 else controls.move.x
	if input_x != 0.0:
		facing = int(signf(input_x))
	var top := (t.crouch_speed if crouching else t.run_speed) * speed_scale
	var forced := allomancy.force_active
	# While a Push acts on her, ground friction does not eat the force.
	velocity.x = MovementMath.horizontal(t, velocity.x, input_x, on_floor and not forced, delta, top)

	if forced:
		velocity.y += ForceModel.push_gravity(t, velocity.y) * delta
		# Jump cancels downward speed mid-Push (DESIGN.md 5.4).
		if controls.jump_pressed and not on_floor and velocity.y > 0.0:
			velocity.y = 0.0
	else:
		var held := controls.jump_held and _jump_held_since_jump
		velocity.y += MovementMath.gravity(t, velocity.y, held) * delta
	if not controls.jump_held and _jump_held_since_jump and velocity.y < 0.0:
		velocity.y *= t.jump_cut
		_jump_held_since_jump = false

	var sliding := _wall_sliding(on_floor)
	if sliding:
		velocity.y = minf(velocity.y, t.wall_slide_speed)
	velocity.y = minf(velocity.y, t.max_fall_speed)

	if _forgiveness.consume():
		_jump(t)
	elif sliding and _forgiveness.has_buffered_press():
		_forgiveness.clear_press()
		_wall_jump(t)

	var fall_speed := velocity.y
	move_and_slide()
	if is_on_floor() and not _was_on_floor:
		landed.emit(fall_speed)
	_was_on_floor = is_on_floor()
	if not is_on_floor() and velocity.y >= 0.0:
		_try_ledge_grab()


func _jump(t: Tuning) -> void:
	velocity.y = -t.jump_speed() * sqrt(jump_scale)
	_jump_held_since_jump = true
	crouching = false
	_apply_shape()
	jumped.emit()


func _wall_jump(t: Tuning) -> void:
	var away := get_wall_normal().x
	velocity = Vector2(away * t.wall_jump_speed.x, -t.wall_jump_speed.y)
	facing = int(signf(away))
	_wall_jump_lock = t.wall_jump_lock
	_jump_held_since_jump = true
	jumped.emit()


func _wall_sliding(on_floor: bool) -> bool:
	if on_floor or not is_on_wall() or velocity.y < 0.0:
		return false
	var into_wall := controls.move.x != 0.0 and signf(controls.move.x) == -signf(get_wall_normal().x)
	return into_wall


func _update_crouch(on_floor: bool) -> void:
	var want := on_floor and controls.move.y > 0.5
	if want == crouching:
		return
	if not want and not _room_to_stand():
		return
	crouching = want
	_apply_shape()


func _apply_shape() -> void:
	var rect := _crouch_rect if crouching else _stand_rect
	_shape.shape = rect
	_shape.position = Vector2(0, -rect.size.y / 2.0)


func _room_to_stand() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _stand_rect
	query.transform = Transform2D(0.0, global_position + Vector2(0, -STAND_HEIGHT / 2.0 - 1.0))
	query.collision_mask = Layers.WORLD
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _ray(from: Vector2, to: Vector2) -> Dictionary:
	var q := PhysicsRayQueryParameters2D.create(from, to, Layers.WORLD, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(q)


## Grabs a ledge when falling past the top of a wall Vin is moving into.
func _try_ledge_grab() -> void:
	if _ledge_cooldown > 0.0 or crouching:
		return
	var dir := facing
	if controls.move.x != 0.0:
		dir = int(signf(controls.move.x))
	elif not is_on_wall():
		return
	var reach := HALF_WIDTH + LEDGE_REACH
	var hand := global_position + Vector2(0, LEDGE_HAND_Y)
	var low := _ray(hand + Vector2(0, 6), hand + Vector2(dir * reach, 6))
	var high := _ray(hand + Vector2(0, -8), hand + Vector2(dir * reach, -8))
	if low.is_empty() or not high.is_empty():
		return
	var top := _ray(Vector2(low.position.x + dir * 2.0, hand.y - 8.0), Vector2(low.position.x + dir * 2.0, hand.y + 8.0))
	if top.is_empty() or top.normal.y > -0.7:
		return
	global_position = Vector2(low.position.x - dir * (HALF_WIDTH + 0.5), top.position.y - LEDGE_HAND_Y)
	_ledge_point = top.position
	velocity = Vector2.ZERO
	facing = dir
	state = State.LEDGE_HANG
	reset_physics_interpolation()


func _ledge_hang() -> void:
	velocity = Vector2.ZERO
	if controls.jump_pressed or controls.move.y < -0.5:
		state = State.NORMAL
		global_position = _ledge_point + Vector2(facing * (HALF_WIDTH + 2.0), -0.5)
		velocity = Vector2(facing * 30.0, 0.0)
		reset_physics_interpolation()
	elif controls.move.y > 0.5 or (controls.move.x != 0.0 and signf(controls.move.x) != facing):
		state = State.NORMAL
		_ledge_cooldown = 0.3


## Pulled to an anchor: hang from it by the hands until released.
func cling_to(source: MetalSource) -> void:
	if state == State.BRACKET_HANG:
		return
	state = State.BRACKET_HANG
	_cling_source = source
	velocity = Vector2.ZERO


func _bracket_hang() -> void:
	velocity = Vector2.ZERO
	if not is_instance_valid(_cling_source):
		state = State.NORMAL
		return
	global_position = _cling_source.global_position - CHEST
	if controls.jump_pressed:
		state = State.NORMAL
		_jump(Game.tuning)
	elif not controls.pull_held:
		state = State.NORMAL


func _process(_delta: float) -> void:
	queue_redraw()


## Placeholder art until the character art pass.
func _draw() -> void:
	var h := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	draw_rect(Rect2(-HALF_WIDTH, -h, HALF_WIDTH * 2.0, h), Color(0.16, 0.16, 0.2))
	draw_rect(Rect2(-HALF_WIDTH + 1, -h, HALF_WIDTH * 2.0 - 2, 10), Color(0.85, 0.72, 0.62))
	draw_rect(Rect2(-HALF_WIDTH, -h, HALF_WIDTH * 2.0, 4), Color(0.05, 0.05, 0.06))
	draw_rect(Rect2(facing * 2.0 - 1.0, -h + 5, 2, 2), Color.BLACK)
