extends Node

const MATCH1 := "*_won"
const MATCH2 := [ "*_too", "*_3" ]
const TYPED_WORDS: Array[StringName] = [ &"won", &"too", &"3" ]
const EMPTY_ARRAY := [  ]

const EXPR := "target.is_class(\"Node2D\")"


static func target(target: Node) -> bool:
	return target is Node2D

static func retvoid() -> void:
	return

static func nonono():
	return
