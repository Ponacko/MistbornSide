class_name Bendal
extends Enemy
## Inquisitor Bendal as a pursuer (DESIGN.md 10.4): he runs an authored
## route behind Vin at pewter speed, coin-jumping the climbs, closes in when
## she stalls, Pushes her coins back at her and strikes with an obsidian axe
## that takes most of her health. His spikes are metal inside his body: Vin
## sees their lines but cannot Push them. The mists part around him.

signal struck

enum Phase { WAITING, PURSUING, ATTACKING, RECOVERING, DONE }

## World-space route he follows, start to end.
@export var route := PackedVector2Array()
## Optional Line2D whose points are the route.
@export var route_line: NodePath
## Starts the pursuit this long after the level begins; negative waits for start().
@export var start_delay := -1.0

var phase := Phase.WAITING
var progress := 0.0
var _lengths := PackedFloat32Array()
var _total := 0.0
var _timer := 0.0
var _swings_left := 0
var _last_segment := -1


func _init() -> void:
	max_health = 3000.0
	misting_label = "Inquisitor"
	seeker = true


func _ready() -> void:
	super._ready()
	if route_line and has_node(route_line):
		var line := get_node(route_line) as Line2D
		route = PackedVector2Array()
		for p in line.points:
			route.append(line.to_global(p))
	for x in [-3.0, 3.0]:
		var spike := MetalSource.new()
		spike.kind = MetalSource.Kind.CARRIED
		spike.inside_body = true
		spike.mass = 0.5
		spike.position = Vector2(x, -HEIGHT - 2)
		add_child(spike)
	var rep := MistRepeller.new()
	rep.radius = 80.0
	rep.position = Vector2(0, -30)
	add_child(rep)
	_measure()
	if not route.is_empty():
		global_position = route[0]
	Checkpoints.respawned.connect(_on_vin_respawned)
	if start_delay >= 0.0:
		get_tree().create_timer(start_delay, false, true).timeout.connect(start)


func _measure() -> void:
	_lengths.clear()
	_total = 0.0
	for i in range(1, route.size()):
		_lengths.append(route[i - 1].distance_to(route[i]))
		_total += _lengths[-1]


## After a death the chase restarts with Bendal a fair distance behind.
func _on_vin_respawned() -> void:
	var v := vin()
	if v == null or phase == Phase.DONE or phase == Phase.WAITING:
		return
	progress = 0.0
	_last_segment = -1
	var target_x := v.global_position.x - Game.tuning.bendal_catch_up_gap
	while progress < _total and global_position.x < target_x:
		_advance(8.0)
	phase = Phase.PURSUING
	reset_physics_interpolation()


func start() -> void:
	if phase == Phase.WAITING:
		phase = Phase.PURSUING
		notice()


func stop() -> void:
	phase = Phase.DONE


func _physics_process(delta: float) -> void:
	var t := Game.tuning
	var v := vin()
	_return_coins(v, t)
	match phase:
		Phase.PURSUING:
			_pursue(delta, v, t)
		Phase.ATTACKING:
			_timer -= delta
			if _timer <= 0.0:
				_swing(v, t)
		Phase.RECOVERING:
			_timer -= delta
			if _timer <= 0.0:
				phase = Phase.PURSUING
	queue_redraw()


func _pursue(delta: float, v: Vin, t: Tuning) -> void:
	if v and not v.is_dead():
		var dx := v.global_position.x - global_position.x
		face_toward(v.global_position.x)
		if absf(dx) <= t.bendal_reach and absf(v.global_position.y - global_position.y) < 40.0:
			phase = Phase.ATTACKING
			_swings_left = 2
			_timer = t.bendal_windup
			return
	var gap := 0.0
	if v:
		gap = v.global_position.x - global_position.x
	var speed := t.bendal_catch_up_speed if gap > t.bendal_catch_up_gap else t.bendal_speed
	_advance(speed * delta)


func _advance(distance: float) -> void:
	if route.size() < 2:
		return
	progress = minf(progress + distance, _total)
	var acc := 0.0
	for i in _lengths.size():
		if acc + _lengths[i] >= progress or i == _lengths.size() - 1:
			var f := clampf((progress - acc) / maxf(_lengths[i], 0.001), 0.0, 1.0)
			global_position = route[i].lerp(route[i + 1], f)
			if i != _last_segment:
				_last_segment = i
				if route[i + 1].y < route[i].y - 20.0:
					_coin_jump()
			return
		acc += _lengths[i]


## The coin he drops and Pushes off to launch up a climb.
func _coin_jump() -> void:
	var c := Coin.new()
	c.thrower = self
	c.position = global_position + Vector2(0, -3)
	c.linear_velocity = Vector2(0, 200)
	get_parent().add_child.call_deferred(c)


func _swing(v: Vin, t: Tuning) -> void:
	NoiseBus.emit(global_position, 0.9, NoiseBus.Kind.FIGHT)
	if v and not v.is_dead():
		var dx := v.global_position.x - global_position.x
		if absf(dx) <= t.bendal_reach + 8.0 and absf(v.global_position.y - global_position.y) < 40.0:
			if v.take_hit(Hit.make(Hit.Kind.AXE, t.bendal_axe_damage, Vector2(facing, 0), self, false)):
				struck.emit()
	_swings_left -= 1
	if _swings_left > 0:
		phase = Phase.ATTACKING
		_timer = t.bendal_second_swing
	else:
		phase = Phase.RECOVERING
		_timer = t.bendal_recover


## Seconds until his next axe stroke lands, or -1 if none is coming (the
## recovery window atium reveals).
func time_to_next_strike() -> float:
	if phase == Phase.ATTACKING:
		return _timer
	return -1.0


func recovering() -> bool:
	return phase == Phase.RECOVERING


## Coins Vin throws at him come back at her.
func _return_coins(v: Vin, t: Tuning) -> void:
	if v == null:
		return
	for n in get_tree().get_nodes_in_group("coins"):
		var c := n as Coin
		if c.thrower == self or c.count <= 0:
			continue
		if c.global_position.distance_to(chest_position()) < t.bendal_coin_return_range and c.linear_velocity.length() > 150.0:
			c.thrower = self
			c.linear_velocity = (v.chest_position() - c.global_position).normalized() * t.projectile_max_speed * 0.8


func take_hit(hit: Hit) -> bool:
	# Unwinnable by design: he barely notices.
	return super.take_hit(Hit.make(hit.kind, hit.damage * 0.1, hit.direction, hit.source, true))


func receive_push(impulse: Vector2, _source: MetalSource) -> Vector2:
	return impulse


func _draw() -> void:
	var robe := Color(0.12, 0.1, 0.12)
	draw_rect(Rect2(-HALF_WIDTH - 1, -HEIGHT - 4, HALF_WIDTH * 2.0 + 2, HEIGHT + 4), robe)
	draw_rect(Rect2(-HALF_WIDTH + 1, -HEIGHT - 4, HALF_WIDTH * 2.0 - 2, 9), Color(0.78, 0.7, 0.66))
	draw_rect(Rect2(facing * 2.0 - 1.5, -HEIGHT + 0, 3, 3), Color(0.55, 0.58, 0.62))
	for x in [-3.0, 3.0]:
		draw_line(Vector2(x, -HEIGHT - 4), Vector2(x - facing * 4.0, -HEIGHT - 9), Color(0.6, 0.62, 0.66), 1.0)
	var swing := phase == Phase.ATTACKING
	var head := Vector2(facing * (24.0 if not swing else 10.0), -34 if not swing else -46)
	draw_line(Vector2(0, -26), head, Color(0.35, 0.28, 0.2), 2.0)
	draw_rect(Rect2(head + Vector2(-3, -4), Vector2(6, 8)), Color(0.08, 0.08, 0.1))
