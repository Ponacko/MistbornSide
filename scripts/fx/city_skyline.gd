class_name CitySkyline
extends CanvasLayer
## The night sky and Luthadel's thousand spires behind the play space: a
## vertical sky gradient, then two or three parallax bands of building and
## spire silhouettes with a few lit windows, each band dimmer and bluer with
## distance (DESIGN.md 12.2). Procedural from a seed; each band is a
## Parallax2D that repeats horizontally. Lives on its own canvas layer under
## the world, so the night modulate and the lanterns leave the distance alone.

@export var seed_value := 11
## Horizon height in world space: silhouettes stand on it.
@export var horizon_y := 0.0
## Draw Kredik Shaw's cluster of spires on the far band.
@export var kredik_shaw := true
@export var sky_top := Color(0.045, 0.05, 0.085)
@export var sky_bottom := Color(0.13, 0.14, 0.19)
## Nearest to farthest.
@export var band_colors: Array[Color] = [Color(0.06, 0.065, 0.09), Color(0.085, 0.09, 0.12), Color(0.11, 0.115, 0.155)]
@export var band_scales: Array[float] = [0.55, 0.35, 0.2]

const WIDTH := 1600


func _ready() -> void:
	layer = -10
	follow_viewport_enabled = true
	var sky := Parallax2D.new()
	sky.scroll_scale = Vector2(0.0, 0.05)
	sky.repeat_size = Vector2(WIDTH, 0)
	sky.repeat_times = 3
	var grad := _sky_sprite()
	sky.add_child(grad)
	add_child(sky)
	for i in range(band_scales.size() - 1, -1, -1):
		var band := Parallax2D.new()
		band.scroll_scale = Vector2(band_scales[i], band_scales[i] * 0.6)
		band.repeat_size = Vector2(WIDTH, 0)
		band.repeat_times = 3
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture = ImageTexture.create_from_image(_band(i))
		sprite.position = Vector2(-WIDTH, horizon_y - 400.0)
		band.add_child(sprite)
		add_child(band)


func _sky_sprite() -> Sprite2D:
	var img := Image.create(4, 512, false, Image.FORMAT_RGBA8)
	for y in 512:
		var t := float(y) / 511.0
		var c := sky_top.lerp(sky_bottom, pow(t, 1.6))
		for x in 4:
			img.set_pixel(x, y, c)
	var s := Sprite2D.new()
	s.centered = false
	s.texture = ImageTexture.create_from_image(img)
	s.scale = Vector2(WIDTH / 4.0 * 3.0, 1200.0 / 512.0)
	s.position = Vector2(-WIDTH, horizon_y - 1000.0)
	return s


## One band of rooflines, WIDTH wide, 400 tall, horizon at the bottom.
func _band(index: int) -> Image:
	var h := 400
	var img := Image.create(WIDTH, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + index
	var color := band_colors[index]
	var far := float(index) / maxf(band_scales.size() - 1, 1)
	var window_warm := Color(0.95, 0.6, 0.25).lerp(color, far * 0.6)
	var x := 0
	while x < WIDTH:
		var w := rng.randi_range(28, 90)
		var tall := rng.randi_range(40, 140 + int(80 * far))
		var top := h - tall
		for yy in range(top, h):
			for xx in range(x, mini(x + w, WIDTH)):
				img.set_pixel(xx, yy, color)
		# Roof shapes: a pitched roof, a parapet with chimneys, or a spire.
		match rng.randi_range(0, 3):
			0:
				for k in range(0, w / 2):
					var yy := top - k
					if yy < 0:
						break
					for xx in range(x + k, mini(x + w - k, WIDTH)):
						img.set_pixel(xx, yy, color)
			1:
				for c in rng.randi_range(1, 3):
					var cx := x + rng.randi_range(3, maxi(w - 6, 4))
					for yy in range(maxi(top - rng.randi_range(6, 14), 0), top):
						for xx in range(cx, mini(cx + 3, WIDTH)):
							img.set_pixel(xx, yy, color)
			2:
				var sx := x + w / 2
				var sh := rng.randi_range(30, 90)
				for k in sh:
					var yy := top - k
					if yy < 0:
						break
					var half := maxi(int(3.0 * (1.0 - float(k) / sh)), 0)
					for xx in range(sx - half, mini(sx + half + 1, WIDTH)):
						img.set_pixel(xx, yy, color)
		# A few lit windows; fewer and dimmer with distance.
		if rng.randf() < 0.7 - far * 0.4:
			for k in rng.randi_range(1, 4):
				var wx := x + rng.randi_range(3, maxi(w - 5, 4))
				var wy := rng.randi_range(top + 6, h - 8)
				var a := rng.randf_range(0.35, 0.8) * (1.0 - far * 0.5)
				for yy in range(wy, wy + 3):
					for xx in range(wx, mini(wx + 2, WIDTH)):
						img.set_pixel(xx, yy, Color(window_warm, a))
		x += w + rng.randi_range(0, 10)
	if kredik_shaw and index == band_scales.size() - 1:
		_spires(img, rng, color.lightened(0.08))
	return img


## Kredik Shaw: a crowded cluster of thin spires rising above everything.
func _spires(img: Image, rng: RandomNumberGenerator, color: Color) -> void:
	var h := img.get_height()
	var cx := WIDTH * 3 / 4
	for i in 14:
		var sx := cx + rng.randi_range(-90, 90)
		var base := h - rng.randi_range(60, 120)
		var tall := rng.randi_range(120, 300) + int(150.0 * (1.0 - absf(sx - cx) / 90.0))
		var width := rng.randi_range(3, 7)
		for k in tall:
			var yy := base - k
			if yy < 0:
				break
			var half := maxi(int(width * (1.0 - float(k) / tall)), 0)
			for xx in range(sx - half, mini(sx + half + 1, WIDTH)):
				if xx >= 0:
					img.set_pixel(xx, yy, color)
		for yy in range(base, h):
			for xx in range(sx - width - 2, mini(sx + width + 3, WIDTH)):
				if xx >= 0:
					img.set_pixel(xx, yy, color)
