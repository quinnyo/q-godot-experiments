@tool
class_name GonNode2D
extends Node2D


const FN_GON_BUILD := "_gon_build"


### This node's own shape data
#@export var gon: Gonagon:
#	set(value):
#		if gon != value:
#			if is_instance_valid(gon) && gon.changed.is_connected(mark_dirty):
#				gon.changed.disconnect(mark_dirty)
#			gon = value
#			if is_instance_valid(gon):
#				var err := gon.changed.connect(mark_dirty)
#				if err != OK:
#					push_error("could not connect signal (%s)" % [ err ])


var _dirty := true
var _gx: Gonagon


func _ready() -> void:
	set_notify_local_transform(true)


func _process(_delta: float) -> void:
	if _dirty:
		_update()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_CANVAS,NOTIFICATION_ENABLED,NOTIFICATION_ENTER_TREE,NOTIFICATION_VISIBILITY_CHANGED:
			mark_dirty()
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			if !is_root_gon_node():
				mark_dirty()


func _draw() -> void:
	if _dirty:
		return

	if is_root_gon_node() && is_instance_valid(_gx):
		if _gx.get_vertex_count() > 2:
			draw_colored_polygon(_gx.v_position, Color.WHITE)

		if Engine.is_editor_hint():
	#		_draw_wire_gon(gon, Color.CYAN, 1.1)
			_draw_wire_gon(_gx, Color.MIDNIGHT_BLUE, 1.1)


func get_parent_gon_node() -> GonNode2D:
	return get_parent() as GonNode2D


func is_root_gon_node() -> bool:
	return get_parent_gon_node() == null


func mark_dirty() -> void:
	if !is_root_gon_node():
		get_parent_gon_node().mark_dirty()
	_dirty = true
	if Engine.is_editor_hint():
		_update()


func _gon_build(gx: Gonagon) -> void:
	var _unused_parameter := gx


func _update() -> void:
	_gx = Gonagon.new()
	_gon_build(_gx)
	for child in get_children():
		var gonchild := child as Node2D
		if gonchild && gonchild.visible:
			if child.has_method(FN_GON_BUILD):
				child.call(FN_GON_BUILD, _gx)
				_gx.notify_changed()

	queue_redraw()
	_dirty = false


func _draw_wire_gon(gx: Gonagon, color: Color, width: float = 1.1) -> void:
#	var alt_color := Color.from_hsv(color.h, color.s * 0.5, 0.9 if color.v <= 0.6 else 0.3)

	for k in range(gx.get_vertex_count()):
		var a := gx.get_vertex_position(k - 1)
		var b := gx.get_vertex_position(k)
#		draw_line(a, b, alt_color, width + 1.0)
		draw_line(a, b, color, width)

		if k < gx.v_normal.size():
			draw_line(b, b + gx.v_normal[k] * 20.0, Color.MAGENTA)

#	draw_rect(gx.bounds, Color(alt_color, 0.5 * alt_color.a), false, width + 1.0)
#	draw_rect(gx.bounds, Color(color, 0.5 * color.a), false, width)
