@tool
## Polygon/points geometry resource thing.
class_name Gonagon
extends Resource


#@export var generate_normals: bool = true:
#	set(value):
#		if value != generate_normals:
#			generate_normals = value
#			_changed()

@export var v_position: PackedVector2Array:
	set(value):
		v_position = value.duplicate()
		_changed()

#@export var v_normal: PackedVector2Array:
#	set(value):
#		v_normal = value.duplicate()
#		_changed()

#@export var v_properties: Array[Dictionary]:
#	set(value):
#		v_properties = value.duplicate()
#		_changed()

#@export var vertex_groups: Array[Dictionary]


var v_normal: PackedVector2Array

var bounds: Rect2

var _winding_order: int

#func get_vertex_properties(p_idx: int) -> Dictionary:
#


#func get_vertex_property(p_key: Variant) -> Variant:
#


func get_vertex_count() -> int:
	return v_position.size()


func get_vertex_position(p_idx: int) -> Vector2:
	return v_position[wrapi(p_idx, 0, get_vertex_count())]


func set_vertex_position(p_idx: int, p_pos: Vector2) -> void:
	v_position[p_idx] = p_pos
	_changed()


func insert_vertex(idx: int, p_pos: Vector2) -> void:
	v_position.insert(idx, p_pos)
	_changed()


func remove_vertex(p_idx: int) -> void:
	v_position.remove_at(p_idx)
	_changed()


func notify_changed() -> void:
	_changed()


func get_winding_signum() -> float:
	return float(_winding_order)


func get_normal_signum() -> float:
	return float(-_winding_order)


func _changed() -> void:
	_update()
	emit_changed()


func _update() -> void:
	_winding_order = 0
	if get_vertex_count() > 2:
		_winding_order = 1 if Geometry2D.is_polygon_clockwise(v_position) else -1

	bounds = Rect2()
	if get_vertex_count() != 0:
		bounds = Rect2(get_vertex_position(0), Vector2())
		for i in range(get_vertex_count()):
			bounds = bounds.expand(get_vertex_position(i))

#	v_normal.resize(get_vertex_count())
#
#	if get_vertex_count() < 2:
#		return
#
#	for k in range(get_vertex_count()):
#		var a := get_vertex_position(k - 1)
#		var b := get_vertex_position(k)
#		var c := get_vertex_position(k + 1)
#
#		var ab := b - a
#		var uab := ab.orthogonal().normalized()
#		var bc := c - b
#		var ubc := bc.orthogonal().normalized()
#		var n := uab.slerp(ubc, 0.5)
#		v_normal[k] = n


