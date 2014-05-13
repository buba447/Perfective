varying lowp vec4 textureVarying;
varying lowp vec4 textureVarying_b;

uniform sampler2D texture;
uniform lowp float circleRadius;
uniform int hasTexture;
uniform lowp vec4 diffuseColor;

const highp vec2 center = vec2(0.5, 0.5);
void main()
{
  lowp vec2 alteredTexture = textureVarying_b.xy;
  alteredTexture.x = alteredTexture.x - 0.5;
  alteredTexture.y = alteredTexture.y - 0.5;
  highp float magDistance = distance(vec2(0.0, 0.0), alteredTexture.xy);
  magDistance = (magDistance * 2.0);
  magDistance = (magDistance * magDistance * magDistance * magDistance) * 0.05;
  lowp vec2 offsetDistance = magDistance * alteredTexture.xy;
  
  highp float distanceFromCenter = distance(center, textureVarying_b.xy);
  lowp float checkForPresenceWithinCircle = step(distanceFromCenter, circleRadius);
  lowp float checkForPresenceWithinOuterCircle = step(distanceFromCenter, 0.5);
  lowp float xValid = step(textureVarying.x, 1.0);
  lowp float yValid = step(textureVarying.y, 1.0);
  lowp vec4 black = vec4(0.0, 0.0, 0.0, checkForPresenceWithinOuterCircle) * float(hasTexture);
  gl_FragColor = black + (texture2D(texture, (textureVarying.xy + offsetDistance)) * checkForPresenceWithinOuterCircle * xValid * yValid * float(hasTexture)) + (diffuseColor * checkForPresenceWithinCircle);
}
