attribute vec4 position;
attribute highp vec4 texture;

varying highp vec4 textureVarying;

uniform mat4 projection;
uniform mat4 projectionTransform;
uniform mat4 transform;

void main() {
  textureVarying = texture;
  gl_Position = projection * projectionTransform * transform * position;
}