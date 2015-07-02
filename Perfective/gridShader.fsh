uniform sampler2D texture;

varying highp vec4 textureVarying;
uniform lowp vec4 diffuseColor;
uniform int drawY;
uniform int drawX;
void main() {
  lowp float xMod = textureVarying.x * textureVarying.z * 3.0;
  lowp float yMod = textureVarying.y * textureVarying.z * 3.0;
  
  lowp float xStepHigh = step(0.97, fract(xMod)) * float(drawY);
  lowp float xStepLow = step(fract(xMod), 0.03) * float(drawY);
  lowp float yStepHigh = step(0.97, fract(yMod)) * float(drawX);
  lowp float yStepLow = step(fract(yMod), 0.03) * float(drawX);
  
  lowp float mixStep = min((xStepHigh + xStepLow + yStepHigh + yStepLow), 1.0);
  
  gl_FragColor = mix(vec4(0.0, 0.0, 0.0, 0.0), diffuseColor, mixStep);
}