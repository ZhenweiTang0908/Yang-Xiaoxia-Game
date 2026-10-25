shader_type canvas_item;
void fragment() {
 vec4 tex = texture(TEXTURE, UV);
 float spill = min(tex.r, tex.b) - tex.g;
 float key = 1.0 - smoothstep(0.12, 0.50, spill);
 if (spill > 0.10) COLOR.rgb = mix(COLOR.rgb, vec3(0.06, 0.10, 0.08), smoothstep(0.10, 0.35, spill));
 COLOR *= vec4(1.0, 1.0, 1.0, key);
}
