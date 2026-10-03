extends Node
## Autoload "Settings": player-facing comfort and accessibility options
## (DESIGN.md 7.3). Saved with the game in the integration ticket.

## Scales full-screen flashes such as the tin whiteout (0 to 1).
var flash_intensity := 1.0
var screen_shake := 1.0


func reset_for_test() -> void:
	flash_intensity = 1.0
	screen_shake = 1.0
