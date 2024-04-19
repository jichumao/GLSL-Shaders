#version 150

in vec2 fs_UV;

out vec3 color;

uniform sampler2D u_RenderedTexture;

void main()
{

    vec3 originalColor = texture(u_RenderedTexture, fs_UV).rgb;

    float grey = dot(originalColor, vec3(0.21, 0.72, 0.07));

    vec2 center = vec2(0.5, 0.5);
    float dist = distance(fs_UV, center);
    float vignette = smoothstep(0.1, 0.707, dist);

    color = mix(vec3(grey), vec3(0, 0, 0), vignette);

}
