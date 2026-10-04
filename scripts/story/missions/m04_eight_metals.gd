extends Mission
## Mission 4, Eight Metals (TFE chapter 7): Kelsier gives Vin her mistcloak
## and first vial in Clubs' shop and teaches tin, pewter, steel and iron on
## the rooftops, ending atop the city wall. Beats are StoryTriggers and
## gated TutorialPrompts in the scene; Kelsier is a demonstrator scripted by
## KelsierMarkers. This script handles what the scene cannot: the opening
## state, the cloak, the first vial and the clips.

const DIALOGUE := "res://data/dialogue/m04.json"

@export var clips_given := 10


func _ready() -> void:
	_begin.call_deferred()


func _begin() -> void:
	var v := vin()
	v.wears_cloak = false
	for m in MetalReserves.Metal.values():
		v.reserves.set_amount(m, 0.0)
	v.pouch.count = 0
	var hud := get_tree().get_first_node_in_group("hud") as Hud
	if hud:
		hud.revealed_metals = 0
	Checkpoints.reach(v, v.global_position)
	var coin_trigger := trigger("CoinTrigger")
	if coin_trigger:
		coin_trigger.fired.connect(func(): vin().pouch.count = maxi(vin().pouch.count, clips_given))
	var end_trigger := trigger("WallTrigger")
	if end_trigger:
		end_trigger.dialogue_closed.connect(complete)
	var box := _dialogue_box()
	box.closed.connect(_after_intro, CONNECT_ONE_SHOT)
	box.play_file(DIALOGUE, "intro")


func _dialogue_box() -> DialogueBox:
	var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if box == null:
		box = DialogueBox.new()
		box.add_to_group("dialogue_box")
		add_child(box)
	return box


## Beat 1: the cloak goes on, the vial goes down, eight reserves appear.
func _after_intro() -> void:
	var v := vin()
	v.wears_cloak = true
	v.reserves.refill_all()
	Checkpoints.reach(v, v.global_position)
	var hud := get_tree().get_first_node_in_group("hud") as Hud
	if hud == null:
		return
	for i in 8:
		await get_tree().create_timer(0.25, false).timeout
		hud.revealed_metals = i + 1
