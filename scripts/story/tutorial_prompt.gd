class_name TutorialPrompt
extends Node
## Shows the key for an action ("[2] Burn tin") and, if gated, holds a
## barrier shut until the player performs it. Each prompt shows once per
## playthrough: having seen it is a story flag.

signal satisfied

@export var prompt_id := ""
## Input map action the player must perform.
@export var action := ""
@export var text := ""
## Freed when the action is performed (a barrier, an invisible wall).
@export var gate_path: NodePath

var showing := false
var _layer: CanvasLayer
var _label: Label


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = CanvasLayers.HUD + 1
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 10)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(170, 40)
	_label.size = Vector2(300, 16)
	_layer.add_child(_label)
	_layer.visible = false
	add_child(_layer)


func seen() -> bool:
	return StoryFlags.get_flag("prompt_seen_" + prompt_id)


func show_prompt() -> void:
	if seen() or showing:
		return
	showing = true
	_label.text = "[%s]  %s" % [key_label(), text]
	_layer.visible = true


## The bound key's name, from the live input map (so remapping updates it).
func key_label() -> String:
	if not InputMap.has_action(action):
		return action
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return OS.get_keycode_string((e as InputEventKey).physical_keycode)
		if e is InputEventMouseButton:
			return ["", "LMB", "RMB", "MMB"][mini((e as InputEventMouseButton).button_index, 3)]
	return action


func _physics_process(_delta: float) -> void:
	if not showing:
		return
	var vin := get_tree().get_first_node_in_group("player") as Vin
	var done := false
	if vin and vin.scripted:
		done = vin.controls.action_pressed(action)
	else:
		done = Input.is_action_just_pressed(action)
	if done:
		_complete()


func _complete() -> void:
	showing = false
	_layer.visible = false
	StoryFlags.set_flag("prompt_seen_" + prompt_id)
	if gate_path and has_node(gate_path):
		get_node(gate_path).queue_free()
	satisfied.emit()
