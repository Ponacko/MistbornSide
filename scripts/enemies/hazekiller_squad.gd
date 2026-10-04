class_name HazekillerSquad
extends Node2D
## Four to eight hazekillers who move and fight as one: when one is alerted
## they all are, and only a couple strike at a time.

@export_range(4, 8) var count := 4
@export var spacing := 26.0
@export var patrol_distance := 0.0

var members: Array[Hazekiller] = []
var _attackers: Array[Hazekiller] = []


func _ready() -> void:
	for i in clampi(count, 4, 8):
		var h := Hazekiller.new()
		h.name = "Hazekiller%d" % (i + 1)
		h.position = Vector2((i - (count - 1) * 0.5) * spacing, 0)
		h.patrol_distance = patrol_distance
		h.squad = self
		h.slot = i
		add_child(h)
		members.append(h)
		h.noticed.connect(_alert_all)


func _alert_all() -> void:
	var v := get_tree().get_first_node_in_group("player") as Vin
	for m in members:
		if is_instance_valid(m) and not m.dead() and not m.aware:
			m.suspicion.alert(v.global_position if v else Vector2.INF)


func take_attack_token(h: Hazekiller) -> bool:
	_attackers = _attackers.filter(func(a): return is_instance_valid(a) and not a.dead())
	if _attackers.has(h):
		return true
	if _attackers.size() >= Game.tuning.squad_attackers:
		return false
	_attackers.append(h)
	return true


func release_attack_token(h: Hazekiller) -> void:
	_attackers.erase(h)


func alive() -> Array[Hazekiller]:
	return members.filter(func(m): return is_instance_valid(m) and not m.dead())
