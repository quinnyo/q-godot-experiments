@tool
class_name IzmoGizmo
extends Node2D


signal redraw()
signal edit_begin(handle_id: Variant)
signal edit_update(handle_id: Variant, pos: Vector2)
signal edit_end(handle_id: Variant, restore: Variant, cancel: bool)
#signal handle_pointer_event(handle_id: Variant, entered: bool)

## gui_input captured by the input sink (unhandled by interactive elements / handles).
signal sink_input(event: InputEvent)


const Handle := preload("gizmo/handle.gd")
const HandleDefault := preload("gizmo/handle.tscn")


class Edit:
	enum State { BEGIN, ONGOING, APPLY, CANCEL }
	var handle_id: Variant
	var restore: Variant
	var state := State.BEGIN
	var _handle: Handle

	func get_handle_position() -> Vector2:
		return _handle.position

	func is_cancelled() -> bool:
		return state == State.CANCEL


var _target: Node
var _handles: Dictionary
var _edits: Dictionary
var _groups: Dictionary
var _plugin: EditorPlugin

var _elements: Node2D
var _default_group: Node2D

## mouse rect captures input that handles did not.
var _mouse_rect: Control
## debug cursor
#var _ptr_sink: Node2D


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_mouse_rect = ReferenceRect.new()
			_mouse_rect.border_color = Color(0.9,0.8,0.1,0.25)
			_mouse_rect.border_width = 1.1
			_mouse_rect.focus_mode = Control.FOCUS_NONE
			_mouse_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			_mouse_rect.mouse_filter = Control.MOUSE_FILTER_STOP
			_mouse_rect.gui_input.connect(_on_mouse_rect_gui_input)
			_mouse_rect.mouse_entered.connect(_on_mouse_rect_mouse_entered)
			_mouse_rect.mouse_exited.connect(_on_mouse_rect_mouse_exited)
			add_child(_mouse_rect)

			_elements = Node2D.new()
			_elements.name = "elements"
			add_child(_elements)

#			_ptr_sink = Node2D.new()
#			add_child(_ptr_sink)
#			var marker := Marker2D.new()
#			marker.gizmo_extents = 50.0
#			_ptr_sink.add_child(marker)
#		NOTIFICATION_EXIT_TREE:
#			clear()
		NOTIFICATION_DRAW:
			var radius := 50.0
			draw_arc(Vector2.ZERO, radius / 2.0, 0.0, TAU, 5, Color(0.1,0.0,0.1), 2.2, true)
			draw_arc(Vector2.ZERO, radius / 2.0, 0.0, TAU, 5, Color(0.95,0.9,0), 1.1, true)


func _process(_delta: float) -> void:
	var xf := _get_target_to_gizmo_xf()
	position = xf.origin
	set_group_transform(null, Transform2D(xf.x, xf.y, Vector2.ZERO))

	var bounds := _calc_bounding_rect().grow(100)
	set_input_sink_rect(bounds)


func _input(event: InputEvent) -> void:
#	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
#		prints("_input:", event.as_text(), event.is_pressed())
	pass


func target_to_gizmo(p: Vector2) -> Vector2:
	return _get_target_to_gizmo_xf() * p


func gizmo_to_target(p: Vector2) -> Vector2:
	return _get_target_to_gizmo_xf().affine_inverse() * p


func add_group(group_id: Variant) -> void:
	assert(!_groups.has(group_id), "group '%s' already exists" % group_id)
	var node := Node2D.new()
	node.name = "group%s" % group_id
	_groups[group_id] = node
	_elements.add_child(node)


func add_handle(id: Variant, pos: Vector2, group_id: Variant = null) -> void:
	assert(id != null)
	assert(!_handles.has(id), "handle '%s' already exists" % id)
	var handle := HandleDefault.instantiate() as Handle
	handle.position = pos
	handle.drag_begin.connect(_on_handle_drag_begin.bind(id))
	handle.drag_update.connect(_on_handle_drag_update.bind(id))
	handle.drag_end.connect(_on_handle_drag_end.bind(id))
	_handles[id] = handle
	add_handle_to_group(id, group_id)


func add_handle_to_group(handle_id: Variant, group_id: Variant) -> void:
	assert(handle_id != null && _handles.has(handle_id))
	var handle := _get_handle(handle_id)
	if handle.is_inside_tree():
		handle.get_parent().remove_child(handle)
	var group := _get_group_node(group_id)
	group.add_child(handle)


func set_handle_position(id: Variant, pos: Vector2) -> void:
	assert(_handles.has(id))
	var handle := _handles.get(id) as Handle
	handle.position = pos


func set_group_transform(group_id: Variant, xf: Transform2D) -> void:
	var group := _get_group_node(group_id)
	group.transform = xf


func set_restore_value(id: Variant, restore: Variant) -> void:
	var edit := _edits.get(id) as Edit
	edit.restore = restore


func clear() -> void:
	for child in _elements.get_children():
		child.queue_free()

	_handles.clear()
	_groups.clear()
	_edits.clear()

	queue_redraw()


func set_input_sink_rect(rect: Rect2) -> void:
	_mouse_rect.set_begin(rect.position)
	_mouse_rect.set_end(rect.end)


func get_target_node() -> Node:
	assert(_target, "gizmo not initialised correctly")
	return _target


func get_undo_redo() -> EditorUndoRedoManager:
	assert(_plugin, "gizmo not initialised correctly")
	return _plugin.get_undo_redo()


func _calc_bounding_rect() -> Rect2:
	var bounds := Rect2()
	var first := true
	for v in _handles.values():
		var handle := v as Handle
		var xf := (handle as Node2D).get_relative_transform_to_parent(self)
		if first:
			bounds = Rect2(xf.origin, Vector2.ZERO)
			first = false
		else:
			bounds = bounds.expand(xf.origin)
	return bounds


func _get_target_to_gizmo_xf() -> Transform2D:
	var xf := get_target_node().get_viewport().global_canvas_transform
	var target_2d := get_target_node() as Node2D
	if target_2d:
		var target_xf := target_2d.get_global_transform_with_canvas()
#		target_xf = Transform2D(target_xf.get_rotation(), target_xf.get_origin())
#		target_xf = Transform2D(0.0, target_xf.get_origin())
		return xf * target_xf
	return xf


func _get_group_node(group_id: Variant) -> Node2D:
	if group_id == null:
		if !is_instance_valid(_default_group) || _default_group.is_queued_for_deletion():
			_default_group = Node2D.new()
			_default_group.name = "default_group"
			_elements.add_child(_default_group)
		return _default_group
	else:
		assert(_groups.has(group_id))
		return _groups.get(group_id)


func _get_handle(handle_id: Variant) -> Handle:
	return _handles.get(handle_id) as Handle


func _redraw() -> void:
	redraw.emit()
	queue_redraw()


func _edit_begin(edit: Edit) -> void:
	edit_begin.emit(edit.handle_id)


func _edit_update(edit: Edit) -> void:
	edit_update.emit(edit.handle_id, edit.get_handle_position())


func _edit_end(edit: Edit) -> void:
	edit_end.emit(edit.handle_id, edit.restore, edit.is_cancelled())


func _sink_input(event: InputEvent) -> void:
	sink_input.emit(event)

#	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
#		prints("_sink_input:", event.as_text(), event.is_pressed())

#	if !get_viewport().is_input_handled():
#		if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
#			_plugin.get_editor_interface().get_selection().clear()
##			get_viewport().set_input_as_handled()


func _on_handle_drag_begin(id: Variant) -> void:
	var edit := Edit.new()
	edit.handle_id = id
	edit._handle = _handles[id]
	_edits[id] = edit
	_edit_begin(edit)


func _on_handle_drag_update(_pos: Vector2, id: Variant) -> void:
	var edit := _edits.get(id) as Edit
	edit.state = Edit.State.ONGOING
	_edit_update(edit)


func _on_handle_drag_end(cancel: bool, id: Variant) -> void:
	var edit := _edits.get(id) as Edit
	edit.state = Edit.State.CANCEL if cancel else Edit.State.APPLY
	_edit_end(edit)
	_edits.erase(id)

	_redraw()


func _on_mouse_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_sink_input(event)


func _on_mouse_rect_mouse_exited() -> void:
#	_ptr_sink.rotation = PI / 4.0
	pass


func _on_mouse_rect_mouse_entered() -> void:
#	_ptr_sink.rotation = 0.0
	pass
