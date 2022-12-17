@tool
##
## Does stuff to corners... Calculates surface normals,
## Optionally adds chamfers, fillets based on corner angle.
extends GonNode2D



@export var smooth_normals: bool = true:
	set(value):
		if value != smooth_normals:
			smooth_normals = value
			mark_dirty()

## Corner angle threshold for adding chamfer.
## Chamfer will be added to corners with an (outer) angle greater than this value.
@export_range(0.0, 180.0, 0.05) var sharp_threshold_deg: float = 30.0:
	set(value):
		if !is_equal_approx(value, sharp_threshold_deg):
			sharp_threshold_deg = value
			mark_dirty()

@export_range(0.0, 200.0, 0.1) var sharp_chamfer_depth: float = 4.0:
	set(value):
		if !is_equal_approx(value, sharp_chamfer_depth):
			sharp_chamfer_depth = value
			mark_dirty()

## Corner angle threshold for adding fillet.
## Fillet will be added to corners with an (inner) angle greater than this value.
@export_range(0.0, 180.0, 0.05) var fillet_threshold_deg: float = 60.0:
	set(value):
		if !is_equal_approx(value, fillet_threshold_deg):
			fillet_threshold_deg = value
			mark_dirty()

@export_range(0.0, 200.0, 0.1) var fillet_depth: float = 4.0:
	set(value):
		if !is_equal_approx(value, fillet_depth):
			fillet_depth = value
			mark_dirty()


func _gon_build(gx: Gonagon) -> void:
	if gx.get_vertex_count() < 3:
		return

	_gmod_build_normals(gx)


func _gmod_build_normals(gx: Gonagon) -> void:
	var err := gx.v_normal.resize(gx.get_vertex_count())
	if err != OK:
		push_error("failed to resize v_normal (%s)" % [ err ])
		return

	var sharp_threshold := deg_to_rad(sharp_threshold_deg)
	var fillet_threshold := deg_to_rad(-fillet_threshold_deg)

	var k := 0
	while k < gx.get_vertex_count():
		var a := gx.get_vertex_position(k - 1)
		var b := gx.get_vertex_position(k)
		var c := gx.get_vertex_position(k + 1)

		var ab := b - a
		var bc := c - b
		var mab := ab.length()
		var mbc := bc.length()
		var uab := ab / mab
		var ubc := bc / mbc
		var nab := -uab.orthogonal() * gx.get_winding_signum()
		var nbc := -ubc.orthogonal() * gx.get_winding_signum()
		var angle := ab.angle_to(bc)
		gx.v_normal[k] = nbc

		var cut_depth := 0.0
		if angle <= fillet_threshold:
			cut_depth = fillet_depth * angle / fillet_threshold
		elif angle >= sharp_threshold:
			cut_depth = sharp_chamfer_depth * angle / sharp_threshold

		cut_depth = minf(minf(mab, mbc), cut_depth)
		if cut_depth > 1.0:
			var p := b - uab * cut_depth
			b = b + ubc * cut_depth
			gx.set_vertex_position(k, b)
			var npb := -(b - p).orthogonal().normalized() * gx.get_winding_signum()
			if smooth_normals:
				gx.v_normal[k] = npb.slerp(nbc, 0.5)
				npb = nab.slerp(npb, 0.5)
			gx.insert_vertex(k, p)
			gx.v_normal.insert(k, npb)
			k += 2
			continue

		# corner split smooth normal things
		if smooth_normals:
			gx.v_normal[k] = nab.slerp(nbc, 0.5)

		k += 1
