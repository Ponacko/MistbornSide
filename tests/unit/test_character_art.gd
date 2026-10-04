extends TestCase


func test_every_state_each_system_uses_has_frames_for_each_character() -> void:
	for who in CharacterArt.REQUIRED:
		for state in CharacterArt.REQUIRED[who]:
			assert_gt(CharacterArt.frame_count(who, state), 0, "%s has %s" % [who, state])


func test_sprites_are_normal_mapped_and_metal_is_specular() -> void:
	var tex := CharacterArt.texture("guard", "idle", 0)
	assert_true(tex.normal_texture != null, "normal map")
	var img := tex.normal_texture.get_image()
	var xs := {}
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				xs[snappedf(img.get_pixel(x, y).r, 0.05)] = true
	assert_gt(xs.size(), 3, "normals vary across the body (it is lit as rounded)")
	assert_true(tex.specular_texture != null, "the breastplate is specular")
	var inq := CharacterArt.texture("inquisitor", "idle", 0)
	assert_true(inq.specular_texture != null, "the spikes catch light")


func test_vin_is_about_48_pixels_and_the_inquisitor_a_head_taller() -> void:
	var vin_h := CharacterArt.silhouette_height("vin", "idle")
	assert_near(vin_h, 48.0, 3.0, "Vin")
	assert_gt(CharacterArt.silhouette_height("inquisitor", "idle"), vin_h + 6.0, "Inquisitor towers")


func test_vin_cloak_attaches_at_her_shoulders_in_every_state() -> void:
	for state in CharacterArt.REQUIRED["vin"]:
		for f in CharacterArt.frame_count("vin", state):
			var s := CharacterArt.shoulder("vin", state, f)
			var mask := CharacterArt.mask("vin", state, f)
			var px := Vector2i(roundi(s.x + CharacterArt.ORIGIN.x), roundi(s.y + CharacterArt.ORIGIN.y))
			var near := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var q := px + Vector2i(dx, dy)
					if q.x >= 0 and q.y >= 0 and q.x < mask.get_width() and q.y < mask.get_height() and mask.get_pixel(q.x, q.y).a > 0.5:
						near = true
			assert_true(near, "%s/%d shoulder on the body" % [state, f])


func test_silhouettes_are_distinguishable() -> void:
	var who := ["vin", "kelsier", "guard", "hazekiller", "obligator", "inquisitor"]
	for i in who.size():
		for j in range(i + 1, who.size()):
			var iou := CharacterArt.silhouette_overlap(who[i], who[j])
			assert_lt(iou, 0.8, "%s vs %s overlap %.2f" % [who[i], who[j], iou])


func test_characters_draw_with_their_sprites_and_respond_to_state() -> void:
	var w := TestWorld.create(self, [Rect2(-200, 0, 400, 32)], Vector2(0, -1))
	await physics_frames(10)
	var sprite: CharacterSprite = w.vin.get_node("Sprite")
	assert_eq(sprite.state, "idle")
	w.vin.controls.move.x = 1.0
	await physics_frames(10)
	assert_eq(sprite.state, "run", "runs")
	w.vin.controls.move = Vector2(0, 1)
	await physics_frames(10)
	assert_eq(sprite.state, "crouch")
