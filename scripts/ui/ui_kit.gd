class_name UiKit
## Shared look for the menus: small pixel-friendly text, dark panels.

static func theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 9
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.03, 0.035, 0.05, 0.92)
	panel.border_color = Color(0.45, 0.5, 0.6, 0.6)
	panel.set_border_width_all(1)
	panel.set_content_margin_all(8)
	t.set_stylebox("panel", "PanelContainer", panel)
	var button := StyleBoxFlat.new()
	button.bg_color = Color(0.1, 0.11, 0.15)
	button.set_content_margin_all(3)
	var hover := button.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.24, 0.34)
	for s in ["normal", "pressed", "disabled"]:
		t.set_stylebox(s, "Button", button)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("focus", "Button", hover)
	t.set_color("font_color", "Button", Color(0.85, 0.85, 0.9))
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.4, 0.45))
	return t


static func button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.name = text
	b.pressed.connect(action)
	return b


static func centered_panel(parent: Node, width := 260.0) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	return box
