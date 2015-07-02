//
//  BWAssetPickerSheet.h
//  Perfective
//
//  Created by Brandon Withrow on 9/27/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BWAssetPickerSheet;
@protocol BWAssetPickerSheetDelegate <NSObject>

- (void)assetPickerSheet:(BWAssetPickerSheet *)picker didSelectImage:(UIImage *)image;
- (void)assetPickerSheetDidCancel:(BWAssetPickerSheet *)picker;
- (void)assetPickerSheetDidChooseCamera:(BWAssetPickerSheet *)picker;
- (void)assetPickerSheetDidChooseLibrary:(BWAssetPickerSheet *)picker;
@optional
- (void)assetPickerSheetDidLoadMostRecentPhoto:(UIImage *)mostRecent;
@end

@interface BWAssetPickerSheet : UIView
@property (nonatomic, weak) id <BWAssetPickerSheetDelegate>delegate;

- (void)resetState;
- (CGFloat)idealHeight;

@end
