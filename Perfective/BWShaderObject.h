//
//  BWShaderObject.h
//  TestGame
//
//  Created by Brandon Withrow on 6/12/13.
//  Copyright (c) 2013 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface BWShaderObject : NSObject
@property (nonatomic, assign) GLuint shaderProgram;
@property (nonatomic, assign) GLint uniformModelMatrix;
@property (nonatomic, assign) GLint uniformNormalMatrix;
@property (nonatomic, assign) GLint uniformCameraLocationMatrix;
@property (nonatomic, assign) GLint uniformCameraProjectionMatrix;
@property (nonatomic, assign) GLint uniformTextureUV;
@property (nonatomic, assign) GLint uniformDiffuse;
@property (nonatomic, assign) GLint uniformLight1;
@property (nonatomic, assign) GLint uniformLight2;
@property (nonatomic, assign) GLint uniformLight3;
@property (nonatomic, assign) GLint uniformLight4;
@property (nonatomic, assign) GLint uniformLight1On;
@property (nonatomic, assign) GLint uniformLight2On;
@property (nonatomic, assign) GLint uniformLight3On;
@property (nonatomic, assign) GLint uniformLight4On;
@property (nonatomic, assign) GLint uniformHasTexture;
@end
