@tool
extends Node



class Thing:
	var name: StringName


class Thingstance:
	var number: int
	var texture: Texture2D
#	var thing: Thing


	func _get_property_list() -> Array[Dictionary]:
		var properties: Array[Dictionary] = [
			{ "name": "number", "type": TYPE_INT, "usage": PROPERTY_USAGE_DEFAULT },
			{ "name": "texture", "type": TYPE_OBJECT, "hint": PROPERTY_HINT_RESOURCE_TYPE, "hint_string": "Texture2D", "usage": PROPERTY_USAGE_DEFAULT },
		]
		return properties

	func _property_can_revert(property: StringName) -> bool:
		match property:
			"number": return true
			"texture": return true
		return false

	func _property_get_revert(property: StringName):
		match property:
			"number": return 0
			"texture": return null


var things: Array[Thingstance]


# PROPERTY_HINT_TYPE_STRING = 23
# hint_string = "%s:" % [TYPE_INT] # Array of integers.
# hint_string = "%s:%s:" % [TYPE_ARRAY, TYPE_REAL] # Two-dimensional array of floats.
# hint_string = "%s/%s:Resource" % [TYPE_OBJECT, TYPE_OBJECT] # Array of resources.
# hint_string = "%s:%s/%s:Resource" % [TYPE_ARRAY, TYPE_OBJECT, TYPE_OBJECT] # Two-dimensional array of resources.


# PROPERTY_HINT_RESOURCE_TYPE = 17
# Hints that a property is an instance of a Resource-derived type, optionally specified via the hint string (e.g. "Texture2D"). Editing it will show a popup menu of valid resource types to instantiate.



func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = [
		{ "name": "things/size", "type": TYPE_INT, "usage": PROPERTY_USAGE_DEFAULT },
	]

	for i in range(things.size()):
		var inst := things[i]
		if !(is_instance_valid(inst) && inst is Thingstance):
			continue

		for propinfo in inst._get_property_list():
			var indexed_propinfo := propinfo.duplicate()
			indexed_propinfo["name"] = "things/thing%d/%s" % [ i, propinfo["name"] ]
			properties.push_back(indexed_propinfo)

#		var basename := "things/i%d" % i
#		properties.append_array([
##			{ "name": basename + "/number", "type": TYPE_INT, "usage": PROPERTY_USAGE_DEFAULT },
##			{ "name": basename + "/texture", "type": TYPE_OBJECT, "hint": PROPERTY_HINT_RESOURCE_TYPE, "hint_string": "Texture2D", "usage": PROPERTY_USAGE_DEFAULT },
#		])


	return properties



func _property_can_revert(property: StringName) -> bool:
	var indexed_result := _match_things_indexed_property(property)
	if indexed_result:
		var index_str := indexed_result.get_string("index")
		var sub := indexed_result.get_string("sub")
		if index_str.is_valid_int():
			var index := index_str.to_int()
			if index >= 0 && index < things.size():
				return things[index].property_can_revert(sub)
		print("_set: bad indexed times %s" % property)
		return false

	var array_result := _match_things_property(property)
	if array_result:
		var sub := array_result.get_string("sub")
		match sub:
			"size": return true
		print("_set: bad array times %s" % property)
		return false

	return false


func _property_get_revert(property: StringName):
	var indexed_result := _match_things_indexed_property(property)
	if indexed_result:
		var index_str := indexed_result.get_string("index")
		var sub := indexed_result.get_string("sub")
		if index_str.is_valid_int():
			var index := index_str.to_int()
			if index >= 0 && index < things.size():
				return things[index].property_get_revert(sub)
		print("indexed thingstance property error! badness = '%s'" % property)
		return

	var array_result := _match_things_property(property)
	if array_result:
		var sub := array_result.get_string("sub")
		match sub:
			"size": return 0



func _set(property: StringName, value) -> bool:
	var indexed_result := _match_things_indexed_property(property)
	if indexed_result:
		var index_str := indexed_result.get_string("index")
		var sub := indexed_result.get_string("sub")
		if index_str.is_valid_int():
			var index := index_str.to_int()
			if index >= 0 && index < things.size():
				things[index].set(sub, value)
				return true
		print("_set: bad indexed times %s" % property)
		return false

	var array_result := _match_things_property(property)
	if array_result:
		var sub := array_result.get_string("sub")
		match sub:
			"size":
				while things.size() < value:
					things.push_back(Thingstance.new())
				things.resize(value)
				notify_property_list_changed()
				return true
		print("_set: bad array times %s" % property)
		return false

	return false


func _get(property: StringName):
	var indexed_result := _match_things_indexed_property(property)
	if indexed_result:
		var index_str := indexed_result.get_string("index")
		var sub := indexed_result.get_string("sub")
		if index_str.is_valid_int():
			var index := index_str.to_int()
			if index >= 0 && index < things.size():
				return things[index].get(sub)
		print("_get: bad indexed times %s" % property)
		return null

	var array_result := _match_things_property(property)
	if array_result:
		var sub := array_result.get_string("sub")
		match sub:
			"size": return things.size()
		print("_get: bad array times %s" % property)
		return null


func _match_things_indexed_property(property: StringName) -> RegExMatch:
	var rexp := RegEx.create_from_string("things/thing(?<index>\\d+)/(?<sub>.*)$")
	return rexp.search(property)


func _match_things_property(property: StringName) -> RegExMatch:
	var rexp := RegEx.create_from_string("things/(?<sub>.*)$")
	return rexp.search(property)
