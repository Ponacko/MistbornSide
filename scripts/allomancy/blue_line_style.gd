class_name BlueLineStyle
## How a blue line looks: thickness by mass, brightness by distance.

const COLOR := Color(0.55, 0.78, 1.0)
const MAX_ALPHA := 0.85
const WALL_DIM := 0.45
const MIN_WIDTH := 0.4
const MAX_WIDTH := 3.5


## A hair for a clip (0.01 kg), a cable for a gate.
static func width_for_mass(mass: float) -> float:
	return clampf(MIN_WIDTH + 0.55 * log(maxf(mass, 0.01) / 0.01) / log(10.0), MIN_WIDTH, MAX_WIDTH)


## Same curve as the force falloff, so a line's brightness tells the player
## how much a Push on it will do.
static func alpha(distance: float, line_range: float, through_wall: bool) -> float:
	var f := clampf(1.0 - pow(distance / line_range, 2.0), 0.0, 1.0)
	var a := MAX_ALPHA * f
	return a * WALL_DIM if through_wall else a
