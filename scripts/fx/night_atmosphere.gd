class_name NightAtmosphere
extends Node2D
## Drop into a level to make it night in Luthadel: darkened world, the
## mists, falling ash. Lanterns (Lantern nodes) light it.

@export var darkness := Color(0.2, 0.22, 0.3)
@export var mist_thickness := 0.35

## How far tin lifts the darkness.
@export var tin_darkness := Color(0.45, 0.47, 0.56)

var mists: MistLayer
var _modulate: CanvasModulate


func _ready() -> void:
	_modulate = CanvasModulate.new()
	_modulate.color = darkness
	add_child(_modulate)
	mists = MistLayer.new()
	mists.thickness = mist_thickness
	get_parent().add_child.call_deferred(mists)
	add_child(AshFall.new())


func _process(_delta: float) -> void:
	var vin := get_tree().get_first_node_in_group("player") as Vin
	var lift := 0.0
	if vin:
		lift = clampf(vin.senses.tin_amount + vin.senses.pulse, 0.0, 1.0)
	_modulate.color = darkness.lerp(tin_darkness, lift)
