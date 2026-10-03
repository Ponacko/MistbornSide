class_name Tuning
extends Resource
## Every designer-facing value in the game. Lengths are in pixels unless the
## name says tiles; one tile is 16 pixels. The debug panel edits the live
## instance (Game.tuning) and saves presets as .tres files.

const TILE := 16.0

@export_group("Movement")
@export var run_speed := 140.0
@export var crouch_speed := 55.0
@export var ground_accel := 1500.0
@export var ground_decel := 1900.0
@export var air_accel := 950.0
@export var air_drag := 40.0
@export var jump_height_tiles := 3.25
@export var jump_time_to_apex := 0.36
@export var fall_gravity_mult := 1.5
@export var jump_cut := 0.5
@export var max_fall_speed := 560.0
@export var coyote_time := 0.1
@export var jump_buffer := 0.1
@export var apex_threshold := 45.0
@export var apex_gravity_mult := 0.5
@export var wall_slide_speed := 70.0
@export var wall_jump_speed := Vector2(170.0, 270.0)
@export var wall_jump_lock := 0.14


func jump_gravity() -> float:
	return JumpMath.gravity_for(jump_height_tiles * TILE, jump_time_to_apex)


func jump_speed() -> float:
	return JumpMath.launch_speed_for(jump_height_tiles * TILE, jump_time_to_apex)

@export_group("Push and Pull")
@export var vin_mass := 45.0
## Designer-facing force: a full held Push off a coin at Vin's feet carries
## her this many tiles up in push_reach_time seconds. The force constant is
## derived from these two values (DESIGN.md 5.4).
@export var push_reach_tiles := 7.0
@export var push_reach_time := 0.55
@export var flare_force := 1.6
## Gravity multiplier near the apex of a Push arc while the button is held.
@export var push_apex_gravity_mult := 0.7
## Damping (per second) on Vin's vertical speed while a near-vertical Push
## or Pull acts on her. Makes a held Push over an anchor settle into a hover;
## sideways launches are untouched, so momentum is kept.
@export var hover_damping := 4.0
## Fastest a Push can make a light dynamic source (a coin) travel.
@export var projectile_max_speed := 900.0
## Pulling to an anchor closer than this makes Vin cling to it.
@export var bracket_catch_distance := 14.0

@export_group("Lines and targeting")
## Range of the blue lines and of Push and Pull, in pixels (half a screen
## width); force falls smoothly to zero here.
@export var line_range := 320.0
## How close to the cursor a source must be to be picked by aim.
@export var aim_snap_radius := 48.0
## Cursor distance forgiven per tenfold of mass over a clip.
@export var aim_mass_weight := 4.0
## Steepest angle from straight down that the falling heuristic accepts.
@export var below_cone_degrees := 50.0


var _push_accel_key := ""
var _push_accel := 0.0


## Base acceleration a full Push gives Vin off an anchor at zero distance,
## derived from the reach height and time. F0 = push_accel() * vin_mass.
func push_accel() -> float:
	var key := str([push_reach_tiles, push_reach_time, line_range, jump_height_tiles, jump_time_to_apex,
		push_apex_gravity_mult, apex_threshold, hover_damping])
	if key != _push_accel_key:
		_push_accel_key = key
		_push_accel = ForceModel.derive_push_accel(self)
	return _push_accel
