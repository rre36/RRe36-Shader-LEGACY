#version 120

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

varying vec4 color;

uniform int fogMode;

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
	gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
	
/* DRAWBUFFERS:04 */
	
	gl_FragData[1] = vec4(0.0, 1.0, 0.0, 1.0);
	
}