shader_type canvas_item;
// Remove invalid red/yellow alpha-matte fringe; preserve the priest's ivory/purple paint.
void fragment() {
 vec4 source = texture(TEXTURE, UV);
 bool red_fringe = source.r > source.g * 1.7 && source.r > source.b * 1.5;
 bool yellow_fringe = source.r > 0.6 && source.g > 0.5 && source.b < 0.15;
 if (red_fringe || yellow_fringe) { COLOR.a = 0.0; }
}
