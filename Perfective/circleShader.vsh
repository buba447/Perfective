attribute vec4 position;
attribute vec4 texture;
attribute vec4 texture_b;

varying lowp vec4 textureVarying;
varying lowp vec4 textureVarying_b;

uniform mat4 projection;
uniform mat4 transform;

void main()
{
  textureVarying = texture;
  textureVarying_b = texture_b;
  gl_Position = projection * transform * position;
}