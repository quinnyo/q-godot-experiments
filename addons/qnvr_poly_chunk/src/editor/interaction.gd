@tool
extends RefCounted


func _init() -> void:
	push_error("Interaction is a base class and not meant to be instantiated directly.")


@warning_ignore(unused_parameter)
func bind(ctx: GonEditorTypes.EditContext) -> void:
	return


@warning_ignore(unused_parameter)
func update(ctx: GonEditorTypes.EditContext, pointer: GonEditorTypes.Pointer) -> void:
	return


@warning_ignore(unused_parameter)
func finalise(ctx: GonEditorTypes.EditContext) -> void:
	return


@warning_ignore(unused_parameter)
func cancel(ctx: GonEditorTypes.EditContext) -> void:
	return


func _interaction_class_name() -> StringName:
	return &"Interaction"


func _to_string() -> String:
	return "[%s]" % [ _interaction_class_name() ]

