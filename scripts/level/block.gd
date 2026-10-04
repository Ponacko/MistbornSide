@tool
class_name Block
extends StaticBody2D
## A grey-box solid. Position is the top-left corner; size is in pixels.
## Designers place and resize these in the editor; collision follows.

@export var size := Vector2(64, 16):
	set(value):
		size = value
		_rebuild()
@export var color := Color(0.33, 0.34, 0.38):
	set(value):
		color = value
		queue_redraw()
## Surface art: GREY is the grey box; the others are normal-mapped textures.
@export var style := PixelTextures.Style.GREY:
	set(value):
		style = value
		queue_redraw()
## Solid but undrawn: invisible walls and tutorial gates.
@export var invisible := false
## Black ash running down from the top edge, as on every building in Luthadel.
@export var ash := true

var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		add_child(_shape)
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size / 2.0
	queue_redraw()


func _draw() -> void:
	if invisible and not Engine.is_editor_hint():
		return
	if style == PixelTextures.Style.GREY:
		draw_rect(Rect2(Vector2.ZERO, size), color)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 2)), color.lightened(0.2))
		return
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	draw_texture_rect(PixelTextures.texture(style), Rect2(Vector2.ZERO, size), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 2)), Color(0.42, 0.42, 0.46))
	if ash:
		var bands := mini(int(size.y / 2.0), 10)
		for i in bands:
			draw_rect(Rect2(0, 2 + i * 2, size.x, 2), Color(0.02, 0.02, 0.025, 0.45 * (1.0 - float(i) / bands)))
