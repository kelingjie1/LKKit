//
//  LKUtility.swift
//  LKKit
//
//  Created by lingtonke on 16/6/12.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit

extension LKObjc
{
    class public func UIInterfaceOrientationToAngle(_ orientation : UIInterfaceOrientation) -> CGFloat
    {
        return orientation.lk_angle()
    }
}


extension UIInterfaceOrientation
{
    init(deviceOrentation : UIDeviceOrientation)
    {
        switch deviceOrentation
        {
        case UIDeviceOrientation.portrait:
            self = .portrait
        case UIDeviceOrientation.portraitUpsideDown:
            self = .portraitUpsideDown
        case UIDeviceOrientation.landscapeLeft:
            self = .landscapeLeft
        case UIDeviceOrientation.landscapeRight:
            self = .landscapeRight
        default:
            self = .unknown
        }
    }
    
    public func lk_angle() -> CGFloat
    {
        switch self {
        case .landscapeLeft:
            return CGFloat(M_PI_2)
        case .landscapeRight:
            return CGFloat(-M_PI_2)
        case .portraitUpsideDown:
            return CGFloat(M_PI)
        default:
            return 0
        }
    }
}

class LKTargetObject: NSObject
{
    var dic = Dictionary<String,AnyObject>()
    weak var sender : AnyObject?
    var callback : ((targetObject : LKTargetObject)->Void)?
    override init()
    {
        super.init()
    }
    
    func trigger(_ obj : AnyObject)
    {
        callback?(targetObject: self)
    }
}

extension CADisplayLink
{
    class public func lk_animationWithDuration(_ duration : Double, callback : (percent : Double,finished : Bool)->Void)
    {
        let targetObject = LKTargetObject()
        let displayLink = CADisplayLink(target: targetObject, selector: #selector(LKTargetObject.trigger))
        displayLink.add(to: RunLoop.current(), forMode: RunLoopMode.defaultRunLoopMode.rawValue)
        targetObject.sender = displayLink
        var time = 0.0
        targetObject.callback =
            { (targetObject) in
                let link = targetObject.sender as! CADisplayLink
                time+=link.duration
                let duration = targetObject.dic["duration"] as! Double
                if time<duration
                {
                    callback(percent: time/duration, finished: false)
                    
                }
                else
                {
                    callback(percent: 1, finished: true)
                    link.remove(from: RunLoop.current(), forMode: RunLoopMode.defaultRunLoopMode.rawValue)
                }
        }
        targetObject.dic["duration"] = duration
    }
}

extension Float
{
    static public func lk_Between(_ fromValue : Float, toValue : Float, percent : Float)->Float
    {
        return fromValue + ( toValue - fromValue ) * percent
    }
}

extension CGFloat
{
    static public func lk_Between(_ fromValue : CGFloat, toValue : CGFloat, percent : Float)->CGFloat
    {
        return fromValue + ( toValue - fromValue ) * CGFloat(percent)
    }
}

public class LKMath: NSObject
{
    
}

public class LKArrayAutoRemoveObject : LKAutoRemoveObject
{
    var container : NSMutableArray?
    init(object: NSObject, container : NSMutableArray)
    {
        self.container = container
        super.init(object: object)
    }
    
    override func objectReleased()
    {
        container?.remove(self)
        container = nil
    }
}

public class LKSetAutoRemoveObject : LKAutoRemoveObject
{
    var container : NSMutableSet?
    init(object: NSObject, container : NSMutableSet)
    {
        self.container = container
        super.init(object: object)
    }
    
    override func objectReleased()
    {
        container?.remove(self)
        container = nil
    }
}

public class LKDictionaryAutoRemoveObject : LKAutoRemoveObject
{
    var container : NSMutableDictionary?
    var key : NSCopying?
    init(object: NSObject, container : NSMutableDictionary, key : NSCopying)
    {
        self.container = container
        self.key = key
        super.init(object: object)
    }
    
    override func objectReleased()
    {
        container?.removeObject(forKey: key!)
        key = nil
        container = nil
    }
}

public class LKReleaseNotifier : NSObject
{
    var callback : ()->Void
    init(callback : ()->Void)
    {
        self.callback = callback
    }
    
    deinit
    {
        self.callback()
    }
}



public class LKAutoRemoveObjectNotifier : NSObject
{
    var object : LKAutoRemove? = nil
    init(object : LKAutoRemove)
    {
        self.object = object
        super.init()
    }
    
    
    deinit
    {
        self.object?.objectReleased()
        self.object = nil
    }
}

extension NSMutableArray
{
    public func lk_addWeakObject(_ anObject: NSObject)
    {
        self.add(LKArrayAutoRemoveObject(object: anObject,container: self))
    }
    public func lk_insertWeakObject(_ anObject: NSObject, atIndex index: Int)
    {
        self.insert(LKArrayAutoRemoveObject(object: anObject,container: self), at: index)
    }
    public func lk_replaceWithWeakObjectAtIndex(_ index: Int, withObject anObject: NSObject)
    {
        self.replaceObject(at: index, with: LKArrayAutoRemoveObject(object: anObject,container: self))
    }
}

extension NSMutableDictionary
{
    public func lk_setWeakObject(_ anObject: NSObject, forKey aKey: NSCopying)
    {
        self.setObject(LKDictionaryAutoRemoveObject(object: anObject,container: self,key: aKey), forKey: aKey)
    }
    
    public func lk_objectForKey(_ aKey: AnyObject) -> AnyObject?
    {
        if let object = self.object(forKey: aKey) as? LKDictionaryAutoRemoveObject
        {
            return object.object
        }
        else
        {
            return self.object(forKey: aKey)
        }
    }
}

extension NSMutableSet
{
    public func lk_addWeakObject(_ object: NSObject)
    {
        self.add(LKSetAutoRemoveObject(object: object,container: self))
    }
}

public class LKKVC
{
    static let ClassType = "ClassType"
    
    static let ButtonTitle = "ButtonTitle"
}

extension NSObject
{
    public func lk_addReleaseCallback(_ callback : ()->Void)
    {
        let notifier = LKReleaseNotifier(callback: callback)
        if var list = self.lk_getAssociatedObject("LKReleaseNotifierList") as? Array<LKReleaseNotifier>
        {
            list.append(notifier)
        }
        else
        {
            self.lk_setAssociatedObject("LKReleaseNotifierList", value: [notifier])
        }
    }
    
    public func lk_setValuesForKeys(dic : Dictionary<String,AnyObject>,unnameHandle : ((obj : NSObject, key : String, value : AnyObject)->Void)?)
    {
        for (key,value) in dic
        {
            LKObjc.lk_tryCatchFinally(
                {
                    self.setValue(value, forKey: key)
                },
                catch:
                { (exception) in
                    unnameHandle?(obj : self, key : key,value: value)
                }, finallyBlock: nil)
            
        }
        
    }
    
    public func lk_setValuesForKeysEx(dic : Dictionary<String,AnyObject>,unnameHandle : ((obj : NSObject, key : String, value : AnyObject)->Void)?)
    {
        for (key,value) in dic
        {
            var handled = false
            if key == LKKVC.ClassType
            {
                handled = true
            }
            else if let button = self as? UIButton
            {
                if key == LKKVC.ButtonTitle
                {
                    let valueDic = value as! Dictionary<UInt,String>
                    for (rawValue,value) in valueDic
                    {
                        button.setTitle(value, for: UIControlState(rawValue: rawValue))
                    }
                    handled = true
                }
            }
            
            if !handled
            {
                LKObjc.lk_tryCatchFinally(
                    {
                        self.setValue(value, forKey: key)
                    },
                    catch:
                    { (exception) in
                        unnameHandle?(obj : self,key : key,value: value)
                    }, finallyBlock: nil)
            }
            
            
        }
        
    }
    
    public func lk_valuesForKeysEx(keys : Array<String>,unnameHandle : ((obj : NSObject, key : String)->Void)?) -> Dictionary<String,AnyObject>
    {
        var dic = Dictionary<String,AnyObject>()
        for key in keys
        {
            if key == LKKVC.ClassType
            {
                dic[key] = NSStringFromClass(self.self as! AnyClass)
            }
            else if let button = self as? UIButton
            {
                if key == LKKVC.ButtonTitle
                {
                    var stateDic = Dictionary<UInt,String>()
                    dic[key] = stateDic
                    if let title = button.title(for: UIControlState())
                    {
                        stateDic[UIControlState().rawValue] = title
                    }
                    if let title = button.title(for: UIControlState.highlighted)
                    {
                        stateDic[UIControlState.highlighted.rawValue] = title
                    }
                    if let title = button.title(for: UIControlState.disabled)
                    {
                        stateDic[UIControlState.disabled.rawValue] = title
                    }
                    if let title = button.title(for: UIControlState.selected)
                    {
                        stateDic[UIControlState.selected.rawValue] = title
                    }
                }
            }
            else
            {
                LKObjc.lk_tryCatchFinally(
                    {
                        dic[key] = self.value(forKey: key)
                    },
                    catch:
                    { (exception) in
                        unnameHandle?(obj : self, key : key)
                    }, finallyBlock: nil)
            }

        }
        return dic
    }
    
}

public typealias TimerBlock = @convention(block)()->Void
extension Timer
{
    public class func lk_scheduledTimerWithTimeInterval(_ ti: TimeInterval, block : TimerBlock, repeats yesOrNo: Bool) -> Timer
    {
        return self.scheduledTimer(timeInterval: ti, target: self, selector: #selector(lk_blockInvoke), userInfo: unsafeBitCast(block, to: AnyObject.self), repeats: yesOrNo)
    }
    
    class func lk_blockInvoke(_ timer : Timer)
    {
        let block = unsafeBitCast(timer.userInfo, to: TimerBlock.self)
        block()
    }
}

extension UIView
{
    
}

public struct LKRandomStringTypeOptions: OptionSet
{
    public let rawValue: Int
    public init(rawValue : Int)
    {
        self.rawValue = rawValue
    }
    
    public static let LowerCaseLetter = LKRandomStringTypeOptions(rawValue: 1 << 0)
    public static let UpperCaseLetter = LKRandomStringTypeOptions(rawValue: 1 << 1)
    public static let Number = LKRandomStringTypeOptions(rawValue: 1 << 2)
}

extension String
{
    static func lk_randomString(type : LKRandomStringTypeOptions,length : Int) -> String
    {
        
        let Scalars1 = "a".unicodeScalars
        let lowerCaseLetters : [Character] = (0..<26).map { i in Character(UnicodeScalar(Scalars1[Scalars1.startIndex].value+i))}
        let Scalars2 = "A".unicodeScalars
        let upperCaseLetters : [Character] = (0..<26).map { i in Character(UnicodeScalar(Scalars2[Scalars2.startIndex].value+i))}
        let Scalars3 = "0".unicodeScalars
        let numbers : [Character] = (0..<10).map { i in Character(UnicodeScalar(Scalars3[Scalars3.startIndex].value+i))}
        
        var list = Array<Character>()
        if type.contains(LKRandomStringTypeOptions.LowerCaseLetter)
        {
            list.append(contentsOf: lowerCaseLetters)
        }
        if type.contains(LKRandomStringTypeOptions.UpperCaseLetter)
        {
            list.append(contentsOf: upperCaseLetters)
        }
        if type.contains(LKRandomStringTypeOptions.Number)
        {
            list.append(contentsOf: numbers)
        }
        var str = ""
        for _ in 0..<length
        {
            let index = Int(arc4random_uniform(UInt32(list.count)))
            str.append(list[index])
        }
        
        return str
    }
}

extension CGRect
{
    static public func lk_Between(_ fromValue : CGRect, toValue : CGRect, percent : Float)->CGRect
    {
        return CGRect(x: CGFloat.lk_Between(fromValue.origin.x, toValue: toValue.origin.x, percent: percent),
                      y: CGFloat.lk_Between(fromValue.origin.y, toValue: toValue.origin.y, percent: percent),
                      width: CGFloat.lk_Between(fromValue.size.width, toValue: toValue.size.width, percent: percent),
                      height: CGFloat.lk_Between(fromValue.size.height, toValue: toValue.size.height, percent: percent))
    }
    
    var left : CGFloat
    {
        get
        {
            return self.origin.x
        }
        set
        {
            self.origin.x = newValue
        }
    }
    var top : CGFloat
    {
        get
        {
            return self.origin.y
        }
        set
        {
            self.origin.y = newValue
        }
    }
    var width : CGFloat
    {
        get
        {
            return self.size.width
        }
        set
        {
            self.size.width = newValue
        }
    }
    var height : CGFloat
    {
        get
        {
            return self.size.height
        }
        set
        {
            self.size.height = newValue
        }
    }
    
    var right : CGFloat
    {
        get
        {
            return self.origin.x + self.size.width
        }
        set
        {
            self.origin.x = newValue - self.size.width
        }
    }
    
    var bottom : CGFloat
        {
        get
        {
            return self.origin.y + self.size.height
        }
        set
        {
            self.origin.y = newValue - self.size.height
        }
    }
    
    var centerX : CGFloat
        {
        get
        {
            return self.origin.x + self.size.width/2
        }
        set
        {
            self.origin.x = newValue - self.size.width/2
        }
    }
    
    var centerY : CGFloat
        {
        get
        {
            return self.origin.y + self.size.height/2
        }
        set
        {
            self.origin.y = newValue - self.size.height/2
        }
    }
}

extension Int
{
    static func lk_random(_ from:Int,_ to:Int) -> Int
    {
        return Int(arc4random_uniform(UInt32(to - from)))+from
    }
}

extension UIColor
{
    static func lk_randomColor() -> UIColor
    {
        return UIColor(red: CGFloat(Int.lk_random(0, 256)) / CGFloat(256.0), green: CGFloat(Int.lk_random(0, 256)) / CGFloat(256.0), blue: CGFloat(Int.lk_random(0, 256)) / CGFloat(256.0), alpha: 1)
    }
}


func cast<T,U>(_ value:T,to:U.Type) throws -> U.Type
{
    if let value = value as? U.Type
    {
        return value
    }
    throw LKError(code: LKErrorDomain.CastError)
}
