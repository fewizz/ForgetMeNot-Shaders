float smoothHash(in vec2 st) {
	vec2 p = floor(st);
	vec2 f = fract(st);
		
	float n = p.x + p.y*57.0;

	float a =  hash11((n + 0.0)) * 2.0 - 1.0;
	float b =  hash11((n + 1.0)) * 2.0 - 1.0;
	float c = hash11((n + 57.0)) * 2.0 - 1.0;
	float d = hash11((n + 58.0)) * 2.0 - 1.0;
	
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;
	
	vec2 t = 3.0 * f2 - 2.0 * f3;
	
	float u = t.x;
	float v = t.y;

	float noise = a + (b - a) * u +(c - a) * v + (a - b + d - c) * u * v;
    // float noise = mix(a, b, f.x) + (c - a) * f.y * (1.0 - f.x) + (d - b) * f.x * f.y;

    return noise;
}

const mat2 fbmRot = mat2(cos(PI / 6.0), sin(PI / 6.0), -sin(PI / 6.0), cos(PI / 6.0));

float fbmHash(vec2 uv, int octaves) {
	float noise = 0.01;
	float amp = 0.5;

	for (int i = 0; i < octaves; i++) {
		noise += amp * (smoothHash(uv) * 0.5 + 0.51);
		uv = fbmRot * uv * 2.0 + mod(fmn_time / 10.0, 1000.0);
		amp *= 0.5;
	}

    return noise;
}
float fbmHash(vec2 uv, int octaves, float t) {
	float noise = 0.01;
	float amp = 0.5;

	for (int i = 0; i < octaves; i++) {
		noise += amp * (smoothHash(uv) * 0.5 + 0.51);
		uv = fbmRot * uv * 2. + mod(fmn_time * t, 1000.0);
		amp *= 0.5;
	}

    return noise;
}

// Thanks SixthSurge#3922 for helping me with curl noise which makes clouds much nicer!
vec2 curlNoise(in vec2 plane) {
    const float offset = 1e-3;
    float dx = snoise(plane + vec2(offset, 0.0));
    dx -= snoise(plane - vec2(offset, 0.0));
    dx /= 2.0 * offset;

    float dy = snoise(plane + vec2(0.0, offset));
    dy -= snoise(plane - vec2(0.0, offset));
    dy /= 2.0 * offset;

    return vec2(-dy, dx);
}

vec2 fbmCurl(in vec2 plane, in int octaves) {
    vec2 noise = vec2(0.01);
    float amp = 0.5;

    mat2 rotationMatrix = mat2(cos(PI / 6.0), sin(PI / 6.0), -sin(PI / 6.0), cos(PI / 6.0));

    for(int i = 0; i < octaves; i++) {
        noise += amp * curlNoise(plane);
        plane = rotationMatrix * plane;
        amp *= 0.5;
    }

    return noise * ((octaves + 1.0) / octaves);
}

#ifndef VERTEX_SHADER
    vec3 goldNoise3d() {
        float seed = mod(frx_renderSeconds, 10.0);
        vec3 r = vec3(
            gold_noise(gl_FragCoord.xy, seed),
            gold_noise(gl_FragCoord.xy, seed + 1.0),
            gold_noise(gl_FragCoord.xy, seed + 2.0)
        );
        r = (r) * 2.0 - 1.0;
        return normalize(r);
    }
    vec3 goldNoise3d(float seed) {
        seed += mod(frx_renderSeconds, 10.0);

        vec3 r = vec3(
            gold_noise(gl_FragCoord.xy, seed),
            gold_noise(gl_FragCoord.xy, seed + 1.0),
            gold_noise(gl_FragCoord.xy, seed + 2.0)
        );
        r = (r) * 2.0 - 1.0;
        return normalize(r);
    }
    vec3 goldNoise3d_noiseless(float seed) {
        vec3 r = vec3(
            gold_noise(vec2(0.5), seed),
            gold_noise(vec2(0.5), seed + 1.0),
            gold_noise(vec2(0.5), seed + 2.0)
        );
        r = (r) * 2.0 - 1.0;
        return normalize(r);
    }

    // Thanks Belmu#4066 for helping me solve the issues with my variable penumbra shadows!
    vec2 sincos(float x) {
        return vec2(sin(x), cos(x));
    }
    vec2 diskSampling(float i, float n, float phi){
        float theta = (i + phi) / n; 
        return sincos(theta * TAU * n * 1.618033988749894) * theta;
    }


    // -----------------------------------------------------------------------------------------------
    // From belmu#4066
    // Noise distribution: https://www.pcg-random.org/
    void pcg(inout uint seed) {
        uint state = seed * 747796405u + 2891336453u;
        uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
        seed = (word >> 22u) ^ word;
    }

    uint rngState = 185730u * frx_renderFrames + uint(gl_FragCoord.x + gl_FragCoord.y * frxu_size.x);
    float randF() { pcg(rngState); return float(rngState) / float(0xffffffffu); }

    // From Jessie
    vec3 generateUnitVector(vec2 xy) {
        xy.x *= TAU; xy.y = 2.0 * xy.y - 1.0;
        return vec3(sincos(xy.x) * sqrt(1.0 - xy.y * xy.y), xy.y);
    }

    vec3 generateCosineVector(vec3 vector, vec2 xy) {
        return normalize(vector + generateUnitVector(xy));
    }
    // -----------------------------------------------------------------------------------------------

    vec3 generateCosineVector(vec3 vector) {
        return normalize(
            vector + 
            generateUnitVector(
                vec2(
                        randF(), randF()
                )
            )
        );
    }
    vec3 generateCosineVector(vec3 vector, float roughness) {
        return mix(vector, generateCosineVector(vector), roughness);
    }

#else
    vec3 goldNoise3d(float seed) {
        vec3 r = vec3(
            gold_noise(vec2(100.0), seed),
            gold_noise(vec2(1.0), seed + 1.0),
            gold_noise(vec2(1.0), seed + 2.0)
        );
        r = (r) * 2.0 - 1.0;
        return r;
    }
#endif