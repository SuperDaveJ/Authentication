//
//  PaycomUILabel.swift
//  pinEntryUI
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import UIKit

enum AnimationDirection {
    case up
    case down
}

class PaycomUILabel: UILabel {
    
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func fadeUp(_ duration: Double) {
        let yAnimation = CABasicAnimation(keyPath: "position")
        yAnimation.fromValue = self.layer.position
        yAnimation.toValue = CGPoint(x: self.layer.position.x, y: self.layer.position.y - 5)
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.0
        opacityAnimation.toValue = 1.0
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [yAnimation, opacityAnimation]
        groupAnimation.duration = duration
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = CAMediaTimingFillMode.forwards
        
        self.layer.add(groupAnimation, forKey: nil)
        self.layer.opacity = 1.0
        self.layer.position = CGPoint(x: self.layer.position.x, y: self.layer.position.y - 5)
    }
    
    private func fadeDown(_ duration: Double) {
        let yAnimation = CABasicAnimation(keyPath: "position")
        yAnimation.fromValue = self.layer.position
        yAnimation.toValue = CGPoint(x: self.layer.position.x, y: self.layer.position.y  + 5)
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.0
        opacityAnimation.toValue = 1.0
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [yAnimation, opacityAnimation]
        groupAnimation.duration = duration
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = CAMediaTimingFillMode.forwards
        
        self.layer.add(groupAnimation, forKey: nil)
        self.layer.opacity = 1.0
        self.layer.position = CGPoint(x: self.layer.position.x, y: self.layer.position.y  + 5)
    }
    
    func fadeOut(_ duration: Double = 0.33) {
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [opacityAnimation]
        groupAnimation.duration = duration
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = CAMediaTimingFillMode.forwards
        
        self.layer.add(groupAnimation, forKey: nil)
        self.layer.opacity = 0.0
    }
}

