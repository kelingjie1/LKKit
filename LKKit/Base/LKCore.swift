//
//  LKCore.swift
//  LKKit
//
//  Created by lingtonke on 16/6/8.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit

@objc public enum LKErrorDomain : Int
{
    //cast
    case CastError
    
    //MMapCache
    case cannotReadConfigFile
    case openDataFileError
    case memoryMapError
    case createDataFileError
    
}


public class LKError: NSError
{
    public var desc = ""

    init(code: LKErrorDomain, desc : String, userInfo dict: [NSObject : AnyObject]?)
    {
        self.desc = desc
        super.init(domain: "LKErrorDomain", code: code.rawValue, userInfo: dict)
    }
    
    init(code: LKErrorDomain)
    {
        super.init(domain: "LKErrorDomain", code: code.rawValue, userInfo: nil)
    }
    
    
    required public init?(coder aDecoder: NSCoder)
    {
        desc = aDecoder.decodeObject(forKey: "desc") as! String
        super.init(coder: aDecoder)
    }
    
    public override func encode(with aCoder: NSCoder)
    {
        aCoder.encode(desc, forKey: "desc")
        super.encode(with: aCoder)
    }
}

public class LKWeakObject : NSObject
{
    weak var object : NSObject? = ""
    override init()
    {
        super.init()
    }
    
    init(object : NSObject)
    {
        self.object = object
        super.init()
    }
    
    public override var description: String
    {
        return "weak_\(self.object?.description)"
    }
    
    deinit
    {
        
    }
}

@objc protocol LKAutoRemove : NSObjectProtocol
{
    func objectReleased()
}

public class LKAutoRemoveObject : LKWeakObject,LKAutoRemove
{
    override init(object : NSObject)
    {
        super.init(object : object)
        self.object?.lk_setAssociatedObject("LKAutoRemoveObjectNotifier", value: LKAutoRemoveObjectNotifier(object: self))
    }
    
    func objectReleased()
    {
        
    }
}



