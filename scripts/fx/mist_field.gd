extends Node
## Autoload "MistField": the analytic flow of the mists. Attractors are
## Allomancers burning metal (the mists swirl toward them); repellers are
## spiked beings (the mists part around them). The mist shader mirrors these
## formulas on the GPU; the mistcloak samples wind_at() on the CPU.

## Attractor nodes expose mist_strength (0..1) and mist_phase (swirl angle).
var attractors: Array[Node2D] = []
var repellers: Array[Node2D] = []

const ATTRACT_RADIUS := 90.0
const SWIRL_SPEED := 40.0
const INWARD_SPEED := 18.0
const REPEL_SPEED := 30.0
## Lazy drift of the mists, in pixels per second.
const DRIFT := Vector2(7.0, 0.8)

var time := 0.0


func _physics_process(delta: float) -> void:
	time += delta


func add_attractor(node: Node2D) -> void:
	if not attractors.has(node):
		attractors.append(node)


func remove_attractor(node: Node2D) -> void:
	attractors.erase(node)


func add_repeller(node: Node2D) -> void:
	if not repellers.has(node):
		repellers.append(node)


func remove_repeller(node: Node2D) -> void:
	repellers.erase(node)


## The lazy drift plus slow gusts, without any attractor or repeller.
func base_wind(pos: Vector2) -> Vector2:
	var gust := sin(time * 0.7 + pos.x * 0.01) * 0.5 + sin(time * 0.31 + pos.y * 0.02) * 0.5
	return DRIFT * (1.0 + 0.6 * gust)


func wind_at(pos: Vector2) -> Vector2:
	var w := base_wind(pos)
	for a in attractors:
		if not is_instance_valid(a):
			continue
		var s: float = a.mist_strength
		if s <= 0.0:
			continue
		var d := pos - a.global_position
		var r := d.length()
		if r < 0.001:
			continue
		var f := s * exp(-r * r / (2.0 * ATTRACT_RADIUS * ATTRACT_RADIUS))
		var radial := d / r
		w += radial.orthogonal() * SWIRL_SPEED * f - radial * INWARD_SPEED * f
	for rp in repellers:
		if not is_instance_valid(rp):
			continue
		var d := pos - rp.global_position
		var r := d.length()
		var radius: float = rp.radius
		if r < 0.001 or r > radius * 1.5:
			continue
		w += d / r * REPEL_SPEED * (1.0 - r / (radius * 1.5))
	return w


## Multiplier on mist density from repellers: 0 at a spiked being, 1 clear of it.
func density_factor(pos: Vector2) -> float:
	var k := 1.0
	for rp in repellers:
		if not is_instance_valid(rp):
			continue
		var radius: float = rp.radius
		k *= smoothstep(radius * 0.5, radius, pos.distance_to(rp.global_position))
	return k


func reset_for_test() -> void:
	attractors.clear()
	repellers.clear()
