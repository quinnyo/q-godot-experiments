## Adapter interface for EditContext.
## Implement an adapter for any Gon-like object to allow it to be edited.
##
@tool
extends RefCounted


func get_target_node() -> Node:
	push_error(&"must implement")
	return null


func get_target_transform() -> Transform2D:
	push_error(&"must implement")
	return Transform2D()


func get_undo_context() -> Object:
	var target := get_target_node()
	if is_instance_valid(target) && target.is_inside_tree():
		return target
	return null


func get_vertex_count() -> int:
	push_error(&"must implement")
	return -1


func get_vertex_position(p_idx: int) -> Vector2:
	push_error(&"must implement")
	return Vector2()


func set_vertex_position(p_idx: int, p_pos: Vector2) -> void:
	push_error(&"must implement")
	return


func insert_vertex(p_idx: int, p_pos: Vector2) -> void:
	push_error(&"must implement")
	return


func remove_vertex(p_idx: int) -> void:
	push_error(&"must implement")
	return


func has_vertex(p_idx: int) -> bool:
	return p_idx < get_vertex_count() && p_idx >= 0


func append_vertex(p_pos: Vector2) -> void:
	insert_vertex(get_vertex_count(), p_pos)


## Divide an edge by inserting a vertex at $p_offset edge offset.
func insert_vertex_on_edge(p_offset: float) -> void:
	var idx := ceili(p_offset)
	var a := get_vertex_position(idx - 1)
	var b := get_vertex_position(idx)
	insert_vertex(idx, a.lerp(b, p_offset - floorf(p_offset)))


## Find the vertex nearest to $p_pos and return its index.
## Optionally only consider vertices within $p_radius.
## If no vertex is found, returns `-1`
func pick_vertex(p_pos: Vector2, p_radius: float = INF) -> int:
	var best_idx := -1
	var best_distsq := pow(p_radius, 2.0) if is_finite(p_radius) else INF
	for idx in range(get_vertex_count()):
		var distsq := p_pos.distance_squared_to(get_vertex_position(idx))
		if distsq < best_distsq:
			best_idx = idx
			best_distsq = distsq
	return best_idx


## Find the closest point on an edge nearest to $p_pos.
## Optionally only consider points within $p_radius.
## Returns null if no edge point is found.
func pick_edge(p_pos: Vector2, p_radius: float = INF) -> Dictionary:
	if get_vertex_count() < 2:
		return { "offset": -1.0 }

	var xf := get_target_transform().affine_inverse()
	var ploc := xf * p_pos

	var best_idx := -1
	var best_distsq := pow(p_radius, 2.0) if is_finite(p_radius) else INF
	var best_u := 0.0
	var best_pos := Vector2()
	var edge_idx = get_vertex_count() - 1
	for j in range(get_vertex_count()):
#		var seg := get_segment(idx)
#		var ab := seg[1] - seg[0]
#		var ap := p_pos - seg[0]
#		var u := ap.dot(ab) / ab.length_squared()
		var a := get_vertex_position(edge_idx)
		var b := get_vertex_position(j)
		var ab := b - a
		var ap := ploc - a
		var u := ap.dot(ab) / ab.length_squared()
		if u < 0.0 || u >= 1.0:
			continue
		var pos := a + ab * u
		var distsq := ploc.distance_squared_to(pos)
		if distsq < best_distsq:
			best_idx = edge_idx
			best_distsq = distsq
			best_u = u
			best_pos = pos

		edge_idx = j

	var offset := float(best_idx) + best_u
	var res := { "offset": offset }
	if offset > 0.0:
		res["position"] = get_target_transform() * best_pos
	return res
