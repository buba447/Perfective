//
//  ViewController.m
//  Perfective
//
//  Created by Brandon Withrow on 4/25/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "BWGLPhotViewController.h"
#import "BWMesh.h"
#import "BWShader.h"
#import "BWModel.h"
#import "BWImage.h"
#import "BWLineModel.h"

@interface BWGLPhotViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate> {
  NSMutableArray *cornerPoints_;
  
  UIScrollView *scroller_;
  UIView *placeholderView_;
  
  BWModel *pictureModel_;
  BWModel *loupeModel_;
  BWModel *overLayModel_;

  CADisplayLink *trackingDisplayLink_;
  CADisplayLink *zoomingDisplayLink_;
  CADisplayLink *panDisplayLink_;
  
  UITapGestureRecognizer *doubleTap_;
  UITapGestureRecognizer *singleTap_;
  
  GLKMatrix4 appliedTransform_;
  UIImage *currentImage_;
  
  UIView *projectedView_;
  BOOL drawLoupe_;
  BOOL pauseUpdate_;
  BOOL drawUpdate_;
  BOOL needsUpdate_;
  
  BOOL animatingTransform_;
  CGFloat transformAmount_;
  CGFloat panStartZoom_;
  GLKVector3 transformStartOffsetAndZoom_;
  UIPanGestureRecognizer *currentPan_;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation BWGLPhotViewController

#pragma mark - View Lifecycle

- (instancetype)init {
  self = [super init];
  if (self) {
    self.contentEdgeInsets = UIEdgeInsetsZero;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  appliedTransform_ = GLKMatrix4Identity;
  _currentState = BWPhotoStateNone;
  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  drawLoupe_ = NO;
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
  
  projectedView_ = [[UIView alloc] initWithFrame:CGRectZero];
  projectedView_.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.3];
  [placeholderView_ addSubview:projectedView_];
}

- (void)refreshGL {
  needsUpdate_ = YES;
}

- (UIView *)cornerView {
  CGFloat boundSize = (1.f / scroller_.zoomScale) * 50;
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, boundSize, boundSize)];
  
  UIImageView *image = [[UIImageView alloc] initWithFrame:view.bounds];
  image.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  [image setImage:[UIImage imageNamed:@"circle"]];
  [view addSubview:image];
  
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handPan:)];
  pan.delegate = self;
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
  if (panGesture.state == UIGestureRecognizerStateBegan) {
    panStartZoom_ = scroller_.zoomScale;
    currentPan_ = panGesture;
    if (scroller_.zoomScale == scroller_.minimumZoomScale) {
      CGPoint centerPoint = panGesture.view.center;
      CGSize rectSize = self.view.bounds.size;
      rectSize.width *= scroller_.maximumZoomScale;
      rectSize.height *= scroller_.maximumZoomScale;
      CGRect zoomRect = CGRectCenteredAtPoint(centerPoint, rectSize, YES);
      [scroller_ zoomToRect:zoomRect animated:YES];
    }
  }
  if (panGesture != currentPan_) {
    return;
  }
  CGPoint superLocation = [panGesture locationInView:self.view];
  CGRect insetSelf = CGRectInset(self.view.bounds, 70, 70);
  
  if (!CGRectContainsPoint(insetSelf, superLocation)) {
    [self startPanningDisplayLinkIfNeccessary];
  }
  
  if (!panDisplayLink_) {
    [self scrollPanView];
  }
  
  if (panGesture.state == UIGestureRecognizerStateEnded) {
    [self invalidatePanningDisplayLink];
    currentPan_ = nil;
    [scroller_ setZoomScale:panStartZoom_ animated:YES];
    drawLoupe_ = NO;
  }
}

- (void)scrollPanView {
  CGPoint superLocation = [currentPan_ locationInView:self.view];
  CGPoint scrollerOffset = scroller_.contentOffset;
  
  CGFloat minX = scroller_.zoomScale < 1 ? -scroller_.contentInset.left : 0;
  CGFloat minY = scroller_.zoomScale < 1 ? -scroller_.contentInset.top : 0;
  CGFloat maxX = scroller_.zoomScale < 1 ? -scroller_.contentInset.right : 0;
  CGFloat maxY = scroller_.zoomScale < 1 ? -scroller_.contentInset.bottom : 0;
  if (superLocation.x < 70) {
    scrollerOffset.x = MAX(scrollerOffset.x - 5, minX);
  }
  if (superLocation.x > self.view.bounds.size.width - 70) {
    scrollerOffset.x = MAX(scrollerOffset.x + 5, minX);
  }
  
  if (superLocation.y < 70) {
    scrollerOffset.y = MAX(scrollerOffset.y - 5, minY);
  }
  if (superLocation.y > self.view.bounds.size.height - 70) {
    scrollerOffset.y = MAX(scrollerOffset.y + 5, minY);
  }
  
  scroller_.contentOffset = scrollerOffset;
  
  CGPoint center = [currentPan_ locationInView:placeholderView_];
  center.x = MAX(0, MIN(center.x, placeholderView_.bounds.size.width));
  center.y = MAX(0, MIN(center.y, placeholderView_.bounds.size.height));
  currentPan_.view.center = center;

  [self computeLoupeDateFromScreenPoint:superLocation];
  [self updateForPoints];
  drawLoupe_ = YES;
  needsUpdate_ = YES;
}

- (void)startPanningDisplayLinkIfNeccessary {
  if (!panDisplayLink_) {
    panDisplayLink_ = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollPanView)];
    [panDisplayLink_ addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  }
}

- (void)invalidatePanningDisplayLink {
  [panDisplayLink_ invalidate];
  panDisplayLink_ = nil;
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
    //Sort points by quad.
    [self updateForPoints];
  }
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

#pragma mark - Image Loading and Saving

- (void)loadImage:(UIImage *)image {
  //Load Image Into GL
  for (UIView *view in cornerPoints_) {
    [view removeFromSuperview];
  }
  [cornerPoints_ removeAllObjects];
  [self setCurrentState:BWPhotoStateNone];
  
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
                  bottomLeft:CGPointMake(0, image.size.height)
                 bottomRight:CGPointMake(image.size.width, image.size.height)];

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
  GLint max_rb_size;
  glGetIntegerv (GL_MAX_RENDERBUFFER_SIZE, &max_rb_size);
  
  CGSize originalPictureSize = placeholderView_.bounds.size; // = xformedPictureModel_.imageTexture.originalImage.size;
  
  CGFloat maxSide = MAX(originalPictureSize.height, originalPictureSize.width);
  CGFloat scale = MIN(1, ((CGFloat)max_rb_size / maxSide));
  
  originalPictureSize.width = floor(originalPictureSize.width * scale);
  originalPictureSize.height = floor(originalPictureSize.height * scale);
  
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, originalPictureSize.width, originalPictureSize.height, 0, 1, -1);
  GLKMatrix4 projectionXform = GLKMatrix4Scale(GLKMatrix4MakeTranslation(0, 0, 0), scale, scale, 1);

  CGFloat width = originalPictureSize.width;
  CGFloat height = originalPictureSize.height;

  pictureModel_.projectionTransform = projectionXform;
  pictureModel_.projection = projection;
  pictureModel_.transform = appliedTransform_;

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

  glClearColor(0.f, 0.f, 0.f, 1.f);
  glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
  
  [pictureModel_ use];
  [pictureModel_ draw];

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

- (void)pause {
  pauseUpdate_ = YES;
}

- (void)start {
  pauseUpdate_ = NO;
  needsUpdate_ = YES;
}

#pragma mark - Setter Overrides

- (void)setContentEdgeInsets:(UIEdgeInsets)contentEdgeInsets {
  _contentEdgeInsets = contentEdgeInsets;
  [self setScrollEdgeInsets];
}

- (void)setTransformApplied:(BOOL)transformApplied {
  [self setTransformApplied:transformApplied animate:NO];
}

- (void)setTransformApplied:(BOOL)transformApplied animate:(BOOL)animated {
  _transformApplied = transformApplied;
  
  if (transformApplied) {
    CGPoint corner1, corner2, corner3, corner4;
    corner1 = ((UIView *)cornerPoints_[0]).center;
    corner2 = ((UIView *)cornerPoints_[1]).center;
    corner3 = ((UIView *)cornerPoints_[2]).center;
    corner4 = ((UIView *)cornerPoints_[3]).center;
    
    if (_currentState == BWPhotoStateLines) {
      // Rectify uneven lines
      //first top
      CGFloat riseRunRight = (corner2.x - corner4.x) / fabs(corner2.y - corner4.y);
      CGFloat riseRunLeft = (corner1.x - corner3.x) / fabs(corner1.y - corner3.y);
      if (corner1.y < corner2.y) {
        corner2.x += (fabs(corner2.y - corner1.y) * riseRunRight);
        corner2.y = corner1.y;
        [(UIView *)cornerPoints_[1] setCenter:corner2];
      } else {
        corner1.x += (fabs(corner1.y - corner2.y) * riseRunLeft);
        corner1.y = corner2.y;
        [(UIView *)cornerPoints_[0] setCenter:corner1];
      }
      //now bottom
      if (corner3.y < corner4.y) {
        corner3.x -= (fabs(corner3.y - corner4.y) * riseRunLeft);
        corner3.y = corner4.y;
        [(UIView *)cornerPoints_[2] setCenter:corner3];
      } else {
        corner4.x -= (fabs(corner4.y - corner3.y) * riseRunRight);
        corner4.y = corner3.y;
        [(UIView *)cornerPoints_[3] setCenter:corner4];
      }
    }
    
    GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, self.view.bounds.size.width, self.view.bounds.size.height, 0, 1, -1);
    
    GLKMatrix4 transHomography = TransHomographicMatrix(pictureModel_.imageTexture.originalImage.size.width, pictureModel_.imageTexture.originalImage.size.height, corner1, corner2, corner3, corner4);
    int viewport[] = {0, 0, self.view.bounds.size.width, self.view.bounds.size.height};
    
    GLKVector3 topLeft = GLKMathProject(GLKVector3Make(0, 0, 0), transHomography, projection, viewport);
    topLeft.y -= self.view.bounds.size.height;
    topLeft.y *= -1;
    
    GLKVector3 topRight = GLKMathProject(GLKVector3Make(pictureModel_.imageTexture.originalImage.size.width, 0, 0), transHomography, projection, viewport);
    topRight.y -= self.view.bounds.size.height;
    topRight.y *= -1;
    
    GLKVector3 bottomLeft = GLKMathProject(GLKVector3Make(0, pictureModel_.imageTexture.originalImage.size.height, 0), transHomography, projection, viewport);
    bottomLeft.y -= self.view.bounds.size.height;
    bottomLeft.y *= -1;
    
    GLKVector3 bottomRight = GLKMathProject(GLKVector3Make(pictureModel_.imageTexture.originalImage.size.width, pictureModel_.imageTexture.originalImage.size.height, 0), transHomography, projection, viewport);
    bottomRight.y -= self.view.bounds.size.height;
    bottomRight.y *= -1;
    
    CGRect boundingBox = BoundingBoxForPoints(CGPointMake(topLeft.x, topLeft.y), CGPointMake(topRight.x, topRight.y), CGPointMake(bottomLeft.x, bottomLeft.y), CGPointMake(bottomRight.x, bottomRight.y));
    
    
    CGFloat quadAspect = ComputeAspectFromPoints(corner1, corner4, corner2, corner3, pictureModel_.imageTexture.originalImage.size.width, pictureModel_.imageTexture.originalImage.size.height);//, GLKMatrix3Make(homographic.m00, homographic.m01, homographic.m02, homographic.m10, homographic.m11, homographic.m12, homographic.m20, homographic.m21, homographic.m22));;
    if (_currentState == BWPhotoStateLines) {
      quadAspect = (((corner4.x + corner2.x) / 2) - ((corner3.x + corner1.x) / 2)) / (corner4.y - corner2.y);
    }
    
    CGFloat projectedAdjustedWidth = quadAspect * pictureModel_.imageTexture.originalImage.size.height;
    
    CGFloat aspectScale = projectedAdjustedWidth / pictureModel_.imageTexture.originalImage.size.width;
    
    appliedTransform_ = GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4MakeScale(aspectScale, 1, 1), -(boundingBox.origin.x * 1), -boundingBox.origin.y, 0), transHomography);

    CALayer *presentationLayer = scroller_.layer.presentationLayer;
    CGPoint contentOffset = presentationLayer.bounds.origin;
    transformStartOffsetAndZoom_ = GLKVector3Make(-contentOffset.x, -contentOffset.y, scroller_.zoomScale);
    scroller_.contentOffset = CGPointZero;
    scroller_.zoomScale = 1;
    scroller_.minimumZoomScale = 1;
    scroller_.maximumZoomScale = 1;
    placeholderView_.frame = CGRectMake(0, 0, boundingBox.size.width * aspectScale, boundingBox.size.height);
    
    scroller_.contentSize = placeholderView_.bounds.size;
    [self setZoomConstraints];
    scroller_.zoomScale = scroller_.minimumZoomScale;
    [self setScrollEdgeInsets];
    for (UIView *view in cornerPoints_) {
      view.hidden = YES;
    }
    needsUpdate_ = YES;
    animatingTransform_ = NO;
    transformAmount_ = 0;
  } else {
    needsUpdate_ = YES;
    appliedTransform_ = GLKMatrix4Identity;
    scroller_.contentOffset = CGPointZero;
    scroller_.zoomScale = 1;
    scroller_.minimumZoomScale = 1;
    scroller_.maximumZoomScale = 1;
    placeholderView_.frame = CGRectMake(0, 0, pictureModel_.imageTexture.originalImage.size.width, pictureModel_.imageTexture.originalImage.size.height);
    
    scroller_.contentSize = placeholderView_.bounds.size;
    [self setZoomConstraints];
    scroller_.zoomScale = scroller_.minimumZoomScale;
    [self setScrollEdgeInsets];
    for (UIView *view in cornerPoints_) {
      view.hidden = NO;
    }
  }
}

- (void)setCurrentState:(BWPhotoState)currentState {
  if (_currentState == currentState) {
    return;
  }
  switch (currentState) {
    case BWPhotoStateNone: {
      singleTap_.enabled = NO;
      for (UIView *corner in cornerPoints_) {
        [corner removeFromSuperview];
      }
      
      [cornerPoints_ removeAllObjects];
      [self updateForPoints];
      [self setTransformApplied:NO animate:NO];
    } break;
    case BWPhotoStateSquare: {
      singleTap_.enabled = YES;
    } break;
    case BWPhotoStateLines: {
      singleTap_.enabled = YES;
    } break;
    default:
      break;
  }
  _currentState = currentState;
  
  needsUpdate_ = YES;
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
  
  contentInset.bottom = MAX(contentInset.bottom, self.contentEdgeInsets.bottom);
  contentInset.top = MAX(contentInset.top, self.contentEdgeInsets.top);
  contentInset.left = MAX(contentInset.left, self.contentEdgeInsets.left);
  contentInset.right = MAX(contentInset.right, self.contentEdgeInsets.right);
  
  scroller_.scrollIndicatorInsets = contentInset;
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

#pragma mark - Internal Helpers

- (void)updateForPoints {
  NSArray *newCorners = [self sortedCornersForQuad];
  if (newCorners.count == 4) {
    [cornerPoints_ removeAllObjects];
    [cornerPoints_ addObjectsFromArray:newCorners];
    needsUpdate_ = YES;
    _transformValid = YES;
  } else {
    _transformValid = NO;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:BWTransformValidityChanged object:self];
}

- (GLKMatrix4)adjustedTranshomographyLerpAmount:(CGFloat)amount {
  CGSize size = pictureModel_.imageTexture.originalImage.size;
  CGPoint corner1, corner2, corner3, corner4;
  corner1 = ((UIView *)cornerPoints_[0]).center;
  corner2 = ((UIView *)cornerPoints_[1]).center;
  corner3 = ((UIView *)cornerPoints_[2]).center;
  corner4 = ((UIView *)cornerPoints_[3]).center;
  
  GLKVector2 lerp1 = GLKVector2Lerp(GLKVector2Make(0, 0), GLKVector2Make(corner1.x, corner1.y), amount);
  GLKVector2 lerp2 = GLKVector2Lerp(GLKVector2Make(size.width, 0), GLKVector2Make(corner2.x, corner2.y), amount);
  GLKVector2 lerp3 = GLKVector2Lerp(GLKVector2Make(0, size.height), GLKVector2Make(corner3.x, corner3.y), amount);
  GLKVector2 lerp4 = GLKVector2Lerp(GLKVector2Make(size.width, size.height), GLKVector2Make(corner4.x, corner4.y), amount);
  
  corner1 = CGPointMake(lerp1.x, lerp1.y);
  corner2 = CGPointMake(lerp2.x, lerp2.y);
  corner3 = CGPointMake(lerp3.x, lerp3.y);
  corner4 = CGPointMake(lerp4.x, lerp4.y);
  
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, self.view.bounds.size.width, self.view.bounds.size.height, 0, 1, -1);
  
  GLKMatrix4 transHomography = TransHomographicMatrix(pictureModel_.imageTexture.originalImage.size.width, pictureModel_.imageTexture.originalImage.size.height, corner1, corner2, corner3, corner4);
  int viewport[] = {0, 0, self.view.bounds.size.width, self.view.bounds.size.height};
  
  GLKVector3 topLeft = GLKMathProject(GLKVector3Make(0, 0, 0), transHomography, projection, viewport);
  topLeft.y -= self.view.bounds.size.height;
  topLeft.y *= -1;
  
  GLKVector3 topRight = GLKMathProject(GLKVector3Make(pictureModel_.imageTexture.originalImage.size.width, 0, 0), transHomography, projection, viewport);
  topRight.y -= self.view.bounds.size.height;
  topRight.y *= -1;
  
  GLKVector3 bottomLeft = GLKMathProject(GLKVector3Make(0, pictureModel_.imageTexture.originalImage.size.height, 0), transHomography, projection, viewport);
  bottomLeft.y -= self.view.bounds.size.height;
  bottomLeft.y *= -1;
  
  GLKVector3 bottomRight = GLKMathProject(GLKVector3Make(pictureModel_.imageTexture.originalImage.size.width, pictureModel_.imageTexture.originalImage.size.height, 0), transHomography, projection, viewport);
  bottomRight.y -= self.view.bounds.size.height;
  bottomRight.y *= -1;
  
  CGRect boundingBox = BoundingBoxForPoints(CGPointMake(topLeft.x, topLeft.y), CGPointMake(topRight.x, topRight.y), CGPointMake(bottomLeft.x, bottomLeft.y), CGPointMake(bottomRight.x, bottomRight.y));
  
  
  CGFloat quadAspect = ComputeAspectFromPoints(corner1, corner4, corner2, corner3, pictureModel_.imageTexture.originalImage.size.width, pictureModel_.imageTexture.originalImage.size.height);//, GLKMatrix3Make(homographic.m00, homographic.m01, homographic.m02, homographic.m10, homographic.m11, homographic.m12, homographic.m20, homographic.m21, homographic.m22));;
  if (_currentState == BWPhotoStateLines) {
    quadAspect = (((corner4.x + corner2.x) / 2) - ((corner3.x + corner1.x) / 2)) / (corner4.y - corner2.y);
  }
  
  CGFloat projectedAdjustedWidth = quadAspect * pictureModel_.imageTexture.originalImage.size.height;
  
  CGFloat aspectScale = projectedAdjustedWidth / pictureModel_.imageTexture.originalImage.size.width;
  
  return GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4MakeScale(aspectScale, 1, 1), -(boundingBox.origin.x * 1), -boundingBox.origin.y, 0), transHomography);
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


#pragma mark - GLKView Methods

- (void)setupGL {
  [EAGLContext setCurrentContext:self.context];

  glEnable(GL_TEXTURE_2D);
  
  glEnable(GL_BLEND);
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
// DELETE ME
//  glShadeModel (GL_SMOOTH);
  
  BWShader *pictureShader = [[BWShader alloc] initWithShaderNamed:@"Shader"];
  BWShader *gridShader = [[BWShader alloc] initWithShaderNamed:@"gridShader"];
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
  
  overLayModel_ = [[BWModel alloc] init];
  overLayModel_.shader = gridShader;
  overLayModel_.mesh = lineMesh;

}

- (void)update {
  if ((needsUpdate_ || animatingTransform_) && !pauseUpdate_) {
    drawUpdate_ = YES;
    needsUpdate_ = NO;
    
    // Update transform for scrollview
    CALayer *zoomedLayer = placeholderView_.layer.presentationLayer;
    CGFloat viewportZoomScale = zoomedLayer.transform.m11;
    
    CALayer *presentationLayer = scroller_.layer.presentationLayer;
    CGPoint contentOffset = presentationLayer.bounds.origin;
    
    GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, self.view.bounds.size.width, self.view.bounds.size.height, 0, 1, -1);
    GLKMatrix4 projectionXform = GLKMatrix4Scale(GLKMatrix4MakeTranslation(-contentOffset.x, -contentOffset.y, 0), viewportZoomScale, viewportZoomScale, 1);
    // Update Models
    loupeModel_.projection = projection;
    
    pictureModel_.projection = projection;
    pictureModel_.projectionTransform = projectionXform;
    pictureModel_.transform = GLKMatrix4Identity;
    
    overLayModel_.projection = projection;
    overLayModel_.projectionTransform = projectionXform;
    
    if (_transformValid) {
      if (_transformApplied) {
        if (animatingTransform_) {
          if (transformAmount_ >= 1) {
            transformAmount_ = 1;
            animatingTransform_ = NO;
          }
          pictureModel_.transform = [self adjustedTranshomographyLerpAmount:transformAmount_];
          GLKVector3 lerpedProjection = GLKVector3Lerp(transformStartOffsetAndZoom_, GLKVector3Make(-contentOffset.x, -contentOffset.y, viewportZoomScale), transformAmount_);
          pictureModel_.projectionTransform = GLKMatrix4Scale(GLKMatrix4MakeTranslation(lerpedProjection.x, lerpedProjection.y, 0), lerpedProjection.z, lerpedProjection.z, 1);
          transformAmount_ += self.timeSinceLastUpdate / 0.1;
        } else {
          pictureModel_.transform = appliedTransform_;
        }
      } else {
        CGPoint corner1, corner2, corner3, corner4;
        corner1 = ((UIView *)cornerPoints_[0]).center;
        corner2 = ((UIView *)cornerPoints_[1]).center;
        corner3 = ((UIView *)cornerPoints_[2]).center;
        corner4 = ((UIView *)cornerPoints_[3]).center;
        GLKMatrix4 homographic = HomographicMatrix(placeholderView_.bounds.size.width,
                                                   placeholderView_.bounds.size.height,
                                                   corner1, corner2, corner3, corner4);
        
        overLayModel_.transform = homographic;
      }
    }
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
  
  if (_transformValid && (_currentState != BWPhotoStateNone) && !_transformApplied) {
    [overLayModel_ use];
    GLKVector4 diffuseColor = GLKVector4Make(1, 1, 1, 0.6);
    [overLayModel_.shader setUniform:@"diffuseColor" withValue:&diffuseColor];
    int drawX = 1;
    [overLayModel_.shader setUniform:@"drawY" withValue:&drawX];
    if (_currentState == BWPhotoStateLines) {
      drawX = 0;
    }
    [overLayModel_.shader setUniform:@"drawX" withValue:&drawX];
    [overLayModel_ draw];
  }

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
