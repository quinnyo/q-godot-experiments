@tool
extends IzmoExtension

const SCALE_UNIT := 60.0


func has_gizmo(target: Node) -> bool:
	return target is Sprite2D


func _gizmo_redraw(gizmo: IzmoGizmo) -> void:
	gizmo.clear()
	var target := gizmo.get_target_node() as Node2D

	gizmo.add_handle("scale:x", target.global_transform.x * SCALE_UNIT)
	gizmo.add_handle("scale:y", target.global_transform.y * SCALE_UNIT)
	gizmo.add_handle("scale", target.scale * Vector2.ONE * SCALE_UNIT)


func _gizmo_edit_begin(id: Variant, gizmo: IzmoGizmo) -> void:
	var target := gizmo.get_target_node() as Node2D
	match id:
		"scale:x": gizmo.set_restore_value(id, target.scale.x)
		"scale:y": gizmo.set_restore_value(id, target.scale.y)
		"scale": gizmo.set_restore_value(id, target.scale)


func _gizmo_edit_update(id: Variant, position: Vector2, gizmo: IzmoGizmo) -> void:
	var target := gizmo.get_target_node() as Node2D
	match id:
		"scale:x":
			var ux := target.global_transform.y.normalized().orthogonal()
			var pdx := position.dot(ux)
			if ux.is_zero_approx() || is_zero_approx(pdx):
				return
			gizmo.set_handle_position(id, ux * pdx)
			target.scale.x = pdx / SCALE_UNIT
		"scale:y":
#			if is_zero_approx(position.y):
#				return
#			var snapped := Vector2(0.0, snappedf(position.y, SCALE_UNIT / 10.0))
#			if is_zero_approx(snapped.y):
#				return
#			target.scale.y = snapped.y / SCALE_UNIT
##			gizmo.set_handle_position(id, snapped.abs() * SCALE_UNIT)
#			return

			var uy := target.global_transform.y.normalized()
			var pdy := position.dot(uy)
			if uy.is_zero_approx() || is_zero_approx(pdy):
				return
			gizmo.set_handle_position(id, uy * pdy)
			target.scale.y = pdy / SCALE_UNIT
		"scale":
			if is_zero_approx(position.x) || is_zero_approx(position.y):
				return

			target.scale = position / SCALE_UNIT


func _gizmo_edit_end(id: Variant, restore: Variant, cancel: bool, gizmo: IzmoGizmo) -> void:
	var unre := gizmo.get_undo_redo()
	var target := gizmo.get_target_node() as Node2D
	match id:
		"scale:x":
			var undo_value := Vector2(restore, target.scale.y)
			if cancel:
				target.scale = undo_value
			else:
				unre.create_action("set " + str(id))
				unre.add_do_property(target, "scale", target.scale)
				unre.add_undo_property(target, "scale", undo_value)
				unre.commit_action()
		"scale:y":
			var undo_value := Vector2(target.scale.x, restore)
			if cancel:
				target.scale = undo_value
			else:
				unre.create_action("set " + str(id))
				unre.add_do_property(target, "scale", target.scale)
				unre.add_undo_property(target, "scale", undo_value)
				unre.commit_action()
		"scale":
			var undo_value := Vector2(restore)
			if cancel:
				target.scale = undo_value
			else:
				unre.create_action("set " + str(id))
				unre.add_do_property(target, "scale", target.scale)
				unre.add_undo_property(target, "scale", undo_value)
				unre.commit_action()
