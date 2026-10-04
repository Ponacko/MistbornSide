class_name CoinPouch
extends Node
## Vin's finite pouch of clips: flick (E), drop (S + E), spray (E + Push).

signal count_changed(count: int)

var vin: Vin
var count := 0:
	set(value):
		count = maxi(value, 0)
		count_changed.emit(count)


func _init(owner_vin: Vin) -> void:
	vin = owner_vin
	name = "CoinPouch"
	count = Game.tuning.coin_pouch_size


func physics_update(_delta: float) -> void:
	var c := vin.controls
	# Spray is E pressed while Push is held; a Push clicked while E is still
	# down from a drop is a Push on that coin, not a spray.
	if c.coin_pressed and c.push_held:
		spray()
	elif c.coin_pressed:
		if c.move.y > 0.5:
			drop()
		else:
			flick()


func flick() -> Coin:
	var dir := Vector2.DOWN
	if vin.controls.aim_active:
		dir = (vin.controls.aim_point - vin.chest_position()).normalized()
	return _throw(vin.chest_position() + dir * 6.0, dir * Game.tuning.coin_flick_speed + vin.velocity * 0.5)


func drop() -> Coin:
	return _throw(vin.global_position + Vector2(0, -Coin.RADIUS - 1.0), Vector2(vin.velocity.x * 0.3, maxf(vin.velocity.y, 0.0)))


## Five clips in a fan, already flying at Push speed.
func spray() -> void:
	var t := Game.tuning
	var aim := vin.controls.aim_point if vin.controls.aim_active else vin.chest_position() + Vector2(vin.facing, 0)
	var dir := (aim - vin.chest_position()).normalized()
	var n := mini(t.coin_spray_count, count)
	for i in n:
		var k := 0.0 if n == 1 else float(i) / (n - 1) - 0.5
		var d := dir.rotated(deg_to_rad(t.coin_spray_spread_degrees) * k)
		_throw(vin.chest_position() + d * 6.0, d * t.projectile_max_speed * 0.85)
	vin.reserves.burn(MetalReserves.Metal.STEEL, 0.5, false)


func _throw(at: Vector2, velocity: Vector2) -> Coin:
	if count <= 0:
		return null
	count -= 1
	var coin := Coin.new()
	coin.thrower = vin
	coin.position = at
	coin.linear_velocity = velocity
	vin.get_parent().add_child(coin)
	return coin


func pouch(coin: Coin) -> void:
	count += coin.count
	coin.count = 0
	coin.queue_free()
