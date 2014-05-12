//
//  BWModel.m
//  Perfective
//
//  Created by Brandon Withrow on 5/11/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "BWModel.h"
#import "BWShader.h"
#import "BWMesh.h"

@implementation BWModel

- (id)init {
  self = [super init];
  if (self) {
    _projection = GLKMatrix4Identity;
    _transform = GLKMatrix4Identity;
  }
  return self;
}

- (void)use {
  if (!self.shader || !self.mesh) {
    return;
  }
  if (self.mesh.needsUpdate) {
    [self.mesh updateBuffer];
  }
  [self.shader use];
  [self.mesh use];
}

- (void)draw {
  if (!self.shader || !self.mesh) {
    return;
  }
  [self.shader setUniform:@"projection" withMatrix4:_projection];
  [self.shader setUniform:@"transform" withMatrix4:_transform];
  glDrawArrays(GL_TRIANGLE_STRIP, 0, self.mesh.vertexCount);
  glUseProgram(0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArrayOES(0);
}

@end
