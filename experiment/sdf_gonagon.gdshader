shader_type canvas_item;

const int GON_SIZE = 32;

uniform vec4 core_color:source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float core_start_depth:hint_range(0.0, 500.0, 0.1) = 30.0;
uniform float core_fade_dist:hint_range(0.0, 500.0, 0.1) = 50.0;
uniform float core_fade_power:hint_range(0.01, 16.0, 0.01) = 1.0;

uniform vec4 border_color:source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform float border_thickness = 4.0;
uniform float border_ratio:hint_range(-1.0, 1.0, 0.1) = 0.0;

uniform float line_spacing:hint_range(0.0, 500.0, 0.01) = 12.0;
uniform float line_thickness:hint_range(0.0, 50.0, 0.01) = 2.0;
//uniform int line_minor_count = 2;
//uniform float line_minor_thickness:hint_range(0.0, 16.0, 0.1) = 1.0;

uniform vec2 polygon[GON_SIZE];

varying vec4 vColor;
varying vec2 vPos;


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

float sdPolygon( in vec2[GON_SIZE] v, in vec2 p )
{
    float d = dot(p-v[0],p-v[0]);
    float s = 1.0;
    for( int i=0, j=GON_SIZE-1; i<GON_SIZE; j=i, i++ )
    {
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
        d = min( d, dot(b,b) );
        bvec3 c = bvec3(p.y>=v[i].y,p.y<v[j].y,e.x*w.y>e.y*w.x);
        if( all(c) || all(not(c)) ) s*=-1.0;  
    }
    return s*sqrt(d);
}

//float lines2(float dist, float spacing, float thickness, float sublines, float subline_thickness) {
//	float major_line_dist = abs(fract(dist / spacing + 0.5) - 0.5) * spacing;
//	float major_line = softstep(thickness, major_line_dist);
//
//	float minor_line_spacing = spacing / float(sublines + 1.0);
//	float minor_line_dist = abs(fract(dist / minor_line_spacing + 0.5) - 0.5) * minor_line_spacing;
//	float minor_line = softstep(subline_thickness, minor_line_dist);
//	return (major_line * minor_line);
//}

float lines(float dist, float spacing, float thickness) {
	float major_line_dist = abs(fract(dist / spacing + 0.5) - 0.5) * spacing;
	return softstep(thickness, major_line_dist);
}

float line( float sd, float r ) {
	return step(-r, sd) * step(sd, r);
}

/// Square wave
float sqr( float t ) {
	return step(0.50, fract(t));
}

float pul( float t, float w ) {
	return step(1.0-w, fract(t));
}

/// Triangle wave
float tri( float t ) {
	return abs(fract(t + 0.5) - 0.5);
}

float saw( float t ) {
	return fract(t);
}

void vertex() {
	vColor = COLOR;
	vPos = VERTEX;
}

void fragment() {
	float sd = sdPolygon(polygon, vPos);

	float core_fade_end = core_start_depth + core_fade_dist;
	float core = smoothstep(core_start_depth, core_start_depth + core_fade_dist, pow(-sd, core_fade_power));


	float asdf = lines(sd, line_spacing, line_thickness * (-abs(sd)/core_fade_end) + line_thickness);
	vec4 fill = vec4(mix(vec3(-sd), vec3(-sd + 20.0), 1.0-asdf) / 50.0, 1.0);


	float border_offset = border_ratio * border_thickness;
	float border0 = softstep(border_offset - border_thickness, sd); // inner edge of stroke
	float border1 = softstep(-border_offset - border_thickness, -sd); // outer edge of stroke

	vec4 color = mix(fill, core_color, core);
	color = mix(color, border_color, border0);
	COLOR = color * vColor;
	// mask with outer edge of border
	COLOR.a *= border1;


	// normal thing
//	float sdx = dFdx(sd);
//	float sdy = dFdy(sd);
//	vec2 sdn = normalize(vec2(sdx, sdy));
//	float b = atan(sdn.y, sdn.x) / PI;
//	COLOR = vec4(vec2(0.5) + sdn / 2.0, 0.0, 1.0);

	// edge thing
//	float edge_alpha = line(sd, 0.5);
//	COLOR.rgb = mix(COLOR.rgb, 1.0 - COLOR.rgb, edge_alpha);
//	COLOR.a = max(COLOR.a, edge_alpha);
}
