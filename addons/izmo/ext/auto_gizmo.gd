@tool
extends "../extension.gd"

##
## Auto Gizmo Loader Extension
##
## Built-in IzmoExtension to discover and load 'AutoGizmos'.
##
## Gizmo scripts that [...] are detected and activated automatically, by the built-in AutoGizmoLoader extension.
## - res:// is searched recursively for autogizmo scripts
## - file basename must match '*.autogizmo'
## - file extension must be a recognised Script extension
##   - 'tres' and 'res' are excluded by default
## - must be a tool script
## - must inherit from IzmoGizmo
## - must impl `static func _auto_gizmo_is_target(target: Node) -> bool`:
##   - return true if gizmo should be activated for editing the target node.
##


var _autogizmos: Array[Script]

var _selected: Array[Script]
var _selected_for_target: Node

var _script_extensions: PackedStringArray
var _exclude_extensions := PackedStringArray([ "tres", "res" ])

## failed to load or be autogizmo scripts. { <path>: <modified_time> }
var _failed := {}


func has_gizmo(target: Node) -> bool:
	_load_autogizmos()
	_selected_for_target = target
	_selected = _autogizmos.filter(func(script): return script._auto_gizmo_is_target(target))
	return _selected.size() > 0


func create_gizmo(target: Node) -> IzmoGizmo:
	if _selected_for_target == target:
		for script in _selected:
			var gizmo := script.new() as IzmoGizmo
			gizmo._target = target
			return gizmo
	return null


func _enter_tree() -> void:
	_load_autogizmos()
	print("AutoGizmo: loaded %d scripts" % _autogizmos.size())


func _load_autogizmos() -> void:
	_autogizmos.clear()
	_script_extensions = ResourceLoader.get_recognized_extensions_for_type("Script")
	var failed := []
	var found := _filter_files("res://", _is_autogizmo_filename)
	for file in found:
		if _failed.has(file) && _failed[file] == FileAccess.get_modified_time(file):
			continue # failed last time & hasn't changed, skip.
		_failed.erase(file)
		var script := ResourceLoader.load(file, "Script", ResourceLoader.CACHE_MODE_REPLACE) as Script
		if _is_script_autogizmo(script):
			_autogizmos.push_back(script)
		else:
			_failed[file] = FileAccess.get_modified_time(file)
			failed.push_back(file)

	if failed.size():
		print("AutoGizmo: %d failed to load: %s" % [ failed.size(), failed ])


func _is_autogizmo_filename(file: String) -> bool:
	var fext := file.get_extension()
	var ext_ok := !_exclude_extensions.has(fext) && _script_extensions.has(fext)
	var tagged := file.get_basename().match("*.autogizmo")
	# NOTE: 2022-12-14, type_hint doesn't seem to do anything
	var exists := ResourceLoader.exists(file)

	return ext_ok && tagged && exists


func _is_script_autogizmo(script: Script) -> bool:
	if !(is_instance_valid(script) && script.can_instantiate() && script.is_tool()):
		return false

	# find ultimate base script
	var base := script
	while base.get_base_script():
		base = base.get_base_script()
	if base != IzmoGizmo:
		return false

	var has_is_target_fn := false
	for m in script.get_script_method_list():
		if m.get("name") == "_auto_gizmo_is_target":
			if m.get("flags", 0) & METHOD_FLAG_STATIC == 0:
				break
			if m.get("return", {}).get("type") != TYPE_BOOL:
				break
			var args = m.get("args", [])
			if args.size() != 1 || args[0].get("class_name") != "Node":
				break
			has_is_target_fn = true
			break

	return has_is_target_fn


func _filter_files(search_dir: String, f: Callable) -> PackedStringArray:
	var found := PackedStringArray()
	var da := DirAccess.open(search_dir)
	if not da:
		push_error("failed to open '%s': '%s'" % [ search_dir, DirAccess.get_open_error() ])
		return PackedStringArray()
	da.list_dir_begin()
	var name := da.get_next()
	while name != "":
		var path := search_dir.path_join(name)
		if da.current_is_dir():
			found.append_array(_filter_files(path, f))
		elif f.call(path):
			found.push_back(path)
		name = da.get_next()
	return found
