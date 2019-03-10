#version 120

/*
RRe36's shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
These functions are Post-Process Effects
*/

//-------- Adjustable Variables --------//

	//---- Visual Effects ----//
		#define LENS_EFFECTS
			#define LENS_STRENGTH 2.62
			#define LENS_PARTICLE_SIZE 1.25

		#define BLOOM_HQ						//do the "fog blur" in the same time
		//#define BLOOM_LQ
			#define B_INTENSITY 1.5		//basic multiplier

		#define DOF
			#define HEXAGONAL_BOKEH						//disabling this will cause to use a circular bokeh effect.
			//-- Profiles --//												//activate only one of these items
				#define PACK_DEFAULT
				//#define HUMAN_EYE
				//#define TILT_SHIFT
				//#define IMAX
				//#define GAMING_DOF
				//define CUSTOM											//activate this and change values
			
				#ifdef CUSTOM												//here
					const float focal = 0.03;
					float aperture = 0.0012;	
					const float sizemult = 100.0;
				#endif
				
			
			//-- End of Profiles --//
			
		#define VIGNETTE
			
	//---- End of Visual Effects ----//
	
	//---- Colors ----//
		#define COLOR_CONTRAST 1.125		             		//Color strength. 1.125 is Default
		//#define COLOR_SAT												//comiclike colors
			#define SAT 1.00

	//---- End of Colors ----//

//-------- End of Adjustable Variables --------//






//---- DOF Profiles ----//
		
		#ifdef PACK_DEFAULT
			const float focal = 0.03;
			float aperture = 0.0012;	
			const float sizemult = 100.0;
		#endif
	
		#ifdef HUMAN_EYE
			const float focal = 0.024;
			float aperture = 0.0012;	
			const float sizemult = 100.0;
		#endif

		#ifdef TILT_SHIFT
			const float focal = 0.3;
			float aperture = 0.3;	
			const float sizemult = 1.0;
		#endif
		
		#ifdef IMAX
			const float focal = 0.07;
			float aperture = 0.02;	
			const float sizemult = 10.0;
		#endif
		
		#ifdef GAMING_DOF
			const float focal = 0.008;
			float aperture = 0.009;	
			const float sizemult = 100.0;
		#endif
		
//---- End of DOF Profiles ----//

#define MAX_COLOR_RANGE 48.0


varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 ambient_color;


uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D depthtex3;
uniform sampler2D noisetex;
uniform sampler2D gaux0;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
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
uniform ivec2 eyeBrightnessSmooth;

uniform int isEyeInWater;
uniform int worldTime;
uniform int fogMode;

uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform float centerDepthSmooth;

vec3 sunPos = sunPosition;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float timefract = worldTime;

//Raining
float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;
float wetx  = clamp(wetness, 0.0f, 1.0f);

//Calculate Time of Day
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

// Standard depth function.
float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}


#ifdef DOF
	//hexagon pattern
	const vec2 hex_offsets[60] = vec2[60] (	vec2(  0.2165,  0.1250 ),
											vec2(  0.0000,  0.2500 ),
											vec2( -0.2165,  0.1250 ),
											vec2( -0.2165, -0.1250 ),
											vec2( -0.0000, -0.2500 ),
											vec2(  0.2165, -0.1250 ),
											vec2(  0.4330,  0.2500 ),
											vec2(  0.0000,  0.5000 ),
											vec2( -0.4330,  0.2500 ),
											vec2( -0.4330, -0.2500 ),
											vec2( -0.0000, -0.5000 ),
											vec2(  0.4330, -0.2500 ),
											vec2(  0.6495,  0.3750 ),
											vec2(  0.0000,  0.7500 ),
											vec2( -0.6495,  0.3750 ),
											vec2( -0.6495, -0.3750 ),
											vec2( -0.0000, -0.7500 ),
											vec2(  0.6495, -0.3750 ),
											vec2(  0.8660,  0.5000 ),
											vec2(  0.0000,  1.0000 ),
											vec2( -0.8660,  0.5000 ),
											vec2( -0.8660, -0.5000 ),
											vec2( -0.0000, -1.0000 ),
											vec2(  0.8660, -0.5000 ),
											vec2(  0.2163,  0.3754 ),
											vec2( -0.2170,  0.3750 ),
											vec2( -0.4333, -0.0004 ),
											vec2( -0.2163, -0.3754 ),
											vec2(  0.2170, -0.3750 ),
											vec2(  0.4333,  0.0004 ),
											vec2(  0.4328,  0.5004 ),
											vec2( -0.2170,  0.6250 ),
											vec2( -0.6498,  0.1246 ),
											vec2( -0.4328, -0.5004 ),
											vec2(  0.2170, -0.6250 ),
											vec2(  0.6498, -0.1246 ),
											vec2(  0.6493,  0.6254 ),
											vec2( -0.2170,  0.8750 ),
											vec2( -0.8663,  0.2496 ),
											vec2( -0.6493, -0.6254 ),
											vec2(  0.2170, -0.8750 ),
											vec2(  0.8663, -0.2496 ),
											vec2(  0.2160,  0.6259 ),
											vec2( -0.4340,  0.5000 ),
											vec2( -0.6500, -0.1259 ),
											vec2( -0.2160, -0.6259 ),
											vec2(  0.4340, -0.5000 ),
											vec2(  0.6500,  0.1259 ),
											vec2(  0.4325,  0.7509 ),
											vec2( -0.4340,  0.7500 ),
											vec2( -0.8665, -0.0009 ),
											vec2( -0.4325, -0.7509 ),
											vec2(  0.4340, -0.7500 ),
											vec2(  0.8665,  0.0009 ),
											vec2(  0.2158,  0.8763 ),
											vec2( -0.6510,  0.6250 ),
											vec2( -0.8668, -0.2513 ),
											vec2( -0.2158, -0.8763 ),
											vec2(  0.6510, -0.6250 ),
											vec2(  0.8668,  0.2513 ));
											
	const vec2 offsets[60] = vec2[60]  (  vec2( 0.0000, 0.2500 ),
									vec2( -0.2165, 0.1250 ),
									vec2( -0.2165, -0.1250 ),
									vec2( -0.0000, -0.2500 ),
									vec2( 0.2165, -0.1250 ),
									vec2( 0.2165, 0.1250 ),
									vec2( 0.0000, 0.5000 ),
									vec2( -0.2500, 0.4330 ),
									vec2( -0.4330, 0.2500 ),
									vec2( -0.5000, 0.0000 ),
									vec2( -0.4330, -0.2500 ),
									vec2( -0.2500, -0.4330 ),
									vec2( -0.0000, -0.5000 ),
									vec2( 0.2500, -0.4330 ),
									vec2( 0.4330, -0.2500 ),
									vec2( 0.5000, -0.0000 ),
									vec2( 0.4330, 0.2500 ),
									vec2( 0.2500, 0.4330 ),
									vec2( 0.0000, 0.7500 ),
									vec2( -0.2565, 0.7048 ),
									vec2( -0.4821, 0.5745 ),
									vec2( -0.6495, 0.3750 ),
									vec2( -0.7386, 0.1302 ),
									vec2( -0.7386, -0.1302 ),
									vec2( -0.6495, -0.3750 ),
									vec2( -0.4821, -0.5745 ),
									vec2( -0.2565, -0.7048 ),
									vec2( -0.0000, -0.7500 ),
									vec2( 0.2565, -0.7048 ),
									vec2( 0.4821, -0.5745 ),
									vec2( 0.6495, -0.3750 ),
									vec2( 0.7386, -0.1302 ),
									vec2( 0.7386, 0.1302 ),
									vec2( 0.6495, 0.3750 ),
									vec2( 0.4821, 0.5745 ),
									vec2( 0.2565, 0.7048 ),
									vec2( 0.0000, 1.0000 ),
									vec2( -0.2588, 0.9659 ),
									vec2( -0.5000, 0.8660 ),
									vec2( -0.7071, 0.7071 ),
									vec2( -0.8660, 0.5000 ),
									vec2( -0.9659, 0.2588 ),
									vec2( -1.0000, 0.0000 ),
									vec2( -0.9659, -0.2588 ),
									vec2( -0.8660, -0.5000 ),
									vec2( -0.7071, -0.7071 ),
									vec2( -0.5000, -0.8660 ),
									vec2( -0.2588, -0.9659 ),
									vec2( -0.0000, -1.0000 ),
									vec2( 0.2588, -0.9659 ),
									vec2( 0.5000, -0.8660 ),
									vec2( 0.7071, -0.7071 ),
									vec2( 0.8660, -0.5000 ),
									vec2( 0.9659, -0.2588 ),
									vec2( 1.0000, -0.0000 ),
									vec2( 0.9659, 0.2588 ),
									vec2( 0.8660, 0.5000 ),
									vec2( 0.7071, 0.7071 ),
									vec2( 0.5000, 0.8660 ),
									vec2( 0.2588, 0.9659 ));
#endif

/*
float A = 0.15;
float B = 0.50;
float C = 0.10;
float D = 0.20;
float E = 0.02;
float F = 0.30;
float W = 4.2;
*/

float A = 0.15;
float B = 0.2;
float C = 0.1;
float D = 0.2;
float E = 0.02;
float F = 0.3;
float W = MAX_COLOR_RANGE;

vec3 Uncharted2Tonemap(vec3 x) {
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float distratio(vec2 pos, vec2 pos2, float ratio) {
	float xvect = pos.x*ratio-pos2.x*ratio;
	float yvect = pos.y-pos2.y;
	return sqrt(xvect*xvect + yvect*yvect);
}
								
float gen_circular_lens(vec2 center, float size) {
	return 1.0-pow(min(distratio(texcoord.xy,center,aspectRatio),size)/size,3.0);
}

vec2 noisepattern(vec2 pos) {
	return vec2(abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f)),abs(fract(sin(dot(pos.yx ,vec2(18.9898f,28.633f))) * 4378.5453f)));
}
float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {


		const float pi = 3.14159265359;
		vec3 fogclr = mix(gl_Fog.color.rgb,vec3(0.25,0.25,0.25),rainStrength)*vec3(0.7,0.7,1.0);
		float rainlens = 0.0;
		const float lifetime = 3.0;		//water drop lifetime in seconds
		float ftime = frameTimeCounter*2.0/lifetime;  

	

		float gen = 1.0-fract((ftime+0.5)*0.5);
		vec2 pos = (noisepattern(vec2(-0.94386347*floor(ftime*0.5+0.25),floor(ftime*0.5+0.25)))-0.5)*0.85+0.5;
		rainlens += gen_circular_lens(pos,0.04)*gen*rainStrength;

		gen = 1.0-fract((ftime+1.0)*0.5);
		pos = (noisepattern(vec2(0.9347*floor(ftime*0.5+0.5),-0.2533282*floor(ftime*0.5+0.5)))-0.5)*0.85+0.5;
		rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength;

		gen = 1.0-fract((ftime+1.5)*0.5);
		pos = (noisepattern(vec2(0.785282*floor(ftime*0.5+0.75),-0.285282*floor(ftime*0.5+0.75)))-0.5)*0.85+0.5;
		rainlens += gen_circular_lens(pos,0.03)*gen*rainStrength;

		gen =  1.0-fract(ftime*0.5);
		pos = (noisepattern(vec2(-0.347*floor(ftime*0.5),0.6847*floor(ftime*0.5)))-0.5)*0.85+0.5;
		rainlens += gen_circular_lens(pos,0.05)*gen*rainStrength;
	
		rainlens *= clamp((eyeBrightness.y-220)/15.0,0.0,1.0);
	
	
	vec2 fake_refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0)) ;
	vec2 newTC = texcoord.st + fake_refract * 0.01 * (rainlens);
	vec3 color = (pow(texture2D(gaux2, newTC).rgb,vec3(2.2))*MAX_COLOR_RANGE);


	float fog = 1-(exp(-pow(ld(texture2D(depthtex0, newTC.st).r)/256.0*far,4.0-(2.7*rainStrength))*4.0));
	
if (isEyeInWater > 0.9) {
		vec2 water_refract = vec2(sin(worldTime/15.0 + texcoord.x*100.0 + texcoord.y*50.0),cos(worldTime/15.0 + texcoord.y*100.0 + texcoord.x*50.0)) * isEyeInWater;
		vec3 color = texture2D(gaux2, texcoord.st + fake_refract * 0.005).rgb*16.0;
}
#ifdef DOF
	//Calculate pixel Circle of Confusion that will be used for bokeh depth of field
	float dof_center = (texture2D(depthtex0, vec2(0.5)).r)*far/1.4;
	float dof_fading = centerDepthSmooth;
	float z = ld(texture2D(depthtex0, newTC.st).r)*far/1.4;
	float focus = (ld(texture2D(depthtex0, vec2(0.5)).r)*far/1.4);
	float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*20.0);
	#ifdef DISTANT_BLUR
	pcoc = min(fog*pw*20.0,pw*20.0);
	#endif
	vec4 sample = vec4(0.0);
	vec3 bcolor = color/MAX_COLOR_RANGE;
	float nb = 0.0;
	vec2 bcoord = vec2(0.0);
	if (pcoc > pw*1.5) {
	#ifdef HEXAGONAL_BOKEH
	
		for ( int i = 0; i < 60; i++) {
			bcolor += pow(texture2D(gaux2, newTC.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio)).rgb,vec3(2.2));
			
		}
		color.rgb = bcolor/61.0*MAX_COLOR_RANGE;
	#else

		for ( int i = 0; i < 60; i++) {
		bcolor += pow(texture2D(gaux2, newTC.xy + offsets[i]*pcoc*vec2(1.0,aspectRatio)).rgb,vec3(2.2));
		}
color.rgb = bcolor/61.0*MAX_COLOR_RANGE;
	#endif
		
	}
#endif

	
//---------- Bloom ----------//
#ifdef BLOOM_HQ
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

blur += pow(texture2D(gcolor,texcoord.xy + rMult*vec2(1.0,aspectRatio)*vec2(0.0,i-center)).rgb,vec3(2.2))*weight;

tw += weight;
}
blur /= tw;
//blur *= 0.2;

color.rgb = (mix(color,blur*MAX_COLOR_RANGE,(fog)*(rainStrength)));
blur *= pow(luma(blur),1.95)/luma(blur)*3.80;

color = ((blur + color/MAX_COLOR_RANGE) - (blur * color/MAX_COLOR_RANGE))*MAX_COLOR_RANGE;
/*
vec3 input = color;
color /= MAX_COLOR_RANGE;
blur = blur*0.5+0.5;
color = color+(2.0*blur-1.0)*(sqrt(color)-color);
color *= MAX_COLOR_RANGE;
*/
//color= blur*MAX_COLOR_RANGE; 

	color.rgb += pow(texture2D(gaux4,newTC.xy).rgb,vec3(2.2))*pow(texture2D(gaux4,newTC.xy).a,0.4)*2.0*ambient_color;
	
#endif

#ifdef BLOOM_LQ
const float radius = 0.003;
vec3 blur = vec3(0.0);
float tw = 0.0;
for (int i = 0; i < 7; i++) {
float weight = exp(-pow(abs((i-3.0))/1.5,2.0)/2.0);
blur += pow(texture2DLod(gcolor,newTC.xy + radius*vec2(1.0,aspectRatio)*ivec2(0,i-3),3).rgb,vec3(2.2)).rgb*weight;
tw += weight;
}
blur /= tw;
color.rgb = mix(color,blur*MAX_COLOR_RANGE,fog*(0.0+rainStrength));
color += pow(blur,vec3(1.6))*(1/2.56)*MAX_COLOR_RANGE*B_INTENSITY;
//color= blur*MAX_COLOR_RANGE;
//color = texture2DLod(gaux2,newTC.xy,1).rgb*16.0;

	color.rgb += pow(texture2D(gaux4,newTC.xy).rgb,vec3(2.2))*pow(texture2D(gaux4,newTC.xy).a,0.4)*2.0*ambient_color;
#endif
	
//---------- End of Bloom ----------//
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		lightPos = (lightPos + 1.0f)/2.0f;
		
		vec3 lightVector;
		
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	
	else {
		lightVector = normalize(moonPosition);
	}
	
//circle position pattern (vec2 coordinate, size)
const vec3 pattern[16] = vec3[16](	vec3(0.1,0.1,0.02),
								vec3(-0.12,0.07,0.02),
								vec3(-0.11,-0.13,0.02),
								vec3(0.1,-0.1,0.02),
								
								vec3(0.07,0.15,0.02),
								vec3(-0.08,0.17,0.02),
								vec3(-0.14,-0.07,0.02),
								vec3(0.15,-0.19,0.02),
								
								vec3(0.012,0.15,0.02),
								vec3(-0.08,0.17,0.02),
								vec3(-0.14,-0.07,0.02),
								vec3(0.02,-0.17,0.021),
								
								vec3(0.10,0.05,0.02),
								vec3(-0.13,0.09,0.02),
								vec3(-0.05,-0.1,0.02),
								vec3(0.1,0.01,0.02)
								);
								

			float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
			float fading = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);
			float time = float(worldTime);
			float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));
			float sunvisibility = min(texture2D(gaux2,vec2(0.0)).a*2.5,1.0) * (1.0-rainStrength*0.9) * fading * transition_fading;
	
	
#ifdef LENS_EFFECTS
float xdist = abs(lightPos.x-texcoord.x);
float ydist = abs(lightPos.y-texcoord.y);
float xydist = distance(lightPos.xy,texcoord.xy);
float xydistratio = distratio(lightPos.xy,texcoord.xy,aspectRatio);



//float anamorphic_lens = clamp( 0.75-(pow(ydist,0.1)) - pow(xdist*2.0,2.0),0.0,1.0)*5.0;


float centerdist = distance(lightPos.xy,vec2(0.5))/1.412;
float sizemult = 1.0 + centerdist;
float noise = fract(sin(dot(texcoord.st ,vec2(18.9898f,28.633f))) * 4378.5453f)*0.1 + 0.9;
							
float circles_lens = 0.0;


if (sunvisibility > 0.2) {

//-- Lens Particles --//

if (xydist < 0.35) {
vec2 sun_to_center = lightPos-vec2(0.5);
float dir = abs(sin(length(sun_to_center)))*0.25+0.75;

for (int i = 0; i < 8; i++) {
vec3 carac = pattern[i]*1.125;
carac.z *= 1.125/1.25;
carac.x /= aspectRatio;
carac *= (1.0 + dir)/1.75;
vec2 coord = carac.xy * sizemult+ lightPos.xy;
float strength = sin(length(coord-vec2(0.5))*40.0)*0.5+0.5;
circles_lens += gen_circular_lens(coord,carac.z*LENS_PARTICLE_SIZE - (rainStrength*LENS_PARTICLE_SIZE))*strength*15;

carac = pattern[i];
carac.x /= aspectRatio;
carac.yx *= (2.0 - dir)/1.5;

coord = -carac.yx * sizemult + lightPos.xy;
strength = sin(length(coord-vec2(0.5))*40.0)*0.5+0.5;
circles_lens += gen_circular_lens(coord,carac.z*0.66)*strength;
}
color += sunlight*vec3(circles_lens) * sunvisibility * noise * 0.35 ;
}

//-- End of Lens Particles --//
if (ydist < 0.27) {
float anamorphic_lens = max(pow(max(1.0 - ydist/1.412,0.01),8.0)-0.2,0.0);
color += sunlight * vec3(0.0,0.0,1.0)*anamorphic_lens*LENS_STRENGTH*sunvisibility;
}
}
//rain drops on screen
if (rainStrength > 0.05) {
const float pi = 3.14159265359;
vec3 fogclr = mix(gl_Fog.color.rgb,vec3(0.25,0.25,0.25),rainStrength)*vec3(0.7,0.7,1.0);
float rainlens = 0.0;
float time = frameTimeCounter;
float gen = sin(time*pi)*0.5+0.5;
vec2 pos = noisepattern(vec2(-0.94386347*floor(time*0.5+0.25),floor(time*0.5+0.25)));
rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength;

gen = cos(time*pi)*0.5+0.5;
pos = noisepattern(vec2(0.9347*floor(time*0.5+0.5),-0.2533282*floor(time*0.5+0.5)));
rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength;

gen = cos(time*pi)*0.5+0.5;
pos = noisepattern(vec2(0.785282*floor(time*0.5+0.5),-0.285282*floor(time*0.5+0.5)));
rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength;

gen = sin(time*pi)*0.5+0.5;
pos = noisepattern(vec2(-0.347*floor(time*0.5+0.25),0.6847*floor(time*0.5+0.25)));
rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength;
color += 0.2*fogclr*rainlens*(eyeBrightness.y/255.0);

}

if (sunvisibility > 0.2) {

float chroma_circle = pow(xydistratio/1.412,0.5)*0.2;

vec3 circle_color = clamp(sin(xydistratio*8.5+8.7)*vec3(1.2,0.4,0.3)*chroma_circle,0.0,1.0);

color+= sunlight*vec3(circle_color)*(LENS_STRENGTH + 0.2)*sunvisibility;

}

#endif
	
#ifdef COLOR_SAT
vec3 input = color;
float rdist = max(color.r*sqrt(2.0)-length(color.gb),0.0)*(1.0/length(color));
float gdist = max(color.g*sqrt(2.0)-length(color.rb),0.0)*(1.0/length(color));
float bdist = max(color.b*sqrt(2.0)-length(color.rg),0.0)*(1.0/length(color));
color *= (vec3(rdist,gdist,bdist)+SAT)/SAT;

#endif


	
	float avglight = texture2D(gaux2,vec2(1.0)).a;
	
	vec3 curr = Uncharted2Tonemap(color);
	

	vec3 whiteScale = 1.0f/Uncharted2Tonemap(vec3(W));
	color = curr*whiteScale;
	
	 float saturation = 1.04;   
	
       
        float avg = (color.r + color.g + color.b);
       
        color = (((color - avg )*saturation)+avg) ;
		color /= saturation;
		


	color = pow(color,vec3(COLOR_CONTRAST/2.2));
	
	float gamma = 1.0f;
	color *= gamma;

	


	gl_FragColor = vec4(color,1.0);
}
