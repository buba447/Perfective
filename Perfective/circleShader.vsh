attribute vec4 position;
attribute vec4 texture;
attribute vec4 texture_b;

varying lowp vec4 textureVarying;
varying lowp vec4 textureVarying_b;
uniform lowp vec4 diffuseColor;
uniform mat4 modelViewProjectionMatrix;
uniform lowp float circleRadius;
uniform int hasTexture;
void main()
{
  textureVarying = texture;
  textureVarying_b = texture_b;
  gl_Position = modelViewProjectionMatrix * position;
}