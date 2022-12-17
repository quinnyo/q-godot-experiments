@tool
#class_name Izmo
extends EditorPlugin

var _extensions: Array[IzmoExtension]
var _gizmos: Array[IzmoGizmo]


func _enter_tree() -> void:
	add_tool_menu_item("izmo:reload_extensions", _reload_extensions)
	_reload_extensions()
	get_undo_redo().version_changed.connect(_on_unre_version_changed)


func _exit_tree() -> void:
	remove_tool_menu_item("izmo:reload_extensions")


func _handles(object: Variant) -> bool:
	var node := object as Node
	return node && _extensions.any(func(ext: IzmoExtension) -> bool: return ext.has_gizmo(node))


func _edit(object: Variant) -> void:
	_clear_gizmos()
	var node := object as Node
	for ext in _extensions:
		if ext.has_gizmo(node):
			var gizmo := ext.create_gizmo(node)
			gizmo._plugin = self
			_gizmos.push_back(gizmo)
#			add_child(gizmo)
#			gizmo._redraw()
			update_overlays()


func _make_visible(visible: bool) -> void:
	if !visible:
		_clear_gizmos()


func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	for gizmo in _gizmos:
		if !gizmo.is_inside_tree():
			overlay.add_child(gizmo)
			gizmo._redraw()


func add_extension(ext: IzmoExtension) -> void:
	_extensions.push_back(ext)
	ext._izmo = self
	add_child(ext)


func _reload_extensions() -> void:
	_clear_gizmos()
	_clear_extensions()
	for filename in _discover_extension_scripts():
		if !_load_extension_script(filename):
			push_error("izmo: could not load extension script '%s'" % [ filename ])

	print("izmo: loaded %d extensions" % [ _extensions.size() ])


func _clear_gizmos() -> void:
	for giz in _gizmos:
		giz.queue_free()
	_gizmos.clear()


func _clear_extensions() -> void:
	for ext in _extensions:
#		ext._izmo_exit()
		ext.queue_free()
	_extensions.clear()


func _discover_extension_scripts() -> Array[String]:
	return [
		"res://addons/izmo/ext/auto_gizmo.gd",
#		"res://addons/izmo/example/test_izmo.gd",
#		"res://addons/izmo/example/redundant_polygon_gizmo.gd"
	]


func _load_extension_script(filename: String) -> bool:
	var script := load(filename) as Script

	if !is_instance_valid(script):
		return false
	elif !script.can_instantiate():
		return false
	elif !script.is_tool():
		return false

	var base := script # find ultimate base script
	while base.get_base_script():
		base = base.get_base_script()
	if base != IzmoExtension:
		return false

	@warning_ignore(unsafe_method_access)
	add_extension(script.new())
	return true


func _on_unre_version_changed() -> void:
#	update_overlays()
	for gizmo in _gizmos:
		gizmo._redraw()
