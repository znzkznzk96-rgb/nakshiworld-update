shader_type canvas_item;
render_mode unshaded;
void fragment(){
    vec4 moon=texture(TEXTURE,UV)*COLOR;
    // Trim isolated alpha specks outside the disk without altering source pixels.
    moon.a*=1.0-smoothstep(0.449,0.455,length(UV-vec2(0.5)));
    COLOR=moon;
}
