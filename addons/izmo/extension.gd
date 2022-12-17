@tool
class_name IzmoExtension
extends Node


var _izmo: EditorPlugin


func has_gizmo(target: Node) -> bool:
	return false


func create_gizmo(target: Node) -> IzmoGizmo:
	var gizmo := IzmoGizmo.new()
	gizmo._target = target
	gizmo.redraw.connect(_gizmo_redraw.bind(gizmo))
	gizmo.edit_begin.connect(_gizmo_edit_begin.bind(gizmo))
	gizmo.edit_update.connect(_gizmo_edit_update.bind(gizmo))
	gizmo.edit_end.connect(_gizmo_edit_end.bind(gizmo))
	return gizmo


### Extension added to Izmo.
#func _izmo_enter() -> void:
#	return
#
#
### Extension removed from Izmo.
#func _izmo_exit() -> void:
#	return


func _gizmo_redraw(gizmo: IzmoGizmo) -> void:
	return


func _gizmo_edit_begin(id: Variant, gizmo: IzmoGizmo) -> void:
	return


func _gizmo_edit_update(id: Variant, position: Vector2, gizmo: IzmoGizmo) -> void:
	return


func _gizmo_edit_end(id: Variant, restore: Variant, cancel: bool, gizmo: IzmoGizmo) -> void:
	return
