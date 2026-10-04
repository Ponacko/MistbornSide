class_name DialogueRunner
extends RefCounted
## Plays a dialogue scene from data (data/dialogue/*.json): speakers, lines,
## and choice points where Vin may Soothe or Riot. A choice sets story flags;
## any line can carry "if" or "unless" a flag to change what is said later.
##
## Format: {"start": id, "nodes": {id: {"speaker", "portrait"?, "lines": [str
## or {"text", "if"?, "unless"?}], "prompt"?, "choices"?: [{"text", "kind",
## "set": {flag: value}, "next"}], "next"?}}}

var data := {}
var finished := true
var _node_id := ""
var _line := 0
var _lines: Array = []


func load_file(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return false
	data = parsed
	return true


func start(node_id := "") -> void:
	finished = false
	_goto(node_id if node_id != "" else str(data.get("start", "")))


## The current beat: {speaker, portrait, text, choices: [{text, kind}]}.
func current() -> Dictionary:
	if finished:
		return {}
	var node: Dictionary = data.nodes[_node_id]
	var out := {
		"speaker": node.get("speaker", ""),
		"portrait": node.get("portrait", str(node.get("speaker", "")).to_lower()),
		"text": "",
		"choices": [],
	}
	if _line < _lines.size():
		out.text = _lines[_line]
	elif node.has("choices"):
		out.text = node.get("prompt", "")
		for c in node.choices:
			out.choices.append({"text": c.text, "kind": c.get("kind", "")})
	return out


func advance() -> void:
	if finished:
		return
	var node: Dictionary = data.nodes[_node_id]
	if _line < _lines.size():
		_line += 1
		if _line < _lines.size() or node.has("choices"):
			return
	elif node.has("choices"):
		return
	_goto(str(node.get("next", "")) if node.get("next") != null else "")


func choose(index: int) -> void:
	var node: Dictionary = data.nodes[_node_id]
	if finished or not node.has("choices") or _line < _lines.size():
		return
	var c: Dictionary = node.choices[index]
	for flag in c.get("set", {}):
		StoryFlags.set_flag(flag, c.set[flag])
	_goto(str(c.get("next", "")) if c.get("next") != null else "")


func _goto(node_id: String) -> void:
	if node_id == "" or not data.nodes.has(node_id):
		finished = true
		return
	_node_id = node_id
	_line = 0
	_lines = []
	for l in data.nodes[node_id].get("lines", []):
		if l is String:
			_lines.append(l)
		elif _passes(l):
			_lines.append(l.text)
	if _lines.is_empty() and not data.nodes[node_id].has("choices"):
		_goto(str(data.nodes[node_id].get("next", "")) if data.nodes[node_id].get("next") != null else "")


func _passes(line: Dictionary) -> bool:
	if line.has("if") and not StoryFlags.get_flag(line["if"]):
		return false
	if line.has("unless") and StoryFlags.get_flag(line["unless"]):
		return false
	return true
