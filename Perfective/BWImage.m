//
//  BWImage.m
//  Perfective
//
//  Created by Brandon Withrow on 5/11/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "BWImage.h"

@implementation BWImage

- (id)initWithImage:(UIImage *)image {
  self = [super init];
  if (self) {
    _originalImage = image;
    [self loadTexture];
  }
  return self;
}

- (void)use {
  glBindTexture(GL_TEXTURE_2D, _imageLocation);
}

- (void)loadTexture {
  if (self.imageLoaded) {
    return;
  }
  
  GLuint returnTexture;
  
  GLuint width = _originalImage.size.width;
  GLuint height = _originalImage.size.height;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  void *imageData = malloc( height * width * 4 );
  CGContextRef imgcontext = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
  UIGraphicsPushContext(imgcontext);
  CGColorSpaceRelease( colorSpace );
  CGContextClearRect( imgcontext, CGRectMake( 0, 0, width, height ) );
  CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, height);
  CGContextConcatCTM(imgcontext, flipVertical);
  CGRect imageDrawRect = CGRectZero;
  imageDrawRect.size = CGSizeMake(width, height);
  [_originalImage drawInRect:imageDrawRect];

  glGenTextures(1, &returnTexture);
  glBindTexture(GL_TEXTURE_2D, returnTexture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
// DELETE ME
//  glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height,
               0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	glBindTexture(GL_TEXTURE_2D, 0);
  free(imageData);
  CGContextRelease(imgcontext);
  
  _imageLocation = returnTexture;
  _imageLoaded = YES;
}

- (void)unloadTexture {
  glBindTexture(GL_TEXTURE_2D, 0);
  glDeleteTextures(1, &_imageLocation);
  _imageLoaded = NO;
}
- (void)dealloc {
  [self unloadTexture];
}
@end
