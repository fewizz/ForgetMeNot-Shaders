#include forgetmenot:shaders/lib/inc/header.glsl
#include forgetmenot:shaders/lib/inc/exposure.glsl
#include forgetmenot:shaders/lib/inc/noise.glsl

#include can-pipe:shaders/compat/hdrmod.glsl

uniform sampler2D u_color;
uniform sampler2D u_exposure;

in vec2 texcoord;
in float exposure;

layout(location = 0) out vec4 fragColor;

float getExposureValue() {
	return getExposureValue(exposure);
}

// Post-processing stuff, provided by belmu
vec3 vibrance(vec3 color, float intensity) {
	float mn = min(color.r, min(color.g, color.b));
	float mx = max(color.r, max(color.g, color.b));
	float sat = (1.0 - clamp01(mx - mn)) * clamp01(1.0 - mx) * frx_luminance(color) * 5.0;
	vec3 lightness = vec3((mn + mx) * 0.5);

	// Vibrance
	color = mix(color, mix(lightness, color, intensity), sat);
	// Negative vibrance
	color = mix(color, lightness, (1.0 - lightness) * (1.0 - intensity) * 0.5 * abs(intensity));

	return color;
}

// http://filmicworlds.com/blog/minimal-color-grading-tools/
// component-wise
float liftGammaGain(float color, float lift, float gamma, float gain) {
	float lerpV = clamp01(pow(color, gamma));
	color = gain * lerpV + lift * (1.0 - lerpV);

	return color;
}

// Lottes 2016, "Advanced Techniques and Optimization of HDR Color Pipelines"
// https://www.desmos.com/calculator/rbawjul014
vec3 lottes(vec3 x, vec2 whitePoint) {
	const vec3 a = vec3(1.6);
	const vec3 d = vec3(0.977);

	const vec3 midIn = vec3(0.18);
	const vec3 midOut = vec3(0.267);

	vec3 whiteIn = vec3(whitePoint.x);
	vec3 whiteOut = vec3(whitePoint.y);

	vec3 b =
		(pow(whiteIn, a) * midOut - pow(midIn, a) * whiteOut) /
		((pow(whiteIn, a * d) - pow(midIn, a * d)) * midOut * whiteOut);
	vec3 c =
		(pow(whiteIn, a * d) * pow(midIn, a) * whiteOut - pow(whiteIn, a) * pow(midIn, a * d) * midOut) /
		((pow(whiteIn, a * d) - pow(midIn, a * d)) * midOut * whiteOut);

	return pow(x, a) / (pow(x, a * d) * b + c);
}

vec3 bt709ToOklab(vec3 color) {
	vec3 lms = mat3(
		0.4122214708f, 0.2119034982f, 0.0883024619f,
		0.5363325363f, 0.6806995451f, 0.2817188376f,
		0.0514459929f, 0.1073969566f, 0.6299787005f
	) * color;
	lms = pow(abs(lms), vec3(1.0/3.0)) * sign(lms);
	return mat3(
		0.2104542553f, 1.9779984951f, 0.0259040371f,
		0.7936177850f, -2.4285922050f, 0.7827717662f,
		-0.0040720468f, 0.4505937099f, -0.8086757660f
	) * lms;
}

// from https://github.com/clshortfuse/renodx/blob/66f4a40362cd7840bc0647734c434670539addb0/src/shaders/color/oklab.hlsl#L10
vec3 oklabToBt709(vec3 color) {
	vec3 lms = mat3(
		1.f, 1.f, 1.f,
		0.3963377774f, -0.1055613458f, -0.0894841775f,
		0.2158037573f, -0.0638541728f, -1.2914855480f
	) * color;
	lms = lms * lms * lms;
	return mat3(
		4.0767416621f, -1.2684380046f, -0.0041960863f,
		-3.3077115913f, 2.6097574011f, -0.7034186147f,
		0.2309699292f, -0.3413193965f, 1.7076147010f
	) * lms;
}


vec3 sRGB_EncodeSafe(vec3 c) {
	//Save sign for Wide Color Gamut
	vec3 s = sign(c);
	c = abs(c);

	//sRGB
	bvec3 cutoff = lessThan(c, vec3(0.0031308));
	vec3 higher = vec3(1.055) * pow(c, vec3(1.0 / 2.4)) - vec3(0.055);
	vec3 lower = c * vec3(12.92);
	c = mix(higher, lower, cutoff);

	//Restore Sign
	return c * s;
}

void main() {
	initGlobals();

	vec3 color = texture(u_color, texcoord).rgb;

	// Purkinje effect
	float purkinjeFactor = clamp01(1.0 - exp2(-frx_luminance(color * 40.0)));
	color = mix(color, saturation(color, 0.0) * vec3(0.5, 1.2, 1.8) + PURKINJE_LIFT, (1.0 - purkinjeFactor) * PURKINJE_AMOUNT);

	#ifdef ENABLE_BLOOM
		color *= getExposureValue() * getExposureProfile().exposureMultiplier;
	#endif

	#define WHITE_POINT 8.0

	//#define DEBUG_POST_PROCESSING
	#ifdef DEBUG_POST_PROCESSING
		float _contrast = 1.0;
		float _saturation = 1.0;
		float _vibrance = 1.0;

		vec3 lift = vec3(0.0, 0.0, 0.0);
		vec3 gamma = vec3(1.0, 1.0, 1.0);
		vec3 gain = vec3(1.0, 1.0, 1.0);

		#define CONTRAST _contrast
		#define SATURATION _saturation
		#define VIBRANCE _vibrance

		#define LIFT_R lift.r
		#define LIFT_G lift.g
		#define LIFT_B lift.b

		#define GAMMA_R gamma.r
		#define GAMMA_G gamma.g
		#define GAMMA_B gamma.b

		#define GAIN_R gain.r
		#define GAIN_G gain.g
		#define GAIN_B gain.b
	#endif

	#if CAMERA_PRESET == PRESET_MOODY
		#define WHITE_POINT 4.0

		#define CONTRAST 1.15
		#define SATURATION 0.85
		#define VIBRANCE 1.0

		vec3 lift = vec3(0.0, 0.0, 0.0);
		vec3 gamma = vec3(1.0, 1.0, 1.0);
		vec3 gain = vec3(1.0, 1.0, 1.0);

		#define LIFT_R lift.r
		#define LIFT_G lift.g
		#define LIFT_B lift.b

		#define GAMMA_R gamma.r
		#define GAMMA_G gamma.g
		#define GAMMA_B gamma.b

		#define GAIN_R gain.r
		#define GAIN_G gain.g
		#define GAIN_B gain.b
	#endif

	#ifdef ENABLE_POST_PROCESSING
		// Contrast in log-scale to preserve more color detail
		color = log(color);
		color = contrast(color, CONTRAST);
		color = exp(color);

		color = saturation(color, SATURATION);
	#endif

	#if defined HDRMOD
		float peak = hdrmod_gamePeakBrightness / hdrmod_gamePaperWhiteBrightness;
	#else
		float peak = 1.0;
	#endif

	#if defined ACES_TONEMAP
		#if defined HDRMOD
			vec3 acesColor = max(frx_toneMap(color), vec3(0.0));
			color = lottes(color * 0.5, vec2(WHITE_POINT, peak));

			// hue correction
			// https://github.com/clshortfuse/renodx/blob/66f4a40362cd7840bc0647734c434670539addb0/src/shaders/colorcorrect.hlsl#L163
			vec3 colorOklab = bt709ToOklab(color);
			vec3 acesColorOklab = bt709ToOklab(acesColor);
			colorOklab.yz = acesColorOklab.yz;
			color = oklabToBt709(colorOklab);

			color = max(color, vec3(0.0));
		#else
			color = frx_toneMap(color);
		#endif
	#else
		color = lottes(color * 0.45, vec2(WHITE_POINT, peak));
	#endif

	// TODO
	#if 0 && defined ENABLE_POST_PROCESSING
		color = vibrance(color, VIBRANCE);

		// Lift-gamma-gain component-wise
		color.r = clamp01(liftGammaGain(color.r, LIFT_R, GAMMA_R, GAIN_R));
		color.b = clamp01(liftGammaGain(color.b, LIFT_G, GAMMA_G, GAIN_G));
		color.g = clamp01(liftGammaGain(color.g, LIFT_B, GAMMA_B, GAIN_B));
	#endif

	#if defined HDRMOD
		color *= hdrmod_gamePaperWhiteBrightness / hdrmod_uiBrightness;
		color = sRGB_EncodeSafe(color);
	#else
		color = clamp01(color);
		color = pow(color, vec3(1.0 / 2.2));
	#endif

	fragColor = vec4(color, 1.0);
}