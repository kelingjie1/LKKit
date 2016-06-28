//
//  LKLayoutAttributes.swift
//  LKKit
//
//  Created by lingtonke on 16/6/22.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit

@objc public enum LKLayoutDirection : Int
{
    case Horizontal
    case Vertical
    
}

@objc public enum LKLayoutHorizontalAlignment : Int
{
    case Middle
    case Left
    case Right
}

@objc public enum LKLayoutVerticalAlignment : Int
{
    case Middle
    case Top
    case Bottom
}

@objc public enum LKLayoutWidthMode : Int
{
    case DividedEqually             //ignorePriority
    case Custom
    case VariableAccodingItemSize
}

@objc public enum LKLayoutHeightMode : Int
{
    case DividedEqually
    case Custom
    case VariableAccodingItemSize
}

public class LKLayoutAttributes : NSObject
{
    var name = String.lk_randomString(type: [LKRandomStringTypeOptions.UpperCaseLetter, LKRandomStringTypeOptions.Number], length: 10)
    var frame = CGRect()
    private var internalHeight : CGFloat = 0
    var item : LKLayoutItemAttributes? = nil
    weak var superBlock : LKLayoutAttributes? = nil
    var blockList : Array<LKLayoutAttributes> = []
    var visibleBlockList : Array<LKLayoutAttributes> = []
    var priority = 0
    var edgeInsets : UIEdgeInsets = UIEdgeInsets()
    var hidden = false

    var defaultInterBlockSpacing : CGFloat = 0
    var interBlockSpacingList : Array<CGFloat> = []
    
    var direction = LKLayoutDirection.Horizontal
    
    var widthMode = LKLayoutWidthMode.DividedEqually
    var heightMode = LKLayoutHeightMode.VariableAccodingItemSize
    var autoAdjustSize = true
    var horizontalAlignment = LKLayoutHorizontalAlignment.Left
    var verticalAlignment = LKLayoutVerticalAlignment.Top
    
    //customWidth
    var fullWidthMultiplier : CGFloat = 0;
    var restWidthMultiplier : CGFloat = 0;
    var widthConstant : CGFloat = 0;
    
    //customHeight
    var fullHeightMultiplier : CGFloat = 0;
    var restHeightMultiplier : CGFloat = 0;
    var heightConstant : CGFloat = 0;
    
    override init()
    {
        super.init()
    }
    
    init(_ name : String)
    {
        self.name = name
        super.init()
    }
    public override var description: String
    {
        return "<LKLayoutAttributes name:\(self.name) frame:\(self.frame)>"
    }
    
    public func attributesAtPathList(_ pathList : Array<String>) -> LKLayoutAttributes?
    {
        if pathList.isEmpty
        {
            return self
        }
        for block in self.blockList
        {
            if block.name == pathList[0]
            {
                var newPathList = pathList
                newPathList.remove(at: 0)
                return block.attributesAtPathList(newPathList)
            }
        }
        return nil
    }
    
    public func attributesListForName(_ name : String) -> Array<LKLayoutAttributes>
    {
        var list = Array<LKLayoutAttributes>()
        for block in self.blockList
        {
            if block.name == name
            {
                list.append(block)
            }
            list.append(contentsOf: block.attributesListForName(name))
        }
        return list
    }
    
    public func viewListForName(_ name : String) -> Array<UIView>
    {
        let list = self.attributesListForName(name)
        var newList = Array<UIView>()
        for attributes in list
        {
            if attributes.item?.view != nil
            {
                newList.append(attributes.item!.view!)
            }
        }
        return newList
    }
    
    public func viewAtPath(_ path : String) -> UIView?
    {
        return self.attributesAtPath(path)?.item?.view
    }
    
    public func attributesAtPath(_ path : String) -> LKLayoutAttributes?
    {
        let array = path.characters.split(separator: ".").map(String.init)
        return self.attributesAtPathList(array)
    }
    
    func append(_ attributes : LKLayoutAttributes,spaceAfter : CGFloat = -1)
    {
        var space = spaceAfter
        if space<0
        {
            space = self.defaultInterBlockSpacing
        }
        attributes.superBlock = self
        self.blockList.append(attributes)
        self.interBlockSpacingList.append(space)
    }
    
    func insert(_ attributes : LKLayoutAttributes, index : Int,spaceAfter : CGFloat = -1)
    {
        var space = spaceAfter
        if space<0
        {
            space = self.defaultInterBlockSpacing
        }
        attributes.superBlock = self
        self.blockList.insert(attributes, at: index)
        self.interBlockSpacingList.insert(space, at: index)
    }
    
    
    func createView(_ inView : UIView)
    {
        item?.createView(inView)
        
        for block in self.blockList
        {
            block.createView(inView)
        }
    }
    
    func layout()
    {
        self.layoutWithWidth()
        self.layoutWithHeight()
        self.layoutPosition()
    }
    
    func allViews() -> Array<UIView>
    {
        if self.item?.view != nil
        {
            return [self.item!.view!]
        }
        var list = Array<UIView>()
        for block in self.blockList
        {
            list.append(contentsOf: block.allViews())
        }
        return list
    }
    
    func layoutWithWidth()
    {
        if self.hidden
        {
            return
        }
        
        self.visibleBlockList.removeAll()
        for block in self.blockList
        {
            if !block.hidden
            {
                self.visibleBlockList.append(block)
            }
        }

            
        if let item = self.item
        {
            item.frame = self.frame
            if self.widthMode == LKLayoutWidthMode.VariableAccodingItemSize || self.heightMode == LKLayoutHeightMode.VariableAccodingItemSize
            {
                item.sizeToFit()
            }
            
            if self.widthMode == LKLayoutWidthMode.VariableAccodingItemSize
            {
                self.frame.width = item.frame.width
            }
            else
            {
                item.frame.width = self.frame.width
            }

            if self.heightMode == LKLayoutHeightMode.VariableAccodingItemSize
            {
                self.frame.height = item.frame.height
            }
        }
        
        if self.blockList.count <= 0
        {
            return
        }
        
        if direction == LKLayoutDirection.Vertical
        {
            for block in visibleBlockList
            {
                block.frame.left = self.frame.left + self.edgeInsets.left
                if block.autoAdjustSize
                {
                    block.frame.width = self.frame.width - edgeInsets.left - edgeInsets.right
                }
                else
                {
                    switch block.widthMode
                    {
                    case LKLayoutWidthMode.Custom:
                        block.frame.width = block.fullWidthMultiplier*self.frame.width+block.restWidthMultiplier*self.frame.width+block.widthConstant
                    case LKLayoutWidthMode.VariableAccodingItemSize:
                        block.frame.width = block.fullWidthMultiplier*self.frame.width+block.restWidthMultiplier*self.frame.width+block.widthConstant
                    default:
                        block.frame.width = self.frame.width - edgeInsets.left - edgeInsets.right
                    }
                }
                
                block.layoutWithWidth()
            }
        }
        else if direction == LKLayoutDirection.Horizontal
        {
            
            var dividList : Array<LKLayoutAttributes> = []
            var orderList : Array<LKLayoutAttributes> = []
            for block in visibleBlockList
            {
                //DividedEqually 单独处理
                if block.widthMode == LKLayoutWidthMode.DividedEqually
                {
                    dividList.append(block)
                }
                else
                {
                    //按priority排序
                    var find = false
                    for i in 0..<orderList.count
                    {
                        if block.priority > orderList[i].priority
                        {
                            find = true
                            orderList.insert(block, at: i)
                            break
                        }
                    }
                    if !find
                    {
                        orderList.append(block)
                    }
                }
                
            }
            
            var totalSpace : CGFloat = 0
            for i in 0..<self.interBlockSpacingList.count-1
            {
                totalSpace += self.interBlockSpacingList[i]
            }
            
            let fullWidth = self.frame.width - totalSpace
            var restWidth = fullWidth - edgeInsets.left - edgeInsets.right
            for block in orderList
            {
                switch block.widthMode
                {
                case LKLayoutWidthMode.Custom:
                    block.frame.width = block.fullWidthMultiplier*fullWidth+block.restWidthMultiplier*restWidth+block.widthConstant
                case LKLayoutWidthMode.VariableAccodingItemSize:
                    block.frame.width = block.fullWidthMultiplier*fullWidth+block.restWidthMultiplier*restWidth+block.widthConstant
                default:
                    break
                }
                block.layoutWithWidth()
                restWidth -= block.frame.width
            }
            
            for block in dividList
            {
                block.frame.width = restWidth/CGFloat(dividList.count)
                block.layoutWithWidth()
            }
            
        }
        
    }
    
    func layoutWithHeight()
    {
        if self.hidden
        {
            return
        }
        
        if let item = self.item
        {
            if self.heightMode == LKLayoutHeightMode.Custom || self.heightMode == LKLayoutHeightMode.DividedEqually
            {
                item.frame.height = self.frame.height
            }
        }
        
        if self.blockList.count <= 0
        {
            return
        }
        
        if direction == LKLayoutDirection.Vertical
        {
            
            var dividList : Array<LKLayoutAttributes> = []
            var orderList : Array<LKLayoutAttributes> = []
            for block in visibleBlockList
            {
                //DividedEqually 单独处理
                if block.heightMode == LKLayoutHeightMode.DividedEqually
                {
                    dividList.append(block)
                }
                else
                {
                    //按priority排序
                    var find = false
                    for i in 0..<orderList.count
                    {
                        if block.priority > orderList[i].priority
                        {
                            find = true
                            orderList.insert(block, at: i)
                            break
                        }
                    }
                    if !find
                    {
                        orderList.append(block)
                    }
                }
                
            }
            
            var totalSpace : CGFloat = 0
            for i in 0..<self.interBlockSpacingList.count-1
            {
                totalSpace += self.interBlockSpacingList[i]
            }
            let fullHeight = self.frame.height - totalSpace
            var restHeight = fullHeight - edgeInsets.top - edgeInsets.bottom
            self.internalHeight = 0
            for block in orderList
            {
                switch block.heightMode
                {
                case LKLayoutHeightMode.Custom:
                    block.frame.height = block.fullHeightMultiplier*fullHeight+block.restHeightMultiplier*restHeight+block.heightConstant
                case LKLayoutHeightMode.VariableAccodingItemSize:
                    break
                default:
                    break
                }
                block.layoutWithHeight()
                restHeight -= block.frame.height
                self.internalHeight += block.frame.height
            }
            
            for i in 0..<dividList.count
            {
                let block = dividList[i]
                block.frame.height = restHeight/CGFloat(dividList.count)
                block.layoutWithHeight()
                self.internalHeight += block.frame.height
            }
            
            if self.heightMode == LKLayoutHeightMode.VariableAccodingItemSize
            {
                self.frame.height = max(self.frame.height,self.internalHeight + self.edgeInsets.top + self.edgeInsets.bottom)
                self.internalHeight = self.frame.height-self.edgeInsets.top-self.edgeInsets.bottom
            }
            
        }
        else if direction == LKLayoutDirection.Horizontal
        {
            var totalSpace : CGFloat = 0
            for i in 0..<self.interBlockSpacingList.count-1
            {
                totalSpace += self.interBlockSpacingList[i]
            }
            let fullHeight = self.frame.height - totalSpace
            let restHeight = fullHeight - edgeInsets.top - edgeInsets.bottom
            
            for i in 0..<self.visibleBlockList.count
            {
                let block = self.visibleBlockList[i]
                switch block.heightMode
                {
                case LKLayoutHeightMode.Custom:
                    block.frame.height = block.fullHeightMultiplier*fullHeight+block.restHeightMultiplier*restHeight+block.heightConstant
                case LKLayoutHeightMode.VariableAccodingItemSize:
                    block.layoutWithHeight()
                default:
                    break
                }
                
                if self.heightMode == LKLayoutHeightMode.VariableAccodingItemSize && block.frame.height > self.internalHeight
                {
                    self.internalHeight = block.frame.height
                }
            }
            
            
            if self.heightMode == LKLayoutHeightMode.VariableAccodingItemSize
            {
                self.frame.height = max(self.frame.height, self.internalHeight + self.edgeInsets.top+self.edgeInsets.bottom)
                self.internalHeight = self.frame.height-self.edgeInsets.top-self.edgeInsets.bottom
            }
            else
            {
                self.internalHeight = self.frame.height - self.edgeInsets.top - self.edgeInsets.bottom
            }
            
            for i in 0..<self.visibleBlockList.count
            {
                let block = self.visibleBlockList[i]
                if block.autoAdjustSize
                {
                    block.frame.height = self.internalHeight
                }
                if block.heightMode != LKLayoutHeightMode.VariableAccodingItemSize
                {
                    block.layoutWithHeight()
                }
                
            }

        }
    }
    public func layoutPosition()
    {
        if let item = self.item
        {
            switch item.horizontalAlignment
            {
            case LKLayoutHorizontalAlignment.Left:
                item.frame.left = self.frame.left
            case LKLayoutHorizontalAlignment.Right:
                item.frame.right = self.frame.right
            case LKLayoutHorizontalAlignment.Middle:
                item.frame.centerX = self.frame.centerX
            }
            
            switch item.verticalAlignment
            {
            case LKLayoutVerticalAlignment.Top:
                item.frame.top = self.frame.top
            case LKLayoutVerticalAlignment.Bottom:
                item.frame.bottom = self.frame.bottom
            case LKLayoutVerticalAlignment.Middle:
                item.frame.centerY = self.frame.centerY
            }
            
            item.layout()
        }
        
        if direction == LKLayoutDirection.Vertical
        {
            var y : CGFloat = edgeInsets.top+self.frame.top
            
            for i in 0..<self.blockList.count
            {
                let block = self.blockList[i]
                
                switch block.horizontalAlignment
                {
                case LKLayoutHorizontalAlignment.Left:
                    block.frame.left = self.frame.left + self.edgeInsets.left
                case LKLayoutHorizontalAlignment.Middle:
                    block.frame.centerX = self.frame.left + self.edgeInsets.left + block.frame.width/2
                case LKLayoutHorizontalAlignment.Right:
                    block.frame.right = self.frame.left + self.edgeInsets.left + block.frame.width
                }
                
                
                switch block.verticalAlignment
                {
                case LKLayoutVerticalAlignment.Top:
                    block.frame.top = y
                case LKLayoutVerticalAlignment.Middle:
                    block.frame.centerY = y + self.internalHeight/2
                case LKLayoutVerticalAlignment.Bottom:
                    block.frame.bottom = y + self.internalHeight
                }

                
                
                
                
                if !block.hidden
                {
                    y += block.frame.height+self.interBlockSpacingList[i]
                }
                block.layoutPosition()
            }
        }
        else if direction == LKLayoutDirection.Horizontal
        {
            var x = self.frame.left + self.edgeInsets.left
            for i in 0..<self.blockList.count
            {
                let block = self.blockList[i]
                switch block.horizontalAlignment
                {
                case LKLayoutHorizontalAlignment.Left:
                    block.frame.left = x
                case LKLayoutHorizontalAlignment.Middle:
                    block.frame.centerX = x + block.frame.width/2
                case LKLayoutHorizontalAlignment.Right:
                    block.frame.right = x + block.frame.width
                }
                
                switch block.verticalAlignment
                {
                case LKLayoutVerticalAlignment.Top:
                    block.frame.top = self.edgeInsets.top + self.frame.top
                case LKLayoutVerticalAlignment.Middle:
                    block.frame.centerY = self.edgeInsets.top + self.frame.top + self.internalHeight/2
                case LKLayoutVerticalAlignment.Bottom:
                    block.frame.bottom = self.edgeInsets.top + self.frame.top + self.internalHeight
                }
                
                
                
                if !block.hidden
                {
                    x += block.frame.width + self.interBlockSpacingList[i]
                }
                block.layoutPosition()
            }
        }
        for block in self.blockList
        {
            if block.hidden
            {
                if let superBlock = block.superBlock
                {
                    if superBlock.direction == LKLayoutDirection.Horizontal
                    {
                        block.allViews().map({ view in
                            var frame = view.frame
                            frame.width = 0
                            view.frame = frame
                        })
                    }
                    else
                    {
                        block.allViews().map({ view in
                            var frame = view.frame
                            frame.height = 0
                            view.frame = frame
                        })
                    }
                }
            }
        }
    }
}

public class LKLayoutItemAttributes : NSObject
{
    var frame = CGRect()
    weak var view : UIView? = nil
    var dataSource : Dictionary<String,AnyObject> = [:]
    var horizontalAlignment = LKLayoutHorizontalAlignment.Middle
    var verticalAlignment = LKLayoutVerticalAlignment.Middle
    init(_ dataSource : Dictionary<String,AnyObject> = [:])
    {
        self.dataSource = dataSource
        super.init()
    }
    
    func createView(_ inView : UIView)
    {
        if self.view != nil
        {
            return
        }
        
        if self.dataSource[LKKVC.ClassType] == nil
        {
            self.dataSource[LKKVC.ClassType] = "UIView"
        }
        
        let view = LKLayoutManager.createView(self.dataSource[LKKVC.ClassType] as! String)
        inView.addSubview(view)
        view.lk_setValuesForKeysEx(dic: self.dataSource) { (obj, key, value) in
            LKLogError("unnameKey")
        }
        self.view = view
        
    }
    
    func sizeToFit()
    {
        if let view = self.view
        {
            view.sizeToFit()
            self.frame.size = view.bounds.size
        }
        else
        {
            LKLogError("noViewInLKLayoutItemAttributes")
        }
        
    }
    
    func layout()
    {
        if let view = self.view
        {
            view.frame = self.frame
        }
        
    }
}
