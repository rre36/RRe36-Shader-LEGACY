#version 120
/*
!! DO NOT REMOVE !!
This code is from Chocapic13' shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/
varying vec2 lmcoord;
varying vec4 color;
varying float mat;
varying float dist;
varying vec2 texcoord;
varying vec4 vtexcoordam; // .st for add, .pq for mul
varying vec4 vtexcoord;

varying vec3 tangent;
varying vec3 normal;
varying vec3 binormal;
varying vec3 viewVector;

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int fogMode;
uniform int worldTime;
uniform float wetness;

const float mincoord = 1.0/4096.0;
const float maxcoord = 1.0-mincoord;

vec2 dcdx = dFdx(vtexcoord.st*vtexcoordam.pq);
vec2 dcdy = dFdy(vtexcoord.st*vtexcoordam.pq);


//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	vec2 adjustedTexCoord;
	adjustedTexCoord = vtexcoord.st*vtexcoordam.pq+vtexcoordam.st;

	float dirtest = 0.4;
	vec3 lightVector;

	vec4 frag2 = vec4(normal*0.5+0.5, 1.0f);
	
/* DRAWBUFFERS:024 */

	gl_FragData[0] = texture2D(texture, adjustedTexCoord)*color;
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4((lmcoord.t), 0.8, lmcoord.s, 1.0);

}