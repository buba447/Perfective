varying lowp vec4 colorVarying;
varying lowp vec4 textureVarying;

uniform sampler2D texture;

const highp vec2 center = vec2(0.5, 0.5);
const highp float radius = 0.5;

void main()
{
  highp float distanceFromCenter = distance(center, textureVarying.xy);
//  lowp float checkForPresenceWithinCircle = step(distanceFromCenter, radius);
  lowp float checkForPresenceWithinCircle = 0.0;
  gl_FragColor = (texture2D(texture, textureVarying.xy) * (1.0 - checkForPresenceWithinCircle)) + (colorVarying * checkForPresenceWithinCircle);
}
