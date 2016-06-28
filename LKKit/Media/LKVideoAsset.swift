//
//  LKVideoAsset.swift
//  LKVideoSDK
//
//  Created by lingtonke on 16/6/6.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import AVFoundation
import MobileCoreServices


public class LKVideoAsset: AVURLAsset,AVAssetResourceLoaderDelegate
{
    var queue : DispatchQueue
    var session : URLSession?
    public var reqeustUrl : URL
    public var downloader : LKFileDownloader? = nil
    public var fileCache : LKMMapFileCache? = nil
    
    var timer : Timer? = nil
    var loadingRequestList : Array<AVAssetResourceLoadingRequest> = []
    
    override init(url: URL, options: [String : AnyObject]? = [:])
    {
        self.reqeustUrl = url
        self.queue = DispatchQueue(label: "com.tencent.video", attributes: [])
        
        super.init(url: Foundation.URL(string: "LKVideoAsset://\(url)")!, options: options)
        
        LKMMapFileCacheManager.shareInstance().openCache(url.lastPathComponent!)
        {
            (cache, error) in
            if error == nil
            {
                self.fileCache = cache
            }
        }
        
        if self.fileCache == nil || self.fileCache?.totalDataLength() < self.fileCache?.fileInfo.size
        {
            LKFileDownloaderManager.shareInstance().openOrCreateDownloader(url)
            {
                (downloader, error) in
                self.downloader = downloader!
                self.downloader?.pause = false
            }
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(LKVideoAsset.dealWithData), userInfo: nil, repeats: true)
        self.resourceLoader.setDelegate(self, queue: self.queue)
    }
    
    deinit
    {
        LKLog("\(self) deinit")
    }
    
    func releaseResource()
    {
        self.cancelLoading()
        self.timer?.invalidate()
        self.timer = nil
        self.loadingRequestList.removeAll()
        self.resourceLoader.setDelegate(nil, queue: nil)
        self.downloader = nil;
        self.fileCache = nil;
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool
    {
        
        self.downloader?.preferOffset = Int(loadingRequest.dataRequest!.requestedOffset)
        
        self.loadingRequestList.append(loadingRequest)
        return true;
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest)
    {
        for i in 0..<self.loadingRequestList.count
        {
            if loadingRequest==self.loadingRequestList[i]
            {
                self.loadingRequestList.remove(at: i)
                break
            }
        }
    }
    
    func dealWithData()
    {
        self.queue.async
        {
            if self.fileCache == nil
            {
                self.fileCache = self.downloader?.fileCache
            }
            
            if let fileCache = self.fileCache
            {
                var newList = Array<AVAssetResourceLoadingRequest>()
                for loadingRequest in self.loadingRequestList
                {
                    
                    loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true;
                    let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, "application/octet-stream", nil)
                    
                    loadingRequest.contentInformationRequest?.contentType = String(contentType)
                    loadingRequest.contentInformationRequest?.contentLength = Int64(fileCache.fileInfo.size);
                    
                    let offset = loadingRequest.dataRequest!.currentOffset;
                    let length = loadingRequest.dataRequest!.requestedOffset+loadingRequest.dataRequest!.requestedLength-loadingRequest.dataRequest!.currentOffset
                    
                    let data = fileCache.readData(NSMakeRange(Int(offset), Int(length)))
                    if (data != nil)
                    {
                        loadingRequest.dataRequest?.respond(with: data!)
                        //LKLog("data:\(data?.length) offset:\(offset) length:\(length)")
                        if (offset+data!.count>=loadingRequest.dataRequest!.requestedOffset+loadingRequest.dataRequest!.requestedLength)
                        {
                            loadingRequest.finishLoading()
                            LKLog("finishLoading")
                            
                        }
                        else
                        {
                            newList.append(loadingRequest)
                        }
                    }
                }
                self.loadingRequestList = newList
            }
            
            
        }
    }
    
}
