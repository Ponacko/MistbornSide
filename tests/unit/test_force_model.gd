extends TestCase


func test_falloff_is_full_at_zero_and_smoothly_zero_at_range() -> void:
	assert_near(ForceModel.falloff(0.0, 300.0), 1.0, 0.0001)
	assert_near(ForceModel.falloff(300.0, 300.0), 0.0, 0.0001)
	assert_near(ForceModel.falloff(350.0, 300.0), 0.0, 0.0001, "clamped beyond range")
	var prev := 1.0
	for d in range(0, 301, 3):
		var f := ForceModel.falloff(float(d), 300.0)
		assert_lt(absf(prev - f), 0.025, "smooth at %d" % d)
		prev = f


func test_derived_push_reaches_the_stated_height_at_the_stated_time() -> void:
	var t := Tuning.new()
	var a0 := t.push_accel()
	var y := ForceModel.reference_height_at(t, a0, t.push_reach_time)
	assert_near(y, t.push_reach_tiles * Tuning.TILE, 1.0, "height at reach time")


func test_derived_push_changes_when_tuning_changes() -> void:
	var t := Tuning.new()
	var a := t.push_accel()
	t.push_reach_tiles = 9.0
	assert_gt(t.push_accel(), a, "higher reach needs more force")


func test_anchor_takes_nothing_and_vin_gets_the_whole_impulse() -> void:
	var r := ForceModel.split(100.0, 45.0, INF, INF)
	assert_near(r.vin_dv, 100.0 / 45.0, 0.0001)
	assert_near(r.target_dv, 0.0, 0.0001)


func test_equal_masses_share_equally_and_impulses_are_equal_and_opposite() -> void:
	var r := ForceModel.split(90.0, 45.0, 45.0, INF)
	assert_near(r.vin_dv, r.target_dv, 0.0001)
	assert_near(r.vin_dv * 45.0, r.target_dv * 45.0, 0.0001, "equal momentum")


func test_coin_takes_almost_all_motion_and_is_capped() -> void:
	var r := ForceModel.split(1000.0, 45.0, 0.01, 900.0)
	assert_near(r.target_dv, 900.0, 0.0001, "capped coin speed change")
	assert_lt(r.vin_dv, 0.25, "Vin barely moves")
	assert_near(r.vin_dv * 45.0, r.target_dv * 0.01, 0.0001, "momentum conserved")


func test_reserves_drain_flare_and_refill() -> void:
	var r := MetalReserves.new()
	var full := r.amount(MetalReserves.Metal.STEEL)
	r.burn(MetalReserves.Metal.STEEL, 1.0, false)
	var normal := full - r.amount(MetalReserves.Metal.STEEL)
	assert_gt(normal, 0.0, "drains")
	r.refill_all()
	r.burn(MetalReserves.Metal.STEEL, 1.0, true)
	var flared := full - r.amount(MetalReserves.Metal.STEEL)
	assert_near(flared, normal * MetalReserves.FLARE_DRAIN, 0.001, "flare drains 4x")


func test_pewter_drains_fastest_copper_slowest() -> void:
	var rates := MetalReserves.BASE_RATE
	for m in rates:
		assert_true(rates[MetalReserves.Metal.PEWTER] >= rates[m], "pewter fastest")
		assert_true(rates[MetalReserves.Metal.COPPER] <= rates[m], "copper slowest")


func test_empty_reserve_cannot_burn_and_never_goes_negative() -> void:
	var r := MetalReserves.new()
	r.set_amount(MetalReserves.Metal.IRON, 0.01)
	assert_true(r.burn(MetalReserves.Metal.IRON, 1.0, false), "burns the last bit")
	assert_near(r.amount(MetalReserves.Metal.IRON), 0.0, 0.0001)
	assert_false(r.burn(MetalReserves.Metal.IRON, 1.0, false), "nothing left")
	assert_false(r.has(MetalReserves.Metal.IRON))
