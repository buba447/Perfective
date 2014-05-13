//
//  BWImage.h
//  Perfective
//
//  Created by Brandon Withrow on 5/11/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BWImage : NSObject

@property (nonatomic, readonly) GLuint imageLocation;
@property (nonatomic, readonly) UIImage *originalImage;
@property (nonatomic, readonly) BOOL imageLoaded;

- (id)initWithImage:(UIImage *)image;
- (void)use;
- (void)loadTexture;
- (void)unloadTexture;
@end
