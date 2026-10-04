class_name SenseOverlay
extends Node2D
## Tin's overlay above the mists: noise rings through walls and glints on
## concealed metal.

var vin: Vin
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if vin == null:
		return
	for n in vin.senses.visible_rings():
		var life: float = n.age / NoiseBus.RING_LIFE
		var r: float = 6.0 + NoiseBus.RING_RADIUS * float(n.loudness) * life
		draw_arc(n.pos, r, 0.0, TAU, 32, Color(0.9, 0.92, 1.0, 0.55 * (1.0 - life)), 1.0, true)
	if vin.senses.sees_concealed():
		for l in vin.allomancy.lines:
			if is_instance_valid(l.source) and l.source.concealed:
				var p: Vector2 = l.to
				var a := 0.5 + 0.5 * sin(_time * 7.0 + p.x)
				var c := Color(0.85, 0.95, 1.0, a)
				draw_line(p + Vector2(-3, 0), p + Vector2(3, 0), c, 1.0)
				draw_line(p + Vector2(0, -3), p + Vector2(0, 3), c, 1.0)

	for b in vin.senses.bronze_beacons():
		var n: Node2D = b.node
		var at: Vector2 = n.global_position + Vector2(0, -24)
		var r := 5.0 + 3.0 * (0.5 + 0.5 * sin(_time * 5.0))
		var c := Color(0.85, 0.6, 0.3, 0.8)
		draw_arc(at, r, 0.0, TAU, 16, c, 1.0, true)
		draw_arc(at, r + 4.0, 0.0, TAU, 16, Color(c, 0.35), 1.0, true)
		if b.labelled:
			draw_string(ThemeDB.fallback_font, at + Vector2(-16, -12), b.label, HORIZONTAL_ALIGNMENT_CENTER, 32, 8, c)
