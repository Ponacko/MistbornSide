extends SceneTree
## Writes every character's frames (diffuse and normal) to art/characters as
## sprite sheets, one row per state, for an artist to paint over:
##   godot --headless --path . -s tools/export_sprites.gd

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/characters"))
	for who in CharacterArt.REQUIRED:
		var states: Array = CharacterArt.REQUIRED[who]
		var cols := 4
		var sheet := Image.create(CharacterArt.W * cols, CharacterArt.H * states.size(), false, Image.FORMAT_RGBA8)
		var normals := Image.create(CharacterArt.W * cols, CharacterArt.H * states.size(), false, Image.FORMAT_RGBA8)
		for row in states.size():
			for f in CharacterArt.frame_count(who, states[row]):
				var tex := CharacterArt.texture(who, states[row], f)
				var at := Vector2i(f * CharacterArt.W, row * CharacterArt.H)
				sheet.blit_rect(tex.diffuse_texture.get_image(), Rect2i(0, 0, CharacterArt.W, CharacterArt.H), at)
				normals.blit_rect(tex.normal_texture.get_image(), Rect2i(0, 0, CharacterArt.W, CharacterArt.H), at)
		sheet.save_png("res://art/characters/%s.png" % who)
		normals.save_png("res://art/characters/%s_n.png" % who)
		print("%s: %d states" % [who, states.size()])
	quit()
