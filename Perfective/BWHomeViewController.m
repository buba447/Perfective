//
//  PFContainmentViewController.m
//  Perfective
//
//  Created by Brandon Withrow on 6/3/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "BWHomeViewController.h"
#import "BWGLPhotViewController.h"
#import "BWAssetPickerSheet.h"
#import <pop/POP.h>
@interface BWHomeViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, BWAssetPickerSheetDelegate> {
  UIToolbar *bottomBar_;
  UINavigationBar *navBar_;
  BWGLPhotViewController *photoViewController_;
  UIBarButtonItem *applyButton_;
  UIBarButtonItem *editButton_;
  UIBarButtonItem *saveButton_;
  UIBarButtonItem *squareButton_;
  UIBarButtonItem *linesButton_;
  UIBarButtonItem *choosePhoto_;
  UIBarButtonItem *flex1_;
  UIBarButtonItem *flex2_;
  UIBarButtonItem *flex3_;
  UILabel *descriptionLabel_;
  
  BWAssetPickerSheet *pickerSheet_;
  UIButton *dismissPickerButton_;
  UIView *dimView_;
}

@end

@implementation BWHomeViewController

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transformChanged) name:BWTransformValidityChanged object:nil];
  self.view.backgroundColor = [UIColor blackColor];
  
  photoViewController_ = [[BWGLPhotViewController alloc] init];
  [self addChildViewController:photoViewController_];
  [self.view addSubview:photoViewController_.view];
  photoViewController_.view.frame = self.view.bounds;
  photoViewController_.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  [photoViewController_ didMoveToParentViewController:self];
  
  bottomBar_ = [[UIToolbar alloc] initWithFrame:CGRectZero];
  
  saveButton_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(saveImage)];
  saveButton_.enabled = NO;
  
  squareButton_ = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"squareIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(declareSquare)];
  linesButton_ = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"parallelIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(declareLines)];
  choosePhoto_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(pickImage)];
  applyButton_ = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStylePlain target:self action:@selector(applyCurrentTransform)];
  applyButton_.enabled = NO;
  editButton_ = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editCurrentTransform)];

  flex1_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  flex2_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  flex3_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  
  [bottomBar_ setItems:@[saveButton_, flex1_, squareButton_, flex2_, linesButton_, flex3_, choosePhoto_]];
  bottomBar_.barStyle = UIBarStyleBlack;
  bottomBar_.tintColor = [UIColor whiteColor];
  [self.view addSubview:bottomBar_];
  
  navBar_ = [[UINavigationBar alloc] initWithFrame:CGRectZero];
  navBar_.barStyle = UIBarStyleBlack;
  [self setNavbarWithTitle:@"PERFECTIVE"];
  [self.view addSubview:navBar_];
  
  dimView_ = [[UIView alloc] initWithFrame:self.view.bounds];
  dimView_.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
  dimView_.alpha = 0;
  dimView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:dimView_];
  
  dismissPickerButton_ = [UIButton buttonWithType:UIButtonTypeCustom];
  dismissPickerButton_.frame = self.view.bounds;
  dismissPickerButton_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  dismissPickerButton_.hidden = YES;
  [dismissPickerButton_ addTarget:self action:@selector(dismissPickerSheet) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:dismissPickerButton_];
  
  pickerSheet_ = [[BWAssetPickerSheet alloc] initWithFrame:self.view.bounds];
  pickerSheet_.delegate = self;
  CGRect pickerFrame = pickerSheet_.frame;
  pickerFrame.size.height = [pickerSheet_ idealHeight] + 50;
  pickerSheet_.frame = CGRectAttachedBottomToRect(self.view.bounds, pickerFrame.size, 0, YES);
  
  [self.view addSubview:pickerSheet_];
}

- (void)setNavbarWithTitle:(NSString *)title {
  UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:title];
  [navBar_ setItems:@[navItem]];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  photoViewController_.contentEdgeInsets = UIEdgeInsetsMake(64, 0, 44, 0);
  navBar_.frame = CGRectFramedTopInRect(self.view.bounds, CGSizeMake(self.view.bounds.size.width, 64), 0, YES);
  bottomBar_.frame = CGRectFramedBottomInRect(self.view.bounds, CGSizeMake(self.view.bounds.size.width, 44), 0, YES);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

#pragma mark - Action Responders

- (void)declareSquare {
  NSArray *items;
  if (photoViewController_.currentState == BWPhotoStateSquare) {
    [squareButton_ setImage:[UIImage imageNamed:@"squareIcon"]];
    photoViewController_.currentState = BWPhotoStateNone;
    items = @[saveButton_, flex1_, squareButton_, flex2_, linesButton_, flex3_, choosePhoto_];
  } else {
    [squareButton_ setImage:[UIImage imageNamed:@"squareIcon_selected"]];
    photoViewController_.currentState = BWPhotoStateSquare;
    items = @[saveButton_, flex1_, squareButton_, flex2_, linesButton_, flex3_, applyButton_];
  }
  [linesButton_ setImage:[UIImage imageNamed:@"parallelIcon"]];
  [bottomBar_ setItems:items animated:YES];
}

- (void)declareLines {
  NSArray *items;
  if (photoViewController_.currentState == BWPhotoStateLines) {
    [linesButton_ setImage:[UIImage imageNamed:@"parallelIcon"]];
    photoViewController_.currentState = BWPhotoStateNone;
    items = @[saveButton_, flex1_, squareButton_, flex2_, linesButton_, flex3_, choosePhoto_];
  } else {
    [linesButton_ setImage:[UIImage imageNamed:@"parallelIcon_selected"]];
    photoViewController_.currentState = BWPhotoStateLines;
    items = @[saveButton_, flex1_, squareButton_, flex2_, linesButton_, flex3_, applyButton_];
  }
  [squareButton_ setImage:[UIImage imageNamed:@"squareIcon"]];
  [bottomBar_ setItems:items animated:YES];
}

- (void)saveImage {
  UIAlertView *save = [[UIAlertView alloc] initWithTitle:@"Image Saved!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
  [save show];
  [photoViewController_ saveImage];
}

- (void)applyCurrentTransform {
  [photoViewController_ setTransformApplied:YES animate:YES];
  [bottomBar_ setItems: @[saveButton_, flex1_, squareButton_, flex2_, linesButton_, flex3_, editButton_] animated:YES];

}

- (void)editCurrentTransform {
  [photoViewController_ setTransformApplied:NO animate:YES];
  [bottomBar_ setItems: @[saveButton_, flex1_, squareButton_, flex2_, linesButton_, flex3_, applyButton_] animated:YES];
}

- (void)transformChanged {
  applyButton_.enabled = photoViewController_.transformValid;
  saveButton_.enabled = photoViewController_.transformValid;
}

- (void)pickImage {
  [self showPickerSheet];
}

#pragma mark - Picker View Methods

- (void)showPickerSheet {
  [photoViewController_ pause];
  dismissPickerButton_.hidden = NO;
  POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
  anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  anim.fromValue = @(0.0);
  anim.toValue = @(1.0);
  [dimView_ pop_addAnimation:anim forKey:@"fade"];
  
  CGRect toRect = CGRectFramedBottomInRect(self.view.bounds, pickerSheet_.bounds.size, -50, YES);
  POPSpringAnimation *anim2 = [POPSpringAnimation animationWithPropertyNamed:kPOPViewCenter];
  anim2.toValue = [NSValue valueWithCGPoint:CGRectGetCenterPoint(toRect)];
  [pickerSheet_ pop_addAnimation:anim2 forKey:@"size"];
}

- (void)dismissPickerSheet {
  [self dismissPickerSheetWithCompletion:NULL];
}

- (void)dismissPickerSheetWithCompletion:(void (^)())completion {
  [photoViewController_ start];
  dismissPickerButton_.hidden = YES;
  POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
  anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  anim.fromValue = @(1.0);
  anim.toValue = @(0.0);
  [dimView_ pop_addAnimation:anim forKey:@"fade"];
  
  CGRect toRect = CGRectAttachedBottomToRect(self.view.bounds, pickerSheet_.bounds.size, 0, YES);
  POPSpringAnimation *anim2 = [POPSpringAnimation animationWithPropertyNamed:kPOPViewCenter];
  anim2.toValue = [NSValue valueWithCGPoint:CGRectGetCenterPoint(toRect)];

  [anim2 setCompletionBlock:^(POPAnimation *anim, BOOL complete) {
    [pickerSheet_ resetState];
    if (completion) {
      completion();
    }
  }];

  [pickerSheet_ pop_addAnimation:anim2 forKey:@"size"];
}

#pragma mark - Picker Sheet Delegate

- (void)assetPickerSheet:(BWAssetPickerSheet *)picker didSelectImage:(UIImage *)image {
  [photoViewController_ loadImage:image];
  [photoViewController_ start];
  [self dismissPickerSheet];
}

- (void)assetPickerSheetDidCancel:(BWAssetPickerSheet *)picker {
  [self dismissPickerSheet];
}

- (void)assetPickerSheetDidChooseCamera:(BWAssetPickerSheet *)picker {
  [self dismissPickerSheetWithCompletion:^{
    [self presentCameraPicker];
  }];
}

- (void)assetPickerSheetDidChooseLibrary:(BWAssetPickerSheet *)picker {
  [self dismissPickerSheetWithCompletion:^{
    [self presentImagePickerController];
  }];
}

- (void)assetPickerSheetDidLoadMostRecentPhoto:(UIImage *)mostRecent {
  [photoViewController_ loadImage:mostRecent];
}

#pragma mark - Image Picker

- (void)presentCameraPicker {
  [photoViewController_ pause];
  UIImagePickerController *pc = [[UIImagePickerController alloc] init];
  pc.sourceType = UIImagePickerControllerSourceTypeCamera;
  pc.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
  pc.delegate = self;
  [self presentViewController:pc animated:YES completion:NULL];
}
- (void)presentImagePickerController {
  [photoViewController_ pause];
  UIImagePickerController *pc = [[UIImagePickerController alloc] init];
  pc.delegate = self;
  [self presentViewController:pc animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
  [photoViewController_ loadImage:image];
  [photoViewController_ start];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [photoViewController_ start];
  [self dismissViewControllerAnimated:YES completion:nil];
}
@end
