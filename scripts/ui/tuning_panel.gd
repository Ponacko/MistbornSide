class_name TuningPanel
extends CanvasLayer
## Live debug panel (F1): every value in the Tuning resource, grouped as in
## the resource, editable while playing; named presets save and load as
## .tres files; Reset restores the defaults.

const EDITOR_DIR := "res://data/tuning"
const USER_DIR := "user://tuning"

var _editors := {}
var _panel: PanelContainer
var _name_edit: LineEdit
var _preset_list: OptionButton
var _status: Label


func _ready() -> void:
	layer = CanvasLayers.DEBUG
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.visible = false


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_panel.visible = not _panel.visible
		if _panel.visible:
			refresh()
			_refresh_presets()


## Names of every exported variable on Tuning, in declaration order.
static func tunable_names() -> PackedStringArray:
	var out: PackedStringArray = []
	for p in Tuning.new().get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_EDITOR:
			out.append(p.name)
	return out


func has_editor(property: String) -> bool:
	return _editors.has(property)


func set_value(property: String, value: Variant) -> void:
	Game.tuning.set(property, value)
	_show(property)


func reset_to_defaults() -> void:
	_copy_into(Tuning.new(), Game.tuning)
	refresh()


func save_preset(preset_name: String, dir := "") -> String:
	if dir == "":
		dir = EDITOR_DIR if OS.has_feature("editor") else USER_DIR
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir) if dir.begins_with("user://") else dir)
	var path := dir.path_join(preset_name.validate_filename() + ".tres")
	var copy := Tuning.new()
	_copy_into(Game.tuning, copy)
	var err := ResourceSaver.save(copy, path)
	_set_status("saved %s" % path if err == OK else "save failed (%d)" % err)
	return path


func load_preset(path: String) -> bool:
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Tuning
	if res == null:
		_set_status("could not load %s" % path)
		return false
	_copy_into(res, Game.tuning)
	refresh()
	_set_status("loaded %s" % path.get_file())
	return true


static func list_presets(dirs: Array = [EDITOR_DIR, USER_DIR]) -> PackedStringArray:
	var out: PackedStringArray = []
	for dir in dirs:
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for f in d.get_files():
			if f.ends_with(".tres"):
				out.append(dir.path_join(f))
	return out


func refresh() -> void:
	for property in _editors:
		_show(property)


static func _copy_into(from: Tuning, to: Tuning) -> void:
	for n in tunable_names():
		to.set(n, from.get(n))


func _show(property: String) -> void:
	var value: Variant = Game.tuning.get(property)
	var e: Array = _editors[property]
	if value is Vector2:
		e[0].set_value_no_signal(value.x)
		e[1].set_value_no_signal(value.y)
	else:
		e[0].set_value_no_signal(value)


func _set_status(text: String) -> void:
	if _status:
		_status.text = text


func _build() -> void:
	var theme := Theme.new()
	theme.default_font_size = 8
	_panel = PanelContainer.new()
	_panel.theme = theme
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -236
	_panel.offset_right = -4
	_panel.offset_top = 4
	_panel.offset_bottom = -4
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.88)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var outer := VBoxContainer.new()
	_panel.add_child(outer)

	var title := Label.new()
	title.text = "Tuning (F1)"
	outer.add_child(title)
	var row := HBoxContainer.new()
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "preset name"
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_name_edit)
	row.add_child(_button("Save", func(): save_preset(_name_edit.text if _name_edit.text != "" else "preset")))
	row.add_child(_button("Reset", reset_to_defaults))
	outer.add_child(row)
	var row2 := HBoxContainer.new()
	_preset_list = OptionButton.new()
	_preset_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(_preset_list)
	row2.add_child(_button("Load", func():
		if _preset_list.selected >= 0:
			load_preset(_preset_list.get_item_metadata(_preset_list.selected))))
	outer.add_child(row2)
	_status = Label.new()
	outer.add_child(_status)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for p in Tuning.new().get_property_list():
		if p.usage & PROPERTY_USAGE_GROUP:
			var header := Label.new()
			header.text = p.name
			header.add_theme_color_override("font_color", Color(0.6, 0.78, 1.0))
			grid.add_child(header)
			grid.add_child(Control.new())
		elif p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_EDITOR:
			_add_row(grid, p)
	_refresh_presets()


func _add_row(grid: GridContainer, p: Dictionary) -> void:
	var label := Label.new()
	label.text = p.name
	label.custom_minimum_size.x = 120
	label.clip_text = true
	grid.add_child(label)
	var property: String = p.name
	var value: Variant = Game.tuning.get(property)
	if value is Vector2:
		var box := HBoxContainer.new()
		var x := _spin(value.x, false)
		var y := _spin(value.y, false)
		x.value_changed.connect(func(v): Game.tuning.set(property, Vector2(v, Game.tuning.get(property).y)))
		y.value_changed.connect(func(v): Game.tuning.set(property, Vector2(Game.tuning.get(property).x, v)))
		box.add_child(x)
		box.add_child(y)
		grid.add_child(box)
		_editors[property] = [x, y]
	else:
		var spin := _spin(float(value), p.type == TYPE_INT)
		spin.value_changed.connect(func(v): Game.tuning.set(property, int(v) if p.type == TYPE_INT else v))
		grid.add_child(spin)
		_editors[property] = [spin]


func _spin(value: float, integer: bool) -> SpinBox:
	var s := SpinBox.new()
	s.allow_greater = true
	s.allow_lesser = true
	s.step = 1.0 if integer else 0.01
	s.custom_minimum_size.x = 52
	s.value = value
	return s


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(action)
	return b


func _refresh_presets() -> void:
	if _preset_list == null:
		return
	_preset_list.clear()
	for path in list_presets():
		_preset_list.add_item(path.get_file().get_basename())
		_preset_list.set_item_metadata(_preset_list.item_count - 1, path)
