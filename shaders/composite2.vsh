#version 120

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 ambient_color;

uniform int worldTime;
uniform float rainStrength;

////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
const ivec4 ToD[25] = ivec4[25](ivec4(0,2,4,8), //hour,r,g,b
								ivec4(1,2,4,8),
								ivec4(2,2,4,8),
								ivec4(3,2,4,8),
								ivec4(4,2,4,8),
								ivec4(5,2,4,8),
								ivec4(6,120,80,35),
								ivec4(7,255,195,80),
								ivec4(8,255,200,97),
								ivec4(9,255,200,110),
								ivec4(10,255,205,135),
								ivec4(11,255,215,160),
								ivec4(12,255,215,160),
								ivec4(13,255,215,160),
								ivec4(14,255,205,125),
								ivec4(15,255,200,110),
								ivec4(16,255,200,97),
								ivec4(17,255,195,80),
								ivec4(18,255,190,70),
								ivec4(19,77,67,194),
								ivec4(20,2,4,8),
								ivec4(21,2,4,8),
								ivec4(22,2,4,8),
								ivec4(23,2,4,8),
								ivec4(24,2,4,8));

////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
const ivec4 ToD2[25] = ivec4[25](ivec4(0,20,40,90), //hour,r,g,b
								ivec4(1,20,40,90),
								ivec4(2,20,40,90),
								ivec4(3,20,40,90),
								ivec4(4,20,40,90),
								ivec4(5,60,120,180),
								ivec4(6,160,200,255),
								ivec4(7,160,205,255),
								ivec4(8,160,210,260),
								ivec4(9,165,220,270),
								ivec4(10,190,235,280),
								ivec4(11,205,250,290),
								ivec4(12,220,250,300),
								ivec4(13,205,250,290),
								ivec4(14,190,235,280),
								ivec4(15,165,220,270),
								ivec4(16,150,210,260),
								ivec4(17,140,200,255),
								ivec4(18,120,140,220),
								ivec4(19,50,55,110),
								ivec4(20,20,40,90),
								ivec4(21,20,40,90),
								ivec4(22,20,40,90),
								ivec4(23,20,40,90),
								ivec4(24,20,40,90));
							
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;
	
	//sunlight color
	float hour = worldTime/1000.0+6.0;
	if (hour > 24.0) hour = hour - 24.0;
	
	ivec4 temp = ToD[int(floor(hour))];
	ivec4 temp2 = ToD[int(floor(hour)) + 1];
	
	sunlight = mix(vec3(temp.yzw),vec3(temp2.yzw),(hour-float(temp.x))/float(temp2.x-temp.x))/255.0f;
	
	ivec4 tempa = ToD2[int(floor(hour))];
	ivec4 tempa2 = ToD2[int(floor(hour)) + 1];
	
	ambient_color = mix(vec3(tempa.yzw),vec3(tempa2.yzw),(hour-float(tempa.x))/float(tempa2.x-tempa.x))/255.0f;
}
