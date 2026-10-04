@tool
class_name ArenaLock
extends Node2D
## An unavoidable fight (mission 9): when Vin walks in, iron gates close at
## both ends until every enemy inside is dead. Enemies are its children.
## Position is the top-left corner of the arena; size is its extent.

signal sealed_changed(is_sealed: bool)

@export var size := Vector2(300, 120):
	set(value):
		size = value
		queue_redraw()

var sealed := false
var cleared := false
var _gates: Array[Block] = []


func enemies() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for c in find_children("*", "Enemy", true, false):
		if not (c as Enemy).dead():
			out.append(c)
	return out


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or cleared:
		return
	var vin := get_tree().get_first_node_in_group("player") as Vin
	if not sealed:
		if vin and Rect2(global_position + Vector2(8, -size.y), size - Vector2(16, 0)).has_point(vin.global_position + Vector2(0, -1)):
			if not enemies().is_empty():
				_seal()
	elif enemies().is_empty():
		_open()


func _seal() -> void:
	sealed = true
	for x in [-8.0, size.x]:
		var g := Block.new()
		g.position = Vector2(x, -size.y)
		g.size = Vector2(8, size.y)
		g.style = PixelTextures.Style.IRON
		g.ash = false
		add_child(g)
		_gates.append(g)
	for e in enemies():
		e.notice()
	sealed_changed.emit(true)


func _open() -> void:
	sealed = false
	cleared = true
	for g in _gates:
		g.queue_free()
	_gates.clear()
	sealed_changed.emit(false)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2(0, -size.y), size), Color(1, 0.4, 0.2, 0.15))
