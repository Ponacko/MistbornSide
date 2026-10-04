class_name Cutscene
extends Node2D
## In-engine cutscene convention (DESIGN.md 14): a child AnimationPlayer
## named "Anim" with an animation "play" that moves a child Camera2D named
## "CutsceneCamera" and any characters (tracks are relative to this node).
## play() takes control from Vin, runs it, and hands control and the game
## camera back.

signal finished

## Story flag set when it has played; empty plays every time.
@export var played_flag := ""

var playing := false


func play() -> void:
	if playing or (played_flag != "" and StoryFlags.get_flag(played_flag)):
		return
	playing = true
	var vin := get_tree().get_first_node_in_group("player") as Vin
	var game_cam := get_viewport().get_camera_2d()
	var cam := get_node_or_null("CutsceneCamera") as Camera2D
	if vin:
		vin.lock_input(self)
	if cam:
		cam.make_current()
	var anim := get_node("Anim") as AnimationPlayer
	anim.play(&"play")
	await anim.animation_finished
	if game_cam and is_instance_valid(game_cam):
		game_cam.make_current()
	if vin and is_instance_valid(vin):
		vin.unlock_input(self)
	if played_flag != "":
		StoryFlags.set_flag(played_flag)
	playing = false
	finished.emit()
