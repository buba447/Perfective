//
//  BWShaderObject.h
//  TestGame
//
//  Created by Brandon Withrow on 6/12/13.
//  Copyright (c) 2013 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef enum {
  BWUniformTypeFloat,
  BWUniformTypeFloatVec2,
  BWUniformTypeFloatVec3,
  BWUniformTypeFloatVec4,
  BWUniformTypeInt,
  BWUniformTypeIntVec2,
  BWUniformTypeIntVec3,
  BWUniformTypeIntVec4,
  BWUniformTypeBool,
  BWUniformTypeBoolVec2,
  BWUniformTypeBoolVec3,
  BWUniformTypeBoolVec4,
  BWUniformTypeFloatMatrix2,
  BWUniformTypeFloatMatrix3,
  BWUniformTypeFloatMatrix4,
  BWUniformTypeSampler2D,
  BWUniformTypeSamplerCube
} BWUniformType;

@interface BWShaderUniform : NSObject
@property (nonatomic, assign) GLuint location;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BWUniformType type;
@property (nonatomic, strong) NSValue *value;
@end

@interface BWShader : NSObject

@property (nonatomic, readonly) NSString *shaderName;
- (id)initWithShaderNamed:(NSString *)shaderName;
- (void)use;
- (void)loadUniforms:(NSMutableDictionary *)uniforms;
- (void)loadUniform:(BWShaderUniform *)uniform;
- (void)setUniformValue:(NSValue *)value forUniformNamed:(NSString *)uniform;
- (NSDictionary *)generateUniforms;
@end
