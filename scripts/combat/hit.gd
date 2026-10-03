class_name Hit
extends RefCounted
## One blow landing on something that can be hurt.

enum Kind { COIN, DAGGER, DASH, PLUNGE, BACKSTAB, HEAVY, AXE, SPEAR, STAFF, FALL, HAZARD, LIGHT_HAZARD }

var kind := Kind.DAGGER
var damage := 0.0
var direction := Vector2.ZERO
var source: Node
## Light hits stagger only targets without pewter.
var light := true


static func make(hit_kind: Kind, amount: float, dir: Vector2, from: Node, is_light := true) -> Hit:
	var h := Hit.new()
	h.kind = hit_kind
	h.damage = amount
	h.direction = dir
	h.source = from
	h.light = is_light
	return h
