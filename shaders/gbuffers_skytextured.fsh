#version 120

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

/* DRAWBUFFERS:0 */

uniform sampler2D texture;

varying vec4 color;
varying vec2 texcoord;



const int FOGMODE_LINEAR = 9729;
const int FOGMODE_EXP = 2048;

uniform int fogMode;

void main() {

	gl_FragData[0] = texture2D(texture,texcoord.xy)*color;
	float fogFactor;
	if (fogMode == FOGMODE_EXP) {
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0);
	} else if (fogMode == FOGMODE_LINEAR) {
		fogFactor = 1.0 - clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0);
	} else {
		fogFactor = 1.0;
	}
	gl_FragData[0] = mix(gl_FragData[0],gl_Fog.color,1.0-fogFactor);
}