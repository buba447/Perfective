//
//  BWAssetPickerSheet.m
//  Perfective
//
//  Created by Brandon Withrow on 9/27/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "BWAssetPickerSheet.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "BWRecentPhotoCell.h"

@interface BWAssetPickerSheet () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@end

@implementation BWAssetPickerSheet {
  ALAssetsLibrary *userLibrary_;
  NSMutableArray *recentPhotos_;
  UICollectionView *collectionView_;
  UICollectionViewFlowLayout *flowLayout_;
  UIButton *libraryButton_;
  UIButton *cameraButton_;
  UIButton *cancelButton_;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor whiteColor];
    flowLayout_ = [[UICollectionViewFlowLayout alloc] init];
    flowLayout_.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout_.sectionInset = UIEdgeInsetsMake(0, 6, 0, 6);
    collectionView_ = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 6, frame.size.width, 120.f) collectionViewLayout:flowLayout_];
    collectionView_.backgroundColor = self.backgroundColor;
    collectionView_.showsHorizontalScrollIndicator = NO;
    [collectionView_ registerClass:[BWRecentPhotoCell class] forCellWithReuseIdentifier:@"photo"];
    collectionView_.delegate = self;
    collectionView_.dataSource = self;
    collectionView_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:collectionView_];
    
    CGSize dividerSize = CGSizeMake(frame.size.width - 12, 1);
    
    UIView *dividerView;
    
    dividerView = [[UIView alloc] init];
    dividerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    dividerView.frame = CGRectAttachedBottomToRect(collectionView_.frame, dividerSize, 3, YES);
    dividerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:dividerView];
    
    libraryButton_ = [UIButton buttonWithType:UIButtonTypeSystem];
    [libraryButton_ setTitle:@"Photo Library" forState:UIControlStateNormal];
    libraryButton_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [libraryButton_ addTarget:self action:@selector(chooseLibraryPressed) forControlEvents:UIControlEventTouchUpInside];
    libraryButton_.frame = CGRectAttachedBottomToRect(collectionView_.frame, CGSizeMake(frame.size.width, 44), 7, YES);
    [self addSubview:libraryButton_];
    
    dividerView = [[UIView alloc] init];
    dividerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    dividerView.frame = CGRectAttachedBottomToRect(libraryButton_.frame, dividerSize, 1, YES);
    dividerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:dividerView];
    CGRect prevRect = dividerView.frame;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
      cameraButton_ = [UIButton buttonWithType:UIButtonTypeSystem];
      [cameraButton_ setTitle:@"Take Photo" forState:UIControlStateNormal];
      cameraButton_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      [cameraButton_ addTarget:self action:@selector(chooseCameraPressed) forControlEvents:UIControlEventTouchUpInside];
      cameraButton_.frame = CGRectAttachedBottomToRect(libraryButton_.frame, CGSizeMake(frame.size.width, 44), 3, YES);
      [self addSubview:cameraButton_];
      prevRect = cameraButton_.frame;
      
      dividerView = [[UIView alloc] init];
      dividerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
      dividerView.frame = CGRectAttachedBottomToRect(prevRect, dividerSize, 1, YES);
      dividerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      [self addSubview:dividerView];
    }
    
    cancelButton_ = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton_ setTitle:@"Cancel" forState:UIControlStateNormal];
    cancelButton_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [cancelButton_ addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    cancelButton_.frame = CGRectAttachedBottomToRect(prevRect, CGSizeMake(frame.size.width, 44), 3, YES);
    [self addSubview:cancelButton_];
    
    [self loadRecentPhotos];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
}

#pragma mark - Load Photos

- (void)loadRecentPhotos {
  userLibrary_ = [[ALAssetsLibrary alloc] init];
  recentPhotos_ = [NSMutableArray array];
  ALAssetsLibraryGroupsEnumerationResultsBlock assetGroupEnumerator =
  ^(ALAssetsGroup *assetGroup, BOOL *stop) {
    if (assetGroup != nil && assetGroup.numberOfAssets > 0) {
      [self enumerateAndPrunAssetGroup:assetGroup];
    }
  };
  
  ALAssetsLibraryAccessFailureBlock assetFailureBlock = ^(NSError *error) {
    
  };
  NSUInteger groupTypes = ALAssetsGroupSavedPhotos;
  [userLibrary_ enumerateGroupsWithTypes:groupTypes usingBlock:assetGroupEnumerator failureBlock:assetFailureBlock];
}

- (void)enumerateAndPrunAssetGroup:(ALAssetsGroup *)group {
  NSInteger len = group.numberOfAssets > 10 ? 10 : group.numberOfAssets;
  NSInteger loc = group.numberOfAssets - len;
  [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(loc, len)]
                          options:NSEnumerationReverse
                       usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                         if ([result valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto && recentPhotos_.count < 10) {
                           [recentPhotos_ addObject:result];
                         }
                       }];
  
  if (recentPhotos_.count && self.delegate && [self.delegate respondsToSelector:@selector(assetPickerSheetDidLoadMostRecentPhoto:)]) {
    ALAsset *asset = recentPhotos_.firstObject;
    [self.delegate assetPickerSheetDidLoadMostRecentPhoto:[self imageFromAsset:asset]];
  }
  [collectionView_ reloadData];
}

- (UIImage *)imageFromAsset:(ALAsset *)asset {
  UIImageOrientation orientation = UIImageOrientationUp;
  NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
  if (orientationValue != nil) {
    orientation = [orientationValue intValue];
  }
  UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage scale:1 orientation:orientation];
  return image;
}

#pragma mark - External Methods

- (void)resetState {
  [collectionView_ scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
}

- (CGFloat)idealHeight {
  return CGRectGetMaxY(cancelButton_.frame) + 2;
}

#pragma mark - UICollectionView Delegate and DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return recentPhotos_.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  BWRecentPhotoCell *cell = (BWRecentPhotoCell *)[collectionView_ dequeueReusableCellWithReuseIdentifier:@"photo" forIndexPath:indexPath];
  ALAsset *asset = [recentPhotos_ objectAtIndex:indexPath.row];
  cell.imageView.image = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
  return cell;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
  return 6;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  ALAsset *asset = [recentPhotos_ objectAtIndex:indexPath.row];
  UIImage *image = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
  CGFloat ratio = image.size.width / image.size.height;
  CGSize size = CGSizeMake(collectionView.bounds.size.height * ratio, collectionView.bounds.size.height);
  return size;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (self.delegate) {
    ALAsset *asset = [recentPhotos_ objectAtIndex:indexPath.row];
    [self.delegate assetPickerSheet:self didSelectImage:[self imageFromAsset:asset]];
  }
}

#pragma mark - Action responders

- (void)chooseLibraryPressed {
  if (self.delegate) {
    [self.delegate assetPickerSheetDidChooseLibrary:self];
  }
}

- (void)chooseCameraPressed {
  if (self.delegate) {
    [self.delegate assetPickerSheetDidChooseCamera:self];
  }
}

- (void)cancelPressed {
  if (self.delegate) {
    [self.delegate assetPickerSheetDidCancel:self];
  }
}

@end
