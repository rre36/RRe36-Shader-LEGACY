#version 120
#extension GL_ARB_shader_texture_lod : enable 
/* DRAWBUFFERS:0247 */

/*
RRe36's Shaders, derived from Chocapic13 v4
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
IMPORTANT: Placing Slashes in front of lines like '#define FILTER_LEVEL 15.0' will cause errors!
*/

//-------- Adjustable Variables --------//

	//---- Normal Mapping ----//
		#define NORMAL_MAPPING
			#define NORMAL_MAP_MAX_ANGLE 1.0
		
	//---- End of Normal Mapping ----//
	
	//---- Parallax Displacement aka. POM ----//
		//#define POM
			#define POM_MAP_RES 96.0
			#define POM_DEPTH (1.0/20.0)
			const float MAX_OCCLUSION_DISTANCE = 32.0;
			const float MIX_OCCLUSION_DISTANCE = 28.0;
			const int   MAX_OCCLUSION_POINTS   = 12;
		
	//---- End of Parallax Displacement ----//
	
	//---- Lightmaps ----//
		#define MIN_LIGHTAMOUNT 0.1		//affect the minecraft lightmap (not torches)
		#define MINELIGHTMAP_EXP 2.0		//affect the minecraft lightmap (not torches)
		
	//---- End of Lightmaps ----//
	
//-------- End of Adjustable Variables --------//

/* Here, intervalMult might need to be tweaked per texture pack.  
   The first two numbers determine how many samples are taken per fragment.  They should always be the equal to eachother.
   The third number divided by one of the first two numbers is inversely proportional to the range of the height-map. */
const vec3 intervalMult = vec3(1.0, 1.0, 1.0/POM_DEPTH)/POM_MAP_RES * 1.0; 



const int RGBA16 = 3;
const int RGB16 = 2;
const int RGB8 = 1;
const int gnormalFormat = RGB16;
const int compositeFormat = RGBA16;
const int gaux2Format = RGBA16;
const int gcolorFormat = RGB8;

const int GL_EXP = 2048;
const int GL_LINEAR = 9729;

const float bump_distance = 64.0;			//bump render distance: tiny = 32, short = 64, normal = 128, far = 256
const float pom_distance = 32.0;			//POM render distance: tiny = 32, short = 64, normal = 128, far = 256
const float fademult = 0.1;

	
varying vec2 lmcoord;
varying vec4 color;
varying float translucent;
varying vec4 vtexcoordam; // .st for add, .pq for mul
varying vec4 vtexcoord;
varying float dist;

varying vec3 tangent;
varying vec3 normal;
varying vec3 binormal;
varying vec3 viewVector;

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int fogMode;
uniform int worldTime;
uniform float wetness;
uniform float rainStrength;

float totalspec = 0.0;
float wetx = clamp(wetness, 0.0f, 1.0)/1.0;

const float mincoord = 1.0/4096.0;
const float maxcoord = 1.0-mincoord;

vec2 dcdx = dFdx(vtexcoord.st*vtexcoordam.pq);
vec2 dcdy = dFdy(vtexcoord.st*vtexcoordam.pq);

vec4 readTexture(in vec2 coord){
	return texture2DGradARB(texture,fract(coord)*vtexcoordam.pq+vtexcoordam.st,dcdx,dcdy);
}

vec4 readNormal(in vec2 coord){
	return texture2DGradARB(normals,fract(coord)*vtexcoordam.pq+vtexcoordam.st,dcdx,dcdy);
}

float normalmap_intensity	= NORMAL_MAP_MAX_ANGLE-((NORMAL_MAP_MAX_ANGLE*rainStrength)*0.95);

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	
vec2 adjustedTexCoord = vtexcoord.st*vtexcoordam.pq+vtexcoordam.st;		

#ifdef POM
	if (dist < MAX_OCCLUSION_DISTANCE) {
	if ( viewVector.z < 0.0 && readNormal(vtexcoord.st).a < 0.99 && readNormal(vtexcoord.st).a > 0.01) 
	{
		vec3 interval = viewVector.xyz * intervalMult;
		vec3 coord = vec3(vtexcoord.st, 1.0);
		for (int loopCount = 0; 
				(loopCount < MAX_OCCLUSION_POINTS) && (readNormal(coord.st).a < coord.p);
				++loopCount) {
			coord = coord+interval;
		}
		
		
		
		// Don't wrap around top of tall grass/flower
		if (coord.t < mincoord) {
			if (readTexture(vec2(coord.s,mincoord)).a == 0.0) {
				coord.t = mincoord;
				discard;
			}
		}
		
		adjustedTexCoord = mix(fract(coord.st)*vtexcoordam.pq+vtexcoordam.st , adjustedTexCoord , max(dist-MIX_OCCLUSION_DISTANCE,0.0)/(MAX_OCCLUSION_DISTANCE-MIX_OCCLUSION_DISTANCE));
	}
}
#endif

	vec3 lightVector;	
	
	vec3 specularity = texture2DGradARB(specular, adjustedTexCoord.st, dcdx, dcdy).rgb;
	float atten = 1.0-(specularity.b)*0.86;

	vec4 frag2 = vec4(normal, 1.0f);
	
		vec3 bump = texture2DGradARB(normals, adjustedTexCoord.st, dcdx, dcdy).rgb*2.0-1.0;
				
		float bumpmult = normalmap_intensity*(1.0-wetness*lmcoord.t*0.65)*atten;
	
		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								  tangent.y, binormal.y, normal.y,
						     	  tangent.z, binormal.z, normal.z);
			
			frag2 = vec4(normalize(bump * tbnMatrix) * 0.5 + 0.5, 1.0);
			
	float dirtest = 0.4;
	
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	} 
	
	else {
		lightVector = normalize(moonPosition);
	}
	
	dirtest = mix(1.0-0.8*step(dot(frag2.xyz*2.0-1.0,lightVector),-0.02),0.4,float(translucent > 0.01));

	
/* DRAWBUFFERS:0246 */

	gl_FragData[0] = texture2DGradARB(texture, adjustedTexCoord.st, dcdx, dcdy) * color;
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4(lmcoord.t, dirtest, lmcoord.s, 1.0);
	gl_FragData[3] = texture2DGradARB(specular, adjustedTexCoord.st, dcdx, dcdy);
}