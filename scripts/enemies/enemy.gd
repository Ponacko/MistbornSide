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
var suspicion := Suspicion.new()
## Knows Vin is here: the alerted stage of suspicion.
var aware: bool:
	get:
		return suspicion.stage == Suspicion.Stage.ALERTED
	set(value):
		if value:
			suspicion.alert()
		else:
			suspicion.level = 0.0
			suspicion.calm(0.0)
## Senses Vin's burning through walls (Seekers, Inquisitors).
var seeker := false
## Shown to bronze as a beacon with this Misting name; empty for none.
var misting_label := ""
var desired_speed := 0.0
var last_hit_kind := -1
var home := Vector2.ZERO
var sprite: CharacterSprite
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
	if misting_label != "":
		add_to_group("allomancers")
	suspicion.stage_changed.connect(_on_stage_changed)
	if art_who() != "":
		sprite = CharacterSprite.new()
		sprite.name = "Sprite"
		sprite.who = art_who()
		add_child(sprite)
	NoiseBus.noise.connect(_on_noise)


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
		var v := vin()
		suspicion.alert(v.global_position if v else Vector2.INF)


func _on_stage_changed(stage: Suspicion.Stage) -> void:
	if stage == Suspicion.Stage.ALERTED:
		noticed.emit()


func _on_noise(pos: Vector2, loudness: float, _kind: NoiseBus.Kind) -> void:
	if _dead:
		return
	var reach := loudness * Game.tuning.hearing_range
	var d := pos.distance_to(global_position)
	if d < reach and d > 1.0:
		suspicion.hear(loudness * (1.0 - d / reach), pos)


## How plainly this enemy sees Vin right now, 0..1. Lantern light exposes
## her; in shadow the mists hide her beyond arm's reach; guards do not look
## up at rooftops unless alerted.
func sight_of_vin() -> float:
	var v := vin()
	if v == null or v.is_dead():
		return 0.0
	var t := Game.tuning
	var d := v.chest_position() - chest_position()
	var dist := d.length()
	var alerted := aware
	if d.x * facing < -8.0 and not alerted:
		return 0.0
	if not alerted and rad_to_deg(atan2(-d.y, absf(d.x))) > t.look_up_degrees:
		return 0.0
	var range := t.sight_range_lit if Stealth.is_lit(v.chest_position()) else t.sight_range_dark
	if dist > range:
		return 0.0
	var q := PhysicsRayQueryParameters2D.create(chest_position(), v.chest_position(), Layers.WORLD)
	if not get_world_2d().direct_space_state.intersect_ray(q).is_empty():
		return 0.0
	return 1.0 - dist / range * 0.6


## Seekers feel any metal Vin burns within their radius unless copper is on.
func seeker_sense() -> float:
	var v := vin()
	if not seeker or v == null or not v.detectable_burning():
		return 0.0
	return Game.tuning.seeker_rate if v.global_position.distance_to(global_position) < Game.tuning.seeker_radius else 0.0


func _physics_process(delta: float) -> void:
	var t := Game.tuning
	if not _dead:
		var v := vin()
		var seen := maxf(sight_of_vin(), seeker_sense())
		suspicion.update(delta, seen, t, v.global_position if v and seen > 0.0 else Vector2.INF)
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


## Suspicious: stop and look toward the last sight or sound, edging closer.
func _investigate() -> void:
	var at := suspicion.last_stimulus
	if at == Vector2.INF:
		desired_speed = 0.0
		return
	face_toward(at.x)
	desired_speed = facing * walk_speed * 0.6 if absf(at.x - global_position.x) > 24.0 and _floor_ahead() else 0.0


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


## What atium shows of this enemy `seconds` from now: {node, pos, attacking,
## safe}. Default: he keeps walking as he is, and strikes if he is winding up
## or will be in reach.
func forecast(seconds: float) -> Dictionary:
	var pos := global_position + Vector2(velocity.x * seconds, 0)
	if not is_on_floor():
		pos.y += velocity.y * seconds
	return {"node": self, "pos": pos, "attacking": winding_up() or _will_strike(seconds), "safe": false}


func winding_up() -> bool:
	return false


func _will_strike(_seconds: float) -> bool:
	return false


## Which CharacterArt figure draws this enemy ("" for none).
func art_who() -> String:
	return ""


## The animation state to show this frame.
func art_state() -> String:
	if _dead:
		return "dead"
	if _stagger > 0.0:
		return "stagger"
	return "walk" if absf(velocity.x) > 5.0 else "idle"


func _process(_delta: float) -> void:
	if sprite:
		sprite.who = art_who()
		sprite.show_state(art_state(), facing)


func _draw() -> void:
	_draw_suspicion()


## The suspicion icon over the head: ? suspicious, ! alerted.
func _draw_suspicion() -> void:
	if _dead:
		return
	var top := Vector2(0, -HEIGHT - 6)
	match suspicion.stage:
		Suspicion.Stage.SUSPICIOUS:
			var c := Settings.palette_color(&"suspicious")
			draw_arc(top + Vector2(0, -6), 2.5, PI, TAU + PI * 0.5, 6, c, 1.0)
			draw_rect(Rect2(top + Vector2(-0.5, -4), Vector2(1, 2)), c)
			draw_rect(Rect2(top + Vector2(-0.5, -1), Vector2(1, 1)), c)
		Suspicion.Stage.ALERTED:
			var c := Settings.palette_color(&"alerted")
			draw_rect(Rect2(top + Vector2(-1, -9), Vector2(2, 6)), c)
			draw_rect(Rect2(top + Vector2(-1, -1), Vector2(2, 2)), c)
