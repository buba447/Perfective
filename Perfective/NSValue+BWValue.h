//
//  NSValue+BWValue.h
//  Perfective
//
//  Created by Brandon Withrow on 5/10/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//
#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>

@interface NSValue (BWValue)
+ (NSValue *)valueWithGLKVector2:(GLKVector2)vector;
+ (NSValue *)valueWithGLKVector3:(GLKVector3)vector;
+ (NSValue *)valueWithGLKVector4:(GLKVector4)vector;
+ (NSValue *)valueWithGLKMatrix2:(GLKMatrix2)matrix;
+ (NSValue *)valueWithGLKMatrix3:(GLKMatrix3)matrix;
+ (NSValue *)valueWithGLKMatrix4:(GLKMatrix4)matrix;
- (GLKVector2)vector2Value;
- (GLKVector3)vector3Value;
- (GLKVector4)vector4Value;
- (GLKMatrix2)matrix2Value;
- (GLKMatrix3)matrix3Value;
- (GLKMatrix4)matrix4Value;
@end
