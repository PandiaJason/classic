shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
void fragment() {
    vec4 color = textureLod(screen_texture, SCREEN_UV, blur_amount);
    COLOR = color * vec4(0.5, 0.5, 0.5, 1.0); // Darken the blurred background
}
