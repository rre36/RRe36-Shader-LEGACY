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


//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

	#define GODRAYS			//in this step previous godrays result is blurred
		const float exposure = 2.8;			//godrays intensity
		const float density = 1.0;			
		const int NUM_SAMPLES = 9;			//increase this for better quality at the cost of performance 
		const float grnoise = 0.0;		//amount of noise 
		
	#define WATER_REFLECTIONS			
		#define REFLECTION_STRENGTH 1.0

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



//don't touch these lines if you don't know what you do!
const int maxf = 8;				//number of refinements
const float stp = 1.0;			//size of one step for raytracing algorithm
const float ref = 0.05;			//refinement multiplier
const float inc = 2.2;			//increasement factor at each step
//ground constants (lower quality)
const int Gmaxf = 4;				//number of refinements
const float Gstp = 1.2;			//size of one step for raytracing algorithm
const float Gref = 0.06;			//refinement multiplier
const float Ginc = 3.0;			//increasement factor at each step
/*--------------------------------*/
varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;
varying vec3 colorSunglow;
varying vec3 colorMoonglow;
varying vec3 fcolor;

varying float timeSunrise;
varying float timeNoon;
varying float timeSunset;
varying float timeNight;
varying float timeMoon;
varying float timeSun;

varying float eyeAdapt;

varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D noisetex;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 skyColor;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

uniform int isEyeInWater;
uniform int worldTime;
uniform float far;
uniform float near;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform int fogMode;
uniform ivec2 eyeBrightnessSmooth;
/*--------------------------------*/
vec2 wind[4] = vec2[4](vec2(abs(1/1000.-0.5),abs(1/1000.-0.5))+vec2(0.5),
					vec2(-abs(1/1000.-0.5),abs(1/1000.-0.5)),
					vec2(-abs(1/1000.-0.5),-abs(1/1000.-0.5)),
					vec2(abs(1/1000.-0.5),-abs(1/1000.-0.5)));
/*--------------------------------*/				
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
/*--------------------------------*/
float matflag = texture2D(gaux1,texcoord.xy).g;
/*--------------------------------*/
vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;
/*--------------------------------*/
float time = float(worldTime);
float night = clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-22800.0)/200.0,0.0,1.0);
/*--------------------------------*/
float sky_lightmap = texture2D(gaux1,texcoord.xy).r;
float iswet = wetness*pow(sky_lightmap,5.0)*sqrt(0.5+max(dot(normal,upVec),0.0));

vec3 specular = pow(texture2D(gaux3,texcoord.xy).rgb,vec3(2.2));
float specmap = (specular.r+specular.g*(iswet));
/*--------------------------------*/	
vec4 color = texture2DLod(composite,texcoord.xy,0);
/*--------------------------------*/

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}
/*--------------------------------*/
vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}
/*--------------------------------*/
float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}
/*--------------------------------*/

vec3 getSkyColor(vec3 fposition) {
/*--------------------------------*/
vec3 sky_color = vec3(35,95,255)/255;
vec3 nsunlight = normalize(pow(colorSunglow,vec3(2.2)));
vec3 sVector = normalize(fposition);
/*--------------------------------*/
sky_color = normalize(mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength)); //normalize colors in order to don't change luminance
/*--------------------------------*/
float Lz = 0.8;
float cosT = dot(sVector,upVec); 
float absCosT = max(cosT,0.0);
float cosS = dot(sunVec,upVec);
float S = acos(cosS);				
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);	
/*--------------------------------*/
float a = -1.;
float b = -0.25;
float c = 6.0;
float d = -0.7;
float e = 0.45;
/*--------------------------------*/

//sun sky color
float L =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*Y)+e*cosY*cosY); 
L = pow(L,1.0-rainStrength*0.8)*(1.0-rainStrength*0.83); //modulate intensity when raining
/*--------------------------------*/

float sunSkyLight = 4.3*timeSunrise + 5.5*timeNoon + 4.3*timeSunset + 4.3*timeNight;

vec3 skyColorSun = mix(sky_color, nsunlight,1-exp(-0.005*pow(L,sunSkyLight)*(1-rainStrength*0.5)))*L*0.5; //affect color based on luminance (0% physically accurate)
skyColorSun *= sunVisibility;
/*--------------------------------*/

//moon sky color
float McosS = MdotU;
float MS = acos(McosS);
float McosY = dot(moonVec,sVector);
float MY = acos(McosY);
/*--------------------------------*/
float L2 =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*MY)+e*McosY*McosY)+0.2;
L2 = pow(L2,1.0-rainStrength*0.8)*(1.0-rainStrength*0.15); //modulate intensity when raining
/*--------------------------------*/
vec3 skyColormoon = mix(moonlight,normalize(vec3(0.25,0.3,0.4))*length(moonlight),rainStrength*0.8)*L2 ; //affect color based on luminance (0% physically accurate)
skyColormoon *= moonVisibility;
sky_color = skyColormoon+skyColorSun;
/*--------------------------------*/
return sky_color;
}

vec3 sun_sunrise		= vec3(1.0f,0.6f,0.2f)*1.0f;
vec3 sun_noon			= vec3(1.0f,1.0f,1.0f)*1.0f;
vec3 sun_sunset		= vec3(1.0f,0.6f,0.2f)*1.0f;
vec3 sun_midnight	= vec3(1.0f,0.45f,0.1f)*1.0f;

vec3 sun_color			= (sun_sunrise*timeSunrise + sun_noon*timeNoon + sun_sunset*timeSunset + sun_midnight*timeNight);

vec3 drawSun(vec3 fposition,vec3 color,int land) {
vec3 sVector = normalize(fposition);

float angle = (1-max(dot(sVector,sunVec),0.0))*250.0;
float sun = exp(-angle*angle);
sun *= land*(1-rainStrength*0.995)*sunVisibility;
vec3 sunlight = mix(sun_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength*0.8);

return mix(color,sun_color*8.,sun);

}

vec3 skyGradient (vec3 fposition, vec3 color, vec3 fogclr) {

	return (fogclr*3.+color)/4.;		
	

}

float getAirDensity (float h) {
return (max((h),60.0)-40.0)/2;
}

vec3 calcFog(vec3 fposition, vec3 color, vec3 fogclr) {
	float density = (6000. -rainStrength*4000)*(0.4+sunVisibility*0.6);
	/*--------------------------------*/
	vec3 worldpos = (gbufferModelViewInverse*vec4(fposition,1.0)).rgb+cameraPosition;
	float d = length(fposition);
	float height = mix(getAirDensity (worldpos.y),0.1,rainStrength*0.8);
	/*--------------------------------*/
	float fog =   clamp(30.0*exp(-getAirDensity (cameraPosition.y)/density) * (1.0-exp( -d*height/density ))/height-0.3+rainStrength*0.25,0.0,1.);
	/*--------------------------------*/
return mix(color,normalize(fogclr)*mix(pow(length(fogclr),0.33)*vec3(0.35,0.4,0.5),pow(length(fogclr),0.1)*vec3(0.05),max(moonVisibility*(1-sunVisibility),rainStrength)),fog);	
}

float subSurfaceScattering(vec3 vec,vec3 pos, float N) {

return pow(max(dot(vec,normalize(pos)),0.0),N)*(N+1)/6.28;

}
float subSurfaceScattering2(vec3 vec,vec3 pos, float N) {

return pow(max(dot(vec,normalize(pos))*0.5+0.5,0.0),N)*(N+1)/6.28;

}

vec3 simplifiedCloud(vec3 fposition,vec3 color) {
/*--------------------------------*/
vec3 sVector = normalize(fposition);
float cosT = max(dot(normalize(sVector),upVec),0.0);
float McosY = MdotU;
float cosY = SdotU;
vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition,1.0));
vec3 wvec = normalize(tpos);
vec3 wVector = normalize(tpos);
/*--------------------------------*/
vec4 totalcloud = vec4(.0);
/*--------------------------------*/
vec3 intersection = wVector*((-400.0)/(wVector.y));
vec3 iSpos = (gbufferModelView*vec4(intersection,1.0)).rgb;
float cosT2 = pow(0.89,distance(vec2(0.0),intersection.xz)/100);
/*--------------------------------*/	
for (int i = 0;i<7;i++) {
	intersection = wVector*((-cameraPosition.y+500.0-i*3.66*(1+cosT2*cosT2*3.5)+400*sqrt(cosT2))/(wVector.y)); 			//curved cloud plane
	vec3 wpos = tpos.xyz+cameraPosition;
	vec2 coord1 = (intersection.xz+cameraPosition.xz)/1000.0/140.+wind[0]*0.07;
	vec2 coord = fract(coord1/2.0);
	/*--------------------------------*/
	float noise = texture2D(noisetex,coord).x;
	noise += texture2D(noisetex,coord*3.5).x/3.5;
	noise += texture2D(noisetex,coord*12.25).x/12.25;
	noise /= 1.4238;
	/*--------------------------------*/
	float cl = max(noise-0.6  +rainStrength*0.4,0.0)*(1-rainStrength*0.4);
	float density = max(1-cl*2.5,0.)*max(1-cl*2.5,0.)*(i/7.)*(i/7.);
	/*--------------------------------*/  
	vec3 c =(ambient_color + mix(sunlight,length(sunlight)*vec3(0.25,0.32,0.4),rainStrength)*sunVisibility + mix(moonlight,length(moonlight)*vec3(0.25,0.32,0.4),rainStrength) * moonVisibility) * 0.12 *density + (24.*subSurfaceScattering(sunVec,fposition,10.0)*pow(density,3.) + 10.*subSurfaceScattering2(sunVec,fposition,0.1)*pow(density,2.))*mix(sunlight,length(sunlight)*vec3(0.25,0.32,0.4),rainStrength)*sunVisibility +  (24.*subSurfaceScattering(moonVec,fposition,10.0)*pow(density,3.) + 10.*subSurfaceScattering2(moonVec,fposition,0.1)*pow(density,2.))*mix(moonlight,length(moonlight)*vec3(0.25,0.32,0.4),rainStrength)*moonVisibility;
	cl = max(cl-(abs(i-3.0)/3.)*0.15,0.)*0.146;
	/*--------------------------------*/
	totalcloud += vec4(c.rgb*exp(-totalcloud.a),cl);
	totalcloud.a = min(totalcloud.a,1.0);
	/*--------------------------------*/
	if (totalcloud.a > 0.999) break;
}

return mix(color.rgb,totalcloud.rgb*(1 - rainStrength*0.87)*6.,totalcloud.a*pow(cosT2,1.2));

}

vec4 raytrace(vec3 fragpos, vec3 normal,vec3 fogclr,vec3 sky_int) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
	
	//far black dots fix
	vec4 wrv = (gbufferModelViewInverse*vec4(rvector,1.0));
	wrv.y *= sign(dot(upVec,rvector));
	rvector = normalize((gbufferModelView*wrv).rgb);
	
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
	/*--------------------------------*/
    for(int i=0;i<40;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = abs(fragpos.z-spos.z);
		if(err < pow(length(vector)*2.0,1.15)){
                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 20.0), 0.0, 1.0);
                    color = texture2DLod(composite, pos.st,0);
					float land = texture2D(gaux1, pos.st).g;
					land = float(land < 0.03);
					
					spos.z = mix(spos.z,2000.0*(0.25+sunVisibility*0.75),land);
					if (land > 0.0) color.rgb = simplifiedCloud(sky_int,skyGradient(sky_int,pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE,fogclr));
					else color.rgb = calcFog(spos,pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE,fogclr);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=ref;
				
        
}
/*--------------------------------*/
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
/*--------------------------------*/
    }
    return color;
}	

vec4 raytraceGround(vec3 fragpos, vec3 normal,vec3 fogclr) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
	
    vec3 vector = Gstp * rvector;
	
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i=0;i<30;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
		if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = distance(fragpos.xyz,spos.xyz);
        if(err < pow(length(vector)*1.8,1.15)){

                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 20.0), 0.0, 1.0);
                    color = texture2DLod(composite, pos.st,0);
					float land = texture2D(gaux1, pos.st).g;
					land = float(land < 0.03);
					
					spos.z = mix(spos.z,2000.0*(0.25+sunVisibility*0.75),land);
					if (land > 0.0) color.rgb = skyGradient(spos,pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE,fogclr);
					else color.rgb = calcFog(spos,pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE,fogclr);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=Gref;
				
        
}
        vector *= Ginc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}

vec3 underwaterFog (float depth,vec3 color) {
	const float density = 48.0;
	float fog = exp(-depth/density);
	/*--------------------------------*/
	vec3 Ucolor= normalize(pow(vec3(0.1,0.4,0.6),vec3(2.2)))*(sqrt(3.0));
	/*--------------------------------*/
	vec3 c = mix(color*Ucolor,color,fog);
	vec3 fc = Ucolor*length(ambient_color)*0.02;
	return mix(fc,c,fog);
}

	
vec3 drawCloud(vec3 fposition,vec3 color) {
/*--------------------------------*/
vec3 sVector = normalize(fposition);
float cosT = max(dot(normalize(sVector),upVec),0.0);
float McosY = MdotU;
float cosY = SdotU;
vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition,1.0));
vec3 wvec = normalize(tpos);
vec3 wVector = normalize(tpos);
/*--------------------------------*/
vec4 totalcloud = vec4(.0);
/*--------------------------------*/
vec3 intersection = wVector*((-cameraPosition.y+400.0+400*sqrt(cosT))/(wVector.y));
vec3 iSpos = (gbufferModelView*vec4(intersection,1.0)).rgb;
float cosT2 = max(dot(normalize(iSpos),upVec),0.0);
/*--------------------------------*/	
for (int i = 0;i<11;i++) {
	intersection = wVector*((-cameraPosition.y+300.0-i*3.*(1+cosT2*cosT2*3.5)+500*sqrt(cosT2))/(wVector.y)); 			//curved cloud plane
	vec3 wpos = tpos.xyz+cameraPosition;
	vec2 coord1 = (intersection.xz+cameraPosition.xz)/1000.0/140.+wind[0]*0.07;
	coord1.x += -frameTimeCounter*0.00008;
	vec2 coord = fract(coord1/2.0);
	/*--------------------------------*/
	float noise = texture2D(noisetex,coord).x;
	noise += texture2D(noisetex,coord*2.5).x/3.5;
	noise += texture2D(noisetex,coord*15.25).x/12.25;
	noise += texture2D(noisetex,coord*48.87).x/42.87;	
	noise /= 1.4472;
	/*--------------------------------*/
	float cl = max(noise-0.5  +rainStrength*0.4,0.0)*(1-rainStrength*0.4);
	float density = max(1-cl*2.5,0.)*max(1-cl*2.5,0.)*(i/11.)*(i/11.);
	/*--------------------------------*/  
	vec3 c =(ambient_color + mix(sunlight,length(sunlight)*vec3(0.25,0.32,0.4),rainStrength)*sunVisibility + mix(moonlight,length(moonlight)*vec3(0.25,0.32,0.4),rainStrength) * moonVisibility) * 0.12 *density + (24.*subSurfaceScattering(sunVec,fragpos,10.0)*pow(density,3.) + 10.*subSurfaceScattering2(sunVec,fragpos,0.1)*pow(density,2.))*mix(sunlight,length(sunlight)*vec3(0.25,0.32,0.4),rainStrength)*sunVisibility +  (24.*subSurfaceScattering(moonVec,fragpos,10.0)*pow(density,3.) + 10.*subSurfaceScattering2(moonVec,fragpos,0.1)*pow(density,2.))*mix(moonlight,length(moonlight)*vec3(0.25,0.32,0.4),rainStrength)*moonVisibility;
	cl = max(cl-(abs(i-5.)/5.)*0.15,0.)*0.12;
	/*--------------------------------*/
	totalcloud += vec4(c.rgb*exp(-totalcloud.a),cl);
	totalcloud.a = min(totalcloud.a,1.0);
	/*--------------------------------*/
	if (totalcloud.a > 0.999) break;
}

return mix(color.rgb,totalcloud.rgb*(1 - rainStrength*0.87)*3.7,totalcloud.a*pow(cosT2,1.2));

}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	color.rgb = pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE;
	/*--------------------------------*/
	int land = int(matflag < 0.03);
	int iswater = int(matflag > 0.04 && matflag < 0.07);
	int hand  = int(matflag > 0.75 && matflag < 0.85);
	/*--------------------------------*/
	fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));
	vec3 tfpos = fragpos.xyz;
	if (land > 0.9) fragpos = (gbufferModelView*(gbufferModelViewInverse*vec4(fragpos,1.0)+vec4(.0,max(cameraPosition.y-70.,.0),.0,.0))).rgb;
	vec3 uPos  = nvec3(gbufferProjectionInverse * nvec4(vec3(texcoord.xy,texture2D(depthtex1,texcoord.xy).x) * 2.0 - 1.0));		//underwater position
	float cosT = dot(normalize(fragpos),upVec);
	vec3 fogclr = getSkyColor(fragpos.xyz);
	uPos.z = mix(uPos.z,2000.0*(0.25+sunVisibility*0.75),land);
	/*--------------------------------*/
	float normalDotEye = clamp((dot(normal, normalize(fragpos))),-1.0,0.0);
	float fresnel = pow(1.0 + normalDotEye, mix(4.0+rainStrength,5.,iswater));
	fresnel = mix(1.,fresnel,0.95)*0.5;
	/*--------------------------------*/	
	
		vec3 lc = mix(vec3(0.0),sunlight,sunVisibility);
		vec4 reflection = vec4(0.0);
		vec3 npos = normalize(fragpos);
		vec3 reflectedVector = reflect(normalize(fragpos), normalize(normal));
		float RdotU = (dot(reflectedVector,upVec)+1.)/2.;
		reflectedVector = fragpos + reflectedVector * (2000.0-fragpos.z);
		vec3 skyc = mix(getSkyColor(reflectedVector),vec3(0.002,0.005,0.002)*ambient_color*0.5,1-RdotU) ;
		vec3 sky_color = simplifiedCloud(reflectedVector,skyGradient(reflectedVector,vec3(0.0),skyc)*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0));
	if (iswater > 0.9 && isEyeInWater == 0) {

		/*--------------------------------*/
		reflection = raytrace(fragpos, normal,skyc,reflectedVector);
		reflection.rgb = mix(sky_color, reflection.rgb, reflection.a)+(color.a)*lc*(1.0-rainStrength)*(5.+SdotU*45.);			
		reflection.a = min(reflection.a,1.0);
		reflection.rgb = reflection.rgb*REFLECTION_STRENGTH;
		color.rgb = fresnel*reflection.rgb + (1-fresnel)*color.rgb;
		/*--------------------------------*/
    }
else if (land < 0.9 && hand < 0.1) {



		if (specmap*fresnel > 0.005) reflection = raytraceGround(fragpos, normal, sky_color);
		
		reflection.rgb = mix(sky_color, reflection.rgb, reflection.a)+(color.a)*lc*(1.0-rainStrength)*24.;		
		reflection.rgb = mix(reflection.rgb,reflection.rgb*normalize(color.rgb),0.0);
		reflection.rgb = reflection.rgb*3.;
		color.rgb = specmap*fresnel*reflection.rgb + (1-fresnel*specmap)*color.rgb;;


		}
		
	/*--------------------------------*/
	if (hand < 0.1) {
		if (land < 0.9) {
		if ((isEyeInWater == 1 && iswater > 0.9)|| (isEyeInWater == 0 && iswater < 0.9)) color.rgb = calcFog(uPos.xyz,color.rgb,(fogclr));
		else color.rgb = calcFog(fragpos.xyz,color.rgb,(fogclr));
		}
		else  {
		
	color.rgb = skyGradient(uPos.xyz,color.rgb,fogclr);
	color.rgb = drawSun(tfpos,color.rgb,land);
	
	if (cosT > 0.) color.rgb = drawCloud(tfpos.xyz,color.rgb);
	}
	}
	if (isEyeInWater == 1) color.rgb = underwaterFog(length(fragpos),color.rgb);
	/*--------------------------------*/
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	float gr = 0.0;
	
#ifdef GODRAYS
	float truepos = sunPosition.z/abs(sunPosition.z);		//1 -> sun / -1 -> moon
	vec3 rainc = mix(vec3(1.),fogclr*1.5,rainStrength);
	vec3 lightColor = mix(sunlight*sunVisibility*rainc,5*moonlight*moonVisibility*rainc,(truepos+1.0)/2.);
	/*--------------------------------*/
	const int nSteps = NUM_SAMPLES;
	const float blurScale = 0.002/nSteps*9.0;
	const int center = (nSteps-1)/2;
	vec3 blur = vec3(0.0);
	float tw = 0.0;
	const float sigma = 0.5;
	/*--------------------------------*/
	vec2 deltaTextCoord = normalize(texcoord.st - lightPos.xy)*blurScale;
	vec2 textCoord = texcoord.st - deltaTextCoord*center;
	float distx = texcoord.x*aspectRatio-lightPos.x*aspectRatio;
	float disty = texcoord.y-lightPos.y;
	float illuminationDecay = pow(max(1.0-sqrt(distx*distx+disty*disty),0.0),4.0);
	/*--------------------------------*/
		for(int i=0; i < nSteps ; i++) {
			textCoord += deltaTextCoord;
				
			float dist = (i-float(center))/center;
			float weight = exp(-(dist*dist)/(2.0*sigma));
				
			float sample = texture2D(gdepth, textCoord).r*weight;
			tw += weight;
			gr += sample;
		
		
		
	}
	vec3 grC = mix(lightColor,fogclr,rainStrength)*exposure*(gr/tw)*illuminationDecay * (1-isEyeInWater);
	color.xyz = (1-(1-color.xyz/48.0)*(1-grC.xyz/48.0))*48.0;

#endif
/*--------------------------------*/	
float visiblesun = 0.0;
float temp;
float nb = 0;
	
//calculate sun occlusion (only on one pixel) 
if (texcoord.x < 3.0*pw && texcoord.x < 3.0*ph) {
	for (int i = 0; i < 10;i++) {
		for (int j = 0; j < 10 ;j++) {
		temp = texture2D(gaux1,lightPos + vec2(pw*(i-5.0)*10.0,ph*(j-5.0)*10.0)).g;
		visiblesun +=  1.0-float(temp > 0.04) ;
		nb += 1;
		}
	}
	visiblesun /= nb;

}
/*--------------------------------*/
	color.rgb = clamp(pow(color.rgb/MAX_COLOR_RANGE,vec3(1.0/2.2)),0.0,1.0);

/* DRAWBUFFERS:5 */
	gl_FragData[0] = vec4(color.rgb,visiblesun);
}