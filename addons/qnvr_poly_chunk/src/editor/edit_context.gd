@tool
extends RefCounted

const Editable := preload("editable.gd")

var target: Editable
var undo_man: EditorUndoRedoManager


func initialise(p_target: Editable, p_undo_man: EditorUndoRedoManager) -> void:
	clear_target()
	target = p_target
	undo_man = p_undo_man


func clear_target() -> void:
	target = null


func has_target() -> bool:
	if is_instance_valid(target):
		var node := target.get_target_node()
		return is_instance_valid(node) && node.is_inside_tree() && node.visible
	return false


func is_vertex_valid(p_idx: int) -> bool:
	return has_target() && target.has_vertex(p_idx)


func do_append_vertex(p_pos: Vector2) -> void:
	assert(has_target())
	undo_man.create_action("Gon:append_vertex", 0, target.get_undo_context())
	undo_man.add_do_method(target, "append_vertex", p_pos)
	undo_man.add_undo_method(target, "remove_vertex", target.get_vertex_count())
	undo_man.commit_action()


func do_set_vertex_position(p_index: int, p_position: Vector2) -> void:
	assert(is_vertex_valid(p_index), "do_set_vertex: p_index out of bounds")
	undo_man.create_action("Gon:set_vertex(%d)" % [ p_index ], UndoRedo.MERGE_ENDS, target.get_undo_context())
	undo_man.add_do_method(target, "set_vertex_position", p_index, p_position)
	undo_man.add_undo_method(target, "set_vertex_position", p_index, target.get_vertex_position(p_index))
	undo_man.commit_action()


func do_insert_vertex_on_edge(p_segpos: float) -> int:
	var new_idx := ceili(p_segpos)
	undo_man.create_action("Gon:insert_vertex_on_edge", 0, target.get_undo_context())
	undo_man.add_do_method(target, "insert_vertex_on_edge", p_segpos)
	undo_man.add_undo_method(target, "remove_vertex", new_idx)
	undo_man.commit_action()
	return new_idx


func do_remove_vertex(p_index: int) -> void:
	assert(is_vertex_valid(p_index), "do_remove_vertex: p_index out of bounds")
	undo_man.create_action("Gon:remove_vertex", 0, target.get_undo_context())
	undo_man.add_do_method(target, "remove_vertex", p_index)
	undo_man.add_undo_method(target, "insert_vertex", p_index, target.get_vertex_position(p_index))
	undo_man.commit_action()
