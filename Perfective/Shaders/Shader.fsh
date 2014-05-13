//
//  Shader.fsh
//  Perfective
//
//  Created by Brandon Withrow on 4/25/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

uniform int hasTexture;
uniform sampler2D texture;

varying highp vec4 textureVarying;
uniform lowp vec4 diffuseColor;
void main()
{
  gl_FragColor = (diffuseColor * (1.0 - float(hasTexture))) + (texture2D(texture, vec2(textureVarying.x * textureVarying.z, textureVarying.y * textureVarying.z)) * float(hasTexture));
}
