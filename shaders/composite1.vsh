#version 120

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 lightVector;
varying vec3 ambient_color;
varying vec3 sky_color;
varying vec3 fog_color;
varying vec3 sunglow_color;
varying vec3 cloud_color;

uniform int worldTime;
uniform float rainStrength;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

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
							ivec4(8,240,210,90),
							ivec4(9,255,255,170),
							ivec4(10,300,280,240),
							ivec4(11,300,300,300),
							ivec4(12,300,300,300),
							ivec4(13,300,300,300),
							ivec4(14,300,300,300),
							ivec4(15,300,280,280),
							ivec4(16,255,200,165),
							ivec4(17,220,90,20),
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
							ivec4(5,5,30,50),
							ivec4(6,20,120,240),
							ivec4(7,5,170,250),
							ivec4(8,0,175,255),
							ivec4(9,0,180,285),
							ivec4(10,0,185,305),
							ivec4(11,0,185,345),
							ivec4(12,0,185,355),
							ivec4(13,0,185,355),
							ivec4(14,0,185,345),
							ivec4(15,0,165,305),
							ivec4(16,5,145,285),
							ivec4(17,20,120,255),
							ivec4(18,10,60,240),
							ivec4(19,0,40,60),
							ivec4(20,0,20,45),
							ivec4(21,0,15,30),
							ivec4(22,0,8,30),
							ivec4(23,0,5,17),
							ivec4(24,0,5,15));
							
	////////////////////sky color////////////////////
	////////////////////sky color////////////////////
	////////////////////sky color////////////////////
	const ivec4 ToD3[25] = ivec4[25](ivec4(0,0,5,15), //hour,r,g,b
							ivec4(1,0,5,15),
							ivec4(2,0,5,17),
							ivec4(3,0,20,45),
							ivec4(4,10,20,45),
							ivec4(5,5,30,50),
							ivec4(6,15,90,200),
							ivec4(7,5,120,215),
							ivec4(8,0,145,235),
							ivec4(9,0,180,265),
							ivec4(10,0,185,305),
							ivec4(11,0,185,345),
							ivec4(12,0,185,345),
							ivec4(13,0,185,345),
							ivec4(14,0,185,345),
							ivec4(15,0,165,305),
							ivec4(16,0,145,285),
							ivec4(17,20,120,255),
							ivec4(18,10,60,240),
							ivec4(19,0,40,60),
							ivec4(20,0,20,45),
							ivec4(21,0,15,30),
							ivec4(22,0,8,30),
							ivec4(23,0,5,17),
							ivec4(24,0,5,15));
							
	////////////////////fog color////////////////////
	////////////////////fog color////////////////////
	////////////////////fog color////////////////////
	const ivec4 ToD4[25] = ivec4[25](ivec4(0,0,5,15), //hour,r,g,b
							ivec4(1,0,5,15),
							ivec4(2,0,5,17),
							ivec4(3,0,20,45),
							ivec4(4,10,20,45),
							ivec4(5,5,30,50),
							ivec4(6,20,120,240),
							ivec4(7,40,170,250),
							ivec4(8,80,175,255),
							ivec4(9,150,180,255),
							ivec4(10,205,185,275),
							ivec4(11,205,205,295),
							ivec4(12,205,205,305),
							ivec4(13,205,205,305),
							ivec4(14,205,205,295),
							ivec4(15,150,185,275),
							ivec4(16,80,145,255),
							ivec4(17,20,120,255),
							ivec4(18,10,60,240),
							ivec4(19,0,40,60),
							ivec4(20,0,20,45),
							ivec4(21,0,15,30),
							ivec4(22,0,8,30),
							ivec4(23,0,5,17),
							ivec4(24,0,5,15));
							
////////////////////cloud color////////////////////
////////////////////cloud color////////////////////
////////////////////cloud color////////////////////
	const ivec4 ToD5[25] = ivec4[25](ivec4(0,0,8,11), //hour,r,g,b
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

////////////////////sunglow color////////////////////
////////////////////sunglow color////////////////////
////////////////////sunglow color////////////////////
	const ivec4 ToD6[25] = ivec4[25](ivec4(0,0,8,11), //hour,r,g,b
							ivec4(1,0,8,11),
							ivec4(2,0,8,12),
							ivec4(3,0,8,12),
							ivec4(4,0,8,15),
							ivec4(5,2,12,19),
							ivec4(6,160,75,0),
							ivec4(7,170,85,15),
							ivec4(8,180,120,90),
							ivec4(9,190,150,120),
							ivec4(10,205,190,160),
							ivec4(11,220,210,190),
							ivec4(12,230,230,210),
							ivec4(13,240,240,240),
							ivec4(14,230,230,210),
							ivec4(15,220,210,190),
							ivec4(16,200,165,140),
							ivec4(17,170,130,100),
							ivec4(18,160,55,40),
							ivec4(19,0,20,35),
							ivec4(20,0,15,30),
							ivec4(21,0,8,15),
							ivec4(22,0,8,12),
							ivec4(23,0,8,12),
							ivec4(24,0,8,11));
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	
	else {
		lightVector = normalize(moonPosition);
	}
	
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
	
	ivec4 tempb = ToD3[int(floor(hour))];
	ivec4 tempb2 = ToD3[int(floor(hour)) + 1];
	
	sky_color = mix(vec3(tempb.yzw),vec3(tempb2.yzw),(hour-float(tempb.x))/float(tempb2.x-tempb.x))/255.0f;
	
	ivec4 tempc = ToD4[int(floor(hour))];
	ivec4 tempc2 = ToD4[int(floor(hour)) + 1];
	
	fog_color = (mix(vec3(tempc.yzw),vec3(tempc2.yzw),(hour-float(tempc.x))/float(tempc2.x-tempc.x))/255.0f) - (rainStrength*0.3);
	
	ivec4 tempd = ToD5[int(floor(hour))];
	ivec4 tempd2 = ToD5[int(floor(hour)) + 1];
	
	cloud_color = (mix(vec3(tempd.yzw),vec3(tempd2.yzw),(hour-float(tempd.x))/float(tempd2.x-tempd.x))/255.0f) - (rainStrength*0.3);
	
	ivec4 tempe = ToD6[int(floor(hour))];
	ivec4 tempe2 = ToD6[int(floor(hour)) + 1];
	
	sunglow_color = mix(vec3(tempe.yzw),vec3(tempe2.yzw),(hour-float(tempe.x))/float(tempe2.x-tempe.x))/255.0f;
	
}
