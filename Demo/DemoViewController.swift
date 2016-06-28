//
//  DemoViewController.swift
//  LKKit
//
//  Created by lingtonke on 16/6/23.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit

class DemoViewController: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }
}
