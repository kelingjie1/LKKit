//
//  LKFileDownloader.swift
//  LKVideoSDK
//
//  Created by lingtonke on 16/6/7.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation

public let LKFileDownloaderErrorNotification = "LKFileDownloaderErrorNotification"
public let LKFileDownloaderCompleteNotification = "LKFileDownloaderCompleteNotification"

public class LKLKFileDownloadRedirectInfo: NSObject
{
    var date = Date()
    var url : String = ""
    
    init(url : String)
    {
        super.init()
    }
}

public class LKFileDownloadTask : NSObject
{
    var request : URLRequest
    var task : URLSessionDataTask
    var range : NSRange
    var offset : Int = 0
    var startDate = Date()
    var responseDate : Date? = nil
    var finishDate : Date? = nil
    var redirectList : Array<LKLKFileDownloadRedirectInfo> = []
    static var taskCount = 0
    
    init(request : URLRequest,task : URLSessionDataTask, range : NSRange)
    {
        self.request = request
        self.task = task
        self.range = range
        super.init()
        LKFileDownloadTask.taskCount += 1
        NSLog("taskCount:\(LKFileDownloadTask.taskCount)")
    }
    
    deinit
    {
        LKFileDownloadTask.taskCount -= 1
        NSLog("taskCount:\(LKFileDownloadTask.taskCount)")
    }
}

protocol LKFileDownloaderDelegate
{
    
}


public class LKFileDownloader: NSObject,URLSessionDelegate,URLSessionDataDelegate,URLSessionTaskDelegate
{
    var fileCache : LKMMapFileCache? = nil
    var url : URL
    var session : Foundation.URLSession? = nil
    var taskDic : Dictionary<URLSessionDataTask,LKFileDownloadTask> = [:]
    var config = URLSessionConfiguration.default()
    var preferOffset = 0
    {
        didSet
        {
            if preferOffset != oldValue
            {
                LKFileDownloaderManager.queue.async
                {
                    let shouldStartNewTask = true
                    if shouldStartNewTask
                    {
                        self.cancel()
                        if !self.pause
                        {
                            self.nextTask()
                        }
                    }
                }
            }
            
        }
    }
    var pause = false
    {
        didSet
        {
            LKFileDownloaderManager.queue.async
            {
                if self.pause
                {
                    for (task,_) in self.taskDic
                    {
                        task.suspend()
                    }
                }
                else
                {
                    for (task,_) in self.taskDic
                    {
                        task.resume()
                    }
                    self.start()
                }
            }
            
            
        }
    }
    
    init(url : URL)
    {
        self.url = url
        super.init()
        config.timeoutIntervalForRequest = 10;
        config.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
    }
    
    deinit
    {
        NSLog("\(self) deinit")
    }
    
    func newTask(_ range : NSRange)
    {
        let rangeStr = "bytes=\(range.location)-\(range.location+range.length)";
        var request = URLRequest(url: self.url)
        request.setValue(rangeStr, forHTTPHeaderField: "Range")
        request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.addValue("identity", forHTTPHeaderField: "Accept-Encoding")
        request.httpMethod = "GET"
        let task = self.session!.dataTask(with: request)
        task.resume()
        
        let downloadTask = LKFileDownloadTask(request: request, task: task, range: range)
        self.taskDic[task] = downloadTask
        NSLog("newTask:\(range)")
    }
    
    func nextTask()
    {
        if !self.taskDic.isEmpty || self.pause
        {
            return
        }
        if self.fileCache == nil
        {
            self.newTask(NSMakeRange(0, 2))
        }
        else if  self.fileCache!.totalDataLength() < self.fileCache!.fileInfo.size
        {
            var range = NSMakeRange(0, 2)
            if self.fileCache != nil
            {
                range = self.fileCache!.rangeOfRequestRange(NSMakeRange(self.preferOffset, self.fileCache!.fileInfo.size-self.preferOffset))
                if range.length==0
                {
                    range = self.fileCache!.rangeOfRequestRange(NSMakeRange(0, self.fileCache!.fileInfo.size))
                }
            }
            self.newTask(range)
        }
        else
        {
            self.session?.invalidateAndCancel()
            self.session = nil
            NotificationCenter.default().post(name: Notification.Name(rawValue: LKFileDownloaderCompleteNotification), object: self, userInfo: nil)

        }
    }
    
    func start()
    {
        if self.session == nil
        {
            self.session = Foundation.URLSession(configuration: self.config, delegate: self, delegateQueue: nil)
        }
        
        if self.taskDic.isEmpty
        {
            self.nextTask()
        }
        
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        LKFileDownloaderManager.queue.async
        {
            if self.fileCache==nil
            {
                LKLogError("fileCache is nil")
                return
            }
            let downloadTask = self.taskDic[dataTask]!
            self.fileCache?.writeData(data, offset: downloadTask.offset+downloadTask.range.location)
            downloadTask.offset+=data.count
            self.taskDic[dataTask] = downloadTask
        }
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?)
    {
        LKFileDownloaderManager.queue.async
        {
            if let dataTask = task as? URLSessionDataTask
            {
                if let error = error
                {
                    switch error.code
                    {
                    case NSURLErrorCancelled:
                        NSLog("cancel")
                    default:
                        LKLogError("error")
                    }
                    
                    self.taskDic.removeValue(forKey: dataTask)
                    self.nextTask()
                    NotificationCenter.default().post(name: Notification.Name(rawValue: LKFileDownloaderErrorNotification), object: self, userInfo: ["error":error])
                }
                else
                {
                    NSLog("complete")
                    self.taskDic.removeValue(forKey: dataTask)
                    self.nextTask()
                }
                
                
            }
            else
            {
                NSLog("not dataTask")
            }
        }
        
    }
    
    @nonobjc public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: (URLRequest) -> Void)
    {
        LKFileDownloaderManager.queue.async
        {
            if let dataTask = task as? URLSessionDataTask
            {
                let downloadTask = self.taskDic[dataTask]
                downloadTask?.responseDate = Date()
                
                
                let location = response.allHeaderFields["Location"] as? String
                if location != nil
                {
                    downloadTask?.redirectList.append(LKLKFileDownloadRedirectInfo(url: location!))
                }
                
                
            }
            completionHandler(request)
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void)
    {
        LKFileDownloaderManager.queue.async
        {
            let downloadTask = self.taskDic[dataTask]
            downloadTask?.responseDate = Date()
            if let response = response as? HTTPURLResponse
            {
                NSLog("rsp \(response.statusCode)")
                if response.statusCode>=200&&response.statusCode<300
                {
                    if self.fileCache==nil
                    {
                        let strContentRange = response.allHeaderFields["Content-Range"]
                        let index = strContentRange!.range(of: "/").location+1
                        let fileSizeStr = strContentRange?.substring(with: NSRange(location: index,length: strContentRange!.length-index))
                        LKMMapFileCacheManager.shareInstance().openOrCreateCache(self.url.lastPathComponent!, size: Int(fileSizeStr!)!, complete:{
                            (cache, error) in
                            if let error = error
                            {
                                NSLog("\(error.code) : \(error.localizedDescription)")
                                NotificationCenter.default().post(name: Notification.Name(rawValue: LKFileDownloaderErrorNotification), object: self, userInfo: ["error":error])
                            }
                            else
                            {
                                self.fileCache = cache
                            }
                            
                            
                        })
                    }
                }
                else
                {
                    
                }
                
                completionHandler(Foundation.URLSession.ResponseDisposition.allow)
            }
            else
            {
                LKLogError("Not httpResponse")
                completionHandler(Foundation.URLSession.ResponseDisposition.cancel)
            }
        }
    }
    
    public func cancel()
    {
        for (task,_) in self.taskDic
        {
            task.cancel()
        }
    }
    
    public func close()
    {
        self.session?.invalidateAndCancel()
        self.session = nil
        self.fileCache = nil
    }
}


public class LKFileDownloaderManager: NSObject
{
    private static var __once: () = {
            instance = LKFileDownloaderManager()
        }()
    static var queue = DispatchQueue(label: "com.tencent.download", attributes: [])
    static var instance : LKFileDownloaderManager? = nil
    static var once : Int = 0
    var downloaderDic : NSMutableDictionary = [:]
    
    class public func shareInstance() -> LKFileDownloaderManager
    {
        _ = LKFileDownloaderManager.__once
        return instance!
    }
    
    public func openOrCreateDownloader(_ url : URL, complete : (LKFileDownloader?,NSError?)->Void)
    {
        LKFileDownloaderManager.queue.sync
        {
            let downloader = self.downloaderDic.lk_objectForKey(url.path!) as? LKFileDownloader
            if downloader != nil
            {
                self.downloaderDic.lk_setWeakObject(downloader!, forKey: url.path!)
                complete(downloader,nil)
                
            }
            else
            {
                let downloader = LKFileDownloader(url: url)
                self.downloaderDic.lk_setWeakObject(downloader, forKey: url.path!)
                complete(downloader,nil)
            }
            
        }
    }
    
    public func getDownloader(_ url : URL) -> LKFileDownloader?
    {
        var downloader : LKFileDownloader?
        LKFileDownloaderManager.queue.sync
        {
            downloader = self.downloaderDic.lk_objectForKey(url.path!) as? LKFileDownloader
        }
        return downloader
    }
    
    public func removeAndCloseDownloader(_ url : URL)
    {
        LKFileDownloaderManager.queue.sync
        {
            let downloader = self.downloaderDic.lk_objectForKey(url.path!)  as? LKFileDownloader
            downloader?.close()
            self.downloaderDic.removeObject(forKey: url.path!)
        }
    }
    
    public func removeAndCloseAllDownloader()
    {
        LKFileDownloaderManager.queue.sync
        {
            for (_,downloader) in self.downloaderDic
            {
                if let downloader = downloader as? LKDictionaryAutoRemoveObject
                {
                    (downloader.object as? LKFileDownloader)?.close()
                }
                else
                {
                    (downloader.object as? LKFileDownloader)?.close()
                }
                
            }
            self.downloaderDic.removeAllObjects()
        }
    }
}
