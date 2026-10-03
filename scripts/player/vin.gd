class_name Vin
extends CharacterBody2D
## The player character. Base movement (run, jump, ledge grab, wall slide,
## crouch) with Celeste-style forgiveness. The origin is at Vin's feet.

signal landed(fall_speed: float)
signal jumped
signal hurt(hit: Hit)
signal died
signal crashed

enum State { NORMAL, LEDGE_HANG, BRACKET_HANG, STAGGER }

const HALF_WIDTH := 6.0
const STAND_HEIGHT := 44.0
const CROUCH_HEIGHT := 26.0
const CHEST := Vector2(0, -30)
const SHOULDERS := Vector2(0, -36)
const LEDGE_REACH := 7.0
const LEDGE_HAND_Y := -40.0

## When true, controls are set by code (tests, cutscenes) instead of the device.
@export var scripted := false

var controls := PlayerControls.new()
var reserves := MetalReserves.new()
var allomancy: Allomancer
var pouch: CoinPouch
var senses: TinSense
var cloak: Mistcloak
## Vin wears the mistcloak; Valette's gowns turn it off (DESIGN.md 4).
var wears_cloak := true:
	set(value):
		wears_cloak = value
		if cloak:
			cloak.visible = value
			if value:
				cloak.reset(global_position + SHOULDERS)
var health := Health.new(100.0)
var pewter_on := false
var tin_on := false
var copper_on := false
var bronze_on := false
## Seconds of the pewter crash left: the stagger, then the slowdown.
var crash_time_left := 0.0
var invulnerable := false
## How strongly the mists swirl toward Vin (0..1): rises while she burns
## metal, settles when she stops.
var mist_strength := 0.0
var mist_phase := 0.0
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
var _stagger_left := 0.0
var _stunned := false
var _pewter := PewterBurn.new()


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
	MistField.add_attractor(self)
	allomancy = Allomancer.new(self)
	add_child(allomancy)
	pouch = CoinPouch.new(self)
	add_child(pouch)
	senses = TinSense.new(self)
	add_child(senses)
	# The mists are faintly luminescent: Vin is never a black hole in the night.
	var glow := PointLight2D.new()
	glow.name = "MistGlow"
	glow.texture = Lantern._light_texture()
	glow.texture_scale = 0.9
	glow.color = Color(0.62, 0.68, 0.85)
	glow.energy = 0.9
	glow.position = CHEST
	add_child(glow)
	cloak = Mistcloak.new()
	cloak.name = "Mistcloak"
	add_child(cloak)
	cloak.reset(global_position + SHOULDERS)
	var layer := CanvasLayer.new()
	layer.name = "LinesLayer"
	layer.layer = CanvasLayers.LINES
	layer.follow_viewport_enabled = true
	var lines_node := BlueLines.new()
	lines_node.allomancer = allomancy
	layer.add_child(lines_node)
	var overlay := SenseOverlay.new()
	overlay.vin = self
	layer.add_child(overlay)
	add_child(layer)
	health.died.connect(func(): died.emit())


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

	_burn_toggles(delta, t)
	senses.physics_update(delta)
	if state != State.STAGGER:
		pouch.physics_update(delta)
		allomancy.physics_update(delta)
	match state:
		State.NORMAL:
			_normal(delta, t)
		State.LEDGE_HANG:
			_ledge_hang()
		State.BRACKET_HANG:
			_bracket_hang()
		State.STAGGER:
			_stagger(delta, t)
	_update_mist_pull(delta)
	if wears_cloak:
		var shoulders := global_position + (Vector2(0, -20) if crouching else SHOULDERS)
		cloak.step(delta, shoulders, velocity, facing)
	if scripted:
		controls.end_frame()


func _exit_tree() -> void:
	MistField.remove_attractor(self)


## True while any metal burns: Push or Pull acting, or a toggled metal on.
func burning_metal() -> bool:
	return allomancy.force_active or pewter_on or tin_on or copper_on or bronze_on


func pewter_flared() -> bool:
	return pewter_on and controls.flare_held


## Keys 1 to 4 toggle pewter, tin, copper and bronze; each burns
## continuously while on and goes out when its reserve is empty.
func _burn_toggles(delta: float, t: Tuning) -> void:
	var c := controls
	if c.toggle_pewter:
		pewter_on = not pewter_on and reserves.has(MetalReserves.Metal.PEWTER)
	if c.toggle_tin:
		tin_on = not tin_on and reserves.has(MetalReserves.Metal.TIN)
	if c.toggle_copper:
		copper_on = not copper_on and reserves.has(MetalReserves.Metal.COPPER)
	if c.toggle_bronze:
		bronze_on = not bronze_on and reserves.has(MetalReserves.Metal.BRONZE)
	var flared := pewter_flared()
	if pewter_on:
		reserves.burn(MetalReserves.Metal.PEWTER, delta, flared)
		health.heal(t.pewter_regen * delta)
	if _pewter.update(delta, pewter_on, flared, reserves.has(MetalReserves.Metal.PEWTER), t):
		_crash(t)
	if pewter_on and not reserves.has(MetalReserves.Metal.PEWTER):
		pewter_on = false
	tin_on = tin_on and reserves.burn(MetalReserves.Metal.TIN, delta, c.flare_held) and reserves.has(MetalReserves.Metal.TIN)
	copper_on = copper_on and reserves.burn(MetalReserves.Metal.COPPER, delta, false) and reserves.has(MetalReserves.Metal.COPPER)
	bronze_on = bronze_on and reserves.burn(MetalReserves.Metal.BRONZE, delta, false) and reserves.has(MetalReserves.Metal.BRONZE)

	crash_time_left = maxf(crash_time_left - delta, 0.0)
	var slowed := crash_time_left > 0.0 and crash_time_left <= t.crash_slow_seconds
	speed_scale = (t.pewter_flare_speed if flared else (t.pewter_speed if pewter_on else 1.0))
	jump_scale = (t.pewter_flare_jump if flared else (t.pewter_jump if pewter_on else 1.0))
	if slowed:
		speed_scale *= t.crash_slow_speed


func _crash(t: Tuning) -> void:
	pewter_on = false
	crash_time_left = t.crash_stagger + t.crash_slow_seconds
	_enter_stagger(t.crash_stagger)
	crashed.emit()


## A blow lands on Vin. Pewter halves damage (quarters flared) and shrugs off
## light hits without staggering.
func take_hit(hit: Hit) -> bool:
	if invulnerable or health.is_dead():
		return false
	var t := Game.tuning
	var mult := 1.0
	if pewter_flared():
		mult = t.pewter_flare_damage
	elif pewter_on:
		mult = t.pewter_damage
	health.damage(hit.damage * mult)
	hurt.emit(hit)
	if not (pewter_on and hit.light):
		velocity += hit.direction * 120.0
		_enter_stagger(t.light_hit_stagger if hit.light else t.heavy_hit_stagger)
	return true


func _enter_stagger(time: float) -> void:
	state = State.STAGGER
	_stagger_left = maxf(_stagger_left, time)
	crouching = false
	_apply_shape()


## Blinded by a flash: no control for a moment.
func stun(time: float) -> void:
	_stunned = true
	_enter_stagger(time)


func stunned() -> bool:
	return _stunned and state == State.STAGGER


func clear_stun() -> void:
	if _stunned:
		_stunned = false
		_stagger_left = 0.0


func _stagger(delta: float, t: Tuning) -> void:
	_stagger_left -= delta
	velocity.x = move_toward(velocity.x, 0.0, t.ground_decel * delta)
	velocity.y = minf(velocity.y + MovementMath.gravity(t, velocity.y, false) * delta, t.max_fall_speed)
	move_and_slide()
	if _stagger_left <= 0.0:
		_stunned = false
		state = State.NORMAL


func _update_mist_pull(delta: float) -> void:
	var target := 1.0 if burning_metal() else 0.0
	var rate := 2.0 if target > mist_strength else 0.7
	mist_strength = move_toward(mist_strength, target, rate * delta)
	mist_phase += mist_strength * delta * 1.6


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

	if not on_floor:
		_correct_corners(delta, t)
	var fall_speed := velocity.y
	move_and_slide()
	for i in get_slide_collision_count():
		var other := get_slide_collision(i).get_collider()
		if other and other.has_method("shoulder"):
			other.shoulder(self)
	if is_on_floor() and not _was_on_floor:
		landed.emit(fall_speed)
	_was_on_floor = is_on_floor()
	if not is_on_floor() and velocity.y >= 0.0:
		_try_ledge_grab()


## Celeste-style corner correction: rising into a ceiling edge nudges Vin
## sideways past it; flying into a ledge lip lifts her over it.
func _correct_corners(delta: float, t: Tuning) -> void:
	var motion := velocity * delta
	var xf := global_transform
	if velocity.y < 0.0 and test_move(xf, Vector2(0, motion.y)):
		for i in range(1, t.corner_correction + 1):
			for dir in [1, -1]:
				var off := Vector2(dir * i, 0)
				if not test_move(xf, off) and not test_move(xf.translated(off), Vector2(0, motion.y)):
					global_position += off
					return
	if absf(velocity.x) > 1.0 and test_move(xf, Vector2(motion.x, 0)):
		for i in range(1, t.ledge_correction + 1):
			var up := Vector2(0, -i)
			if not test_move(xf, up) and not test_move(xf.translated(up), Vector2(motion.x, 0)):
				global_position += up
				return


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
	draw_rect(Rect2(-HALF_WIDTH, -h, HALF_WIDTH * 2.0, h), Color(0.3, 0.29, 0.34))
	draw_rect(Rect2(-HALF_WIDTH + 1, -h, HALF_WIDTH * 2.0 - 2, 10), Color(0.85, 0.72, 0.62))
	draw_rect(Rect2(-HALF_WIDTH, -h, HALF_WIDTH * 2.0, 4), Color(0.05, 0.05, 0.06))
	draw_rect(Rect2(facing * 2.0 - 1.0, -h + 5, 2, 2), Color.BLACK)
