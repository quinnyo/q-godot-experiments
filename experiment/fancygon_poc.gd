@tool
extends Polygon2D

var rebuild_triggers := [
	NOTIFICATION_PARENTED,
	NOTIFICATION_MOVED_IN_PARENT,
	NOTIFICATION_ENTER_TREE,
	NOTIFICATION_LOCAL_TRANSFORM_CHANGED,
	NOTIFICATION_VISIBILITY_CHANGED,
]

var _dirty := true

var _msdf_thing := false

func _ready() -> void:
	set_notify_local_transform(true)


func _process(_delta: float) -> void:
	if _dirty:
		build()
		_dirty = false


func _notification(what: int) -> void:
	if rebuild_triggers.has(what):
		mark_dirty()


func _draw() -> void:
	for point in polygon:
		draw_circle(point, 8, color.inverted())

	#####
	## triangulate and mark the exterior edges somehowe
	var hulls := Geometry2D.decompose_polygon_in_convex(polygon)
	for hull in hulls:
		var c := Vector2()
		for p in hull:
			c = c * 0.5 + p * 0.5
		var xf := Transform2D(0.0, -Vector2(c)).scaled(Vector2.ONE * 0.9).translated(c)
		draw_colored_polygon(xf * hull, Color.DARK_GRAY)
		_draw_wires_indexed(hull, Geometry2D.triangulate_polygon(hull), Color.MAGENTA)

#	var delaunay := Geometry2D.triangulate_delaunay(polygon)
#	var triangled := Geometry2D.triangulate_polygon(polygon)
#	_draw_wires_indexed(polygon, Geometry2D.triangulate_polygon(polygon), color.inverted())


func mark_dirty() -> void:
	_dirty = true


func build() -> void:
	var RS := RenderingServer
	var item := get_canvas_item()
#	if !_msdf_thing:
#		_msdf_thing = true
#
#	RS.canvas_item_clear(item)
#	RS.canvas_item_add_msdf_texture_rect_region(item, Rect2(Vector2(), Vector2(500,500)), preload("res://msdf_gradient.tres"), Rect2(Vector2.ZERO, Vector2.ONE), Color.WHITE)
	print("[%s] built '%s'" % [ Time.get_datetime_string_from_system(), get_tree().edited_scene_root.get_path_to(self) if Engine.is_editor_hint() else get_path() ])

	queue_redraw()



func _draw_wires_indexed(p_vertices: PackedVector2Array, p_indices: PackedInt32Array, p_color: Color) -> void:
	var i := 0
	while i < p_indices.size():
		var p0 := p_vertices[i]
		var p1 := p_vertices[i+1]
		var p2 := p_vertices[i+2]
		var a := (p0 + p1 + p2) / 3.0
#		RS.canvas_item_add_line(item, a, p0, p_color)
#		RS.canvas_item_add_line(item, a, p1, p_color)
#		RS.canvas_item_add_line(item, a, p2, p_color)
		draw_line(a.lerp(p0, 0.5), a.lerp(p1, 0.5), p_color, 2.0,true)
		draw_line(a.lerp(p1, 0.5), a.lerp(p2, 0.5), p_color, 2.0,true)
		draw_line(a.lerp(p2, 0.5), a.lerp(p0, 0.5), p_color, 2.0,true)
		draw_polyline([ p0, p1, p2, p0, ], p_color, 2.0)
#		draw_multiline([a, a.lerp(p0, 0.5), a, a.lerp(p1, 0.5), a, a.lerp(p2, 0.5), ], p_color)

		i += 3
