//
//  LKMMapFileCache.swift
//  LKVideoSDK
//
//  Created by lingtonke on 16/6/6.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation

public class LKMMapFileInfo: NSObject,NSCoding
{
    var size = 0
    var dataRanges = Array<NSRange>()
    
    override init()
    {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        super.init()
        size = aDecoder.decodeInteger(forKey: "size")
        dataRanges = aDecoder.decodeObject(forKey: "dataRanges") as! Array<NSRange>
    }
    
    public func encode(with aCoder: NSCoder)
    {
        aCoder.encode(size, forKey: "size")
        aCoder.encode(dataRanges, forKey: "dataRanges")
    }
    
    func totalDataLength() -> Int
    {
        var length = 0
        
        for range in dataRanges
        {
            length += range.length
        }
        return length
    }
    
    class func openFile(_ path : String) -> LKMMapFileInfo?
    {
        
        var obj : AnyObject?
        LKObjc.lk_tryCatchFinally(
            {
                obj = NSKeyedUnarchiver.unarchiveObject(withFile: path+".cfg")
            }, catch: { (exception) in
                obj = nil
            }, finallyBlock: nil
        )
        
        return obj as? LKMMapFileInfo;
    }
    
    func save(_ path : String)
    {
        if !NSKeyedArchiver.archiveRootObject(self, toFile: path+".cfg")
        {
            LKLogWarning("Config File Save Error")
        }
    }
    
    
}

public class LKMMapFileCache: NSObject
{
    var fileInfo : LKMMapFileInfo;
    var path = ""
    var mappedFile : UnsafeMutablePointer<Void>
    var needSaveConfigFile = false
    
    var currentRangeIndex : Int = -1;
    var currentRange : NSRange?=nil;
    var timer : Timer? = nil
    var closed = false;

    init(path : String , fileInfo : LKMMapFileInfo,mappedFile : UnsafeMutablePointer<Void>)
    {
        self.path = path
        self.fileInfo = fileInfo
        self.mappedFile = mappedFile
        super.init()
        weak var wself = self
        self.timer = Timer.lk_scheduledTimerWithTimeInterval(2, block: {
            wself?.checkAndSaveConfigFile()
            }, repeats: true)
    }
    
    func checkAndSaveConfigFile()
    {
        LKMMapFileCacheManager.queue.async
        {
            self.saveConfigFile()
        }
    }
    
    func saveConfigFile()
    {
        if self.needSaveConfigFile
        {
            self.needSaveConfigFile = false
            self.fileInfo.save(self.path)
        }
    }
    
    
    class func openFile(_ path : String, complete : (LKMMapFileCache?,NSError?)->Void)
    {
        LKMMapFileCacheManager.queue.sync
        {
            self._openFile(path, complete: complete)
        }
    }
    
    class func _openFile(_ path : String, complete : (LKMMapFileCache?,NSError?)->Void)
    {
        let fileInfo : LKMMapFileInfo? = LKMMapFileInfo.openFile(path)
        if fileInfo == nil
        {
            complete(nil,LKError(code: LKErrorDomain.cannotReadConfigFile))
            return;
        }
        
        var fd = open(path, O_RDWR);
        if (fd < 0)
        {
            complete(nil,LKError(code: LKErrorDomain.openDataFileError))
            return;
        }
        
        defer
        {
            close(fd);
        }
        
        do
        {
            let fileAttributes = try FileManager.default().attributesOfItem(atPath: path)
            let fileSize = fileAttributes[FileAttributeKey.size.rawValue] as! Int
            
            // mmap
            let mappedFile = mmap(nil, fileSize, PROT_READ|PROT_WRITE, MAP_FILE|MAP_SHARED, fd, 0);
            if (mappedFile==nil)
            {
                complete(nil,LKError(code: LKErrorDomain.memoryMapError))
                return;
            }
            complete(LKMMapFileCache(path: path,fileInfo: fileInfo!, mappedFile: mappedFile!),nil)
            return;
            
        }
        catch let error as NSError
        {
            complete(nil,error)
            return;
        }
    }
    
    class func createFile(_ path : String,size : Int, complete : (LKMMapFileCache?,NSError?)->Void)
    {
        LKMMapFileCacheManager.queue.sync
        {
            self._createFile(path, size: size, complete: complete)
        }
    }
    
    class func _createFile(_ path : String,size : Int, complete : (LKMMapFileCache?,NSError?)->Void)
    {
        let fileInfo = LKMMapFileInfo();
        fileInfo.size = size;
        fileInfo.save(path)
        
        let f = fopen(path, "wb+");
        if (f==nil)
        {
            complete(nil,LKError(code: LKErrorDomain.createDataFileError))
            return;
        }
        fseek(f, size-1, SEEK_CUR);
        fputc(0, f);
        fclose(f);
        
        LKMMapFileCache._openFile(path, complete: complete)
    }
    
    func dataRanges() -> Array<NSRange>
    {
        var array = Array<NSRange>();
        LKMMapFileCacheManager.queue.sync
        {
            array = Array<NSRange>(self.fileInfo.dataRanges);
        }
        return array;
    }
    
    func totalDataLength() -> Int {
        var length = 0;
        LKMMapFileCacheManager.queue.sync
        {
            length = self.fileInfo.totalDataLength();
        }
        return length;
    }

    func rangeOfRequestRange(_ range : NSRange) -> NSRange
    {
        var newRange : NSRange?;
        LKMMapFileCacheManager.queue.sync
        {
            
            newRange = self._rangeOfRequestRange(range)
        }
        return newRange!;
    }
    
    func _rangeOfRequestRange(_ range : NSRange) -> NSRange
    {
        var newRange = range;
        for i in 0 ..< self.fileInfo.dataRanges.count
        {
            let curRange = self.fileInfo.dataRanges[i];
            if (range.location<curRange.location&&range.location+range.length>curRange.location)
            {
                newRange.location = range.location;
                newRange.length = curRange.location-range.location;
                break;
                
            }
            else if (range.location>=curRange.location&&range.location<=curRange.location+curRange.length)
            {
                if (range.location+range.length<=curRange.location+curRange.length)
                {
                    newRange = NSMakeRange(0, 0);
                    break;
                }
                else
                {
                    newRange.location = curRange.location+curRange.length;
                    newRange.length = range.location+range.length-curRange.location-curRange.length;
                    break;
                    
                }
            }

        }
        
        
        if (newRange.location+newRange.length>self.fileInfo.size)
        {
            newRange.length = self.fileInfo.size-newRange.location;
        }
        return newRange;
    }
    
    func writeData(_ data : Data, offset : Int)
    {
        LKMMapFileCacheManager.queue.async
        {
            self._writeData(data, offset: offset)
        }
    }
    
    func _writeData(_ data : Data, offset : Int)
    {
        if self.closed
        {
            LKLogWarning("LKMMapFileCache already closed")
            return;
        }
        var length = data.count;
        if (offset>=self.fileInfo.size)
        {
            return;
        }
        if (length+offset>self.fileInfo.size)
        {
            length = self.fileInfo.size-offset;
        }
        (data as NSData).getBytes(self.mappedFile+offset,length: length)
        
        self.addDataRange(offset, length: data.count)

    }
    
    func addDataRange(_ offset : Int, length : Int) {
        if (self.currentRangeIndex>=0&&offset>=self.currentRange!.location&&offset<=self.currentRange!.location+self.currentRange!.length)
        {
            if (offset+length>self.currentRange!.location+self.currentRange!.length)
            {
                self.currentRange = NSMakeRange(self.currentRange!.location, offset+length-self.currentRange!.location)
                self.fileInfo.dataRanges[self.currentRangeIndex] = self.currentRange!;
            }
            
        }
        else
        {
            var found = false;
            for i in 0 ..< self.fileInfo.dataRanges.count
            {
                let range = self.fileInfo.dataRanges[i];
                if (range.location+range.length<offset)
                {
                    continue;
                }
                else if (range.location<=offset&&range.location+range.length>=offset)
                {
                    self.currentRange = NSMakeRange(range.location,max(offset+length-range.location,range.length))
                    self.currentRangeIndex = i;
                    self.fileInfo.dataRanges[self.currentRangeIndex] = self.currentRange!
                    found = true;
                    break;
                }
                else
                {
                    self.currentRange = NSMakeRange(offset,length)
                    self.currentRangeIndex = i;
                    self.fileInfo.dataRanges.insert(self.currentRange!, at: i)
                    found = true;
                    break;
                }
            }
            if (!found)
            {
                self.currentRange = NSMakeRange(offset,length)
                self.currentRangeIndex = self.fileInfo.dataRanges.count;
                self.fileInfo.dataRanges.append(self.currentRange!)
            }
        }
        
        
        
        
        while (self.currentRangeIndex<self.fileInfo.dataRanges.count-1)
        {
            let nextRange = self.fileInfo.dataRanges[self.currentRangeIndex+1];
            if (self.currentRange!.location+self.currentRange!.length>=nextRange.location)
            {
                self.currentRange = NSMakeRange(self.currentRange!.location,nextRange.location+nextRange.length-self.currentRange!.location)
                self.fileInfo.dataRanges.remove(at: self.currentRangeIndex+1)
                self.fileInfo.dataRanges[self.currentRangeIndex] = self.currentRange!;
            }
            else
            {
                break;
            }
        }
        
        self.needSaveConfigFile = true;

    }
    
    func readData(_ range : NSRange) -> Data?
    {
        var data : Data?;
        LKMMapFileCacheManager.queue.sync
        {
            data = self._readData(range)
        }

        return data!;
    }
    
    func _readData(_ range : NSRange) -> Data?
    {
        if self.closed
        {
            LKLogWarning("LKMMapFileCache already closed")
            return nil;
        }
        var data : Data?;
        var newRange = self._rangeForOffset(range.location);
        if (newRange.length>range.length)
        {
            newRange.length = range.length;
        }
        data = Data(bytesNoCopy: UnsafeMutablePointer<UInt8>(self.mappedFile+newRange.location), count: newRange.length, deallocator: .none)
        return data;
    }
    
    func rangeForOffset(_ offset : Int) -> NSRange
    {
        var range : NSRange?;
        LKMMapFileCacheManager.queue.sync
        {
            range = self._rangeForOffset(offset)
        }
        return range!;
    }
    
    func _rangeForOffset(_ offset : Int) -> NSRange
    {
        var newRange = NSMakeRange(0, 0);
        for i in 0 ..< self.fileInfo.dataRanges.count
        {
            let range = self.fileInfo.dataRanges[i];
            if (range.location<=offset&&range.location+range.length>=offset)
            {
                newRange = NSMakeRange(offset, range.location+range.length-offset);
                break;
            }
        }
        return newRange;
    }
    
    func clear()
    {
        LKMMapFileCacheManager.queue.sync
        {
            self.fileInfo.dataRanges = Array<NSRange>();
            self.currentRangeIndex = -1;
            self.fileInfo.save(self.path)
        }
    }
    
    func closeAndDeleteFile()
    {
        LKMMapFileCacheManager.queue.sync
        {
            self._closeFile()
            
            do
            {
                try FileManager.default().removeItem(atPath: self.path)
                try FileManager.default().removeItem(atPath: self.path + ".cfg")
            }
            catch let error as NSError
            {
                LKLogWarning("\(error.code) : \(error.localizedDescription)")
            }
        }
    }
    
    deinit
    {
        if (!self.closed)
        {
            self.closeFile();
        }
        LKLog("\(self) deinit")
    }
    
    func closeFile()
    {
        
        LKMMapFileCacheManager.queue.sync
        {
            self.timer?.invalidate()
            self.saveConfigFile()
            self._closeFile()
        }
    }
    
    func _closeFile()
    {
        if self.closed
        {
            return
        }
        self.closed = true;
        let mappedFile = self.mappedFile;
        let fileSize = self.fileInfo.size;
        let result = munmap(mappedFile, fileSize);
        if result>0
        {
            LKLogWarning("munmap:\(result)")
        }
    }
    
}

public class LKMMapFileCacheManager: NSObject
{
    private static var __once: () = {
            instance = LKMMapFileCacheManager()
        }()
    static var queue : DispatchQueue = DispatchQueue(label: "com.tencent.filecache", attributes: [])
    static var instance : LKMMapFileCacheManager? = nil
    static var once : Int = 0
    var cacheDic : NSMutableDictionary = [:]
    var _rootPath = ""
    
    
    public var rootPath : String
    {
        get
        {
            return _rootPath;
        }
        set
        {
            if newValue.hasSuffix("/")
            {
                _rootPath = newValue
            }
            else
            {
                _rootPath = newValue+"/"
            }
            
            do
            {
                try FileManager.default().createDirectory(atPath: _rootPath, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError
            {
                LKLogWarning("\(error.code) : \(error.localizedDescription)")
            }
        }
    }
    
    public class func shareInstance() -> LKMMapFileCacheManager
    {
        _ = LKMMapFileCacheManager.__once
        return instance!
    }
    
    override init()
    {
        super.init()
    }
    
    public func openCache(_ path : String, complete : (LKMMapFileCache?,NSError?)->Void)
    {
        if let cache = self.getCache(path)
        {
            complete(cache,nil)
            return
        }
        LKMMapFileCacheManager.queue.sync
        {
            let callback =
                {
                    (cache : LKMMapFileCache?,error : NSError?)->Void in
                    if let error = error
                    {
                        complete(nil,error)
                    }
                    else
                    {
                        self.cacheDic.lk_setWeakObject(cache!, forKey: path)
                        complete(cache,nil)
                    }
                    
            }
            LKMMapFileCache._openFile(self.rootPath+path, complete: callback)
        }
        
    }
    
    public func openOrCreateCache(_ path : String, size : Int, complete : (LKMMapFileCache?,NSError?)->Void)
    {
        if let cache = self.getCache(path)
        {
            complete(cache,nil)
            return
        }
        
        LKMMapFileCacheManager.queue.sync
        {
            let callback =
            {
                (cache : LKMMapFileCache?,error : NSError?)->Void in
                if let error = error
                {
                    complete(nil,error)
                }
                else
                {
                    self.cacheDic.lk_setWeakObject(cache!, forKey: path)
                    complete(cache,nil)
                }
                
            }
            
            LKMMapFileCache._openFile(self.rootPath+path)
            {
                (cache, error) in
                if error != nil
                {
                    LKMMapFileCache._createFile(self.rootPath+path, size: size, complete: callback)
                }
                else
                {
                    if cache?.fileInfo.size == size
                    {
                        self.cacheDic.lk_setWeakObject(cache!, forKey: path)
                        complete(cache,nil)
                    }
                    else
                    {
                        cache?.closeAndDeleteFile()
                        LKMMapFileCache._createFile(self.rootPath+path, size: size, complete: callback)
                    }
                }
            }
        }
        
    }
    
    public func getCache(_ path : String) -> LKMMapFileCache?
    {
        var cache : LKMMapFileCache?
        LKMMapFileCacheManager.queue.sync
        {
            cache = self.cacheDic.lk_objectForKey(path) as? LKMMapFileCache
        }
        return cache;
    }
    
    public func removeAndCloseCache(_ cache : LKMMapFileCache)
    {
        cache.closeFile()
        LKMMapFileCacheManager.queue.async
        {
            let path = cache.path.replacingOccurrences(of: self.rootPath, with: "")
            self.cacheDic.removeObject(forKey: path)
        }
    }
    
    public func removeAndCloseAllCache()
    {
        LKMMapFileCacheManager.queue.async
        {
            for (_,cache) in self.cacheDic
            {
                (cache.object as? LKMMapFileCache)?.closeFile()
            }
            self.cacheDic.removeAllObjects()
        }
    }
}
