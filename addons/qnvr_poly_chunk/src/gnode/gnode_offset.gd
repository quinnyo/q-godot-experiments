@tool
## Inflates or deflates the gon by translating points along their normal.
extends GonNode2D

@export var offset: float = 8.0:
	set(value):
		if !is_equal_approx(value, offset):
			offset = value
			mark_dirty()


func _gon_build(gx: Gonagon) -> void:
	if gx.get_vertex_count() < 3:
		return

	_gmod_offset(gx)


func _gmod_offset(gx: Gonagon) -> void:
	var v_dir := PackedVector2Array()
	v_dir.resize(gx.get_vertex_count())

#	for i in range(gx.get_vertex_count()):
#		var a := gx.get_vertex_position(i)
#		var b := gx.get_vertex_position(i+1)
#		var d := (b-a).normalized()
#		var n := (b-a).orthogonal().normalized() * gx.get_normal_signum()
#		var b1 := b + n * offset

	if gx.v_normal.size() == gx.get_vertex_count():
		for i in range(gx.get_vertex_count()):
			var p := gx.get_vertex_position(i)
			gx.set_vertex_position(i, (p + gx.v_normal[i] * offset).round())
