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
## A Push within this angle of straight down is a hover: its sideways part is
## scaled down and sideways speed damped, so balancing over an anchor is
## stable and steered with the move keys instead of flinging Vin off it.
@export var hover_cone_degrees := 30.0
## On the ground Vin braces against a sideways Push or Pull: this much of
## the acceleration is absorbed by her footing, so a shove sends the guard
## back and Vin only slides a little (pewter braces harder).
@export var brace_accel := 1500.0
@export var pewter_brace_mult := 1.6
@export var hover_lateral_mult := 0.3
## Fastest a Push can make a light dynamic source (a coin) travel.
@export var projectile_max_speed := 900.0
## Pulling to an anchor closer than this makes Vin cling to it.
@export var bracket_catch_distance := 20.0
## Gravity multiplier while Pulling on an anchor, so Vin flies a near-straight
## line to it instead of sagging under it.
@export var pull_gravity_mult := 0.4
## Damping (per second) of Vin's motion across the line while she Pulls on
## an anchor: a Pull to fixed metal flies like a zip line, not a pendulum.
@export var pull_line_damping := 6.0

@export_group("Steelsight and forgiveness")
@export var steelsight_time_scale := 0.15
## Real seconds the slow window stays open (mouse, then gamepad).
@export var steelsight_window := 0.25
@export var steelsight_window_gamepad := 0.4
@export var steelsight_ramp := 0.2
## A release during Steelsight still Pushes for this long.
@export var steelsight_tap_time := 0.12
@export var push_buffer_frames := 6
@export var arc_preview_time := 0.5
## Pixels Vin is nudged sideways past a ceiling corner, or up over a ledge lip.
@export var corner_correction := 6
@export var ledge_correction := 6

@export_group("Pewter and tin")
@export var pewter_speed := 1.4
@export var pewter_jump := 1.3
@export var pewter_damage := 0.5
@export var pewter_flare_speed := 1.9
@export var pewter_flare_jump := 1.45
@export var pewter_flare_damage := 0.25
@export var pewter_regen := 1.5
## Continuous pewter flare that ends in a crash, in seconds.
@export var crash_flare_seconds := 40.0
@export var crash_stagger := 2.0
@export var crash_slow_seconds := 10.0
@export var crash_slow_speed := 0.7
@export var light_hit_stagger := 0.35
@export var heavy_hit_stagger := 0.6
## How far Vin sees in the mists without tin; tin triples it.
@export var vision_radius := 260.0
@export var tin_flash_stun := 1.0
@export var tin_pulse_time := 0.6

@export_group("Combat")
@export var dagger_damage := 34.0
## Reach of a dagger strike from Vin's centre, in pixels.
@export var dagger_reach := 30.0
@export var dagger_swing_time := 0.22
@export var combo_window := 0.45
@export var dash_speed := 300.0
@export var dash_time := 0.22
@export var dash_damage := 50.0
@export var plunge_speed := 520.0
@export var plunge_damage := 100.0
## Hold the dagger this long with pewter on for the heavy strike.
@export var heavy_hold_time := 0.3
@export var heavy_damage := 70.0
@export var dodge_time := 0.35
@export var dodge_speed := 260.0
@export var dodge_iframes := 0.25
@export var dodge_cooldown := 0.4
@export var death_respawn_delay := 1.0
@export var guard_spear_damage := 34.0
@export var guard_reach := 28.0
@export var guard_windup := 0.4
@export var guard_cooldown := 0.9
@export var guard_contact_distance := 16.0
## Pull impulse a guard's grip withstands before the spear is torn away.
@export var guard_grip := 8000.0
## Landing faster than this kills a guard (a fall from a roof).
@export var fall_death_speed := 520.0

@export_group("Hazekillers and Inquisitors")
@export var hazekiller_staff_damage := 18.0
@export var hazekiller_reach := 34.0
@export var hazekiller_windup := 0.35
@export var hazekiller_cooldown := 1.2
## At most this many squad members strike at once.
@export var squad_attackers := 2
@export var bendal_speed := 165.0
## Bendal speeds up to this when he falls far behind, keeping the pressure on.
@export var bendal_catch_up_speed := 200.0
@export var bendal_catch_up_gap := 320.0
@export var bendal_axe_damage := 75.0
@export var bendal_reach := 34.0
@export var bendal_windup := 0.3
@export var bendal_second_swing := 0.25
## The gap in his attack pattern that atium reveals.
@export var bendal_recover := 0.9
@export var bendal_coin_return_range := 70.0

@export_group("Kredik Shaw")
## Speed multiplier while the Soothing weighs on Vin without copper.
@export var soothed_speed := 0.8

@export_group("Atium")
## Hold Tab this long to burn a bead (prevents waste).
@export var atium_confirm_time := 0.35
## Real seconds a bead burns.
@export var atium_duration := 8.0
## How far ahead enemy shadows show, in seconds.
@export var atium_lookahead := 1.2
@export var atium_time_scale := 0.9
@export var atium_dodge_scale := 2.5

@export_group("Stealth")
## Suspicion per second when Vin is in plain sight, close up.
@export var see_rate := 1.3
@export var suspicious_threshold := 0.35
@export var suspicion_decay := 0.15
## Seconds an alerted enemy keeps hunting after losing Vin.
@export var alert_memory := 6.0
@export var sight_range_lit := 280.0
@export var sight_range_dark := 40.0
## Guards do not look up past this angle unless alerted (rooftop advantage).
@export var look_up_degrees := 35.0
## Pixels a noise of loudness 1 carries.
@export var hearing_range := 300.0
@export var seeker_radius := 220.0
@export var seeker_rate := 0.9
@export var bronze_range := 450.0
@export var bronze_listen_time := 1.0
@export var bell_delay := 2.5
## Fall speed above which Vin's landing makes a noise.
@export var loud_landing_speed := 380.0

@export_group("Coins")
@export var coin_pouch_size := 30
@export var coin_flick_speed := 220.0
## A resting coin is an anchor for Pushes within this angle of the surface
## normal (Kelsier's centre-of-mass lesson); outside it the coin skids.
@export var anchor_cone_degrees := 35.0
## Share of an anchor's lift Vin gets when a Push outside the cone skids the coin.
@export var coin_partial_lift := 0.5
@export var coin_skid_speed := 160.0
## Push coyote time: a coin that left the ground this many frames ago still anchors.
@export var coin_coyote_frames := 5
## A bouncing coin slower than this, just above the ground, still anchors.
@export var coin_bounce_accept_speed := 60.0
@export var coin_lethal_speed := 320.0
@export var coin_spray_count := 5
@export var coin_spray_spread_degrees := 30.0
@export var coin_recall_speed := 520.0
@export var coin_recall_accel := 4000.0
@export var coin_max_active := 60
@export var coin_merge_radius := 7.0

@export_group("Lines and targeting")
## Range of the blue lines and of Push and Pull, in pixels (half a screen
## width); force falls smoothly to zero here.
@export var line_range := 320.0
## How close to the cursor a source must be to be picked by aim.
@export var aim_snap_radius := 48.0
## Cursor distance forgiven per tenfold of mass over a clip.
@export var aim_mass_weight := 4.0
@export var aim_cycle_radius := 96.0
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
