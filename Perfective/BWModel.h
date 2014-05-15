//
//  BWModel.h
//  Perfective
//
//  Created by Brandon Withrow on 5/11/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BWShader;
@class BWMesh;
@class BWImage;

@interface BWModel : NSObject

@property (nonatomic, assign) GLKMatrix4 projection;
@property (nonatomic, assign) GLKMatrix4 projectionTransform;
@property (nonatomic, assign) GLKMatrix4 transform;

@property (nonatomic, strong) BWShader *shader;
@property (nonatomic, strong) BWMesh *mesh;
@property (nonatomic, strong) BWImage *imageTexture;
@property (nonatomic, assign) BOOL drawLines;

- (void)use;
- (void)draw;

- (void)setUniforms;
@end
