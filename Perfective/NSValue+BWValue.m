//
//  NSValue+BWValue.m
//  Perfective
//
//  Created by Brandon Withrow on 5/10/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "NSValue+BWValue.h"

@implementation NSValue (BWValue)

+ (NSValue *)valueWithGLKVector2:(GLKVector2)vector {
  return [NSValue valueWithBytes:&vector objCType:@encode(GLKVector2)];
}

+ (NSValue *)valueWithGLKVector3:(GLKVector3)vector {
  return [NSValue valueWithBytes:&vector objCType:@encode(GLKVector3)];
}

+ (NSValue *)valueWithGLKVector4:(GLKVector4)vector {
  return [NSValue valueWithBytes:&vector objCType:@encode(GLKVector4)];
}

+ (NSValue *)valueWithGLKMatrix2:(GLKMatrix2)matrix {
  return [NSValue valueWithBytes:&matrix objCType:@encode(GLKMatrix2)];
}

+ (NSValue *)valueWithGLKMatrix3:(GLKMatrix3)matrix {
  return [NSValue valueWithBytes:&matrix objCType:@encode(GLKMatrix3)];
}

+ (NSValue *)valueWithGLKMatrix4:(GLKMatrix4)matrix {
  return [NSValue valueWithBytes:&matrix objCType:@encode(GLKMatrix4)];
}

- (GLKVector2)vector2Value {
  GLKVector2 value;
  [self getValue:&value];
  return value;
}

- (GLKVector3)vector3Value {
  GLKVector3 value;
  [self getValue:&value];
  return value;
}

- (GLKVector4)vector4Value {
  GLKVector4 value;
  [self getValue:&value];
  return value;
}

- (GLKMatrix2)matrix2Value {
  GLKMatrix2 value;
  [self getValue:&value];
  return value;
}

- (GLKMatrix3)matrix3Value {
  GLKMatrix3 value;
  [self getValue:&value];
  return value;
}

- (GLKMatrix4)matrix4Value {
  GLKMatrix4 value;
  [self getValue:&value];
  return value;
}

@end
