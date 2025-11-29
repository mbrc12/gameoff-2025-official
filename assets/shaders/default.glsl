uniform mediump int blink;
uniform mediump vec3 blinkColor;

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL

vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 screen_coords) {
    vec4 pixel = Texel(tex, texcoord);
    if (pixel.a < 0.1) {
        discard;
    }
    if (blink > 0) {
        return vec4(blinkColor, 1.0) * 0.8 + pixel * 0.2;
    } else {
        return color * pixel;
    }
}

#endif
