//
//  LKOrientationManager.swift
//  LKKit
//
//  Created by lingtonke on 16/6/12.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit


public class LKOrientationManager: NSObject
{
    private static var __once: () = {
            instance = LKOrientationManager()
        }()
    static var instance : LKOrientationManager? = nil
    static var once : Int = 0
    
    static public let LKOrientationDidChangeNotification = "LKOrientagtionDidChangeNotification"
    static public let LKOrientationAttempChangeNotification = "LKOrientagtionAttempChangeNotification"
    
    var supportedOrientations : Set<UIInterfaceOrientation> = [UIInterfaceOrientation.portrait,UIInterfaceOrientation.landscapeLeft,UIInterfaceOrientation.landscapeRight]
    var currentOrientation = UIInterfaceOrientation.portrait
    {
        didSet
        {
            NotificationCenter.default().post(name: Notification.Name(rawValue: LKOrientationManager.LKOrientationDidChangeNotification), object: nil, userInfo: ["orientation":self.currentOrientation.rawValue])
        }
    }
    
    var lastOrientation = UIInterfaceOrientation.portrait
    {
        didSet
        {
            NotificationCenter.default().post(name: Notification.Name(rawValue: LKOrientationManager.LKOrientationAttempChangeNotification), object: nil, userInfo: ["newOrientation":self.lastOrientation.rawValue,"oldOrientation":self.currentOrientation.rawValue])
        }
    }
    
    var lastValidOrientation = UIInterfaceOrientation.portrait
    
    
    var lock = false
    
    public class func shareInstance() -> LKOrientationManager
    {
        _ = LKOrientationManager.__once
        return instance!
    }
    
    override init()
    {
        
        super.init()
        NotificationCenter.default().addObserver(self, selector: #selector(orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    func orientationDidChange(_ notification : Notification)
    {
        let deviceOrientation = UIDevice.current().orientation
        let interfaceOrientation = UIInterfaceOrientation(deviceOrentation: deviceOrientation)
        if supportedOrientations.contains(interfaceOrientation) && lastOrientation != interfaceOrientation
        {
            self.lastOrientation = interfaceOrientation
            if !lock
            {
                self.lastValidOrientation = self.currentOrientation
                self.currentOrientation = interfaceOrientation
            }
        }
    }
}
