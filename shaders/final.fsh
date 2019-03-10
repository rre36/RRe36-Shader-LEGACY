#version 120

#extension GL_ARB_shader_texture_lod : enable
/*






!! DO NOT REMOVE !! !! DO NOT REMOVE !!

This code is from Chocapic13' shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !! !! DO NOT REMOVE !!


Sharing and modification rules

Sharing a modified version of my shaders:
-You are not allowed to claim any of the code included in "Chocapic13' shaders" as your own
-You can share a modified version of my shaders if you respect the following title scheme : " -Name of the shaderpack- (Chocapic13' Shaders edit) "
-You cannot use any monetizing links
-The rules of modification and sharing have to be same as the one here (copy paste all these rules in your post), you cannot make your own rules
-I have to be clearly credited
-You cannot use any version older than "Chocapic13' Shaders V4" as a base, however you can modify older versions for personal use
-Common sense : if you want a feature from another shaderpack or want to use a piece of code found on the web, make sure the code is open source. In doubt ask the creator.
-Common sense #2 : share your modification only if you think it adds something really useful to the shaderpack(not only 2-3 constants changed)


Special level of permission; with written permission from Chocapic13, if you think your shaderpack is an huge modification from the original (code wise, the look/performance is not taken in account):
-Allows to use monetizing links
-Allows to create your own sharing rules
-Shaderpack name can be chosen
-Listed on Chocapic13' shaders official thread
-Chocapic13 still have to be clearly credited


Using this shaderpack in a video or a picture:
-You are allowed to use this shaderpack for screenshots and videos if you give the shaderpack name in the description/message
-You are allowed to use this shaderpack in monetized videos if you respect the rule above.


Minecraft website:
-The download link must redirect to the link given in the shaderpack's official thread
-You are not allowed to add any monetizing link to the shaderpack download

If you are not sure about what you are allowed to do or not, PM Chocapic13 on http://www.minecraftforum.net/
Not respecting these rules can and will result in a request of thread/download shutdown to the host/administrator, with or without warning. Intellectual property stealing is punished by law.











*/
#define MAX_COLOR_RANGE 48.0
const bool compositeMipmapEnabled = true;


/*
Disable an effect by putting "//" before "#define" when there is no number after
You can tweak the numbers, the impact on the shaders is self-explained in the variable's name or in a comment
*/

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
#define VIGNETTE
#define VIGNETTE_STRENGTH 1. 
#define VIGNETTE_START 0.15	//distance from the center of the screen where the vignette effect start (0-1)
#define VIGNETTE_END 0.95		//distance from the center of the screen where the vignette effect end (0-1), bigger than VIGNETTE_START
  
#define LENS_EFFECTS			
	#define LENS_STRENGTH 2.85		
	
#define RAIN_DROPS

#define BLOOM_STRENGTH 96.


//#define DOF							//enable depth of field (blur on non-focused objects)
	//#define HEXAGONAL_BOKEH			//disabled : circular blur shape - enabled : hexagonal blur shape
	//#define DISTANT_BLUR				//constant distance blur
			//lens properties
			const float focal = 0.024;
			float aperture = 0.008;	
			const float sizemult = 80.0;
			/*
			Try different setting by replacing the values above by the values here or use your own settings
			----------------------------------
			"Near to human eye (for gameplay,default)":

			const float focal = 0.024;
			float aperture = 0.009;	
			const float sizemult = 100.0;
			----------------------------------
			"Tilt shift (cinematics)":

			const float focal = 0.3;
			float aperture = 0.3;	
			const float sizemult = 1.0;
			----------------------------------
			"Camera (cinematics)":

			const float focal = 0.05;
			float aperture = focal/7.0;	
			const float sizemult = 100.0;
			---------------------------------- 
			*/

//tonemapping constants			
float A = 1.25;		
float B = 0.4;		
float C = 0.09;		



//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES


/*--------------------------------*/
varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;

varying float eyeAdapt;

varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;


uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform sampler2D composite;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform ivec2 eyeBrightnessSmooth;
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
/*--------------------------------*/
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

#ifdef LENS_EFFECTS

	float distratio(vec2 pos, vec2 pos2, float ratio) {
		float xvect = pos.x*ratio-pos2.x*ratio;
		float yvect = pos.y-pos2.y;
		return sqrt(xvect*xvect + yvect*yvect);
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
									

	
	float yDistAxis (in float degrees) {
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
			 tpos = vec4(tpos.xyz/tpos.w,1.0);
		vec2 lightPos = tpos.xy/tpos.z;
			 lightPos = (lightPos + 1.0f)/2.0f;
			 
		return abs((lightPos.y-lightPos.x*(degrees))-(texcoord.y-texcoord.x*(degrees)));
		
	}
	
	float smoothCircleDist (in float lensDist) {

		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
			 tpos = vec4(tpos.xyz/tpos.w,1.0);
		vec2 lightPos = tpos.xy/tpos.z*lensDist;
			 lightPos = (lightPos + 1.0f)/2.0f;
			 
		return distratio(lightPos.xy, texcoord.xy, aspectRatio);
		
	}
	
	float cirlceDist (float lensDist, float size) {
	
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
			 tpos = vec4(tpos.xyz/tpos.w,1.0);
		vec2 lightPos = tpos.xy/tpos.z*lensDist;
			 lightPos = (lightPos + 1.0f)/2.0f;
			 
		return pow(min(distratio(lightPos.xy, texcoord.xy, aspectRatio),size)/size,10.);
	}
	
	float hash( float n ) {
		return fract(sin(n)*43758.5453);
	}
 
	float noise( in vec2 x ) {
		vec2 p = floor(x);
		vec2 f = fract(x);
    	f = f*f*(3.0-2.0*f);
    	float n = p.x + p.y*57.0;
    	float res = mix(mix( hash(n+  0.0), hash(n+  1.0),f.x), mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);
    	return res;
	}
 
	float fbm( vec2 p ) {
    	float f = 0.0;
    	f += 0.50000*noise( p ); p = p*2.02;
    	f += 0.25000*noise( p ); p = p*2.03;
    	f += 0.12500*noise( p ); p = p*2.01;
    	f += 0.06250*noise( p ); p = p*2.04;
    	f += 0.03125*noise( p );
		
    	return f/0.984375;
	}

#endif

vec3 Uncharted2Tonemap(vec3 x) {
	float D = 0.09;		
	float E = 0.02;
	float F = 0.3;
	float W = MAX_COLOR_RANGE;
	/*--------------------------------*/
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float distratio(vec2 pos, vec2 pos2) {
	float xvect = pos.x*aspectRatio-pos2.x*aspectRatio;
	float yvect = pos.y-pos2.y;
	return sqrt(xvect*xvect + yvect*yvect);
}
								
float gen_circular_lens(vec2 center, float size) {
	float dist=distratio(center,texcoord.xy)/size;
	return exp(-dist*dist);
}

vec2 noisepattern(vec2 pos) {
	return vec2(abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f)),abs(fract(sin(dot(pos.yx ,vec2(18.9898f,28.633f))) * 4378.5453f)));
}

float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}



vec3 alphablend(vec3 c, vec3 ac, float a) {
vec3 n_ac = normalize(ac)*(1/sqrt(3.));
vec3 nc = sqrt(c*n_ac);
return mix(c,nc,a);
}
float smStep (float edge0,float edge1,float x) {
float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
return t * t * (3.0 - 2.0 * t); }

float dirtPattern (vec2 tc) {
	float noise = texture2D(noisetex,tc).x;
	noise += texture2D(noisetex,tc*3.5).x/3.5;
	noise += texture2D(noisetex,tc*12.25).x/12.25;
	noise += texture2D(noisetex,tc*42.87).x/42.87;	
	return noise / 1.4472;
}
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {

	/*--------------------------------*/
	const float pi = 3.14159265359;
	float rainlens = 0.0;
	const float lifetime = 4.0;		//water drop lifetime in seconds
	/*--------------------------------*/
	float ftime = frameTimeCounter*2.0/lifetime;  
	vec2 drop = vec2(0.0,fract(frameTimeCounter/20.0));
	/*--------------------------------*/
#ifdef RAIN_DROPS
		if (rainStrength > 0.02) {
		/*--------------------------------*/
		float gen = 1.0-fract((ftime+0.5)*0.5);
		vec2 pos = (noisepattern(vec2(-0.94386347*floor(ftime*0.5+0.25),floor(ftime*0.5+0.25))))*0.8+0.1 - drop;
		rainlens += gen_circular_lens(fract(pos),0.04)*gen*rainStrength;
		/*--------------------------------*/
		gen = 1.0-fract((ftime+1.0)*0.5);
		pos = (noisepattern(vec2(0.9347*floor(ftime*0.5+0.5),-0.2533282*floor(ftime*0.5+0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.023)*gen*rainStrength;
		/*--------------------------------*/
		gen = 1.0-fract((ftime+1.5)*0.5);
		pos = (noisepattern(vec2(0.785282*floor(ftime*0.5+0.75),-0.285282*floor(ftime*0.5+0.75))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.03)*gen*rainStrength;
		/*--------------------------------*/
		gen =  1.0-fract(ftime*0.5);
		pos = (noisepattern(vec2(-0.347*floor(ftime*0.5),0.6847*floor(ftime*0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.05)*gen*rainStrength;
		/*--------------------------------*/
		rainlens *= clamp((eyeBrightnessSmooth.y-220)/15.0,0.0,1.0);
	}
#endif
	vec2 fake_refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0)) ;
	vec2 newTC = texcoord.st + fake_refract * 0.01 * (rainlens+isEyeInWater*0.25);
	/*--------------------------------*/
	vec3 color = pow(texture2D(gaux2, newTC).rgb,vec3(2.2))*MAX_COLOR_RANGE;
	/*--------------------------------*/
	float fog = 1-(exp(-pow(ld(texture2D(depthtex0, newTC.st).r)/256.0*far,4.0-(2.7*rainStrength))*4.0));
	fog = mix(fog,1-exp(-ld(texture2D(depthtex0, newTC.st).r)*far/256.),isEyeInWater);
	/*--------------------------------*/
	
#ifdef DOF
	/*--------------------------------*/
	float z = ld(texture2D(depthtex0, newTC.st).r)*far;
	float focus = ld(texture2D(depthtex0, vec2(0.5)).r)*far;
	float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*15.0);
	/*--------------------------------*/
	#ifdef DISTANT_BLUR
	pcoc = min(fog*pw*20.0,pw*20.0);
	#endif
	/*--------------------------------*/
	vec4 sample = vec4(0.0);
	vec3 bcolor = color/MAX_COLOR_RANGE;
	float nb = 0.0;
	vec2 bcoord = vec2(0.0);
	/*--------------------------------*/
	#ifdef HEXAGONAL_BOKEH
		for ( int i = 0; i < 60; i++) {
			bcolor += pow(texture2D(gaux2, newTC.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio)).rgb,vec3(2.2));
		}
		color.rgb = bcolor/61.0*MAX_COLOR_RANGE;
	#else
		for ( int i = 0; i < 60; i++) {
			bcolor += pow(texture2D(gaux2, newTC.xy + offsets[i]*pcoc*vec2(1.0,aspectRatio)).rgb,vec3(2.2));
		}
	/*--------------------------------*/	
color.rgb = bcolor/61.0*MAX_COLOR_RANGE;
	#endif

#endif
	
	
//Bloom
/*--------------------------------*/
const float rMult = 0.0025;
const int nSteps = 15;
int center = (nSteps-1)/2;
float radius = center*rMult;
float sigma = 0.3;
/*--------------------------------*/
vec3 blur = vec3(0.0);
float tw = 0.0;
/*--------------------------------*/
for (int i = 0; i < nSteps; i++) {
	float dist = (i-float(center))/center;
	float weight = A*exp(-(dist*dist)/(2.0*sigma));
	/*--------------------------------*/
	blur += pow(texture2DLod(composite,texcoord.xy + rMult*vec2(1.0,aspectRatio)*vec2(0.0,i-center),2).rgb,vec3(2.2))*weight;
	tw += weight;
}
blur /= tw;
/*--------------------------------*/

float dirt = dirtPattern(texcoord.xy/100.);
color.xyz += blur*BLOOM_STRENGTH*(1+45*pow(rainStrength,3.));

/*--------------------------------*/
	//draw rain
	vec4 rain = pow(texture2D(gaux4,texcoord.xy),vec4(vec3(2.2),1.));
	if (length(rain) > 0.0001) {
	rain.rgb = normalize(rain.rgb)*0.001*(0.5+length(rain.rgb)*0.25)*length(ambient_color);
	color.rgb = ((1-(1-color.xyz/48.0)*(1-rain.xyz*rain.a))*48.0);
	}
/*--------------------------------*/

	#ifdef RAIN_DROPS
	vec3 c_rain = rainlens*ambient_color*0.0008;
	color = (((1-(1-color.xyz/48.0)*(1-c_rain.xyz))*48.0));
	#endif
/*--------------------------------*/


#ifdef LENS_EFFECTS


	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		lightPos = (lightPos + 1.0f)/2.0f;

    float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
	float fading = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);

    float time = float(worldTime);

    float sunvisibility = min(texture2D(gaux2,vec2(pw,ph)).a,1.0) * fading ;
	float sunvisibility2 = min(texture2D(gaux2,vec2(pw,ph)).a,1.0);
	float centerVisibility = 1.0 - clamp(distance(lightPos.xy, vec2(0.5, 0.5)) * 2.0, 0.0, 1.0);
		  centerVisibility *= sunvisibility;
	
	float lensBrightness = 0.17;
	
	
	// Fix, that the particles are visible on the moon position at daytime
	float truepos = 0.99*sign(sunPosition.z);		//1 -> sun / -1 -> moon
	vec3 rainc = mix(vec3(1.),vec3(0.2,0.25,0.3),rainStrength);
	vec3 lightColor = mix(sunlight*sunVisibility*rainc,6*moonlight*moonVisibility*rainc,(truepos+1.0)/2.);
	
	
	// Dirty Lens
		// Set up domain
		vec2 q = texcoord.xy + texcoord.x * 0.4;
		vec2 p = -1.0 + 3.0 * q;
		vec2 p2 = -1.0 + 3.0 * q + vec2(10.0, 10.0);
		
		// Create noise using fBm
		float f = fbm(5.0 * p);
		float f2 = fbm(20.0 * p2);
	 
		float cover = 0.35f;
		float sharpness = 0.99 * sunvisibility2;	// Brightness
		
		float c = f - (1.0 - cover);
		if ( c < 0.0 )
			 c = 0.0;
		
		f = 1.0 - (pow(1.0 - sharpness, c));
				
				
		float c2 = f2 - (1.0 - cover);
		if ( c2 < 0.0 )
			 c2 = 0.0;
		
		f2 = 1.0 - (pow(1.0 - sharpness, c2));
				
		float dirtylens = (f * 2.0) + (f2 / 1);

	
		float visibility = max(pow(max(1.0 - smoothCircleDist(1.0)/0.8,0.1),2.0)-0.1,0.0);

				
		vec3 lenscolor = pow(normalize(lightColor),vec3(2.2))*length(lightColor);
			
		float lens_strength = 1.3 * lensBrightness;
		lenscolor *= lens_strength;
				
		color += (dirtylens*visibility)*lenscolor*(1.0-rainStrength*1.0)*2.;

	
	// Anamorphic Lens
	if (sunvisibility > 0.01) {
		
		float visibility = max(pow(max(1.0 - smoothCircleDist(1.0)/1.5,0.1),1.0)-0.1,0.0);
		
			
		vec3 lenscolor = length(lightColor)*vec3(0.2, 0.8, 2.55);

		float lens_strength = 0.8 * lensBrightness;
		lenscolor *= lens_strength;
			
		float anamorphic_lens = max(pow(max(1.0 - yDistAxis(0.0)/1.4,0.1),10.0)-0.5,0.0);
		color += anamorphic_lens * lenscolor * visibility  * sunvisibility * (1.0-rainStrength*1.0);
	}
	

	
		float dist = distance(texcoord.st, vec2(0.5, 0.5));
		
		float sunvisValue = 0.0;
		


		
		// Sunrays
		if (sunvisibility > sunvisValue) {
		
			float visibility = max(pow(max(1.0 - smoothCircleDist(1.0)/1.0,0.1),5.0)-0.1,0.0);
			
			vec3 lenscolor = pow(normalize(lightColor),vec3(2.2))*length(lightColor);
			
			float lens_strength = 0.7 * lensBrightness;
			lenscolor *= lens_strength;
			
			float sunray1 = max(pow(max(1.0 - yDistAxis(1.5)/0.7,0.1),10.0)-0.6,0.0);
			float sunray2 = max(pow(max(1.0 - yDistAxis(-1.3)/0.7,0.1),10.0)-0.6,0.0);
			float sunray3 = max(pow(max(1.0 - yDistAxis(5.0)/1.5,0.1),10.0)-0.6,0.0);
			float sunray4 = max(pow(max(1.0 - yDistAxis(-4.8)/1.5,0.1),10.0)-0.6,0.0);
			
			float sunrays = sunray1 + sunray2 + sunray3 + sunray4;
			
			color += lenscolor * sunrays * visibility * sunvisibility * (1.0-rainStrength*1.0)*2.;
		}
		
		// Sun Glow
		

			
		lenscolor = pow(normalize(lightColor),vec3(2.2))*length(lightColor)* vec3(0.7, 0.75, 1.);
			
		lens_strength = 0.6 * lensBrightness;
		lenscolor *= lens_strength;
			
		float lensFlare = max(pow(max(1.0 - smoothCircleDist(1.0)/2.4,0.1),5.0)-0.1,0.0);
			
		color += lensFlare * lenscolor * sunvisibility2 * (1.0-rainStrength*1.0);
		
				// Circle Lens 1
		if (sunvisibility > 0.01) {
		
			vec3 lenscolor =  vec3(2.52, 1.2, 0.4) * lightColor;
			
			float lens_strength = 0.2 * lensBrightness;
			lenscolor *= lens_strength;
			
			float lensFlare1 = max(pow(max(1.0 - cirlceDist(-0.15, 0.07)/1.0,0.1),5.0)-0.1,0.0);
			float lensFlare2 = max(pow(max(1.0 - cirlceDist(-0.2, 0.07)/1.0,0.1),5.0)-0.1,0.0);
			float lensFlare3 = max(pow(max(1.0 - cirlceDist(-0.25, 0.07)/1.0,0.1),5.0)-0.1,0.0);
			
			float lensFlare = clamp(lensFlare1 * lensFlare2 * lensFlare3, 0.0, 1.0);
			
			color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0)*0.7;
		}
		
		// Circle Lens 2
		if (sunvisibility > 0.01) {
		
			vec3 lenscolor =  vec3(1.6, 2.55, 0.4) * lightColor;
			
			float lens_strength = 0.2 * lensBrightness;
			lenscolor *= lens_strength;
			
			float lensFlare1 = max(pow(max(1.0 - cirlceDist(-0.4, 0.13)/1.0,0.1),5.0)-0.1,0.0);
			float lensFlare2 = max(pow(max(1.0 - cirlceDist(-0.5, 0.13)/1.0,0.1),5.0)-0.1,0.0);
			float lensFlare3 = max(pow(max(1.0 - cirlceDist(-0.6, 0.13)/1.0,0.1),5.0)-0.1,0.0);
			
			float lensFlare = clamp(lensFlare1 * lensFlare2 * lensFlare3, 0.0, 1.0);
			
			color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0)*0.7;
		}
		
		// Circle Lens 3
		if (sunvisibility > 0.01) {
		
			vec3 lenscolor =  vec3(0.4, 2.55, 1.55) * lightColor;
			
			float lens_strength = 0.1 * lensBrightness;
			lenscolor *= lens_strength;
			
			float lensFlare1 = max(pow(max(1.0 - cirlceDist(-0.75, 0.09)/1.0,0.1),5.0)-0.1,0.0);
			float lensFlare2 = max(pow(max(1.0 - cirlceDist(-0.8, 0.09)/1.0,0.1),5.0)-0.1,0.0);
			float lensFlare3 = max(pow(max(1.0 - cirlceDist(-0.85, 0.09)/1.0,0.1),5.0)-0.1,0.0);
			
			float lensFlare = clamp(lensFlare1 * lensFlare2 * lensFlare3, 0.0, 1.0);
			
			color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0)*0.7;
		}
		
		
		// Small point 1
		if (sunvisibility > 0.01) {
		
			vec3 lenscolor = vec3(2.55, 2.55, 0.0) * lightColor;
			
			float lens_strength = 150.0 * lensBrightness;
			lenscolor *= lens_strength;
			
			float lensFlare1 = max(pow(max(1.0 - smoothCircleDist(-0.27)/1.0,0.1),5.0)-0.85,0.0);
			float lensFlare2 = max(pow(max(1.0 - smoothCircleDist(-0.3)/1.0,0.1),5.0)-0.85,0.0);
			float lensFlare3 = max(pow(max(1.0 - smoothCircleDist(-0.33)/1.0,0.1),5.0)-0.85,0.0);
			
			float lensFlare = clamp(lensFlare1 * lensFlare2 * lensFlare3, 0.0, 1.0);
			
			color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0);
		}
		
		// Small point 2
		if (sunvisibility > 0.01) {
		
			vec3 lenscolor = vec3(0.0, 1.55, 2.52) * lightColor;
			
			float lens_strength = 150.0 * lensBrightness;
			lenscolor *= lens_strength;
			
			float lensFlare1 = max(pow(max(1.0 - smoothCircleDist(-0.82)/1.0,0.1),5.0)-0.85,0.0);
			float lensFlare2 = max(pow(max(1.0 - smoothCircleDist(-0.85)/1.0,0.1),5.0)-0.85,0.0);
			float lensFlare3 = max(pow(max(1.0 - smoothCircleDist(-0.88)/1.0,0.1),5.0)-0.85,0.0);
			
			float lensFlare = clamp(lensFlare1 * lensFlare2 * lensFlare3, 0.0, 1.0);
			
			color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0);
		}
		
		// Ring Lens 
		if (sunvisibility > 0.01) {
		
			vec3 lenscolor = vec3(0.2, 0.8, 2.55) * length(lightColor);
			
			float lens_strength = 0.3 * lensBrightness;
			lenscolor *= lens_strength;
			
			float lensFlare1 = max(pow(max(1.0 - cirlceDist(-0.7, 0.5)/1.0,0.1),5.0)-0.1,0.0);
			float lensFlare2 = max(pow(max(1.0 - cirlceDist(-0.9, 0.5)/1.0,0.1),5.0)-0.1,0.0);
			
			float lensFlare = clamp(lensFlare2 - lensFlare1, 0.0, 1.0);
			color += lensFlare*lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0)*1.3;
		}
		


	
#endif
	
	/*--------------------------------*/
	vec3 curr = Uncharted2Tonemap(color);
	vec3 whiteScale = 1.0f/Uncharted2Tonemap(vec3(MAX_COLOR_RANGE));
	color = pow(curr*whiteScale,vec3(1./2.2));
	/*--------------------------------*/
	

	
	#ifdef VIGNETTE
	float len = length(texcoord.xy-vec2(.5));
	float len2 = distratio(texcoord.xy,vec2(.5));
	/*--------------------------------*/
	float dc = mix(len,len2,0.3);
    float vignette = smStep(VIGNETTE_END, VIGNETTE_START,  dc);
	/*--------------------------------*/
	color = color*(1+vignette)*0.5;
	#endif	

	/*--------------------------------*/
	gl_FragColor = vec4(color,1.0);
}