//
//  BWMesh.h
//  TestGame
//
//  Created by Brandon Withrow on 6/16/13.
//  Copyright (c) 2013 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BWMesh : NSObject
@property (nonatomic, assign) GLuint vertexArray;
@property (nonatomic, assign) GLuint vertexBuffer;
@property (nonatomic, assign) int vertexCount;
@property (nonatomic, retain) NSString *name;
@end
