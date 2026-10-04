extends Node
## Autoload "Checkpoints": where Vin comes back after a death or a fall, and
## the reserves, pouch and health she had when she reached it.

signal respawned

var position := Vector2.INF
var _snapshot := {}


## Records a checkpoint. Reaching one refills Vin to the state she has now,
## topped up: reserves and pouch as she carries them, health full.
func reach(vin: Vin, at: Vector2) -> void:
	position = at
	_snapshot = {
		"reserves": vin.reserves.snapshot(),
		"pouch": vin.pouch.count,
	}


func has_checkpoint() -> bool:
	return position != Vector2.INF


func respawn(vin: Vin) -> void:
	if not has_checkpoint():
		reach(vin, vin.global_position)
	vin.respawn_at(position)
	vin.reserves.restore(_snapshot.reserves)
	vin.pouch.count = _snapshot.pouch
	# A wounded chase restarts with enough pewter to be winnable, however
	# low it was when the checkpoint was touched.
	if vin.wounded:
		var floor_amount := MetalReserves.FULL * 0.4
		vin.reserves.set_amount(MetalReserves.Metal.PEWTER, maxf(vin.reserves.amount(MetalReserves.Metal.PEWTER), floor_amount))
	respawned.emit()


func reset_for_test() -> void:
	position = Vector2.INF
	_snapshot = {}
