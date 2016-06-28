//
//  LKVideoPlayerItem.swift
//  LKVideoSDK
//
//  Created by lingtonke on 16/6/6.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import AVFoundation

public class LKVideoPlayerItem: AVPlayerItem
{
    weak var player : LKVideoPlayer? = nil
    var videoAsset : LKVideoAsset
    {
        get
        {
            return self.asset as! LKVideoAsset
        }
    }
    
    
    var seekTarget = -1.0
    var seekCallback : ((finished : Bool)->Void)? = nil
    
    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?)
    {
        super.init(asset: asset, automaticallyLoadedAssetKeys: automaticallyLoadedAssetKeys)
        
        
        self.addObserver(self, forKeyPath: "status", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil)
        self.addObserver(self, forKeyPath: "playbackBufferFull", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old,NSKeyValueObservingOptions.initial], context: nil)
        self.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old,NSKeyValueObservingOptions.initial], context: nil)
        self.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old,NSKeyValueObservingOptions.initial], context: nil)
        
        NotificationCenter.default().addObserver(self, selector: #selector(didPlayToEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self)
    }
    
    deinit
    {
        NotificationCenter.default().removeObserver(self)
        
        self.removeObserver(self, forKeyPath: "status")
        self.removeObserver(self, forKeyPath: "playbackBufferFull")
        self.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        self.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        
        let asset = self.asset as! LKVideoAsset
        asset.releaseResource()
        NSLog("\(self) deinit")
    }
    
    func didPlayToEnd(_ notification : Notification)
    {
        
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?)
    {
        switch keyPath!
        {
        case "status":
            if self.status == AVPlayerItemStatus.readyToPlay && self.seekTarget>=0
            {
                if self.seekCallback != nil
                {
                    self.seek(to: CMTimeMakeWithSeconds(self.seekTarget, 1000), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: self.seekCallback!)
                }
                else
                {
                    self.seek(to: CMTimeMakeWithSeconds(self.seekTarget, 1000), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
                }
                self.seekTarget = -1.0
                self.seekCallback = nil
            }
            self.player?.playerItemStatusChange()
        case "playbackBufferFull":
            break
        case "playbackBufferEmpty":
            break
        case "playbackLikelyToKeepUp":
            self.player?.playerItemPlaybackLikelyToKeepUpChange()
            break
        default:
            LKLogError("unknow kvo")
        }
        
    }
    
    public func seekTo(_ time : Double, complete : ((finished : Bool)->Void)?)
    {
        if self.status == AVPlayerItemStatus.readyToPlay
        {
            if complete != nil
            {
                self.seek(to: CMTimeMakeWithSeconds(time, 1000), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: complete!)
            }
            else
            {
                self.seek(to: CMTimeMakeWithSeconds(time, 1000), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            }
            
        }
        else if self.status == AVPlayerItemStatus.unknown
        {
            self.seekTarget = time
            self.seekCallback = complete
        }
        else
        {
            LKLogError("PlayerItemStatus is fail")
        }
    }
}
