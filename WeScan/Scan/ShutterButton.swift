//
//  ShutterButton.swift
//  WeScan
//
//  Created by Boris Emorine on 2/26/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// A simple button used for the shutter.
final public class ShutterButton: UIControl {
    
    // UIAppearance compatible property
    @objc dynamic public var outterRingFillColor: UIColor? {
        get { return self._outterRingFillColor }
        set { self._outterRingFillColor = newValue }
    }
    @objc dynamic public var innerCircleFillColor: UIColor? {
        get { return self._innerCircleFillColor }
        set { self._innerCircleFillColor = newValue }
    }
    
    private var _outterRingFillColor: UIColor? = .white
    private var _innerCircleFillColor: UIColor? = .white
    
    private let outterRingLayer = CAShapeLayer()
    private let innerCircleLayer = CAShapeLayer()
    
    private let outterRingRatio: CGFloat = 0.80
    private let innerRingRatio: CGFloat = 0.75
    
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    override public var isHighlighted: Bool {
        didSet {
            if oldValue != isHighlighted {
                animateInnerCircleLayer(forHighlightedState: isHighlighted)
            }
        }
    }
    
    // MARL: Life Cycle
    
    convenience public init(frame: CGRect, outterRingFillColor:UIColor, innerCircleFillColor:UIColor) {
        self.init(frame: frame)
        self.outterRingFillColor = outterRingFillColor
        self.innerCircleFillColor = innerCircleFillColor
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(outterRingLayer)
        layer.addSublayer(innerCircleLayer)
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitButton
        impactFeedbackGenerator.prepare()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    
    override public func draw(_ rect: CGRect) {
        outterRingLayer.frame = rect
        outterRingLayer.path = pathForOutterRing(inRect: rect).cgPath
        outterRingLayer.fillColor = _outterRingFillColor?.cgColor
        outterRingLayer.rasterizationScale = UIScreen.main.scale
        outterRingLayer.shouldRasterize = true
        
        innerCircleLayer.frame = rect
        innerCircleLayer.path = pathForInnerCircle(inRect: rect).cgPath
        innerCircleLayer.fillColor = _innerCircleFillColor?.cgColor
        innerCircleLayer.rasterizationScale = UIScreen.main.scale
        innerCircleLayer.shouldRasterize = true
    }
    
    // MARK: - Animation
    
    private func animateInnerCircleLayer(forHighlightedState isHighlighted: Bool) {
        let animation = CAKeyframeAnimation(keyPath: "transform")
        var values = [CATransform3DMakeScale(1.0, 1.0, 1.0), CATransform3DMakeScale(0.9, 0.9, 0.9), CATransform3DMakeScale(0.93, 0.93, 0.93), CATransform3DMakeScale(0.9, 0.9, 0.9)]
        if isHighlighted == false {
            values = [CATransform3DMakeScale(0.9, 0.9, 0.9), CATransform3DMakeScale(1.0, 1.0, 1.0)]
        }
        animation.values = values
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.duration = isHighlighted ? 0.35 : 0.10
        
        innerCircleLayer.add(animation, forKey: "transform")
        impactFeedbackGenerator.impactOccurred()
    }
    
    // MARK: - Paths
    
    private func pathForOutterRing(inRect rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath(ovalIn: rect)
        
        let innerRect = rect.scaleAndCenter(withRatio: outterRingRatio)
        let innerPath = UIBezierPath(ovalIn: innerRect).reversing()
        
        path.append(innerPath)
        
        return path
    }
    
    private func pathForInnerCircle(inRect rect: CGRect) -> UIBezierPath {
        let rect = rect.scaleAndCenter(withRatio: innerRingRatio)
        let path = UIBezierPath(ovalIn: rect)
        
        return path
    }
    
}
