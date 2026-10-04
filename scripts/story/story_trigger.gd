class_name StoryTrigger
extends Area2D
## Plays a dialogue scene or a cutscene when Vin walks in, once.

@export var dialogue_file := ""
@export var dialogue_node := ""
@export var cutscene_path: NodePath
@export var size := Vector2(32, 64)
@export var once_flag := ""

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
	if dialogue_file != "":
		var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
		if box == null:
			box = DialogueBox.new()
			box.add_to_group("dialogue_box")
			get_tree().current_scene.add_child(box)
		box.play_file(dialogue_file, dialogue_node)
	if cutscene_path and has_node(cutscene_path):
		(get_node(cutscene_path) as Cutscene).play()
