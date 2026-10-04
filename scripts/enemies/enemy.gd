class_name Enemy
extends CharacterBody2D
## Shared body for human enemies: health, gravity, patrol walking, Push and
## Pull response by body mass through carried metal, death by falls.
## Subclasses implement think() to set desired_speed and act.

signal died
signal noticed

## Kilograms, without carried metal.
@export var body_mass := 80.0
@export var max_health := 100.0
@export var walk_speed := 40.0
@export var chase_speed := 95.0
## Patrols this far either side of where he was placed; 0 stands guard.
@export var patrol_distance := 80.0
@export var facing := 1

const HALF_WIDTH := 7.0
const HEIGHT := 44.0

var health: Health
## Knows Vin is here (the alerted stage of suspicion).
var aware := false
var desired_speed := 0.0
var last_hit_kind := -1
var home := Vector2.ZERO
var _stagger := 0.0
var _dead := false
## Shoved off his feet: no footing to resist with for a moment.
var _shoved := 0.0


func _ready() -> void:
	collision_layer = Layers.ENEMY
	collision_mask = Layers.WORLD
	floor_snap_length = 4.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(HALF_WIDTH * 2.0, HEIGHT)
	shape.shape = rect
	shape.position = Vector2(0, -HEIGHT / 2.0)
	add_child(shape)
	health = Health.new(max_health)
	home = global_position
	add_to_group("enemies")
	add_to_group("hittable")


func dead() -> bool:
	return _dead


func vin() -> Vin:
	return get_tree().get_first_node_in_group("player") as Vin


func chest_position() -> Vector2:
	return global_position + Vector2(0, -30)


func is_unaware() -> bool:
	return not aware


func notice() -> void:
	if not aware and not _dead:
		aware = true
		noticed.emit()


func _physics_process(delta: float) -> void:
	var t := Game.tuning
	if not _dead:
		_stagger = maxf(_stagger - delta, 0.0)
		if _stagger <= 0.0:
			think(delta)
		else:
			desired_speed = 0.0
	else:
		desired_speed = 0.0
	_shoved = maxf(_shoved - delta, 0.0)
	var rate := 600.0 if is_on_floor() and _shoved <= 0.0 else 60.0
	velocity.x = move_toward(velocity.x, desired_speed, rate * delta)
	velocity.y = minf(velocity.y + MovementMath.gravity(t, velocity.y, false) * delta, t.max_fall_speed * 1.5)
	var fall := velocity.y
	move_and_slide()
	if not _dead and is_on_floor() and fall > t.fall_death_speed:
		die()
	queue_redraw()


## Behaviour hook: set desired_speed, attack, turn.
func think(_delta: float) -> void:
	_patrol()


func _patrol() -> void:
	if patrol_distance <= 0.0:
		desired_speed = 0.0
		return
	if (global_position.x - home.x) * facing > patrol_distance or is_on_wall() or not _floor_ahead():
		facing = -facing
	desired_speed = facing * walk_speed


func _floor_ahead() -> bool:
	if not is_on_floor():
		return true
	var from := global_position + Vector2(facing * (HALF_WIDTH + 4.0), -4.0)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 16), Layers.WORLD)
	return not get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func face_toward(x: float) -> void:
	if absf(x - global_position.x) > 2.0:
		facing = 1 if x > global_position.x else -1


## Push or Pull on metal he carries: the whole body moves by its mass.
func receive_push(impulse: Vector2, source: MetalSource) -> Vector2:
	if _dead:
		return impulse
	velocity += impulse / (body_mass + source.mass)
	_shoved = 0.25
	_stagger = maxf(_stagger, 0.2)
	notice()
	return impulse


## Damage multiplier for a hit (armour, shields).
func damage_scale(_hit: Hit) -> float:
	return 1.0


func take_hit(hit: Hit) -> bool:
	if _dead:
		return false
	last_hit_kind = hit.kind
	var amount := hit.damage * damage_scale(hit)
	if amount <= 0.0:
		notice()
		return false
	health.damage(amount)
	NoiseBus.emit(global_position, 0.7, NoiseBus.Kind.FIGHT)
	if health.is_dead():
		die()
	else:
		_stagger = 0.3
		velocity.x += hit.direction.x * 60.0
		notice()
	return true


## Lethal by default: there is no knockout state.
func die() -> void:
	if _dead:
		return
	_dead = true
	aware = false
	collision_layer = 0
	remove_from_group("hittable")
	died.emit()
	on_death()


func on_death() -> void:
	pass
