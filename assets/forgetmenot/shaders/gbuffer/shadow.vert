#include forgetmenot:shaders/lib/inc/header.glsl

uniform int frxu_cascade;

void frx_pipelineVertex() {
	frx_vertex += frx_modelToCamera;

	#ifdef TAA
		frx_vertex = frx_viewProjectionMatrix * frx_vertex;
		frx_vertex.xy += getTaaOffset(frx_renderFrames) * (1.0 / vec2(frx_viewWidth, frx_viewHeight)) * frx_vertex.w;
		frx_vertex = frx_inverseViewProjectionMatrix * frx_vertex;
	#endif

	gl_Position = frx_shadowViewProjectionMatrix(frxu_cascade) * frx_vertex;
}