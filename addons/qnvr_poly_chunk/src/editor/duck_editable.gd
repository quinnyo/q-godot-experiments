@tool
extends "editable.gd"

## A Node is DuckEditable if the following methods are implemented:
## func get_vertex_count() -> int:
## func get_vertex_position(p_idx: int) -> Vector2:
## func set_vertex_position(p_idx: int, p_pos: Vector2) -> void:
## func insert_vertex(p_idx: int, p_pos: Vector2) -> void:
## func remove_vertex(p_idx: int) -> void:


const DUCK_METHODS := [
	"get_vertex_count",
	"get_vertex_position",
	"set_vertex_position",
	"insert_vertex",
	"remove_vertex",
]

var target: Object
var target_node: Node2D


func _init(p_target: Object) -> void:
	@warning_ignore(static_called_on_instance)
	assert(looks_editable(p_target))
	target = p_target
	target_node = p_target as Node2D


func get_target_node() -> Node:
	return target as Node


func get_target_transform() -> Transform2D:
	if is_instance_valid(target_node) && target_node.is_inside_tree():
		return target_node.global_transform
	return Transform2D()


func get_vertex_count() -> int:
	@warning_ignore(unsafe_method_access)
	return target.get_vertex_count()


func get_vertex_position(p_idx: int) -> Vector2:
	@warning_ignore(unsafe_method_access)
	return target.get_vertex_position(p_idx)


func set_vertex_position(p_idx: int, p_pos: Vector2) -> void:
	@warning_ignore(unsafe_method_access)
	target.set_vertex_position(p_idx, p_pos)


func insert_vertex(p_idx: int, p_pos: Vector2) -> void:
	@warning_ignore(unsafe_method_access)
	target.insert_vertex(p_idx, p_pos)


func remove_vertex(p_idx: int) -> void:
	@warning_ignore(unsafe_method_access)
	target.remove_vertex(p_idx)


static func looks_editable(p_target: Object) -> bool:
	if not p_target is Node:
		return false
	for method in DUCK_METHODS:
		if !p_target.has_method(method):
			return false
	return true
