extends Node
## Autoload "MetalRegistry": every MetalSource in the world, bucketed in a
## spatial grid so range queries touch only nearby cells. The grid is rebuilt
## at most once per physics frame, on the first query, so moving metal (coins,
## carried armour) is always current without per-move bookkeeping.

const CELL := 128.0

var _sources: Array[MetalSource] = []
var _grid := {}
var _built_frame := -1


func register(source: MetalSource) -> void:
	if not _sources.has(source):
		_sources.append(source)
	_built_frame = -1


func unregister(source: MetalSource) -> void:
	_sources.erase(source)
	_built_frame = -1


func all() -> Array[MetalSource]:
	return _sources


func count() -> int:
	return _sources.size()


func query(center: Vector2, radius: float) -> Array[MetalSource]:
	_ensure_grid()
	var out: Array[MetalSource] = []
	var r2 := radius * radius
	var lo := _cell(center - Vector2(radius, radius))
	var hi := _cell(center + Vector2(radius, radius))
	for cx in range(lo.x, hi.x + 1):
		for cy in range(lo.y, hi.y + 1):
			var bucket: Array = _grid.get(Vector2i(cx, cy), [])
			for s: MetalSource in bucket:
				if s.global_position.distance_squared_to(center) <= r2:
					out.append(s)
	return out


func _ensure_grid() -> void:
	var frame := Engine.get_physics_frames()
	if frame == _built_frame:
		return
	_built_frame = frame
	_grid.clear()
	for s in _sources:
		var key := _cell(s.global_position)
		if not _grid.has(key):
			_grid[key] = []
		_grid[key].append(s)


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))


func reset_for_test() -> void:
	_built_frame = -1
