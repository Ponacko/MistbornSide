extends Node
## Autoload "Settings": player-facing comfort and accessibility options
## (DESIGN.md 7.3). Saved with the game in the integration ticket.

## Scales full-screen flashes such as the tin whiteout (0 to 1).
var flash_intensity := 1.0
var screen_shake := 1.0
## Colour-blind friendly palette for lines and suspicion icons.
var colorblind := false

const PALETTES := {
	false: {&"suspicious": Color(0.95, 0.8, 0.3), &"alerted": Color(0.95, 0.35, 0.3), &"lines": Color(0.55, 0.78, 1.0)},
	true: {&"suspicious": Color(0.95, 0.9, 0.95), &"alerted": Color(0.95, 0.6, 0.1), &"lines": Color(0.45, 0.85, 0.95)},
}


func palette_color(key: StringName) -> Color:
	return PALETTES[colorblind][key]


func reset_for_test() -> void:
	flash_intensity = 1.0
	screen_shake = 1.0
	colorblind = false
