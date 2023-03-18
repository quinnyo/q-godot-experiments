@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var theme := ThemeDB.get_default_theme()
	var icon_types := theme.get_icon_type_list()
	for type in icon_types:
		print(type, ": ", theme.get_icon_list(type))
	pass
