//
//  PinEntryDotView.swift
//  pinEntryUI
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import UIKit
import Shared

class PinEntryDotView: UIView {
    
    private let dayOvalShapeLayer = CAShapeLayer()
    
    var isActive: Bool = false {
        didSet {
            configure()
        }
    }

    var dotColor = PaycomNamedColor.darkGrayAdaptive.color
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        
        layer.addSublayer(dayOvalShapeLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupShapeLayer(dayOvalShapeLayer)
    }
    
    func configure() {
        self.layoutSubviews()
        if isActive == true {
            emphasize()
        }
    }
    
    private func setupShapeLayer(_ shapeLayer: CAShapeLayer) {
        shapeLayer.frame = self.bounds
        shapeLayer.lineWidth = 2.0
        shapeLayer.fillColor = isActive == true ? dotColor.cgColor : UIColor.clear.cgColor
        shapeLayer.strokeColor = dotColor.cgColor
        
        let arcCenter = shapeLayer.position
        let radius = shapeLayer.bounds.size.width / 2.0
        let startAngle = CGFloat(0.0)
        let endAngle = CGFloat(2.0 * .pi)
        let clockwise = true
        
        let circlePath = UIBezierPath(arcCenter: arcCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
        
        shapeLayer.path = circlePath.cgPath
    }
    
    private func emphasize() {
        let originalTransform = self.transform
        UIView.animateKeyframes(withDuration: 0.2, delay: 0.0, options: .calculationModeCubic, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5, animations: {
                self.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
                self.transform = originalTransform
            })
        })
    }
}

















