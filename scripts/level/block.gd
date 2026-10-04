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
## Depth of slate at the top of a SLATE block; below it the block draws a
## building front (Facade.paint) so a tall slab reads as a house.
@export var roof_depth := 22.0
@export var body_kind := Facade.Kind.TENEMENT
@export var body_style := PixelTextures.Style.BRICK
@export var body_tint := Color(0.4, 0.4, 0.46)
@export_range(0.0, 1.0) var body_lit := 0.3

var _shape: CollisionShape2D
var _occluder: LightOccluder2D


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
	if not Engine.is_editor_hint() and not invisible:
		if _occluder == null:
			_occluder = LightOccluder2D.new()
			_occluder.occluder = OccluderPolygon2D.new()
			_occluder.occluder.closed = false
			add_child(_occluder)
		# A full rectangle would shadow the block's own face. A slab casts
		# from its underside (an interior lantern never leaks onto the roof
		# above, a roof lantern throws the eave's shadow down the front); a
		# wall casts from its centre line, so the side facing a light is lit.
		if size.x >= size.y:
			_occluder.occluder.polygon = PackedVector2Array([Vector2(0, size.y), Vector2(size.x, size.y)])
		else:
			_occluder.occluder.polygon = PackedVector2Array([Vector2(size.x / 2.0, 0), Vector2(size.x / 2.0, size.y)])
	queue_redraw()


## Ridge cap, a gutter line, and chimney stacks seeded from the position,
## so a slate block reads as a roof rather than a slab.
func _roof_details() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x) * 7 + int(position.y)
	var ridge := Color(0.3, 0.31, 0.36)
	draw_rect(Rect2(0, 0, size.x, 1), ridge.lightened(0.35))
	# Gutter along the bottom of the visible roof band.
	if size.y > 20:
		draw_rect(Rect2(0, 18, size.x, 1), Color(0.05, 0.05, 0.06, 0.6))
	var brick := Color(0.33, 0.25, 0.22)
	var x := rng.randf_range(10, 40)
	while x < size.x - 12 and size.x > 48:
		var ch_w := rng.randf_range(6, 10)
		var ch_h := rng.randf_range(10, 20)
		draw_rect(Rect2(x, -ch_h, ch_w, ch_h), brick)
		draw_rect(Rect2(x - 1, -ch_h, ch_w + 2, 2), brick.lightened(0.2))
		draw_rect(Rect2(x, -ch_h + 2, ch_w, ch_h * 0.3), Color(0.02, 0.02, 0.025, 0.5))
		x += rng.randf_range(60, 160)


func _draw() -> void:
	if invisible and not Engine.is_editor_hint():
		return
	if style == PixelTextures.Style.GREY:
		draw_rect(Rect2(Vector2.ZERO, size), color)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 2)), color.lightened(0.2))
		return
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if style == PixelTextures.Style.SLATE and size.y > roof_depth + 30.0:
		draw_texture_rect(PixelTextures.texture(style), Rect2(Vector2.ZERO, Vector2(size.x, roof_depth)), true)
		Facade.paint(self, Rect2(0, roof_depth, size.x, size.y - roof_depth), body_kind, body_style, body_tint, int(position.x) * 3 + int(position.y), body_lit, 14.0)
		# Eave shadow under the roof slab.
		draw_rect(Rect2(0, roof_depth, size.x, 3), Color(0.02, 0.02, 0.03, 0.6))
	else:
		draw_texture_rect(PixelTextures.texture(style), Rect2(Vector2.ZERO, size), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 2)), Color(0.42, 0.42, 0.46))
	if style == PixelTextures.Style.SLATE:
		_roof_details()
	if ash and not (style == PixelTextures.Style.SLATE and size.y > roof_depth + 30.0):
		var bands := mini(int(size.y / 2.0), 10)
		for i in bands:
			draw_rect(Rect2(0, 2 + i * 2, size.x, 2), Color(0.02, 0.02, 0.025, 0.45 * (1.0 - float(i) / bands)))
