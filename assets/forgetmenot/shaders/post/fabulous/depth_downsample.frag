#include forgetmenot:shaders/lib/inc/header.glsl
#include forgetmenot:shaders/lib/inc/space.glsl

uniform sampler2D u_depth_mips;

layout(location = 0) out float out_depth;

void main() {
	initGlobals();

	const int power_of_two = 2;
	const int cell_size = 1 << power_of_two;
	int prev_lod = max(0, frxu_lod - power_of_two);
	ivec2 prev_texture_size = textureSize(u_depth_mips, prev_lod);

	float depth = depthFar;

	for(int x = 0; x < cell_size; ++x) {
		for(int y = 0; y < cell_size; ++y) {
			ivec2 prev_pos = ivec2(gl_FragCoord.xy) << power_of_two;
			prev_pos += ivec2(x, y);
			if (any(greaterThanEqual(prev_pos, prev_texture_size))) {
				continue;
			}
			depth =
				depthIsReversed ?
				max(
					depth,
					texelFetch(u_depth_mips, prev_pos, prev_lod).r
				) :
				min(
					depth,
					texelFetch(u_depth_mips, prev_pos, prev_lod).r
				);
		}
	}

	out_depth = depth;
}