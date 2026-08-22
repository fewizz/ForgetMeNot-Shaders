/*
#include forgetmenot:shaders/lib/inc/raytrace.glsl

Contains the raytracer from lomo, provided by fewizz.
*/

bool raytrace(inout vec3 pos, vec3 dir, int steps, sampler2D depths, out float depth) {
	const int last_level = 8;
	const int level_step = 2;

	int level = 0;

	while (
		steps-- > 0
		&& all(lessThan(pos.xy, frxu_size))
		&& all(greaterThanEqual(pos.xy, vec2(0.0)))
		&& (depthIsReversed ? pos.z < depthNear : pos.z > depthNear)
	) {
		depth = texelFetch(depths, ivec2(pos.xy) >> level, max(0, level-1)).r;

		vec3 advance; {
			int cell_size = 1 << level; // 1, 4, 16, etc...
			vec2 position_in_cell = mod(pos.xy * sign(dir.xy), cell_size);
			vec2 dists_to_axis = cell_size - position_in_cell;
			vec2 diagonal_dists = dists_to_axis / abs(dir.xy);
			float dist = min(diagonal_dists.x, diagonal_dists.y);
			advance = max(dist, 0.001) * 1.001 * dir;
		}

		bool intersects = (
			(depthIsReversed ? dir.z < 0.0 : dir.z > 0.0) && (depthIsReversed ? pos.z + advance.z <= depth : pos.z + advance.z >= depth) ||
			(depthIsReversed ? dir.z > 0.0 : dir.z < 0.0) && (depthIsReversed ? pos.z <= depth : pos.z >= depth)
		);

		if (intersects) {
			if (level == 0) return true;
			advance *= max(sign(dir.z)*(depthIsReversed ? -1.0 : 1.0)*(depth - pos.z) / advance.z, 0.0); // to the hit point
		}

		pos += advance;
		level = clamp(level + (intersects ? -level_step : +level_step), 0, last_level);
	}

	return false;
}