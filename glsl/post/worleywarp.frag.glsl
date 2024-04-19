#version 150

uniform ivec2 u_Dimensions;
uniform float u_Time;

in vec2 fs_UV;

out vec3 color;

uniform sampler2D u_RenderedTexture;

vec2 random2(vec2 st) {
    st = vec2(dot(st, vec2(127.1, 311.7)), dot(st, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

float WorleyNoise(vec2 uv, out vec2 closestPoint) {
    uv *= 0.05;
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);
    float minDist = 1.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = random2(uvInt + neighbor);
            vec2 diff = neighbor + point - uvFract;
            float dist = length(diff);
            if (dist < minDist) {
                minDist = dist;
                closestPoint = uvInt + neighbor + point;
            }
        }
    }
    return minDist;
}

vec3 CellColor(vec2 point) {
    return vec3(
        fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453),
        fract(sin(dot(point, vec2(78.233, 12.9898))) * 43758.5453),
        fract(sin(dot(point, vec2(0.233, 1.9898))) * 43758.5453)
    );
}

vec3 EdgeDetection(vec2 uv) {
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

    vec3 gradientH = vec3(0.0);
    vec3 gradientV = vec3(0.0);

    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            vec2 offset = vec2(i, j) / vec2(u_Dimensions);
            vec3 color0 = texture(u_RenderedTexture, uv + offset).rgb;
            gradientH += color0 * kernelH[i + 1][j + 1];
            gradientV += color0 * kernelV[i + 1][j + 1];
        }
    }

    return sqrt(gradientH * gradientH + gradientV * gradientV);
}

void main() {
    vec2 closestPoint;
    float noiseValue = WorleyNoise(fs_UV * u_Dimensions, closestPoint);

    // Compute gradient of Worley Noise for edge effect
    float noiseValueXPlus = WorleyNoise((fs_UV + vec2(1.0/float(u_Dimensions.x), 0.0)) * u_Dimensions, closestPoint);
    float noiseValueYPlus = WorleyNoise((fs_UV + vec2(0.0, 1.0/float(u_Dimensions.y))) * u_Dimensions, closestPoint);
    vec2 gradient = vec2(noiseValueXPlus - noiseValue, noiseValueYPlus - noiseValue);

    float gradientMagnitude = length(gradient);
    float edgeHighlight = smoothstep(0.1, 2.5, gradientMagnitude);

    vec2 warpedUV = fs_UV + gradient * 2.0;
    vec3 originalColor = texture(u_RenderedTexture, warpedUV).rgb;

    vec3 normal = normalize(vec3(gradient, sqrt(1.0 - dot(gradient, gradient))));
    vec3 lightDir = normalize(vec3(0.5, 0.5, 1.0));
    float diffuse = max(dot(normal, lightDir), 0.0);

    // Compute specular reflection
    vec3 viewDir = vec3(0, 0, -1);
    vec3 reflectDir = reflect(viewDir, normal);
    float spec = pow(max(dot(reflectDir, lightDir), 0.0), 16.0); // 16.0 is the shininess factor; adjust as needed

    vec3 specularColor = spec * vec3(1.0);  // white specular highlights

    vec3 reflectionColor = originalColor * diffuse + specularColor;

    reflectionColor *= CellColor(closestPoint);

    vec3 aberration = vec3(
        texture(u_RenderedTexture, warpedUV + vec2(noiseValue, 0.1) * 0.05).r,
        texture(u_RenderedTexture, warpedUV).g,
        texture(u_RenderedTexture, warpedUV - vec2(noiseValue, 0.1) * 0.05).b
    );

    float crtEffect = 0.5 + 0.5 * cos(8.0 * fs_UV.y * u_Dimensions.y);
    vec3 crtColor = mix(reflectionColor, aberration, crtEffect);

    // Combine Worley noise effect with edge detection effect
    vec3 combinedColor = mix(crtColor, EdgeDetection(fs_UV), 0.5);

    color = mix(combinedColor, vec3(1.0, 1.0, 0), edgeHighlight);
}
