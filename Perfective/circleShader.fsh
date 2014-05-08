varying lowp vec4 colorVarying;
varying lowp vec4 textureVarying;
varying lowp vec4 textureVarying_b;
uniform sampler2D texture;

const highp vec2 center = vec2(0.5, 0.5);
const highp float radius = 0.05;

void main()
{
  highp float distanceFromCenter = distance(center, textureVarying_b.xy);
  lowp float checkForPresenceWithinCircle = step(distanceFromCenter, radius);
  lowp float checkForPresenceWithinOuterCircle = step(distanceFromCenter, 0.5);
//  lowp float checkForPresenceWithinCircle = 0.0;
  lowp float xValid = step(textureVarying.x, 1.0);
  lowp float yValid = step(textureVarying.y, 1.0);
  lowp vec4 black = vec4(0.0, 0.0, 0.0, checkForPresenceWithinOuterCircle);
  gl_FragColor = black + (texture2D(texture, textureVarying.xy) * checkForPresenceWithinOuterCircle * xValid * yValid) + (colorVarying * checkForPresenceWithinCircle);
//  fragColor.z = 1.0;
//   = fragColor;
}
