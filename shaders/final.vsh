#version 120

/*
RRe36's shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 ambient_color;

uniform int worldTime;
uniform float rainStrength;

////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
	const ivec4 ToD[25] = ivec4[25](ivec4(0,0,8,11), //hour,r,g,b
							ivec4(1,0,8,11),
							ivec4(2,0,8,12),
							ivec4(3,0,8,12),
							ivec4(4,0,8,15),
							ivec4(5,2,12,19),
							ivec4(6,220,105,0),
							ivec4(7,230,180,20),
							ivec4(8,240,200,60),
							ivec4(9,255,255,140),
							ivec4(10,300,280,220),
							ivec4(11,300,300,300),
							ivec4(12,300,300,300),
							ivec4(13,300,300,300),
							ivec4(14,300,300,300),
							ivec4(15,300,280,280),
							ivec4(16,255,200,125),
							ivec4(17,240,100,20),
							ivec4(18,110,77,10),
							ivec4(19,0,20,35),
							ivec4(20,0,15,30),
							ivec4(21,0,8,15),
							ivec4(22,0,8,12),
							ivec4(23,0,8,12),
							ivec4(24,0,8,11));

////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
	const ivec4 ToD2[25] = ivec4[25](ivec4(0,0,5,15), //hour,r,g,b
							ivec4(1,0,5,15),
							ivec4(2,0,5,17),
							ivec4(3,0,20,45),
							ivec4(4,10,20,45),
							ivec4(5,15,30,50),
							ivec4(6,160,90,0),
							ivec4(7,190,130,40),
							ivec4(8,220,160,90),
							ivec4(9,255,200,150),
							ivec4(10,255,255,255),
							ivec4(11,255,255,255),
							ivec4(12,255,255,255),
							ivec4(13,255,255,255),
							ivec4(14,255,255,255),
							ivec4(15,255,230,210),
							ivec4(16,220,180,120),
							ivec4(17,160,40,0),
							ivec4(18,120,60,20),
							ivec4(19,20,40,60),
							ivec4(20,10,20,45),
							ivec4(21,5,15,30),
							ivec4(22,0,8,30),
							ivec4(23,0,5,17),
							ivec4(24,0,5,15));
							
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
