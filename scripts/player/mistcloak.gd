class_name Mistcloak
extends Node2D
## Vin's mistcloak (DESIGN.md 4, 14): a dozen verlet chains of charcoal
## tassels hanging from her shoulders, driven by her velocity and the mist
## wind, drawn as textured strips. It fans on a launch, trails on a fall,
## settles when she stands and twists like the mists while she walks.

const CHAINS := 12
const POINTS := 6
const SEGMENT := 6.0
const SHOULDER_WIDTH := 12.0
const GRAVITY := Vector2(0, 320)
## Acceleration per px/s of air moving past the cloak.
const DRAG := 5.0
## Sideways spread per px/s of speed, by each chain's place across the back.
const FAN := 4.5
const TWIST := 70.0
const DAMPING := 0.94
const ITERATIONS := 5
## No point may move further than this in one step.
const MAX_STEP := 14.0
const TELEPORT := 80.0
const COLOR := Color(0.3, 0.3, 0.34)
const EDGE := Color(0.46, 0.46, 0.52)


class Chain:
	var points: Array[Vector2] = []
	var prev: Array[Vector2] = []
	## Place across the back, -1 (left shoulder) to 1 (right).
	var spread := 0.0
	var phase := 0.0


var chains: Array[Chain] = []
var _last_anchor := Vector2.INF
var _prev_anchor := Vector2.INF
var _texture: ImageTexture
var _width := PackedFloat32Array()


func _init() -> void:
	top_level = true
	z_index = -1
	for i in CHAINS:
		var c := Chain.new()
		c.spread = lerpf(-1.0, 1.0, float(i) / (CHAINS - 1))
		c.phase = i * 1.7
		chains.append(c)
	for j in POINTS:
		_width.append(lerpf(3.5, 1.2, float(j) / (POINTS - 1)))


func _ready() -> void:
	_texture = _make_texture()


## Lays every chain straight down from the shoulders.
func reset(anchor: Vector2) -> void:
	_last_anchor = anchor
	_prev_anchor = anchor
	for c in chains:
		c.points.clear()
		c.prev.clear()
		var root := anchor + Vector2(c.spread * SHOULDER_WIDTH * 0.5, 0)
		for j in POINTS:
			var p := root + Vector2(0, j * SEGMENT)
			c.points.append(p)
			c.prev.append(p)


## One simulation step. anchor: between the shoulders, world space;
## velocity: the wearer's.
func step(delta: float, anchor: Vector2, velocity: Vector2, facing: int) -> void:
	if chains[0].points.is_empty() or anchor.distance_to(_last_anchor) > TELEPORT:
		reset(anchor)
	var shift := anchor - _last_anchor
	_prev_anchor = _last_anchor
	_last_anchor = anchor
	var speed := velocity.length()
	var across := velocity.orthogonal().normalized() if speed > 1.0 else Vector2.RIGHT
	var dt2 := delta * delta
	var t := MistField.time
	for c in chains:
		var root := anchor + Vector2(c.spread * SHOULDER_WIDTH * 0.5 - facing * 4.0, 0)
		var wind := MistField.wind_at(c.points[-1])
		var air := wind - velocity
		var accel := GRAVITY + air * DRAG
		accel += across * c.spread * FAN * speed
		accel.x += sin(t * 2.3 + c.phase) * TWIST * minf(absf(velocity.x) / 100.0, 1.0)
		accel.x -= facing * 40.0
		c.points[0] = root
		c.prev[0] = root - shift
		for j in range(1, POINTS):
			var p := c.points[j]
			var v := (p - c.prev[j]) * DAMPING
			var move := (v + accel * dt2).limit_length(MAX_STEP)
			c.prev[j] = p
			c.points[j] = p + move
		for k in ITERATIONS:
			c.points[0] = root
			for j in range(1, POINTS):
				var a := c.points[j - 1]
				var b := c.points[j]
				var d := b - a
				var len := d.length()
				if len < 0.0001:
					continue
				var fix := d * ((len - SEGMENT) / len)
				if j == 1:
					c.points[j] = b - fix
				else:
					c.points[j - 1] = a + fix * 0.5
					c.points[j] = b - fix * 0.5
		# Follow-the-leader pass: no segment may end the step stretched, so a
		# flared Push can whip the cloak but never tear it apart.
		for j in range(1, POINTS):
			var d := c.points[j] - c.points[j - 1]
			var len := d.length()
			if len > SEGMENT * 1.1:
				var fixed := c.points[j - 1] + d / len * SEGMENT * 1.1
				c.prev[j] += fixed - c.points[j]
				c.points[j] = fixed
		for j in POINTS:
			if not (is_finite(c.points[j].x) and is_finite(c.points[j].y)):
				reset(anchor)
				return


## Mean point speed in pixels per step: how much the cloak is still moving.
func motion() -> float:
	var total := 0.0
	var n := 0
	for c in chains:
		for j in range(1, POINTS):
			total += c.points[j].distance_to(c.prev[j])
			n += 1
	return total / n


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# The wearer is drawn interpolated between physics frames; draw the cloak
	# with the same offset so it stays on her shoulders at speed.
	if _prev_anchor != Vector2.INF and is_physics_interpolated_and_enabled():
		var f := Engine.get_physics_interpolation_fraction()
		draw_set_transform(_prev_anchor.lerp(_last_anchor, f) - _last_anchor)
	for c in chains:
		if c.points.is_empty():
			continue
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for j in POINTS:
			var dir := (c.points[mini(j + 1, POINTS - 1)] - c.points[maxi(j - 1, 0)]).normalized()
			var n := dir.orthogonal() * _width[j] * 0.5
			left.append(c.points[j] + n)
			right.append(c.points[j] - n)
		# One quad per segment via draw_primitive: a whipped tassel can fold
		# over itself, which a single strip polygon could not triangulate.
		var tint := COLOR.lerp(EDGE, absf(c.spread) * 0.5)
		var colors := PackedColorArray([tint, tint, tint, tint])
		for j in POINTS - 1:
			var v0 := float(j) / (POINTS - 1)
			var v1 := float(j + 1) / (POINTS - 1)
			draw_primitive(
				PackedVector2Array([left[j], left[j + 1], right[j + 1], right[j]]),
				colors,
				PackedVector2Array([Vector2(0, v0), Vector2(0, v1), Vector2(1, v1), Vector2(1, v0)]),
				_texture)


## A strip texture: a lighter thread down the middle of each tassel.
func _make_texture() -> ImageTexture:
	var img := Image.create(4, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 4:
			var v := 1.15 if x == 1 or x == 2 else 0.85
			if y == 7:
				v *= 0.8
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)
