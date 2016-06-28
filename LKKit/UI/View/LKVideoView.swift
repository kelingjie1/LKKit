//
//  LKVideoView.swift
//  LKVideoSDK
//
//  Created by lingtonke on 16/6/3.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

@objc public enum LKVideoViewMode : Int
{
    case normal,system,singleVR,doubleVR
}

@objc protocol LKPlayable
{
    var videoRect : CGRect {get}
    var videoRectChange : (()->Void)? {get set}
    var frame : CGRect {get set}
    var view : UIView {get}
    var player : LKVideoPlayer? {get set}
}

public class LKVideoPlayView: UIView,LKPlayable
{
    var videoRect: CGRect
    {
        get
        {
            return (self.layer as! AVPlayerLayer).videoRect
        }
    }
    
    var videoRectChange: (() -> Void)?
    var view: UIView
    {
        get
        {
            return self
        }
    }
    
    var player : LKVideoPlayer?
    {
        get
        {
            return (self.layer as! AVPlayerLayer).player as? LKVideoPlayer
        }
        set
        {
            (self.layer as! AVPlayerLayer).player = newValue
        }
    }
    
    
    public override class func layerClass() -> AnyClass
    {
        return AVPlayerLayer.self
    }
    
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.layer.addObserver(self, forKeyPath: "videoRect", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil)
    }
    
    deinit
    {
        self.layer.removeObserver(self, forKeyPath: "videoRect")
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?)
    {
        self.videoRectChange?()
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}

public class LKVideoView: UIView
{
    public var mode = LKVideoViewMode.normal {
        didSet
        {
            for view in self.subviews {
                view .removeFromSuperview()
            }
            self.normalVC = nil
            self.playerView = nil
            if mode == LKVideoViewMode.normal
            {
                self.normalVC = LKNormalVideoViewControler()
                self.current = self.normalVC!
            }
            else if mode == LKVideoViewMode.system
            {
                self.playerView = LKVideoPlayView()
                self.current = self.playerView!
            }
            self.addSubview(self.current.view)
            self.current.player = self.player
            
        }
    }
    
    var normalVC : LKNormalVideoViewControler? = nil
    var playerView : LKVideoPlayView? = nil
    var animating = false
    
    public var player : LKVideoPlayer?
    {
        didSet
        {
            normalVC?.player = self.player;
            playerView?.player = self.player;
        }
    }
    
    var current : LKPlayable
    
    
    override init(frame: CGRect)
    {
        self.normalVC = LKNormalVideoViewControler()
        self.current = self.normalVC!
        super.init(frame : frame)
        self.addSubview(self.normalVC!.view)
        self.backgroundColor = UIColor.yellow()
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews()
    {
        super.layoutSubviews()
        if current.videoRect.size != CGSize.zero
        {
            current.view.frame = AVMakeRect(aspectRatio: current.videoRect.size, insideRect: self.bounds)
        }
        else
        {
            current.view.frame = self.bounds
        }
    }
}
