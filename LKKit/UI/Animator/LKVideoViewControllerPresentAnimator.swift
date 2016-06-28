//
//  LKVideoViewControllerPresentAnimator.swift
//  LKKit
//
//  Created by lingtonke on 16/6/12.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

import Foundation
import UIKit

public class LKVideoViewControllerPresentAnimator: NSObject,UIViewControllerAnimatedTransitioning
{
    public func transitionDuration(_ transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.3
    }
    
    public func animateTransition(_ transitionContext: UIViewControllerContextTransitioning)
    {
        //let fromController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toController = transitionContext.viewController(forKey: UITransitionContextToViewControllerKey)!
        NSLog("\(UIScreen.main().bounds)")
        transitionContext.containerView().addSubview(toController.view)
        toController.view.transform = CGAffineTransform(rotationAngle: -CGFloat(M_PI_2));
        
        UIView.animate(withDuration: self.transitionDuration(transitionContext), animations:{
            toController.view.transform = CGAffineTransform.identity
            toController.view.frame = UIScreen.main().bounds
            toController.view.layoutIfNeeded()
        }){ (finished) in
            transitionContext.completeTransition(finished)
            NSLog("\(toController.view)")
        }
    }
}

public class LKVideoViewControllerDissmissAnimator: NSObject,UIViewControllerAnimatedTransitioning
{
    var frame = CGRect()
    public func transitionDuration(_ transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.3
    }
    
    public func animateTransition(_ transitionContext: UIViewControllerContextTransitioning)
    {
        let fromController = transitionContext.viewController(forKey: UITransitionContextFromViewControllerKey)!
        let toController = transitionContext.viewController(forKey: UITransitionContextToViewControllerKey)!
        NSLog("\(UIScreen.main().bounds)")
        transitionContext.containerView().addSubview(toController.view)
        toController.view.addSubview(fromController.view)
        toController.view.frame = UIScreen.main().bounds
        fromController.view.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2));
        fromController.view.frame = toController.view.bounds
        
        UIView.animate(withDuration: self.transitionDuration(transitionContext), animations:{
            fromController.view.transform = CGAffineTransform.identity
            fromController.view.frame = self.frame
            fromController.view.layoutIfNeeded()
        }){ (finished) in
            transitionContext.completeTransition(finished)
            toController.view.addSubview(fromController.view)
            fromController.view.transform = CGAffineTransform.identity
            fromController.view.frame = self.frame
            NSLog("\(toController.view)")
        }
    }
}
