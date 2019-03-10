#version 120

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

#define WAVING_LEAVES
//#define WAVING_VINES
#define WAVING_GRASS
#define WAVING_WHEAT
#define WAVING_FLOWERS
#define WAVING_FIRE
#define WAVING_LAVA
#define WAVING_LILYPAD

#define ENTITY_LEAVES        18.0
#define ENTITY_VINES        106.0
#define ENTITY_TALLGRASS     31.0
#define ENTITY_DANDELION     37.0
#define ENTITY_ROSE          38.0
#define ENTITY_WHEAT         59.0
#define ENTITY_LILYPAD      111.0
#define ENTITY_FIRE          51.0
#define ENTITY_LAVAFLOWING   10.0
#define ENTITY_LAVASTILL     11.0

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



const float PI = 3.1415927;

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;
varying float translucent;

varying vec3 tangent;
varying vec3 normal;
varying vec3 binormal;
varying vec3 viewVector;

attribute vec4 mc_Entity;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;
uniform float rainStrength;

float pi2wt = PI*2*(frameTimeCounter*24);

vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5) {
    vec3 ret;
    float magnitude,d0,d1,d2,d3;
    magnitude = sin(pi2wt*fm + pos.x*0.5 + pos.z*0.5 + pos.y*0.5) * mm + ma;
    d0 = sin(pi2wt*f0);
    d1 = sin(pi2wt*f1);
    d2 = sin(pi2wt*f2);
    ret.x = sin(pi2wt*f3 + d0 + d1 - pos.x + pos.z + pos.y) * magnitude;
    ret.z = sin(pi2wt*f4 + d1 + d2 + pos.x - pos.z + pos.y) * magnitude;
	ret.y = sin(pi2wt*f5 + d2 + d0 + pos.z + pos.y - pos.y) * magnitude;
    return ret;
}

vec3 calcMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    vec3 move1 = calcWave(pos      , 0.0027, 0.0400, 0.0400, 0.0127, 0.0089, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
	vec3 move2 = calcWave(pos+move1, 0.0348, 0.0400, 0.0400, f0, f1, f2, f3, f4, f5) * amp2;
    return move1+move2;
}

vec3 calcWaterMove(in vec3 pos) {
	float fy = fract(pos.y + 0.001);
	
	if (fy > 0.002) {
		float wave = 0.05 * sin(2 * PI * (worldTime / 86.0 + pos.x /  7.0 + pos.z / 13.0))
					+ 0.05 * sin(2 * PI * (worldTime / 60.0 + pos.x / 11.0 + pos.z /  5.0));
		return vec3(0, clamp(wave, -fy, 1.0-fy), 0);
	}
	
	else {
		return vec3(0);
	}
}

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	
	texcoord = (gl_MultiTexCoord0).xy;
	
	translucent = 0.0f;

	bool istopv = gl_MultiTexCoord0.t < gl_MultiTexCoord3.t;

	/* un-rotate */
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec3 worldpos = position.xyz + cameraPosition;
	
	//initialize per-entity waving parameters
	float parm0,parm1,parm2,parm3,parm4,parm5 = 0.0;
	vec3 ampl1,ampl2;
	ampl1 = vec3(0.0);
	ampl2 = vec3(0.0);
	
#ifdef WAVING_LEAVES
	if ( mc_Entity.x == ENTITY_LEAVES ) {
			parm0 = 0.0040;
			parm1 = 0.0064;
			parm2 = 0.0043;
			parm3 = 0.0035;
			parm4 = 0.0037;
			parm5 = 0.0041;
			ampl1 = vec3(1.0,0.2,1.0);
			ampl2 = vec3(0.5,0.1,0.5);
			}
#endif
	
#ifdef WAVING_VINES
	if ( mc_Entity.x == ENTITY_VINES ) {
			parm0 = 0.0040;
			parm1 = 0.0064;
			parm2 = 0.0043;
			parm3 = 0.0035;
			parm4 = 0.0037;
			parm5 = 0.0041;
			ampl1 = vec3(1.0,0.2,1.0);
			ampl2 = vec3(0.5,0.1,0.5);
			}
			
#endif
	
#ifdef WAVING_GRASS
	if ( mc_Entity.x == ENTITY_TALLGRASS && istopv ) {
			parm0 = 0.0041;
			parm1 = 0.0070;
			parm2 = 0.0044;
			parm3 = 0.0038;
			parm4 = 0.0063;
			parm5 = 0.0;
			ampl1 = vec3(0.8,0.0,0.8);
			ampl2 = vec3(0.4,0.0,0.4);
			}
#endif
	
#ifdef WAVING_FLOWERS
	if ((mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE) && istopv ) {
			parm0 = 0.0041;
			parm1 = 0.005;
			parm2 = 0.0044;
			parm3 = 0.0038;
			parm4 = 0.0240;
			parm5 = 0.0;
			ampl1 = vec3(0.8,0.0,0.8);
			ampl2 = vec3(0.4,0.0,0.4);
			}
#endif
	
#ifdef WAVING_WHEAT
	if ( mc_Entity.x == ENTITY_WHEAT && istopv ) {
			parm0 = 0.0041;
			parm1 = 0.0070;
			parm2 = 0.0044;
			parm3 = 0.0240;
			parm4 = 0.0063;
			parm5 = 0.0;
			ampl1 = vec3(0.8,0.0,0.8);
			ampl2 = vec3(0.4,0.0,0.4);
			}
#endif
	
#ifdef WAVING_FIRE
	if ( mc_Entity.x == ENTITY_FIRE && istopv ) {
			parm0 = 0.0105;
			parm1 = 0.0096;
			parm2 = 0.0087;
			parm3 = 0.0063;
			parm4 = 0.0097;
			parm5 = 0.0156;
			ampl1 = vec3(1.2,0.4,1.2);
			ampl2 = vec3(0.8,0.8,0.8);
			}				
#endif
	float movemult = 0.0;
#ifdef WAVING_LAVA
	if ( mc_Entity.x == ENTITY_LAVAFLOWING || mc_Entity.x == ENTITY_LAVASTILL )	movemult = 0.25;

#endif
	
#ifdef WAVING_LILYPAD
	if ( mc_Entity.x == ENTITY_LILYPAD )  movemult = 1.0;
#endif

	position.xyz += calcWaterMove(worldpos.xyz) * movemult;
	position.xyz += calcMove(worldpos.xyz, parm0, parm1, parm2, parm3, parm4, parm5, ampl1, ampl2);
	
	if (mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == ENTITY_VINES || mc_Entity.x == ENTITY_TALLGRASS || mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE || mc_Entity.x == ENTITY_WHEAT || mc_Entity.x == 30.0 || mc_Entity.x == 115.0 || mc_Entity.x == 32.0)
	
	translucent = 1.0;
	
	/* re-rotate */
	
	/* projectify */
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	
	color = gl_Color;
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	
	normal = normalize(gl_NormalMatrix * gl_Normal);
	
		 tangent = vec3(0.0);
	 binormal = vec3(0.0);
	 normal = normalize(gl_NormalMatrix * gl_Normal);

	if (gl_Normal.x > 0.5) {
		//  1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0, -1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.x < -0.5) {
		// -1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.y > 0.5) {
		//  0.0,  1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	} else if (gl_Normal.y < -0.5) {
		//  0.0, -1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	} else if (gl_Normal.z > 0.5) {
		//  0.0,  0.0,  1.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.z < -0.5) {
		//  0.0,  0.0, -1.0
		tangent  = normalize(gl_NormalMatrix * vec3(-1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								  tangent.y, binormal.y, normal.y,
						     	  tangent.z, binormal.z, normal.z);
	
	
	viewVector = (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewVector = normalize(tbnMatrix * viewVector);
}