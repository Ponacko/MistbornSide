class_name CharacterArt
## Procedural pixel-art character sprites (ADR 0003, world-and-visuals
## note). Each character is a small jointed figure posed per animation
## state and rendered to a pixel frame with a normal map (from a rounded
## height field, so 2D lights shade the body) and a specular map for metal
## (breastplates, Inquisitor spikes). Frames are cached; tools/export_sprites.gd
## writes them out as sheets for an artist to paint over.

const W := 64
const H := 80
## Where the feet are in each frame.
const ORIGIN := Vector2(32, 76)

## Every animation state each system asks for.
const REQUIRED := {
	"vin": ["idle", "run", "jump", "fall", "crouch", "ledge_hang", "bracket_hang", "wall_slide", "stagger",
		"dodge", "attack", "heavy", "dash", "plunge", "push", "pull", "dead"],
	"kelsier": ["idle", "run", "leap", "attack", "shove"],
	"guard": ["idle", "walk", "windup", "strike", "stagger", "dead"],
	"hazekiller": ["idle", "walk", "windup", "strike", "stagger", "dead"],
	"obligator": ["idle", "walk", "alarm", "stagger", "dead"],
	"inquisitor": ["idle", "run", "windup", "strike", "recover"],
}

const FRAMES := {"run": 4, "walk": 4, "attack": 3}

## Proportions and palette per character.
const LOOKS := {
	"vin": {"scale": 1.0, "skin": Color(0.86, 0.72, 0.62), "hair": Color(0.07, 0.06, 0.07), "top": Color(0.28, 0.28, 0.32),
		"legs": Color(0.2, 0.2, 0.24), "boots": Color(0.12, 0.1, 0.1), "hair_style": "short", "slight": true},
	"kelsier": {"scale": 1.12, "skin": Color(0.86, 0.73, 0.6), "hair": Color(0.86, 0.76, 0.45), "top": Color(0.3, 0.3, 0.34),
		"legs": Color(0.22, 0.22, 0.25), "boots": Color(0.12, 0.1, 0.1), "hair_style": "short", "scars": true, "cloak": Color(0.24, 0.24, 0.28)},
	"guard": {"scale": 1.05, "skin": Color(0.8, 0.66, 0.55), "hair": Color(0.3, 0.24, 0.18), "top": Color(0.42, 0.33, 0.27),
		"legs": Color(0.3, 0.25, 0.2), "boots": Color(0.15, 0.12, 0.1), "hair_style": "helm", "breastplate": true, "spear": true},
	"hazekiller": {"scale": 1.05, "skin": Color(0.75, 0.6, 0.5), "hair": Color(0.2, 0.17, 0.14), "top": Color(0.24, 0.22, 0.2),
		"legs": Color(0.2, 0.18, 0.16), "boots": Color(0.12, 0.1, 0.09), "hair_style": "hood", "shield": true, "staff": true},
	"obligator": {"scale": 1.04, "skin": Color(0.82, 0.7, 0.6), "hair": Color(0.82, 0.7, 0.6), "top": Color(0.46, 0.46, 0.5),
		"legs": Color(0.42, 0.42, 0.46), "boots": Color(0.2, 0.2, 0.22), "hair_style": "bald", "robe": true, "tattoos": true},
	"inquisitor": {"scale": 1.22, "skin": Color(0.75, 0.68, 0.66), "hair": Color(0.75, 0.68, 0.66), "top": Color(0.1, 0.09, 0.11),
		"legs": Color(0.08, 0.08, 0.1), "boots": Color(0.06, 0.06, 0.07), "hair_style": "bald", "robe": true, "spikes": true, "axe": true},
}

const METAL := Color(0.62, 0.65, 0.7)
const OBSIDIAN := Color(0.07, 0.07, 0.09)
const WOOD := Color(0.5, 0.36, 0.22)

static var _cache := {}


static func frame_count(who: String, state: String) -> int:
	return FRAMES.get(state, 1) if REQUIRED.get(_base(who), []).has(state) or state == "unarmed" else 0


static func texture(who: String, state: String, frame := 0) -> CanvasTexture:
	return _frame(who, state, frame).texture


static func mask(who: String, state: String, frame := 0) -> Image:
	return _frame(who, state, frame).diffuse


## The point between the shoulders, relative to the feet, facing right.
static func shoulder(who: String, state: String, frame := 0) -> Vector2:
	return _frame(who, state, frame).shoulder


static func silhouette_height(who: String, state: String) -> float:
	var img := mask(who, state)
	var top := H
	for y in H:
		for x in W:
			if img.get_pixel(x, y).a > 0.5:
				top = mini(top, y)
	return ORIGIN.y - top


## Intersection over union of two characters' idle silhouettes.
static func silhouette_overlap(a: String, b: String) -> float:
	var ma := mask(a, "idle")
	var mb := mask(b, "idle")
	var inter := 0
	var union := 0
	for y in H:
		for x in W:
			var pa := ma.get_pixel(x, y).a > 0.5
			var pb := mb.get_pixel(x, y).a > 0.5
			if pa and pb:
				inter += 1
			if pa or pb:
				union += 1
	return float(inter) / maxf(union, 1.0)


static func _base(who: String) -> String:
	return who.get_slice("_", 0)


static func _frame(who: String, state: String, frame: int) -> Dictionary:
	var key := "%s/%s/%d" % [who, state, frame]
	if not _cache.has(key):
		_cache[key] = _render(who, state, frame)
	return _cache[key]


## Joint angles in degrees: 0 hangs straight down, positive swings forward.
static func pose(state: String, frame: int) -> Dictionary:
	var p := {"lean": 0.0, "crouch": 0.0, "thigh_f": 6.0, "shin_f": 0.0, "thigh_b": -6.0, "shin_b": 0.0,
		"arm_f": 12.0, "fore_f": 10.0, "arm_b": -10.0, "fore_b": 6.0, "weapon": "rest"}
	var phase := TAU * frame / 4.0
	match state:
		"run", "leap":
			if state == "leap":
				p.merge({"lean": 20.0, "thigh_f": 60.0, "shin_f": -70.0, "thigh_b": -30.0, "shin_b": 40.0, "arm_f": 70.0, "arm_b": -60.0}, true)
			else:
				p.merge({"lean": 12.0, "thigh_f": 38.0 * sin(phase), "shin_f": -maxf(0.0, 55.0 * cos(phase)) - 10.0,
					"thigh_b": -38.0 * sin(phase), "shin_b": -maxf(0.0, -55.0 * cos(phase)) - 10.0,
					"arm_f": -30.0 * sin(phase), "fore_f": 50.0, "arm_b": 30.0 * sin(phase), "fore_b": 50.0}, true)
		"walk":
			p.merge({"thigh_f": 20.0 * sin(phase), "shin_f": -maxf(0.0, 25.0 * cos(phase)), "thigh_b": -20.0 * sin(phase),
				"shin_b": -maxf(0.0, -25.0 * cos(phase)), "arm_f": -12.0 * sin(phase), "arm_b": 12.0 * sin(phase)}, true)
		"jump":
			p.merge({"thigh_f": 50.0, "shin_f": -80.0, "thigh_b": 5.0, "shin_b": -30.0, "arm_f": 140.0, "fore_f": 20.0, "arm_b": -40.0, "fore_b": 30.0}, true)
		"fall":
			p.merge({"thigh_f": 20.0, "shin_f": -20.0, "thigh_b": -15.0, "shin_b": -10.0, "arm_f": 120.0, "fore_f": 30.0, "arm_b": 100.0, "fore_b": 40.0}, true)
		"crouch":
			p.merge({"crouch": 12.0, "lean": 18.0, "thigh_f": 80.0, "shin_f": -110.0, "thigh_b": 60.0, "shin_b": -120.0, "arm_f": 30.0, "fore_f": 40.0}, true)
		"ledge_hang":
			p.merge({"arm_f": 175.0, "fore_f": 0.0, "arm_b": 170.0, "fore_b": 0.0, "thigh_f": 8.0, "thigh_b": -4.0, "shin_b": -15.0}, true)
		"bracket_hang":
			p.merge({"arm_f": 160.0, "fore_f": 10.0, "arm_b": 40.0, "fore_b": 30.0, "thigh_f": 20.0, "shin_f": -30.0, "thigh_b": -10.0}, true)
		"wall_slide":
			p.merge({"lean": -8.0, "arm_f": 150.0, "fore_f": 20.0, "thigh_f": 30.0, "shin_f": -40.0}, true)
		"stagger", "recover":
			p.merge({"lean": -18.0, "arm_f": 60.0, "fore_f": 50.0, "arm_b": -70.0, "fore_b": -30.0, "thigh_f": 20.0, "thigh_b": -20.0}, true)
		"dodge":
			p.merge({"crouch": 18.0, "lean": 55.0, "thigh_f": 120.0, "shin_f": -150.0, "thigh_b": 100.0, "shin_b": -150.0, "arm_f": 100.0, "fore_f": 90.0, "arm_b": 80.0, "fore_b": 90.0}, true)
		"attack", "strike", "shove":
			var reach: float = [80.0, 55.0, 100.0][frame % 3]
			p.merge({"lean": 10.0, "arm_f": reach, "fore_f": 5.0, "thigh_f": 25.0, "shin_f": -10.0, "thigh_b": -20.0, "weapon": "thrust"}, true)
		"windup":
			p.merge({"lean": -6.0, "arm_f": 150.0, "fore_f": 30.0, "arm_b": -30.0, "weapon": "raised"}, true)
		"heavy":
			p.merge({"lean": 16.0, "arm_f": 165.0, "fore_f": -30.0, "arm_b": 150.0, "fore_b": -20.0, "thigh_f": 30.0, "shin_f": -20.0, "weapon": "raised"}, true)
		"dash":
			p.merge({"lean": 30.0, "arm_f": 85.0, "fore_f": 0.0, "arm_b": -40.0, "thigh_f": 45.0, "shin_f": -30.0, "thigh_b": -45.0, "shin_b": -20.0, "weapon": "thrust"}, true)
		"plunge":
			p.merge({"thigh_f": 5.0, "thigh_b": 0.0, "arm_f": 10.0, "fore_f": -20.0, "arm_b": 10.0, "weapon": "down"}, true)
		"push":
			p.merge({"lean": -4.0, "arm_f": 90.0, "fore_f": 0.0, "arm_b": -30.0, "thigh_f": 15.0, "thigh_b": -15.0}, true)
		"pull":
			p.merge({"lean": 6.0, "arm_f": 95.0, "fore_f": 40.0, "arm_b": -20.0, "thigh_f": 10.0, "thigh_b": -10.0}, true)
		"alarm":
			p.merge({"arm_f": 160.0, "fore_f": 10.0, "arm_b": 160.0, "fore_b": 10.0}, true)
		"dead":
			p.merge({"lean": -88.0, "crouch": 20.0, "thigh_f": -88.0, "thigh_b": -84.0, "shin_f": 0.0, "shin_b": 0.0, "arm_f": -100.0, "arm_b": -80.0}, true)
	return p


static func _dir(deg: float) -> Vector2:
	var a := deg_to_rad(deg)
	return Vector2(sin(a), cos(a))


static func _render(who: String, state: String, frame: int) -> Dictionary:
	var base := _base(who)
	var look: Dictionary = LOOKS[base].duplicate()
	if who.contains("unarmed"):
		look.erase("spear")
	if who.contains("bare"):
		look.erase("breastplate")
	if who.contains("noshield"):
		look.erase("shield")
	var s: float = look.scale
	var p := pose("idle" if state == "unarmed" else state, frame)
	var c := _Canvas.new()
	var thigh := 11.0 * s
	var shin := 11.0 * s
	var torso := 15.0 * s
	var upper := 8.0 * s
	var lower := 7.5 * s
	var hip := Vector2(0, -(thigh + shin) + p.crouch)
	var up := -_dir(p.lean)
	var top: Vector2 = hip + up * torso
	var shoulder: Vector2 = top - up * 2.0
	var head_c: Vector2 = top + up * (2.0 + 4.5 * s)
	var limb := 1.4 if look.get("slight", false) else 1.7
	# Back limbs first.
	var knee_b: Vector2 = hip + _dir(p.thigh_b) * thigh
	var foot_b: Vector2 = knee_b + _dir(p.thigh_b + p.shin_b) * shin
	var elbow_b: Vector2 = shoulder + _dir(p.arm_b) * upper
	var hand_b: Vector2 = elbow_b + _dir(p.arm_b + p.fore_b) * lower
	var knee_f: Vector2 = hip + _dir(p.thigh_f) * thigh
	var foot_f: Vector2 = knee_f + _dir(p.thigh_f + p.shin_f) * shin
	var elbow_f: Vector2 = shoulder + _dir(p.arm_f) * upper
	var hand_f: Vector2 = elbow_f + _dir(p.arm_f + p.fore_f) * lower
	var back_shade := 0.78
	if look.has("cloak"):
		for i in 5:
			c.line(shoulder + Vector2(-2 - i, 0), shoulder + Vector2(-5 - i * 1.5, 26 * s), 0.6, look.cloak)
	if look.get("staff", false):
		c.line(hand_b + Vector2(-14, 10), hand_b + Vector2(14, -16), 0.8, WOOD)
	c.line(hip, knee_b, limb, look.legs.darkened(1.0 - back_shade))
	c.line(knee_b, foot_b, limb, look.legs.darkened(1.0 - back_shade))
	c.line(foot_b, foot_b + Vector2(3, 0), limb * 0.9, look.boots)
	c.line(shoulder, elbow_b, limb * 0.85, look.top.darkened(1.0 - back_shade))
	c.line(elbow_b, hand_b, limb * 0.8, look.skin.darkened(0.25))
	# Torso (or robe).
	if look.get("robe", false):
		var hem := hip + Vector2(0, thigh + shin * 0.6)
		c.poly(PackedVector2Array([shoulder + Vector2(-4 * s, 0), shoulder + Vector2(4 * s, 0), hem + Vector2(7 * s, 0), hem + Vector2(-7 * s, 0)]), look.top)
	else:
		c.line(hip, top, 3.2 * s if not look.get("slight", false) else 2.6, look.top)
		c.line(hip, hip + up * 3.0, 3.0 * s, look.legs)
	if look.get("breastplate", false):
		c.line(hip + up * 5.0, top - up * 1.0, 3.3 * s, METAL, true)
	# Front leg and arm.
	if not look.get("robe", false):
		c.line(hip, knee_f, limb, look.legs)
		c.line(knee_f, foot_f, limb, look.legs)
	c.line(foot_f, foot_f + Vector2(3, 0), limb * 0.9, look.boots)
	# Head.
	c.disc(head_c, 4.2 * s, look.skin)
	match look.hair_style:
		"short":
			c.disc(head_c + Vector2(-1, -2) * s, 3.6 * s, look.hair)
		"helm":
			c.disc(head_c + Vector2(0, -2) * s, 4.0 * s, METAL.darkened(0.15), true)
		"hood":
			c.disc(head_c + Vector2(-1.5, -1.5) * s, 4.4 * s, look.hair)
	c.disc(head_c + Vector2(1.5, 1.0) * s, 2.6 * s, look.skin)
	c.px(head_c + Vector2(2.4, -0.5) * s, Color(0.05, 0.05, 0.06))
	if look.get("tattoos", false):
		c.line(head_c + Vector2(1.5, -2.0) * s, head_c + Vector2(4.0, -1.0) * s, 0.4, Color(0.2, 0.25, 0.45))
		c.line(head_c + Vector2(1.5, 1.0) * s, head_c + Vector2(4.0, 0.5) * s, 0.4, Color(0.2, 0.25, 0.45))
	if look.get("spikes", false):
		c.disc(head_c + Vector2(2.4, -0.5) * s, 1.2, METAL.lightened(0.2), true)
		for dy in [-2.0, 1.0]:
			c.line(head_c + Vector2(-3, dy) * s, head_c + Vector2(-8, dy - 2) * s, 0.7, METAL.lightened(0.15), true)
	c.line(shoulder, elbow_f, limb * 0.85, look.top)
	c.line(elbow_f, hand_f, limb * 0.8, look.skin)
	if look.get("scars", false):
		var mid := elbow_f.lerp(hand_f, 0.5)
		c.px(mid, Color(0.95, 0.85, 0.8))
		c.px(mid + _dir(p.arm_f + p.fore_f) * 2.0, Color(0.95, 0.85, 0.8))
	# Weapons.
	var along := _dir(p.arm_f + p.fore_f)
	if look.get("spear", false) and state != "unarmed":
		var back := hand_f - along.orthogonal() * 0.0 - Vector2(1, 0) * 12.0 * s if p.weapon == "rest" else hand_f - along * 12.0
		var tip := hand_f + (Vector2(0, -1) * 14.0 * s if p.weapon == "rest" else along * 18.0)
		c.line(back, tip, 0.7, WOOD)
		c.line(tip, tip + (tip - back).normalized() * 3.0, 0.9, METAL, true)
	if look.get("axe", false):
		var haft := hand_f + (along * 10.0 if p.weapon != "rest" else Vector2(0, 8))
		c.line(hand_f, haft, 0.7, Color(0.25, 0.2, 0.15))
		c.disc(haft, 2.6 * s, OBSIDIAN)
	if look.get("shield", false):
		c.poly(PackedVector2Array([hand_f + Vector2(1, -8) * s, hand_f + Vector2(4, -8) * s, hand_f + Vector2(4, 8) * s, hand_f + Vector2(1, 8) * s]), WOOD.darkened(0.1))
	if base == "vin" and p.weapon != "rest":
		c.line(hand_f, hand_f + along * 5.0, 0.6, OBSIDIAN)
	var tex := c.finish()
	return {"texture": tex, "diffuse": c.color, "shoulder": shoulder}


## A small pixel canvas that also records height and metal for the maps.
class _Canvas:
	var color := Image.create(CharacterArt.W, CharacterArt.H, false, Image.FORMAT_RGBA8)
	var metal := Image.create(CharacterArt.W, CharacterArt.H, false, Image.FORMAT_L8)
	var any_metal := false

	func px(p: Vector2, c: Color, is_metal := false) -> void:
		var q := (p + CharacterArt.ORIGIN).round()
		if q.x < 0 or q.y < 0 or q.x >= CharacterArt.W or q.y >= CharacterArt.H:
			return
		color.set_pixel(int(q.x), int(q.y), Color(c, 1.0))
		metal.set_pixel(int(q.x), int(q.y), Color.WHITE if is_metal else Color.BLACK)
		any_metal = any_metal or is_metal

	func disc(center: Vector2, r: float, c: Color, is_metal := false) -> void:
		for y in range(floori(-r), ceili(r) + 1):
			for x in range(floori(-r), ceili(r) + 1):
				if x * x + y * y <= r * r + 0.5:
					px(center + Vector2(x, y), c, is_metal)

	func line(a: Vector2, b: Vector2, half_width: float, c: Color, is_metal := false) -> void:
		var steps := maxi(int(a.distance_to(b) * 2.0), 1)
		for i in steps + 1:
			disc(a.lerp(b, float(i) / steps), half_width, c, is_metal)

	func poly(points: PackedVector2Array, c: Color) -> void:
		var r := Rect2(points[0], Vector2.ZERO)
		for p in points:
			r = r.expand(p)
		for y in range(floori(r.position.y), ceili(r.end.y) + 1):
			for x in range(floori(r.position.x), ceili(r.end.x) + 1):
				if Geometry2D.is_point_in_polygon(Vector2(x, y), points):
					px(Vector2(x, y), c)

	## Normal map from a rounded height field: higher away from the edges.
	func finish() -> CanvasTexture:
		var w := CharacterArt.W
		var h := CharacterArt.H
		var height := PackedFloat32Array()
		height.resize(w * h)
		for y in h:
			for x in w:
				height[y * w + x] = 3.0 if color.get_pixel(x, y).a > 0.5 else 0.0
		for pass_i in 3:
			for y in range(1, h - 1):
				for x in range(1, w - 1):
					var i := y * w + x
					if height[i] > 0.0:
						height[i] = minf(height[i], minf(minf(height[i - 1], height[i + 1]), minf(height[i - w], height[i + w])) + 1.0)
		var normal := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				if color.get_pixel(x, y).a < 0.5:
					continue
				var i := y * w + x
				var n := Vector3((height[i - 1] - height[i + 1]) * 0.6, (height[i - w] - height[i + w]) * 0.6, 1.0).normalized()
				normal.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
		var tex := CanvasTexture.new()
		tex.diffuse_texture = ImageTexture.create_from_image(color)
		tex.normal_texture = ImageTexture.create_from_image(normal)
		if any_metal:
			var spec := Image.create(w, h, false, Image.FORMAT_RGBA8)
			for y in h:
				for x in w:
					var m := metal.get_pixel(x, y).r
					spec.set_pixel(x, y, Color(m, m, m, 1.0))
			tex.specular_texture = ImageTexture.create_from_image(spec)
			tex.specular_shininess = 0.7
		return tex
