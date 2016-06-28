//
//  LKVideoPlayer.swift
//  LKVideoSDK
//
//  Created by lingtonke on 16/6/3.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import AVFoundation

public class LKVideoPlayerBufferInfo
{
    var startDate = Date()
    var endDate : Date? = nil
    var startDataLength = 0
    var endDataLength = 0
    
    var duration : Double
    {
        get
        {
            if endDate != nil
            {
                return endDate!.timeIntervalSince(startDate)
            }
            else
            {
                return 0
            }
            
        }
    }
    
    var downloadedData : Int
    {
        get
        {
            return endDataLength-startDataLength
        }
    }
}

public class LKVideoPlayer: AVPlayer
{
    static let LKVideoPlayerFailNotification = "LKVideoPlayerFailNotification"
    static let LKVideoPlayerBufferStatusChangeNotification = "LKVideoPlayerBufferStatusChangeNotification"
    static let LKVideoPlayerDidPlayToEndNotification = "LKVideoPlayerDidPlayToEndNotification"
    static let LKVideoPlayerPlayStatusChangeNotification = "LKVideoPlayerPlayStatusChangeNotification"
    
    
    public var videoOutput : AVPlayerItemVideoOutput
    var asset : LKVideoAsset? = nil
    
    
    public var duration : Double
    {
        get
        {
            if self.currentPlayerItem != nil
            {
                let d = self.currentPlayerItem!.duration
                if d != kCMTimeInvalid
                {
                    return CMTimeGetSeconds(self.currentPlayerItem!.duration)
                }
                
            }
            return 0
            
        }
    }
    
    public var currentPlayTime : Double
    {
        get
        {
            if self.currentPlayerItem != nil
            {
                let d = self.currentPlayerItem!.currentTime()
                if d != kCMTimeInvalid
                {
                    return CMTimeGetSeconds(self.currentPlayerItem!.currentTime())
                }
                
            }
            return 0
        }
    }
    
    
    public var currentPlayerItem: LKVideoPlayerItem?
    {
        get
        {
            return self.currentItem as? LKVideoPlayerItem
        }
        set
        {
            self.replaceCurrentItem(with: newValue)
        }
    }
    
    var isPlaying = false
    {
        didSet
        {
            NotificationCenter.default().post(name: Notification.Name(rawValue: LKVideoPlayer.LKVideoPlayerPlayStatusChangeNotification), object: self, userInfo: ["isPlaying":!self.isPlaying])
        }
    }
    
    var bufferInfoList = Array<LKVideoPlayerBufferInfo>()
    var bufferInfo : LKVideoPlayerBufferInfo? = nil
    
    var isBuffering = false
    {
        didSet
        {
            if isBuffering != oldValue
            {
                if isBuffering
                {
                    bufferInfo = LKVideoPlayerBufferInfo()
                    if self.currentPlayerItem!.videoAsset.fileCache != nil
                    {
                        bufferInfo?.startDataLength = self.currentPlayerItem!.videoAsset.fileCache!.fileInfo.totalDataLength()
                    }
                    
                    bufferCount += 1
                }
                else
                {
                    bufferInfo?.endDate = Date()
                    bufferInfo?.endDataLength = self.currentPlayerItem!.videoAsset.fileCache!.fileInfo.totalDataLength()
                    bufferInfoList.append(bufferInfo!)
                    bufferInfo = nil
                    if isPlaying
                    {
                        self.play()
                    }
                }
                
                NotificationCenter.default().post(name: Notification.Name(rawValue: LKVideoPlayer.LKVideoPlayerBufferStatusChangeNotification), object: self, userInfo: ["isBuffering":!self.isBuffering])
                NSLog("buffer:\(isBuffering)")
            }
        }
    }
    var bufferCount = 0
    
    override init(url: URL)
    {
        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
        super.init()
        self.addObserver(self, forKeyPath: "rate", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil)
        self.newPlayTask(url)
    }
    
    override init()
    {
        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
        super.init()
        self.addObserver(self, forKeyPath: "rate", options: [NSKeyValueObservingOptions.new,NSKeyValueObservingOptions.old], context: nil)
    }
    
    deinit
    {
        self.removeObserver(self, forKeyPath: "rate")
        LKLog("\(self) deinit")
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?)
    {
        if keyPath == "rate"
        {
            
        }
    }
    
    public func stop()
    {
        self.pause()
        self.currentPlayerItem = nil
        
    }
    
    public func newPlayTask(_ url : URL)
    {
        if self.currentPlayerItem != nil
        {
            LKLogError("use a new LKPlayer instead")
            return
        }
        self.asset = LKVideoAsset(url: url, options: nil)
    }
    
    public func seekTo(_ time: Double, complete : ((finished : Bool)->Void)?)
    {
        super.pause()
        self.isBuffering = true
        self.currentPlayerItem?.seekTo(time, complete: complete)
        
    }
    
    public override func replaceCurrentItem(with item: AVPlayerItem?)
    {
        if let item = item as? LKVideoPlayerItem
        {
            self.currentPlayerItem?.player = nil
            self.currentPlayerItem?.remove(self.videoOutput)
            item.player = self
            item.add(self.videoOutput)
            super.replaceCurrentItem(with: item)
        }
        else
        {
            LKLogError("not LKVideoPlayerItem")
            return
        }
    }
    
    func playerItemStatusChange()
    {
        if self.currentPlayerItem!.status == AVPlayerItemStatus.failed
        {
            NotificationCenter.default().post(name: Notification.Name(rawValue: LKVideoPlayer.LKVideoPlayerFailNotification), object: self, userInfo: ["error":self.currentPlayerItem!.error!])
        }
    }
    
    func playerItemPlaybackLikelyToKeepUpChange()
    {
        self.isBuffering = !self.currentPlayerItem!.isPlaybackLikelyToKeepUp
    }
    
    func playerItemDidPlayToEnd()
    {
        NotificationCenter.default().post(name: Notification.Name(rawValue: LKVideoPlayer.LKVideoPlayerDidPlayToEndNotification), object: self, userInfo: nil)
    }
    
    public func loadVideo()
    {
        if self.currentPlayerItem == nil
        {
            if self.asset != nil
            {
                let playerItem = LKVideoPlayerItem(asset: asset!, automaticallyLoadedAssetKeys: nil)
                self.currentPlayerItem = playerItem
                self.isBuffering = true
            }
            else
            {
                LKLogError("must call newPlayerTask first")
            }
        }

    }
    
    public override func play()
    {
        self.loadVideo()
        self.isPlaying = true
        super.play()
    }
    
    public override func pause()
    {
        self.isPlaying = false
        super.pause()
    }
}
