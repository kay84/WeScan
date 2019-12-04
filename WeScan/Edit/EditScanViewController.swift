//
//  EditScanViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/12/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation

/// The `EditScanViewController` offers an interface for the user to edit the detected quadrilateral.
final class EditScanViewController: UIViewController {
    
    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isOpaque = true
        imageView.image = self.image
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy private var quadView: QuadrilateralView = {
        let quadView = QuadrilateralView()
        quadView.editable = true
        quadView.translatesAutoresizingMaskIntoConstraints = false
        return quadView
    }()
    
    lazy private var buttonContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.cancelButton)
        view.addSubview(self.nextButton)
        return view
    }()
    
    lazy internal var nextButton: UIButton = {
        let title = NSLocalizedString("wescan.edit.button.next", tableName: nil, bundle: Bundle(for: EditScanViewController.self), value: "Next", comment: "A generic next button")
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(showReviewController), for: .touchUpInside)
        button.tintColor = self.navigationController?.navigationBar.tintColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy internal var cancelButton: UIButton = {
        let title = NSLocalizedString("wescan.edit.button.cancel", tableName: nil, bundle: Bundle(for: ImageScannerController.self), value: "Cancel", comment: "A generic cancel button")
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        button.tintColor = self.navigationController?.navigationBar.tintColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy internal var hintLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("wescan.edit.hint", tableName: nil, bundle: Bundle(for: ImageScannerController.self), value: "Hint", comment: "Hint for user")
        label.numberOfLines = 0
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        label.alpha = 1.0
        return label
    }()
    
    lazy internal var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = .black
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    /// The image the quadrilateral was detected on.
    private let image: UIImage
    
    /// The detected quadrilateral that can be edited by the user. Uses the image's coordinates.
    private var quad: Quadrilateral
    
    private var zoomGestureController: ZoomGestureController!
    
    private var quadViewWidthConstraint = NSLayoutConstraint()
    
    private var quadViewHeightConstraint = NSLayoutConstraint()
    
    private var isCropScanScreen: Bool
    
//    private let scanOperationQueue = OperationQueue()
    
    weak var editScanDelegate: EditScanViewControllerDelegate?
    
    // MARK: - Life Cycle
    
    init(image: UIImage, quad: Quadrilateral?, rotateImage: Bool = true, isCropScanScreen: Bool = false) {
        self.image = rotateImage ? image.applyingPortraitOrientation() : image
        self.quad = quad ?? Quadrilateral.defaultQuad(forImage: image)
        self.isCropScanScreen = isCropScanScreen
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupConstraints()
        
        zoomGestureController = ZoomGestureController(image: image, quadView: quadView)
        
        let touchDown = UILongPressGestureRecognizer(target: zoomGestureController, action: #selector(zoomGestureController.handle(pan:)))
        touchDown.cancelsTouchesInView = false
        touchDown.minimumPressDuration = 0
        touchDown.delegate = self
        view.addGestureRecognizer(touchDown)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustQuadViewConstraints()
        displayQuad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Work around for an iOS 11.2 bug where UIBarButtonItems don't get back to their normal state after being pressed.
        navigationController?.navigationBar.tintAdjustmentMode = .normal
        navigationController?.navigationBar.tintAdjustmentMode = .automatic
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
    }
    
    // MARK: - Setups
    private func setupViews() {
        view.addSubview(imageView)
        view.addSubview(quadView)
        view.addSubview(activityIndicator)
        view.addSubview(hintLabel)
        view.addSubview(buttonContainerView)
    }
    
    private func setupConstraints() {
        
        let imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ]

        quadViewWidthConstraint = quadView.widthAnchor.constraint(equalToConstant: 0.0)
        quadViewHeightConstraint = quadView.heightAnchor.constraint(equalToConstant: 0.0)
        
        let quadViewConstraints = [
            quadView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quadView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            quadViewWidthConstraint,
            quadViewHeightConstraint
        ]
        
        let buttonContainerViewConstraints = [
            buttonContainerView.heightAnchor.constraint(equalToConstant: 34.0),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: 20.0),
            view.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor)
        ]
        
        let cancelButtonConstraints = [
            cancelButton.widthAnchor.constraint(equalToConstant: 100.0),
            cancelButton.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 8.0),
            buttonContainerView.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 0)
        ]
        
        let nextButtonnConstraints = [
            nextButton.widthAnchor.constraint(equalToConstant: 100.0),
            buttonContainerView.trailingAnchor.constraint(equalTo: nextButton.trailingAnchor, constant: 8.0),
            buttonContainerView.bottomAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 0)
        ]
        
        let hintLabelConstraints = [
            hintLabel.heightAnchor.constraint(equalToConstant: 32.0),
            hintLabel.widthAnchor.constraint(equalToConstant: view.frame.width - 50),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -100.0)
        ]
        
        let activityIndicatorConstraints = [
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        
        NSLayoutConstraint.activate(
            quadViewConstraints +
            imageViewConstraints +
            buttonContainerViewConstraints +
            cancelButtonConstraints +
            nextButtonnConstraints +
            hintLabelConstraints +
            activityIndicatorConstraints
        )
    }
    
    internal func hideHintLabel() {
        
        if hintLabel.alpha == 0.0 {
            return
        }
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.hintLabel.alpha = 0.0
        }) { completed in
            
        }
        
    }
    
    private func displayQuad() {
        let imageSize = image.size
        let imageFrame = CGRect(origin: quadView.frame.origin, size: CGSize(width: quadViewWidthConstraint.constant, height: quadViewHeightConstraint.constant))
        
        let scaleTransform = CGAffineTransform.scaleTransform(forSize: imageSize, aspectFillInSize: imageFrame.size)
        let transforms = [scaleTransform]
        let transformedQuad = quad.applyTransforms(transforms)
        
        quadView.drawQuadrilateral(quad: transformedQuad, animated: false)
    }
    
    /// The quadView should be lined up on top of the actual image displayed by the imageView.
    /// Since there is no way to know the size of that image before run time, we adjust the constraints to make sure that the quadView is on top of the displayed image.
    private func adjustQuadViewConstraints() {
        let frame = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        quadViewWidthConstraint.constant = frame.size.width
        quadViewHeightConstraint.constant = frame.size.height
    }
    
    private func applyPerspectiveCorrection() {

        guard
            let quad = quadView.quad,
            let cgIm = image.cgImage?.copy()
            else {
                if let imageScannerController = navigationController as? ImageScannerController {
                    let error = ImageScannerControllerError.ciImageCreation
                    imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
                }
                return
        }

        activityIndicator.startAnimating()
        
        let quadViewSize = quadView.bounds.size
        
        DispatchQueue.global().async { [weak self] in
            
            guard let strongSelf = self else { return }
            
            let orgImage = UIImage(cgImage: cgIm, scale: strongSelf.image.scale, orientation: strongSelf.image.imageOrientation)
            let scaledQuad = quad.scale(quadViewSize, orgImage.size)
            strongSelf.quad = scaledQuad
            let results = ImageScannerResults(originalImage: orgImage, detectedRectangle: scaledQuad)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
                
                guard let strongSelf = self else { return }
                
                strongSelf.activityIndicator.stopAnimating()
                
                if strongSelf.navigationController == nil {
                    strongSelf.editScanDelegate?.finishedEditingWith(results: results)
                } else {
                    let galleryViewController = GalleryViewController(with: [results])
                    galleryViewController.galleryDelegate = strongSelf
                    strongSelf.navigationController?.pushViewController(galleryViewController, animated: true)
                }
                
            })
            
        }
        

        // ScanOperation causes a retain cycle. dont know how to fix it right now
//        let scanOperation = ScanOperation(withImage: orgImage, detectedQuad: scaledQuad) { [weak self] scannedImage, enhancedImage in
//
//            guard let strongSelf = self else {
//                return
//            }
//
//            let results = ImageScannerResults(originalImage: orgImage, scannedImage: scannedImage, enhancedImage: enhancedImage, detectedRectangle: scaledQuad)
//
//            if strongSelf.navigationController == nil {
//                strongSelf.editScanDelegate?.finishedEditingWith(results: results)
//            } else {
//                let galleryViewController = GalleryViewController(with: [results])
//                galleryViewController.galleryDelegate = self
//                strongSelf.navigationController?.pushViewController(galleryViewController, animated: true)
//            }
//
//        }
//        scanOperationQueue.addOperation(scanOperation)

        
    }
    
    // MARK: - Actions
    @objc private func showReviewController() {
        applyPerspectiveCorrection()
    }
    
    @objc private func cancelButtonAction() {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - GalleryViewControllerDelegate
extension EditScanViewController: GalleryViewControllerDelegate {
    
    func didSaveResult(results: ImageScannerResults) {
        editScanDelegate?.finishedEditingWith(results: results)
    }
    
}

// MARK: - UIGestureRecognizerDelegate
extension EditScanViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard touch.view != cancelButton && touch.view != nextButton else {
            return false
        }
        hideHintLabel()
        return true
    }
    
}
