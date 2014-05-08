//
//  Shader.fsh
//  Perfective
//
//  Created by Brandon Withrow on 4/25/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

varying lowp vec4 colorVarying;
varying lowp vec4 textureVarying;
uniform int hasTexture;
uniform sampler2D texture;

void main()
{
  gl_FragColor = (colorVarying * (1.0 - float(hasTexture))) + (texture2D(texture, vec2(textureVarying.x / textureVarying.z, textureVarying.y / textureVarying.z)) * float(hasTexture));
}
