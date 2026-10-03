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
