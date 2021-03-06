//
//  AGLKTextureTransformBaseEffect.m
//  OpenGL_ES_15
//
//  Created by STMBP on 2017/2/14.
//  Copyright © 2017年 sensetime. All rights reserved.
//

#import "AGLKTextureTransformBaseEffect.h"

enum
{
    AGLKModelviewMatrix,
    AGLKMVPMatrix,
    AGLKNormalMatrix,
    AGLKTex0Matrix,
    AGLKTex1Matrix,
    AGLKSamplers,
    AGLKTex0Enabled,
    AGLKTex1Enabled,
    AGLKGlobalAmbient,
    AGLKLight0Pos,
    AGLKLight0Direction,
    AGLKLight0Diffuse,
    AGLKLight0Cutoff,
    AGLKLight0Exponent,
    AGLKLight1Pos,
    AGLKLight1Direction,
    AGLKLight1Diffuse,
    AGLKLight1Cutoff,
    AGLKLight1Exponent,
    AGLKLight2Pos,
    AGLKLight2Diffuse,
    AGLKNumUniforms
};
@interface AGLKTextureTransformBaseEffect ()
{
    GLuint _program;
    GLint _uniforms[AGLKNumUniforms];
}

@property (nonatomic, assign) GLKVector3 light0EyePosition;
@property (nonatomic, assign) GLKVector3 light0EyeDirection;
@property (nonatomic, assign) GLKVector3 light1EyePosition;
@property (nonatomic, assign) GLKVector3 light1EyeDirection;
@property (nonatomic, assign) GLKVector3 light2EyePosition;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation AGLKTextureTransformBaseEffect

- (instancetype)init
{
    if (self = [super init])
    {
        self.textureMatrix2d0 = GLKMatrix4Identity;
        self.textureMatrix2d1 = GLKMatrix4Identity;
        self.texture2d0.enabled = GL_FALSE;
        self.texture2d1.enabled = GL_FALSE;
        self.material.ambientColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
        self.lightModelAmbientColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
        self.light0.enabled = GL_FALSE;
        self.light1.enabled = GL_FALSE;
        self.light2.enabled = GL_FALSE;
    }
    return self;
}
- (void)prepareToDrawMultiTextures
{
    if (0 == _program)
    {
        [self loadShaders];
    }

    if (0 != _program)
    {
        glUseProgram(_program);

        const GLuint samplerIDs[2] = {0, 1};
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(self.transform.projectionMatrix,self.transform.modelviewMatrix);

        glUniformMatrix4fv(_uniforms[AGLKModelviewMatrix], 1, 0,self.transform.modelviewMatrix.m);
        glUniformMatrix4fv(_uniforms[AGLKMVPMatrix], 1, 0,modelViewProjectionMatrix.m);
        glUniformMatrix3fv(_uniforms[AGLKNormalMatrix], 1, 0,self.transform.normalMatrix.m);
        glUniformMatrix4fv(_uniforms[AGLKTex0Matrix], 1, 0,self.textureMatrix2d0.m);
        glUniformMatrix4fv(_uniforms[AGLKTex1Matrix], 1, 0,self.textureMatrix2d1.m);

        glUniform1iv(_uniforms[AGLKSamplers], 2,(const GLint *)samplerIDs);

        GLKVector4 globalAmbient = GLKVector4Multiply(self.lightModelAmbientColor,self.material.ambientColor);
        if(self.light0.enabled)
        {
            globalAmbient = GLKVector4Add(globalAmbient,GLKVector4Multiply(self.light0.ambientColor,self.material.ambientColor));
        }
        if(self.light1.enabled)
        {
            globalAmbient = GLKVector4Add(globalAmbient,GLKVector4Multiply(self.light1.ambientColor,self.material.ambientColor));
        }
        if(self.light2.enabled)
        {
            globalAmbient = GLKVector4Add(globalAmbient,GLKVector4Multiply(self.light2.ambientColor,self.material.ambientColor));
        }
        glUniform4fv(_uniforms[AGLKGlobalAmbient], 1, globalAmbient.v);

        glUniform1f(_uniforms[AGLKTex0Enabled],self.texture2d0.enabled ? 1.0 : 0.0);
        glUniform1f(_uniforms[AGLKTex1Enabled],self.texture2d1.enabled ? 1.0 : 0.0);

            // light0
        if(self.light0.enabled)
        {
            glUniform3fv(_uniforms[AGLKLight0Pos], 1,self.light0EyePosition.v);
            glUniform3fv(_uniforms[AGLKLight0Direction], 1,self.light0EyeDirection.v);
            glUniform4fv(_uniforms[AGLKLight0Diffuse], 1,GLKVector4Multiply(self.light0.diffuseColor,self.material.diffuseColor).v);
            glUniform1f(_uniforms[AGLKLight0Cutoff],GLKMathDegreesToRadians(self.light0.spotCutoff));
            glUniform1f(_uniforms[AGLKLight0Exponent],self.light0.spotExponent);
        }
        else
        {
            glUniform4fv(_uniforms[AGLKLight0Diffuse], 1,GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f).v);
        }

            // light1
        if(self.light1.enabled)
        {
            glUniform3fv(_uniforms[AGLKLight1Pos], 1,self.light1EyePosition.v);
            glUniform3fv(_uniforms[AGLKLight1Direction], 1,self.light1EyeDirection.v);
            glUniform4fv(_uniforms[AGLKLight1Diffuse], 1,GLKVector4Multiply(self.light1.diffuseColor,self.material.diffuseColor).v);
            glUniform1f(_uniforms[AGLKLight1Cutoff],GLKMathDegreesToRadians(self.light1.spotCutoff));
            glUniform1f(_uniforms[AGLKLight1Exponent],self.light1.spotExponent);
        }
        else
        {
            glUniform4fv(_uniforms[AGLKLight1Diffuse], 1,GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f).v);
        }

            // light2
        if(self.light2.enabled)
        {
            glUniform3fv(_uniforms[AGLKLight2Pos], 1,self.light2EyePosition.v);
            glUniform4fv(_uniforms[AGLKLight2Diffuse], 1,GLKVector4Multiply(self.light2.diffuseColor,self.material.diffuseColor).v);
        }
        else
        {
            glUniform4fv(_uniforms[AGLKLight2Diffuse], 1,GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f).v);
        }

            // 绑定所有的纹理到各自指定的单元
        glActiveTexture(GL_TEXTURE0);
        if(0 != self.texture2d0.name && self.texture2d0.enabled)
        {
            glBindTexture(GL_TEXTURE_2D, self.texture2d0.name);
        }
        else
        {
            glBindTexture(GL_TEXTURE_2D, 0);
        }

        glActiveTexture(GL_TEXTURE1);
        if(0 != self.texture2d1.name && self.texture2d1.enabled)
        {
            glBindTexture(GL_TEXTURE_2D, self.texture2d1.name);
        }
        else
        {
            glBindTexture(GL_TEXTURE_2D, 0);
        }

#ifdef DEBUG
        {  // Report any errors
            GLenum error = glGetError();
            if(GL_NO_ERROR != error)
            {
                NSLog(@"GL Error: 0x%x", error);
            }
        }
#endif

    }
}
- (BOOL)loadShaders
{
    GLuint vertShader,fragShader;

    _program = glCreateProgram();

    NSString *vertShaderPathName = [[NSBundle mainBundle]pathForResource:@"AGLKTextureMatrix2PointLightShader" ofType:@"vsh"];
    NSString *fragShaderPathName = [[NSBundle mainBundle]pathForResource:@"AGLKTextureMatrix2PointLightShader" ofType:@"fsh"];

    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathName]
        ||![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathName]
        )
    {
        NSLog(@"Failed to compile vertex or fragment shader");
        return NO;
    }
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);

    glBindAttribLocation(_program, GLKVertexAttribPosition,"a_position");
    glBindAttribLocation(_program, GLKVertexAttribNormal,"a_normal");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord0,"a_texCoord0");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord1,"a_texCoord1");

    if (![self linkProgram:_program])
    {
        NSLog(@"Failed to link program: %d", _program);

        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program)
        {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }

    _uniforms[AGLKModelviewMatrix] = glGetUniformLocation(_program, "u_modelviewMatrix");
    _uniforms[AGLKMVPMatrix] = glGetUniformLocation(_program, "u_mvpMatrix");
    _uniforms[AGLKNormalMatrix] = glGetUniformLocation(_program, "u_normalMatrix");
    _uniforms[AGLKTex0Matrix] = glGetUniformLocation(_program, "u_tex0Matrix");
    _uniforms[AGLKTex1Matrix] = glGetUniformLocation(_program, "u_tex1Matrix");
    _uniforms[AGLKSamplers] = glGetUniformLocation(_program, "u_unit2d");
    _uniforms[AGLKTex0Enabled] = glGetUniformLocation(_program, "u_tex0Enabled");
    _uniforms[AGLKTex1Enabled] = glGetUniformLocation(_program, "u_tex1Enabled");
    _uniforms[AGLKGlobalAmbient] = glGetUniformLocation(_program, "u_globalAmbient");
    _uniforms[AGLKLight0Pos] = glGetUniformLocation(_program, "u_light0EyePos");
    _uniforms[AGLKLight0Direction] = glGetUniformLocation(_program, "u_light0NormalEyeDirection");
    _uniforms[AGLKLight0Diffuse] = glGetUniformLocation(_program, "u_light0Diffuse");
    _uniforms[AGLKLight0Cutoff] = glGetUniformLocation(_program, "u_light0Cutoff");
    _uniforms[AGLKLight0Exponent] = glGetUniformLocation(_program, "u_light0Exponent");
    _uniforms[AGLKLight1Pos] = glGetUniformLocation(_program, "u_light1EyePos");
    _uniforms[AGLKLight1Direction] = glGetUniformLocation(_program, "u_light1NormalEyeDirection");
    _uniforms[AGLKLight1Diffuse] = glGetUniformLocation(_program, "u_light1Diffuse");
    _uniforms[AGLKLight1Cutoff] = glGetUniformLocation(_program, "u_light1Cutoff");
    _uniforms[AGLKLight1Exponent] = glGetUniformLocation(_program, "u_light1Exponent");
    _uniforms[AGLKLight2Pos] = glGetUniformLocation(_program, "u_light2EyePos");
    _uniforms[AGLKLight2Diffuse] = glGetUniformLocation(_program, "u_light2Diffuse");

    if (vertShader)
    {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }

    if (fragShader)
    {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
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

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    const GLchar *source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);

#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif

    GLint status;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) 
    {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}


#pragma mark - 
- (void)setLight0Position:(GLKVector4)light0Position
{
    self.light0.position = light0Position;
    light0Position = GLKMatrix4MultiplyVector4(self.light0.transform.modelviewMatrix, light0Position);
    self.light0EyePosition = GLKVector3Make(light0Position.x, light0Position.y, light0Position.z);
}
- (GLKVector4)light0Position
{
    return self.light0.position;
}

- (void)setLight0SpotDirection:(GLKVector3)light0SpotDirection
{
    self.light0.spotDirection = light0SpotDirection;
    light0SpotDirection = GLKMatrix4MultiplyVector3(self.light0.transform.modelviewMatrix, light0SpotDirection);
    self.light0SpotDirection = GLKVector3Normalize(GLKVector3Make(light0SpotDirection.x, light0SpotDirection.y, light0SpotDirection.z));
}
- (GLKVector3)light0SpotDirection
{
    return self.light0.spotDirection;
}

- (void)setLight1Position:(GLKVector4)light1Position
{
    self.light1.position = light1Position;
    light1Position = GLKMatrix4MultiplyVector4(self.light1.transform.modelviewMatrix, light1Position);
    self.light1EyePosition = GLKVector3Make(light1Position.x, light1Position.y, light1Position.z);
}
- (GLKVector4)light1Position
{
    return self.light1.position;
}
- (void)setLight1SpotDirection:(GLKVector3)light1SpotDirection
{
    self.light1.spotDirection = light1SpotDirection;
    light1SpotDirection = GLKMatrix4MultiplyVector3(self.light1.transform.modelviewMatrix, light1SpotDirection);
    self.light1SpotDirection = GLKVector3Normalize(GLKVector3Make(light1SpotDirection.x, light1SpotDirection.y, light1SpotDirection.z));
}
- (GLKVector3)light1SpotDirection
{
    return self.light1.spotDirection;
}

- (void)setLight2Position:(GLKVector4)light2Position
{
    self.light2.position = light2Position;
    light2Position = GLKMatrix4MultiplyVector4(self.light2.transform.modelviewMatrix, light2Position);
    self.light2EyePosition = GLKVector3Make(light2Position.x, light2Position.y, light2Position.z);
}
- (GLKVector4)light2Position
{
    return self.light2.position;
}
- (void)setLight2SpotDirection:(GLKVector3)light2SpotDirection
{
    self.light2.spotDirection = light2SpotDirection;
    light2SpotDirection = GLKMatrix4MultiplyVector3(self.light2.transform.modelviewMatrix, light2SpotDirection);
    self.light2SpotDirection = GLKVector3Normalize(GLKVector3Make(light2SpotDirection.x, light2SpotDirection.y, light2SpotDirection.z));
}
- (GLKVector3)light2SpotDirection
{
    return self.light2.spotDirection;
}

@end


@implementation GLKEffectPropertyTexture (AGLKAdditions)

- (void)aglkSetParameter:(GLenum)parameterID value:(GLint)value
{
    glBindTexture(self.target, self.name);
    glTexParameteri(self.target, parameterID, value);
}

@end
