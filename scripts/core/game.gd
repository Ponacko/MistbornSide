extends Node
## Autoload "Game": owns the live tuning resource every system reads from.

var tuning: Tuning = Tuning.new()


func reset_for_test() -> void:
	tuning = Tuning.new()
