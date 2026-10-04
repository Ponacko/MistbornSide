extends Mission
## Mission 9, Kredik Shaw (TFE chapter 14). A stealth approach across the
## spire yard; interior arenas fought beside Kelsier under the Lord Ruler's
## Soothing; the domed chamber and the hut; Inquisitor Bendal, unwinnable,
## read with atium so Vin can take the logbook; the axe wound; the chase
## across the roofs with Bendal behind her; the collapse at Sazed's
## carriage. Being caught outside rings the bell, not a mission failure.

const DIALOGUE := "res://data/dialogue/m09.json"

@export var clips := 20

var bendal: Bendal
var wounded := false


func _ready() -> void:
	_begin.call_deferred()


func _begin() -> void:
	var v := vin()
	v.pouch.count = clips
	Checkpoints.reach(v, v.global_position)
	bendal = get_node_or_null("Bendal") as Bendal
	if bendal:
		bendal.visible = false
		bendal.process_mode = Node.PROCESS_MODE_DISABLED
	var bendal_trigger := trigger("BendalTrigger")
	if bendal_trigger:
		bendal_trigger.fired.connect(_bendal_appears)
	var book := get_node_or_null("Logbook") as Logbook
	if book:
		book.taken.connect(_take_logbook)
	var collapse := trigger("CollapseTrigger")
	if collapse:
		collapse.fired.connect(func(): vin().lock_input(self))
		collapse.dialogue_closed.connect(_collapse)
	var soothing := trigger("SoothingTrigger")
	if soothing:
		soothing.dialogue_closed.connect(func(): StoryFlags.set_flag("m09_copper_known"))
	var box := _dialogue_box()
	box.closed.connect(func():
		var prompt := get_node_or_null("CopperPrompt") as TutorialPrompt
		if prompt:
			prompt.show_prompt(), CONNECT_ONE_SHOT)
	box.play_file(DIALOGUE, "approach")


func _dialogue_box() -> DialogueBox:
	var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if box == null:
		box = DialogueBox.new()
		add_child(box)
	return box


func _bendal_appears() -> void:
	vin().atium_beads += 1
	if bendal:
		bendal.visible = true
		bendal.process_mode = Node.PROCESS_MODE_INHERIT
		bendal.hold_ground = true
		bendal.start()


## The logbook is hers, and so is the axe.
func _take_logbook() -> void:
	if wounded:
		return
	wounded = true
	var v := vin()
	StoryFlags.set_flag("m09_logbook")
	v.atium.stop()
	v.reserves.set_amount(MetalReserves.Metal.PEWTER, MetalReserves.FULL)
	v.wound(10.0)
	NoiseBus.emit(v.global_position, 1.0, NoiseBus.Kind.FIGHT)
	var gate := get_node_or_null("Geometry/ExitGate")
	if gate:
		gate.queue_free()
	Checkpoints.reach(v, v.global_position)
	if bendal:
		var line := get_node_or_null("ChaseRoute") as Line2D
		if line:
			var route := PackedVector2Array()
			for p in line.points:
				route.append(line.to_global(p))
			bendal.begin_chase(route, 2.5)
	_dialogue_box().play_file(DIALOGUE, "wound")


func _collapse() -> void:
	if bendal:
		bendal.stop()
	vin().unlock_input(self)
	complete()
