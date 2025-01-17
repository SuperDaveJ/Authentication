//
//  UIView+Extension.swift
//  Authentication
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Foundation


extension UIView {
    
    // Shake Screen View
    public func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
}
