@tool
class_name GonGonNode2D
extends GonNode2D


@export var gon: Gonagon:
	set(value):
		if gon != value:
			if is_instance_valid(gon) && gon.changed.is_connected(mark_dirty):
				gon.changed.disconnect(mark_dirty)
			gon = value
			if is_instance_valid(gon):
				var err := gon.changed.connect(mark_dirty)
				if err != OK:
					push_error("could not connect signal (%s)" % [ err ])


func get_vertex_count() -> int:
	return gon.get_vertex_count() if is_instance_valid(gon) else 0


func get_vertex_position(p_idx: int) -> Vector2:
	return gon.get_vertex_position(p_idx)


func set_vertex_position(p_idx: int, p_pos: Vector2) -> void:
	gon.set_vertex_position(p_idx, p_pos)


func insert_vertex(p_idx: int, p_pos: Vector2) -> void:
	if !is_instance_valid(gon):
		gon = Gonagon.new()
	gon.insert_vertex(p_idx, p_pos)


func remove_vertex(p_idx: int) -> void:
	gon.remove_vertex(p_idx)


func _gon_build(gx: Gonagon) -> void:
	if is_instance_valid(gon):
		gx.v_position = gon.v_position.duplicate()
