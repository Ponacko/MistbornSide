class_name TitleScreen
extends CanvasLayer
## The title: new game, continue, the slice's mission select, settings,
## the grey-box practice yard, quit.

var _root: Control
var _menu: VBoxContainer
var _buttons := {}


func _ready() -> void:
	layer = CanvasLayers.MENU
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiKit.theme()
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.025, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	_main_menu()
	Audio.play_music("night_city")


func has_button(text: String) -> bool:
	return _buttons.has(text)


func _clear() -> void:
	for c in _root.get_children():
		if c is CenterContainer:
			c.queue_free()
	_buttons.clear()


func _add(box: VBoxContainer, text: String, action: Callable, enabled := true) -> Button:
	var b := UiKit.button(text, action)
	b.disabled = not enabled
	box.add_child(b)
	_buttons[text] = b
	return b


func _main_menu() -> void:
	_clear()
	_menu = UiKit.centered_panel(_root, 240)
	var title := Label.new()
	title.text = "MistbornSide"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.add_child(title)
	var sub := Label.new()
	sub.text = "an unofficial Mistborn fan game"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	_menu.add_child(sub)
	var resume_id := "09" if StoryFlags.get_flag("mission_04_done") and not StoryFlags.get_flag("mission_09_done") else ""
	if resume_id != "":
		_add(_menu, "Continue", func(): GameFlow.start_mission(resume_id)).grab_focus.call_deferred()
	_add(_menu, "New game", func(): GameFlow.start_mission("04"))
	_add(_menu, "Missions", _missions)
	_add(_menu, "Settings", _settings)
	_add(_menu, "Practice yard", func(): get_tree().change_scene_to_file("res://levels/greybox/greybox.tscn"))
	_add(_menu, "Quit", func(): get_tree().quit())
	var note := Label.new()
	note.text = "Mistborn is the property of Dragonsteel Entertainment.\nThis project is not affiliated with or endorsed by Dragonsteel."
	note.add_theme_font_size_override("font_size", 7)
	note.add_theme_color_override("font_color", Color(0.45, 0.47, 0.55))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.add_child(note)
	if resume_id == "":
		(_buttons["New game"] as Button).grab_focus.call_deferred()


func _missions() -> void:
	_clear()
	var box := UiKit.centered_panel(_root, 260)
	var head := Label.new()
	head.text = "Missions"
	box.add_child(head)
	for m in GameFlow.missions():
		var label := "%s: %s" % [m.id, m.title] if GameFlow.unlocked(m.id) else "%s: locked" % m.id
		var id: String = m.id
		_add(box, label, func(): GameFlow.start_mission(id), GameFlow.unlocked(m.id))
	_add(box, "Back", _main_menu)


func _settings() -> void:
	_clear()
	var screen := SettingsScreen.new()
	screen.closed.connect(func():
		screen.queue_free()
		_main_menu())
	add_child(screen)
