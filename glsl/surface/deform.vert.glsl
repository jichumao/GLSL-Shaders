#version 150

uniform mat4 u_Model;
uniform mat3 u_ModelInvTr;
uniform mat4 u_View;
uniform mat4 u_Proj;

uniform int u_Time;

in vec4 vs_Pos;
in vec4 vs_Nor;

out vec3 fs_Pos;
out vec3 fs_Nor;

void main()
{
    // TODO Homework 4
    fs_Nor = normalize(u_ModelInvTr * vec3(vs_Nor));

    float radius = 1.0 + 0.5 * sin(float(u_Time) * 0.01);
    vec3 spherePos = normalize(vec3(vs_Pos)) * radius;
    vec3 interpolatedPos = mix(vec3(vs_Pos), spherePos, 0.5 * (1.0 + sin(float(u_Time) * 0.01)));

    vec4 modelposition = u_Model * vec4(interpolatedPos, 1.0);
    fs_Pos = vec3(modelposition);
    gl_Position = u_Proj * u_View * modelposition;
}
