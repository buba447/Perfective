//
//  BWMesh.h
//  TestGame
//
//  Created by Brandon Withrow on 6/16/13.
//  Copyright (c) 2013 Brandon Withrow. All rights reserved.
//

//TODO Convert to GLELEMENTS and add facemaking methods.

#import <Foundation/Foundation.h>

@interface BWMesh : NSObject

@property (nonatomic, readonly) GLint vertexCount;
@property (nonatomic, readonly) GLuint vertexArray;
@property (nonatomic, readonly) GLuint vertexBuffer;
@property (nonatomic, readonly) BOOL needsUpdate;

- (id)initWithNumberOfVertices:(GLint)vertexCount;

- (void)updateBuffer;
- (void)use;

- (void)setVertex:(GLKVector3)vertex atIndex:(GLint)index;
- (void)setTexCoor0:(GLKVector3)textCoor atIndex:(GLint)index;
- (void)setTexCoor1:(GLKVector3)textCoor atIndex:(GLint)index;
- (void)setVertexData:(GLKMatrix3)vertexData atIndex:(GLint)index;

- (GLKVector3)vertexAtIndex:(GLint)index;
- (GLKVector3)texCoor0AtIndex:(GLint)index;
- (GLKVector3)texCoor1AtIndex:(GLint)index;

- (void)logBuffer;
@end
