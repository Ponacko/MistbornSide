class_name Mission
extends Node2D
## A story mission: knows its id and title, completes with a story flag and
## a title card.

signal completed

@export var mission_id := ""
@export var title := ""
## Real seconds from the start, for playtest timing.
var elapsed := 0.0
var done := false


func vin() -> Vin:
	return get_tree().get_first_node_in_group("player") as Vin


func _process(delta: float) -> void:
	if not done:
		elapsed += TimeController.real_delta(delta)


func trigger(name_in_scene: String) -> StoryTrigger:
	return get_node_or_null(name_in_scene) as StoryTrigger


func complete() -> void:
	if done:
		return
	done = true
	StoryFlags.set_flag("mission_%s_done" % mission_id)
	var card := MissionCard.new()
	card.text = title
	card.subtitle = "Mission complete"
	add_child(card)
	completed.emit()
