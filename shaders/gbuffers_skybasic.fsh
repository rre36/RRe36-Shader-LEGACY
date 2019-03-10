#version 120

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

/* DRAWBUFFERS:0 */

float timeSunrise;
float timeNoon;
float timeSunset;
float timeNight;
float timeMoon;
float timeSun;

uniform int worldTime;
uniform sampler2D texture;
uniform float rainStrength;

varying vec4 color;
varying vec4 texcoord;

varying vec3 normal;

const int FOGMODE_LINEAR = 9729;
const int FOGMODE_EXP = 2048;

uniform int fogMode;

float timefract = worldTime;

void main() {

//Calculate Time of Day
timeSunrise	= ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 1500.0)/1500.0));
timeNoon     	= ((clamp(timefract, 0.0, 1500.0)) / 1500.0) - ((clamp(timefract, 8000.0, 11500.0) - 8000.0) / 3500.0);
timeSunset   	= ((clamp(timefract, 8000.0, 11500.0) - 8000.0) / 3500.0) - ((clamp(timefract, 12000.0, 13000.0) - 12000.0) / 1000.0);
timeNight 		= ((clamp(timefract, 12000.0, 13000.0) - 12000.0) / 1000.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
timeMoon 		= ((clamp(timefract, 13000.0, 13750.0) - 13000.0) / 750.0) - ((clamp(timefract, 22000.0, 23000.0) - 22000.0) / 1000.0);
timeSun			= timeSunrise + timeNoon + timeSunset;

	////////////////////sky color////////////////////
	////////////////////sky color////////////////////
	////////////////////sky color////////////////////
	const ivec4 ToD3[25] = ivec4[25]
							(ivec4(0,	0,5,15),
							ivec4(1,	0,5,15),
							ivec4(2,	0,5,17),
							ivec4(3,	0,20,45),
							ivec4(4,	0,20,45),
							ivec4(5,	0,30,50),
							ivec4(6,	0,70,120),
							ivec4(7,	15,90,215),
							ivec4(8,	35,105,235),
							ivec4(9,	35,105,255),
							ivec4(10,	35,105,255),
							ivec4(11,	35,105,255),
							ivec4(12,	35,105,255),
							ivec4(13,	35,105,255),
							ivec4(14,	35,105,255),
							ivec4(15,	35,105,255),
							ivec4(16,	35,105,235),
							ivec4(17,	35,105,215),
							ivec4(18,	15,75,120),
							ivec4(19,	0,40,60),
							ivec4(20,	0,20,45),
							ivec4(21,	0,15,30),
							ivec4(22,	0,8,30),
							ivec4(23,	0,5,17),
							ivec4(24,	0,5,15));
	
	float hour = worldTime/1000.0+6.0;
	if (hour > 24.0) hour = hour - 24.0;
	
	
	ivec4 tempb = ToD3[int(floor(hour))];
	ivec4 tempb2 = ToD3[int(floor(hour)) + 1];
	
	vec3 colorSky = mix(vec3(tempb.yzw),vec3(tempb2.yzw),(hour-float(tempb.x))/float(tempb2.x-tempb.x))/255;
	colorSky *= 2.0f;
	
float skyBrightness = 0.5*timeSunrise + 1.0*timeNoon + 0.5*timeSunset + 0.1*timeNight;

colorSky *= skyBrightness;
	
	vec3 colorSky_rain = vec3(0.2, 0.2, 0.2); //rain

	vec3 skyColor = sqrt(pow(mix(colorSky, colorSky_rain, rainStrength*0.75),vec3(2.0))*2.0*colorSky); //rain	

	
	gl_FragData[0] = color;
	float fogFactor;
	if (fogMode == FOGMODE_EXP) {
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0);
		
	} else if (fogMode == FOGMODE_LINEAR) {
		fogFactor = 1.0 - clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0);
	} else {
		fogFactor = 1.0;
	}
	gl_FragData[0] = mix(gl_FragData[0],gl_Fog.color,1.0-fogFactor);
	
	gl_FragData[0].rgb = skyColor/2.0;
	gl_FragData[0] = mix(gl_FragData[0],gl_Fog.color,1.0-fogFactor);
}