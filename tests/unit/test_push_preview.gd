extends TestCase


func _source(kind: MetalSource.Kind, mass: float) -> MetalSource:
	var s := MetalSource.new()
	s.kind = kind
	s.mass = mass
	return s


func test_anchor_puts_the_long_arrow_on_vin() -> void:
	var s := _source(MetalSource.Kind.ANCHORED, 6.0)
	var r := PushPreview.shares(s, Vector2.DOWN, 45.0)
	assert_near(r.vin, 1.0, 0.001)
	assert_near(r.target, 0.0, 0.001)
	s.free()


func test_loose_coin_puts_the_long_arrow_on_the_coin() -> void:
	var s := _source(MetalSource.Kind.DYNAMIC, 0.01)
	var r := PushPreview.shares(s, Vector2.RIGHT, 45.0)
	assert_gt(r.target, 0.99)
	assert_lt(r.vin, 0.01)
	s.free()


func test_equal_masses_share_evenly() -> void:
	var s := _source(MetalSource.Kind.DYNAMIC, 45.0)
	var r := PushPreview.shares(s, Vector2.RIGHT, 45.0)
	assert_near(r.vin, 0.5, 0.001)
	assert_near(r.target, 0.5, 0.001)
	s.free()


func test_carried_metal_shares_by_the_carriers_body_mass() -> void:
	var s := _source(MetalSource.Kind.CARRIED, 8.0)
	s.body = BodyWithMass.new()
	var r := PushPreview.shares(s, Vector2.RIGHT, 45.0)
	assert_near(r.target, 45.0 / (45.0 + 88.0), 0.01, "guard of 80 kg plus armour")
	s.body.free()
	s.free()


func test_resting_coin_reads_as_anchor_inside_the_cone_and_skid_outside() -> void:
	var w := TestWorld.create(self, [Rect2(-400, 0, 800, 32)])
	var coin := Coin.new()
	coin.position = Vector2(0, -4)
	w.add_child(coin)
	await physics_frames(40)
	var down := PushPreview.shares(coin.source, Vector2.DOWN, 45.0)
	assert_near(down.vin, 1.0, 0.001, "inside the cone")
	var shallow := PushPreview.shares(coin.source, Vector2(1, 0.3).normalized(), 45.0)
	assert_lt(shallow.vin, 0.5, "outside the cone: partial lift")
	assert_gt(shallow.target, 0.5, "outside the cone: the coin skids")


class BodyWithMass:
	extends Node2D
	var body_mass := 80.0
