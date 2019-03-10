#version 120

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

//disabling is done by adding "//" to the beginning of a line.

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
const int RGB16 = 2;
const int gcolorFormat = RGB16;


//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 ambient_color;

uniform sampler2D depthtex0;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform sampler2D gcolor;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform ivec2 eyeBrightness;
uniform int isEyeInWater;
uniform int worldTime;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform int fogMode;
vec3 sunPos = sunPosition;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float timefract = worldTime;

float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
//Bloom
const float rMult = 0.0012;
const int nSteps = 21;


int center = (nSteps-1)/2;
float radius = center*rMult;

vec3 blur = vec3(0.0);
float tw = 0.0;

float sigma = 0.25;
float A = 1.0/sqrt(2.0*3.14159265359*sigma);


for (int i = 0; i < nSteps; i++) {

float dist = (i-float(center))/center;

float weight = A*exp(-(dist*dist)/(2.0*sigma));

blur += pow(texture2D(gaux2,texcoord.xy + rMult*vec2(1.0,aspectRatio)*vec2(i-center,0.0)).rgb,vec3(2.2))*weight;
tw += weight;
}
blur /= tw;
blur = pow(blur,vec3(1.0/2.2));
/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(blur,1.0);
}
