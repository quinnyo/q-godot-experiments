@tool
extends IzmoExtension

const SCALE_UNIT := 60.0


func has_gizmo(target: Node) -> bool:
	return target is Polygon2D


func _gizmo_redraw(gizmo: IzmoGizmo) -> void:
	gizmo.clear()
	var target := gizmo.get_target_node() as Polygon2D
	var points := target.polygon
	for i in range(points.size()):
		gizmo.add_handle(i, points[i])


func _gizmo_edit_begin(id: Variant, gizmo: IzmoGizmo) -> void:
	var target := gizmo.get_target_node() as Polygon2D
	if typeof(id) == TYPE_INT:
		gizmo.set_restore_value(id, target.polygon[id])


func _gizmo_edit_update(id: Variant, position: Vector2, gizmo: IzmoGizmo) -> void:
	var target := gizmo.get_target_node() as Polygon2D
	if typeof(id) == TYPE_INT:
		var p := position.snapped(Vector2.ONE)
		var points := target.polygon
		points[id] = p
		target.polygon = points
		gizmo.set_handle_position(id, p)


func _gizmo_edit_end(id: Variant, restore: Variant, cancel: bool, gizmo: IzmoGizmo) -> void:
	var unre := gizmo.get_undo_redo()
	var target := gizmo.get_target_node() as Polygon2D
	if typeof(id) == TYPE_INT:
		if cancel:
			var points := target.polygon
			points[id] = restore
			target.polygon = points
		else:
			var undo_value := target.polygon
			undo_value[id] = restore
			unre.create_action("set point " + str(id))
			unre.add_do_property(target, "polygon", target.polygon)
			unre.add_undo_property(target, "polygon", undo_value)
			unre.commit_action()
