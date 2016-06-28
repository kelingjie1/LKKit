//
//  LKLayoutManager.swift
//  LKKit
//
//  Created by lingtonke on 16/6/22.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit

public class LKLayoutManager: NSObject
{
    static var instance : LKLayoutManager? = nil
    private static var once: () = {
        instance = LKLayoutManager()
    }()
    
    class func shareInstance() -> LKLayoutManager
    {
        _ = once
        return instance!
    }
    
    func handleProperty(_ object : NSObject, key:NSObject, value : AnyObject)
    {
        
    }
    
    class func createView(_ className : String) -> UIView
    {
        let UIViewType = NSClassFromString(className) as! UIView.Type
        return UIViewType.init()
    }
}
