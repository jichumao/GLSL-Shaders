#version 150

uniform ivec2 u_Dimensions;
uniform int u_Time;

in vec2 fs_UV;

out vec3 color;

uniform sampler2D u_RenderedTexture;

vec2 random2(vec2 st){
    st = vec2( dot(st, vec2(127.1, 311.7)), dot(st, vec2(269.5, 183.3)) );
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

float WorleyNoise(vec2 uv) {
    uv *= 10.0;
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);
    float minDist = 1.0;
    for(int y = -1; y <= 1; ++y) {
        for(int x = -1; x <= 1; ++x) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = random2(uvInt + neighbor);
            vec2 diff = neighbor + point - uvFract;
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    return minDist;
}

void main()
{
    vec2 gradient;
    // Calculate the gradient of the Worley noise for the current fragment
    gradient.x = WorleyNoise(fs_UV + vec2(1.0/float(u_Dimensions.x), 0.0)) - WorleyNoise(fs_UV - vec2(1.0/float(u_Dimensions.x), 0.0));
    gradient.y = WorleyNoise(fs_UV + vec2(0.0, 1.0/float(u_Dimensions.y))) - WorleyNoise(fs_UV - vec2(0.0, 1.0/float(u_Dimensions.y)));

    // Warp the UV coordinates using the gradient, reduce the impact to show grid boundaries clearly
    vec2 warpedUV = fs_UV + gradient * 0.001;

    // Reduce the wave-like fluctuations to make the water effect more subtle
    float wave = sin(fs_UV.x * 2.0 + u_Time * 0.05) * sin(fs_UV.y * 2.0 + u_Time * 0.05) * 0.05; // Reduced the frequency and amplitude

    // Sample the original color from the texture
    vec3 originalColor = texture(u_RenderedTexture, warpedUV + wave).rgb;

    // Get the grid effect
    float noiseValue = WorleyNoise(fs_UV);
    vec3 gridEffectColor = originalColor * vec3(0.5 + cos(3.14 * noiseValue * 0.3));

    float flashDecision = fract(sin(dot(floor(warpedUV * 10.0 + vec2(u_Time * 0.25, u_Time * 0.25)), vec2(12.9898, 78.233))) * 43758.5453);
    float flashIntensity = step(0.7, flashDecision); // 30% chance of being 1, otherwise 0

    float timeBasedFlash = mod(u_Time, 50.0);
    flashIntensity *= step(0.0, timeBasedFlash) * (1 - step(25.0, timeBasedFlash));

    gridEffectColor *= (1.0 + flashIntensity * 0.3); // Brighten the color when flashing

    // Chromatic Aberration influenced by time
    float aberrationAmount = sin(u_Time * 0.2 ) * 2;
    vec3 redChannel = texture(u_RenderedTexture, warpedUV + vec2(gradient.x * aberrationAmount, 0)).rgb;
    vec3 greenChannel = texture(u_RenderedTexture, warpedUV).rgb;
    vec3 blueChannel = texture(u_RenderedTexture, warpedUV - vec2(gradient.x * aberrationAmount, 0)).rgb;

    // Combine the three channels to get the chromatic aberration effect
    vec3 chromaticColor = vec3(redChannel.r, greenChannel.g, blueChannel.b);

    // CRT-TV effect with alternating flicker
    float flicker = (sin(u_Time * 0.5) + 1.0) * 0.5;
    float crtEffect = 0.9 + 0.1 * sin(fs_UV.y * float(u_Dimensions.y) * 0.1) * flicker;

    // Blend the grid effect color, chromatic aberration effect, and CRT effect to get the final color
    color = mix(gridEffectColor, chromaticColor, 0.7) * crtEffect;
}
