extends Node
## Autoload "NoiseBus": every sound the stealth game cares about (DESIGN.md
## 6.4). Guards listen to it; tin draws its recent noises as rings.

signal noise(pos: Vector2, loudness: float, kind: Kind)

enum Kind { FOOTSTEP, VOICE, LANDING, FIGHT, BREAK, BELL, METAL }

## How long a ring stays visible, in seconds.
const RING_LIFE := 1.4
## Ring radius at full loudness when it fades out, in pixels.
const RING_RADIUS := 90.0

## Recent noises: {pos, loudness, kind, age}.
var recent: Array[Dictionary] = []


func emit(pos: Vector2, loudness: float, kind: Kind) -> void:
	recent.append({"pos": pos, "loudness": loudness, "kind": kind, "age": 0.0})
	noise.emit(pos, loudness, kind)


func _physics_process(delta: float) -> void:
	for n in recent:
		n.age += delta
	recent = recent.filter(func(n): return n.age < RING_LIFE)


func reset_for_test() -> void:
	recent.clear()
