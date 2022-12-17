shader_type canvas_item;

varying vec4 vColor;


float softstep(float compValue, float gradient) {
  float halfChange = fwidth(gradient) / 2.0;
  //base the range of the inverse lerp on the change over one pixel
  float lowerEdge = compValue - halfChange;
  float upperEdge = compValue + halfChange;
  //do the inverse interpolation
  float stepped = (gradient - lowerEdge) / (upperEdge - lowerEdge);
  stepped = clamp(stepped, 0.0, 1.0);
  return stepped;
}

void vertex() {
	vColor = COLOR;
}

void fragment() {
	vec2 sdf_uv = screen_uv_to_sdf(SCREEN_UV);
	float sd = texture_sdf(sdf_uv);
	vec2 sdn = texture_sdf_normal(sdf_uv);

	float border_thickness = 12.0;
	float border_alpha = softstep(abs(sd), border_thickness / 2.0);

	float interior = step(sd, 0.0) - border_alpha;
	COLOR = vColor;
//	COLOR.rgb = vec3(0.0);
//	COLOR.r = border_alpha;
//	COLOR.g = interior;
//	COLOR.b = step(0.0, sd);

//	COLOR.a = 0.5 + 0.5 * max(border_alpha, interior);

	float crust_thickness = 40.0;
	float core_fade_distance = 20.0;
	float core_alpha = smoothstep(crust_thickness - core_fade_distance / 2.0, crust_thickness + core_fade_distance / 2.0, -sd);
	COLOR.a *= core_alpha;
}
