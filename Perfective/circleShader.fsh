varying lowp vec4 textureVarying;
varying lowp vec4 textureVarying_b;
uniform sampler2D texture;
uniform lowp float circleRadius;
const highp vec2 center = vec2(0.5, 0.5);
uniform int hasTexture;
uniform lowp vec4 diffuseColor;
void main()
{
  highp float distanceFromCenter = distance(center, textureVarying_b.xy);
  lowp float checkForPresenceWithinCircle = step(distanceFromCenter, circleRadius);
  lowp float checkForPresenceWithinOuterCircle = step(distanceFromCenter, 0.5);
  lowp float xValid = step(textureVarying.x, 1.0);
  lowp float yValid = step(textureVarying.y, 1.0);
  lowp vec4 black = vec4(0.0, 0.0, 0.0, checkForPresenceWithinOuterCircle) * float(hasTexture);
  gl_FragColor = black + (texture2D(texture, textureVarying.xy) * checkForPresenceWithinOuterCircle * xValid * yValid * float(hasTexture)) + (diffuseColor * checkForPresenceWithinCircle);
}
