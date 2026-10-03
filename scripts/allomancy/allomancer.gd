class_name Allomancer
extends Node
## Vin's Allomancy: reads the metal around her, keeps the current target and
## publishes the blue lines for the drawer.

## One entry per visible source: {source, id, from, to, width, alpha, carried, through_wall}.
var lines: Array[Dictionary] = []
var target: MetalSource
var vin: Vin

## Interpolation endpoints for drawing between physics frames.
var _prev_positions := {}
var _cur_positions := {}
var _prev_chest := Vector2.ZERO
var _cur_chest := Vector2.ZERO


func _init(owner_vin: Vin) -> void:
	vin = owner_vin
	name = "Allomancer"


## True while Vin has steel or iron to burn. Lines show only then.
func sees_lines() -> bool:
	return true


func physics_update(_delta: float) -> void:
	_prev_chest = _cur_chest
	_cur_chest = vin.chest_position()
	_prev_positions = _cur_positions
	_cur_positions = {}
	lines.clear()
	if not sees_lines():
		target = null
		return
	var t := Game.tuning
	var candidates := []
	for s in MetalRegistry.query(_cur_chest, t.line_range):
		if s.body == vin:
			continue
		var id := s.get_instance_id()
		var pos := s.global_position
		_cur_positions[id] = pos
		var d := pos.distance_to(_cur_chest)
		var wall := _blocked(_cur_chest, pos)
		lines.append({
			"source": s, "id": id, "to": pos, "width": s.line_width(),
			"alpha": BlueLineStyle.alpha(d, t.line_range, wall),
			"carried": s.kind == MetalSource.Kind.CARRIED, "through_wall": wall,
			"inside_body": s.inside_body,
		})
		if s.is_targetable():
			candidates.append({"source": s, "pos": pos, "mass": s.mass, "kind": s.kind, "id": id})
	var picked := TargetScorer.pick(candidates, _context())
	target = picked.source if not picked.is_empty() else null


func _context() -> TargetScorer.Context:
	var t := Game.tuning
	var ctx := TargetScorer.Context.new()
	ctx.origin = _cur_chest
	ctx.feet = vin.global_position
	ctx.aim_point = vin.controls.aim_point
	ctx.aim_active = vin.controls.aim_active
	ctx.falling = not vin.is_on_floor() and vin.velocity.y > 0.0
	ctx.on_floor = vin.is_on_floor()
	ctx.facing = vin.facing
	ctx.last_id = target.get_instance_id() if is_instance_valid(target) else null
	ctx.snap_radius = t.aim_snap_radius
	ctx.mass_weight = t.aim_mass_weight
	ctx.below_cone = t.below_cone_degrees
	return ctx


## True if level geometry lies between the two points. A hit right at the
## source is the wall the metal is fixed into, not an obstruction.
func _blocked(from: Vector2, to: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(from, to, Layers.WORLD, [vin.get_rid()])
	var hit := vin.get_world_2d().direct_space_state.intersect_ray(q)
	return not hit.is_empty() and (hit.position as Vector2).distance_to(to) > 6.0


## Chest and source positions blended between the last two physics frames.
func interpolated_chest(fraction: float) -> Vector2:
	return _prev_chest.lerp(_cur_chest, fraction) if _prev_chest != Vector2.ZERO else _cur_chest


func interpolated_position(id: int, fraction: float) -> Vector2:
	var cur: Vector2 = _cur_positions.get(id, Vector2.ZERO)
	var prev: Vector2 = _prev_positions.get(id, cur)
	return prev.lerp(cur, fraction)
