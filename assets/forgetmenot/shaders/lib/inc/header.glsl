#include frex:shaders/api/header.glsl

#include frex:shaders/api/fog.glsl
#include frex:shaders/api/sampler.glsl

#include frex:shaders/api/player.glsl
#include frex:shaders/api/view.glsl
#include frex:shaders/api/world.glsl

#include frex:shaders/lib/face.glsl
#include frex:shaders/lib/math.glsl
#include frex:shaders/lib/color.glsl

#include frex:shaders/lib/sample.glsl

#include frex:shaders/lib/noise/noise2d.glsl
#include frex:shaders/lib/noise/noise3d.glsl
#include frex:shaders/lib/noise/cellular2d.glsl
#include frex:shaders/lib/noise/cellular3d.glsl
#include frex:shaders/lib/noise/cellular2x2x2.glsl

uniform ivec2 frxu_size;
uniform int frxu_lod;

// Offsets from Chocapic13 shaders
const vec2[] TAA_OFFSETS = vec2[8] (
	vec2( 0.125,-0.375),
	vec2(-0.125, 0.375),
	vec2( 0.625, 0.125),
	vec2( 0.375,-0.625),
	vec2(-0.625, 0.625),
	vec2(-0.875,-0.125),
	vec2( 0.375,-0.875),
	vec2( 0.875, 0.875)
);

vec2 getTaaOffset(in uint frame) {
	return TAA_OFFSETS[frame % 8u];
}

#include forgetmenot:general
#include forgetmenot:seasons
#include forgetmenot:misc

// These will always be needed
#include forgetmenot:shaders/lib/inc/utility.glsl 
#include forgetmenot:shaders/lib/inc/general.glsl 
#include forgetmenot:shaders/lib/inc/palette.glsl 

// Global utility variables
float fmn_rainFactor;
float fmn_time;

bool isModdedDimension;

// Should be called in every program that uses these variables
void init() {
	fmn_rainFactor = frx_smoothedRainGradient * 0.5 + frx_smoothedThunderGradient * 0.5;
	fmn_time = mod(frx_renderSeconds, 4000.0);

	isModdedDimension = frx_worldIsOverworld + frx_worldIsNether + frx_worldIsEnd == 0;
}