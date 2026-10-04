class_name Kelsier
extends Node2D
## Kelsier as a companion or a demonstrator (DESIGN.md 8; mission notes).
## Companion: follows Vin's own path, so he never leaves it or Pushes off
## into traversal, engages the nearest threat with dagger and shove, cannot
## die and has no body to block a doorway with. Demonstrator: performs one
## scripted move at a lesson beat, then waits as a silhouette at the next
## vantage point. KelsierMarker nodes script him; the same character will
## serve Ham and Breeze.

enum Mode { COMPANION, DEMONSTRATOR }

@export var mode := Mode.COMPANION
## A node whose KelsierMarker children script him, in order.
@export var markers_path: NodePath
## Test and staging aid: stand still.
@export var hold_position := false

const FOLLOW_DISTANCE := 36.0
const FOLLOW_SPEED := 240.0
const ENGAGE_RANGE := 160.0
const STRIKE_INTERVAL := 0.55
const SHOVE_INTERVAL := 2.4
const HEIGHT := 52.0

var facing := 1
var performing := false
var silhouette := false
var landed_blows := 0
var _markers: Array[KelsierMarker] = []
var _step := 0
var _trail := PackedVector2Array()
var _strike_cd := 0.0
var _shove_cd := 0.0
var _move_from := Vector2.ZERO
var _move_t := 0.0
var _move_marker: KelsierMarker
var _advance_after := true


func _ready() -> void:
	add_to_group("allies")
	if markers_path and has_node(markers_path):
		for c in get_node(markers_path).get_children():
			if c is KelsierMarker:
				_markers.append(c)
	_enter_step()


func vin() -> Vin:
	return get_tree().get_first_node_in_group("player") as Vin


## The current marker's action, or -1 with no script left.
func step_action() -> int:
	return _markers[_step].action if _step < _markers.size() else -1


func take_hit(_hit: Hit) -> bool:
	return false


func _enter_step() -> void:
	silhouette = false
	if _step >= _markers.size():
		return
	var m := _markers[_step]
	mode = Mode.COMPANION if m.action == KelsierMarker.Action.COMPANION else Mode.DEMONSTRATOR


func _next_step() -> void:
	_step += 1
	_trail.clear()
	_enter_step()


func _physics_process(delta: float) -> void:
	var v := vin()
	if v == null:
		return
	_record(v)
	_strike_cd = maxf(_strike_cd - delta, 0.0)
	_shove_cd = maxf(_shove_cd - delta, 0.0)
	if performing:
		_perform(delta)
	elif _step < _markers.size():
		var m := _markers[_step]
		match m.action:
			KelsierMarker.Action.DEMONSTRATE:
				face_toward(v.global_position.x)
				if v.global_position.distance_to(global_position) < m.trigger_radius:
					_begin_move(m)
			KelsierMarker.Action.WAIT:
				if global_position.distance_to(m.global_position) > 2.0:
					# Travel to the vantage point first, then wait there.
					_begin_move(m, false)
					return
				silhouette = true
				if v.global_position.distance_to(m.global_position) < m.trigger_radius:
					_next_step()
			KelsierMarker.Action.COMPANION:
				_companion(delta, v)
				if _step < _markers.size() - 1 and v.global_position.distance_to(m.global_position) < m.trigger_radius:
					_next_step()
	elif mode == Mode.COMPANION:
		_companion(delta, v)
	queue_redraw()


func face_toward(x: float) -> void:
	if absf(x - global_position.x) > 2.0:
		facing = 1 if x > global_position.x else -1


func _begin_move(m: KelsierMarker, advance := true) -> void:
	performing = true
	_advance_after = advance
	_move_marker = m
	_move_from = global_position
	_move_t = 0.0
	face_toward(m.global_position.x)
	if m.move == KelsierMarker.Move.COIN_JUMP:
		var c := Coin.new()
		c.thrower = self
		c.position = global_position + Vector2(0, -3)
		get_parent().add_child(c)


func _perform(delta: float) -> void:
	var m := _move_marker
	_move_t += delta / maxf(m.duration, 0.05)
	var u := minf(_move_t, 1.0)
	var to := m.global_position
	match m.move:
		KelsierMarker.Move.WALK, KelsierMarker.Move.PULL:
			global_position = _move_from.lerp(to, u)
		_:
			var apex := minf(_move_from.y, to.y) - m.arc_height
			var p := _move_from.lerp(to, u)
			var base := lerpf(_move_from.y, to.y, u)
			p.y = base + (apex - (_move_from.y + to.y) * 0.5) * 4.0 * u * (1.0 - u)
			global_position = p
	if u >= 1.0:
		performing = false
		if _advance_after:
			_next_step()


func _record(v: Vin) -> void:
	var p := v.global_position
	if _trail.is_empty() or _trail[-1].distance_to(p) > 2.0:
		_trail.append(p)
		if _trail.size() > 600:
			_trail = _trail.slice(_trail.size() - 600)


func _companion(delta: float, v: Vin) -> void:
	if hold_position:
		return
	var foe := _nearest_threat(v)
	if foe:
		_fight(delta, foe)
		return
	_follow(delta, v)


## Walks Vin's own path, staying a little behind her.
func _follow(delta: float, v: Vin) -> void:
	if _trail.is_empty():
		return
	var budget := 0.0
	var target := _trail[-1]
	for i in range(_trail.size() - 1, 0, -1):
		budget += _trail[i].distance_to(_trail[i - 1])
		if budget >= FOLLOW_DISTANCE:
			target = _trail[i - 1]
			break
	if global_position.distance_to(v.global_position) > 220.0:
		global_position = target
		reset_physics_interpolation()
		return
	var step := FOLLOW_SPEED * delta
	var to := target - global_position
	if to.length() > 1.0:
		face_toward(target.x)
	global_position += to.limit_length(step)


func _nearest_threat(v: Vin) -> Enemy:
	var best: Enemy = null
	var best_d := ENGAGE_RANGE
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.dead() or e is Bendal or absf(e.global_position.y - global_position.y) > 24.0:
			continue
		if not (e.aware or e.global_position.distance_to(v.global_position) < 90.0):
			continue
		var d := e.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _fight(delta: float, e: Enemy) -> void:
	face_toward(e.global_position.x)
	var dx := e.global_position.x - global_position.x
	if absf(dx) > 22.0:
		global_position.x += signf(dx) * minf(FOLLOW_SPEED * 0.7 * delta, absf(dx) - 20.0)
		return
	if _shove_cd <= 0.0 and e is Guard and (e as Guard).breastplate:
		_shove_cd = SHOVE_INTERVAL
		e.receive_push(Vector2(facing * 18000.0, -2000.0), (e as Guard).breastplate)
	elif _strike_cd <= 0.0:
		_strike_cd = STRIKE_INTERVAL
		if e.take_hit(Hit.make(Hit.Kind.DAGGER, Game.tuning.dagger_damage, Vector2(facing, 0), self)):
			landed_blows += 1


func _draw() -> void:
	var body := Color(0.22, 0.22, 0.26)
	var skin := Color(0.85, 0.72, 0.6)
	var hair := Color(0.85, 0.75, 0.45)
	if silhouette:
		body = Color(0.08, 0.09, 0.12, 0.85)
		skin = body
		hair = body
	draw_rect(Rect2(-6, -HEIGHT + 10, 12, HEIGHT - 10), body)
	draw_rect(Rect2(-5, -HEIGHT, 10, 10), skin)
	draw_rect(Rect2(-5, -HEIGHT, 10, 3), hair)
	if not silhouette:
		draw_rect(Rect2(facing * 2.0 - 1.0, -HEIGHT + 5, 2, 2), Color.BLACK)
	# Cloak tassels.
	for i in 4:
		draw_line(Vector2(-facing * 4.0 + i - 2, -HEIGHT + 12), Vector2(-facing * 9.0 + i * 2 - 3, -8), Color(body, 0.8), 1.0)
