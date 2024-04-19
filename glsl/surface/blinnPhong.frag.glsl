#version 330

//This is a fragment shader. If you've opened this file first, please open and read lambert.vert.glsl before reading on.
//Unlike the vertex shader, the fragment shader actually does compute the shading of geometry.
//For every pixel in your program's output screen, the fragment shader is run for every bit of geometry that particular pixel overlaps.
//By implicitly interpolating the position data passed into the fragment shader by the vertex shader, the fragment shader
//can compute what color to apply to its pixel based on things like vertex position, light position, and vertex color.

uniform sampler2D u_Texture; // The texture to be read from by this shader

//These are the interpolated values out of the rasterizer, so you can't know
//their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec2 fs_UV;

in vec4 fs_CameraPos;
in vec4 fs_Pos;

layout(location = 0) out vec3 out_Col;//This is the final output color that you will see on your screen for the pixel that is currently being processed.

void main()
{
    // normalization
    vec3 N = normalize(fs_Nor.xyz);
    vec3 L = normalize(fs_LightVec.xyz);

    // the view unit vector
    vec3 V = normalize(fs_CameraPos.xyz - fs_Pos.xyz);

    // Compute halfway vector
    vec3 H = normalize(V + L);

    // Compute diffuse term
    float lambert = max(dot(N, L), 0.0);

    // Compute specular term
    float specularIntensity = pow(max(dot(H, N), 0.0), 256.0);

    vec3 ambientColor = vec3(0.1);
    vec3 diffuseColor = lambert * vec3(1.0);
    vec3 specularColor = specularIntensity * vec3(1.0);

    vec3 textureColor = texture(u_Texture, fs_UV).rgb;

    out_Col = textureColor * (ambientColor + diffuseColor) + specularColor;
}
