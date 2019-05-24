//
//  EditToolsView.swift
//  WeScan
//
//  Created by Alexander Kraicsich on 23.05.19.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import UIKit

class EditToolsView: UIStackView {
    
    weak private var delegate:EditToolsViewDelegate?
    
    lazy private var deleteButton: UIButton = {
        let image = UIImage(named: "delete", in: Bundle(for: EditToolsView.self), compatibleWith: nil)
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(deleteImage(_:)), for: .touchUpInside)
        button.backgroundColor = .clear
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy private var editButton: UIButton = {
        let image = UIImage(named: "crop", in: Bundle(for: EditToolsView.self), compatibleWith: nil)
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(editImage(_:)), for: .touchUpInside)
        button.backgroundColor = .clear
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy private var enhanceButton: UIButton = {
        let image = UIImage(named: "enhance", in: Bundle(for: EditToolsView.self), compatibleWith: nil)
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(toggleEnhancedImage), for: .touchUpInside)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy private var rotateButton: UIButton = {
        let image = UIImage(named: "rotate", in: Bundle(for: EditToolsView.self), compatibleWith: nil)
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(rotateImage), for: .touchUpInside)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    convenience init(bgcolor: UIColor, delegate:EditToolsViewDelegate? = nil) {
     
        self.init(frame: .zero)
        self.delegate = delegate
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        alignment = .fill
        distribution = .fillEqually
        spacing = 0
        
        addArrangedSubview(editButton)
        addArrangedSubview(enhanceButton)
        addArrangedSubview(rotateButton)
        addArrangedSubview(deleteButton)
        
        addBackgroundView(withColor: bgcolor)
        
    }
    
    private func addBackgroundView(withColor bgcolor:UIColor) {
        let subView = UIView()
        subView.backgroundColor = bgcolor
        subView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(subView, at: 0)
        
        subView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        subView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        subView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        subView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }
    
    func setEnhanceButtonActive(_ isActive:Bool) {
        if isActive {
            enhanceButton.tintColor = UIColor(red: 64 / 255, green: 159 / 255, blue: 255 / 255, alpha: 1.0)
        } else {
            enhanceButton.tintColor = .white
        }
    }
    
    // MARK: - Actions
    @objc private func deleteImage(_ sender: Any?) {
        delegate?.editToolsView(editToolsView: self, didPressDeleteButton: self.deleteButton)
    }
    
    @objc private func editImage(_ sender: Any?) {
        delegate?.editToolsView(editToolsView: self, didPressEditButton: self.editButton)
    }
    
    @objc private func toggleEnhancedImage() {
        delegate?.editToolsView(editToolsView: self, didPressToggleEnhancedButton: self.enhanceButton)
    }
    
    @objc private func rotateImage() {
        delegate?.editToolsView(editToolsView: self, didPressRotateButton: rotateButton)
    }
    
}

protocol EditToolsViewDelegate: NSObjectProtocol {
    func editToolsView(editToolsView: EditToolsView, didPressDeleteButton: UIButton)
    func editToolsView(editToolsView: EditToolsView, didPressEditButton: UIButton)
    func editToolsView(editToolsView: EditToolsView, didPressToggleEnhancedButton: UIButton)
    func editToolsView(editToolsView: EditToolsView, didPressRotateButton: UIButton)
}

extension EditToolsViewDelegate {
    func editToolsView(editToolsView: EditToolsView, didPressDeleteButton: UIButton) {}
    func editToolsView(editToolsView: EditToolsView, didPressEditButton: UIButton) {}
    func editToolsView(editToolsView: EditToolsView, didPressToggleEnhancedButton: UIButton) {}
    func editToolsView(editToolsView: EditToolsView, didPressRotateButton: UIButton) {}
}

