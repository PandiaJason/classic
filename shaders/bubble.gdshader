shader_type canvas_item;

uniform vec4 bubble_color : source_color = vec4(0.2, 0.6, 1.0, 0.05);
uniform vec3 rim_color : source_color = vec3(0.8, 0.95, 1.0);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	
	if (dist > 1.0) {
		COLOR.a = 0.0;
	} else {
		// Faint inner center
		vec4 color = bubble_color;
		
		// Inner glowing falloff increasing as it approaches the edge
		float glow = pow(dist, 4.0) * 0.2;
		
		// Very thin, softer glossy outer edge
		float outline = smoothstep(0.985, 0.995, dist) - smoothstep(0.995, 1.0, dist);
		
		color.rgb = mix(color.rgb, rim_color, outline + glow);
		color.a += outline * 0.4 + glow;
		
		COLOR = color;
	}
}
