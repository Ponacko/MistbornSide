extends Node
## Autoload "GameFlow": the slice as one game. Title, the two missions, the
## bridging card between them, and back to the title at the end.

const TITLE_SCENE := "res://scenes/ui/title.tscn"
const MISSIONS := [
	{"id": "04", "title": "Eight Metals", "chapter": "The Final Empire, chapter 7", "scene": "res://levels/missions/m04_eight_metals/m04_eight_metals.tscn"},
	{"id": "09", "title": "Kredik Shaw", "chapter": "The Final Empire, chapter 14", "scene": "res://levels/missions/m09_kredik_shaw/m09_kredik_shaw.tscn"},
]
const BRIDGES := {
	"04": "Kelsier Pushes Vin off the city wall and teaches her to brake with a coin. A mistwraith shadows them to Fellise, where Sazed waits and Vin becomes Lady Valette Renoux.\n\nShe spars with Kelsier in the mists, learns to be a noblewoman, and finds Camon hung by the Inquisitors. At her first ball, at Keep Venture, she meets Elend reading on a balcony.\n\nThen, one night, she follows Kelsier along the spikeway into Luthadel. He teaches her atium. Tonight they go into Kredik Shaw.",
}
const ENDING := "Sazed carries Vin out of the city. The logbook is written in an old Terris script; it will take weeks to read.\n\nThis is the end of the vertical slice."


func missions() -> Array:
	return MISSIONS


func mission(id: String) -> Dictionary:
	for m in MISSIONS:
		if m.id == id:
			return m
	return {}


func unlocked(id: String) -> bool:
	for i in MISSIONS.size():
		if MISSIONS[i].id == id:
			return i == 0 or StoryFlags.get_flag("mission_%s_done" % MISSIONS[i - 1].id)
	return false


func next_mission(id: String) -> String:
	for i in MISSIONS.size() - 1:
		if MISSIONS[i].id == id:
			return MISSIONS[i + 1].id
	return ""


## The card shown after a mission, summarising the chapters the slice skips.
func bridge_card(after_id: String) -> MissionCard:
	var card := MissionCard.new()
	card.hold = 0.0
	if BRIDGES.has(after_id):
		var next := mission(next_mission(after_id))
		card.text = next.title
		card.subtitle = next.chapter
		card.body = BRIDGES[after_id]
	else:
		card.text = "Mistborn"
		card.subtitle = "an unofficial fan game"
		card.body = ENDING
	return card


func start_mission(id: String) -> void:
	var m := mission(id)
	if m.is_empty():
		return
	Checkpoints.reset_for_test()
	get_tree().paused = false
	get_tree().change_scene_to_file(m.scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var node := get_tree().current_scene as Mission
	if node:
		node.completed.connect(_on_completed.bind(id), CONNECT_ONE_SHOT)
	Settings.apply()


func _on_completed(id: String) -> void:
	SaveGame.save()
	await get_tree().create_timer(3.5, true).timeout
	var card := bridge_card(id)
	get_tree().current_scene.add_child(card)
	await card.dismissed
	var next := next_mission(id)
	if next != "":
		start_mission(next)
	else:
		to_title()


func to_title() -> void:
	get_tree().paused = false
	TimeController.reset_for_test()
	get_tree().change_scene_to_file(TITLE_SCENE)
