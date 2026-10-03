class_name Allomancer
extends Node
## Vin's Allomancy: reads the metal around her, keeps the current target,
## publishes the blue lines for the drawer, and applies Steelpush and
## Ironpull through Steelsight's firing rules.

enum Mode { NONE, PUSH, PULL }

## One entry per visible source: {source, id, to, width, alpha, carried, through_wall, inside_body}.
var lines: Array[Dictionary] = []
var target: MetalSource
var vin: Vin
## The source the current Push or Pull acts on, held while the button is.
var locked: MetalSource
var mode := Mode.NONE
var steelsight := Steelsight.new()
## True on frames where a Push or Pull force acted on Vin.
var force_active := false
## Direction of this frame's force on Vin.
var force_dir := Vector2.ZERO
## Other candidates near the cursor that the target cycle steps through.
var cycle_candidates: Array[MetalSource] = []

var _cycle_id: Variant = null
## After a forced release (jumping off a bracket), a still-held button does
## nothing until it is let go and pressed again.
var _ignore_held := false
var _candidates := []
var _prev_positions := {}
var _cur_positions := {}
var _prev_chest := Vector2.ZERO
var _cur_chest := Vector2.ZERO
var _ray: PhysicsRayQueryParameters2D
var _space: PhysicsDirectSpaceState2D


func _init(owner_vin: Vin) -> void:
	vin = owner_vin
	name = "Allomancer"


## True while Vin has steel or iron to burn. Lines show only then.
func sees_lines() -> bool:
	return vin.reserves.has(MetalReserves.Metal.STEEL) or vin.reserves.has(MetalReserves.Metal.IRON)


func physics_update(delta: float) -> void:
	_update_lines_and_target()
	_apply_force(delta)


func _update_lines_and_target() -> void:
	_prev_chest = _cur_chest
	_cur_chest = vin.chest_position()
	_prev_positions = _cur_positions
	_cur_positions = {}
	lines.clear()
	_candidates.clear()
	cycle_candidates.clear()
	if not sees_lines():
		target = null
		return
	var t := Game.tuning
	for s in MetalRegistry.query(_cur_chest, t.line_range):
		if s.body == vin or (s.concealed and not vin.senses.sees_concealed()):
			continue
		var id := s.get_instance_id()
		var pos := s.global_position
		_cur_positions[id] = pos
		var wall := _blocked(_cur_chest, pos)
		lines.append({
			"source": s, "id": id, "to": pos, "width": s.line_width(),
			"alpha": BlueLineStyle.alpha(pos.distance_to(_cur_chest), t.line_range, wall),
			"carried": s.kind == MetalSource.Kind.CARRIED, "through_wall": wall,
			"inside_body": s.inside_body,
		})
		if s.is_targetable():
			_candidates.append({"source": s, "pos": pos, "mass": s.mass, "kind": s.kind, "id": id})
	var ctx := _context()
	var picked := TargetScorer.pick(_candidates, ctx)
	_update_cycle(ctx, picked)


## Mouse wheel or Q steps through candidates near the aim point; the pick
## sticks until the player moves the aim.
func _update_cycle(ctx: TargetScorer.Context, picked: Dictionary) -> void:
	var c := vin.controls
	if c.aim_moved:
		_cycle_id = null
	if not ctx.aim_active:
		ctx.aim_point = _cur_chest
	var ranked := TargetScorer.ranked(_candidates, ctx)
	if ranked.size() >= 2:
		for r in ranked:
			cycle_candidates.append(r.source)
	if c.target_cycle != 0 and not ranked.is_empty():
		var current: Variant = _cycle_id if _cycle_id != null else (picked.id if not picked.is_empty() else null)
		var index := -1
		for i in ranked.size():
			if ranked[i].id == current:
				index = i
		index = posmod(index + c.target_cycle, ranked.size())
		_cycle_id = ranked[index].id
		if mode != Mode.NONE and steelsight.firing():
			locked = ranked[index].source
	if _cycle_id != null:
		for r in _candidates:
			if r.id == _cycle_id:
				target = r.source
				return
		_cycle_id = null
	target = picked.source if not picked.is_empty() else null


func _apply_force(delta: float) -> void:
	force_active = false
	var c := vin.controls
	var t := Game.tuning
	if _ignore_held:
		if c.push_held or c.pull_held:
			return
		_ignore_held = false
	if c.push_pressed:
		mode = Mode.PUSH
		locked = null
	elif c.pull_pressed:
		mode = Mode.PULL
		locked = null
	elif mode == Mode.NONE and (c.push_held or c.pull_held):
		mode = Mode.PUSH if c.push_held else Mode.PULL
	var held := (c.push_held if mode == Mode.PUSH else c.pull_held) if mode != Mode.NONE else false
	var pressed := c.push_pressed or c.pull_pressed
	steelsight.update(TimeController.real_delta(delta), pressed, held, target != null, t, c.gamepad)
	TimeController.set_factor(&"steelsight", steelsight.time_scale(t))
	if not steelsight.firing():
		if steelsight.phase == Steelsight.Phase.IDLE:
			mode = Mode.NONE
			locked = null
		return

	var metal := MetalReserves.Metal.STEEL if mode == Mode.PUSH else MetalReserves.Metal.IRON
	if not vin.reserves.has(metal):
		locked = null
		return
	if mode == Mode.PULL:
		_pouch_arriving_coins()
	# Retarget while holding: only a deliberate aim move switches the lock.
	if c.aim_moved and target != null and target != locked:
		locked = target
	if not _valid(locked):
		locked = target
	if not _valid(locked):
		locked = null
		if mode == Mode.PULL:
			_recall(delta)
		return
	var to_source := locked.global_position - _cur_chest
	var d := to_source.length()
	if d >= t.line_range:
		locked = null
		return
	var dir := to_source / d if d > 0.001 else Vector2.DOWN
	var flare := t.flare_force if c.flare_held else 1.0
	var impulse := t.push_accel() * t.vin_mass * flare * ForceModel.falloff(d, t.line_range) * delta
	# A Push drives the target away from Vin and Vin away from it; a Pull the reverse.
	var vin_dir := -dir if mode == Mode.PUSH else dir
	var delivered := PushPhysics.deliver(locked, -vin_dir * impulse, t.vin_mass, t)
	var dv := vin_dir * delivered.length() / t.vin_mass
	var hovering := mode == Mode.PUSH and rad_to_deg(vin_dir.angle_to(Vector2.UP)) < t.hover_cone_degrees and rad_to_deg(vin_dir.angle_to(Vector2.UP)) > -t.hover_cone_degrees
	if hovering:
		dv.x *= t.hover_lateral_mult
		vin.velocity.x = ForceModel.hover_damp(t, vin.velocity.x, delta) if c.move.x == 0.0 else vin.velocity.x
	vin.velocity += dv
	if mode == Mode.PULL and locked.kind == MetalSource.Kind.ANCHORED:
		var along := vin.velocity.project(dir)
		var across := vin.velocity - along
		vin.velocity = along + across * maxf(1.0 - t.pull_line_damping * delta, 0.0)
	if absf(vin_dir.y) > 0.8:
		vin.velocity.y = ForceModel.hover_damp(t, vin.velocity.y, delta)
	vin.reserves.burn(metal, delta, c.flare_held)
	force_active = true
	force_dir = vin_dir
	if mode == Mode.PULL and locked.kind == MetalSource.Kind.ANCHORED:
		# Swept catch: also cling if this frame's flight passes close by.
		var step_end := _cur_chest + vin.velocity * delta
		var closest := Geometry2D.get_closest_point_to_segment(locked.global_position, _cur_chest, step_end)
		if minf(d, closest.distance_to(locked.global_position)) < t.bracket_catch_distance:
			vin.cling_to(locked)


## True while a Pull on an anchor is carrying Vin (gravity is lightened).
func pulling_anchor() -> bool:
	return force_active and mode == Mode.PULL and _valid(locked) and locked.kind == MetalSource.Kind.ANCHORED


## Ends the current Push or Pull; it will not resume until the button is
## pressed again.
func release() -> void:
	mode = Mode.NONE
	locked = null
	steelsight.cancel()
	_ignore_held = true
	TimeController.set_factor(&"steelsight", 1.0)


## The faint half-second arc drawn during Steelsight and its ramp.
func predicted_arc() -> PackedVector2Array:
	var t := Game.tuning
	var source := locked if _valid(locked) else target
	var pos := Vector2.INF
	var share := 0.0
	var sign := -1.0 if vin.controls.pull_held and not vin.controls.push_held else 1.0
	if source:
		pos = source.global_position
		var on_target := (pos - _cur_chest).normalized() * sign
		share = PushPreview.shares(source, on_target, t.vin_mass).vin
	var flare := t.flare_force if vin.controls.flare_held else 1.0
	return ArcPredictor.predict(vin.global_position, vin.velocity, pos, share, sign, flare, t)


func shows_arc() -> bool:
	return steelsight.aiming() or steelsight.time_scale(Game.tuning) < 1.0


## Holding Pull with no target: every loose coin in range flies back.
func _recall(delta: float) -> void:
	var any := false
	for s in MetalRegistry.query(_cur_chest, Game.tuning.line_range):
		if s.body is Coin and not s.inside_body:
			(s.body as Coin).recall_toward(_cur_chest, delta)
			any = true
	if any:
		vin.reserves.burn(MetalReserves.Metal.IRON, delta, vin.controls.flare_held)


## Coins Pulled into Vin's hands go back in the pouch.
func _pouch_arriving_coins() -> void:
	for s in MetalRegistry.query(_cur_chest, 16.0):
		if s.body is Coin and (s.body as Coin).count > 0:
			vin.pouch.pouch(s.body)


func _valid(s: MetalSource) -> bool:
	return is_instance_valid(s) and s.is_inside_tree() and s.is_targetable()


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
	ctx.cycle_radius = t.aim_cycle_radius
	ctx.below_cone = t.below_cone_degrees
	return ctx


## True if level geometry lies between the two points. A hit right at the
## source is the wall the metal is fixed into, not an obstruction.
func _blocked(from: Vector2, to: Vector2) -> bool:
	if _ray == null:
		_ray = PhysicsRayQueryParameters2D.create(from, to, Layers.WORLD, [vin.get_rid()])
		_space = vin.get_world_2d().direct_space_state
	_ray.from = from
	_ray.to = to
	var hit := _space.intersect_ray(_ray)
	return not hit.is_empty() and (hit.position as Vector2).distance_to(to) > 6.0


## Chest and source positions blended between the last two physics frames.
func interpolated_chest(fraction: float) -> Vector2:
	return _prev_chest.lerp(_cur_chest, fraction) if _prev_chest != Vector2.ZERO else _cur_chest


func interpolated_position(id: int, fraction: float) -> Vector2:
	var cur: Vector2 = _cur_positions.get(id, Vector2.ZERO)
	var prev: Vector2 = _prev_positions.get(id, cur)
	return prev.lerp(cur, fraction)
