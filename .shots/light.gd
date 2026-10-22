extends Node2D
func _ready():
	var f := Facade.new(); f.position = Vector2(-320, -300); f.size = Vector2(640, 300); f.tint = Color(0.5,0.5,0.56); add_child(f)
	var b := Block.new(); b.position = Vector2(-320, 0); b.size = Vector2(640, 60); b.style = PixelTextures.Style.STONE; add_child(b)
	var n := NightAtmosphere.new(); add_child(n)
	var l := Lantern.new(); l.position = Vector2(0, -80); l.metal = false; add_child(l)
	if OS.get_environment("NOSHADOW") == "1": l.light.shadow_enabled = false
	var cam := Camera2D.new(); cam.position = Vector2(0, -120); add_child(cam); cam.make_current()
