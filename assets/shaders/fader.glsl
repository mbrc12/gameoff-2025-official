uniform mediump vec3 colorA;
uniform mediump vec3 colorB;
uniform mediump float radius;

const float WAVELENGTH = 5.0;

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
#COMMON

vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 screen_coords) {
    float dist = length(screen_coords - vec2(160.0, 90.0));
    if (dist < radius) {
        discard;
    }
    float s = (sin(dist / WAVELENGTH) + 1.0)/2.0;
    if (s > 0.8) {
        return vec4(colorB, 1.0);
    }
    return vec4(colorA, 1.0);
}

#endif
