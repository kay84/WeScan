//
//  CloseButton.swift
//  WeScan
//
//  Created by Boris Emorine on 2/27/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// A simple close button shaped like an "X".
final public class CloseButton: UIControl {
    
    let xLayer = CAShapeLayer()
    
    // UIAppearance compatible property
    @objc dynamic public var strokeColor: UIColor? {
        get { return self._strokeColor }
        set { self._strokeColor = newValue }
    }
    @objc dynamic public var fillColor: UIColor? {
        get { return self._fillColor }
        set { self._fillColor = newValue }
    }
    
    private var _strokeColor: UIColor? = .white
    private var _fillColor: UIColor? = .clear
    
    convenience public init(frame: CGRect, strokeColor:UIColor, fillColor:UIColor) {
        self.init(frame: frame)
        self.strokeColor = strokeColor
        self.fillColor = fillColor
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(xLayer)
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitButton
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func draw(_ rect: CGRect) {
        self.clipsToBounds = false
        xLayer.frame = rect
        xLayer.lineWidth = 3.0
        xLayer.path = pathForX(inRect: rect.insetBy(dx: xLayer.lineWidth / 2, dy: xLayer.lineWidth / 2)).cgPath
        xLayer.fillColor = _fillColor?.cgColor
        xLayer.strokeColor = _strokeColor?.cgColor
        xLayer.lineCap = kCALineCapRound
    }
    
    private func pathForX(inRect rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: rect.origin)
        path.addLine(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height))
        path.move(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y))
        path.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height))
        
        return path
    }

}
