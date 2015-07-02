//
//  ViewController.h
//  Perfective
//
//  Created by Brandon Withrow on 4/25/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum {
  BWPhotoStateNone,
  BWPhotoStateSquare,
  BWPhotoStateLines
} BWPhotoState;

static NSString * const BWTransformValidityChanged = @"BWTransformValidityChanged";

@interface BWGLPhotViewController : GLKViewController

@property (nonatomic, assign) BWPhotoState currentState;
@property (nonatomic, readonly) BOOL transformValid;
@property (nonatomic, assign) UIEdgeInsets contentEdgeInsets;

@property (nonatomic, assign) BOOL transformApplied;
- (void)setTransformApplied:(BOOL)transformApplied animate:(BOOL)animated;

- (void)loadImage:(UIImage *)image;
- (void)pause;
- (void)start;
- (void)saveImage;
@end
