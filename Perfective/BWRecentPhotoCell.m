//
//  BWRecentPhotoCell.m
//  Perfective
//
//  Created by Brandon Withrow on 9/27/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "BWRecentPhotoCell.h"

@implementation BWRecentPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.imageView];
  }
  return self;
}

@end
