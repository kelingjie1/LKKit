//
//  LKContentView.swift
//  LKKit
//
//  Created by lingtonke on 16/6/12.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol LKContentViewDelegate : NSObjectProtocol
{
    @objc optional func LKContentViewLayoutSubviews(_ view : LKContentView);
}

public class LKContentView: UIView,LKContentViewDelegate
{
    public weak var delegate : LKContentViewDelegate?
    
    override public func layoutSubviews()
    {
        super.layoutSubviews()
        self.delegate?.LKContentViewLayoutSubviews?(self)
    }
}
