class_name TestCase
extends RefCounted
## Base class for tests run by tests/run.gd. Every method named test_* is a test;
## it may await (for example physics_frames) to drive scenes headlessly.

var tree: SceneTree
var failures: PackedStringArray = []
var _nodes: Array[Node] = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


## Adds a node under the root for the duration of the test; freed afterwards.
func add(node: Node) -> Node:
	tree.root.add_child(node)
	_nodes.append(node)
	return node


func free_nodes() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()


func physics_frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


func process_frames(count: int) -> void:
	for i in count:
		await tree.process_frame


func fail(message: String) -> void:
	failures.append(message)


func assert_true(condition: bool, message := "expected true") -> void:
	if not condition:
		fail(message)


func assert_false(condition: bool, message := "expected false") -> void:
	if condition:
		fail(message)


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if actual != expected:
		fail("%s expected %s, got %s" % [message, str(expected), str(actual)])


func assert_near(actual: float, expected: float, tolerance: float, message := "") -> void:
	if absf(actual - expected) > tolerance:
		fail("%s expected %s +/- %s, got %s" % [message, expected, tolerance, actual])


func assert_gt(actual: float, bound: float, message := "") -> void:
	if not actual > bound:
		fail("%s expected > %s, got %s" % [message, bound, actual])


func assert_lt(actual: float, bound: float, message := "") -> void:
	if not actual < bound:
		fail("%s expected < %s, got %s" % [message, bound, actual])
