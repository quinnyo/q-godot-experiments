@tool
extends IzmoGizmo

##
## look_at__auto_gizmo.gd
##
## Example AutoGizmo. Adds a "look at" handle to Node2D.
##

const RADIUS := 120.0

const GOFFSET := &"offset"
const HLOOK := &"look"


func _redraw() -> void:
	clear()

	var target := get_target_node() as Node2D
	add_group(GOFFSET)
	add_handle(HLOOK, target.global_transform.x.normalized() * RADIUS, GOFFSET)
	super()


func _edit_begin(edit: Edit) -> void:
	var target := get_target_node() as Node2D
	match edit.handle_id:
		HLOOK:
			edit.restore = target.rotation
	super(edit)


func _edit_update(edit: Edit) -> void:
	var target := get_target_node() as Node2D
	match edit.handle_id:
		HLOOK:
			target.look_at(target.global_position + edit.get_handle_position())
			set_handle_position(edit.handle_id, edit.get_handle_position().normalized() * RADIUS)
	super(edit)


func _edit_end(edit: Edit) -> void:
	var unre := get_undo_redo()
	var target := get_target_node() as Node2D
	match edit.handle_id:
		HLOOK:
			if edit.is_cancelled():
				target.rotation = edit.restore
			else:
				unre.create_action(HLOOK)
				unre.add_do_property(target, "rotation", target.rotation)
				unre.add_undo_property(target, "rotation", edit.restore)
				unre.commit_action()
				pass
	super(edit)


static func _auto_gizmo_is_target(target: Node) -> bool:
	return target is Node2D
