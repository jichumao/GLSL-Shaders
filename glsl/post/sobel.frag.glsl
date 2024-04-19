#version 150

in vec2 fs_UV;

out vec3 color;

uniform sampler2D u_RenderedTexture;
uniform int u_Time;
uniform ivec2 u_Dimensions;

const mat3 kernelH = mat3(
    3.0,  0.0, -3.0,
    10.0, 0.0, -10.0,
    3.0,  0.0, -3.0
);

const mat3 kernelV = mat3(
    3.0,  10.0, 3.0,
    0.0,  0.0,  0.0,
    -3.0, -10.0, -3.0
);

void main()
{

    vec3 gradientH = vec3(0.0);
    vec3 gradientV = vec3(0.0);

    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            vec2 offset = vec2(i, j) / vec2(u_Dimensions);

            vec3 color0 = texture(u_RenderedTexture, fs_UV + offset).rgb;
            gradientH += color0 * kernelH[i + 1][j + 1];
            gradientV += color0 * kernelV[i + 1][j + 1];
        }
    }

    vec3 gradientMagnitude = sqrt(gradientH * gradientH + gradientV * gradientV);
    color = gradientMagnitude;
}
