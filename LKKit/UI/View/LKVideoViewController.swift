//
//  LKVideoViewController.swift
//  LKKit
//
//  Created by lingtonke on 16/6/12.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import UIKit

@objc public protocol LKVideoViewControllerDelegate : NSObjectProtocol
{
    @objc optional func LKVideoViewControllerCanTransitionChange(_ controller : LKVideoViewController, orientation : UIInterfaceOrientation)->Bool;
}

public class LKVideoViewController: LKViewController,UIViewControllerTransitioningDelegate
{
    var videoView : LKVideoView
    var interfaceOrientations = UIInterfaceOrientationMask.landscape
    var landscape = true
    {
        didSet
        {
            if landscape
            {
                interfaceOrientations = UIInterfaceOrientationMask.landscape
            }
            else
            {
                interfaceOrientations = UIInterfaceOrientationMask.portrait
            }
            
        }
    }
    
    var player : LKVideoPlayer?
    {
        get
        {
            return self.videoView.player
        }
        set
        {
            self.videoView.player = newValue
        }
    }
    
    var presentAnimator = LKVideoViewControllerPresentAnimator()
    var dismissAnimator = LKVideoViewControllerDissmissAnimator()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        self.videoView = LKVideoView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.view.addSubview(self.videoView)
        self.transitioningDelegate = self
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        self.videoView = LKVideoView()
        super.init(coder: aDecoder)
        self.view.addSubview(self.videoView)
        self.transitioningDelegate = self
    }
    
    public override func viewDidLoad()
    {
        NotificationCenter.default().addObserver(self, selector: #selector(orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    func orientationDidChange(_ notification : Notification)
    {
        
    }
    
    func LKContentViewLayoutSubviews(_ view: LKContentView)
    {
        self.videoView.frame = self.view.bounds
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    {
        return interfaceOrientations
    }
    
    public override func shouldAutorotate() -> Bool
    {
        return true
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        
    }
    
    public func presentFrom(_ fromController : UIViewController, animated : Bool, completion : ((()->Void))?)
    {
        fromController.present(self, animated: animated, completion: completion)
    }
    
    public func animationController(forPresentedController presented: UIViewController, presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        self.dismissAnimator.frame = self.view.frame
        return self.presentAnimator
    }
    
    public func animationController(forDismissedController dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return self.dismissAnimator;
    }
    
}
