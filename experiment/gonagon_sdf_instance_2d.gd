@tool
## Adds a Gonagon to the scene. Draws gon with SDF thing...
#class_name GonagonInstance2D
extends Node2D

const GON_SIZE := 32

@export var border: float = 32.0

@export var gon: Gonagon:
	set(value):
		if gon != value:
			if is_instance_valid(gon) && gon.changed.is_connected(mark_dirty):
				gon.changed.disconnect(mark_dirty)
			gon = value
			if is_instance_valid(gon):
				gon.changed.connect(mark_dirty)


var _dirty := true
var _gon_bounds: Rect2
var _polygon: PackedVector2Array


func _physics_process(_delta: float) -> void:
	if _dirty:
		_update()


func _draw() -> void:
	draw_rect(_gon_bounds.grow(border), Color.WHITE)

#	if gon.v_normal.size() == get_vertex_count():
#		var points := gon.v_position.duplicate()
#		for i in range(get_vertex_count()):
#			points[i] += -gon.v_normal[i] * border
#		draw_colored_polygon(points, Color.WHITE)


#	var indices := Geometry2D.triangulate_polygon(v_position)
#	for i in range(get_vertex_count()):
#		var pos := get_vertex_position(i)
#		var prec := get_vertex_position(wrapi(i - 1, 0, get_vertex_count()))
#		var succ := get_vertex_position(wrapi(i + 1, 0, get_vertex_count()))
#		draw_line(pos, succ, Color.WHITE, 2.0)

#	if Engine.is_editor_hint():
#		_draw_editor()


func get_vertex_count() -> int:
	return gon.get_vertex_count() if is_instance_valid(gon) else 0


func get_vertex_position(p_idx: int) -> Vector2:
	return gon.get_vertex_position(p_idx)


func set_vertex_position(p_idx: int, p_pos: Vector2) -> void:
	gon.set_vertex_position(p_idx, p_pos)


func insert_vertex(p_idx: int, p_pos: Vector2) -> void:
	assert(p_idx < GON_SIZE)

	if !is_instance_valid(gon):
		gon = Gonagon.new()
	gon.insert_vertex(p_idx, p_pos)


func remove_vertex(p_idx: int) -> void:
	gon.remove_vertex(p_idx)


func mark_dirty() -> void:
	_dirty = true
	if Engine.is_editor_hint():
		_update()


func _update() -> void:
	_gon_bounds = gon.bounds
#	_gon_bounds = Rect2()
	if get_vertex_count() > 0:
#		_gon_bounds = Rect2(get_vertex_position(0), Vector2())
		_polygon.resize(GON_SIZE)
		_polygon.fill(get_vertex_position(0))
		for i in range(get_vertex_count()):
#			_gon_bounds = _gon_bounds.expand(get_vertex_position(i))
			_polygon[i] = get_vertex_position(i)

	var shmat := material as ShaderMaterial
	if shmat:
#		var polygon := gon.v_position.duplicate()
#		polygon.resize(128)
		shmat.set_shader_parameter("polygon", _polygon)

	queue_redraw()
	_dirty = false


func _draw_editor() -> void:
	var vert_size := Vector2.ONE * 6.0
	for i in range(get_vertex_count()):
		var pos := get_vertex_position(i)
		draw_rect(Rect2(pos - vert_size / 2.0, vert_size), Color.GRAY)


	draw_rect(_gon_bounds, Color(0.0, 1.0, 1.0, 0.5), false, 1.0)

