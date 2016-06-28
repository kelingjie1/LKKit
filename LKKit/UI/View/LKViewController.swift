//
//  LKViewController.swift
//  LKKit
//
//  Created by lingtonke on 16/6/12.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit



public class LKViewController : UIViewController,LKContentViewDelegate
{
    var contentView : LKContentView
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        contentView = LKContentView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        contentView = LKContentView()
        super.init(coder: aDecoder)
    }
    
    public override func loadView()
    {
        self.view = contentView
        contentView.delegate = self
    }
    
    
}
