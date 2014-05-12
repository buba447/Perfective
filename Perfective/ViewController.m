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

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate> {

  UIView *topLeft_;
  UIView *topRight_;
  UIView *bottomLeft_;
  UIView *bottomrRight_;
  BOOL needsUpdate_;
  CGPoint topLeftPosition;
  CGPoint bottomLeftPosition;
  CGPoint bottomRightPosition;
  CGPoint topRightPosition;
  CGSize scaledImageSize;
  
  BWModel *loupeModel_;
  BWModel *pictureModel_;
  BWModel *xformedPictureModel_;
  BWModel *overLayModel_;
  
  BOOL drawOverlay_;
  BOOL drawLoupe_;
  GLuint _texture;
  BOOL textureLoaded_;
  BOOL pauseUpdate_;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation ViewController

- (void)updateOverlay {
  drawOverlay_ = !drawOverlay_;
}

- (void)viewDidLoad {
  drawOverlay_ = YES;
  drawLoupe_ = NO;
  [super viewDidLoad];
  textureLoaded_ = NO;
  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];


  scaledImageSize.width = self.view.bounds.size.width;
  scaledImageSize.height = self.view.bounds.size.height * 0.5;

  pauseUpdate_ = NO;
  needsUpdate_ = YES;
  
  topLeft_ = [self setupCornerView];
  topLeft_.center = CGPointMake(44, 44);
  topRight_ = [self setupCornerView];
  topRight_.center = CGPointMake(self.view.bounds.size.width - 44, 44);
  bottomLeft_ = [self setupCornerView];
  bottomLeft_.center = CGPointMake(44, (self.view.bounds.size.height * 0.5) - 44);
  bottomrRight_ = [self setupCornerView];
  bottomrRight_.center = CGPointMake(self.view.bounds.size.width - 44, (self.view.bounds.size.height * 0.5) - 44);

  if (!self.context) {
      NSLog(@"Failed to create ES context");
  }
  
  GLKView *view = (GLKView *)self.view;
  view.context = self.context;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  
  UIButton *update = [UIButton buttonWithType:UIButtonTypeCustom];
  [update setTitle:@"Update" forState:UIControlStateNormal];
  [update addTarget:self action:@selector(updateOverlay) forControlEvents:UIControlEventTouchUpInside];
  update.frame = CGRectMake(0, self.view.bounds.size.height - 44, 70, 44);
  [self.view addSubview:update];
  
  UIButton *picImage = [UIButton buttonWithType:UIButtonTypeCustom];
  [picImage setTitle:@"Pick" forState:UIControlStateNormal];
  [picImage addTarget:self action:@selector(pickImage) forControlEvents:UIControlEventTouchUpInside];
  picImage.frame = CGRectMake(self.view.bounds.size.width - 70, self.view.bounds.size.height - 44, 70, 44);
  [self.view addSubview:picImage];
  
  [self setupGL];
  
  GLint maxRenderbufferSize;
  glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &maxRenderbufferSize);
  NSLog(@"");
}

- (void)pickImage {
  pauseUpdate_ = YES;
  UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
  imagePicker.delegate = self;
  [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  topLeft_.center = CGPointMake(44, 44);
  topRight_.center = CGPointMake(self.view.bounds.size.width - 44, 44);
  bottomLeft_.center = CGPointMake(44, (self.view.bounds.size.height * 0.5) - 44);
  bottomrRight_.center = CGPointMake(self.view.bounds.size.width - 44, (self.view.bounds.size.height * 0.5) - 44);
  UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
  [self loadTextureImage:image];
  pauseUpdate_ = NO;
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  pauseUpdate_ = NO;
  [self dismissViewControllerAnimated:YES completion:nil];
}


- (UIView *)setupCornerView {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
  view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handPan:)];
  [view addGestureRecognizer:pan];
  [self.view addSubview:view];
  return view;
}

- (void)handPan:(UIPanGestureRecognizer *)panGesture {
  panGesture.view.center = [panGesture locationInView:self.view];
  [self computeLoupeDateFromPoint:panGesture.view.center];
  drawLoupe_ = YES;
  needsUpdate_ = YES;
  if (panGesture.state == UIGestureRecognizerStateEnded) {
    drawLoupe_ = NO;
  }
}

- (void)setupGL {
  
  [EAGLContext setCurrentContext:self.context];

  [self loadTextureImage:[UIImage imageNamed:@"barn2.jpg"]];
//  glEnable(GL_DEPTH_TEST);
  glEnable(GL_TEXTURE_2D);
  
  
  glEnable(GL_BLEND);
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glShadeModel (GL_SMOOTH);
  
  BWShader *pictureShader = [[BWShader alloc] initWithShaderNamed:@"Shader"];
  
  BWShader *loupeShader = [[BWShader alloc] initWithShaderNamed:@"circleShader"];
  
  BWMesh *loupeMesh = [[BWMesh alloc] initWithNumberOfVertices:4];
  BWMesh *pictureMesh = [[BWMesh alloc] initWithNumberOfVertices:4];
  [self computeDataForSquare:pictureMesh withTopLeft:CGPointMake(0, 0) topRight:CGPointMake(scaledImageSize.width, 0) bottomLeft:CGPointMake(0, scaledImageSize.height) bottomRight:CGPointMake(scaledImageSize.width, scaledImageSize.height)];

  loupeModel_ = [[BWModel alloc] init];
  loupeModel_.shader = loupeShader;
  loupeModel_.mesh = loupeMesh;
  
  pictureModel_ = [[BWModel alloc] init];
  pictureModel_.shader = pictureShader;
  pictureModel_.mesh = pictureMesh;
  
  overLayModel_ = [[BWModel alloc] init];
  overLayModel_.shader = pictureShader;
  overLayModel_.mesh = pictureMesh;
  xformedPictureModel_ = [[BWModel alloc] init];
  xformedPictureModel_.shader = pictureShader;
  xformedPictureModel_.mesh = pictureMesh;
  
}

- (void)computeLoupeDateFromPoint:(CGPoint)point {
  
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

  
  CGPoint centerOfSample = point;
  CGPoint uvSampleCenter = CGPointMake(centerOfSample.x / scaledImageSize.width, centerOfSample.y / scaledImageSize.height);
  CGFloat uvOffsetSize = ((loupeSize / scaledImageSize.width) / zoomScale) * 0.5;

  
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

- (void)computeDataForSquare:(BWMesh *)mesh
                 withTopLeft:(CGPoint)topLeft
                    topRight:(CGPoint)topRight
                  bottomLeft:(CGPoint)bottomLeft
                 bottomRight:(CGPoint)bottomRight{

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

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  needsUpdate_ = YES;
}

- (void)loadTextureImage:(UIImage *)image {
  if (textureLoaded_) {
    textureLoaded_ = NO;
    glBindTexture(GL_TEXTURE_2D, 0);
    glDeleteTextures(1, &_texture);
  }
  
  GLuint returnTexture;
  
  GLuint width = scaledImageSize.width * 2;
  GLuint height = scaledImageSize.height * 2;
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
  CGFloat boundAspect = (float)width / (float)height;
  // 4w 2t = 2a
  CGFloat imageAspect = image.size.width / image.size.height;
  // 3w 2t = 1.5  -- change width by height factor
  // 6w 2t = 3 -- change height by width factor
  if (imageAspect < boundAspect) {
    imageDrawRect.size.width = (height / image.size.height) * image.size.width;
    imageDrawRect.origin.x = (width - imageDrawRect.size.width) * 0.5;
  } else if (imageAspect > boundAspect) {
    imageDrawRect.size.height = (width / image.size.width) * image.size.height;
    imageDrawRect.origin.y = (height - imageDrawRect.size.height) * 0.5;
  }

  [image drawInRect:imageDrawRect];
  

  glGenTextures(1, &returnTexture);
  glBindTexture(GL_TEXTURE_2D, returnTexture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height,
               0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	glBindTexture(GL_TEXTURE_2D, 0);
  
  free(imageData);
  CGContextRelease(imgcontext);
  
  _texture = returnTexture;
  textureLoaded_ = YES;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update {
  if (needsUpdate_) {
    GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, self.view.bounds.size.width, self.view.bounds.size.height, 0, 1, -1);
    pictureModel_.projection = projection;
    pictureModel_.transform = GLKMatrix4Identity;
    
    overLayModel_.projection = projection;
    overLayModel_.transform = HomographicMatrix(scaledImageSize.width, scaledImageSize.height, topLeft_.center, topRight_.center, bottomLeft_.center, bottomrRight_.center);
    
    GLKMatrix4 transHomography = TransHomographicMatrix(scaledImageSize.width, scaledImageSize.height, topLeft_.center, topRight_.center, bottomLeft_.center, bottomrRight_.center);
    
    int viewport[] = {0, 0, self.view.bounds.size.width, self.view.bounds.size.height};
    
    GLKVector3 topLeft = GLKMathProject(GLKVector3Make(0, 0, 0), transHomography, projection, viewport);
    topLeft.y = self.view.bounds.size.height - topLeft.y;
    
    GLKVector3 topRight = GLKMathProject(GLKVector3Make(scaledImageSize.width, 0, 0), transHomography, projection, viewport);
    topRight.y = self.view.bounds.size.height - topRight.y;
    
    GLKVector3 bottomLeft = GLKMathProject(GLKVector3Make(0, scaledImageSize.height, 0), transHomography, projection, viewport);
    bottomLeft.y = self.view.bounds.size.height - bottomLeft.y;
    
    GLKVector3 bottomRight = GLKMathProject(GLKVector3Make(scaledImageSize.width, scaledImageSize.height, 0), transHomography, projection, viewport);
    bottomRight.y = self.view.bounds.size.height - bottomRight.y;
    
    CGFloat leftEdge = (topLeft.x + bottomLeft.x) / 2;
    CGFloat rightEdge = (topRight.x + bottomRight.x) / 2;
    topLeft.x = bottomLeft.x = leftEdge;
    topRight.x = bottomRight.x = rightEdge;
    
    CGRect boundingBox = BoundingBoxForPoints(CGPointMake(topLeft.x, topLeft.y), CGPointMake(topRight.x, topRight.y), CGPointMake(bottomLeft.x, bottomLeft.y), CGPointMake(bottomRight.x, bottomRight.y));
    
    //figure out scale
    CGFloat scalex = scaledImageSize.width / boundingBox.size.width;
    CGFloat scaley = scaledImageSize.height / boundingBox.size.height;
    
    CGPoint offset = CGPointMake(- boundingBox.origin.x,
                                 - boundingBox.origin.y);
    
    GLKMatrix4 projection2 = GLKMatrix4MakeOrtho(0, self.view.bounds.size.width, self.view.bounds.size.height * 0.5, -self.view.bounds.size.height * 0.5, 1, -1);
    GLKMatrix4 adjustedProjection = GLKMatrix4Translate(GLKMatrix4Scale(projection2, scalex, scaley, 1), offset.x, offset.y, 0);
    xformedPictureModel_.projection = adjustedProjection;
    xformedPictureModel_.transform = transHomography;
    loupeModel_.projection = projection;
    needsUpdate_ = NO;
  }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  if (pauseUpdate_) {
    return;
  }  

  glClearColor(0.f, 0.f, 0.f, 0.f);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  
  if (textureLoaded_) {
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  }
  [pictureModel_ use];
  [pictureModel_.shader setUniform:@"hasTexture" withInt:textureLoaded_];
  [pictureModel_ draw];
  
  [overLayModel_ use];
  [overLayModel_.shader setUniform:@"hasTexture" withInt:0];
  [overLayModel_ draw];
  
  
  if (drawOverlay_ && textureLoaded_) {
    [xformedPictureModel_ use];
    [xformedPictureModel_.shader setUniform:@"hasTexture" withInt:1];
    [xformedPictureModel_ draw];
  }
  
  if (drawLoupe_ && textureLoaded_) {
    [loupeModel_ use];
    [loupeModel_.shader setUniform:@"hasTexture" withInt:1];
    [loupeModel_.shader setUniform:@"circleRadius" withFloat:0.04];
    [loupeModel_.shader setUniform:@"diffuseColor" withVector4f:GLKVector4Make(0.7, 0.4, 0.0, 0.4)];
    [loupeModel_ draw];
  }
  
  glBindTexture(GL_TEXTURE_2D, 0);
  glBindVertexArrayOES(0);
  glUseProgram(0);
}

- (void)dealloc
{
  [self tearDownGL];
  
  if ([EAGLContext currentContext] == self.context) {
    [EAGLContext setCurrentContext:nil];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  
  if ([self isViewLoaded] && ([[self view] window] == nil)) {
    self.view = nil;
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
      [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
  }
  
  // Dispose of any resources that can be recreated.
}

- (void)tearDownGL {
  [EAGLContext setCurrentContext:self.context];
}

@end
