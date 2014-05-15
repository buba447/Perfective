//
//  BWLineModel.h
//  Perfective
//
//  Created by Brandon Withrow on 5/13/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "BWModel.h"

typedef enum {
  BWLineModeLoop,
  BWLineModeOpen
}BWLineMode;

@interface BWLineModel : BWModel
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) GLKVector4 lineColor;
@property (nonatomic, assign) BWLineMode lineMode;
@end
