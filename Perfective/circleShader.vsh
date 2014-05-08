attribute vec4 position;
attribute vec4 texture;
attribute vec4 texture_b;

varying lowp vec4 colorVarying;
varying lowp vec4 textureVarying;
varying lowp vec4 textureVarying_b;
uniform mat4 modelViewProjectionMatrix;

void main()
{
  vec4 diffuseColor = vec4(0.7, 0.4, 0.0, 0.5);
  colorVarying = diffuseColor;
  textureVarying = texture;
  textureVarying_b = texture_b;
  gl_Position = modelViewProjectionMatrix * position;
}