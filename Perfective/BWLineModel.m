//
//  BWLineModel.m
//  Perfective
//
//  Created by Brandon Withrow on 5/13/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "BWLineModel.h"
#import "BWImage.h"
#import "BWShader.h"
#import "BWMesh.h"

@implementation BWLineModel

- (id)init {
  self = [super init];
  if (self) {
    _lineColor = GLKVector4Make(1.f, 1.f, 1.f, 1.f);
    _lineWidth = 2.f;
    _lineMode = BWLineModeLoop;
  }
  return self;
}

- (void)setUniforms {
  [super setUniforms];
  [self.shader setUniform:@"diffuseColor" withValue:&_lineColor];
}

- (void)draw {
  if (!self.shader || !self.mesh) {
    return;
  }
  if (self.imageTexture) {
    [self.imageTexture use];
  }
  [self setUniforms];
  glLineWidth(_lineWidth);
  if (self.lineMode == BWLineModeLoop) {
    glDrawArrays(GL_LINE_LOOP, 0, self.mesh.vertexCount);
  } else if (self.lineMode == BWLineModeOpen) {
    glDrawArrays(GL_LINE_STRIP, 0, self.mesh.vertexCount);
  }
  glUseProgram(0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArrayOES(0);
  glBindTexture(GL_TEXTURE_2D, 0);
}

@end
