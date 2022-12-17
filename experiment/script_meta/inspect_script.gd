## What metadata can we get from a Script resource, without instantiating it (as an Object's script)
## related: resource_hunting
@tool
extends EditorScript


func _run() -> void:
	inspect(load("res://experiment/script_meta/example_node.gd"))
	pass


func inspect(script: Script) -> void:
	prints(script, script.resource_path, script.has_method("new"))


	print("CONSTANTS")
	var constants := script.get_script_constant_map()
	for k in constants:
		var v = constants[k]
		var typestr := ""
		match typeof(v):
			TYPE_ARRAY:
				typestr = "Array"
				var a: Array = v
				if a.size() > 0:
					typestr = "Array<%s>" % [ typeof(a[0]) ]

				if a.is_typed():
					typestr = "TypedArray<%s|%s|%s>" % [ a.get_typed_builtin(), a.get_typed_class_name(), a.get_typed_script() ]
			var t:
				typestr = str(t)

		print("  %s : %s = %s" % [ k, typestr, v ])

	print("METHODS")
	var methods := script.get_script_method_list()
	for m in methods:
		print(m.get("name"), ": ", m)
		print(script.has_method(m.get("name")))
	print("  script.target(Node2D|Node): %s|%s" % [ script.target(Node2D.new()), script.target(Node.new()) ])

	if constants.has("EXPR"):
		var code: String = constants["EXPR"]
		var expr := Expression.new()
		var parse_err := expr.parse(code, [ "target" ])
		if parse_err:
			print("parsing expr '%s' failed: '%s'" % [ code, parse_err ])
		else:
			for target in [ Node.new(), Node2D.new(), Sprite2D.new() ]:
				var result = expr.execute([ target ])
				print("expr(%s): %s" % [ target, result ])


#	var gizmo := IzmoGizmo.new()
#	prints(gizmo is IzmoGizmo, gizmo.is_class("IzmoGizmo"), gizmo.get_script() == IzmoGizmo)
#	prints(IzmoGizmo, IzmoGizmo.resource_name, IzmoGizmo.resource_path)
#	print(get_property_list())
#	print(self.get("IzmoGizmo"))
#	print(_exec("a.get_script()", ["a"], [gizmo]))
#	print(ClassDB.can_instantiate("IzmoGizmo"))

	pass

func _exec(code: String, input_names: PackedStringArray = PackedStringArray([]), inputs: Array = []) -> Dictionary:
	var expr := Expression.new()
	var parse_err := expr.parse(code, input_names)
	if parse_err:
		print("parsing expr '%s' failed: '%s'" % [ code, expr.get_error_text() ])
		return { "parse_error": expr.get_error_text() }
	var ret = expr.execute(inputs, self)
	if expr.has_execute_failed():
		return {}
	return { "return_value": ret }


# target:
const TARGET := {
	"name": "target",
	"args": [
		{
			"name": "target",
			"class_name": &"Node",
			"type": 24,
			"hint": 0,
			"hint_string": "", "usage": 6
		}
	],
	"default_args": [],
	"flags": 33,
	"id": 0,
	"return": {
		"name": "",
		"class_name": &"",
		"type": 1,
		"hint": 0,
		"hint_string": "",
		"usage": 6
	}
}
