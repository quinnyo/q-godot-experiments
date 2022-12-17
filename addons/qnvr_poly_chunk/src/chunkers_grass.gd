@tool
extends Node2D


#var count := 0
#var points := PackedVector2Array()
#var normals := PackedVector2Array()

var _points: Array[PackedVector2Array] = []
var _normals: Array[PackedVector2Array] = []


func _draw() -> void:
	for i in range(_points.size()):
		_draw_thing(_points[i], _normals[i])


func _draw_thing(points: PackedVector2Array, normals: PackedVector2Array) -> void:
	for i in range(1, points.size()):
		var j = i - 1
		var p0 := points[j]
		var n0 := normals[j]
		var p1 := points[i]
		var n1 := normals[i]
		var diff := p1 - p0
		var length := diff.length()
		var dir := diff / length
		var x := 0.0
		while x <= length:
			var px := p0 + dir * x
			var nx := n0.slerp(n1, x / length)
			var q0 := nx * (4 + randf() * 4)
			var q1 := q0 + Vector2.UP.slerp(nx, 0.2) * 4.0
			x += 8.0 + randf() * 4.0
			draw_polyline([ px, px + q0, px + q1 ],  Color.GREEN)


#		draw_line(points[i], points[i] + normals[i] * 30, Color.GREEN)


func _chunkers(chunk: PolyChunk2D) -> void:
	_points.clear()
	_normals.clear()
	var points := PackedVector2Array()
	var normals := PackedVector2Array()
#	count = 0
#	points.resize(chunk.points.size())
#	normals.resize(chunk.points.size())
	for i in range(chunk.points.size()):
		var n := chunk.normals[i]
		if n.dot(Vector2.UP) > 0.5:
			points.push_back(chunk.points[i])
			normals.push_back(n)
#			points[count] = chunk.points[i]
#			normals[count] = n
#			count += 1
		else:
			_points.push_back(points)
			_normals.push_back(normals)
			points = PackedVector2Array()
			normals = PackedVector2Array()

	queue_redraw()

