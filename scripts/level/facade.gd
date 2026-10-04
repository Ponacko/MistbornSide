@tool
class_name Facade
extends Node2D
## A building front behind the play space: textured wall, rows of windows
## (dark, or warm-lit with a soft glow), a cornice, drainpipes, and the ash
## gradient every Luthadel building wears from the top down. Non-solid; for
## lights to fall on and for the city to look like a city. Position is the
## top-left corner.

enum Kind { TENEMENT, KEEP, SHOP, WALL, DOME }

@export var size := Vector2(256, 160):
	set(value):
		size = value
		queue_redraw()
@export var kind := Kind.TENEMENT:
	set(value):
		kind = value
		queue_redraw()
@export var style := PixelTextures.Style.BRICK:
	set(value):
		style = value
		queue_redraw()
@export var tint := Color(0.42, 0.42, 0.48):
	set(value):
		tint = value
		queue_redraw()
@export var seed_value := 1:
	set(value):
		seed_value = value
		queue_redraw()
## Share of windows that are lit.
@export_range(0.0, 1.0) var lit := 0.25
## Window rows start this far below the top (room for a roof above).
@export var window_top := 18.0


func _ready() -> void:
	z_index = -10
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _draw() -> void:
	paint(self, Rect2(Vector2.ZERO, size), kind, style, tint, seed_value, lit, window_top)


## Paints a building front into `rect` on any canvas item. Blocks use it for
## the body under a slate roof; Facade nodes for free-standing fronts.
static func paint(canvas: CanvasItem, rect: Rect2, kind: Kind, style: PixelTextures.Style, tint: Color, seed_value: int, lit: float, window_top := 18.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var size := rect.size
	canvas.draw_set_transform(rect.position)
	if style == PixelTextures.Style.GREY:
		canvas.draw_rect(Rect2(Vector2.ZERO, size), tint)
	else:
		canvas.draw_texture_rect(PixelTextures.texture(style), Rect2(Vector2.ZERO, size), true, tint)
	# Cornice.
	canvas.draw_rect(Rect2(0, 0, size.x, 3), tint.lightened(0.25))
	canvas.draw_rect(Rect2(0, 3, size.x, 1), Color(0.03, 0.03, 0.04, 0.7))
	var dark := Color(0.04, 0.045, 0.06)
	var frame := tint.darkened(0.35)
	match kind:
		Kind.TENEMENT, Kind.SHOP:
			var wsize := Vector2(8, 11) if kind == Kind.TENEMENT else Vector2(14, 16)
			var gap := Vector2(16, 26) if kind == Kind.TENEMENT else Vector2(30, 34)
			var y := window_top
			while y + wsize.y < size.y - 6:
				var x := gap.x
				while x + wsize.x < size.x - gap.x * 0.5:
					if rng.randf() > 0.12:
						_window(canvas, Rect2(x, y, wsize.x, wsize.y), rng.randf() < lit, frame, dark, rng)
					x += wsize.x + gap.x
				y += wsize.y + gap.y
			# Drainpipe.
			if size.x > 60:
				var px := rng.randf_range(6, size.x - 8)
				canvas.draw_rect(Rect2(px, 4, 2, size.y - 4), frame)
		Kind.KEEP:
			# Tall stained-glass lancets, lit from inside (DESIGN.md 12.2).
			var x := 20.0
			while x + 14 < size.x - 10:
				_lancet(canvas, Rect2(x, window_top, 12, minf(size.y * 0.55, 90)), rng)
				x += 44
		Kind.DOME:
			# The domed mural chamber: ribs fanning from the crown and a band
			# of faded painted figures, colour melted toward the ash.
			var crown := Vector2(size.x * 0.5, 6.0)
			var ribs := 9
			for i in ribs + 1:
				var a := PI * (0.08 + 0.84 * float(i) / ribs)
				var foot := Vector2(crown.x + cos(a) * size.x * 0.52, size.y)
				canvas.draw_line(crown, foot, tint.darkened(0.4), 1.0)
			var mural := Rect2(size.x * 0.12, size.y * 0.3, size.x * 0.76, size.y * 0.32)
			canvas.draw_rect(mural, tint.lightened(0.12))
			var hues := [Color(0.55, 0.3, 0.25), Color(0.3, 0.35, 0.5), Color(0.55, 0.5, 0.3), Color(0.35, 0.45, 0.35)]
			var x := mural.position.x + 6.0
			var k := 0
			while x < mural.end.x - 8.0:
				var c: Color = hues[k % hues.size()]
				var fh := rng.randf_range(mural.size.y * 0.45, mural.size.y * 0.8)
				canvas.draw_rect(Rect2(x, mural.end.y - fh, 5, fh), c)
				canvas.draw_rect(Rect2(x + 1, mural.end.y - fh - 4, 3, 4), c.lightened(0.3))
				x += rng.randf_range(12, 22)
				k += 1
			canvas.draw_rect(Rect2(mural.position.x, mural.position.y, mural.size.x, 1), tint.darkened(0.4))
			canvas.draw_rect(Rect2(mural.position.x, mural.end.y, mural.size.x, 1), tint.darkened(0.4))
		Kind.WALL:
			# Crenellations and arrow slits.
			var x := 0.0
			while x < size.x:
				canvas.draw_rect(Rect2(x, -8, 10, 8), tint.lightened(0.1))
				x += 20
			for i in int(size.x / 60):
				canvas.draw_rect(Rect2(30 + i * 60, window_top + 10, 2, 14), dark)
	# Ash running down from the top edge.
	var bands := mini(int(size.y / 2.0), 14)
	for i in bands:
		canvas.draw_rect(Rect2(0, 4 + i * 2, size.x, 2), Color(0.02, 0.02, 0.025, 0.5 * (1.0 - float(i) / bands)))
	canvas.draw_set_transform(Vector2.ZERO)


static func _window(canvas: CanvasItem, r: Rect2, is_lit: bool, frame: Color, dark: Color, rng: RandomNumberGenerator) -> void:
	canvas.draw_rect(r.grow(1), frame)
	if is_lit:
		var warm := Color(1.0, 0.72, 0.4).lerp(Color(1.0, 0.85, 0.6), rng.randf()) * rng.randf_range(0.8, 1.15)
		canvas.draw_rect(r, warm)
		# Curtain or a figure's shadow in some windows.
		if rng.randf() < 0.4:
			canvas.draw_rect(Rect2(r.position.x + r.size.x * 0.5, r.position.y + 2, r.size.x * 0.4, r.size.y - 2), warm.darkened(0.4))
	else:
		canvas.draw_rect(r, dark)
		canvas.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(2, 2)), Color(0.35, 0.4, 0.5, 0.35))
	# Mullion.
	canvas.draw_rect(Rect2(r.position.x + r.size.x * 0.5 - 0.5, r.position.y, 1, r.size.y), frame)
	# Sill.
	canvas.draw_rect(Rect2(r.position.x - 1, r.end.y, r.size.x + 2, 1), frame.lightened(0.3))


static func _lancet(canvas: CanvasItem, r: Rect2, rng: RandomNumberGenerator) -> void:
	var palette := [Color(0.85, 0.2, 0.25), Color(0.2, 0.35, 0.9), Color(0.95, 0.7, 0.2), Color(0.25, 0.7, 0.4), Color(0.7, 0.3, 0.8)]
	canvas.draw_rect(r.grow(2), Color(0.12, 0.12, 0.14))
	var cell := 4.0
	var y := r.position.y
	while y < r.end.y:
		var x := r.position.x
		while x < r.end.x:
			var c: Color = palette[rng.randi_range(0, palette.size() - 1)].darkened(0.25)
			canvas.draw_rect(Rect2(x, y, cell, cell), c)
			x += cell
		y += cell
	# Pointed top.
	canvas.draw_colored_polygon(PackedVector2Array([r.position + Vector2(-2, 0), Vector2(r.get_center().x, r.position.y - 8), Vector2(r.end.x + 2, r.position.y)]), Color(0.12, 0.12, 0.14))
	canvas.draw_colored_polygon(PackedVector2Array([r.position, Vector2(r.get_center().x, r.position.y - 5), Vector2(r.end.x, r.position.y)]), palette[0].darkened(0.25))
