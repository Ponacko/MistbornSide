class_name CharacterArt
## Procedural pixel-art character sprites (ADR 0003, world-and-visuals
## note). Each character is a jointed figure: a posed skeleton whose parts
## are drawn as clothed limbs, a torso with its garment, a head with hair
## and a face, and the gear that tells one silhouette from another. Gaits
## are keyframed cycles (contact, recoil, passing, push-off, follow-through,
## swing) with a body bob, not sinusoids. Frames get an outline, edge
## shading, a normal map and a specular map for metal, and are cached.
## tools/export_sprites.gd writes them out as sheets to paint over.

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

const FRAMES := {"run": 6, "walk": 6, "attack": 3, "idle": 2}
## Frames per second per animated state.
const FPS := {"run": 12.0, "walk": 8.0, "attack": 12.0, "idle": 1.4}

## Gait tables: [thigh, knee] per frame, degrees. Thigh swings forward for
## positive values; the knee bends backward for negative. The back leg runs
## half a cycle behind. Bob is the body's rise (negative) or drop per frame.
const RUN_LEGS := [[32.0, -8.0], [14.0, -24.0], [-8.0, -40.0], [-32.0, -14.0], [-38.0, -88.0], [6.0, -98.0]]
const RUN_BOB := [1.0, 1.0, -1.0, 1.0, 1.0, -1.0]
const WALK_LEGS := [[22.0, -4.0], [12.0, -12.0], [0.0, -22.0], [-18.0, -8.0], [-24.0, -42.0], [6.0, -50.0]]
const WALK_BOB := [0.0, 0.0, -1.0, 0.0, 0.0, -1.0]

## Proportions, palette and gear per character.
const LOOKS := {
	"vin": {"scale": 1.0, "build": 0.8, "skin": Color(0.86, 0.72, 0.62), "hair": Color(0.07, 0.06, 0.08),
		"top": Color(0.27, 0.27, 0.31), "legs": Color(0.19, 0.19, 0.23), "boots": Color(0.1, 0.09, 0.09), "belt": Color(0.12, 0.1, 0.09),
		"hair_style": "short", "sleeves": true, "sash": true},
	"kelsier": {"scale": 1.12, "build": 1.0, "skin": Color(0.86, 0.73, 0.6), "hair": Color(0.86, 0.76, 0.45),
		"top": Color(0.3, 0.3, 0.34), "legs": Color(0.22, 0.22, 0.25), "boots": Color(0.12, 0.1, 0.1), "belt": Color(0.14, 0.12, 0.1),
		"hair_style": "short", "sleeves": false, "scars": true, "cloak": Color(0.24, 0.24, 0.28), "smile": true},
	"guard": {"scale": 1.06, "build": 1.1, "skin": Color(0.8, 0.66, 0.55), "hair": Color(0.3, 0.24, 0.18),
		"top": Color(0.45, 0.34, 0.27), "legs": Color(0.3, 0.25, 0.2), "boots": Color(0.15, 0.12, 0.1), "belt": Color(0.2, 0.15, 0.1),
		"hair_style": "helm", "sleeves": true, "breastplate": true, "pauldrons": true, "spear": true},
	"hazekiller": {"scale": 1.06, "build": 1.05, "skin": Color(0.75, 0.6, 0.5), "hair": Color(0.2, 0.17, 0.14),
		"top": Color(0.26, 0.23, 0.2), "legs": Color(0.2, 0.18, 0.16), "boots": Color(0.12, 0.1, 0.09), "belt": Color(0.35, 0.26, 0.16),
		"hair_style": "hood", "sleeves": true, "shield": true, "staff": true},
	"obligator": {"scale": 1.04, "build": 0.95, "skin": Color(0.82, 0.7, 0.6), "hair": Color(0.82, 0.7, 0.6),
		"top": Color(0.46, 0.46, 0.5), "legs": Color(0.42, 0.42, 0.46), "boots": Color(0.2, 0.2, 0.22), "belt": Color(0.3, 0.3, 0.34),
		"hair_style": "bald", "sleeves": true, "robe": true, "tattoos": true},
	"inquisitor": {"scale": 1.22, "build": 1.05, "skin": Color(0.74, 0.68, 0.66), "hair": Color(0.74, 0.68, 0.66),
		"top": Color(0.1, 0.09, 0.11), "legs": Color(0.08, 0.08, 0.1), "boots": Color(0.06, 0.06, 0.07), "belt": Color(0.2, 0.18, 0.2),
		"hair_style": "bald", "sleeves": true, "robe": true, "spikes": true, "axe": true},
}

const METAL := Color(0.62, 0.65, 0.7)
const METAL_BRIGHT := Color(0.8, 0.83, 0.88)
const OBSIDIAN := Color(0.07, 0.07, 0.09)
const WOOD := Color(0.5, 0.36, 0.22)

static var _cache := {}


static func frame_count(who: String, state: String) -> int:
	return FRAMES.get(state, 1) if REQUIRED.get(_base(who), []).has(state) else 0


static func fps(state: String) -> float:
	return FPS.get(state, 10.0)


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


## Joint angles in degrees. Limbs: 0 hangs straight down, positive swings
## forward. lean: torso tilt forward. crouch: hip drop. bob: body shift.
static func pose(state: String, frame: int) -> Dictionary:
	var p := {"lean": 3.0, "crouch": 0.0, "bob": 0.0, "breath": 0.0, "head": 0.0,
		"thigh_f": 5.0, "shin_f": -4.0, "thigh_b": -5.0, "shin_b": -3.0,
		"arm_f": 6.0, "fore_f": 14.0, "arm_b": -8.0, "fore_b": 12.0, "weapon": "rest"}
	match state:
		"idle":
			if frame % 2 == 1:
				p.breath = 0.8
		"run":
			var f := frame % 6
			var fl: Array = RUN_LEGS[f]
			var bl: Array = RUN_LEGS[(f + 3) % 6]
			p.merge({"lean": 12.0, "bob": float(RUN_BOB[f]),
				"thigh_f": float(fl[0]), "shin_f": float(fl[1]), "thigh_b": float(bl[0]), "shin_b": float(bl[1]),
				"arm_f": -0.9 * float(fl[0]), "fore_f": 85.0, "arm_b": -0.9 * float(bl[0]), "fore_b": 85.0}, true)
		"walk":
			var f := frame % 6
			var fl: Array = WALK_LEGS[f]
			var bl: Array = WALK_LEGS[(f + 3) % 6]
			p.merge({"lean": 4.0, "bob": float(WALK_BOB[f]),
				"thigh_f": float(fl[0]), "shin_f": float(fl[1]), "thigh_b": float(bl[0]), "shin_b": float(bl[1]),
				"arm_f": -0.6 * float(fl[0]), "fore_f": 22.0, "arm_b": -0.6 * float(bl[0]), "fore_b": 22.0}, true)
		"leap":
			p.merge({"lean": 18.0, "thigh_f": 55.0, "shin_f": -70.0, "thigh_b": -32.0, "shin_b": -30.0, "arm_f": 60.0, "fore_f": 40.0, "arm_b": -55.0, "fore_b": 20.0}, true)
		"jump":
			p.merge({"lean": 6.0, "thigh_f": 48.0, "shin_f": -85.0, "thigh_b": 4.0, "shin_b": -30.0, "arm_f": 150.0, "fore_f": 10.0, "arm_b": -35.0, "fore_b": 40.0}, true)
		"fall":
			p.merge({"lean": -4.0, "thigh_f": 22.0, "shin_f": -18.0, "thigh_b": -12.0, "shin_b": -10.0, "arm_f": 125.0, "fore_f": 20.0, "arm_b": 105.0, "fore_b": 30.0}, true)
		"crouch":
			p.merge({"crouch": 10.0, "lean": 20.0, "thigh_f": 80.0, "shin_f": -110.0, "thigh_b": 62.0, "shin_b": -118.0, "arm_f": 35.0, "fore_f": 45.0, "arm_b": 20.0, "fore_b": 40.0}, true)
		"ledge_hang":
			p.merge({"lean": 0.0, "arm_f": 176.0, "fore_f": 0.0, "arm_b": 172.0, "fore_b": 0.0, "thigh_f": 10.0, "shin_f": -8.0, "thigh_b": -4.0, "shin_b": -16.0}, true)
		"bracket_hang":
			p.merge({"lean": 2.0, "arm_f": 162.0, "fore_f": 10.0, "arm_b": 40.0, "fore_b": 30.0, "thigh_f": 22.0, "shin_f": -32.0, "thigh_b": -8.0, "shin_b": -6.0}, true)
		"wall_slide":
			p.merge({"lean": -6.0, "arm_f": 150.0, "fore_f": 20.0, "arm_b": -20.0, "fore_b": 20.0, "thigh_f": 32.0, "shin_f": -42.0, "thigh_b": 10.0, "shin_b": -20.0}, true)
		"stagger", "recover":
			p.merge({"lean": -16.0, "head": -2.0, "arm_f": 60.0, "fore_f": 50.0, "arm_b": -70.0, "fore_b": -30.0, "thigh_f": 22.0, "shin_f": -6.0, "thigh_b": -20.0, "shin_b": -10.0}, true)
		"dodge":
			p.merge({"crouch": 16.0, "lean": 58.0, "thigh_f": 120.0, "shin_f": -150.0, "thigh_b": 100.0, "shin_b": -150.0, "arm_f": 100.0, "fore_f": 90.0, "arm_b": 80.0, "fore_b": 90.0}, true)
		"attack", "strike", "shove":
			var reach: float = [82.0, 58.0, 100.0][frame % 3]
			p.merge({"lean": 10.0, "arm_f": reach, "fore_f": 4.0, "arm_b": -30.0, "fore_b": 40.0, "thigh_f": 26.0, "shin_f": -10.0, "thigh_b": -22.0, "shin_b": -6.0, "weapon": "thrust"}, true)
		"windup":
			p.merge({"lean": -6.0, "arm_f": 150.0, "fore_f": 30.0, "arm_b": -30.0, "fore_b": 30.0, "thigh_f": 10.0, "thigh_b": -16.0, "weapon": "raised"}, true)
		"heavy":
			p.merge({"lean": 16.0, "arm_f": 165.0, "fore_f": -30.0, "arm_b": 150.0, "fore_b": -20.0, "thigh_f": 30.0, "shin_f": -20.0, "thigh_b": -20.0, "weapon": "raised"}, true)
		"dash":
			p.merge({"lean": 30.0, "arm_f": 86.0, "fore_f": 0.0, "arm_b": -40.0, "fore_b": 30.0, "thigh_f": 46.0, "shin_f": -30.0, "thigh_b": -46.0, "shin_b": -20.0, "weapon": "thrust"}, true)
		"plunge":
			p.merge({"lean": 2.0, "thigh_f": 6.0, "shin_f": -6.0, "thigh_b": -2.0, "shin_b": -4.0, "arm_f": 12.0, "fore_f": -22.0, "arm_b": 10.0, "fore_b": -10.0, "weapon": "down"}, true)
		"push":
			p.merge({"lean": -4.0, "arm_f": 92.0, "fore_f": 0.0, "arm_b": -30.0, "fore_b": 20.0, "thigh_f": 16.0, "shin_f": -10.0, "thigh_b": -16.0, "shin_b": -8.0}, true)
		"pull":
			p.merge({"lean": 6.0, "arm_f": 96.0, "fore_f": 40.0, "arm_b": -20.0, "fore_b": 30.0, "thigh_f": 12.0, "shin_f": -8.0, "thigh_b": -10.0, "shin_b": -6.0}, true)
		"alarm":
			p.merge({"lean": -4.0, "arm_f": 158.0, "fore_f": 12.0, "arm_b": 155.0, "fore_b": 12.0}, true)
		"dead":
			p.merge({"lean": -88.0, "crouch": 21.0, "head": 2.0, "thigh_f": -84.0, "thigh_b": -90.0, "shin_f": -6.0, "shin_b": 4.0, "arm_f": -110.0, "fore_f": -20.0, "arm_b": -70.0, "fore_b": -10.0}, true)
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
		look.erase("pauldrons")
	if who.contains("noshield"):
		look.erase("shield")
	var s: float = look.scale
	var build: float = look.build
	var p := pose(state, frame)
	var c := PixelPainter.new(W, H, ORIGIN)

	# Skeleton.
	var thigh := 11.0 * s
	var shin := 11.0 * s
	var torso := 15.0 * s + float(p.breath)
	var upper := 8.0 * s
	var lower := 7.5 * s
	var head_r := 4.3 * s
	var hip := Vector2(0, -(thigh + shin) * 0.97 + p.crouch + p.bob)
	var lean_a := deg_to_rad(p.lean)
	var up := Vector2(sin(lean_a), -cos(lean_a))
	var fwd := Vector2(-up.y, up.x)
	var top: Vector2 = hip + up * torso
	var shoulder: Vector2 = top - up * 1.5
	var head_c: Vector2 = top + up * (2.0 + head_r) + fwd * p.head
	var hipw := 3.0 * s * build
	var shw := 3.8 * s * build
	var hip_f: Vector2 = hip + fwd * 1.4 * s
	var hip_b: Vector2 = hip - fwd * 1.4 * s
	var sh_f: Vector2 = shoulder + fwd * (shw * 0.55)
	var sh_b: Vector2 = shoulder - fwd * (shw * 0.55)
	var knee_f: Vector2 = hip_f + _dir(p.thigh_f) * thigh
	var foot_f: Vector2 = knee_f + _dir(p.thigh_f + p.shin_f) * shin
	var knee_b: Vector2 = hip_b + _dir(p.thigh_b) * thigh
	var foot_b: Vector2 = knee_b + _dir(p.thigh_b + p.shin_b) * shin
	var elbow_f: Vector2 = sh_f + _dir(p.arm_f) * upper
	var hand_f: Vector2 = elbow_f + _dir(p.arm_f + p.fore_f) * lower
	var elbow_b: Vector2 = sh_b + _dir(p.arm_b) * upper
	var hand_b: Vector2 = elbow_b + _dir(p.arm_b + p.fore_b) * lower
	var along_f := _dir(p.arm_f + p.fore_f)

	# Widths.
	var thigh_w := 2.3 * s * build
	var shin_w := 1.8 * s * build
	var arm_w := 1.7 * s * build
	var fore_w := 1.4 * s * build
	var skin: Color = look.skin
	var top_c: Color = look.top
	var legs_c: Color = look.legs
	var boots_c: Color = look.boots
	var fore_c: Color = top_c if look.get("sleeves", false) else skin
	var back := 0.72
	var robe: bool = look.get("robe", false)

	# 1. Kelsier's cloak hangs behind him and streams back as he moves.
	if look.has("cloak"):
		var sweep := -fwd * (3.0 + absf(p.lean) * 0.35) * s
		var hem_y := hip.y + thigh * 1.3
		var pts := PackedVector2Array([sh_b - fwd * 1.0 + up * 1.0, sh_f - fwd * 0.5 + up * 1.0,
			Vector2(hip.x + fwd.x * 2.0, hem_y) + sweep * 0.5, Vector2(hip.x - 7.0 * s, hem_y) + sweep])
		c.poly(pts, look.cloak)
		# Tassel cuts along the hem.
		for i in 5:
			var t0 := float(i) / 5.0
			var hp := pts[3].lerp(pts[2], t0 + 0.1)
			c.line(hp, hp + Vector2(0, -3.0 * s), 0.5, Color(0, 0, 0, 0))
	# 2. Back limbs, darker.
	if look.get("staff", false):
		c.line(hand_b + Vector2(-13, 11) * s, hand_b + Vector2(12, -15) * s, 0.8 * s, WOOD.darkened(0.15))
	c.bar(hip_b, knee_b, thigh_w, legs_c.darkened(1.0 - back))
	c.bar(knee_b, foot_b, shin_w, legs_c.darkened(1.0 - back))
	_boot(c, foot_b, p.thigh_b + p.shin_b, s, boots_c.darkened(0.25))
	c.bar(sh_b, elbow_b, arm_w, top_c.darkened(1.0 - back))
	c.bar(elbow_b, hand_b, fore_w, fore_c.darkened(1.0 - back))
	c.disc(hand_b, 1.1 * s, skin.darkened(0.3))
	# 3. Torso or robe.
	if robe:
		var hem := Vector2(hip.x, (knee_f.y + knee_b.y) * 0.5 + shin * 0.45)
		var hemw := 6.0 * s
		c.poly(PackedVector2Array([sh_b - fwd * 1.2, sh_f + fwd * 1.2, hem + Vector2(hemw, 0) + fwd * 1.0, hem + Vector2(-hemw, 0) - fwd * 1.0]), top_c)
		# A fold line down the front and a rope belt.
		c.line(hip + fwd * 1.0, hem + Vector2(1.5 * s, 0), 0.4, top_c.darkened(0.35))
		c.line(hip - fwd * hipw, hip + fwd * hipw, 0.7, look.belt)
	else:
		c.poly(PackedVector2Array([hip - fwd * hipw, hip + fwd * hipw, top + fwd * shw - up * 0.5, top - fwd * shw - up * 0.5]), top_c)
		c.bar(hip - fwd * hipw * 0.9, hip + fwd * hipw * 0.9, 1.1 * s, legs_c)
		c.line(hip + up * 1.5 - fwd * hipw, hip + up * 1.5 + fwd * hipw, 0.7, look.belt)
		# Collar.
		c.line(top - fwd * 1.5, top + fwd * 1.5, 0.6, top_c.lightened(0.15))
	if look.get("sash", false):
		# Vin's sash of vials, shoulder to hip across the chest.
		c.line(sh_b + up * 0.5, hip + fwd * hipw * 0.8, 0.8 * s, Color(0.15, 0.14, 0.16))
		for i in 3:
			var vp := (sh_b + up * 0.5).lerp(hip + fwd * hipw * 0.8, 0.3 + 0.2 * i)
			c.px(vp, Color(0.75, 0.85, 0.95))
	if look.get("breastplate", false):
		var plate := PackedVector2Array([hip + up * 2.0 - fwd * (hipw + 0.3), hip + up * 2.0 + fwd * (hipw + 0.3),
			top + fwd * (shw + 0.3) - up * 1.0, top - fwd * (shw + 0.3) - up * 1.0])
		c.poly(plate, METAL, true)
		c.line(hip + up * 3.0 + fwd * 1.0, top - up * 2.0 + fwd * 1.5, 0.5, METAL_BRIGHT, true)
	if look.get("pauldrons", false):
		c.disc(sh_b + up * 1.0, 2.0 * s, METAL.darkened(0.2), true)
	# 4. Neck and head.
	c.bar(top, head_c, 1.3 * s, skin)
	c.disc(head_c, head_r, skin)
	c.disc(head_c + Vector2(0.6, 1.3) * s, head_r * 0.72, skin)
	_hair(c, head_c, head_r, s, look)
	_face(c, head_c, head_r, s, look, p)
	if look.get("pauldrons", false):
		c.disc(sh_f + up * 1.0, 2.0 * s, METAL, true)
	# 5. Front limbs.
	if not robe:
		c.bar(hip_f, knee_f, thigh_w, legs_c)
		c.bar(knee_f, foot_f, shin_w, legs_c)
	else:
		c.bar(knee_f, foot_f, shin_w, legs_c)
	_boot(c, foot_f, p.thigh_f + p.shin_f, s, boots_c)
	c.bar(sh_f, elbow_f, arm_w, top_c)
	c.bar(elbow_f, hand_f, fore_w, fore_c)
	if look.get("scars", false):
		for k in 3:
			c.px(elbow_f.lerp(hand_f, 0.3 + 0.2 * k) + along_f.orthogonal() * 0.6, Color(0.95, 0.82, 0.78))
	c.disc(hand_f, 1.1 * s, skin)
	# 6. Gear in the front hand.
	if look.get("spear", false):
		var at_rest: bool = p.weapon == "rest"
		var shaft_dir := Vector2(0.08, -1).normalized() if at_rest else along_f
		var grip := hand_f + fwd * 1.5 * s if at_rest else hand_f
		var butt := grip - shaft_dir * (12.0 if at_rest else 8.0) * s
		var tip := grip + shaft_dir * (20.0 if at_rest else 16.0) * s
		c.line(butt, tip, 0.45, WOOD)
		c.px(butt, METAL.darkened(0.2), true)
		var side := shaft_dir.orthogonal()
		c.poly(PackedVector2Array([tip - side * 1.4 * s, tip + shaft_dir * 5.0 * s, tip + side * 1.4 * s, tip - shaft_dir * 1.0 * s]), METAL_BRIGHT, true)
	if look.get("axe", false):
		var at_rest: bool = p.weapon == "rest"
		var haft_dir := Vector2(0.12, -1.0).normalized() if at_rest else along_f
		var grip := hand_f + fwd * 1.0 * s
		var head := grip + haft_dir * 13.0 * s
		c.line(grip - haft_dir * 7.0 * s, head, 0.6, Color(0.28, 0.22, 0.16))
		var side := haft_dir.orthogonal()
		var h := 4.0 * s
		c.poly(PackedVector2Array([head - haft_dir * 3.5 * s, head - haft_dir * 2.5 * s + side * h, head + side * h * 1.3, head + haft_dir * 2.5 * s + side * h, head + haft_dir * 3.5 * s]), OBSIDIAN)
		c.line(head - haft_dir * 2.0 * s + side * h * 1.1, head + haft_dir * 2.0 * s + side * h * 1.1, 0.45, Color(0.32, 0.32, 0.38))
	if look.get("shield", false):
		var sc := hand_f + fwd * 2.5 * s
		c.ellipse(sc, 4.5 * s, 7.5 * s, WOOD)
		c.line(sc + Vector2(0, -7.0 * s), sc + Vector2(0, 7.0 * s), 0.4, WOOD.darkened(0.35))
		c.line(sc + Vector2(-2.5 * s, -7.0 * s), sc + Vector2(-2.5 * s, 7.0 * s), 0.3, WOOD.darkened(0.3))
		c.disc(sc, 1.4 * s, WOOD.darkened(0.45))
	if base == "vin" and p.weapon != "rest":
		c.line(hand_f, hand_f + along_f * 5.5 * s, 0.7, OBSIDIAN)
		c.px(hand_f + along_f * 5.5 * s, Color(0.4, 0.4, 0.45))

	c.shade(0.14)
	c.outline()
	return {"texture": c.to_canvas_texture(), "diffuse": c.color, "shoulder": shoulder}


static func _boot(c: PixelPainter, foot: Vector2, shin_deg: float, s: float, col: Color) -> void:
	var d := _dir(shin_deg)
	# The foot sits across the shin, toe toward the body's front.
	var toe := foot + d.orthogonal() * 3.4 * s
	c.bar(foot - d * 1.6 * s, foot, 1.9 * s, col)
	c.line(foot, toe, 1.5 * s, col)
	c.px(toe + d * 0.6, col.lightened(0.2))


static func _hair(c: PixelPainter, head_c: Vector2, r: float, s: float, look: Dictionary) -> void:
	var hair: Color = look.hair
	var skin: Color = look.skin
	match look.hair_style:
		"short":
			c.disc(head_c + Vector2(-0.9, -1.2) * s, r * 0.92, hair)
			c.disc(head_c + Vector2(1.5, 0.9) * s, r * 0.66, skin)
			c.disc(head_c + Vector2(0.4, 1.6) * s, r * 0.55, skin)
			# Fringe and a strand before the ear.
			c.px(head_c + Vector2(2.2, -2.6) * s, hair)
			c.px(head_c + Vector2(-2.6, 1.6) * s, hair)
			if look.get("smile", false):
				c.px(head_c + Vector2(0.0, -4.6) * s, hair)
				c.px(head_c + Vector2(-2.0, -4.2) * s, hair)
		"helm":
			c.disc(head_c + Vector2(-0.3, -1.1) * s, r * 1.02, METAL, true)
			c.disc(head_c + Vector2(1.4, 1.4) * s, r * 0.66, skin)
			c.disc(head_c + Vector2(0.2, 1.9) * s, r * 0.55, skin)
			c.line(head_c + Vector2(2.6, -1.4) * s, head_c + Vector2(3.2, 1.6) * s, 0.45, METAL.darkened(0.15), true)
			c.line(head_c + Vector2(-4.0, 0.2) * s, head_c + Vector2(1.5, -0.2) * s, 0.4, METAL.darkened(0.3), true)
		"hood":
			c.disc(head_c + Vector2(-1.0, -0.8) * s, r * 1.12, hair)
			c.disc(head_c + Vector2(1.9, 0.9) * s, r * 0.6, skin)
			c.px(head_c + Vector2(2.4, -1.8) * s, hair)
		"bald":
			c.px(head_c + Vector2(-0.5, -3.3) * s, skin.lightened(0.25))
	# Ear.
	if look.hair_style != "helm" and look.hair_style != "hood":
		c.px(head_c + Vector2(-3.4, 0.4) * s, skin.darkened(0.2))


static func _face(c: PixelPainter, head_c: Vector2, r: float, s: float, look: Dictionary, p: Dictionary) -> void:
	var skin: Color = look.skin
	var dark := Color(0.06, 0.05, 0.06)
	var eye := head_c + Vector2(2.0, -0.4) * s
	if look.get("spikes", false):
		# Steel through the eye socket, out to a bright point, and two more
		# spikes out of the back of the skull.
		c.line(eye, eye + Vector2(5.5, -0.4) * s, 0.42, METAL, true)
		c.px(eye + Vector2(5.8, -0.5) * s, METAL_BRIGHT, true)
		c.px(eye, Color(0.3, 0.08, 0.08))
		c.px(eye + Vector2(0, 1), Color(0.3, 0.08, 0.08))
		for dy: float in [-1.8, 0.6]:
			c.line(head_c + Vector2(-3.2, dy) * s, head_c + Vector2(-7.5, dy - 1.2) * s, 0.42, METAL, true)
			c.px(head_c + Vector2(-7.8, dy - 1.3) * s, METAL_BRIGHT, true)
		return
	# Brow, eye white and pupil; mouth; cheek.
	c.px(eye + Vector2(-1.0, -1.2) * s, skin.darkened(0.3))
	c.px(eye + Vector2(0.0, -1.2) * s, skin.darkened(0.3))
	c.px(eye, Color(0.95, 0.95, 0.97))
	c.px(eye + Vector2(1.0, 0), dark)
	if look.get("tattoos", false):
		var ink := Color(0.22, 0.26, 0.45)
		c.px(eye + Vector2(-1.0, 0.0), ink)
		c.px(eye + Vector2(-1.0, 1.0), ink)
		c.px(eye + Vector2(0.0, 1.2), ink)
		c.px(eye + Vector2(2.0, -2.0), ink)
	var mouth := head_c + Vector2(1.8, 1.9) * s
	if look.get("smile", false):
		c.px(mouth + Vector2(-0.8, 0), Color(0.45, 0.22, 0.2))
		c.px(mouth + Vector2(0.4, -0.6), Color(0.45, 0.22, 0.2))
		c.px(mouth + Vector2(1.3, -1.2), Color(0.45, 0.22, 0.2))
	else:
		c.px(mouth, skin.darkened(0.35))
		c.px(mouth + Vector2(0.9, -0.2), skin.darkened(0.35))
	if p.get("head", 0.0) < 0.0:
		# Staggered: eye shut.
		c.px(eye, skin.darkened(0.25))
		c.px(eye + Vector2(1.0, 0), skin.darkened(0.25))
