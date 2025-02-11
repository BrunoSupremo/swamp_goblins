[[FX]]

float4 alpha = { 0, 0, 0, 0.5 };

[[VS]]
#include "shaders/utilityLib/vertCommon.glsl"

uniform mat4 viewProjMat;
uniform vec4 alpha;

attribute vec3 vertPos;
attribute vec4 color;
attribute vec3 normal;

varying vec4 outColor;
varying vec3 tsbNormal;

void main() {
   outColor = vec4(color.rgb + vec3(0.5), alpha.a);
   tsbNormal = calcWorldVec(normal);
   gl_Position = viewProjMat * calcWorldPos(vec4(vertPos, 1.0));
}

[[FS]]
#include "shaders/utilityLib/desaturate.glsl"

varying vec4 outColor;

varying vec3 tsbNormal;

const vec3 lightDir = vec3(-0.3, -0.5, 0.8);

void main() {
   float atten = min(abs(dot(tsbNormal, lightDir)) + 0.3, 1.0);
   vec4 theColor = vec4(outColor.rgb * atten, outColor.a);
   gl_FragColor = globalDesaturateRGBA(theColor);
}