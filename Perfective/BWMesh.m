//
//  BWMesh.m
//  TestGame
//
//  Created by Brandon Withrow on 6/16/13.
//  Copyright (c) 2013 Brandon Withrow. All rights reserved.
//

#import "BWMesh.h"

@implementation BWMesh {
  GLfloat *data_;
  size_t dataSize_;
}

- (void)logBuffer {
  NSMutableArray *values = [NSMutableArray array];
  for (int i = 0; i < _vertexCount * 9; i ++) {
    [values addObject:@(data_[i])];
  }
  NSLog(@"\rMesh [ %@ ]", [values componentsJoinedByString:@", "]);
}


- (id)initWithNumberOfVertices:(GLint)vertexCount {
  self = [super init];
  if (self) {
    _vertexCount = vertexCount;
    [self initBufferOfSize:vertexCount];
    _needsUpdate = NO;
  }
  return self;
}

- (GLKVector3)vertexAtIndex:(GLint)index {
  NSAssert(index < _vertexCount, @"Vertex Index Out Of Bounds");
  int i = index * 9;
  GLKVector3 v = GLKVector3Make(data_[i], data_[i+1], data_[i+2]);
  return v;
}

- (GLKVector3)texCoor0AtIndex:(GLint)index {
  NSAssert(index < _vertexCount, @"Vertex Index Out Of Bounds");
  int i = (index * 9) + 3;
  GLKVector3 v = GLKVector3Make(data_[i], data_[i+1], data_[i+2]);
  return v;
}

- (GLKVector3)texCoor1AtIndex:(GLint)index {
  NSAssert(index < _vertexCount, @"Vertex Index Out Of Bounds");
  int i = (index * 9) + 6;
  GLKVector3 v = GLKVector3Make(data_[i], data_[i+1], data_[i+2]);
  return v;
}

- (void)setVertexData:(GLKMatrix3)vertexData atIndex:(GLint)index {
  NSAssert(index < _vertexCount, @"Vertex Index Out Of Bounds");
  int i = index * 9;
  for (int d = 0; d < 9; d++) {
    data_[i] = vertexData.m[d];
    i++;
  }
  _needsUpdate = YES;
}

- (void)setVertex:(GLKVector3)vertex atIndex:(GLint)index {
  NSAssert(index < _vertexCount, @"Vertex Index Out Of Bounds");
  int i = index * 9;
  data_[i] = vertex.x;
  data_[i+1] = vertex.y;
  data_[i+2] = vertex.z;
  _needsUpdate = YES;
}

- (void)setTexCoor0:(GLKVector3)textCoor atIndex:(GLint)index {
  NSAssert(index < _vertexCount, @"Vertex Index Out Of Bounds");
  int i = (index * 9) + 3;
  data_[i] = textCoor.x;
  data_[i+1] = textCoor.y;
  data_[i+2] = textCoor.z;
  _needsUpdate = YES;
}

- (void)setTexCoor1:(GLKVector3)textCoor atIndex:(GLint)index {
  NSAssert(index < _vertexCount, @"Vertex Index Out Of Bounds");
  int i = (index * 9) + 6;
  data_[i] = textCoor.x;
  data_[i+1] = textCoor.y;
  data_[i+2] = textCoor.z;
  _needsUpdate = YES;
}

- (void)updateBuffer {
  glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
  glBufferSubData(GL_ARRAY_BUFFER, 0, dataSize_, data_);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  _needsUpdate = NO;
}

- (void)use {
  glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
  glBindVertexArrayOES(_vertexArray);
}

- (void)initBufferOfSize:(GLint)vertexCount {
  GLint strideCount = 9;
  GLint strideByteSize = strideCount * sizeof(GLfloat);
  dataSize_ = strideByteSize * vertexCount;
  data_ = calloc(strideCount * vertexCount, sizeof(GLfloat));
  
  GLuint newVertexArray;
  glGenVertexArraysOES(1, &newVertexArray);
  glBindVertexArrayOES(newVertexArray);
  
  GLuint newVertexBuffer;
  glGenBuffers(1, &newVertexBuffer);
  glBindBuffer(GL_ARRAY_BUFFER, newVertexBuffer);
  glBufferData(GL_ARRAY_BUFFER, dataSize_, data_, GL_DYNAMIC_DRAW);

  GLuint offset = 0;
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, strideByteSize, (const void*)offset);
  
  offset += 3 * sizeof(GLfloat);
  
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  glVertexAttribPointer(GLKVertexAttribTexCoord0, 3, GL_FLOAT, GL_FALSE, strideByteSize, (const void*)offset);
  
  offset += 3 * sizeof(GLfloat);
  glEnableVertexAttribArray(GLKVertexAttribTexCoord1);
  glVertexAttribPointer(GLKVertexAttribTexCoord1, 3, GL_FLOAT, GL_FALSE, strideByteSize, (const void*)offset);

  _vertexArray = newVertexArray;
  _vertexBuffer = newVertexBuffer;

  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArrayOES(0);
}

- (void)dealloc {
  glBindVertexArrayOES(0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glDeleteBuffers(1, &(_vertexBuffer));
  glDeleteVertexArraysOES(1, &(_vertexArray));
  free(data_);
}
@end
