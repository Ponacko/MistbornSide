class_name AlarmBell
extends Node2D
## An alarm bell (DESIGN.md 6.4). When an enemy nearby is alerted, someone
## runs to ring it: it peals across the level, alerts everyone and summons
## reinforcements. It is metal: a Push knocks it askew and it never rings.

signal rang

@export var reach := 450.0
## Where reinforcements appear, in world space.
@export var reinforcements: Array[Vector2] = []

var rung := false
var silenced := false
var source: MetalSource
var _countdown := -1.0


func _ready() -> void:
	source = MetalSource.new()
	source.kind = MetalSource.Kind.ANCHORED
	source.mass = 120.0
	add_child(source)
	source.body = self
	for e in get_tree().get_nodes_in_group("enemies"):
		_watch(e)
	get_tree().node_added.connect(func(n):
		if n is Enemy:
			_watch.call_deferred(n))


func _watch(e: Enemy) -> void:
	if not e.noticed.is_connected(_on_noticed):
		e.noticed.connect(_on_noticed.bind(e))


func _on_noticed(e: Enemy) -> void:
	if rung or silenced or _countdown >= 0.0:
		return
	if e.global_position.distance_to(global_position) <= reach:
		_countdown = Game.tuning.bell_delay


func _physics_process(delta: float) -> void:
	if _countdown < 0.0:
		return
	_countdown -= delta
	if _countdown <= 0.0:
		_countdown = -1.0
		ring()


func ring() -> void:
	if rung or silenced:
		return
	rung = true
	NoiseBus.emit(global_position, 3.0, NoiseBus.Kind.BELL)
	var v := get_tree().get_first_node_in_group("player") as Vin
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.global_position.distance_to(global_position) <= reach * 2.0:
			(e as Enemy).suspicion.alert(v.global_position if v else Vector2.INF)
	for at in reinforcements:
		var g := Guard.new()
		g.position = at
		g.patrol_distance = 0.0
		get_parent().add_child.call_deferred(g)
		g.ready.connect(func(): g.suspicion.alert(v.global_position if v else Vector2.INF), CONNECT_ONE_SHOT)
	rang.emit()
	queue_redraw()


## A Push or Pull on the bell knocks it askew: it will not ring.
func receive_push(impulse: Vector2, _from: MetalSource) -> Vector2:
	if not silenced:
		silenced = true
		_countdown = -1.0
		rotation = deg_to_rad(25.0)
		NoiseBus.emit(global_position, 0.3, NoiseBus.Kind.METAL)
		queue_redraw()
	return impulse


func _draw() -> void:
	draw_line(Vector2(0, -14), Vector2(0, -8), Color(0.3, 0.3, 0.32), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, 4), Vector2(-4, -8), Vector2(4, -8), Vector2(6, 4)]), Color(0.65, 0.5, 0.25) if not silenced else Color(0.4, 0.33, 0.2))
