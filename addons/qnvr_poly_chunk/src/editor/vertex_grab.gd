@tool
extends "interaction.gd"

var idx: int
var vertex_initial_position: Vector2
var pointer_initial_position: Vector2
var pointer_position: Vector2

var new_vertex_position: Vector2

func _init(p_idx: int, p_pointer: Vector2) -> void:
	idx = p_idx
	pointer_initial_position = p_pointer
	pointer_position = p_pointer


func bind(ctx: GonEditorTypes.EditContext) -> void:
	vertex_initial_position = ctx.target.get_vertex_position(idx)
	new_vertex_position = vertex_initial_position


func update(ctx: GonEditorTypes.EditContext, pointer: GonEditorTypes.Pointer) -> void:
	if !pointer_position.is_equal_approx(pointer.target_position):
		pointer_position = pointer.target_position
		var delta := pointer_position - pointer_initial_position
		var pos := (vertex_initial_position + delta).round()
		if pos.distance_squared_to(new_vertex_position) >= 1.0:
			new_vertex_position = pos
			ctx.do_set_vertex_position(idx, new_vertex_position)


func _interaction_class_name() -> StringName:
	return &"VertexGrab"
