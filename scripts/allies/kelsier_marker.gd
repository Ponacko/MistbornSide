@tool
class_name KelsierMarker
extends Node2D
## One step of Kelsier's script in a level, placed by a designer with no
## code. Markers run in child order under the node Kelsier's markers_path
## points to.
##
## DEMONSTRATE: when Vin comes within trigger_radius of Kelsier he performs
##   `move` once, ending at this marker.
## WAIT: he waits here as a silhouette in the mists until Vin comes within
##   trigger_radius of the marker.
## COMPANION: he fights beside her until she comes within trigger_radius of
##   the marker (the last COMPANION marker never ends).

enum Action { DEMONSTRATE, WAIT, COMPANION }
enum Move { WALK, COIN_JUMP, LEAP, PULL }

@export var action := Action.DEMONSTRATE:
	set(value):
		action = value
		queue_redraw()
@export var move := Move.COIN_JUMP
@export var trigger_radius := 80.0
## Height of the arc above the higher end for COIN_JUMP and LEAP.
@export var arc_height := 60.0
## Seconds the move takes.
@export var duration := 0.8


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var c: Color = [Color(0.9, 0.7, 0.3), Color(0.5, 0.6, 0.9), Color(0.4, 0.9, 0.5)][action]
	draw_circle(Vector2.ZERO, 4.0, c)
	draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 32, Color(c, 0.3), 1.0)
