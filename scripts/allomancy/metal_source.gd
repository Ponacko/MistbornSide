@tool
class_name MetalSource
extends Node2D
## Anything an Allomancer can Push or Pull on. Add as a child of the object
## that carries the metal; the source sits at its own position.
##
## ANCHORED: does not move (lamp post, bracket, nail); all force goes to the
##   Allomancer. Mass only affects line thickness and target weighting.
## DYNAMIC: a RigidBody2D parent shares the force by mass (coins, braziers).
## CARRIED: metal on a character; Pushes move the carrier's whole body mass.

enum Kind { ANCHORED, DYNAMIC, CARRIED }

## Kilograms. A clip is 0.01, a spear 2, a breastplate 8, a lamp post 300.
@export var mass := 1.0
@export var kind := Kind.ANCHORED
## Metal inside a body (Inquisitor spikes, Vin's earring) cannot be Pushed or Pulled.
@export var inside_body := false
## Hidden metal glints only while tin is burning.
@export var concealed := false

## The node force is applied to: the RigidBody2D for DYNAMIC, the character
## for CARRIED. Defaults to the parent.
var body: Node2D
var enabled := true


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	if body == null:
		body = get_parent() as Node2D
	MetalRegistry.register(self)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	MetalRegistry.unregister(self)


func is_targetable() -> bool:
	return enabled and not inside_body


func line_width() -> float:
	return BlueLineStyle.width_for_mass(mass)


## Mass that resists a Push: the carrier's body plus the metal for carried
## metal, the rigid body for dynamic metal, infinite for anchors.
func push_mass() -> float:
	match kind:
		Kind.ANCHORED:
			return INF
		Kind.CARRIED:
			if body and "body_mass" in body:
				return float(body.body_mass) + mass
			return mass
		_:
			if body is RigidBody2D:
				return (body as RigidBody2D).mass
			return mass


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 3.0, Color(0.5, 0.75, 1.0))
