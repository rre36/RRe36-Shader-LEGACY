#version 120
/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

//-------- Adjustable Variables --------//

	//---- Waving Effects ----//
		#define WAVING_LEAVES
		#define WAVING_VINES
		#define WAVING_GRASS
		#define WAVING_WHEAT
		#define WAVING_FLOWERS
		#define WAVING_FIRE
		#define WAVING_LAVA
		#define WAVING_LILYPAD
		#define WAVING_TALLGRASS
		#define WAVING_REEDS
		
	//---- End of Waving Effects ----//
	
	//---- Entity IDs ----//
		#define ENTITY_LEAVES        18.0
		#define ENTITY_VINES        106.0
		#define ENTITY_TALLGRASS     31.0
		#define ENTITY_DANDELION     37.0
		#define ENTITY_ROSE          38.0
		#define ENTITY_WHEAT     59.0
		#define ENTITY_LILYPAD      111.0
		#define ENTITY_FIRE          51.0
		#define ENTITY_LAVAFLOWING   10.0
		#define ENTITY_LAVASTILL     11.0
		#define ENTITY_SAPLING     6.0
		
	//---- End of Entity IDs ----//


	//---- World Effects -----//
		//#define WORLD_CURVATURE												// will cause bug at high shadowdistances: looks like a dark circle around you
			const float WORLD_RADIUS         = 6000.0;						//Increase for a stronger rounded world
			const float WORLD_RADIUS_SQUARED = 15000000.0;
			
	//---- End of World Effects ----//

//-------- End of Adjustable Variables --------//



const float PI = 3.1415927;

varying vec4 color;
varying vec2 lmcoord;
varying float translucent;
varying vec4 vtexcoordam; // .st for add, .pq for mul
varying vec4 vtexcoord;

varying float dist;

varying vec3 tangent;
varying vec3 normal;
varying vec3 binormal;
varying vec3 viewVector;

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;
uniform float rainStrength;

float timefract = worldTime;

//Calculate Time of Day
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

float animationTime = worldTime/20.0f;

float pi2wt = PI*2*(frameTimeCounter*24 + (rainStrength*2));

vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5) {
    vec3 ret;
    float magnitude,d0,d1,d2,d3;
    magnitude = sin(pi2wt*fm + pos.x*0.5 + pos.z*0.5 + pos.y*0.5) * mm + ma;
    d0 = sin(pi2wt*f0)*(rainStrength*2);
    d1 = sin(pi2wt*f1)*(rainStrength*1.75);
    d2 = sin(pi2wt*f2)*(rainStrength*1.5);
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
	vec2 texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	vec2 midcoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texcoordminusmid = texcoord-midcoord;
	vtexcoordam.pq  = abs(texcoordminusmid)*2;
	vtexcoordam.st  = min(texcoord,midcoord-texcoordminusmid);
	vtexcoord.st    = sign(texcoordminusmid)*0.5+0.5;
	
	translucent = 0.0f;
	
	
	float istopv = 0.0;
	if (gl_MultiTexCoord0.t < mc_midTexCoord.t) istopv = 1.0;
	/* un-rotate */
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec3 worldpos = position.xyz + cameraPosition;
	
	//initialize per-entity waving parameters
	float parm0,parm1,parm2,parm3,parm4,parm5 = rainStrength*4;
	vec3 ampl1,ampl2;
	ampl1 = vec3(0.0);
	ampl2 = vec3(0.0);
	
#ifdef WAVING_LEAVES
	if (( mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == 161 )) {
			parm0 = 0.0040;
			parm1 = 0.0064;
			parm2 = 0.0043;
			parm3 = 0.0035;
			parm4 = 0.0037;
			parm5 = 0.0041;
			ampl1 = vec3(1.0,0.2,1.0) + rainStrength/4;
			ampl2 = vec3(0.5,0.1,0.5) + rainStrength/4;
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

#ifdef WAVING_REEDS
	if ( mc_Entity.x == 83 ) {
			parm0 = 0.0024;
			parm1 = 0.0020;
			parm2 = 0.0016;
			parm3 = 0.0010;
			parm4 = 0.0009;
			parm5 = 0.0002;
			ampl1 = vec3(0.25,0.05,0.25) + rainStrength/5;
			ampl2 = vec3(0.125,0.025,0.125) + rainStrength/5;
			}
			
#endif
		if (istopv > 0.9) {
#ifdef WAVING_GRASS
	if ( mc_Entity.x == ENTITY_TALLGRASS || mc_Entity.x == ENTITY_SAPLING) {
			parm0 = 0.0041;
			parm1 = 0.0070;
			parm2 = 0.0044;
			parm3 = 0.0038;
			parm4 = 0.0063;
			parm5 = 0.0;
			ampl1 = vec3(0.8,0.0,0.8) + 0.2 + rainStrength/3;
			ampl2 = vec3(0.4,0.0,0.4) + 0.2 + rainStrength/3;
			}
#endif
	
#ifdef WAVING_FLOWERS
	if ((mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE)) {
			parm0 = 0.0041;
			parm1 = 0.005;
			parm2 = 0.0044;
			parm3 = 0.0038;
			parm4 = 0.0240;
			parm5 = 0.0;
			ampl1 = vec3(0.8,0.0,0.8) + rainStrength/3;
			ampl2 = vec3(0.4,0.0,0.4) + rainStrength/3;
			}
#endif
	
#ifdef WAVING_WHEAT
	if ( mc_Entity.x == ENTITY_WHEAT  || mc_Entity.x == 141  || mc_Entity.x == 142) {
			parm0 = 0.0041;
			parm1 = 0.0070;
			parm2 = 0.0044;
			parm3 = 0.0240;
			parm4 = 0.0063;
			parm5 = 0.0;
			ampl1 = vec3(0.6,0.0,0.8) + rainStrength/3;
			ampl2 = vec3(0.4,0.0,0.5) + rainStrength/3;
			}
#endif
	
#ifdef WAVING_FIRE
	if ( mc_Entity.x == ENTITY_FIRE) {
			parm0 = 0.0105;
			parm1 = 0.0096;
			parm2 = 0.0087;
			parm3 = 0.0063;
			parm4 = 0.0097;
			parm5 = 0.0156;
			ampl1 = vec3(1.2,0.4,1.2) + rainStrength*1.8;
			ampl2 = vec3(0.8,0.8,0.8) + rainStrength*1.8;
			}				
#endif
}
	float movemult = 0.0;
#ifdef WAVING_LAVA
	if ( mc_Entity.x == ENTITY_LAVAFLOWING || mc_Entity.x == ENTITY_LAVASTILL )	movemult = 0.25;

#endif
	
#ifdef WAVING_LILYPAD
	if ( mc_Entity.x == ENTITY_LILYPAD )  movemult = 1.0 + (rainStrength*0.5);
#endif

#ifdef WAVING_TALLGRASS
	if ( mc_Entity.x == 175) {
			parm0 = 0.0031;
			parm1 = 0.004;
			parm2 = 0.0034;
			parm3 = 0.0028;
			parm4 = 0.0163;
			parm5 = 0.0;
			ampl1 = vec3(0.4,0.0,0.4);
			ampl2 = vec3(0.2,0.0,0.2);
			}
#endif


#ifdef WORLD_CURVATURE
if (gl_Color.a != 0.8) {
    float distanceSquared = position.x * position.x + position.z * position.z;
    position.y -= WORLD_RADIUS - sqrt(max(1.0 - distanceSquared / WORLD_RADIUS_SQUARED, 0.0)) * WORLD_RADIUS;
}	
#endif
	

	position.xyz += calcWaterMove(worldpos.xyz) * movemult;
	position.xyz += calcMove(worldpos.xyz, parm0, parm1, parm2, parm3, parm4, parm5, ampl1, ampl2);
	
	if ( mc_Entity.x == 37 || mc_Entity.x == 31 || mc_Entity.x == 175 || mc_Entity.x == 59 || mc_Entity.x == 141 || mc_Entity.x == 142 || mc_Entity.x == 31  )
	
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
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0, 1.0));
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
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								  tangent.y, binormal.y, normal.y,
						     	  tangent.z, binormal.z, normal.z);
	
	
	viewVector = ( gl_ModelViewMatrix * gl_Vertex).xyz;
	
	viewVector = normalize(tbnMatrix * viewVector);
	dist = 0.0;
	dist = length(gbufferModelView *gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex);
}