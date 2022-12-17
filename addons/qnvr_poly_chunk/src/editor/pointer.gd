@tool
extends RefCounted

## pointer position in editor (overlay?) space
var position: Vector2
## pointer position in target local space
var target_position: Vector2

var picked_vertex: int = -1
var picked_edge_offset: float = -1.0
var picked_edge_position: Vector2
var pick_result: Dictionary
