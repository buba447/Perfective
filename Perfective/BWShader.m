//
//  BWShaderObject.m
//  TestGame
//
//  Created by Brandon Withrow on 6/12/13.
//  Copyright (c) 2013 Brandon Withrow. All rights reserved.
//

#import "BWShader.h"

@implementation BWShaderUniform

@end

@implementation BWShader {
  GLuint programID_;
  NSDictionary *uniforms_;
  
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

- (NSDictionary *)generateUniforms {
  NSMutableDictionary *uniforms = [NSMutableDictionary dictionary];
  for (BWShaderUniform *uniform in uniforms_) {
    BWShaderUniform *newUniform = [[BWShaderUniform alloc] init];
    newUniform.name = uniform.name;
    newUniform.type = uniform.type;
    newUniform.location = uniform.location;
    [uniforms setObject:uniform forKey:uniform.name];
  }
  return uniforms;
}

- (void)loadUniforms:(NSMutableDictionary *)uniforms {
  for (BWShaderUniform *uniform in uniforms.allValues) {
    [self loadUniform:uniform];
  }
}

- (void)setUniformValue:(NSValue *)value forUniformNamed:(NSString *)uniform {
  BWShaderUniform *uObject = [uniforms_ objectForKey:uniform];
  uObject.value = value;
  [self loadUniform:uObject];
  uObject.value = nil;
}

- (void)loadUniform:(BWShaderUniform *)uniform {
  if (!uniform.value) {
    return;
  }
  switch (uniform.type) {
    case BWUniformTypeFloat: {
      glUniform1f(uniform.location, (GLfloat)[(NSNumber *)uniform.value floatValue]);
      break;
    }
    case BWUniformTypeFloatVec2: {
      GLKVector2 value = [uniform.value vector2Value];
      glUniform2f(uniform.location, value.x, value.y);
      break;
    }
    case BWUniformTypeFloatVec3: {
      GLKVector3 value = [uniform.value vector3Value];
      glUniform3f(uniform.location, value.x, value.y, value.z);
      break;
    }
    case BWUniformTypeFloatVec4: {
      GLKVector4 value = [uniform.value vector4Value];
      glUniform4f(uniform.location, value.x, value.y, value.z, value.w);
      break;
    }
    case BWUniformTypeBool:
    case BWUniformTypeInt: {
      glUniform1i(uniform.location, (GLint)[(NSNumber *)uniform.value integerValue]);
      break;
    }
    case BWUniformTypeBoolVec2:
    case BWUniformTypeIntVec2: {
      GLKVector2 value = [uniform.value vector2Value];
      glUniform2i(uniform.location, (GLint)value.x, (GLint)value.y);
      break;
    }
    case BWUniformTypeBoolVec3:
    case BWUniformTypeIntVec3: {
      GLKVector3 value = [uniform.value vector3Value];
      glUniform3i(uniform.location, (GLint)value.x, (GLint)value.y, (GLint)value.z);
      break;
    }
    case BWUniformTypeBoolVec4:
    case BWUniformTypeIntVec4: {
      GLKVector4 value = [uniform.value vector4Value];
      glUniform4i(uniform.location, (GLint)value.x, (GLint)value.y, (GLint)value.z, (GLint)value.w);
      break;
    }
    case BWUniformTypeFloatMatrix2: {
      GLKMatrix2 value = [uniform.value matrix2Value];
      glUniformMatrix2fv(uniform.location, 1, 0, value.m);
      break;
    }
    case BWUniformTypeFloatMatrix3: {
      GLKMatrix3 value = [uniform.value matrix3Value];
      glUniformMatrix3fv(uniform.location, 1, 0, value.m);
      break;
    }
    case BWUniformTypeFloatMatrix4: {
      GLKMatrix4 value = [uniform.value matrix4Value];
      glUniformMatrix4fv(uniform.location, 1, 0, value.m);
      break;
    }
    default:
      break;
  }
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
    
    BWShaderUniform *uniform = [[BWShaderUniform alloc] init];
    uniform.name = [NSString stringWithUTF8String:uniformName];
    uniform.location = uniformLocation;
    switch (type) {
      case GL_FLOAT:
        uniform.type = BWUniformTypeFloat;
        break;
      case GL_FLOAT_VEC2:
        uniform.type = BWUniformTypeFloatVec2;
        break;
      case GL_FLOAT_VEC3:
        uniform.type = BWUniformTypeFloatVec3;
        break;
      case GL_FLOAT_VEC4:
        uniform.type = BWUniformTypeFloatVec4;
        break;
      case GL_INT:
        uniform.type = BWUniformTypeInt;
        break;
      case GL_INT_VEC2:
        uniform.type = BWUniformTypeIntVec2;
        break;
      case GL_INT_VEC3:
        uniform.type = BWUniformTypeIntVec3;
        break;
      case GL_INT_VEC4:
        uniform.type = BWUniformTypeIntVec4;
        break;
      case GL_BOOL:
        uniform.type = BWUniformTypeBool;
        break;
      case GL_BOOL_VEC2:
        uniform.type = BWUniformTypeBoolVec2;
        break;
      case GL_BOOL_VEC3:
        uniform.type = BWUniformTypeBoolVec3;
        break;
      case GL_BOOL_VEC4:
        uniform.type = BWUniformTypeBoolVec4;
        break;
      case GL_FLOAT_MAT2:
        uniform.type = BWUniformTypeFloatMatrix2;
        break;
      case GL_FLOAT_MAT3:
        uniform.type = BWUniformTypeFloatMatrix3;
        break;
      case GL_FLOAT_MAT4:
        uniform.type = BWUniformTypeFloatMatrix4;
        break;
      case GL_SAMPLER_2D:
        uniform.type = BWUniformTypeSampler2D;
        break;
      case GL_SAMPLER_CUBE:
        uniform.type = BWUniformTypeSamplerCube;
        break;
      default:
        uniform.type = GL_ZERO;
        break;
    }
    [uniforms setObject:uniform forKey:uniform.name];
  }
  uniforms_ = uniforms;
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
