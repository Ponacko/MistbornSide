class_name NightAtmosphere
extends Node2D
## Drop into a level to make it night in Luthadel: darkened world, the
## mists, falling ash. Lanterns (Lantern nodes) light it.

@export var darkness := Color(0.3, 0.32, 0.42)
@export var mist_thickness := 0.35

## How far tin lifts the darkness.
@export var tin_darkness := Color(0.55, 0.57, 0.66)

## Glow on the HDR 2D buffer: blue lines, lantern flames and lit windows bloom.
@export var glow := true

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
	if glow:
		var env := Environment.new()
		env.background_mode = Environment.BG_CANVAS
		env.glow_enabled = true
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
		env.glow_intensity = 0.55
		env.glow_strength = 0.9
		env.glow_bloom = 0.05
		env.glow_hdr_threshold = 1.0
		env.glow_hdr_scale = 2.0
		for i in [2, 3, 5]:
			env.set("glow_levels/%d" % i, 1.0)
		var world_env := WorldEnvironment.new()
		world_env.environment = env
		add_child(world_env)


func _process(_delta: float) -> void:
	var vin := get_tree().get_first_node_in_group("player") as Vin
	var lift := 0.0
	if vin:
		lift = clampf(vin.senses.tin_amount + vin.senses.pulse, 0.0, 1.0)
	_modulate.color = darkness.lerp(tin_darkness, lift)
