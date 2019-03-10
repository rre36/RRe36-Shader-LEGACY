#version 120

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

//-------- Adjustable Variables --------//

	//---- Shadows ----//
		const int shadowMapResolution = 1536;							//shadowmap resolution
		const float shadowDistance = 80.0f;									//draw distance of shadows, needs decimal point!
	
		#define SHADOW_DARKNESS 0.20										//shadow darkness levels, lower values mean darker shadows, see .vsh for colors /0.25 is default
			
		#define HQ_SHADOW_FILTER												//only enable one
		//#define SHADOW_FILTER			
		
	//---- End of Shadows ----//

	//---- Lighting ----//
		#define DYNAMIC_HANDLIGHT
	
		#define SUNLIGHTAMOUNT 5.5											//change sunlight strength , see .vsh for colors. /1.7 is default
	
		//-- Torchlight Color --//
			#define TORCH_COLOR_LIGHTING 1.0f,0.26f,0.0 		//Torch Color RGB - Red, Green, Blue / vec3(0.6,0.32,0.1) is default
			#define TORCH_ATTEN 3.0													//how much the torch light will be attenuated (decrease if you want that the torches cover a bigger area))/3.0 is default
			#define TORCH_INTENSITY 7.0											//torch light intensity /2.6 is default
	
		//-- Minecraft lightmap (used for sky) --//
			#define ATTENUATION 3.0
			#define MIN_LIGHT 0.05
			#define SKY_BRIGHTNESS 3.0
			
		const float	ambientOcclusionLevel = 1.0f;						//level of Minecraft smooth lighting, 1.0f is default

	//---- End of Lighting ----//
	
	//---- Visual Effects ----//
		#define GODRAYS
			const float density = 0.7;			
			const int NUM_SAMPLES = 8;												//increase this for better quality at the cost of performance /5 is default
			const float grnoise = 1.0;														//amount of noise /0.012 is default
	
		//#define SSAO																			//works but is turned off by default due to performance cost
			//-- SSAO constants --//
			const int nbdir = 6;																	//the two numbers here affect the number of sample used. Increase for better quality at the cost of performance /6 and 6 is default
			const float sampledir = 6;	
			const float ssaorad = 1.0;														//radius of ssao shadows /1.0 is default
	
		//#define CELSHADING
			#define BORDER 2.0

		const float	sunPathRotation	= -17.5f;								//determines sun/moon inclination /-40.0 is default - 0.0 is normal rotation

	//---- End of Visual Effects ----//

//-------- End of Adjustable Variables --------//







#define MAX_COLOR_RANGE 48.0

const float 	eyeBrightnessHalflife 	= 10.0f;
const float 	wetnessHalflife 		= 70.0f;
const float 	drynessHalflife 		= 70.0f;
const int 		R8						= 0;
const int 		gdepthFormat 			= R8;
const bool 		shadowHardwareFiltering = true;

const float 	shadowIntervalSize 		= 4.0f;
const int 		noiseTextureResolution  = 64;
#define SHADOW_MAP_BIAS 0.80

varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 sunlight_color;
varying vec3 ambient_color;
varying vec3 sky_color;
varying vec3 cloud_2D_color;
varying vec3 sunglow_color;
varying float handItemLight;

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2DShadow shadow;
uniform sampler2D gaux1;
uniform sampler2D noisetex;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform float near;
uniform float far;
uniform vec3 skyColor;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform float frameTime;
uniform ivec2 eyeBrightness;
uniform int isEyeInWater;
uniform int worldTime;
uniform int fogMode;

float timefract = worldTime;

//Calculate Time of Day
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

//dynamic calculations

float dynamicTorchlightBrightness = (1.0*TimeSunrise + 1.0*TimeNoon + 1.0*TimeSunset + 1.0*TimeMidnight)*TORCH_INTENSITY;


float animationTime = worldTime/20.0f;

float cdist(vec2 coord){
    return distance(coord,vec2(0.5))*2.0;
}

vec3 convertScreenSpaceToWorldSpace(vec2 co, float depth) {
    vec4 fragposition = gbufferProjectionInverse * vec4(vec3(co, depth) * 2.0 - 1.0, 1.0);
    fragposition /= fragposition.w;
    return fragposition.xyz;
}

vec3 convertCameraSpaceToScreenSpace(vec3 cameraSpace) {
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
    return screenSpace;
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float edepth(vec2 coord) {
	return texture2D(depthtex0,coord).z;
}

vec2 texel = vec2(1.0/viewWidth,1.0/viewHeight);
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

vec3 aux = texture2D(gaux1, texcoord.st).rgb;
vec3 sunPos = sunPosition;
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0f - 1.0f;

float pixeldepth = texture2D(depthtex0,texcoord.xy).x;
float handlight = handItemLight;

float jitter_speed = 2.2;
float torchlight_jitter1 = 1.0-sin(animationTime*5.4*jitter_speed+sin((animationTime*1.9*jitter_speed)+0.5)+sin((animationTime*1.9*jitter_speed)+0.2))*0.02;
float torch_lightmap = pow(aux.b*torchlight_jitter1,TORCH_ATTEN)*dynamicTorchlightBrightness;

float sky_lightmap = pow(aux.r,ATTENUATION);
float iswet = wetness*pow(sky_lightmap,5.0)*sqrt(0.5+max(dot(normal,normalize(upPosition)),0.0));
	
//poisson distribution for shadow sampling		
const vec2 circle_offsets[25] = vec2[25](vec2(-0.4894566f,-0.3586783f),
									vec2(-0.1717194f,0.6272162f),
									vec2(-0.4709477f,-0.01774091f),
									vec2(-0.9910634f,0.03831699f),
									vec2(-0.2101292f,0.2034733f),
									vec2(-0.7889516f,-0.5671548f),
									vec2(-0.1037751f,-0.1583221f),
									vec2(-0.5728408f,0.3416965f),
									vec2(-0.1863332f,0.5697952f),
									vec2(0.3561834f,0.007138769f),
									vec2(0.2868255f,-0.5463203f),
									vec2(-0.4640967f,-0.8804076f),
									vec2(0.1969438f,0.6236954f),
									vec2(0.6999109f,0.6357007f),
									vec2(-0.3462536f,0.8966291f),
									vec2(0.172607f,0.2832828f),
									vec2(0.4149241f,0.8816f),
									vec2(0.136898f,-0.9716249f),
									vec2(-0.6272043f,0.6721309f),
									vec2(-0.8974028f,0.4271871f),
									vec2(0.5551881f,0.324069f),
									vec2(0.9487136f,0.2605085f),
									vec2(0.7140148f,-0.312601f),
									vec2(0.0440252f,0.9363738f),
									vec2(0.620311f,-0.6673451f)
									);

float ctorspec(vec3 ppos, vec3 lvector, vec3 normal,float rough,float fpow) {
	//half vector
	vec3 pos = -normalize(ppos);
	vec3 cHalf = normalize(lvector + pos);
	
	// beckman's distribution function D
	float normalDotHalf = dot(normal, cHalf);
	float normalDotHalf2 = normalDotHalf * normalDotHalf;
	
	float roughness2 = 1/pow(2.0,8.0);
	float exponent = -(1.0 - normalDotHalf2) / (normalDotHalf2 * roughness2);
	float e = 2.71828182846;
	float D = pow(e, exponent) / (roughness2 * normalDotHalf2 * normalDotHalf2);
	
	// fresnel term F
	float normalDotEye = dot(normal, pos);
	float F = pow(1.0 - normalDotEye, fpow);
	F = 0.5*F + 0.5*(1-F);
	// self shadowing term G
	float normalDotLight = dot(normal, lvector);
	float X = 2.0 * normalDotHalf / dot(pos, cHalf);
	float G = min(1.0, min(X * normalDotLight, X * normalDotEye));
	float pi = 3.1415927;
	float CookTorrance = (D*F*G)/(normalDotEye*pi);
	
	return clamp(CookTorrance/pi,0.0,1.0);
}

float Blinn_Phong(vec3 ppos, vec3 lvector, vec3 normal,float fpow, float gloss, float visibility)  {
	/*
	vec3 npos = normalize(ppos);
	vec3 halfVector = normalize(lightVector - npos);
	float specular 	= max(0.0f, dot(halfVector, normal));
	specular = pow(specular,60.0);
	return clamp(specular,0.0,1.0);
	*/
	vec3 lightDir = vec3(lvector);
	
	vec3 surfaceNormal = normal;
	float cosAngIncidence = dot(surfaceNormal, lightDir);
	cosAngIncidence = clamp(cosAngIncidence, 0.0, 1.0);
	
	vec3 viewDirection = normalize(-ppos);
	
	vec3 halfAngle = normalize(lightDir + viewDirection);
	float blinnTerm = dot(surfaceNormal, halfAngle);
	
	float normalDotEye = dot(normal, normalize(ppos));
	float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
	fresnel = fresnel*0.5 + 0.5 * (1.0-fresnel);
	float pi = 3.1415927;
	float n =  pow(2.0,gloss*10.0);
	return (pow(blinnTerm, n )*((n+8.0)/(8*pi)))*fresnel*visibility;
}

float diffuseorennayar(vec3 pos, vec3 lvector, vec3 normal, float spec, float roughness) {
	
vec3 eyeDir = normalize(pos);

float roughness2 = roughness * roughness;
float PI = 3.1415927;
    
    // calculate intermediary values
    float NdotL = dot(normal, lvector);
    float NdotV = dot(normal, eyeDir); 

    float angleVN = acos(NdotV);
    float angleLN = acos(NdotL);
    
    float alpha = max(angleVN, angleLN);
    float beta = min(angleVN, angleLN);

    
    float roughnessSquared = roughness * roughness;
    float roughnessSquared9 = (roughnessSquared / (roughnessSquared + 0.09));
    
    // calculate C1, C2 and C3
    float C1 = 1.0 - 0.5 * (roughnessSquared / (roughnessSquared + 0.33));
    float C2 = 0.45 * roughnessSquared9;
    

        C2 *= sin(alpha);
 
    float powValue = (4.0 * alpha * beta) / (PI * PI);
    float C3  = 0.125 * roughnessSquared9 * powValue * powValue;
 
    // put it all together
    float L1 = max(0.0, NdotL) * (C1 +(C2*max(0.0,cos(angleLN-angleVN))*sin(alpha)));
    
	return clamp((L1),0.0,1.0);
}

float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

float interpolate(vec3 truepos,float center,vec3 poscenter,float value2,vec3 pos2,float value3,vec3 pos3,float value4,vec3 pos4,float value5,vec3 pos5) {
	/*
	float mix1 = mix(center,value2,1.0-length(truepos-pos2));
	float mix2 = mix(mix1,value3,1.0-length(truepos-pos3));
	float mix3 = mix(mix2,value4,1.0-length(truepos-pos4));
	return mix(mix3,value5,1.0-length(truepos-pos5));
	*/
	return center*(1.0-distance(truepos,poscenter))+value2*(1.0-distance(truepos,pos2))+value3*(1.0-distance(truepos,pos3))+value4*(1.0-distance(truepos,pos4))+value5*(1.0-distance(truepos,pos5));
}

#ifdef CELSHADING
vec3 celshade(vec3 clrr) {
	//edge detect
	float d = edepth(texcoord.xy);
	float dtresh = 1/(far-near)/5000.0;	
	vec4 dc = vec4(d,d,d,d);
	vec4 sa;
	vec4 sb;
	sa.x = edepth(texcoord.xy + vec2(-pw,-ph)*BORDER);
	sa.y = edepth(texcoord.xy + vec2(pw,-ph)*BORDER);
	sa.z = edepth(texcoord.xy + vec2(-pw,0.0)*BORDER);
	sa.w = edepth(texcoord.xy + vec2(0.0,ph)*BORDER);
	
	//opposite side samples
	sb.x = edepth(texcoord.xy + vec2(pw,ph)*BORDER);
	sb.y = edepth(texcoord.xy + vec2(-pw,ph)*BORDER);
	sb.z = edepth(texcoord.xy + vec2(pw,0.0)*BORDER);
	sb.w = edepth(texcoord.xy + vec2(0.0,-ph)*BORDER);
	
	vec4 dd = abs(2.0* dc - sa - sb) - dtresh;
	dd = vec4(step(dd.x,0.0),step(dd.y,0.0),step(dd.z,0.0),step(dd.w,0.0));
	
	float e = clamp(dot(dd,vec4(0.25f,0.25f,0.25f,0.25f)),0.0,1.0);
	return clrr*e;
}
#endif




/*
vec3 simplifiedSkyLight (vec3 fposition) {
vec3 sky_color = pow(ambient_color,vec3(2.2));
sky_color = mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength);
vec3 sVector = normalize(fposition);
vec3 upVector = normalize(upPosition);


float Lz = 1.0;
float T = acos(dot(sVector,upVector));
float S = acos(dot(lightVector,upVector));
float Y = acos(dot(lightVector,sVector));

vec3 L = (cos(S)+2.0*cos(T))*sky_color +(2.0*pow(max(cos(Y),0.0),4.0)+cos(S))*pow(sunlight_color,vec3(2.2));
return L * Lz;

}
*/
vec3 skyLightIntegral (vec3 fposition) {
vec3 sky_color = ambient_color*2.0;
sky_color = mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength);
vec3 sVector = normalize(fposition);
vec3 upVector = normalize(upPosition);

const float PI = 3.14159265359;

float Lz = SKY_BRIGHTNESS;
float T = max(acos(dot(sVector,upVector)),0.0); 
float S = max(acos(dot(lightVector,upVector)),0.0);
float Y = max(acos(dot(lightVector,sVector)),0.0);

float blueDif = (1+2.0*cos(T));
float sunDif =  (1.0+2.0*max(cos(Y),0.0));

float hemisphereIntegral = PI + 2.0*(sin(T+PI/2.0)-sin(T-PI/2.0));
float sunIntegral = PI + 2.0*max(sin(Y+PI/2.0)*sin(Y+PI/2.0)*sin(Y+PI/2.0)-sin(Y-PI/2.0)*sin(Y-PI/2.0)*sin(Y-PI/2.0),0.0);

return hemisphereIntegral*sky_color*Lz + sunIntegral*sunlight_color*(1-rainStrength*0.9);
}

float subSurfaceScattering(vec3 pos, float N) {

return pow(max(dot(lightVector,normalize(pos)),0.0),N)*(N+1)/6.28;

}

vec3 getSkyColor(vec3 fposition) {
//sky gradient
/*----------*/
vec3 sky_color = pow(sky_color,vec3(2.2))*2.0;
vec3 sVector = normalize(fposition);
vec3 upVector = normalize(upPosition);

sky_color = mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength);

float Lz = SKY_BRIGHTNESS;
float cosT = dot(sVector,upVector);
float cosS = dot(lightVector,upVector);
float S = acos(cosS);
float cosY = dot(lightVector,sVector);
float Y = acos(cosY);
float cosT2 = abs(cosT);

float L =   pow(((0.91+10*exp(-3*Y)+0.45*cosY*cosY)*(1.0-exp(-0.32/cosT2)))/((0.91+10*exp(-3*S)+0.45*cosS*cosS)*(1.0-exp(-0.32))),1.0-rainStrength*0.8);

sky_color = mix(sky_color,pow(sunglow_color,vec3(2.4)),1-exp(-0.3*L*(1-rainStrength*0.8)));


sky_color = vec3(L*Lz)*sky_color;
/*----------*/


//cloud generation
/*----------*/
vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition,1.0));
vec3 wvec = normalize(tpos);
vec3 wVector = normalize(tpos);
vec3 intersection = wVector*(30.0/wVector.y);


float cloudjitter_speed = 0.001;
float cloud_jitter = 1.2-sin(animationTime*5.4*cloudjitter_speed+sin((animationTime*1.9*cloudjitter_speed)+0.5)+sin((animationTime*1.9*cloudjitter_speed)+0.2))*(0.15);

float canHit = length(intersection)-length(tpos);

	vec2 wind = vec2(animationTime*(cos(animationTime/1000.0)+0.5),animationTime*(sin(animationTime/1000.0)+0.5))*0.5;
	
	
	vec3 wpos = tpos.xyz+cameraPosition;
	intersection.xz = intersection.xz + 2.0*cosT*intersection.xz;		//curve the cloud pattern, because sky is not 100% plane in reality
	vec2 coord = (intersection.xz+wind)/512.0;
	float noise = texture2D(noisetex,fract(coord.xy/(6.0*cloud_jitter))).x;
	noise += texture2D(noisetex,fract(coord.xy)).x/2.0;
	noise += texture2D(noisetex,fract(coord.xy*2.0)).x/4.0;
	noise += texture2D(noisetex,fract(coord.xy*4.0)).x/8.0;
	noise += texture2D(noisetex,fract(coord.xy*8.0)).x/18.0;
	noise += texture2D(noisetex,fract(coord.xy*16.0)).x/30.0;
	noise += texture2D(noisetex,fract(coord.xy*32.0)).x/70.0;
	noise += texture2D(noisetex,fract(coord.xy*64.0)).x/140.0;
	noise += texture2D(noisetex,fract(coord.xy*128.0)).x/220.0;
	
	float coverageVariance = cos(length(coord)*50.0)+0.05;
	float c = max(noise-1.025-coverageVariance*0.1+rainStrength*0.38,0.0);

	float cloud = (1.0 - (pow(0.2-rainStrength*0.19,c)))*max(cosT,0.0);
	float N = 12.0;
	vec3 cloud_color = skyLightIntegral(sVector)/1.6 + sunlight_color*48.0*pow(max(cosY,0.0),N)*(N+1)/6.28 * (cloud*0.5+0.5) * (1-rainStrength);	//coloring clouds
/*----------*/
return mix(sky_color,cloud_color,cloud);  //mix up sky color and clouds
}


float PosDot(vec3 v1,vec3 v2) {
return max(dot(v1,v2),0.0);
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
#ifndef DYNAMIC_HANDLIGHT
		handlight = 0.0;
#endif

	//unpack material flags
	float shadowexit = float(aux.g > 0.1 && aux.g < 0.3);
	float land = float(aux.g > 0.04);
	float iswater = float(aux.g > 0.04 && aux.g < 0.07);
	float translucent = float(aux.g > 0.3 && aux.g < 0.5);
	float hand = float(aux.g > 0.75 && aux.g < 0.85);
	float fresnel_pow = 4.0;
	float shading = 0.0f;
	float spec = 0.0;
	
	vec3 color = texture2D(gcolor, texcoord.st).rgb;
	color = pow(color,vec3(2.2));
	
	vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
	fragposition /= fragposition.w;
	
		vec4 worldposition = vec4(0.0);
		vec4 worldpositionraw = vec4(0.0);
		worldposition = gbufferModelViewInverse * fragposition;	
		float xzDistanceSquared = worldposition.x * worldposition.x + worldposition.z * worldposition.z;
		float yDistanceSquared  = worldposition.y * worldposition.y;
		worldpositionraw = worldposition;
		
		
	float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13500.0)/300.0,0.0,1.0) + clamp((time-22500.0)/300.0,0.0,1.0)-clamp((time-23400.0)/300.0,0.0,1.0));	//fading between sun/moon shadows
	float night = clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-22800.0)/200.0,0.0,1.0);
	
	if (land > 0.9 && isEyeInWater < 0.1) {
		float dist = length(fragposition.xyz);
		float distof = clamp(1.0-dist/shadowDistance,0.0,1.0);
		float distof2 = clamp(1.0-pow(dist/(shadowDistance*0.75),2.0),0.0,1.0);
		//float shadow_fade = clamp(distof*12.0,0.0,1.0);
		float shadow_fade = sqrt(clamp(1.0 - xzDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0) * clamp(1.0 - yDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0));

		
		/*--reprojecting into shadow space --*/

		worldposition = shadowModelView * worldposition;
		float comparedepth = -worldposition.z;
		worldposition = shadowProjection * worldposition;
		worldposition /= worldposition.w;
		float distb = sqrt(worldposition.x * worldposition.x + worldposition.y * worldposition.y);
		float distortFactor = (1.0f - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
		worldposition.xy *= 1.0f / distortFactor;
		worldposition = worldposition * 0.5f + 0.5f;
		/*---------------------------------*/
		
		
		float step = 3.0/shadowMapResolution*(1.0+rainStrength*5.0);
		//shadow_fade = 1.0-clamp((max(abs(worldposition.x-0.5),abs(worldposition.y-0.5))*2.0-0.9),0.0,0.1)*10.0;
		
		float NdotL = dot(normal, lightVector);
		float diffthresh = mix(pow(distortFactor*1.2,2.0)*(0.38/far)*(tan(acos(abs(NdotL)))) + (0.12/far), (0.28/far),(translucent+iswater));
		
		if (comparedepth > 0.0f &&	worldposition.s < 1.0f && worldposition.s > 0.0f && worldposition.t < 1.0f && worldposition.t > 0.0f) {
			if (shadowexit > 0.1 || (sky_lightmap < 0.01 && eyeBrightness.y < 2)) {
					shading = 0.0;
				}
			
			else {
			#ifdef HQ_SHADOW_FILTER
				step = 0.75/shadowMapResolution*(1.0+rainStrength*15.0);
				//diffthresh = 0.0018f * diffthresh * (0.5+(1.0-NdotL)*5.0*(1.0-translucent));
				float weight;
				float totalweight = 0.0;
				for(int i = 0; i < 25; i++){
					weight = exp(-pow(length(circle_offsets[i]),2.0)/2.0);
					shading += shadow2D(shadow,vec3(worldposition.st + circle_offsets[i]*step, worldposition.z-diffthresh*(2.0-weight))).x*weight;
					totalweight += weight;
				}
			
			shading /= totalweight;
			#endif
			
			step = 0.5/shadowMapResolution*(1.0+rainStrength*15.0);
			
			#ifdef SHADOW_FILTER
				shading = shadow2D(shadow,vec3(worldposition.st, worldposition.z-diffthresh/50)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(step,step), worldposition.z-diffthresh/50)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(step,-step), worldposition.z-diffthresh/50)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(-step,-step), worldposition.z-diffthresh/50)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(-step,step), worldposition.z-diffthresh/50)).x;
				shading = shading/5.0;
			#endif
			
			#ifndef SHADOW_FILTER
				#ifndef HQ_SHADOW_FILTER
				shading = shadow2D(shadow,vec3(worldposition.st, worldposition.z-diffthresh/300)).x;
				#endif
			#endif 
			}
		}
		
		else shading = 1.0;
		
		float ao = 1.0;
		
	#ifdef SSAO
		if (land > 0.9 && iswater < 0.9 && hand < 0.9) {
			vec3 norm = texture2D(gnormal,texcoord.xy).rgb*2.0-1.0;
			vec3 projpos = convertScreenSpaceToWorldSpace(texcoord.xy,pixeldepth); 
			float progress = 0.0;
			ao = 0.0;
			float projrad = clamp(distance(convertCameraSpaceToScreenSpace(projpos + vec3(ssaorad,ssaorad,ssaorad)).xy,texcoord.xy),0.05,0.1);
			
			for (int i = 1; i < nbdir; i++) {
				for (int j = 1; j < sampledir; j++) {
					vec2 samplecoord = vec2(cos(progress),sin(progress))*(j/sampledir)*projrad + texcoord.xy;
					float sample = texture2D(depthtex0,samplecoord).x;
					vec3 sprojpos = convertScreenSpaceToWorldSpace(samplecoord,sample);
					float angle = pow(min(1.0-dot(norm,normalize(sprojpos-projpos)),1.0),2.0);
					float dist = min(abs(ld(sample)-ld(pixeldepth)),ssaorad/200.0)/(ssaorad/200.0);
					float temp = min(dist+angle,1.0);
					ao += pow(temp,3.0);
					progress += (1.0-pow(temp,3.0))/nbdir*3.14;
				}
				progress = i*(6.28/nbdir);
			}
			ao /= (nbdir-1)*(sampledir-1);
		}
	#endif
		vec3 npos = normalize(fragposition.xyz);
		float sss_transparency = mix(0.0,0.75,translucent);		//subsurface scattering amount
		float sunlight_direct = max(dot(lightVector,normal),0.0);
		
		sunlight_direct = mix(sunlight_direct,1.0,translucent*0.8*shadow_fade);
		float sss = subSurfaceScattering(fragposition.xyz,30.0)*translucent*SUNLIGHTAMOUNT*2.0;
		sss = mix(0.0,sss,max(shadow_fade-0.1,0.0)*1.111)*0.5+0.5;
		shading = clamp(shading,0.0,1.0);
		float handLight = (handlight*8.0)/pow(1.0+length(fragposition.xyz/2.0),2.0)*sqrt(dot(normalize(fragposition.xyz), -normal)*0.5+0.5);
		
		/*
		const float PI = 3.1415927;
		vec3 underwaterpos = vec3(texcoord.st, texture2D(depthtex1, texcoord.st).r);
		underwaterpos = nvec3(gbufferProjectionInverse * nvec4(underwaterpos * 2.0 - 1.0));
		vec4 worldpositionuw = gbufferModelViewInverse * vec4(underwaterpos,1.0);	
		vec3 wpos = worldpositionuw.xyz + cameraPosition.xyz;
		float wave = 0.05 * sin(2 * PI * (frameTimeCounter*0.75 + wpos.x  + wpos.z / 2.0))
		 + 0.05 * sin(2 * PI * (frameTimeCounter*0.6 + wpos.x / 2.0 + wpos.z ));
		color.rgb += abs(wave)*sunlight_color*vec3(0.1,0.22,0.4)*shading*iswater*5.0;
		*/
		
	//Apply different lightmaps to image
		vec3 Sunlight_lightmap = mix(sunlight_color,vec3(0.5),rainStrength*0.9)*mix(max(sky_lightmap-rainStrength*0.95,0.0),shading*(1.0-rainStrength*0.95),shadow_fade)*SUNLIGHTAMOUNT *sunlight_direct*transition_fading ;
		/*
		float half_lambert = 1.0-sqrt(NdotL*0.5+0.5);
		float NdotUp = (dot(normal,normalize(upPosition))*0.5+0.5);
		vec3 amb = ambient_color;	
		vec3 reflected = sunlight_color*(half_lambert+(1.0-NdotUp))*0.25;
		float sky_inc = sqrt(direct*0.5+0.51);
		vec3 amb = (sky_inc*ambient_color+(1.0-sky_inc)*(sunlight_color+ambient_color*2.0)*vec3(0.2,0.24,0.27))*vec3(0.8,0.8,1.0);
		*/
		
		float visibility = sky_lightmap;
		float NdotUp = dot(normal,normalize(upPosition));
		float bouncefactor = (NdotUp*0.5+0.5);
		float cfBounce = (max(-NdotL,0.0))*0.33 + (1-bouncefactor)*0.33 + 0.5;
		
		vec3 aLightNormal = (skyLightIntegral(normal)+skyLightIntegral(-normal)*(0.5+translucent*0.33))/6.28;
		vec3 a_light =  aLightNormal;
		

		vec3 bounceSunlight = cfBounce*sunlight_color;
		
		
		vec3 sky_light = SHADOW_DARKNESS*a_light*ao * visibility;
		vec3 torchcolor = vec3(TORCH_COLOR_LIGHTING);
		vec3 Torchlight_lightmap = (torch_lightmap + handLight) *  torchcolor ;
		vec3 color_sunlight = Sunlight_lightmap;
		vec3 color_torchlight = Torchlight_lightmap;
		

		
		
	//Add all light elements together
		color = (bounceSunlight*bounceSunlight*sky_lightmap*0.00+sky_light + MIN_LIGHT*ao + Sunlight_lightmap + color_torchlight*ao  +  sss * sunlight_color * shading *(1.0-rainStrength*0.9)*transition_fading)*color;
		float gfactor = mix(0.0,1.0,iswater);
		spec = Blinn_Phong(fragposition.xyz,lightVector,normal,fresnel_pow,gfactor,shading*sunlight_direct) *land * (1.0-isEyeInWater);
		//spec =  ctorspec(fragposition.xyz,lightVector,normalize(normal),0.01,fresnel_pow) *land * (1.0-isEyeInWater) * shading * (1.0-night*0.75);
		
	}
	
	else if (isEyeInWater < 0.1 && (aux.g < 0.02) ){
	color = getSkyColor(fragposition.xyz) + color.rgb*night*3.0 ;
	
	}
	
	if(aux.g > 0.02 && aux.g < 0.04) color *= 5.0;

/* DRAWBUFFERS:31 */

#ifdef GODRAYS
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	float gr = 0.0;
	float truepos = pow(clamp(dot(-lightVector,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.5);		//temporary fix that check if the sun/moon position is correct
	if (truepos > 0.05) {	
		vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
		vec2 textCoord = texcoord.st;
		deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
		float avgdecay = 0.0;
		float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
		float disty = abs(texcoord.y-lightPos.y);
		float fallof = 1.0;
		float noise = getnoise(textCoord);
		
		for(int i=0; i < NUM_SAMPLES ; i++) {			
			textCoord -= deltaTextCoord;
			
			fallof *= 0.8;
			float sample = step(texture2D(gaux1, textCoord+ deltaTextCoord*noise*grnoise).g,0.01);
			gr += sample*fallof;
		}
	}
#endif
	
#ifdef CELSHADING
	if (iswater < 0.9) color = celshade(color);
#endif

	color = clamp(pow(color/MAX_COLOR_RANGE,vec3(1.0/2.2)),0.0,1.0);
	
	gl_FragData[0] = vec4(color, spec);
	gl_FragData[1] = vec4(vec3((gr/NUM_SAMPLES)),1.0);
}
