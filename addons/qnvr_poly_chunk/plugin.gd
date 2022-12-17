@tool
extends EditorPlugin

const Editor := preload("src/editor/editor.gd")
const DuckEditable := preload("src/editor/duck_editable.gd")

var gizmo_size := 8.0
var gizmo_picking_margin := 1.5

var visible := false
var editor: Editor = Editor.new()


func _redraw_overlays() -> void:
	var _i := update_overlays()


func _clear_edit_context() -> void:
	editor.clear_edit_context()
	_redraw_overlays()


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if !editor.has_editable():
		return false

	editor.update()
	_redraw_overlays()

	if event is InputEventKey:
		var kev := event as InputEventKey
		if kev.keycode == KEY_SHIFT:
			_redraw_overlays()
			return false

	if event is InputEventMouseButton:
		var mbev := event as InputEventMouseButton
		match mbev.button_index:
			MOUSE_BUTTON_LEFT:
				return editor.primary_tool_input(mbev.pressed, Input.is_key_pressed(KEY_SHIFT), Input.is_key_pressed(KEY_CTRL))
			MOUSE_BUTTON_RIGHT:
				return editor.secondary_tool_input(mbev.pressed)

	return false


func _forward_canvas_draw_over_viewport(overlay: Control):
	if !editor.has_editable():
		return

	editor.draw(overlay)


func _handles(object: Variant) -> bool:
	return DuckEditable.looks_editable(object)


func _make_visible(p_visible: bool) -> void:
	visible = p_visible
	if !visible:
		_clear_edit_context()

	_redraw_overlays()


func _edit(object: Variant) -> void:
	if DuckEditable.looks_editable(object):
		var editable := DuckEditable.new(object)
		editor.initialise_edit_context(self, editable)

	_redraw_overlays()


func _clear() -> void:
	_clear_edit_context()


func _enable_plugin() -> void:
	set_input_event_forwarding_always_enabled()


func _get_plugin_icon() -> Texture2D:
	return preload("icon/plugin.svg")


#func _selectables_find_recursive(root: Node) -> Array:
#	var found: Array = []
#	_walk_tree(root, func(node: Node) -> bool:
#		if node is PolyChunk2D:
#			found.push_back(node as PolyChunk2D)
#		return true
#		)
#	return found
#
#
#func _walk_tree(root: Node, f: Callable) -> void:
#	if f.call(root):
#		for child in root.get_children():
#			_walk_tree(child, f)
