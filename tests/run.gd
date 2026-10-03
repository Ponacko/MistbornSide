extends SceneTree
## Headless test runner. Usage:
##   tools/test.sh                 # every tests/**/test_*.gd
##   tools/test.sh test_jump       # files whose name contains the filter

var _failed := 0
var _passed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]
	var files := _find("res://tests")
	files.sort()
	for path in files:
		if filter != "" and not path.get_file().contains(filter):
			continue
		await _run_file(path)
	print("\n%d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _find(dir_path: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	for sub in dir.get_directories():
		out.append_array(_find(dir_path.path_join(sub)))
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	return out


func _run_file(path: String) -> void:
	var script: GDScript = load(path)
	if script == null or not script.can_instantiate():
		_failed += 1
		print("FAIL %s: could not load" % path)
		return
	var methods: Array[String] = []
	for m in script.get_script_method_list():
		if m.name.begins_with("test_") and not methods.has(m.name):
			methods.append(m.name)
	for method in methods:
		var t: TestCase = script.new()
		t.tree = self
		await _reset_world()
		t.before_each()
		await t.call(method)
		t.after_each()
		t.free_nodes()
		if t.failures.is_empty():
			_passed += 1
			print("  ok   %s::%s" % [path.get_file(), method])
		else:
			_failed += 1
			print("  FAIL %s::%s" % [path.get_file(), method])
			for f in t.failures:
				print("         " + f)


## Puts autoload singletons back to a known state between tests.
func _reset_world() -> void:
	for child in root.get_children():
		if child.has_method("reset_for_test"):
			child.reset_for_test()
	await physics_frame
