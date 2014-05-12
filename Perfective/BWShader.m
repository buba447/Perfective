//
//  BWShaderObject.m
//  TestGame
//
//  Created by Brandon Withrow on 6/12/13.
//  Copyright (c) 2013 Brandon Withrow. All rights reserved.
//

#import "BWShader.h"

//@implementation BWShaderUniform
//
//@end

@implementation BWShader {
  GLuint programID_;
  NSDictionary *uniformLocations_;
}

- (id)initWithShaderNamed:(NSString *)shaderName {
  self = [super init];
  if (self) {
    _shaderName = shaderName;
    [self loadShaderNamed:shaderName];
  }
  return self;
}

- (void)use {
  glUseProgram(programID_);
}

- (BOOL)loadShaderNamed:(NSString *)name {
  GLuint vertShader, fragShader;
  NSString *vertShaderPathname, *fragShaderPathname;
  programID_ = glCreateProgram();
  
  // Create and compile vertex shader.
  vertShaderPathname = [[NSBundle mainBundle] pathForResource:name ofType:@"vsh"];
  if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
    NSLog(@"Failed to compile vertex shader");
    return NO;
  }
  
  // Create and compile fragment shader.
  fragShaderPathname = [[NSBundle mainBundle] pathForResource:name ofType:@"fsh"];
  if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
    NSLog(@"Failed to compile fragment shader");
    return NO;
  }
  
  // Attach vertex shader to program.
  glAttachShader(programID_, vertShader);
  
  // Attach fragment shader to program.
  glAttachShader(programID_, fragShader);
  
  // Bind attribute locations.
  // This needs to be done prior to linking.

  glBindAttribLocation(programID_, GLKVertexAttribPosition, [@"position" UTF8String]);
  glBindAttribLocation(programID_, GLKVertexAttribTexCoord0, [@"texture" UTF8String]);
  glBindAttribLocation(programID_, GLKVertexAttribTexCoord1, [@"texture_b" UTF8String]);
  
  // Link program.
  if (![self linkProgram:programID_]) {
    NSLog(@"Failed to link program: %d", programID_);
    
    if (vertShader) {
      glDeleteShader(vertShader);
      vertShader = 0;
    }
    if (fragShader) {
      glDeleteShader(fragShader);
      fragShader = 0;
    }
    if (programID_) {
      glDeleteProgram(programID_);
      programID_ = 0;
    }
    
    return NO;
  }
  // Get uniformcount
  GLint uniformCount;
  glGetProgramiv(programID_, GL_ACTIVE_UNIFORMS, &uniformCount);
  
  //get uniform info and create objects
  NSMutableDictionary *uniforms = [NSMutableDictionary dictionary];
  for (int i = 0; i < uniformCount; i++) {
    int name_len=-1, num=-1;
    GLenum type = GL_ZERO;
    char uniformName[100];
    
    glGetActiveUniform(programID_, i, sizeof(uniformName)-1, &name_len, &num, &type, uniformName );
    
    uniformName[name_len] = 0;
    
    GLuint uniformLocation = glGetUniformLocation(programID_, uniformName);
    
    [uniforms setObject:@(uniformLocation) forKey:[NSString stringWithUTF8String:uniformName]];
  }
  uniformLocations_ = uniforms;
  if (vertShader) {
    glDetachShader(programID_, vertShader);
    glDeleteShader(vertShader);
  }
  if (fragShader) {
    glDetachShader(programID_, fragShader);
    glDeleteShader(fragShader);
  }
  return YES;
}

- (NSArray*)uniformNames {
  return uniformLocations_.allKeys;
}

- (void)setUniform:(NSString *)uniform withVector2f:(GLKVector2)vector {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniform2f(location, vector.x, vector.y);
}

- (void)setUniform:(NSString *)uniform withVector3f:(GLKVector3)vector {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniform3f(location, vector.x, vector.y, vector.z);
}

- (void)setUniform:(NSString *)uniform withVector4f:(GLKVector4)vector {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniform4f(location, vector.x, vector.y, vector.z, vector.w);
}

- (void)setUniform:(NSString *)uniform withVector2i:(GLKVector2)vector {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniform2i(location, (GLint)vector.x, (GLint)vector.y);
}

- (void)setUniform:(NSString *)uniform withVector3i:(GLKVector3)vector {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniform3i(location, (GLint)vector.x, (GLint)vector.y, (GLint)vector.z);
}

- (void)setUniform:(NSString *)uniform withVector4i:(GLKVector4)vector {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniform4i(location, (GLint)vector.x, (GLint)vector.y, (GLint)vector.z, (GLint)vector.w);
}

- (void)setUniform:(NSString *)uniform withMatrix2:(GLKMatrix2)matrix {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniformMatrix2fv(location, 1, 0, matrix.m);
}

- (void)setUniform:(NSString *)uniform withMatrix3:(GLKMatrix3)matrix {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniformMatrix3fv(location, 1, 0, matrix.m);
}

- (void)setUniform:(NSString *)uniform withMatrix4:(GLKMatrix4)matrix {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniformMatrix4fv(location, 1, 0, matrix.m);
}

- (void)setUniform:(NSString *)uniform withFloat:(GLfloat)floatValue {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniform1f(location, floatValue);
}

- (void)setUniform:(NSString *)uniform withInt:(GLint)intValue {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniform1i(location, intValue);
}

- (void)setUniform:(NSString *)uniform withBool:(BOOL)boolValue {
  GLint location = (GLint)[[uniformLocations_ objectForKey:uniform] integerValue];
  glUniform1i(location, (GLint)boolValue);
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
  GLint status;
  const GLchar *source;
  
  source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
  if (!source) {
    NSLog(@"Failed to load vertex shader");
    return NO;
  }
  
  *shader = glCreateShader(type);
  glShaderSource(*shader, 1, &source, NULL);
  glCompileShader(*shader);
  
#if defined(DEBUG)
  GLint logLength;
  glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0) {
    GLchar *log = (GLchar *)malloc(logLength);
    glGetShaderInfoLog(*shader, logLength, &logLength, log);
    NSLog(@"Shader compile log:\n%s", log);
    free(log);
  }
#endif
  
  glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
  if (status == 0) {
    glDeleteShader(*shader);
    return NO;
  }
  
  return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
  GLint status;
  glLinkProgram(prog);
  
#if defined(DEBUG)
  GLint logLength;
  glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0) {
    GLchar *log = (GLchar *)malloc(logLength);
    glGetProgramInfoLog(prog, logLength, &logLength, log);
    NSLog(@"Program link log:\n%s", log);
    free(log);
  }
#endif
  
  glGetProgramiv(prog, GL_LINK_STATUS, &status);
  if (status == 0) {
    return NO;
  }
  
  return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
  GLint logLength, status;
  
  glValidateProgram(prog);
  glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0) {
    GLchar *log = (GLchar *)malloc(logLength);
    glGetProgramInfoLog(prog, logLength, &logLength, log);
    NSLog(@"Program validate log:\n%s", log);
    free(log);
  }
  
  glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
  if (status == 0) {
    return NO;
  }
  
  return YES;
}

- (void)dealloc {
  glDeleteProgram(programID_);
}

@end
