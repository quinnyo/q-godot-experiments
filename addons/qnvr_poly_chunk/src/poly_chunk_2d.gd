@tool
class_name PolyChunk2D extends Node2D
@icon("../icon/poly_chunk_2d.svg")

## Emitted after (re)building
signal updated()

enum CombineOperation {
	NOOP,
	## Merge/Union, `A | B`.
	MERGE,
	## Clip A with B. `A - B` -- Removes parts in common with B.
	CLIP,
	## Mask A with B. `A & B` -- Keep parts in common with B.
	MASK,
	## Exclude
	XOR,
	## Combine A and B by appending Bgons to A.
	APPEND,
}

enum ColliderMode {
	## Visual only -- no collision shape or body will be created.
	NONE,
	## Easy-mode static (solid) geometry.
	## A static body and collision shape/s will be created and added to the scene.
	STATIC_BODY,
}


@export var color: Color = Color.PALE_VIOLET_RED:
	set(value):
		color = value
		_mark_dirty()

@export var color_stroke: Color = Color.PALE_GREEN:
	set(value):
		color_stroke = value
		_mark_dirty()

@export var stroke_thickness := 2.0:
	set(value):
		stroke_thickness = value
		_mark_dirty()

@export var texture: Texture2D:
	set(value):
		texture = value
		_mark_dirty()

@export var join_cut_depth := 4.0:
	set(value):
		join_cut_depth = value
		_mark_dirty()

@export var points: PackedVector2Array = PackedVector2Array():
	set(value):
		points = value
		_mark_dirty()

@export var collider_mode: ColliderMode = ColliderMode.NONE

## Boolean/combine mode to use with parent chunk geometry
@export var parent_combine_mode: CombineOperation = CombineOperation.NOOP:
	set(value):
		parent_combine_mode = value
		_mark_dirty()

@export var operation: CombineOperation = CombineOperation.MERGE:
	set(value):
		operation = value
		_mark_dirty()


var normals: PackedVector2Array

## built polygon (cache)
var _polygon: PackedVector2Array

var _update_requested := true


func _init() -> void:
	set_notify_local_transform(true)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED,NOTIFICATION_MOVED_IN_PARENT,NOTIFICATION_VISIBILITY_CHANGED,NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			_mark_dirty()
#TODO: initialise collider stuff?
#		NOTIFICATION_ENTER_TREE:
#			var body := get_node_or_null("_static_body_2d") as StaticBody2D
#			if !Engine.is_editor_hint() && collider_mode == ColliderMode.STATIC_BODY:
#				if body == null:
#					body = StaticBody2D.new()
#					body.name = "_static_body_2d"
#					add_child(body)
#				var colpol := body.get_node_or_null("collision_polygon_2d") as CollisionPolygon2D
#				if colpol == null:
#					colpol = CollisionPolygon2D.new()
#					colpol.name = "collision_polygon_2d"
#					body.add_child(colpol)
#				colpol.polygon = _polygon
#			elif is_instance_valid(body):
#				body.queue_free()


func _physics_process(_delta: float) -> void:
	if _update_requested:
#		print("%s %s" % [ owner.get_path_to(self) if owner else get_path(), Time.get_ticks_usec() ])
		build()
		_update_requested = false


func _draw() -> void:
#	_draw_chunk()

	_draw_gons()

	if Engine.is_editor_hint():
		_draw_wire(points, Color(0,0,0,0.5))


func get_points_count() -> int:
	return points.size()


func get_point_world(idx: int) -> Vector2:
	return to_global(points[idx])


func get_point(idx: int, p_repeating: bool = true) -> Vector2:
	return points[wrapi(idx, 0, get_points_count()) if p_repeating else idx]


func set_point(idx: int, p: Vector2) -> void:
	points[idx] = p
	_mark_dirty()


func append_point(p: Vector2) -> int:
	points.push_back(p)
	_mark_dirty()
	return points.size() - 1


func insert_point(idx: int, p: Vector2) -> void:
	points.insert(idx, p)
	_mark_dirty()


func clone_points() -> PackedVector2Array:
	return points.duplicate()


## Find the point nearest to $p_pos and return its index.
## Optionally only consider points within $p_radius.
## If no point is found, returns `-1`
func pick_point(p_pos: Vector2, p_radius: float = INF) -> int:
	var best_idx := -1
	var best_distsq := pow(p_radius, 2.0)
	for idx in range(points.size()):
		var distsq := p_pos.distance_squared_to(points[idx])
		if distsq < best_distsq:
			best_idx = idx
			best_distsq = distsq
	return best_idx


func pick_edge(p_pos: Vector2, p_margin: float = INF) -> float:
	if get_points_count() < 2:
		return -1.0
	var best_idx := -1
	var best_distsq := pow(p_margin, 2.0)
	var best_u := 0.0
	for idx in range(points.size()):
		var seg := get_segment(idx)
		var ab := seg[1] - seg[0]
		var ap := p_pos - seg[0]
		var u := ap.dot(ab) / ab.length_squared()
		if u < 0.0 || u >= 1.0:
			continue
		var distsq := p_pos.distance_squared_to(seg[0] + ab * u)
		if distsq < best_distsq:
			best_idx = idx
			best_distsq = distsq
			best_u = u

	return float(best_idx) + best_u


func get_segment(idx: int) -> PackedVector2Array:
	if points.size() < 2:
		return PackedVector2Array()
	return PackedVector2Array([ points[idx], points[(idx + 1) % points.size()] ])


func interpolate_polyline(offset: float) -> Vector2:
	var seg := get_segment(int(offset))
	return seg[0].lerp(seg[1], offset - floor(offset))


func get_segment_length_squared(idx: int) -> float:
	var seg := get_segment(idx)
	return (seg[1] - seg[0]).length_squared()


func interpolate_segment(idx: int, t: float) -> Vector2:
	var seg := get_segment(idx)
	return seg[0].lerp(seg[1], t)


func split_segment(offset: float) -> void:
	points.insert(ceili(offset), interpolate_polyline(offset))
	_mark_dirty()


func remove_point(idx: int) -> void:
	points.remove_at(idx)
	_mark_dirty()


func _build() -> void:
	normals = PackedVector2Array()
	normals.resize(points.size())
	var j := points.size() - 1
	for i in range(points.size()):
		var a := points[j]
		var b := points[i]
		var diff := b - a
		var normal := diff.normalized().orthogonal()
		normals[i] = normal
		j = i

	for child in get_children():
		if child.has_method("_chunkers"):
			child.call("_chunkers", self)

	gons = Gons.new()

	gons.gons = [ points.duplicate() ]
	gons.mod_colors = [ color ]

#	if join_cut_depth > 0.0:
#		_polygon = _smooth(_polygon, join_cut_depth)

	for child in get_children():
		var child_chunk := child as PolyChunk2D
		if !is_instance_valid(child_chunk) || !child_chunk.visible:
			continue
		child_chunk._build()
		if child_chunk.gons.count_valid():
			gons = gons.combined(child_chunk.operation, child_chunk.gons)
#		child_chunk.gons = child_chunk.gons.combined(child_chunk.parent_combine_mode, gons)

	for child in get_children():
		var child_chunk := child as PolyChunk2D
		if !is_instance_valid(child_chunk) || !child_chunk.visible:
			continue
		if child_chunk.gons.count_valid() && child_chunk.parent_combine_mode != CombineOperation.NOOP:
			child_chunk.gons = child_chunk.gons.combined(child_chunk.parent_combine_mode, gons)


	if get_poly_chunk_parent() && parent_combine_mode != CombineOperation.NOOP:
		gons = gons.combined(parent_combine_mode, get_poly_chunk_parent().gons)


var gons: Gons

## (re)build geometry
func build() -> void:
	if is_root_chunk():
		_build()

	queue_redraw()
	updated.emit()


func _draw_wire(p_points: PackedVector2Array, color0: Color = Color.BLACK, color1: Color = Color.WHITE) -> void:
	for idx in range(p_points.size()):
		var jdx := (idx + 1) % p_points.size()
		draw_line(p_points[idx], p_points[jdx], color0)
		draw_dashed_line(p_points[idx], p_points[jdx], color1, 1.0, 4.0)


func _draw_gons() -> void:
	if is_instance_valid(gons):
		if is_root_chunk() || parent_combine_mode != CombineOperation.NOOP:
			for idx in range(gons.count()):
				if gons.get_point_count(idx) >= 3:
					draw_colored_polygon(gons.get_polygon_points(idx), gons.get_mod_color(idx))
		for idx in range(gons.count()):
			_draw_wire(gons.get_polygon_points(idx))


func get_poly_chunk_parent() -> PolyChunk2D:
	return get_parent() as PolyChunk2D


func is_root_chunk() -> bool:
	return get_poly_chunk_parent() == null


class Gons:
	var gons: Array[PackedVector2Array] = []
#	var colors: Array[PackedColorArray] = []
	var mod_colors: PackedColorArray = PackedColorArray()

	func count_valid() -> int:
		var n := 0
		for a in gons:
			if a.size() >= 3:
				n += 1
		return n

	func count() -> int:
		return gons.size()

#	func clean() -> void:
#		gons = gons.filter(func(a: PackedVector2Array): return a.size() >= 3)

	func get_mod_color(idx: int) -> Color:
		if mod_colors.is_empty():
			return Color(1,1,1,0.4)
		return mod_colors[idx % mod_colors.size()]

	func get_polygon_points(idx: int) -> PackedVector2Array:
		if idx >= 0 && idx < gons.size():
			return gons[idx]
		return PackedVector2Array()

	func get_point_count(idx: int) -> int:
		if idx >= 0 && idx < gons.size():
			return gons[idx].size()
		return -1

	func combined(op: CombineOperation, b: Gons) -> Gons:
		var c := Gons.new()
		for agon in gons:
			for bdx in range(b.count()):
				var bgon := b.get_polygon_points(bdx)
				var ab := _combine_primitives(op, agon, bgon)
				for points in ab:
					if points.size() >= 3:
						c.gons.push_back(points)
						c.mod_colors.push_back(b.get_mod_color(bdx))
		return c

	func _combine_primitives(op: CombineOperation, a: PackedVector2Array, b: PackedVector2Array) -> Array[PackedVector2Array]:
		match op:
			CombineOperation.MERGE:
				return Geometry2D.merge_polygons(a, b)
			CombineOperation.CLIP:
				return Geometry2D.clip_polygons(a, b)
			CombineOperation.MASK:
				return Geometry2D.intersect_polygons(a, b)
			CombineOperation.XOR:
				return Geometry2D.exclude_polygons(a, b)
			CombineOperation.APPEND:
				return [a, b]
			CombineOperation.NOOP:
				return [ a ]

		push_error("unhandled/invalid CombineOperation: %s ('%s')" % [ op, CombineOperation.find_key(op) ])
		return [ a ] if !a.is_empty() else []


func _mark_dirty() -> void:
	var parent_chunk := get_poly_chunk_parent()
	if parent_chunk:
		parent_chunk._mark_dirty()
	_update_requested = true


func _smooth(p_points: PackedVector2Array, p_depth: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for idx in range(p_points.size()):
		var seg0 := p_points[idx]
		var seg1 := p_points[(idx + 1) % p_points.size()]
		var seglen := seg0.distance_to(seg1)
		var udepth := p_depth / seglen
		if udepth > 0.5:
			polygon.push_back(seg0)
			polygon.push_back(seg1)
		else:
			polygon.push_back(seg0.lerp(seg1, udepth))
			polygon.push_back(seg1.lerp(seg0, udepth))
	return polygon


func _interpolate_segment(polygon: PackedVector2Array, offset: float) -> Vector2:
	var a := polygon[int(offset)]
	var b := polygon[(int(offset) + 1) % polygon.size()]
	var t := offset - floorf(offset)
	return a.lerp(b, t)


func _split_segment(polygon: PackedVector2Array, offset: float) -> PackedVector2Array:
	var a := polygon[int(offset)]
	var b := polygon[(int(offset) + 1) % polygon.size()]
	var t := offset - floorf(offset)
	var new := polygon.duplicate()
	new.insert(int(offset) + 1, a.lerp(b, t))
	return new


func _draw_chunk() -> void:
	if _polygon.size() < 3:
		return

	if stroke_thickness > 0.0:
		var polyline := _polygon.duplicate()
		polyline.push_back(polyline[0])
		draw_polyline(polyline, color_stroke, stroke_thickness)

	if texture:
		var uv_transform := Transform2D().scaled(Vector2.ONE / texture.get_size())
		var uv0 := uv_transform * _polygon
		draw_colored_polygon(_polygon, color, uv0, texture)
	else:
		draw_colored_polygon(_polygon, color)
