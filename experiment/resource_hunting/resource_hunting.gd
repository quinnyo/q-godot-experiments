## detecting files/resources (scripts, particularly)
## for e.g. editor plugin to load automatically
## mainly for autogizmo thing, but would generalise.
## Matches file name, (Resource) extension
@tool
extends EditorScript

var _script_extensions: PackedStringArray
# get_recognized_extensions_for_type does include '[t]res' for Script, but we will skip them
var _exclude_extensions := PackedStringArray([ "tres", "res" ])


func _run() -> void:
	_script_extensions = ResourceLoader.get_recognized_extensions_for_type("Script")

	print()
	print(_filter_files("res://", _is_autogizmo_filename))
#	scan_dir("res://", func(path: String):
#		if _is_autogizmo_filename(path):
#			print(path)
#	)

#	for file in [
#		"res://experiment/resource_hunting/resource_hunting.gd",
#		"res://experiment/resource_hunting/empty.autogizmo.gd",
#		"res://experiment/resource_hunting/also_empty.autogizmo.tres",
##		"res://experiment/resource_hunting/new_curve.autogizmo.tres",
#		"res://icon.svg",
#		"test.autogizmo.gd",
#		"trick.autogizmo.bonk.gd",
#	]:
#		_test(file)


#func _test(file: String) -> void:
#	var script_extensions := ResourceLoader.get_recognized_extensions_for_type("Script")
#	var exclude_extensions := PackedStringArray([ "tres", "res" ])
#	var extok := !exclude_extensions.has(file.get_extension()) && script_extensions.has(file.get_extension())
#
#	var name_tagged := file.get_file().get_basename().match("*.autogizmo")
#	var exists := ResourceLoader.exists(file) # NOTE: type_hint doesn't seem to do anything (2022-12-14)
#
#	var asdf := []
#	if name_tagged:
#		asdf.push_back("name_tagged")
#	if extok:
#		asdf.push_back("extok")
#	if exists:
#		asdf.push_back("exists")
#
#	print(file.right(27).lpad(30, ".") if file.length() > 30 else file.lpad(30), ": ", " ".join(asdf))


func _is_autogizmo_filename(file: String) -> bool:
	var fext := file.get_extension()
	var fbase := file.get_file().get_basename()

	var ext_ok := !_exclude_extensions.has(fext) && _script_extensions.has(fext)
	var tagged := fbase.match("*.autogizmo")
	# NOTE: 2022-12-14, type_hint doesn't seem to do anything
	var exists := ResourceLoader.exists(file)

	return ext_ok && tagged && exists


func _filter_files(search_dir: String, f: Callable) -> PackedStringArray:
	var found := PackedStringArray()
	var da := DirAccess.open(search_dir)
	if not da:
		push_error("failed to open '%s': '%s'" % [ search_dir, DirAccess.get_open_error() ])
		return PackedStringArray()
	da.include_hidden = true
	var cwd := da.get_current_dir()
	for name in da.get_directories():
		found.append_array(_filter_files(cwd.path_join(name), f))
	for name in da.get_files():
		var path := cwd.path_join(name)
		if f.call(path):
			found.push_back(path)
	return found


func scan_dir(path: String, f: Callable, depth: int = 0) -> void:
	var da := DirAccess.open(path)
	if not da:
		push_error("failed to open '%s': '%s'" % [ path, DirAccess.get_open_error() ])
		return
	da.include_hidden = true
	var cwd := da.get_current_dir()
#	if depth == 0:
#		print(cwd, "/")
	var dirs := da.get_directories()
	var files := da.get_files()
	for name in dirs:
#		print("\t".repeat(depth+1), name, "/")
		scan_dir(cwd.path_join(name), f, depth + 1)
	for name in files:
#		print("\t".repeat(depth+1), name)
		f.call(cwd.path_join(name))
