//
//  LKNormalVideoViewControler.swift
//  LKVideoSDK
//
//  Created by lingtonke on 16/6/3.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit
import GLKit
import AVFoundation

class LKNormalVideoViewControler: GLKViewController,LKPlayable
{
    var player : LKVideoPlayer?
    var textureCache : CVOpenGLESTextureCache? = nil
    var renderTexture : CVOpenGLESTexture? = nil
    var renderTexture2 : CVOpenGLESTexture? = nil
    var glcontext : EAGLContext?;
    var cicontext : CIContext?;
    var filter : CIFilter?
    var width = 0
    var height = 0
    var videoRect = CGRect.zero
    
    var videoRectChange: (() -> Void)?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    var frame: CGRect
    {
        get
        {
            return self.view.frame
        }
        set
        {
            self.view.frame = newValue
        }
    }
    
    override func viewDidLoad()
    {
        let view = self.view as! GLKView;
        glcontext = EAGLContext(api: EAGLRenderingAPI.openGLES2);
        if (glcontext==nil) {
            NSLog("Failed to create ES context");
        }
        view.context = glcontext!;
        view.drawableDepthFormat = GLKViewDrawableDepthFormat.format24;
        
        self.cicontext = CIContext(eaglContext: self.glcontext!, options: nil)
        
        EAGLContext.setCurrent(self.glcontext)
        
        self.preferredFramesPerSecond = 30
        
        let err = CVOpenGLESTextureCacheCreate(nil, nil, glcontext!, nil, &textureCache)
        if err != kCVReturnSuccess
        {
            
        }
        
        if (filter == nil) {
            filter = CIFilter(name: "CIColorBlendMode")
            filter?.setDefaults()
        }
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        
        EAGLContext.setCurrent(self.glcontext)
        glClearColor(0, 0, 0, 1);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT));
        
        
        if self.player==nil {
            return
        }
        
        let pixelBuffer = self.player?.videoOutput .copyPixelBuffer(forItemTime: self.player!.currentTime(), itemTimeForDisplay: nil)
        if pixelBuffer==nil {
            return
        }
        width = CVPixelBufferGetWidth(pixelBuffer!)
        height = CVPixelBufferGetHeight(pixelBuffer!)
        
        glActiveTexture(GLenum(GL_TEXTURE0));
        let result = CVOpenGLESTextureCacheCreateTextureFromImage(nil,
                                                                  textureCache!,
                                                                  pixelBuffer!,
                                                                  nil,
                                                                  GLenum(GL_TEXTURE_2D),
                                                                  GL_RGBA,
                                                                  GLsizei(width),
                                                                  GLsizei(height),
                                                                  GLenum(GL_BGRA),
                                                                  GLenum(GL_UNSIGNED_BYTE),
                                                                  0,
                                                                  &renderTexture);
        if result != kCVReturnSuccess {
            NSLog("aa")
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(renderTexture!), CVOpenGLESTextureGetName(renderTexture!));
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
        let image = CIImage(texture: CVOpenGLESTextureGetName(renderTexture!),
                            size:CGSize(width: CGFloat(width), height: CGFloat(height)),
                            flipped:true,
                            colorSpace:nil)
        let drawableRect = CGRect(x: 0, y: 0, width: CGFloat(view.drawableWidth), height: CGFloat(view.drawableHeight));
        let aspectRect = AVMakeRect(aspectRatio: image.extent.size, insideRect: drawableRect);
        if videoRect != aspectRect
        {
            videoRect = aspectRect
            self.videoRectChange?()
        }
        self.cicontext?.draw(image, in: aspectRect, from: image.extent)
    }
    
}











