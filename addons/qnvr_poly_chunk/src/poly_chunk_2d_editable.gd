@tool
extends "editor/editable.gd"

var target: PolyChunk2D


func get_target_node() -> Node:
	return target


func get_target_transform() -> Transform2D:
	return target.global_transform


func get_vertex_count() -> int:
	return target.get_points_count()


func get_vertex_position(p_idx: int) -> Vector2:
	return target.to_global(target.get_point(p_idx))


func set_vertex_position(p_idx: int, p_pos: Vector2) -> void:
	target.set_point(p_idx, target.to_local(p_pos))


func insert_vertex(p_idx: int, p_pos: Vector2) -> void:
	target.insert_point(p_idx, target.to_local(p_pos))


func remove_vertex(p_idx: int) -> void:
	target.remove_point(p_idx)


func pick_vertex(p_pos: Vector2, p_radius: float = INF) -> int:
	var xf := target.global_transform.affine_inverse()
	return target.pick_point(xf * p_pos, p_radius)


func pick_edge(p_pos: Vector2, p_radius: float = INF) -> Dictionary:
	var xf := target.global_transform.affine_inverse()
	var offset := target.pick_edge(xf * p_pos, p_radius)
	var res := { "offset": offset }
	if offset > 0.0:
		var pos := target.to_global(target.interpolate_polyline(offset))
		res["position"] = pos
	return res
