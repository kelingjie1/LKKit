//
//  LKLayoutDemoViewController.swift
//  LKKit
//
//  Created by lingtonke on 16/6/23.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit

class LKLayoutDemoViewController: UIViewController
{
    var layoutView = LKLayoutView()
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.layoutView.frame = self.view.bounds
        self.view.addSubview(self.layoutView)
        
        let layoutAttributes = LKLayoutAttributes("Root")
        layoutAttributes.direction = LKLayoutDirection.Vertical
        self.layoutView.layoutAttributes = layoutAttributes;
        
        //block1
        let block1 = LKLayoutAttributes("block1")
        layoutAttributes.append(block1)
        
        
        block1.item = LKLayoutItemAttributes()
        block1.item?.dataSource =
            [
                LKKVC.ClassType:"UIView",
                "backgroundColor":UIColor.lk_randomColor(),
            ]
        block1.heightConstant = 100
        block1.heightMode = LKLayoutHeightMode.Custom
        
        //block2
        let block2 = LKLayoutAttributes("block2")
        layoutAttributes.append(block2)
        block2.edgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        
        let iconBlock = LKLayoutAttributes("iconBlock")
        block2.append(iconBlock,spaceAfter: 5)
        iconBlock.item = LKLayoutItemAttributes()
        iconBlock.item?.dataSource =
            [
                LKKVC.ClassType:"UIImageView",
                "backgroundColor":UIColor.lk_randomColor(),
            ]
        iconBlock.widthMode = LKLayoutWidthMode.Custom
        iconBlock.widthConstant = 40
        
        iconBlock.heightMode = LKLayoutHeightMode.Custom
        iconBlock.heightConstant = 40
        
        let smallIconBlock = LKLayoutAttributes("smallIconBlock")
        iconBlock.append(smallIconBlock)
        smallIconBlock.item = LKLayoutItemAttributes(
            [
                "backgroundColor":UIColor.lk_randomColor(),
            ])
        smallIconBlock.widthMode = LKLayoutWidthMode.Custom
        smallIconBlock.fullWidthMultiplier = 0.5
        
        smallIconBlock.heightMode = LKLayoutHeightMode.Custom
        smallIconBlock.fullHeightMultiplier = 0.5
        
        smallIconBlock.autoAdjustSize = false
        
        let userInfoBlock = LKLayoutAttributes("userInfoBlock")
        block2.append(userInfoBlock)
        userInfoBlock.direction = LKLayoutDirection.Vertical
        userInfoBlock.heightMode = LKLayoutHeightMode.DividedEqually
        
        let userTitleBlock = LKLayoutAttributes("userTitleBlock")
        userInfoBlock.append(userTitleBlock)
        userTitleBlock.heightMode = LKLayoutHeightMode.DividedEqually
        userTitleBlock.item = LKLayoutItemAttributes()
        userTitleBlock.item?.dataSource =
            [
                LKKVC.ClassType:"UILabel",
                "backgroundColor":UIColor.lk_randomColor(),
                "text":"userTitle",
                "font":UIFont.systemFont(ofSize: 13),
            ]
        
        let userSubTitleBlock = LKLayoutAttributes("userSubTitleBlock")
        userInfoBlock.append(userSubTitleBlock)
        userSubTitleBlock.item = LKLayoutItemAttributes()
        userSubTitleBlock.heightMode = LKLayoutHeightMode.DividedEqually
        userSubTitleBlock.item?.dataSource =
            [
                LKKVC.ClassType:"UILabel",
                "backgroundColor":UIColor.lk_randomColor(),
                "text":"userSubTitle",
                "font":UIFont.systemFont(ofSize: 10),
            ]
        
        let followBlock = LKLayoutAttributes("animation1Button")
        block2.append(followBlock)
        followBlock.item = LKLayoutItemAttributes()
        followBlock.item?.dataSource =
            [
                LKKVC.ClassType:"UIButton",
                "backgroundColor":UIColor.lk_randomColor(),
                LKKVC.ButtonTitle:[UIControlState().rawValue:"animation1"],
                "font":UIFont.systemFont(ofSize: 13),
            ]
        followBlock.priority = 1
        followBlock.widthMode = LKLayoutWidthMode.VariableAccodingItemSize
        
        let block3 = LKLayoutAttributes("block3")
        layoutAttributes.append(block3)
        let colorView1 = LKLayoutAttributes()
        block3.append(colorView1)
        colorView1.item = LKLayoutItemAttributes()
        colorView1.item?.dataSource =
            [
                "backgroundColor":UIColor.lk_randomColor(),
            ]
        colorView1.heightMode = LKLayoutHeightMode.Custom
        colorView1.heightConstant = 50
        
        let colorView2 = LKLayoutAttributes("colorView2")
        block3.append(colorView2)
        colorView2.heightMode = LKLayoutHeightMode.DividedEqually
        colorView2.item = LKLayoutItemAttributes()
        colorView2.item?.dataSource =
            [
                "backgroundColor":UIColor.lk_randomColor(),
            ]
        
        let colorView3 = LKLayoutAttributes()
        block3.append(colorView3)
        colorView3.heightMode = LKLayoutHeightMode.DividedEqually
        colorView3.item = LKLayoutItemAttributes()
        colorView3.item?.dataSource =
            [
                "backgroundColor":UIColor.lk_randomColor(),
            ]
        
        
        let block4 = LKLayoutAttributes("block4")
        layoutAttributes.append(block4)
        
        let iconView2 = LKLayoutAttributes("iconView2")
        block4.append(iconView2)
        iconView2.widthMode = LKLayoutWidthMode.Custom
        iconView2.widthConstant = 40
        iconView2.heightMode = LKLayoutHeightMode.Custom
        iconView2.heightConstant = 40
        iconView2.autoAdjustSize = false
        iconView2.verticalAlignment = LKLayoutVerticalAlignment.Bottom
        iconView2.item = LKLayoutItemAttributes(
            [
                "backgroundColor":UIColor.lk_randomColor(),
            ])
        
        let titleList = LKLayoutAttributes("titleList")
        block4.append(titleList)
        titleList.direction = LKLayoutDirection.Vertical
        
        let addTitleButton = LKLayoutAttributes("addTitleButton")
        block4.append(addTitleButton)
        addTitleButton.item = LKLayoutItemAttributes(
            [
                LKKVC.ClassType : "UIButton",
                "backgroundColor":UIColor.lk_randomColor(),
                LKKVC.ButtonTitle : [UIControlState().rawValue : "add"],
            ])
        addTitleButton.widthMode = LKLayoutWidthMode.VariableAccodingItemSize
        
        
        let block5 = LKLayoutAttributes("block5")
        layoutAttributes.append(block5)
        block5.item = LKLayoutItemAttributes(
            [
                "backgroundColor":UIColor.lk_randomColor(),
            ])
        block5.heightMode = LKLayoutHeightMode.Custom
        block5.heightConstant = 40
        
        layoutView.createView()
        
        self.addHandler()
    }
    
    func addHandler()
    {
        if let layoutAttributes = self.layoutView.layoutAttributes
        {
            let button = layoutAttributes.viewListForName("animation1Button").first as! UIButton
            button.addTarget(self, action: #selector(animation1ButtonTouch), for: UIControlEvents.touchUpInside)
            
            let addTitleButton = layoutAttributes.viewListForName("addTitleButton").first as! UIButton
            addTitleButton.addTarget(self, action: #selector(addTitleButtonTouch), for: UIControlEvents.touchUpInside)
        }
        
        
        
    }
    
    func animation1ButtonTouch()
    {
        let colorView2 = self.layoutView.layoutAttributes?.attributesListForName("colorView2").first
        colorView2!.hidden = !colorView2!.hidden
        
        UIView.animate(withDuration: 0.3) { 
            self.layoutView.layoutAttributes?.layout()
        }
        
    }
    
    func addTitleButtonTouch()
    {
        let titleList = self.layoutView.layoutAttributes!.attributesListForName("titleList").first
        let title = LKLayoutAttributes("title\(titleList!.blockList.count)")
        titleList?.append(title)
        title.item = LKLayoutItemAttributes(
            [
                LKKVC.ClassType : "UILabel",
                "text": title.name,
                "backgroundColor":UIColor.lk_randomColor(),
                "font" : UIFont.systemFont(ofSize: CGFloat(Int.lk_random(7, 20))),
            ])
        UIView.animate(withDuration: 0.3) {
            self.layoutView.createView()
        }
    }
}


