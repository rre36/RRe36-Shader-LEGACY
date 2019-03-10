#version 120

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

varying vec4 color;
varying vec2 texcoord;



void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;


	color = gl_Color;

	vec4 viewVertex = gl_ModelViewMatrix * gl_Vertex;

	gl_Position = gl_ProjectionMatrix * viewVertex;
	
	gl_FogFragCoord = 1.0;
	//gl_FogFragCoord = distance*sqrt(3.0);

}
