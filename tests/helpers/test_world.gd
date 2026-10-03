class_name TestWorld
extends Node2D
## A throwaway level for scene tests: blocks from rects and a scripted Vin.

var vin: Vin


static func create(test: TestCase, blocks: Array[Rect2], vin_at := Vector2.INF) -> TestWorld:
	var w := TestWorld.new()
	test.add(w)
	for r in blocks:
		w.block(r)
	if vin_at != Vector2.INF:
		w.vin = (load("res://scenes/player/vin.tscn") as PackedScene).instantiate()
		w.vin.scripted = true
		w.vin.position = vin_at
		w.add_child(w.vin)
	return w


func block(r: Rect2) -> Block:
	var b := Block.new()
	b.position = r.position
	b.size = r.size
	add_child(b)
	return b


## An anchored metal source fixed at a point (a bracket or nail).
func anchor(pos: Vector2, mass := 5.0) -> MetalSource:
	var holder := Node2D.new()
	holder.position = pos
	var s := MetalSource.new()
	s.mass = mass
	s.kind = MetalSource.Kind.ANCHORED
	holder.add_child(s)
	add_child(holder)
	return s
