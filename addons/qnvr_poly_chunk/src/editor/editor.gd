@tool
extends RefCounted

const Interaction := preload("interaction.gd")
const VertexGrab := preload("vertex_grab.gd")

const POINT_RADIUS := 7.0


var ctx: GonEditorTypes.EditContext = GonEditorTypes.EditContext.new()
var current_interaction: Interaction
var pointer: GonEditorTypes.Pointer = GonEditorTypes.Pointer.new()
var overlay_points := PackedVector2Array()

var _interaction_count: int = 0


func has_editable() -> bool:
	return ctx.has_target()


func initialise_edit_context(plugin: EditorPlugin, target: GonEditorTypes.Editable) -> void:
	ctx.initialise(target, plugin.get_undo_redo())
#	ctx.target.updated.connect(_on_target_updated)


func clear_edit_context() -> void:
	cancel_interaction()
	ctx.clear_target()
	pointer = GonEditorTypes.Pointer.new()
	_redraw_overlays()


class Picker:
	## Find the closest point on an edge nearest to $p_pos.
	## Optionally only consider points within $p_radius.
	## Returns null if no edge point is found.
	static func pick(p_points: PackedVector2Array, p_pos: Vector2, p_radius: float = INF, p_edge_radius: float = INF, p_edge_clamp: bool = true) -> Dictionary:
		if p_points.size() == 0:
			return {}
		elif p_points.size() == 1:
			return { "point_idx": 0 }

		var best_point_distsq := pow(p_radius, 2.0) if is_finite(p_radius) else INF
		var best_edge_distsq := pow(p_edge_radius, 2.0) if is_finite(p_edge_radius) else INF
		var best := {}
		var edge_idx = p_points.size() - 1
		for j in range(p_points.size()):
			# pick point
			var point_distsq := p_pos.distance_squared_to(p_points[j])
			if point_distsq < best_point_distsq:
				best["point_idx"] = j
				best_point_distsq = point_distsq

			# pick edge
			var a := p_points[edge_idx]
			var ab := p_points[j] - a
			var ap := p_pos - a
			var u := ap.dot(ab) / ab.length_squared()
#			if (u < 0.0 || u >= 1.0):
#				continue
			if p_edge_clamp:
				u = clampf(u, 0.0, 1.0)
			var pos := a + ab * u
			var distsq := p_pos.distance_squared_to(pos)
			if distsq < best_edge_distsq:
				best["edge_idx"] = edge_idx
				best["edge_u"] = u
				best["edge_offset"] = float(edge_idx) + u
				best["edge_position"] = pos
				best_edge_distsq = distsq

			# edge_idx follows point iterator idx
			edge_idx = j

		return best


func update() -> void:
	if !has_editable():
		return

	var scene_viewport := ctx.target.get_target_node().get_viewport()
	var canvas_transform := scene_viewport.global_canvas_transform
	var target_transform := ctx.target.get_target_transform()

	pointer.position = scene_viewport.get_parent().get_local_mouse_position()
	var world_pointer := canvas_transform.affine_inverse() * pointer.position
	var target_pointer := target_transform.affine_inverse() * world_pointer
	pointer.target_position = target_pointer

	overlay_points.resize(ctx.target.get_vertex_count())
	for i in range(ctx.target.get_vertex_count()):
		var vpos := target_transform * ctx.target.get_vertex_position(i)
		var cpos := canvas_transform * vpos
		overlay_points[i] = cpos

	var picked := Picker.pick(overlay_points, pointer.position, POINT_RADIUS * 1.5, POINT_RADIUS * 4.0)
	pointer.pick_result = picked
	var picked_vertex: int = picked.get("point_idx", -1)
	if picked_vertex != pointer.picked_vertex:
		pointer.picked_vertex = picked_vertex
	var picked_edge: float = picked.get("edge_offset", -1.0)
	pointer.picked_edge_position = picked.get("edge_position", Vector2())
	if !is_equal_approx(picked_edge, pointer.picked_edge_offset):
		pointer.picked_edge_offset = picked_edge

	if current_interaction:
		current_interaction.update(ctx, pointer)


func draw(overlay: Control) -> void:
	if !has_editable():
		return

	# Update overlay points and picking (again) because gui_input is not called while panning...
	update()

	var draw_label := func(font: Font, pos: Vector2, text: String, alignment: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0, font_size: int = 16, outline_size: int = 4, modulate_fg: Color = Color.WHITE, modulate_bg: Color = Color.BLACK):
		overlay.draw_string_outline(font, pos, text, alignment, width, font_size, outline_size, modulate_bg)
		overlay.draw_string(font, pos, text, alignment, width, font_size, modulate_fg)

	var font := ThemeDB.fallback_font
	var point_radius := POINT_RADIUS
	var color0 := Color(0.2,0.2,0.3)
	var color1 := Color(0.7,0.7,0.7)
	var color_accent := Color(0.2, 0.88, 0.3)

	var scene_viewport := ctx.target.get_target_node().get_viewport()
	var canvas_transform := scene_viewport.global_canvas_transform
	var target_transform := ctx.target.get_target_transform()

	var j := overlay_points.size() - 1
	for i in range(overlay_points.size()):
		var a := overlay_points[j]
		var b := overlay_points[i]
		var ab := b - a
		var dir := ab.normalized()
		var edge0 := a + dir * point_radius
		var edge1 := b - dir * point_radius

		# edges
		overlay.draw_line(edge0, edge1, color0, 2.0)
		overlay.draw_dashed_line(edge0, edge1, color1, 2.0, 4.0)

		# points
		var bold := 0.0 if get_picked_vertex() != i else 1.0
		overlay.draw_circle(b, point_radius + 1.0 + bold, color1 if get_picked_vertex() != i else color_accent)
		overlay.draw_circle(b, point_radius - bold, color0)

		var point_label_offset := Vector2(-point_radius, -point_radius * 1.5)
		var point_label_pos := b + point_label_offset
		draw_label.call(font, point_label_pos, str(i), HORIZONTAL_ALIGNMENT_CENTER, point_radius * 2.0, 12, 6)

		j = i

	# picked edge
	if !has_picked_vertex() && has_picked_edge():
		var a := overlay_points[get_picked_edge_idx()]
		var b := overlay_points[get_picked_edge_b_idx()]
		var mid := a.lerp(b, 0.5)
		var closest := a if get_picked_edge_offset() - floorf(get_picked_edge_offset()) <= 0.5 else b
		overlay.draw_line(closest, mid, color_accent, 2.0, true)
		overlay.draw_arc(get_picked_edge_position(), point_radius * 1.5, 0, TAU, 5, color0, 4.0, true)
		overlay.draw_arc(get_picked_edge_position(), point_radius * 1.5, 0, TAU, 5, color_accent, 2.0, true)
		draw_label.call(font, get_picked_edge_position(), "%10.3f" % [ get_picked_edge_offset() ], HORIZONTAL_ALIGNMENT_CENTER, -1.0, 12, 6)

	for i in range(overlay_points.size()):
		var a := overlay_points[wrapi(i - 1, 0, overlay_points.size())]
		var b := overlay_points[i]
		var c := overlay_points[wrapi(i + 1, 0, overlay_points.size())]
		var ab := b - a
		var bc := c - b
		draw_label.call(font, b + Vector2(point_radius, point_radius) * 2.0, "%10.3f" % [ rad_to_deg(ab.angle_to(bc)) ])


func get_picked_vertex() -> int:
	return pointer.picked_vertex


func get_picked_edge_idx() -> int:
	return floori(get_picked_edge_offset())


func get_picked_edge_b_idx() -> int:
	return wrapi(get_picked_edge_idx() + 1, 0, ctx.target.get_vertex_count())


func get_picked_edge_offset() -> float:
	return pointer.picked_edge_offset


func get_picked_edge_position() -> Vector2:
	return pointer.picked_edge_position if get_picked_edge_offset() >= 0.0 else Vector2()


func has_picked_vertex() -> bool:
	return ctx.is_vertex_valid(get_picked_vertex())


func has_picked_edge() -> bool:
	return ctx.is_vertex_valid(get_picked_edge_idx())


func primary_tool_input(pressed: bool, shift: bool, ctrl: bool) -> bool:
	if pressed:
		if shift:
			# APPEND
			vertex_append(pointer.target_position)
			return true
		elif has_picked_vertex() && !ctrl:
			# GRAB
			vertex_grab(get_picked_vertex())
			return true
		elif has_picked_edge():
			# INSERT
			insert_vertex_on_edge(get_picked_edge_offset())
			return true
	else:
		if is_grabbing():
			finalise_interaction()
			return true

	return false


func secondary_tool_input(pressed: bool) -> bool:
	if pressed:
		if is_grabbing():
			# CANCEL GRAB
			cancel_interaction()
			return true
		elif ctx.is_vertex_valid(get_picked_vertex()):
			# REMOVE VERTEX
			ctx.do_remove_vertex(get_picked_vertex())
			return true

	return false


### Primary build action does the first valid action:
### - if a valid vertex is picked, grab it.
### - if an edge is picked, subdivide it (insert vertex).
### - if the target has less than 3 vert
### - append a vertex at the pointer
### Returns true if any action except the fallback was attempted...
#func primary_build(p_no_grab: bool) -> bool:
#	if !p_no_grab && is_vertex_valid(pointer.picked_vertex):
#		vertex_grab(pointer.picked_vertex)
#		return true
#	elif pointer.picked_edge:
#		do_insert_on_edge(pointer.picked_edge.offset)
#		return vertex_grab(ceili(pointer.picked_edge.offset))
#	else:
#		do_append_vertex(pointer.position)
#		return true


#func primary_remove() -> bool:
#	if ctx.is_vertex_valid(get_picked_vertex()):
#		ctx.do_remove_vertex(get_picked_vertex())
#		return true
#	return false


#func primary_grab() -> void:
#	if ctx.is_vertex_valid(get_picked_vertex()):
#		vertex_grab(get_picked_vertex())


## Append a vertex at position $p_pos and start a grab interaction with the new vertex.
func vertex_append(p_pos: Vector2) -> void:
	ctx.do_append_vertex(p_pos)
	vertex_grab(ctx.target.get_vertex_count())


## Inserts a vertex on an edge. $p_offset is an 'edge offset thing'.
## Returns the index of the newly insert vertex if succesful, or -1 if failed.
func insert_vertex_on_edge(p_offset: float) -> int:
	var idx := ctx.do_insert_vertex_on_edge(p_offset)
	vertex_grab(idx)
	return idx


##
func vertex_grab(p_vertex: int) -> void:
	if ctx.is_vertex_valid(p_vertex):
		_push_interaction(VertexGrab.new(p_vertex, pointer.target_position))


func is_grabbing() -> bool:
	return current_interaction is VertexGrab


func get_active_vertex() -> int:
	var g := current_interaction as VertexGrab
	if g:
		return g.idx
	return -1


func cancel_interaction() -> void:
	if current_interaction:
		current_interaction.cancel(ctx)
	current_interaction = null


func finalise_interaction() -> void:
	assert(current_interaction)
	current_interaction.finalise(ctx)
	current_interaction = null


func _push_interaction(p_interaction: Interaction) -> void:
	if current_interaction:
		push_warning("[GonEdit::_push_interaction] replacing current_interaction (%s <- %s)" % [ current_interaction, p_interaction ])
	current_interaction = p_interaction
	current_interaction.bind(ctx)
	_interaction_count += 1


func _redraw_overlays() -> void:
	pass
