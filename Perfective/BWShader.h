//
//  BWShaderObject.h
//  TestGame
//
//  Created by Brandon Withrow on 6/12/13.
//  Copyright (c) 2013 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface BWShader : NSObject

@property (nonatomic, readonly) NSString *shaderName;
@property (nonatomic, readonly) NSArray *uniformNames;

- (id)initWithShaderNamed:(NSString *)shaderName;
- (void)use;

- (void)setUniform:(NSString *)uniform withVector2f:(GLKVector2)vector;
- (void)setUniform:(NSString *)uniform withVector3f:(GLKVector3)vector;
- (void)setUniform:(NSString *)uniform withVector4f:(GLKVector4)vector;

- (void)setUniform:(NSString *)uniform withVector2i:(GLKVector2)vector;
- (void)setUniform:(NSString *)uniform withVector3i:(GLKVector3)vector;
- (void)setUniform:(NSString *)uniform withVector4i:(GLKVector4)vector;

- (void)setUniform:(NSString *)uniform withMatrix2:(GLKMatrix2)matrix;
- (void)setUniform:(NSString *)uniform withMatrix3:(GLKMatrix3)matrix;
- (void)setUniform:(NSString *)uniform withMatrix4:(GLKMatrix4)matrix;

- (void)setUniform:(NSString *)uniform withFloat:(GLfloat)floatValue;
- (void)setUniform:(NSString *)uniform withInt:(GLint)intValue;
- (void)setUniform:(NSString *)uniform withBool:(BOOL)boolValue;

@end
