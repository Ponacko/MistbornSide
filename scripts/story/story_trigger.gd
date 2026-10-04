class_name StoryTrigger
extends Area2D
## A beat: when Vin walks in (once) it plays a dialogue scene and/or a
## cutscene, then shows a tutorial prompt.

signal fired
signal dialogue_closed

@export var dialogue_file := ""
@export var dialogue_node := ""
@export var cutscene_path: NodePath
@export var size := Vector2(32, 64)
@export var once_flag := ""
## Prompt shown when the dialogue closes (or at once with no dialogue).
@export var prompt_path: NodePath

var _fired := false


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, -size.y / 2.0)
	add_child(shape)
	body_entered.connect(func(b):
		if b is Vin:
			fire())


func fire() -> void:
	if _fired or (once_flag != "" and StoryFlags.get_flag(once_flag)):
		return
	_fired = true
	if once_flag != "":
		StoryFlags.set_flag(once_flag)
	fired.emit()
	if dialogue_file != "":
		var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
		if box == null:
			box = DialogueBox.new()
			box.add_to_group("dialogue_box")
			get_parent().add_child(box)
		box.closed.connect(_on_dialogue_closed, CONNECT_ONE_SHOT)
		box.play_file(dialogue_file, dialogue_node)
	else:
		_show_prompt()
	if cutscene_path and has_node(cutscene_path):
		(get_node(cutscene_path) as Cutscene).play()


func _on_dialogue_closed() -> void:
	dialogue_closed.emit()
	_show_prompt()


func _show_prompt() -> void:
	if prompt_path and has_node(prompt_path):
		(get_node(prompt_path) as TutorialPrompt).show_prompt()
