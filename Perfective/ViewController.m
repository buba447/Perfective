//
//  ViewController.m
//  Perfective
//
//  Created by Brandon Withrow on 4/25/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "ViewController.h"
#import "BWMesh.h"
#import "BWShader.h"
#import "BWModel.h"
#import "BWImage.h"
#import "BWLineModel.h"
#import "CGGeometryAdditions.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate> {
  NSMutableArray *cornerPoints_;
  
  UIScrollView *scroller_;
  UIView *placeholderView_;
  UIToolbar *bottomBar_;
  UINavigationBar *navBar_;
  
  BWModel *pictureModel_;
  BWModel *loupeModel_;
  BWLineModel *overLayModel_;
  
  CADisplayLink *trackingDisplayLink_;
  CADisplayLink *zoomingDisplayLink_;
  
  UITapGestureRecognizer *doubleTap_;
  UITapGestureRecognizer *singleTap_;
  
  UIImage *currentImage_;
  
  BOOL drawLoupe_;
  
  BOOL pauseUpdate_;
  BOOL drawUpdate_;
  BOOL needsUpdate_;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation ViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
  drawLoupe_ = NO;
  [super viewDidLoad];
  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

  pauseUpdate_ = NO;
  needsUpdate_ = YES;

  scroller_ = [[UIScrollView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:scroller_];
  scroller_.alwaysBounceHorizontal = YES;
  scroller_.alwaysBounceVertical = YES;
  scroller_.contentSize = self.view.bounds.size;
  scroller_.indicatorStyle = UIScrollViewIndicatorStyleWhite;
  scroller_.delegate = self;
  
  placeholderView_ = [[UIView alloc] initWithFrame:self.view.bounds];
  [scroller_ addSubview:placeholderView_];
  
  cornerPoints_ = [NSMutableArray array];
  
  if (!self.context) {
      NSLog(@"Failed to create ES context");
  }
  
  GLKView *view = (GLKView *)self.view;
  view.context = self.context;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  
  bottomBar_ = [[UIToolbar alloc] initWithFrame:CGRectZero];
  
  UIBarButtonItem *exportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(saveImage)];
  UIBarButtonItem *squareButton = [[UIBarButtonItem alloc] initWithTitle:@"Square" style:UIBarButtonItemStylePlain target:self action:@selector(declareSquare)];
  UIBarButtonItem *lines = [[UIBarButtonItem alloc] initWithTitle:@"Lines" style:UIBarButtonItemStylePlain target:self action:@selector(declareLines)];
  UIBarButtonItem *pickImage = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(pickImage)];
  
  UIBarButtonItem *flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIBarButtonItem *flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIBarButtonItem *flex3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

  [bottomBar_ setItems:@[exportButton, flex1, squareButton, flex2, lines, flex3, pickImage]];
  [self.view addSubview:bottomBar_];
  
  doubleTap_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
  doubleTap_.numberOfTapsRequired = 2;
  [placeholderView_ addGestureRecognizer:doubleTap_];
  
  singleTap_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  singleTap_.enabled = NO;
  [singleTap_ requireGestureRecognizerToFail:doubleTap_];
  [placeholderView_ addGestureRecognizer:singleTap_];
  
  [self setupGL];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGL)
                                               name:UIApplicationWillEnterForegroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGL)
                                               name:UIApplicationDidBecomeActiveNotification object:nil];
  
  navBar_ = [[UINavigationBar alloc] initWithFrame:CGRectZero];
  [self setNavbarWithTitle:@"PERFECTIVE"];
//  [self.view addSubview:navBar_];
}

- (void)refreshGL {
  needsUpdate_ = YES;
}

- (void)setNavbarWithTitle:(NSString *)title {
  UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:title];
  [navBar_ setItems:@[navItem]];
}

- (UIView *)cornerView {
  CGFloat boundSize = (1.f / scroller_.zoomScale) * 50;
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, boundSize, boundSize)];
  
  UIImageView *image = [[UIImageView alloc] initWithFrame:view.bounds];
  image.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  [image setImage:[UIImage imageNamed:@"circle"]];
  [view addSubview:image];
  
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handPan:)];
  [view addGestureRecognizer:pan];
  [placeholderView_ addSubview:view];
  return view;
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];

  BOOL zoomToMin = (scroller_.zoomScale == scroller_.minimumZoomScale);
  BOOL zoomToMax = (scroller_.zoomScale == scroller_.maximumZoomScale);
  scroller_.frame = self.view.bounds;
  [self setZoomConstraints];
  
  if (scroller_.zoomScale <= scroller_.minimumZoomScale || zoomToMin) {
    scroller_.zoomScale = scroller_.minimumZoomScale;
  } else if (scroller_.zoomScale > scroller_.maximumZoomScale || zoomToMax) {
    scroller_.zoomScale = scroller_.maximumZoomScale;
  }
  
  [self setScrollEdgeInsets];
  needsUpdate_ = YES;
  
  navBar_.frame = CGRectFramedTopInRect(self.view.bounds, CGSizeMake(self.view.bounds.size.width, 64), 0, YES);
  bottomBar_.frame = CGRectFramedBottomInRect(self.view.bounds, CGSizeMake(self.view.bounds.size.width, 44), 0, YES);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self startTrackingDisplayLinkIfNeccessary];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self invalidateTrackingDisplayLink];
}

- (void)dealloc {
  [self tearDownGL];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if ([EAGLContext currentContext] == self.context) {
    [EAGLContext setCurrentContext:nil];
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  
  if ([self isViewLoaded] && ([[self view] window] == nil)) {
    self.view = nil;
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
      [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
  }
}

#pragma mark - Gesture Recognizers

- (void)handPan:(UIPanGestureRecognizer *)panGesture {
  if (panGesture.state == UIGestureRecognizerStateEnded) {
    NSArray *newCorners = [self sortedCornersForQuad];
    if (newCorners.count == 4) {
      [cornerPoints_ removeAllObjects];
      [cornerPoints_ addObjectsFromArray:newCorners];
    } else {
      // HANDLE NON-PLANAR ERROR
    }
    drawLoupe_ = NO;
    needsUpdate_ = YES;
    return;
  }
  panGesture.view.center = [panGesture locationInView:placeholderView_];
  [self computeLoupeDateFromScreenPoint:[panGesture locationInView:self.view]];
  drawLoupe_ = YES;
  needsUpdate_ = YES;
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)doubleTap {
  if (scroller_.zoomScale >= scroller_.maximumZoomScale) {
    [self startZoomingDisplayLinkIfNeccessary];
    [scroller_ setZoomScale:scroller_.minimumZoomScale animated:YES];
  } else {
    [self startZoomingDisplayLinkIfNeccessary];
    CGPoint centerPoint = [doubleTap locationInView:placeholderView_];
    CGSize rectSize = self.view.bounds.size;
    rectSize.width *= scroller_.maximumZoomScale;
    rectSize.height *= scroller_.maximumZoomScale;
    CGRect zoomRect = CGRectCenteredAtPoint(centerPoint, rectSize, YES);
    [scroller_ zoomToRect:zoomRect animated:YES];
  }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)singleTap {
  NSLog(@"Single Tap");
  CGPoint location = [singleTap locationInView:placeholderView_];
  UIView *corner = [self cornerView];
  corner.center = location;
  [cornerPoints_ addObject:corner];
  if (cornerPoints_.count == 4) {
    singleTap_.enabled = NO;
    [self setNavbarWithTitle:@"PERFECTIVE"];
    //Sort points by quad.
    NSArray *newCorners = [self sortedCornersForQuad];
    if (newCorners.count == 4) {
      [cornerPoints_ removeAllObjects];
      [cornerPoints_ addObjectsFromArray:newCorners];
      needsUpdate_ = YES;
    } else {
      // HANDLE NON-PLANAR ERROR
    }
  }
}

- (NSArray *)sortedCornersForQuad {
  NSMutableArray *corners;
  if (cornerPoints_.count == 4) {
    for (int i = 1; i < 4; i ++) {
      corners = [NSMutableArray arrayWithArray:cornerPoints_];
      UIView *first = [cornerPoints_ objectAtIndex:0];
      UIView *second = [cornerPoints_ objectAtIndex:i];
      [corners removeObjectAtIndex:0];
      [corners removeObjectAtIndex:i - 1];
      UIView *third = [corners objectAtIndex:0];
      UIView *fourth = [corners objectAtIndex:1];
      [corners removeAllObjects];
      CGPoint i = IntersectionOfPoints(first.center, second.center, third.center, fourth.center);
      if (!CGPointEqualToPoint(i, CGPointZero)) {
        // found our intersectiong point set
        NSLog(@"Found Point");
        // sort left to right
        UIView *set1L = (first.center.x < second.center.x) ? first : second;
        UIView *set1R = (first.center.x < second.center.x) ? second : first;
        
        UIView *set2L = (third.center.x < fourth.center.x) ? third : fourth;
        UIView *set2R = (third.center.x < fourth.center.x) ? fourth : third;
        
        if (set1L.center.y < set2L.center.y) {
          [corners addObject:set1L];
          [corners addObject:set2R];
          [corners addObject:set2L];
          [corners addObject:set1R];
        } else {
          [corners addObject:set2L];
          [corners addObject:set1R];
          [corners addObject:set1L];
          [corners addObject:set2R];
        }
        break;
      }
    }
  }
  return corners;
}

#pragma mark - Scroll View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [self startTrackingDisplayLinkIfNeccessary];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
  [self startZoomingDisplayLinkIfNeccessary];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (scroller_.layer.animationKeys.count && !decelerate) {
    CAAnimation *animation = [scroller_.layer animationForKey:scroller_.layer.animationKeys.firstObject];
    [self performSelector:@selector(invalidateTrackingDisplayLink) withObject:nil afterDelay:animation.duration + 0.001];
  } else if (!decelerate) {
    [self invalidateTrackingDisplayLink];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [self invalidateTrackingDisplayLink];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
  [self invalidateZoomingDisplayLink];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
  for (UIView *view in cornerPoints_) {
    CGFloat boundSize = (1.f / scroller_.zoomScale) * 50;
    view.bounds = CGRectMake(0, 0, boundSize, boundSize);
  }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return placeholderView_;
}

- (void)setScrollEdgeInsets {
  CGFloat imageAspect = placeholderView_.bounds.size.width / placeholderView_.bounds.size.height;
  CGFloat viewAspect = self.view.bounds.size.width / self.view.bounds.size.height;
  UIEdgeInsets contentInset;
  if (imageAspect > viewAspect) {
    CGFloat inset = MAX(0, (self.view.bounds.size.height - (scroller_.zoomScale * placeholderView_.bounds.size.height)) * 0.5);
    contentInset = UIEdgeInsetsMake(inset, 0, inset, 0);
  } else {
    CGFloat inset = MAX(0, (self.view.bounds.size.width - (scroller_.zoomScale * placeholderView_.bounds.size.width)) * 0.5);
    contentInset = UIEdgeInsetsMake(0, inset, 0, inset);
  }
  scroller_.contentInset = contentInset;
}

- (void)setZoomConstraints {
  CGFloat imageAspect = placeholderView_.bounds.size.width / placeholderView_.bounds.size.height;
  CGFloat viewAspect = self.view.bounds.size.width / self.view.bounds.size.height;
  
  CGFloat zoomScale = (imageAspect > viewAspect ?
                       self.view.bounds.size.width / placeholderView_.bounds.size.width:
                       self.view.bounds.size.height / placeholderView_.bounds.size.height);
  if (zoomScale < 1) {
    scroller_.minimumZoomScale = zoomScale;
  } else {
    scroller_.minimumZoomScale = zoomScale;
    scroller_.maximumZoomScale = zoomScale * 2;
  }
}

#pragma mark - Display Link

- (void)displayGL {
  [self setScrollEdgeInsets];
  needsUpdate_ = YES;
  [self update];
  [(GLKView *)self.view display];
}

- (void)startZoomingDisplayLinkIfNeccessary {
  if (!zoomingDisplayLink_) {
    zoomingDisplayLink_ = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayGL)];
    [zoomingDisplayLink_ addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  }
}

- (void)invalidateZoomingDisplayLink {
  [zoomingDisplayLink_ invalidate];
  zoomingDisplayLink_ = nil;
}

- (void)startTrackingDisplayLinkIfNeccessary {
  if (!trackingDisplayLink_) {
    trackingDisplayLink_ = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayGL)];
    [trackingDisplayLink_ addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  }
}

- (void)invalidateTrackingDisplayLink {
  [trackingDisplayLink_ invalidate];
  trackingDisplayLink_ = nil;
}

#pragma mark - Image Picker

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  //  horizScale_ = 1.f;
  UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
  pauseUpdate_ = NO;
  [self loadImage:image];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pickImage {
  pauseUpdate_ = YES;
  UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
  imagePicker.delegate = self;
  [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  pauseUpdate_ = NO;
  needsUpdate_ = YES;
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Image Loading and Saving

- (void)loadImage:(UIImage *)image {
  //Load Image Into GL
  BWImage *selectedImage = [[BWImage alloc] initWithImage:image];
  pictureModel_.imageTexture = selectedImage;
  loupeModel_.imageTexture = selectedImage;
  
  [self computeDataForSquare:pictureModel_.mesh
                 withTopLeft:CGPointMake(0, 0)
                    topRight:CGPointMake(image.size.width, 0)
                  bottomLeft:CGPointMake(0, image.size.height)
                 bottomRight:CGPointMake(image.size.width, image.size.height)];
  
  [self computeDataForSquare:overLayModel_.mesh
                 withTopLeft:CGPointMake(0, 0)
                    topRight:CGPointMake(image.size.width, 0)
                  bottomLeft:CGPointMake(image.size.width, image.size.height)
                 bottomRight:CGPointMake(0, image.size.height)];

  //Tell GL Update is needed
  needsUpdate_ = YES;
  
  //Setup ScrollView and content
  scroller_.contentOffset = CGPointZero;
  scroller_.zoomScale = 1;
  scroller_.minimumZoomScale = 1;
  scroller_.maximumZoomScale = 1;
  scroller_.contentSize = image.size;
  
  placeholderView_.frame = CGRectMake(0, 0, image.size.width, image.size.height);
  
  [self setZoomConstraints];
  scroller_.zoomScale = scroller_.minimumZoomScale;
  [self setScrollEdgeInsets];
}

- (void)saveImage {
  // Figure out drawing Rect and transforms.
  
  CGSize originalPictureSize; // = xformedPictureModel_.imageTexture.originalImage.size;
  
  //  GLKMatrix4 transHomography = xformedPictureModel_.transform;
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, originalPictureSize.width, originalPictureSize.height, 0, 1, -1);
  
  //  int viewport[] = {0, 0, originalPictureSize.width, originalPictureSize.height};
  //
  //  GLKVector3 topLeft = GLKMathProject(GLKVector3Make(0, 0, 0), transHomography, projection, viewport);
  //  topLeft.y = originalPictureSize.height - topLeft.y;
  //
  //  GLKVector3 topRight = GLKMathProject(GLKVector3Make(scaledImageSize.width, 0, 0), transHomography, projection, viewport);
  //  topRight.y = originalPictureSize.height - topRight.y;
  //
  //  GLKVector3 bottomLeft = GLKMathProject(GLKVector3Make(0, scaledImageSize.height, 0), transHomography, projection, viewport);
  //  bottomLeft.y = originalPictureSize.height - bottomLeft.y;
  //
  //  GLKVector3 bottomRight = GLKMathProject(GLKVector3Make(scaledImageSize.width, scaledImageSize.height, 0), transHomography, projection, viewport);
  //  bottomRight.y = originalPictureSize.height - bottomRight.y;
  
  //  CGFloat leftEdge = (topLeft.x + bottomLeft.x) / 2;
  //  CGFloat rightEdge = (topRight.x + bottomRight.x) / 2;
  //  topLeft.x = bottomLeft.x = leftEdge;
  //  topRight.x = bottomRight.x = rightEdge;
  //
  //  CGRect boundingBox = BoundingBoxForPoints(CGPointMake(topLeft.x, topLeft.y), CGPointMake(topRight.x, topRight.y), CGPointMake(bottomLeft.x, bottomLeft.y), CGPointMake(bottomRight.x, bottomRight.y));
  
  
  //  CGFloat ratio = boundingBox.size.height / boundingBox.size.width;
  //  CGFloat width = originalPictureSize.width;
  //  CGFloat height = width * ratio;
  
  
  
  //  CGFloat screenRatio = self.view.bounds.size.height / self.view.bounds.size.width;
  //  CGFloat newWindowHeight = boundingBox.size.width * screenRatio;
  //  GLKMatrix4 newWindowProjection = GLKMatrix4MakeOrtho(boundingBox.origin.x, boundingBox.size.width + boundingBox.origin.x, boundingBox.origin.y + newWindowHeight, boundingBox.origin.y, 1, -1);
  //
  CGFloat width = originalPictureSize.width;
  CGFloat height = originalPictureSize.height;
  //  CGFloat screenRatio = self.view.bounds.size.height / self.view.bounds.size.width;
  //  CGFloat newWindowHeight = boundingBox.size.width * screenRatio;
  //  GLKMatrix4 newWindowProjection = GLKMatrix4MakeOrtho(boundingBox.origin.x, boundingBox.size.width + boundingBox.origin.x, boundingBox.origin.y + boundingBox.size.height, boundingBox.origin.y, 1, -1);
  GLKMatrix4 oldXform; // = xformedPictureModel_.projection;
  GLKMatrix4 oldXformTreans; // = xformedPictureModel_.projectionTransform;
  
  //  xformedPictureModel_.projectionTransform = GLKMatrix4Identity;
  //  xformedPictureModel_.projection = projection;
  //  xformedPictureModel_.transform = GLKMatrix4Identity;
  
  
  
  //  GLKMatrix4 newProjection = GLKMatrix4MakeOrtho(0, width, height, 0, 1, -1);
  
  pauseUpdate_ = YES;
  
  GLuint framebuffer;
  glGenFramebuffers(1, &framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  
  GLuint colorRenderbuffer;
  glGenRenderbuffers(1, &colorRenderbuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, width, height);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
  
  GLuint depthRenderbuffer;
  glGenRenderbuffers(1, &depthRenderbuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
  
  GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
  if(status != GL_FRAMEBUFFER_COMPLETE) {
    NSLog(@"failed to make complete framebuffer object %x", status);
  }
  
  glViewport(0, 0, width, height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  
  glClearColor(1.f, 0.f, 0.f, 1.f);
  glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
  
//  [xformedPictureModel_ use];
//  [xformedPictureModel_ draw];
  
  glBindTexture(GL_TEXTURE_2D, 0);
  glBindVertexArrayOES(0);
  glUseProgram(0);
  
  
  GLint x = 0, y = 0;
  NSInteger dataLength = width * height * 4;
  GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
  
  glPixelStorei(GL_PACK_ALIGNMENT, 4);
  glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
  
  CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
  CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
  CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                  ref, NULL, true, kCGRenderingIntentDefault);
  
  
  UIGraphicsBeginImageContext(CGSizeMake(width, height));
  CGContextRef cgcontext = UIGraphicsGetCurrentContext();
  CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
  CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  free(data);
  CFRelease(ref);
  CFRelease(colorspace);
  CGImageRelease(iref);
  UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
  
  glDeleteRenderbuffers(1, &colorRenderbuffer);
  glDeleteRenderbuffers(1, &depthRenderbuffer);
  glDeleteFramebuffers(1, &framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glBindRenderbuffer(GL_RENDERBUFFER, 0);
  pauseUpdate_ = NO;
  needsUpdate_ = YES;
}

#pragma mark - action responders 

- (void)declareSquare {
  [self setNavbarWithTitle:@"Tap Square Corners"];
  singleTap_.enabled = YES;
  for (UIView *corner in cornerPoints_) {
    [corner removeFromSuperview];
  }
  [cornerPoints_ removeAllObjects];
  needsUpdate_ = YES;
}

- (void)declareLines {
  [self setNavbarWithTitle:@"Tap Parellel Lines"];
  singleTap_.enabled = YES;
  for (UIView *corner in cornerPoints_) {
    [corner removeFromSuperview];
  }
  [cornerPoints_ removeAllObjects];
  needsUpdate_ = YES;
}

#pragma mark - mesh data computation

- (void)computeDataForSquare:(BWMesh *)mesh
                 withTopLeft:(CGPoint)topLeft
                    topRight:(CGPoint)topRight
                  bottomLeft:(CGPoint)bottomLeft
                 bottomRight:(CGPoint)bottomRight {
  
  GLKVector4 w = QuadrilateralQForPoints(topLeft, topRight, bottomLeft, bottomRight);
  
  [mesh setVertex:GLKVector3Make(topLeft.x, topLeft.y, 0.f) atIndex:0];
  [mesh setTexCoor0:GLKVector3Make(0.f, 0.f, 1.f / w.x) atIndex:0];
  
  [mesh setVertex:GLKVector3Make(topRight.x, topRight.y, 0.f) atIndex:1];
  [mesh setTexCoor0:GLKVector3Make(1.f * w.y, 0.f, 1.f / w.y) atIndex:1];
  
  [mesh setVertex:GLKVector3Make(bottomLeft.x, bottomLeft.y, 0.f) atIndex:2];
  [mesh setTexCoor0:GLKVector3Make(0.f, 1.f * w.z, 1.f / w.z) atIndex:2];
  
  [mesh setVertex:GLKVector3Make(bottomRight.x, bottomRight.y, 0.f) atIndex:3];
  [mesh setTexCoor0:GLKVector3Make(1.f * w.w, 1.f * w.w, 1.f / w.w) atIndex:3];
}

- (void)computeLoupeDateFromScreenPoint:(CGPoint)point {
  float zoomScale = 2;
  float loupeSize = 128;
  float loupeOffset = 50;
  CGPoint loupeCenter = point;
  loupeCenter.y -= loupeOffset;
  
  if (loupeCenter.y < loupeSize * 0.5) {
    //Past the top
    /*
     Not Known_______  New Loupe Center
     |     /
     |    /
     |   /
     |  / Needs to be loupeOffset
     | /
     |/
     Touch point
     
     */
    loupeCenter.y = loupeSize * 0.5;
    CGFloat xOffset = sqrtf((pow(loupeOffset, 2) - pow(point.y - loupeCenter.y, 2)));
    loupeCenter.x = loupeCenter.x - xOffset > loupeSize ? loupeCenter.x - xOffset : loupeCenter.x + xOffset;
  }
  
  CGPoint centerOfSample = [placeholderView_ convertPoint:point fromView:self.view];
  CGPoint uvSampleCenter = CGPointMake(centerOfSample.x / placeholderView_.bounds.size.width, centerOfSample.y / placeholderView_.bounds.size.height);
  CGFloat uvOffsetSize = ((loupeSize / placeholderView_.bounds.size.width) / zoomScale) * 0.5;
  
  //              x  y   z    u   v   q    u   v   q
  //top left      0, 1,  2 -  3,  4,  5 -  6,  7,  8
  
  GLKMatrix3 first = GLKMatrix3Make(loupeCenter.x - (loupeSize * 0.5), loupeCenter.y - (loupeSize * 0.5), 0,
                                    uvSampleCenter.x - uvOffsetSize, uvSampleCenter.y - uvOffsetSize, 1.f,
                                    0, 0, 0);
  [loupeModel_.mesh setVertexData:first atIndex:0];
  
  //              x  y   z    u   v   q    u   v   q
  //top right     9, 10, 11 - 12, 13, 14 - 15, 16, 17
  
  GLKMatrix3 second = GLKMatrix3Make(loupeCenter.x + (loupeSize * 0.5), loupeCenter.y - (loupeSize * 0.5), 0.f,
                                     uvSampleCenter.x + uvOffsetSize, uvSampleCenter.y - uvOffsetSize, 1.f,
                                     1.f, 0.f, 0.f);
  [loupeModel_.mesh setVertexData:second atIndex:1];
  
  //              x   y   z    u   v   q    u   v   q
  //bottom left   18, 19, 20 - 21, 22, 23 - 24, 25, 26
  
  
  GLKMatrix3 third = GLKMatrix3Make(loupeCenter.x - (loupeSize * 0.5), loupeCenter.y + (loupeSize * 0.5), 0.f,
                                    uvSampleCenter.x - uvOffsetSize, uvSampleCenter.y + uvOffsetSize, 1.f,
                                    0.f, 1.f, 0.f);
  [loupeModel_.mesh setVertexData:third atIndex:2];
  
  //              x   y   z    u   v   q    u   v   q
  //bottom right  27, 28, 29 - 30, 31, 32 - 33, 34, 35
  GLKMatrix3 fourth = GLKMatrix3Make(loupeCenter.x + (loupeSize * 0.5), loupeCenter.y + (loupeSize * 0.5), 0.f,
                                     uvSampleCenter.x + uvOffsetSize, uvSampleCenter.y + uvOffsetSize, 1.f,
                                     1.f, 1.f, 0.f);
  [loupeModel_.mesh setVertexData:fourth atIndex:3];
}

#pragma mark - GLKView Methods

- (void)setupGL {
  [EAGLContext setCurrentContext:self.context];

  glEnable(GL_TEXTURE_2D);
  
  glEnable(GL_BLEND);
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glShadeModel (GL_SMOOTH);
  
  BWShader *pictureShader = [[BWShader alloc] initWithShaderNamed:@"Shader"];
  
  BWShader *loupeShader = [[BWShader alloc] initWithShaderNamed:@"circleShader"];
  
  BWMesh *loupeMesh = [[BWMesh alloc] initWithNumberOfVertices:4];
  BWMesh *pictureMesh = [[BWMesh alloc] initWithNumberOfVertices:4];

  BWMesh *lineMesh = [[BWMesh alloc] initWithNumberOfVertices:4];

  loupeModel_ = [[BWModel alloc] init];
  loupeModel_.shader = loupeShader;
  loupeModel_.mesh = loupeMesh;
  
  pictureModel_ = [[BWModel alloc] init];
  pictureModel_.shader = pictureShader;
  pictureModel_.mesh = pictureMesh;
  
  overLayModel_ = [[BWLineModel alloc] init];
  overLayModel_.shader = pictureShader;
  overLayModel_.mesh = lineMesh;
  overLayModel_.lineWidth = 2.f;
  overLayModel_.lineColor = GLKVector4Make(1, 0.4, 0.0, 0.2);

  [self loadImage:[UIImage imageNamed:@"photo.JPG"]];
}

- (void)update {
  if (needsUpdate_) {
    drawUpdate_ = YES;
    needsUpdate_ = NO;
    
    CALayer *zoomedLayer = placeholderView_.layer.presentationLayer;
    CGFloat viewportZoomScale = zoomedLayer.transform.m11;
    
    CALayer *presentationLayer = scroller_.layer.presentationLayer;
    CGPoint contentOffset = presentationLayer.bounds.origin;
    
    GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, self.view.bounds.size.width, self.view.bounds.size.height, 0, 1, -1);
    GLKMatrix4 projectionXform = GLKMatrix4Scale(GLKMatrix4MakeTranslation(-contentOffset.x, -contentOffset.y, 0), viewportZoomScale, viewportZoomScale, 1);
    pictureModel_.projection = projection;
    pictureModel_.projectionTransform = projectionXform;
    
    overLayModel_.projection = projection;
    overLayModel_.projectionTransform = projectionXform;
    if (cornerPoints_.count == 4) {
      CGPoint corner1, corner2, corner3, corner4;
      corner1 = ((UIView *)cornerPoints_[0]).center;
      corner2 = ((UIView *)cornerPoints_[1]).center;
      corner3 = ((UIView *)cornerPoints_[2]).center;
      corner4 = ((UIView *)cornerPoints_[3]).center;
      overLayModel_.transform = HomographicMatrix(placeholderView_.bounds.size.width,
                                                  placeholderView_.bounds.size.height,
                                                  corner1, corner2, corner3, corner4);
    }
    
//    pictureModel_.transform = projectionXform;
    

//    GLKMatrix4 transHomography = GLKMatrix4Multiply(GLKMatrix4MakeScale(horizScale_, 1.f, 1.f), TransHomographicMatrix(scaledImageSize.width, scaledImageSize.height, corner1_.center, corner2_.center, corner3_.center, corner4_.center));
//    int viewport[] = {0, 0, self.view.bounds.size.width, self.view.bounds.size.height};
//    
//    GLKVector3 topLeft = GLKMathProject(GLKVector3Make(0, 0, 0), transHomography, projection, viewport);
//    topLeft.y = self.view.bounds.size.height - topLeft.y;
//    
//    GLKVector3 topRight = GLKMathProject(GLKVector3Make(scaledImageSize.width, 0, 0), transHomography, projection, viewport);
//    topRight.y = self.view.bounds.size.height - topRight.y;
//    
//    GLKVector3 bottomLeft = GLKMathProject(GLKVector3Make(0, scaledImageSize.height, 0), transHomography, projection, viewport);
//    bottomLeft.y = self.view.bounds.size.height - bottomLeft.y;
//    
//    GLKVector3 bottomRight = GLKMathProject(GLKVector3Make(scaledImageSize.width, scaledImageSize.height, 0), transHomography, projection, viewport);
//    bottomRight.y = self.view.bounds.size.height - bottomRight.y;
    
//    CGFloat leftEdge = (topLeft.x + bottomLeft.x) / 2;
//    CGFloat rightEdge = (topRight.x + bottomRight.x) / 2;
//    topLeft.x = bottomLeft.x = leftEdge;
//    topRight.x = bottomRight.x = rightEdge;
    
//    CGRect boundingBox = BoundingBoxForPoints(CGPointMake(topLeft.x, topLeft.y), CGPointMake(topRight.x, topRight.y), CGPointMake(bottomLeft.x, bottomLeft.y), CGPointMake(bottomRight.x, bottomRight.y));
//    
//    CGFloat screenRatio = self.view.bounds.size.height / self.view.bounds.size.width;
//    CGFloat newWindowHeight = boundingBox.size.width * screenRatio;
//    GLKMatrix4 newWindowProjection = GLKMatrix4MakeOrtho(boundingBox.origin.x, boundingBox.size.width + boundingBox.origin.x, boundingBox.origin.y + newWindowHeight, boundingBox.origin.y, 1, -1);
//    
//    xformedPictureModel_.projection = projection;
//    xformedPictureModel_.transform = transHomography;
//    xformedPictureModel_.projectionTransform = GLKMatrix4Translate(projectionXform, 0, 0.5 * self.view.bounds.size.height, 0);
    loupeModel_.projection = GLKMatrix4MakeOrtho(0, self.view.bounds.size.width, self.view.bounds.size.height, 0, 1, -1);
    
  }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  if (!drawUpdate_) {
    return;
  }
  if (pauseUpdate_) {
    return;
  }
  
  drawUpdate_ = NO;
  glClearColor(0.f, 0.f, 0.f, 0.f);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  [pictureModel_ use];
  [pictureModel_ draw];
  
  if (cornerPoints_.count == 4) {
    [overLayModel_ use];
    overLayModel_.lineWidth = 8.f;
    overLayModel_.lineColor = GLKVector4Make(1.f, 0.7f, 0.4f, 0.8f);
    [overLayModel_ draw];
  }
  
//  [overLayModel_ use];
//  GLint dstState;
//  GLint srcState;
//  glGetIntegerv(GL_BLEND_SRC_RGB, &srcState);
//  glGetIntegerv(GL_BLEND_DST_RGB, &dstState);
//  glBlendFunc(GL_SRC_COLOR, GL_DST_COLOR);
//  overLayModel_.lineWidth = 8.f;
//  overLayModel_.lineColor = GLKVector4Make(0.7, 0.1, 0.0, 1.f);
//  [overLayModel_ draw];
//  glBlendFunc(srcState, dstState);
//  [overLayModel_ use];
//  overLayModel_.lineColor = GLKVector4Make(1, 0.9, 0.7, 0.5);
//  overLayModel_.lineWidth = 2.f;
//  [overLayModel_ draw];
//  glBlendFunc(srcState, dstState);
//  
//  if (drawOverlay_) {
//    [xformedPictureModel_ use];
//    [xformedPictureModel_ draw];
//  }
//  
  if (drawLoupe_) {
    [loupeModel_ use];
    GLfloat circleRadius = 0.04;
    [loupeModel_.shader setUniform:@"circleRadius" withValue:&circleRadius];
    GLKVector4 diffuseColor = GLKVector4Make(0.7, 0.4, 0.0, 0.4);
    [loupeModel_.shader setUniform:@"diffuseColor" withValue:&diffuseColor];
    [loupeModel_ draw];
  }
  
  glBindTexture(GL_TEXTURE_2D, 0);
  glBindVertexArrayOES(0);
  glUseProgram(0);
}

- (void)tearDownGL {
  [EAGLContext setCurrentContext:self.context];
}

@end
