attribute vec4 position;
attribute vec4 texture;

varying lowp vec4 colorVarying;
varying lowp vec4 textureVarying;
uniform mat4 modelViewProjectionMatrix;

void main()
{
  vec4 diffuseColor = vec4(0.4, 0.4, 1.0, 0.5);
  colorVarying = diffuseColor;
  textureVarying = texture;
  gl_Position = modelViewProjectionMatrix * position;
}