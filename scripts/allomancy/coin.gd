class_name Coin
extends RigidBody2D
## A clip (or a settled pile of them). Rests as an anchor inside the anchor
## cone, skids outside it, becomes a lethal projectile when Pushed fast.

const CLIP_MASS := 0.01
const RADIUS := 2.0

## Clips in this coin; settled coins merge into piles to hold the physics budget.
var count := 1
var source: MetalSource
## Who threw or last Pushed it; projectiles never hit their own thrower.
var thrower: Node
var spawn_order := 0

static var _next_order := 0

var _since_ground := 1000
## Normal of the surface the coin last rested on.
var ground_normal := Vector2.UP


func _ready() -> void:
	_next_order += 1
	spawn_order = _next_order
	mass = CLIP_MASS * count
	collision_layer = Layers.METAL
	collision_mask = Layers.WORLD | Layers.ENEMY | Layers.SHIELD
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 4
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.15
	physics_material_override.friction = 0.9
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	source = MetalSource.new()
	source.kind = MetalSource.Kind.DYNAMIC
	source.mass = CLIP_MASS * count
	add_child(source)
	add_to_group("coins")
	body_entered.connect(_on_body_entered)
	sleeping_state_changed.connect(_on_sleeping_state_changed)
	_enforce_budget.call_deferred()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var grounded := false
	for i in state.get_contact_count():
		var n := state.get_contact_local_normal(i)
		if n.dot(Vector2.UP) > 0.6:
			grounded = true
			ground_normal = n
	if grounded and _since_ground > 6 and state.linear_velocity.length() > 40.0:
		Audio.play.call_deferred("coin_ring", global_position, -10.0)
	_since_ground = 0 if grounded else _since_ground + 1
	var cap := Game.tuning.projectile_max_speed * 1.05
	if state.linear_velocity.length() > cap:
		state.linear_velocity = state.linear_velocity.limit_length(cap)


## Anchored for a Push in this direction: resting (or just left the ground,
## or barely bouncing) and the Push is inside the anchor cone.
func is_anchored_for(push_dir: Vector2) -> bool:
	if not is_supported():
		return false
	return AnchorCone.classify(push_dir, ground_normal, Game.tuning.anchor_cone_degrees).anchored


## Resting, just left the ground (Push coyote time), or barely bouncing.
func is_supported() -> bool:
	var t := Game.tuning
	if _since_ground <= t.coin_coyote_frames:
		return true
	if linear_velocity.length() < t.coin_bounce_accept_speed:
		var q := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, RADIUS + 4.0), Layers.WORLD)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			ground_normal = hit.normal
			return true
	return false


func receive_push(impulse: Vector2, _from: MetalSource) -> Vector2:
	var t := Game.tuning
	var dir := impulse.normalized()
	if is_supported():
		var c := AnchorCone.classify(dir, ground_normal, t.anchor_cone_degrees, t.coin_partial_lift)
		if c.anchored:
			return impulse
		if c.lift > 0.0:
			if linear_velocity.dot(c.tangent) < t.coin_skid_speed:
				linear_velocity = c.tangent * t.coin_skid_speed
			return impulse * c.lift
	return PushPhysics.dynamic(self, impulse, t.vin_mass, t)


func _physics_process(_delta: float) -> void:
	# A coin someone else Pushed can hit Vin.
	if thrower == null or thrower is Vin or not is_lethal():
		return
	var v := get_tree().get_first_node_in_group("player") as Vin
	if v == null:
		return
	var d := global_position - v.global_position
	if absf(d.x) < Vin.HALF_WIDTH + 3.0 and d.y < 2.0 and d.y > -Vin.STAND_HEIGHT:
		v.take_hit(Hit.make(Hit.Kind.COIN, 25.0, linear_velocity.normalized(), self, true))
		linear_velocity *= 0.15
		thrower = null


func is_lethal() -> bool:
	return linear_velocity.length() > Game.tuning.coin_lethal_speed


func _on_body_entered(body: Node) -> void:
	if body == thrower or not is_lethal():
		return
	if body is Enemy:
		if not body.take_hit(Hit.make(Hit.Kind.COIN, 100.0, linear_velocity.normalized(), self)):
			linear_velocity = -linear_velocity * 0.35
		else:
			linear_velocity *= 0.15
		return
	if body.has_method("take_hit"):
		body.take_hit(Hit.make(Hit.Kind.COIN, 100.0, linear_velocity.normalized(), self))
		linear_velocity *= 0.15


## Steers toward the recalling Allomancer's chest.
func recall_toward(point: Vector2, delta: float) -> void:
	var t := Game.tuning
	sleeping = false
	var desired := (point - global_position).normalized() * t.coin_recall_speed
	linear_velocity = linear_velocity.move_toward(desired, t.coin_recall_accel * delta)


func absorb(other: Coin) -> void:
	count += other.count
	mass = CLIP_MASS * count
	source.mass = CLIP_MASS * count
	other.count = 0
	other.queue_free()
	queue_redraw()


func _on_sleeping_state_changed() -> void:
	if not sleeping or count == 0:
		return
	for other in get_tree().get_nodes_in_group("coins"):
		var o := other as Coin
		if o != self and o.count > 0 and o.sleeping and o.global_position.distance_to(global_position) <= Game.tuning.coin_merge_radius:
			absorb(o)
	_enforce_budget()


## Over budget: fold the oldest settled coin into its nearest settled neighbour.
func _enforce_budget() -> void:
	if not is_inside_tree():
		return
	var live := get_tree().get_nodes_in_group("coins").filter(func(c): return (c as Coin).count > 0)
	var excess := live.size() - Game.tuning.coin_max_active
	if excess <= 0:
		return
	var settled := live.filter(func(c): return (c as Coin).sleeping)
	settled.sort_custom(func(a, b): return a.spawn_order < b.spawn_order)
	while excess > 0 and settled.size() >= 2:
		var oldest: Coin = settled.pop_front()
		var nearest: Coin = settled[0]
		for c in settled:
			if c.global_position.distance_squared_to(oldest.global_position) < nearest.global_position.distance_squared_to(oldest.global_position):
				nearest = c
		nearest.absorb(oldest)
		excess -= 1


func _draw() -> void:
	var c := Color(0.8, 0.55, 0.35)
	if count == 1:
		draw_rect(Rect2(-1.5, -1, 3, 2), c)
	else:
		for i in mini(count, 4):
			draw_rect(Rect2(-2 + (i % 2), 0 - i, 4, 1), c.darkened(0.1 * (i % 2)))
