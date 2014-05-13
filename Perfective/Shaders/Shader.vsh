//
//  Shader.vsh
//  Perfective
//
//  Created by Brandon Withrow on 4/25/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

attribute vec4 position;
attribute vec4 texture;

varying vec4 textureVarying;

uniform mat4 projection;
uniform mat4 projectionTransform;
uniform mat4 transform;

void main() {
  textureVarying = texture;
  gl_Position = (projectionTransform * projection) * transform * position;
}
