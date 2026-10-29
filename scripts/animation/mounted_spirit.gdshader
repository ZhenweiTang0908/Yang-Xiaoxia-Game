shader_type canvas_item;
uniform float seat_line = 1.0;
void fragment() {
 vec4 source = texture(TEXTURE, UV);
 float spill = min(source.r, source.b) - source.g;
 float key = 1.0 - smoothstep(0.12, 0.50, spill);
 if (spill > 0.10) COLOR.rgb = mix(COLOR.rgb, vec3(0.06, 0.10, 0.08), smoothstep(0.10, 0.35, spill));
 // Keep the pale blade core as well as its saturated green edge below the hips.
 bool blade = source.g > 0.4 && source.g > source.r * 1.015 && source.g > source.b * 1.015;
 COLOR.a *= key;
 if (source.a < 0.05 || (UV.y > seat_line && !blade)) { COLOR.a = 0.0; }
}
