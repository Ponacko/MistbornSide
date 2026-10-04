@tool
class_name Backdrop
extends Node2D
## A non-solid background surface (walls behind the play space) for lights to
## fall on. Position is the top-left corner.

@export var size := Vector2(256, 128):
	set(value):
		size = value
		queue_redraw()
@export var color := Color(0.2, 0.2, 0.23):
	set(value):
		color = value
		queue_redraw()
@export var style := PixelTextures.Style.GREY:
	set(value):
		style = value
		queue_redraw()


func _ready() -> void:
	z_index = -10


func _draw() -> void:
	if style == PixelTextures.Style.GREY:
		draw_rect(Rect2(Vector2.ZERO, size), color)
		return
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	draw_texture_rect(PixelTextures.texture(style), Rect2(Vector2.ZERO, size), true, color)
