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


#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate> {
  GLuint _program;
  NSMutableArray *debugGeometry_;
  NSMutableDictionary *shaders_;
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
  BOOL drawOverlay_;
  BOOL drawLoupe_;
  GLuint _texture;
  BOOL textureLoaded_;
  BOOL pauseUpdate_;
  UIScrollView *hackScroller_;
  UIView *zoomView_;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation ViewController

- (void)updateOverlay {
  drawOverlay_ = !drawOverlay_;
}

- (void)viewDidLoad {
  drawOverlay_ = YES;
  drawLoupe_ = NO;
  [super viewDidLoad];
  shaders_ = [[NSMutableDictionary alloc] init];
  debugGeometry_ = [NSMutableArray array];
  textureLoaded_ = NO;
  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];


  scaledImageSize.width = self.view.bounds.size.width;
  scaledImageSize.height = self.view.bounds.size.height * 0.5;

  pauseUpdate_ = NO;
  
  needsUpdate_ = YES;
  hackScroller_ = [[UIScrollView alloc] initWithFrame:self.view.bounds];
  hackScroller_.maximumZoomScale = 2;
  hackScroller_.alwaysBounceHorizontal = YES;
  hackScroller_.alwaysBounceVertical = YES;
  hackScroller_.scrollEnabled = NO;
  hackScroller_.contentSize = self.view.bounds.size;
  hackScroller_.delegate = self;
  [self.view addSubview:hackScroller_];
  zoomView_ = [[UIView alloc] initWithFrame:self.view.bounds];
  [hackScroller_ addSubview:zoomView_];
  
  UITapGestureRecognizer *tappy = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
  tappy.numberOfTapsRequired = 2;
  [zoomView_ addGestureRecognizer:tappy];
  
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

- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
  CGFloat zoomScale;
  if (hackScroller_.zoomScale > 1) {
    zoomScale = 1;
  } else {
    zoomScale = hackScroller_.maximumZoomScale;
  }
  [hackScroller_ setZoomScale:zoomScale animated:YES];
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return [scrollView.subviews objectAtIndex:0];
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
  [zoomView_ addSubview:view];
  return view;
}

- (void)handPan:(UIPanGestureRecognizer *)panGesture {
  panGesture.view.center = [panGesture locationInView:self.view];
  [self computeLoupeDateFromPoint:panGesture.view.center];
  drawLoupe_ = YES;
  if (panGesture.state == UIGestureRecognizerStateEnded) {
    drawLoupe_ = NO;
  }
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

- (void)setupGL {
  
  [EAGLContext setCurrentContext:self.context];

  BWShader *shader = [[BWShader alloc] initWithShaderNamed:@"Shader"];
  [shaders_ setObject:shader forKey:@"Shader"];
  
  BWShader *shader2 = [[BWShader alloc] initWithShaderNamed:@"circleShader"];
  [shaders_ setObject:shader2 forKey:@"circleShader"];

  [self loadTextureImage:[UIImage imageNamed:@"barn2.jpg"]];
//  glEnable(GL_DEPTH_TEST);
  glEnable(GL_TEXTURE_2D);
  
  
  glEnable(GL_BLEND);
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glShadeModel (GL_SMOOTH);
  
  BWMesh *mesh = [[BWMesh alloc] initWithNumberOfVertices:4];
  BWMesh *mesh2 = [[BWMesh alloc] initWithNumberOfVertices:4];
  [debugGeometry_ addObject:mesh];
  [debugGeometry_ addObject:mesh2];
}

- (CGPoint)intersectionOfLineFrom:(CGPoint)p1 to:(CGPoint)p2 withLineFrom:(CGPoint)p3 to:(CGPoint)p4
{
  CGFloat d = (p2.x - p1.x)*(p4.y - p3.y) - (p2.y - p1.y)*(p4.x - p3.x);
  if (d == 0)
    return CGPointZero; // parallel lines
  CGFloat u = ((p3.x - p1.x)*(p4.y - p3.y) - (p3.y - p1.y)*(p4.x - p3.x))/d;
  CGFloat v = ((p3.x - p1.x)*(p2.y - p1.y) - (p3.y - p1.y)*(p2.x - p1.x))/d;
  if (u < 0.0 || u > 1.0)
    return CGPointZero; // intersection point not between p1 and p2
  if (v < 0.0 || v > 1.0)
    return CGPointZero; // intersection point not between p3 and p4
  CGPoint intersection;
  intersection.x = p1.x + u * (p2.x - p1.x);
  intersection.y = p1.y + u * (p2.y - p1.y);
  
  return intersection;
}

CGFloat DistanceBetweenTwoPoints(CGPoint point1,CGPoint point2) {
  CGFloat dx = point2.x - point1.x;
  CGFloat dy = point2.y - point1.y;
  return sqrt(dx*dx + dy*dy );
};

- (void)logBuffer:(CGFloat *)trap {
  NSMutableArray *values = [NSMutableArray array];
  for (int i = 0; i < 24; i ++) {
    [values addObject:@(trap[i])];
  }
  NSLog(@"\r\rTrap [ %@ ]", [values componentsJoinedByString:@", "]);
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
  BWMesh *loupe = debugGeometry_.firstObject;
  
  //              x  y   z    u   v   q    u   v   q
  //top left      0, 1,  2 -  3,  4,  5 -  6,  7,  8

  GLKMatrix3 first = GLKMatrix3Make(loupeCenter.x - (loupeSize * 0.5), loupeCenter.y - (loupeSize * 0.5), 0,
                                    uvSampleCenter.x - uvOffsetSize, uvSampleCenter.y - uvOffsetSize, 1.f,
                                    0, 0, 0);
  [loupe setVertexData:first atIndex:0];
  
  //              x  y   z    u   v   q    u   v   q
  //top right     9, 10, 11 - 12, 13, 14 - 15, 16, 17

  GLKMatrix3 second = GLKMatrix3Make(loupeCenter.x + (loupeSize * 0.5), loupeCenter.y - (loupeSize * 0.5), 0.f,
                                     uvSampleCenter.x + uvOffsetSize, uvSampleCenter.y - uvOffsetSize, 1.f,
                                     1.f, 0.f, 0.f);
  [loupe setVertexData:second atIndex:1];
  
  //              x   y   z    u   v   q    u   v   q
  //bottom left   18, 19, 20 - 21, 22, 23 - 24, 25, 26
  
  
  GLKMatrix3 third = GLKMatrix3Make(loupeCenter.x - (loupeSize * 0.5), loupeCenter.y + (loupeSize * 0.5), 0.f,
                                    uvSampleCenter.x - uvOffsetSize, uvSampleCenter.y + uvOffsetSize, 1.f,
                                    0.f, 1.f, 0.f);
  [loupe setVertexData:third atIndex:2];
  
  //              x   y   z    u   v   q    u   v   q
  //bottom right  27, 28, 29 - 30, 31, 32 - 33, 34, 35
  GLKMatrix3 fourth = GLKMatrix3Make(loupeCenter.x + (loupeSize * 0.5), loupeCenter.y + (loupeSize * 0.5), 0.f,
                                     uvSampleCenter.x + uvOffsetSize, uvSampleCenter.y + uvOffsetSize, 1.f,
                                     1.f, 1.f, 0.f);
  [loupe setVertexData:fourth atIndex:3];
}

- (void)computeDataForSquare:(BWMesh *)mesh
                 withTopLeft:(CGPoint)topLeft
                    topRight:(CGPoint)topRight
                  bottomLeft:(CGPoint)bottomLeft
                 bottomRight:(CGPoint)bottomRight{

  CGPoint p0, p1,p2, p3;
  p0 = bottomLeft; // bottom left
  p1 = bottomRight; // bottom right
  p2 = topRight; // top right
  p3 = topLeft; // top left
  CGPoint center = [self intersectionOfLineFrom:p0 to:p2 withLineFrom:p1 to:p3];
  
  CGFloat d0, d1, d2, d3;
  d0 = DistanceBetweenTwoPoints(p0, center);
  d1 = DistanceBetweenTwoPoints(p1, center);
  d2 = DistanceBetweenTwoPoints(p2, center);
  d3 = DistanceBetweenTwoPoints(p3, center);
  
  CGFloat w0, w1, w2, w3;
  w0 = (d0 + d2) / d2;
  w1 = (d1 + d3) / d3;
  w2 = (d2 + d0) / d0;
  w3 = (d3 + d1) / d1;
  
//  w0 = w1 = w2 = w3 = 1;
  
  [mesh setVertex:GLKVector3Make(p3.x, p3.y, 0.f) atIndex:0];
  [mesh setTexCoor0:GLKVector3Make(0.f, 0.f, w3) atIndex:0];
  
  [mesh setVertex:GLKVector3Make(p2.x, p2.y, 0.f) atIndex:1];
  [mesh setTexCoor0:GLKVector3Make(1.f * w2, 0.f, w2) atIndex:1];
  
  [mesh setVertex:GLKVector3Make(p0.x, p0.y, 0.f) atIndex:2];
  [mesh setTexCoor0:GLKVector3Make(0.f, 1.f * w0, w0) atIndex:2];
  
  [mesh setVertex:GLKVector3Make(p1.x, p1.y, 0.f) atIndex:3];
  [mesh setTexCoor0:GLKVector3Make(1.f * w1, 1.f * w1, w1) atIndex:3];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];

    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (CGRect)boundingBoxWithTopLeft:(CGPoint)topLeft
                        topRight:(CGPoint)topRight
                      bottomLeft:(CGPoint)bottomLeft
                     bottomRight:(CGPoint)bottomRight {
  CGRect boundingBox = CGRectZero;
  boundingBox.origin.x = topLeft.x < bottomLeft.x ? topLeft.x : bottomLeft.x;
  boundingBox.origin.y = topLeft.y < topRight.y ? topLeft.y : topRight.y;
  
  boundingBox.size.width  = topRight.x > bottomRight.x ? topRight.x : bottomRight.x;
  boundingBox.size.height  = bottomLeft.y > bottomRight.y ? bottomLeft.y : bottomRight.y;

  boundingBox.size.width -= boundingBox.origin.x;
  boundingBox.size.height -= boundingBox.origin.y;
  
  return boundingBox;
  
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  
  
  CGRect bountingBox = [self boundingBoxWithTopLeft:topLeft_.center topRight:topRight_.center bottomLeft:bottomLeft_.center bottomRight:bottomrRight_.center];
  CGPoint groupCenter = CGPointMake(CGRectGetMidX(bountingBox), CGRectGetMidY(bountingBox));

//  CGPoint offset = CGPointMake((self.view.bounds.size.width / 2) - groupCenter.x, (self.view.bounds.size.height / 2) - groupCenter.y);
  
//  topLeft_.center = CGPointMake(topLeft_.center.x + offset.x, topLeft_.center.y + offset.y);
//  bottomLeft_.center = CGPointMake(bottomLeft_.center.x + offset.x, bottomLeft_.center.y + offset.y);
//  topRight_.center = CGPointMake(topRight_.center.x + offset.x, topRight_.center.y + offset.y);
//  bottomrRight_.center = CGPointMake(bottomrRight_.center.x + offset.x, bottomrRight_.center.y + offset.y);
//  topLeftPosition = topLeft_.center;
//  topRightPosition = topRight_.center;
//  bottomLeftPosition = bottomLeft_.center;
//  bottomRightPosition = bottomrRight_.center;
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
//    [self computeDataForSquare:data_
//                   withTopLeft:topLeft_.center
//                      topRight:topRight_.center
//                    bottomLeft:bottomLeft_.center
//                   bottomRight:bottomrRight_.center];
    
    [self computeDataForSquare:debugGeometry_.lastObject withTopLeft:CGPointMake(0, 0) topRight:CGPointMake(scaledImageSize.width, 0) bottomLeft:CGPointMake(0, scaledImageSize.height) bottomRight:CGPointMake(scaledImageSize.width, scaledImageSize.height)];
    needsUpdate_ = NO;
  }
}

- (void)setNeedsGLKDisplay {
  [(GLKView *)self.view display];
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  if (pauseUpdate_) {
    return;
  }
  BWMesh *loupe = debugGeometry_.firstObject;
  BWMesh *square = debugGeometry_.lastObject;
  
  //Update Everything
  
  if (loupe.needsUpdate) {
    [loupe updateBuffer];
  }
  if (square.needsUpdate) {
    [square updateBuffer];
  }
  
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, self.view.bounds.size.width, self.view.bounds.size.height, 0, 1, -1);
  projection = GLKMatrix4Translate(GLKMatrix4Scale(projection, hackScroller_.zoomScale, hackScroller_.zoomScale, 1), (-hackScroller_.contentOffset.x / hackScroller_.zoomScale), (-hackScroller_.contentOffset.y / hackScroller_.zoomScale), 0);
  glClearColor(0.f, 0.f, 0.f, 0.f);
  
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  if (textureLoaded_) {
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  }
  
  
  BWShader *debugShader = [shaders_ objectForKey:@"Shader"];
  [square use];
  [debugShader use];
  [debugShader setUniformValue:@(textureLoaded_) forUniformNamed:@"hasTexture"];
  [debugShader setUniformValue:[NSValue valueWithGLKMatrix4:GLKMatrix4Multiply(projection, GLKMatrix4Identity)] forUniformNamed:@"modelViewProjectionMatrix"];
  glDrawArrays(GL_TRIANGLE_STRIP, 0, square.vertexCount);
  
  [debugShader setUniformValue:@(0) forUniformNamed:@"hasTexture"];
  [debugShader setUniformValue:[NSValue valueWithGLKMatrix4:GLKMatrix4Multiply(projection, [self homographicMatrix])] forUniformNamed:@"modelViewProjectionMatrix"];

  glLineWidth(4.f);
  glDrawArrays(GL_LINE_LOOP, 0, square.vertexCount);
  
  if (drawOverlay_ && textureLoaded_) {
    GLKMatrix4 transHomography = [self transHomographicMatrix];
    
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
    
    CGRect boundingBox = [self boundingBoxWithTopLeft:CGPointMake(topLeft.x, topLeft.y)
                                             topRight:CGPointMake(topRight.x, topRight.y)
                                           bottomLeft:CGPointMake(bottomLeft.x, bottomLeft.y)
                                          bottomRight:CGPointMake(bottomRight.x, bottomRight.y)];
    
    //figure out scale
    CGFloat scalex = scaledImageSize.width / boundingBox.size.width;
    CGFloat scaley = scaledImageSize.height / boundingBox.size.height;
    
    CGPoint offset = CGPointMake(- boundingBox.origin.x,
                                 - boundingBox.origin.y);
    
    GLKMatrix4 projection2 = GLKMatrix4MakeOrtho(0, self.view.bounds.size.width, self.view.bounds.size.height * 0.5, -self.view.bounds.size.height * 0.5, 1, -1);
    GLKMatrix4 adjustedProjection = GLKMatrix4Translate(GLKMatrix4Scale(projection2, scalex, scaley, 1), offset.x, offset.y, 0);
    [debugShader setUniformValue:@(1) forUniformNamed:@"hasTexture"];
    [debugShader setUniformValue:[NSValue valueWithGLKMatrix4:GLKMatrix4Multiply(adjustedProjection, transHomography)] forUniformNamed:@"modelViewProjectionMatrix"];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, square.vertexCount);
  }
  glBindVertexArrayOES(0);
  
  if (drawLoupe_ && textureLoaded_) {
    BWShader *circleShader = [shaders_ objectForKey:@"circleShader"];
    [circleShader use];
    [loupe use];
    [circleShader setUniformValue:@(1) forUniformNamed:@"hasTexture"];
    [circleShader setUniformValue:[NSValue valueWithGLKMatrix4:projection] forUniformNamed:@"modelViewProjectionMatrix"];
    [circleShader setUniformValue:@(0.04) forUniformNamed:@"circleRadius"];
    [circleShader setUniformValue:[NSValue valueWithGLKVector4:GLKVector4Make(0.7, 0.4, 0.0, 0.4)] forUniformNamed:@"diffuseColor"];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, loupe.vertexCount);
  }
  
  glBindTexture(GL_TEXTURE_2D, 0);
  glBindVertexArrayOES(0);
  glUseProgram(0);
  
  

}

- (void)updateOffsetPoints {
  CGPoint p1 = topLeft_.center;
  CGPoint p2 = topRight_.center;
  CGPoint p3 = bottomLeft_.center;
  CGPoint p4 = bottomrRight_.center;
  
  CGFloat topEdge, bottomEdge, leftEdge, rightEdge;
  
  leftEdge = p1.x + ((p3.x - p1.x) * 0.5);
  rightEdge = p2.x + ((p4.x - p2.x) * 0.5);
  
  topEdge = p1.y + ((p2.y - p1.y) * 0.5);
  bottomEdge = p3.y + ((p4.y - p3.y) * 0.5);
  
  p1.y = p1.y - topEdge;
  p1.x = p1.x - leftEdge;
  
  p2.y = p2.y - topEdge;
  p2.x = p2.x - rightEdge;
  
  p3.y = p3.y - bottomEdge;
  p3.x = p3.x - leftEdge;
  
  p4.y = p4.y - bottomEdge;
  p4.x = p4.x - leftEdge;
  
  
//  CGPoint p2Offset = CGPointMake(p2.x - p1.x, p2.y - p1.y);
//  CGPoint p3Offset = CGPointMake(p2.x - p1.x, p2.y - p1.y);
//  CGPoint p4Offset = CGPointMake(p2.x - p1.x, p2.y - p1.y);
}

- (GLKMatrix4)adjustedHomographicMatrix {
  CGPoint p1 = topLeft_.center;
  CGPoint p2 = topRight_.center;
  CGPoint p3 = bottomLeft_.center;
  CGPoint p4 = bottomrRight_.center;
  CGFloat w = scaledImageSize.width;
  CGFloat h = scaledImageSize.height;
  
  CGFloat topEdge, bottomEdge, leftEdge, rightEdge;
  
  leftEdge = p1.x + ((p3.x - p1.x) * 0.5);
  rightEdge = p2.x + ((p4.x - p2.x) * 0.5);
  
  topEdge = p1.y + ((p2.y - p1.y) * 0.5);
  bottomEdge = p3.y + ((p4.y - p3.y) * 0.5);
  
  p1.y = p1.y - topEdge;
  p1.x = p1.x - leftEdge;
  
  p2.y = p2.y - topEdge;
  p2.x = w + (p2.x - rightEdge);
  
  p3.y = h + (p3.y - bottomEdge);
  p3.x = p3.x - leftEdge;
  
  p4.y = h + (p4.y - bottomEdge);
  p4.x = w + (p4.x - rightEdge);
  
  
  
  GLKMatrix3 t = general2dProjection(0, 0, p1.x, p1.y, w, 0, p2.x, p2.y, 0, h, p3.x, p3.y, w, h, p4.x, p4.y);
  
  for(int i = 0; i != 9; ++i) {
    t.m[i] = t.m[i]/t.m[8];
  }
  GLKMatrix4 r = GLKMatrix4Make(t.m[0], t.m[3], 0, t.m[6],
                                t.m[1], t.m[4], 0, t.m[7],
                                0, 0, 1, 0,
                                t.m[2], t.m[5], 0, t.m[8]);
  return r;
}

- (GLKMatrix4)transHomographicMatrix {
  CGPoint p1 = topLeft_.center;
  CGPoint p2 = topRight_.center;
  CGPoint p3 = bottomLeft_.center;
  CGPoint p4 = bottomrRight_.center;
  
  CGPoint p2Offset = CGPointMake(p2.x - p1.x, p2.y - p1.y);
  CGPoint p3Offset = CGPointMake(p2.x - p1.x, p2.y - p1.y);
  CGPoint p4Offset = CGPointMake(p2.x - p1.x, p2.y - p1.y);
  
//  p2.x -= p1.x;
//  p2.y -= p1.y;
//  p3.x -= p1.x;
//  p3.y -= p1.y;
//  p4.x -= p1.x;
//  p4.y -= p1.y;
//  p1 = CGPointZero;
  
//  CGFloat scale = self.view.bounds.size.width / p2.x;
//  scale *= 1.1;
//  p2.x *= scale;
//  p2.y *= scale;
//  p3.x *= scale;
//  p3.y *= scale;
//  p4.x *= scale;
//  p4.y *= scale;
  
  
  CGFloat w = scaledImageSize.width;
  CGFloat h = scaledImageSize.height;
  
  GLKMatrix3 t = general2dProjection(0, 0, p1.x, p1.y, w, 0, p2.x, p2.y, 0, h, p3.x, p3.y, w, h, p4.x, p4.y);
  
  for(int i = 0; i != 9; ++i) {
    t.m[i] = t.m[i]/t.m[8];
  }
  GLKMatrix4 r = GLKMatrix4Make(t.m[0], t.m[3], 0, t.m[6],
                                t.m[1], t.m[4], 0, t.m[7],
                                0, 0, 1, 0,
                                t.m[2], t.m[5], 0, t.m[8]);
  
  bool is;
  GLKMatrix4 invertR = GLKMatrix4Invert(r, &is);
  return invertR;
}

- (GLKMatrix4)homographicMatrix {
  CGPoint p1 = topLeft_.center;
  CGPoint p2 = topRight_.center;
  CGPoint p3 = bottomLeft_.center;
  CGPoint p4 = bottomrRight_.center;
  CGFloat w = scaledImageSize.width;
  CGFloat h = scaledImageSize.height;
  
  GLKMatrix3 t = general2dProjection(0, 0, p1.x, p1.y, w, 0, p2.x, p2.y, 0, h, p3.x, p3.y, w, h, p4.x, p4.y);
  
  for(int i = 0; i != 9; ++i) {
    t.m[i] = t.m[i]/t.m[8];
  }
  GLKMatrix4 r = GLKMatrix4Make(t.m[0], t.m[3], 0, t.m[6],
                                t.m[1], t.m[4], 0, t.m[7],
                                0, 0, 1, 0,
                                t.m[2], t.m[5], 0, t.m[8]);
  return r;
}


GLKMatrix3 general2dProjection(CGFloat x1s, CGFloat y1s, CGFloat x1d, CGFloat y1d,
                               CGFloat x2s, CGFloat y2s, CGFloat x2d, CGFloat y2d,
                               CGFloat x3s, CGFloat y3s, CGFloat x3d, CGFloat y3d,
                               CGFloat x4s, CGFloat y4s, CGFloat x4d, CGFloat y4d) {
  GLKMatrix3 s = basisToPoints(x1s, y1s, x2s, y2s, x3s, y3s, x4s, y4s);
  GLKMatrix3 d = basisToPoints(x1d, y1d, x2d, y2d, x3d, y3d, x4d, y4d);
  GLKMatrix3 sa = adj(s);
  return multmm(d, sa);
}

GLKMatrix3 adj(GLKMatrix3 m) { // Compute the adjugate of m
  
  GLKMatrix3 r;
  r.m[0] = m.m[4]*m.m[8]-m.m[5]*m.m[7];
  r.m[1] = m.m[2]*m.m[7]-m.m[1]*m.m[8];
  r.m[2] = m.m[1]*m.m[5]-m.m[2]*m.m[4];
  r.m[3] = m.m[5]*m.m[6]-m.m[3]*m.m[8];
  r.m[4] = m.m[0]*m.m[8]-m.m[2]*m.m[6];
  r.m[5] = m.m[2]*m.m[3]-m.m[0]*m.m[5];
  r.m[6] = m.m[3]*m.m[7]-m.m[4]*m.m[6];
  r.m[7] = m.m[1]*m.m[6]-m.m[0]*m.m[7];
  r.m[8] = m.m[0]*m.m[4]-m.m[1]*m.m[3];
  return r;
}

GLKVector3 multmv(GLKMatrix3 m, GLKVector3 v) { // multiply matrix and vector
  GLKVector3 r;
  r.v[0] = m.m[0]*v.v[0] + m.m[1]*v.v[1] + m.m[2]*v.v[2];
  r.v[1] = m.m[3]*v.v[0] + m.m[4]*v.v[1] + m.m[5]*v.v[2];
  r.v[2] = m.m[6]*v.v[0] + m.m[7]*v.v[1] + m.m[8]*v.v[2];
  return r;
}

GLKMatrix3 basisToPoints(x1, y1, x2, y2, x3, y3, x4, y4) {
  GLKMatrix3 m;
  m = GLKMatrix3Make(x1, x2, x3, y1, y2, y3, 1,  1,  1);
  GLKMatrix3 ma = adj(m);
  GLKVector3 v = multmv(ma, GLKVector3Make(x4, y4, 1));
  GLKMatrix3 mb = GLKMatrix3Make(v.v[0], 0, 0, 0, v.v[1], 0, 0, 0, v.v[2]);
  return multmm(m, mb);
}

GLKMatrix3 multmm(GLKMatrix3 a, GLKMatrix3 b) { // multiply two matrices
  GLKMatrix3 c;
  for (int i = 0; i != 3; ++i) {
    for (int j = 0; j != 3; ++j) {
      float cij = 0;
      for (int k = 0; k != 3; ++k) {
        cij += a.m[3*i + k]*b.m[3*k + j];
      }
      c.m[3*i + j] = cij;
    }
  }
  return c;
}

@end
