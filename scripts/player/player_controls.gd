class_name PlayerControls
extends RefCounted
## One frame of player intent. Read from the device each physics frame, or set
## directly by tests and cutscenes when the owner is in scripted mode.

var move := Vector2.ZERO
var jump_pressed := false
var jump_held := false
var push_pressed := false
var push_held := false
var pull_pressed := false
var pull_held := false
var flare_held := false
var flare_pressed := false
var coin_pressed := false
var coin_held := false
var dagger_pressed := false
var dagger_held := false
var dagger_released := false
var dodge_pressed := false
var toggle_pewter := false
var toggle_tin := false
var toggle_copper := false
var toggle_bronze := false
var atium_held := false
var interact_pressed := false
var target_cycle := 0
## Aim point in world space and whether the player is actively aiming (mouse
## moved recently or right stick deflected). With no aim input the targeting
## heuristic takes over.
var aim_point := Vector2.ZERO
var aim_active := false
## True on frames where the player deliberately moved the aim (mouse or
## stick), as opposed to the camera carrying the cursor's world point along.
var aim_moved := false
## True when the last aim input came from a gamepad.
var gamepad := false

const AIM_IDLE_TIME := 1.5
var _last_mouse := Vector2.INF
var _mouse_idle := 0.0
var _wheel := 0
var _last_stick := Vector2.ZERO


## Mouse wheel arrives as events, not polled actions; the owner forwards them.
func on_input_event(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_wheel += 1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_wheel -= 1


func read_device(owner: Node2D, delta: float) -> void:
	move = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_held = Input.is_action_pressed("jump")
	push_pressed = Input.is_action_just_pressed("push")
	push_held = Input.is_action_pressed("push")
	pull_pressed = Input.is_action_just_pressed("pull")
	pull_held = Input.is_action_pressed("pull")
	if Settings.toggle_push:
		apply_toggle_mode(push_pressed, Input.is_action_just_pressed("push"), pull_pressed, Input.is_action_just_pressed("pull"))
	# Clicks on a debug or menu panel are not Pushes.
	if owner.get_viewport().gui_get_hovered_control() != null:
		push_pressed = false
		push_held = false
		pull_pressed = false
		pull_held = false
	flare_held = Input.is_action_pressed("flare")
	flare_pressed = Input.is_action_just_pressed("flare")
	coin_pressed = Input.is_action_just_pressed("coin")
	coin_held = Input.is_action_pressed("coin")
	dagger_pressed = Input.is_action_just_pressed("dagger")
	dagger_held = Input.is_action_pressed("dagger")
	dagger_released = Input.is_action_just_released("dagger")
	dodge_pressed = Input.is_action_just_pressed("dodge")
	toggle_pewter = Input.is_action_just_pressed("toggle_pewter")
	toggle_tin = Input.is_action_just_pressed("toggle_tin")
	toggle_copper = Input.is_action_just_pressed("toggle_copper")
	toggle_bronze = Input.is_action_just_pressed("toggle_bronze")
	atium_held = Input.is_action_pressed("atium")
	interact_pressed = Input.is_action_just_pressed("interact")
	target_cycle = _wheel
	if Input.is_action_just_pressed("target_cycle") and _wheel == 0:
		target_cycle = 1
	_wheel = 0

	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var mouse := owner.get_viewport().get_mouse_position()
	aim_moved = false
	if mouse.distance_to(_last_mouse) > 0.5:
		aim_moved = _last_mouse != Vector2.INF
		_mouse_idle = 0.0
		_last_mouse = mouse
		gamepad = false
	else:
		_mouse_idle += delta
	if stick.length() > 0.3:
		aim_moved = aim_moved or stick.distance_to(_last_stick) > 0.05
		_last_stick = stick
		aim_point = owner.global_position + stick * 160.0
		aim_active = true
		gamepad = true
	else:
		aim_point = owner.get_global_mouse_position()
		aim_active = _mouse_idle < AIM_IDLE_TIME


## Clears one-frame edges. Called at the end of each physics frame in scripted
## mode so a test's "press" lasts exactly one frame.
func end_frame() -> void:
	_last_pressed.clear()
	for a in PRESS_ACTIONS:
		if action_pressed(a):
			_last_pressed[a] = true
	_last_frame = Engine.get_physics_frames()
	jump_pressed = false
	flare_pressed = false
	push_pressed = false
	pull_pressed = false
	coin_pressed = false
	dagger_pressed = false
	dagger_released = false
	dodge_pressed = false
	toggle_pewter = false
	toggle_tin = false
	toggle_copper = false
	toggle_bronze = false
	interact_pressed = false
	target_cycle = 0
	aim_moved = false


const PRESS_ACTIONS := ["jump", "push", "pull", "coin", "dagger", "dodge", "toggle_pewter", "toggle_tin",
	"toggle_copper", "toggle_bronze", "flare", "interact"]
var _last_pressed := {}
var _last_frame := -1


var _push_latched := false
var _pull_latched := false


## Toggle mode (DESIGN.md 7.3): a tap latches Push or Pull on, another tap
## releases it.
func apply_toggle_mode(push_tap: bool, _push_down: bool, pull_tap: bool, _pull_down: bool) -> void:
	if push_tap:
		_push_latched = not _push_latched
		_pull_latched = false
	if pull_tap:
		_pull_latched = not _pull_latched
		_push_latched = false
	push_held = _push_latched
	pull_held = _pull_latched
	push_pressed = push_tap and _push_latched
	pull_pressed = pull_tap and _pull_latched


## Whether the named input action was pressed this frame (scripted mode),
## including by a node that processed before the reader this frame.
func action_pressed(action: String) -> bool:
	if _last_frame == Engine.get_physics_frames() and _last_pressed.has(action):
		return true
	match action:
		"jump": return jump_pressed
		"push": return push_pressed
		"pull": return pull_pressed
		"coin": return coin_pressed
		"dagger": return dagger_pressed
		"dodge": return dodge_pressed
		"toggle_pewter": return toggle_pewter
		"toggle_tin": return toggle_tin
		"toggle_copper": return toggle_copper
		"toggle_bronze": return toggle_bronze
		"flare": return flare_pressed
		"atium": return atium_held
		"interact": return interact_pressed
	return false


## Everything released: what a locked player sends.
func clear() -> void:
	end_frame()
	move = Vector2.ZERO
	jump_held = false
	push_held = false
	pull_held = false
	flare_held = false
	coin_held = false
	dagger_held = false
	atium_held = false
