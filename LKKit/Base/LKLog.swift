//
//  LKLog.swift
//  LKKit
//
//  Created by lingtonke on 16/6/8.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation

@objc public enum LKLogLevel : Int,CustomStringConvertible
{
    case message,warning,error
    
    public var description: String
    {
        switch self {
        case .message:
            return "Message"
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        }
    }
}

public func LKLog(_ format: String, _ args: CVarArg...)
{
    LKLog(String(format: format,arguments: args), level: LKLogLevel.message)
}

public func LKLogWarning(_ format: String, _ args: CVarArg...)
{
    LKLog(String(format: format,arguments: args), level: LKLogLevel.warning)
}

public func LKLogError(_ format: String, _ args: CVarArg...)
{
    LKLog(String(format: format,arguments: args), level: LKLogLevel.error)
}

public func LKLog(_ format: String, _ args: CVarArg..., level : LKLogLevel)
{
    LKLogManager.shareInstance().log(String(format: format,arguments: args), level: level)
}

public class LKLogManager : NSObject
{
    private static var __once: () = {
            instance = LKLogManager()
        }()
    static var instance : LKLogManager? = nil
    static var once : Int = 0
    
    var listenerList : Array<(String,LKLogLevel)->Void> = []
    
    public class func shareInstance() -> LKLogManager
    {
        _ = LKLogManager.__once
        return instance!
    }
    
    public func addListener(_ listener : (String,LKLogLevel)->Void)
    {
        self.listenerList.append(listener)
    }
    
    public func log(_ log : String, level : LKLogLevel)
    {
        for listener in self.listenerList
        {
            listener(log,level)
        }
        if listenerList.isEmpty
        {
            print("\(level):\(log)")
        }
        
        if level == LKLogLevel.error
        {
            print(" ")
        }
    }
}
