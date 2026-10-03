class_name NightAtmosphere
extends Node2D
## Drop into a level to make it night in Luthadel: darkened world, the
## mists, falling ash. Lanterns (Lantern nodes) light it.

@export var darkness := Color(0.2, 0.22, 0.3)
@export var mist_thickness := 0.35

var mists: MistLayer


func _ready() -> void:
	var modulate_node := CanvasModulate.new()
	modulate_node.color = darkness
	add_child(modulate_node)
	mists = MistLayer.new()
	mists.thickness = mist_thickness
	get_parent().add_child.call_deferred(mists)
	add_child(AshFall.new())
