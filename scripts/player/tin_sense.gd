class_name TinSense
extends Node
## Tin (DESIGN.md 5.8): thins the mists, lifts darkness, triples the visible
## radius, shows noise rings through walls and glints on concealed metal. A
## lantern flash whites out and stuns a tin-burner; flaring tin pulses a
## one-off reveal and shakes off a daze.

var vin: Vin
## 0..1, eased toward 1 while tin burns.
var tin_amount := 0.0
## 0..1 whiteout overlay from a flash, fading in real time.
var whiteout := 0.0
## 0..1 reveal pulse from flaring tin.
var pulse := 0.0


func _init(owner_vin: Vin) -> void:
	vin = owner_vin
	name = "TinSense"


func physics_update(delta: float) -> void:
	var real := TimeController.real_delta(delta)
	tin_amount = move_toward(tin_amount, 1.0 if vin.tin_on else 0.0, real * 3.0)
	whiteout = move_toward(whiteout, 0.0, real / 0.8)
	pulse = move_toward(pulse, 0.0, real / Game.tuning.tin_pulse_time)
	if vin.controls.flare_pressed and vin.tin_on:
		pulse = 1.0
		vin.clear_stun()
		vin.reserves.burn(MetalReserves.Metal.TIN, 1.0, true)


func vision_radius() -> float:
	var r := Game.tuning.vision_radius
	return lerpf(r, r * 3.0, tin_amount) + pulse * r * 4.0


## Mists drawn at this fraction of their density.
func mist_thin() -> float:
	return clampf(tin_amount * 0.85 + pulse, 0.0, 1.0)


func sees_concealed() -> bool:
	return tin_amount > 0.5 or pulse > 0.0


## Noise rings visible to Vin: all recent noise, through walls, while tin burns.
func visible_rings() -> Array[Dictionary]:
	if not vin.tin_on:
		return []
	return NoiseBus.recent


## A bright light or loud crack in Vin's face: blinding only with tin on.
func flash(_from: Vector2) -> void:
	if not vin.tin_on:
		return
	whiteout = 1.0
	vin.stun(Game.tuning.tin_flash_stun)
