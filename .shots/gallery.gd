extends SceneTree
## Renders every portrait and a run strip for each character into .shots.
func _initialize():
	var who := ["vin", "kelsier", "camon", "sazed", "guard", "obligator", "inquisitor"]
	var sheet := Image.create(70 * who.size(), 70, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.06, 0.07, 0.1))
	for i in who.size():
		var img := PortraitArt.texture(who[i]).get_image()
		sheet.blend_rect(img, Rect2i(0, 0, 70, 70), Vector2i(i * 70, 0))
	sheet.save_png("res://.shots/portraits.png")
	var states := {"vin": ["idle", "run", "jump", "fall", "crouch", "attack", "push", "dead"], "kelsier": ["idle", "run", "leap", "attack"],
		"guard": ["idle", "walk", "windup", "strike", "dead"], "hazekiller": ["idle", "walk", "strike"], "obligator": ["idle", "walk", "alarm"], "inquisitor": ["idle", "run", "windup", "strike"]}
	var rows := 0
	for w in states: rows += 1
	var strip := Image.create(64 * 8, 80 * rows, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.18, 0.19, 0.24))
	var r := 0
	for w in states:
		var col := 0
		for st in states[w]:
			var n := CharacterArt.frame_count(w, st)
			for f in n:
				if col >= 8: break
				strip.blend_rect(CharacterArt.mask(w, st, f), Rect2i(0, 0, 64, 80), Vector2i(col * 64, r * 80))
				col += 1
		r += 1
	strip.save_png("res://.shots/strip.png")
	print("gallery ok")
	quit()
