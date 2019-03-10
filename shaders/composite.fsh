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



const bool 		shadowtex1Mipmap = true;
const bool 		shadowtex1Nearest = false;
#define MAX_COLOR_RANGE 48.0


#define ALBEDO_MULTIPLIER 1. //texture brightness multiplier, reduce it when using bright ressourcepacks (summerfields for example)



/*
Disable an effect by putting "//" before "#define" when there is no number after
You can tweak the numbers, the impact on the shaders is self-explained in the variable's name or in a comment
*/

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

//----------Shadows----------//
	const int shadowMapResolution = 2048;		//shadowmap resolution
	const float shadowDistance = 128.0;		//draw distance of shadows
	#define SHADOW_DARKNESS 0.10		//shadow darkness levels, lower values mean darker shadows, see .vsh for colors 
	//#define HQ_SHADOW_FILTER	
	#define WIP_VARIABLE_PENUMBRA_SHADOWS
	//#define HQVPS
	//#define SHADOW_FILTER						//smooth shadows
//----------End of Shadows----------//

//----------Lighting----------//
	#define DYNAMIC_HANDLIGHT
	
	#define SUNLIGHTAMOUNT 4.0				//change sunlight strength , see .vsh for colors.
	
	#define TORCH_COLOR_LIGHTING 1.0f,0.3f,0.1 	//Torch Color RGB - Red, Green, Blue
		#define TORCH_INTENSITY 20				//torch light intensity

	//Minecraft lightmap (used for sky)
	#define ATTENUATION 1.3
	#define MIN_LIGHT 0.002
//----------End of Lighting----------//

//----------Visual----------//
#define GODRAYS
		const float density = 0.7;			
		const int NUM_SAMPLES = 7;				//increase this for better quality at the cost of performance
		const float grnoise = 0.9;			//amount of noise

	
	//#define CELSHADING
		#define BORDER 1.0

	#define SSAO					//works but is turned off by default due to performance cost
	const float ssaorad = 0.5;		//radius of ssao shadows
		
	const float	sunPathRotation	= -17.5f;		//determines sun/moon inclination /-40.0 is default - 0.0 is normal rotation
//----------End of Visual----------//

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



const float 	wetnessHalflife 		= 70.0f;
const float 	drynessHalflife 		= 70.0f;

const bool 		shadowHardwareFiltering0 = true;
const float 	shadowIntervalSize 		= 6.f;
const int 		noiseTextureResolution  = 1024;
#define SHADOW_MAP_BIAS 0.85
/*--------------------------------*/
varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;

varying vec4 lightS;

varying float handItemLight;
varying float eyeAdapt;

varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2DShadow shadow;
uniform sampler2D shadowtex1;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;
uniform int fogMode;
/*--------------------------------*/
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



vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float edepth(vec2 coord) {
	return texture2D(depthtex0,coord).z;
}

vec2 newtc = texcoord.xy;
vec3 sky_color = normalize(vec3(0.1, 0.35, 1.));

vec2 texel = vec2(1.0/viewWidth,1.0/viewHeight);

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

vec3 aux = texture2D(gaux1, texcoord.st).rgb;
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0f - 1.0f;


float pixeldepth = texture2D(depthtex0,texcoord.xy).x;
float handlight = handItemLight;

float modlmap = min(aux.b,0.9);
float torch_lightmap = max((1.0/pow((1-modlmap)*16.0,2.0)-(1.0*1.0)/(16.0*16.0))*TORCH_INTENSITY,0.0);


float sky_lightmap = pow(max(aux.r-1.5/16.,0.0)*(1/(1-1.5/16.)),ATTENUATION);

float iswet = wetness*pow(sky_lightmap,5.0)*sqrt(0.5+max(dot(normal,normalize(upPosition)),0.0));
	
vec3 specular = texture2D(gaux3,texcoord.xy).rgb;
float specmap = specular.r*(1.0-specular.b)+specular.g*iswet+specular.b*0.85*(1.0-specular.r);
	
//poisson distribution for shadow sampling		
const vec2 shadow_offsets[60] = vec2[60]  (  vec2(0.06120777f, -0.8370339f),
vec2(0.09790099f, -0.5829314f),
vec2(0.247741f, -0.7406831f),
vec2(-0.09391049f, -0.9929391f),
vec2(0.4241214f, -0.8359816f),
vec2(-0.2032944f, -0.70053f),
vec2(0.2894208f, -0.5542058f),
vec2(0.2610383f, -0.957112f),
vec2(0.4597653f, -0.4111754f),
vec2(0.1003582f, -0.2941186f),
vec2(0.3248212f, -0.2205462f),
vec2(0.4968775f, -0.6096044f),
vec2(0.770794f, -0.5416877f),
vec2(0.6429226f, -0.261653f),
vec2(0.6138752f, -0.7684944f),
vec2(-0.06001971f, -0.4079638f),
vec2(0.08106154f, -0.07295965f),
vec2(-0.1657472f, -0.2334092f),
vec2(-0.321569f, -0.4737087f),
vec2(-0.3698382f, -0.2639024f),
vec2(-0.2490126f, -0.02925519f),
vec2(-0.4394466f, -0.06632736f),
vec2(-0.6763983f, -0.1978866f),
vec2(-0.5428631f, -0.3784158f),
vec2(-0.3475675f, -0.9118061f),
vec2(-0.1321516f, 0.2153706f),
vec2(-0.3601919f, 0.2372792f),
vec2(-0.604758f, 0.07382818f),
vec2(-0.4872904f, 0.4500539f),
vec2(-0.149702f, 0.5208581f),
vec2(-0.6243932f, 0.2776862f),
vec2(0.4688022f, 0.04856517f),
vec2(0.2485694f, 0.07422727f),
vec2(0.08987152f, 0.4031576f),
vec2(-0.353086f, 0.7864715f),
vec2(-0.6643087f, 0.5534591f),
vec2(-0.8378839f, 0.335448f),
vec2(-0.5260508f, -0.7477183f),
vec2(0.4387909f, 0.3283032f),
vec2(-0.9115909f, -0.3228836f),
vec2(-0.7318214f, -0.5675083f),
vec2(-0.9060445f, -0.09217478f),
vec2(0.9074517f, -0.2449507f),
vec2(0.7957709f, -0.05181496f),
vec2(-0.1518791f, 0.8637156f),
vec2(0.03656881f, 0.8387206f),
vec2(0.02989202f, 0.6311651f),
vec2(0.7933047f, 0.4345242f),
vec2(0.3411767f, 0.5917205f),
vec2(0.7432346f, 0.204537f),
vec2(0.5403291f, 0.6852565f),
vec2(0.6021095f, 0.4647908f),
vec2(-0.5826641f, 0.7287358f),
vec2(-0.9144157f, 0.1417691f),
vec2(0.08989539f, 0.2006399f),
vec2(0.2432684f, 0.8076362f),
vec2(0.4476317f, 0.8603768f),
vec2(0.9842657f, 0.03520538f),
vec2(0.9567313f, 0.280978f),
vec2(0.755792f, 0.6508092f));
									
//second array								
const vec2 check_offsets[25] = vec2[25](vec2(-0.4894566f,-0.3586783f),
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
							

float Blinn_Phong(vec3 ppos, vec3 lvector, vec3 normal,float fpow, float gloss, float visibility)  {
	vec3 lightDir = vec3(lvector);
	
	vec3 surfaceNormal = normal;
	float cosAngIncidence = dot(surfaceNormal, lightDir);
	cosAngIncidence = clamp(cosAngIncidence, 0.0, 1.0);
	
	vec3 viewDirection = normalize(-ppos);
	
	vec3 halfAngle = normalize(lightDir + viewDirection);
	float blinnTerm = dot(surfaceNormal, halfAngle);
	
	float normalDotEye = dot(normal, normalize(ppos));
	float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
	fresnel = fresnel*0.85 + 0.15 * (1.0-fresnel);
	float pi = 3.1415927;
	float n =  pow(2.0,gloss*8.0+log(1+length(ppos)/2.));
	return (pow(blinnTerm, n )*((n+8.0)/(8*pi)))*visibility;
}

float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

#ifdef CELSHADING
vec3 celshade(vec3 clrr) {
	//edge detect
	float d = edepth(newtc.xy);
	float dtresh = 1/(far-near)/5000.0;	
	vec4 dc = vec4(d,d,d,d);
	vec4 sa;
	vec4 sb;
	sa.x = edepth(newtc.xy + vec2(-pw,-ph)*BORDER);
	sa.y = edepth(newtc.xy + vec2(pw,-ph)*BORDER);
	sa.z = edepth(newtc.xy + vec2(-pw,0.0)*BORDER);
	sa.w = edepth(newtc.xy + vec2(0.0,ph)*BORDER);
	
	//opposite side samples
	sb.x = edepth(newtc.xy + vec2(pw,ph)*BORDER);
	sb.y = edepth(newtc.xy + vec2(-pw,ph)*BORDER);
	sb.z = edepth(newtc.xy + vec2(pw,0.0)*BORDER);
	sb.w = edepth(newtc.xy + vec2(0.0,-ph)*BORDER);
	
	vec4 dd = abs(2.0* dc - sa - sb) - dtresh;
	dd = vec4(step(dd.x,0.0),step(dd.y,0.0),step(dd.z,0.0),step(dd.w,0.0));
	
	float e = clamp(dot(dd,vec4(0.25f,0.25f,0.25f,0.25f)),0.0,1.0);
	return clrr*e;
}
#endif



float subSurfaceScattering(vec3 pos, float N) {

return pow(max(dot(lightVector,normalize(pos)),0.0),N)*(N+1)/6.28;

}

float PosDot(vec3 v1,vec3 v2) {
return max(dot(v1,v2),0.0);
}

float waterH(vec3 posxz) {

float wave = 0.0;

float factor = 1.0;
float amplitude = 0.2;
float speed = 4.0;
float size = 0.2;

float px = posxz.x/50.0 + 250.0;
float py = posxz.z/50.0  + 250.0;

float fpx = abs(fract(px*20.0)-0.5)*2.0;
float fpy = abs(fract(py*20.0)-0.5)*2.0;

float d = length(vec2(fpx,fpy));

for (int i = 0; i < 3; i++) {
wave -= d*factor*cos( (1/factor)*px*py*size + 1.0*frameTimeCounter*speed);
factor /= 2;
}

factor = 1.0;
px = -posxz.x/50.0 + 250.0;
py = -posxz.z/150.0 - 250.0;

fpx = abs(fract(px*20.0)-0.5)*2.0;
fpy = abs(fract(py*20.0)-0.5)*2.0;

d = length(vec2(fpx,fpy));
float wave2 = 0.0;
for (int i = 0; i < 3; i++) {
wave2 -= d*factor*cos( (1/factor)*px*py*size + 1.0*frameTimeCounter*speed);
factor /= 2;
}

return amplitude*wave2+amplitude*wave;
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
	vec2 newtc = texcoord.xy;
/*--------------------------------*/
	//unpack material flags
	float land = float(aux.g > 0.04);
	float iswater = float(aux.g > 0.04 && aux.g < 0.07);
	float translucent = float(aux.g > 0.3 && aux.g < 0.5);
	float tallgrass = float(aux.g > 0.42 && aux.g < 0.48);
	float hand = float(aux.g > 0.75 && aux.g < 0.85);
	float emissive = float(aux.g > 0.58 && aux.g < 0.62);
	float shading = 0.0f;
	float spec = 0.0;
/*--------------------------------*/
		float roughness = mix(1.0-specular.b,0.005,iswater);
	if (specular.r+specular.g+specular.b < 1.0/255.0 && iswater < 0.09) roughness = 0.99;
	
	float fresnel_pow = pow(roughness,1.25+iswet*0.75)*5.0;
	if (iswater > 0.9) fresnel_pow=5.0;

/*--------------------------------*/	
	vec3 color = texture2D(gcolor, newtc.st).rgb;
	color = pow(color,vec3(2.2))*(.75+tallgrass*0.2)*ALBEDO_MULTIPLIER;
	
	//limit overbright textures
	float colLength = length(color);
	if (colLength > 0.5) colLength = 0.5+max(colLength-0.5,0.0)*.5;
	color = normalize(color)*colLength/sqrt(3.)*0.9;
/*--------------------------------*/	
	
	float NdotL = dot(lightVector,normal);
	float NdotUp = dot(normal,upVec);
/*--------------------------------*/	
	vec4 fragposition = gbufferProjectionInverse * vec4(newtc.s * 2.0f - 1.0f, newtc.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
	fragposition /= fragposition.w;
	
	vec4 worldposition = vec4(0.0);
	vec4 worldpositionraw = vec4(0.0);
	worldposition = gbufferModelViewInverse * fragposition;	
	float xzDistanceSquared = worldposition.x * worldposition.x + worldposition.z * worldposition.z;
	float yDistanceSquared  = worldposition.y * worldposition.y;
	worldpositionraw = worldposition;
/*--------------------------------*/		
		
	float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13500.0)/300.0,0.0,1.0) + clamp((time-22500.0)/300.0,0.0,1.0)-clamp((time-23400.0)/300.0,0.0,1.0));	//fading between sun/moon shadows
/*--------------------------------*/	
	vec3 uPos = vec3(.0);
	
	if (iswater > 0.9) {
		vec3 posxz = worldposition.xyz+cameraPosition;
	posxz.x += sin(posxz.z+frameTimeCounter)*0.25;
	posxz.z += cos(posxz.x+frameTimeCounter*0.5)*0.25;
	
		float deltaPos = 0.4;
		float h0 = waterH(posxz);
		float h1 = waterH(posxz - vec3(deltaPos,0.0,0.0));
		float h2 = waterH(posxz - vec3(0.0,0.0,deltaPos));
	
		float dX = ((h0-h1))/deltaPos;
		float dY = ((h0-h2))/deltaPos;
	
		float nX = sin(atan(dX));
		float nY = sin(atan(dY));
	
		vec3 refract = normalize(vec3(nX,nY,1.0));

	
		float refMult = 0.005-dot(normal,normalize(fragposition).xyz)*0.003;
	
		vec4 rA = texture2D(gcolor, newtc.st + refract.xy*refMult);
		rA.rgb = pow(rA.rgb,vec3(2.2));
		vec4 rB = texture2D(gcolor, newtc.st);
		rB.rgb = pow(rB.rgb,vec3(2.2));
	
		float mask = texture2D(gaux1, newtc.st + refract.xy*refMult).g;
		mask =  float(mask > 0.04 && mask < 0.07);
		newtc = (newtc.st + refract.xy*refMult)*mask + texcoord.xy*(1-mask);
	
		color.rgb = pow(texture2D(gcolor,newtc.xy).rgb,vec3(2.2));
	
		float uDepth = texture2D(depthtex1,newtc.xy).x;
		uPos  = nvec3(gbufferProjectionInverse * nvec4(vec3(newtc.xy,uDepth) * 2.0 - 1.0));	
	}
/*--------------------------------*/	
	
	if (land > 0.9) {
		float sky_occ = 0.0;
		float shadow_fade = sqrt(clamp(1.0 - xzDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0) * clamp(1.0 - yDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0));

		
		/*--reprojecting into shadow space --*/
		worldposition = shadowModelView * worldposition;
		float comparedepth = abs(worldposition.z);
		worldposition = shadowProjection * worldposition;
		worldposition /= worldposition.w;
		float distb = sqrt(worldposition.x * worldposition.x + worldposition.y * worldposition.y);
		float distortFactor = (1.0f - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
		worldposition.xy *= 1.0f / distortFactor; 
		worldposition = worldposition * 0.5f + 0.5f;
		/*---------------------------------*/
		
		float rescale = ((1.0f - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS);
		
		float step = 3.0/shadowMapResolution*(1.0+rainStrength*5.0);
		float NdotL = dot(normal, lightVector);
		
		float diffthresh = (pow(distortFactor*1.2,2.0)*(0.2/148.0)*(tan(acos(abs(NdotL)))) + (0.02/148.0))*(1.0+iswater*2.0);
		diffthresh = mix(diffthresh,0.0005,translucent)*(1.+tallgrass*0.1*clamp(tan(acos(abs(NdotL))),0.0,2.));
		
		if (worldposition.s < 0.99 && worldposition.s > 0.01 && worldposition.t < 0.99 && worldposition.t > 0.01 ) {

			if ((NdotL < 0.0 && translucent < 0.1) || (sky_lightmap < 0.01 && eyeBrightness.y < 2)) {
					shading = 0.0;
				}
			
			else {
			/*--------------------------------*/
			#ifdef HQ_SHADOW_FILTER
				step = 1.25/shadowMapResolution*(1.0+rainStrength*5.0);
				float weight;
				float totalweight = 0.0;
				float sigma = 0.25;
				float A = 1.0/sqrt(2.0*3.14159265359*sigma);
				
				for(int i = 0; i < 60; i++){
					float dist = length(shadow_offsets[i]);
					float weight = A*exp(-(dist*dist)/(2.0*sigma));
					shading += shadow2D(shadow,vec3(worldposition.st + shadow_offsets[i]*step, worldposition.z-diffthresh*(2.0-weight))).x;
					totalweight += 1;
				}
			
			shading /= totalweight;
			#endif
			/*--------------------------------*/
			step = 0.625/shadowMapResolution*(1.0+rainStrength*5.0);
			#ifdef SHADOW_FILTER
				shading = shadow2D(shadow,vec3(worldposition.st, worldposition.z-diffthresh)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(step,0), worldposition.z-diffthresh*2)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(-step,0), worldposition.z-diffthresh*2)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(0,step), worldposition.z-diffthresh*2)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(0,-step), worldposition.z-diffthresh*2)).x;
				shading = shading/5.0;
			#endif
			/*--------------------------------*/
			#ifndef SHADOW_FILTER
				#ifndef HQ_SHADOW_FILTER
				shading = shadow2D(shadow,vec3(worldposition.st, worldposition.z-diffthresh)).x;
				#endif
			#endif 
			/*--------------------------------*/
			#ifdef WIP_VARIABLE_PENUMBRA_SHADOWS

				float avgdepth = .0;
				vec2 scales = vec2(0.,35.);
				float mult = 9.0;
				
				//using texture filtering instead of multiple samples for more sample coherence over pixels, plus huge performance improvement
				float ssample = comparedepth - (0.05 + (texture2DLod(shadowtex1, worldposition.st,6).z) * (256.0 - 0.05));
				avgdepth = clamp(ssample, scales.x, scales.y)/(scales.y);
							
				avgdepth = (avgdepth)*mult;
							
				diffthresh *= avgdepth+1.;			
				step =(0.15/shadowMapResolution*(1.+2.*tallgrass)+(avgdepth)/shadowMapResolution)/rescale*1.25*(1.0+rainStrength*5.0);
				float weight;
				
				for(int i = 0; i < 60; i++){
					float dist = length(shadow_offsets[i]);
					shading += shadow2D(shadow,vec3(worldposition.st + shadow_offsets[i]*step, worldposition.z-diffthresh*(1.0+dist))).x*exp(-dist*dist/0.3);
					weight += exp(-dist*dist/0.3);
				}

				
			shading /= weight;

			#endif
			/*--------------------------------*/
							
							
			}
		}
		else shading = 1.0;
/*--------------------------------*/		
		if (sky_lightmap < 0.02 && eyeBrightness.y < 2) {
			shading = 0.0;
		}
/*--------------------------------*/				
		float ao = 1.0;
		vec3 avgDir = vec3(.0);
		float tweight = 0.0;
/*--------------------------------*/
#ifdef SSAO
	
	if (land > 0.9 && iswater < 0.9 && hand < 0.9) {
	
	
		vec3 norm = texture2D(gnormal,texcoord.xy).rgb*2.0-1.0;
		vec3 projpos = convertScreenSpaceToWorldSpace(texcoord.xy,pixeldepth); 
		float noiseAO = getnoise(texcoord.xy)*2.0-1.;
		ao = 0.0;
		
		float projrad = clamp(distance(convertCameraSpaceToScreenSpace(projpos + ssaorad).xy,texcoord.xy),0.0,120*pw);
		
		for (int i = 0; i < 25; i++) {

				vec2 samplecoord = check_offsets[i]*projrad+ texcoord.xy + noiseAO*projrad*0.05;
				float sample = texture2D(depthtex0,samplecoord).x;
				vec3 sprojpos = convertScreenSpaceToWorldSpace(samplecoord,sample);
				
				float dist = pow(min(distance(sprojpos,projpos),2.5)/2.5,5.);
				float angle = pow(min(1.0-(dot(norm,normalize(sprojpos-projpos))),1.0),2.);
				

				float temp = min(dist+pow(angle,0.33),1.0);
				ao += pow(min(dist+angle,1.),0.5);
				tweight += (1-temp)*(1-temp)*(1-temp);
				avgDir += normalize(sprojpos-projpos)*(1-temp)*(1-temp)*(1-temp);
			}

		avgDir /= tweight;
		ao /= 25.;
		ao = pow(ao,2.);
	}
	
#endif
		
		/*--------------------------------*/
				
		vec3 npos = normalize(fragposition.xyz);

		float diffuse = max(dot(lightVector,normal),0.0);
		
		diffuse = mix(diffuse,1.0,translucent*0.8);
		float sss = subSurfaceScattering(fragposition.xyz,30.0)*SUNLIGHTAMOUNT;
		sss = (mix(0.0,sss,max(shadow_fade-0.5,0.0)*2.0))*translucent;
		
		/*--------------------------------*/
			
		float mfp = min(1-clamp(length(fragposition.xyz),0.0,16.0)/16.0,0.85);		
		float handLight = (1.0/pow((1-mfp)*16.0,2.0))*TORCH_INTENSITY*handlight*sqrt(dot(normalize(fragposition.xyz), -normal)*0.5+0.51);
		
		/*--------------------------------*/
		shading *= 1-isEyeInWater;
		
		vec3 light_col =  mix(pow(sunlight,vec3(2.2)),moonlight,moonVisibility);
		light_col = mix(light_col,vec3(length(light_col))*vec3(0.25,0.32,0.4),rainStrength);
		vec3 Sunlight_lightmap = light_col*shading*(1.0-rainStrength)*SUNLIGHTAMOUNT *diffuse*transition_fading ;
		/*--------------------------------*/
		vec3 Ucolor= normalize(vec3(0.1,0.4,0.6));

		//we'll suppose water plane have same height above pixel and at pixel water's surface
		vec3 uVec = fragposition.xyz-uPos;
		float UNdotUP = abs(dot(normalize(uVec),normal));
		float depth = length(uVec)*UNdotUP;
		float sky_absorbance = mix(mix(1.0,exp(-depth/2.5)*0.2,iswater),1.0,isEyeInWater);
		/*--------------------------------*/

		
		vec4 occlusion = vec4(-normalize(avgDir),length(avgDir));
		
		float visibility = sky_lightmap;
		float bouncefactor = (NdotUp*0.33+0.67);
		float cfBounce = ((-NdotL*0.45+0.56) + (1-bouncefactor)*0.4)*mix(pow(clamp(dot(occlusion.rgb,-lightVector),0.0,1.),2.0),1.0,ao)*mix(pow(clamp(dot(occlusion.rgb,-upVec),0.0,1.),2.0),1.0,ao);
		
		

		vec3 bounceSunlight = 3.2*cfBounce*light_col*visibility*visibility*visibility*SHADOW_DARKNESS * (1-rainStrength*0.9)*transition_fading;
		
		
		vec3 skycolor = ambient_color;

		vec3 sky_light = SHADOW_DARKNESS*skycolor*visibility*bouncefactor*(transition_fading*0.5+0.5)*mix(pow(clamp(dot(occlusion.rgb,upVec),0.0,1.),2.0),1.0,ao);

		vec3 torchcolor = vec3(TORCH_COLOR_LIGHTING)*eyeAdapt;
		vec3 Torchlight_lightmap = (torch_lightmap + handLight) *  torchcolor ;
		vec3 color_torchlight = Torchlight_lightmap*ao;
		/*--------------------------------*/
		color = (((bounceSunlight+sky_light) * (1.0+tallgrass*0.1) + MIN_LIGHT*ao + color_torchlight) + Sunlight_lightmap +  sss * light_col * shading *(1.0-rainStrength*0.9)*transition_fading)*sky_absorbance*color;
		if (iswater > 0.9) color = mix(Ucolor*length(ambient_color)*0.01*sky_lightmap,color,exp(-depth/16));
		/*--------------------------------*/
		
			float gfactor = mix(roughness*0.5+0.01,1.,iswater);
		spec = Blinn_Phong(fragposition.xyz,lightVector,normal,fresnel_pow,gfactor,shading*diffuse) *land * (1.0-isEyeInWater)*transition_fading;
		/*--------------------------------*/
	}
	

	
	else {
	color = pow(texture2D(gcolor,newtc.xy).rgb,vec3(2.2))*(1-sunVisibility)*7.0*sqrt(max(dot(upVec,normalize(fragposition.xyz)),0.0)) ;

	}

/*--------------------------------*/

float gr = 0.0;
#ifdef GODRAYS
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	

		vec2 deltaTextCoord = vec2( newtc.st - lightPos.xy );
		vec2 textCoord = newtc.st;
		deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
		float avgdecay = 0.0;
		float distx = abs(newtc.x*aspectRatio-lightPos.x*aspectRatio);
		float disty = abs(newtc.y-lightPos.y);
		float fallof = 1.0;
		float noise = getnoise(textCoord);
		
		for(int i=0; i < NUM_SAMPLES ; i++) {			
			textCoord -= deltaTextCoord;

			fallof *= 0.7;
			float sample = step(texture2D(gaux1, textCoord+ deltaTextCoord*noise*grnoise).g,0.01);
			gr += sample*fallof;
		}

#endif
/*--------------------------------*/
#ifdef CELSHADING
	if (iswater < 0.9) color = celshade(color);
#endif
/*--------------------------------*/
	color = pow(color/MAX_COLOR_RANGE,vec3(1.0/2.2));
/* DRAWBUFFERS:31 */
	gl_FragData[0] = vec4(color, spec);
	gl_FragData[1] = vec4(vec3((gr/NUM_SAMPLES)),1.0);
}
