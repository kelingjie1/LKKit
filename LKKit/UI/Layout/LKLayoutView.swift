//
//  LKLayoutView.swift
//  LKKit
//
//  Created by lingtonke on 16/6/22.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit

public class LKLayoutView : UIView
{
    var layoutAttributes : LKLayoutAttributes? = nil
    func createView()
    {
        if let layoutAttributes = self.layoutAttributes
        {
            for block in layoutAttributes.blockList
            {
                block.createView(self)
            }
            layoutAttributes.frame = self.bounds
            layoutAttributes.layout()
        }
        else
        {
            LKLogError("layoutAttributes must be set")
        }
    }
    func layout()
    {
        layoutAttributes?.layout()
    }
}
