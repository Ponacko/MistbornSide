extends TestCase


func _c(pos: Vector2, mass := 1.0, kind := MetalSource.Kind.ANCHORED) -> Dictionary:
	return {"source": null, "pos": pos, "mass": mass, "kind": kind, "id": pos}


func _ctx() -> TargetScorer.Context:
	var ctx := TargetScorer.Context.new()
	ctx.origin = Vector2(0, -30)
	ctx.feet = Vector2.ZERO
	ctx.aim_active = true
	return ctx


func test_cursor_picks_the_nearest_source_to_the_aim_point() -> void:
	var ctx := _ctx()
	ctx.aim_point = Vector2(100, -100)
	var a := _c(Vector2(90, -100))
	var b := _c(Vector2(200, -100))
	assert_eq(TargetScorer.pick([a, b], ctx), a)


func test_heavier_source_wins_at_equal_cursor_distance() -> void:
	var ctx := _ctx()
	ctx.aim_point = Vector2(100, -100)
	var nail := _c(Vector2(110, -100), 0.05)
	var gate := _c(Vector2(90, -100), 800.0)
	assert_eq(TargetScorer.pick([nail, gate], ctx), gate)


func test_heavier_source_beats_a_slightly_closer_light_one() -> void:
	var ctx := _ctx()
	ctx.aim_point = Vector2(100, -100)
	var nail := _c(Vector2(104, -100), 0.05)
	var gate := _c(Vector2(114, -100), 800.0)
	assert_eq(TargetScorer.pick([nail, gate], ctx), gate)


func test_no_target_when_nothing_is_near_the_active_cursor() -> void:
	var ctx := _ctx()
	ctx.aim_point = Vector2(300, -300)
	assert_eq(TargetScorer.pick([_c(Vector2(20, 0))], ctx), {})


func test_idle_aim_while_falling_picks_nearest_anchor_below() -> void:
	var ctx := _ctx()
	ctx.aim_active = false
	ctx.falling = true
	var below := _c(Vector2(10, 120))
	var beside := _c(Vector2(60, -30))
	var coin_below := _c(Vector2(-5, 60), 0.01, MetalSource.Kind.DYNAMIC)
	assert_eq(TargetScorer.pick([beside, below, coin_below], ctx), below)


func test_idle_aim_on_ground_picks_coin_at_feet_then_facing() -> void:
	var ctx := _ctx()
	ctx.aim_active = false
	ctx.on_floor = true
	ctx.facing = 1
	var coin := _c(Vector2(4, -2), 0.01, MetalSource.Kind.DYNAMIC)
	var ahead := _c(Vector2(80, -30))
	var behind := _c(Vector2(-40, -30))
	assert_eq(TargetScorer.pick([ahead, coin, behind], ctx), coin, "coin at feet")
	assert_eq(TargetScorer.pick([ahead, behind], ctx), ahead, "facing direction")


func test_idle_aim_falls_back_to_last_target() -> void:
	var ctx := _ctx()
	ctx.aim_active = false
	var last := _c(Vector2(-200, -200))
	ctx.last_id = last.id
	assert_eq(TargetScorer.pick([_c(Vector2(-250, -260)), last], ctx), last)


func test_cycle_steps_through_candidates_near_the_aim_point() -> void:
	var ctx := _ctx()
	ctx.aim_point = Vector2(100, -100)
	var a := _c(Vector2(100, -100))
	var b := _c(Vector2(110, -100))
	var c := _c(Vector2(120, -100))
	var ranked := TargetScorer.ranked([c, a, b], ctx)
	assert_eq(ranked, [a, b, c])
