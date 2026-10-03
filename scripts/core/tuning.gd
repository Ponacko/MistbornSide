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

@export_group("Lines and targeting")
## Range of the blue lines and of Push and Pull, in pixels (about a screen).
@export var line_range := 420.0
## How close to the cursor a source must be to be picked by aim.
@export var aim_snap_radius := 48.0
## Cursor distance forgiven per tenfold of mass over a clip.
@export var aim_mass_weight := 4.0
## Steepest angle from straight down that the falling heuristic accepts.
@export var below_cone_degrees := 50.0
