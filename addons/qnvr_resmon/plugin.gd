@tool
extends EditorPlugin


func _enter_tree() -> void:
	var efs := get_editor_interface().get_resource_filesystem()
	efs.filesystem_changed.connect(_on_filesystem_changed)
	efs.resources_reimported.connect(_on_resources_reimported)
	efs.resources_reload.connect(_on_resources_reload)
	efs.script_classes_updated.connect(_on_script_classes_updated)
	efs.sources_changed.connect(_on_sources_changed)


func _exit_tree() -> void:
	var efs := get_editor_interface().get_resource_filesystem()
	efs.filesystem_changed.disconnect(_on_filesystem_changed)
	efs.resources_reimported.disconnect(_on_resources_reimported)
	efs.resources_reload.disconnect(_on_resources_reload)
	efs.script_classes_updated.disconnect(_on_script_classes_updated)
	efs.sources_changed.disconnect(_on_sources_changed)


func _on_filesystem_changed() -> void:
	print("[resmon] filesystem_changed")
	pass

func _on_resources_reimported(resources: PackedStringArray) -> void:
	print("[resmon] resources_reimported: ", resources)
	pass

func _on_resources_reload(resources: PackedStringArray) -> void:
	print("[resmon] resources_reload: ", resources)
	pass

func _on_script_classes_updated() -> void:
	print("[resmon] script_classes_updated")
	pass

func _on_sources_changed(exist: bool) -> void:
	print("[resmon] sources_changed: ", exist)
	pass
