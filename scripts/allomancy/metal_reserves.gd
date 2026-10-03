class_name MetalReserves
extends RefCounted
## How much of each metal Vin has swallowed and can still burn (DESIGN.md 5.1).

signal changed

enum Metal { STEEL, IRON, TIN, PEWTER, ZINC, BRASS, COPPER, BRONZE }

const FULL := 100.0
const FLARE_DRAIN := 4.0
## Reserve units burned per second at normal intensity. Pewter fastest,
## copper slowest, as in the books.
const BASE_RATE := {
	Metal.STEEL: 2.0, Metal.IRON: 2.0, Metal.TIN: 0.8, Metal.PEWTER: 3.0,
	Metal.ZINC: 1.5, Metal.BRASS: 1.5, Metal.COPPER: 0.2, Metal.BRONZE: 0.5,
}
const NAMES := {
	Metal.STEEL: "steel", Metal.IRON: "iron", Metal.TIN: "tin", Metal.PEWTER: "pewter",
	Metal.ZINC: "zinc", Metal.BRASS: "brass", Metal.COPPER: "copper", Metal.BRONZE: "bronze",
}

var flare_drain := FLARE_DRAIN
## Scales every burn rate; the tuning panel and story beats can change it.
var drain_scale := 1.0
var _amounts := {}


func _init() -> void:
	refill_all()


func amount(metal: Metal) -> float:
	return _amounts[metal]


func fraction(metal: Metal) -> float:
	return _amounts[metal] / FULL


func has(metal: Metal) -> bool:
	return _amounts[metal] > 0.0


func set_amount(metal: Metal, value: float) -> void:
	_amounts[metal] = clampf(value, 0.0, FULL)
	changed.emit()


## Burns for delta seconds. Returns false if the reserve was already empty.
func burn(metal: Metal, delta: float, flared: bool, rate_mult := 1.0) -> bool:
	if not has(metal):
		return false
	var rate: float = BASE_RATE[metal] * drain_scale * rate_mult * (flare_drain if flared else 1.0)
	_amounts[metal] = maxf(_amounts[metal] - rate * delta, 0.0)
	changed.emit()
	return true


## A vial refills every basic metal to full.
func refill_all() -> void:
	for m in Metal.values():
		_amounts[m] = FULL
	changed.emit()


func snapshot() -> Dictionary:
	return _amounts.duplicate()


func restore(data: Dictionary) -> void:
	_amounts = data.duplicate()
	changed.emit()
