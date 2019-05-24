//
//  ScansButton.swift
//  WeScan
//
//  Created by Alexander Kraicsich on 03.08.18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

final class ThumbnailsButton: UIButton {

    fileprivate var badgeLabel:UILabel?
    
    public convenience init(badge badgeString:String? = nil, color badgeColor:UIColor = UIColor(white: 0.0, alpha: 0.6)) {
        
        self.init(type: .custom)
        
        alpha = 0.0
        layer.cornerRadius = 3.0
        clipsToBounds = true
        layer.masksToBounds = false
        translatesAutoresizingMaskIntoConstraints = false
        imageView?.contentMode = .scaleAspectFill
        
        add(badge: badgeString, color: badgeColor)
        
    }
    
    private func add(badge badgeString:String?, color badgeColor:UIColor) {
        
        guard let badgeText = badgeString else { return }
        
        let fontSize = UIFont.smallSystemFontSize
        
        let label = UILabel()
        label.text = " \(badgeText) "
        label.textColor = UIColor.white
        label.backgroundColor = badgeColor
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.layer.cornerRadius = fontSize * CGFloat(0.6)
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.addConstraint(NSLayoutConstraint(item: label, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: label, attribute: .height, multiplier: 1, constant: 0))
        
        addSubview(label)
        addConstraint(NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: -5))
        addConstraint(NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
        
        if badgeString == nil || (badgeString?.isEmpty ?? true) {
            label.isHidden = true
        }
        
        badgeLabel = label
        
    }
    
    public func update(badge badgeString:String?) {
    
        if let label = badgeLabel, let text = badgeString {
            label.text = " \(text) "
            label.isHidden = badgeString?.isEmpty ?? true
        }
        
    }

}
