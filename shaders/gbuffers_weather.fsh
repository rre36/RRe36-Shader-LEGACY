#version 120

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;

uniform sampler2D texture;

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
/* DRAWBUFFERS:7 */
	
	vec4 tex = texture2D(texture, texcoord.xy)*color;
	gl_FragData[0] = tex;
}