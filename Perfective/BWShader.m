//
//  BWShaderObject.m
//  TestGame
//
//  Created by Brandon Withrow on 6/12/13.
//  Copyright (c) 2013 Brandon Withrow. All rights reserved.
//
#import "uthash.h"
#import "BWShader.h"

struct BWUniform {
  char name[24];
  BWUniformType type;
  GLuint location;
  UT_hash_handle hh; /* makes this structure hashable */
};

@implementation BWShader {
  GLuint programID_;
  struct BWUniform *allUniforms_;
}

- (id)initWithShaderNamed:(NSString *)shaderName {
  self = [super init];
  if (self) {
    _shaderName = shaderName;
    allUniforms_ = NULL;
    [self loadShaderNamed:shaderName];
  }
  return self;
}

- (void)use {
  glUseProgram(programID_);
}

- (void)setUniform:(NSString *)name withValue:(void *)value {
  struct BWUniform *uniform2;
  HASH_FIND_STR(allUniforms_, name.UTF8String, uniform2);
  
  if (!uniform2 || !value) {
    return;
  }
  
  GLuint location = uniform2->location;
  BWUniformType type = uniform2->type;
  
  switch (type) {
    case BWUniformTypeFloat: {
      GLfloat setValue = *((GLfloat *)value);
      glUniform1f(location, setValue);
      break;
    }
    case BWUniformTypeFloatVec2: {
      GLKVector2 setValue = *((GLKVector2 *)value);
      glUniform2f(location, setValue.x, setValue.y);
      break;
    }
    case BWUniformTypeFloatVec3: {
      GLKVector3 setValue = *((GLKVector3 *)value);
      glUniform3f(location, setValue.x, setValue.y, setValue.z);
      break;
    }
    case BWUniformTypeFloatVec4: {
      GLKVector4 setValue = *((GLKVector4 *)value);
      glUniform4f(location, setValue.x, setValue.y, setValue.z, setValue.w);
      break;
    }
    case BWUniformTypeBool:
    case BWUniformTypeInt: {
      GLint setValue = *((GLint *)value);
      glUniform1i(location, setValue);
      break;
    }
    case BWUniformTypeBoolVec2:
    case BWUniformTypeIntVec2: {
      GLKVector2 setValue = *((GLKVector2 *)value);
      glUniform2i(location, (GLint)setValue.x, (GLint)setValue.y);
      break;
    }
    case BWUniformTypeBoolVec3:
    case BWUniformTypeIntVec3: {
      GLKVector3 setValue = *((GLKVector3 *)value);
      glUniform3i(location, (GLint)setValue.x, (GLint)setValue.y, (GLint)setValue.z);
      break;
    }
    case BWUniformTypeBoolVec4:
    case BWUniformTypeIntVec4: {
      GLKVector4 setValue = *((GLKVector4 *)value);
      glUniform4i(location, (GLint)setValue.x, (GLint)setValue.y, (GLint)setValue.z, (GLint)setValue.w);
      break;
    }
    case BWUniformTypeFloatMatrix2: {
      GLKMatrix2 setValue = *((GLKMatrix2 *)value);
      glUniformMatrix2fv(location, 1, 0, setValue.m);
      break;
    }
    case BWUniformTypeFloatMatrix3: {
      GLKMatrix3 setValue = *((GLKMatrix3 *)value);
      glUniformMatrix3fv(location, 1, 0, setValue.m);
      break;
    }
    case BWUniformTypeFloatMatrix4: {
      GLKMatrix4 setValue = *((GLKMatrix4 *)value);
      glUniformMatrix4fv(location, 1, 0, setValue.m);
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
  for (int i = 0; i < uniformCount; i++) {
    int name_len=-1, num=-1;
    GLenum type = GL_ZERO;
    char uniformName[100];
    
    glGetActiveUniform(programID_, i, sizeof(uniformName)-1, &name_len, &num, &type, uniformName );
    
    uniformName[name_len] = 0;
    GLuint uniformLocation = glGetUniformLocation(programID_, uniformName);

    struct BWUniform *uniStruct;
    uniStruct = malloc(sizeof(struct BWUniform));
    strcpy(uniStruct->name, uniformName);
    uniStruct->location = uniformLocation;
    
    switch (type) {
      case GL_FLOAT:
        uniStruct->type = BWUniformTypeFloat;
        break;
      case GL_FLOAT_VEC2:
        uniStruct->type = BWUniformTypeFloatVec2;
        break;
      case GL_FLOAT_VEC3:
        uniStruct->type = BWUniformTypeFloatVec3;
        break;
      case GL_FLOAT_VEC4:
        uniStruct->type = BWUniformTypeFloatVec4;
        break;
      case GL_INT:
        uniStruct->type = BWUniformTypeInt;
        break;
      case GL_INT_VEC2:
        uniStruct->type = BWUniformTypeIntVec2;
        break;
      case GL_INT_VEC3:
        uniStruct->type = BWUniformTypeIntVec3;
        break;
      case GL_INT_VEC4:
        uniStruct->type = BWUniformTypeIntVec4;
        break;
      case GL_BOOL:
        uniStruct->type = BWUniformTypeBool;
        break;
      case GL_BOOL_VEC2:
        uniStruct->type = BWUniformTypeBoolVec2;
        break;
      case GL_BOOL_VEC3:
        uniStruct->type = BWUniformTypeBoolVec3;
        break;
      case GL_BOOL_VEC4:
        uniStruct->type = BWUniformTypeBoolVec4;
        break;
      case GL_FLOAT_MAT2:
        uniStruct->type = BWUniformTypeFloatMatrix2;
        break;
      case GL_FLOAT_MAT3:
        uniStruct->type = BWUniformTypeFloatMatrix3;
        break;
      case GL_FLOAT_MAT4:
        uniStruct->type = BWUniformTypeFloatMatrix4;
        break;
      case GL_SAMPLER_2D:
        uniStruct->type = BWUniformTypeSampler2D;
        break;
      case GL_SAMPLER_CUBE:
        uniStruct->type = BWUniformTypeSamplerCube;
        break;
      default:
        uniStruct->type = BWUniformTypeZero;
        break;
    }
    HASH_ADD_STR(allUniforms_, name, uniStruct);
  }
  
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

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
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

- (BOOL)linkProgram:(GLuint)prog {
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

- (BOOL)validateProgram:(GLuint)prog {
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
  glUseProgram(0);
  glDeleteProgram(programID_);
  struct BWUniform *uniform, *tmp;
  HASH_ITER(hh, allUniforms_, uniform, tmp) {
    HASH_DEL(allUniforms_, uniform);
    free(uniform);
  }
}

@end
