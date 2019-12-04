//
//  ScannerViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation

/// The `ScannerViewController` offers an interface to give feedback to the user regarding quadrilaterals that are detected. It also gives the user the opportunity to capture an image with a detected rectangle.
final class ScannerViewController: UIViewController {
    
    var captureSessionManager: CaptureSessionManager?
    internal let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    /// The view that shows the focus rectangle (when the user taps to focus, similar to the Camera app)
    internal var focusRectangle: FocusRectangleView!
    
    /// The view that draws the detected rectangles.
    internal let quadView = QuadrilateralView()
    internal var detectedQuad:Quadrilateral? = nil
    
    ///
    internal var didStartCapturingPicture = false
    
    /// The visual effect (blur) view used on the navigation bar
    private let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let visualEffectViewBgView = UIView(frame: .zero)
    private var visualEffectViewBgColor = UIColor.black.withAlphaComponent(0.3)
    
    /// Whether flash is enabled
    private var flashEnabled = false
    
    /// The original bar style that was set by the host app
    private var originalBarStyle: UIBarStyle?
    
    lazy private var shutterButton: ShutterButton = {
        let button = ShutterButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(captureImage(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy private var closeButton: CloseButton = {
        let button = CloseButton(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
        button.addTarget(self, action: #selector(cancelImageScannerController), for: .touchUpInside)
        return button
    }()
    
    lazy private var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("wescan.scanning.save", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Save", comment: "The Save button"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(saveScannedDocumentsButtonAction), for: .touchUpInside)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.titleLabel?.textAlignment = .left
        return button
    }()
    
    lazy private var autoScanButton: UIBarButtonItem = {
        let title = NSLocalizedString("wescan.scanning.auto", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Auto", comment: "The auto button state")
        let button = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(toggleAutoScan))
        button.tintColor = .white
        return button
    }()
    
    lazy private var flashButton: UIBarButtonItem = {
        let image = UIImage(named: "flash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(toggleFlash))
        button.tintColor = .white
        return button
    }()
    
    lazy internal var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = .black
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    lazy private var thumbnailsButton: ThumbnailsButton = {
        let button = ThumbnailsButton(badge: "")
        button.addTarget(self, action: #selector(showGalleryImages), for: .touchUpInside)
        return button
    }()
    
    internal var documents: [ImageScannerResults] = []
    
    // MARK: - Init
    init(visualEffectViewColor:UIColor? = nil) {
        self.visualEffectViewBgColor = visualEffectViewColor ?? UIColor.black.withAlphaComponent(0.3)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {

        super.viewDidLoad()

        title = nil
        
        setupViews()
        setupNavigationBar()
        setupConstraints()
        
        captureSessionManager = CaptureSessionManager(videoPreviewLayer: videoPreviewLayer)
        captureSessionManager?.delegate = self
        
        originalBarStyle = navigationController?.navigationBar.barStyle
        visualEffectViewBgView.backgroundColor = visualEffectViewBgColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: Notification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.addSubview(self.visualEffectView)
        navigationController?.navigationBar.sendSubview(toBack: self.visualEffectView)
        
        navigationController?.navigationBar.addSubview(self.visualEffectViewBgView)
        navigationController?.navigationBar.sendSubview(toBack: self.visualEffectViewBgView)
        navigationController?.setToolbarHidden(true, animated: true)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        CaptureSession.current.isEditing = false
        quadView.removeQuadrilateral()
        detectedQuad = nil
        didStartCapturingPicture = false
        
        updateThumbnailsButton()
        updateSaveButton()
        enableUserInterface()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSessionManager?.start()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        videoPreviewLayer.frame = view.layer.bounds
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        let visualEffectRect = self.navigationController?.navigationBar.bounds.insetBy(dx: 0, dy: -(statusBarHeight)).offsetBy(dx: 0, dy: -statusBarHeight)
        
        visualEffectViewBgView.frame = visualEffectRect ?? CGRect.zero
        visualEffectView.frame = visualEffectRect ?? CGRect.zero
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CaptureSession.current.isEditing = true
        captureSessionManager?.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        
        visualEffectView.removeFromSuperview()
        visualEffectViewBgView.removeFromSuperview()
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = originalBarStyle ?? .default
        
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else { return }
        if device.torchMode == .on {
            toggleFlash()
        }
    }
    
    // MARK: - Logic
    @objc private func showGalleryImages() {
        let galleryViewController = GalleryViewController(with: documents)
        galleryViewController.galleryDelegate = self
        navigationController?.pushViewController(galleryViewController, animated: true)
    }
    
    func showEditScanViewController(for image:UIImage, withQuad quad:Quadrilateral?) {
        let editViewController = EditScanViewController(image: image, quad: quad)
        editViewController.editScanDelegate = self
        editViewController.modalTransitionStyle = .crossDissolve
        
        let nav = UINavigationController(rootViewController: editViewController)
        navigationController?.present(nav, animated: true, completion: nil)
    }
    
    internal func save(result results:ImageScannerResults) {
        
        dismiss(animated: false, completion: { [weak self] in
            
            guard let strongSelf = self else { return }            
            strongSelf.documents.append(results)
            strongSelf.updateThumbnailsButton()
            strongSelf.updateSaveButton()
            strongSelf.enableUserInterface()
            strongSelf.aniamteNewResult(withImage: results.displayImage)
        })
        
    }
    
    // MARK: - UI
    private func setupViews() {
        
        view.backgroundColor = .black
        
        view.layer.addSublayer(videoPreviewLayer)
        
        quadView.translatesAutoresizingMaskIntoConstraints = false
        quadView.editable = false
        
        view.addSubview(quadView)
        view.addSubview(shutterButton)
        view.addSubview(activityIndicator)
        view.addSubview(thumbnailsButton)
        view.addSubview(saveButton)
        
        updateThumbnailsButton()
        updateSaveButton()
        
    }
    
    private func setupNavigationBar() {
        
        navigationItem.setRightBarButton(autoScanButton, animated: false)
        
        let closeButtonItem = UIBarButtonItem(customView: WrapperView(underlyingView: closeButton))
        navigationItem.leftBarButtonItems = [closeButtonItem, flashButton]
        
        if UIImagePickerController.isFlashAvailable(for: .rear) == false {
            let flashOffImage = UIImage(named: "flashUnavailable", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
            flashButton.image = flashOffImage
            flashButton.tintColor = UIColor.lightGray
        }
        
    }
    
    private func setupConstraints() {
        
        let quadViewConstraints = [
            quadView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: quadView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: quadView.trailingAnchor),
            quadView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ]
        
        var shutterButtonBottomConstraint: NSLayoutConstraint
        
        if #available(iOS 11.0, *) {
            shutterButtonBottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 15.0)
        } else {
            shutterButtonBottomConstraint = view.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 15.0)
        }
        
        let shutterButtonConstraints = [
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButtonBottomConstraint,
            shutterButton.widthAnchor.constraint(equalToConstant: 65.0),
            shutterButton.heightAnchor.constraint(equalToConstant: 65.0)
        ]
        
        let activityIndicatorConstraints = [
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        
        let saveButtonConstraints = [
            saveButton.widthAnchor.constraint(equalToConstant: 100),
            saveButton.heightAnchor.constraint(equalToConstant: 30),
            saveButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            saveButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor)
        ]
        
        let scansButtonConstraints = [
            thumbnailsButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            thumbnailsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15.0),
            thumbnailsButton.widthAnchor.constraint(equalToConstant: 50.0),
            thumbnailsButton.heightAnchor.constraint(equalToConstant: 50.0)
        ]
        
        NSLayoutConstraint.activate(quadViewConstraints + shutterButtonConstraints + activityIndicatorConstraints + saveButtonConstraints + scansButtonConstraints)
        
    }
    
    internal func updateThumbnailsButton() {
        
        guard let doc = documents.last else {
            thumbnailsButton.alpha = 0.0
            return
        }
        
        thumbnailsButton.update(badge: "\(documents.count)")
        thumbnailsButton.alpha = 1.0
        thumbnailsButton.setImage(doc.displayImage.resizeImage(to: CGSize(width: 50, height: 50)), for: .normal)
 
    }
    
    internal func updateSaveButton() {
        saveButton.alpha = documents.count == 0 ? 0.0 : 1.0
    }
    
    internal func enableUserInterface() {
        thumbnailsButton.isUserInteractionEnabled = true
        shutterButton.isUserInteractionEnabled = true
        saveButton.isUserInteractionEnabled = true
    }
    
    internal func disableUserInterface() {
        thumbnailsButton.isUserInteractionEnabled = false
        shutterButton.isUserInteractionEnabled = false
        saveButton.isUserInteractionEnabled = false
    }
    
    private func aniamteNewResult(withImage img:UIImage) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            let imgView = UIImageView(image: img)
            imgView.translatesAutoresizingMaskIntoConstraints = false
            imgView.contentMode = .scaleAspectFit
            strongSelf.view.addSubview(imgView)
            strongSelf.view.bringSubview(toFront: imgView)
            
            let centerX = imgView.centerXAnchor.constraint(equalTo: strongSelf.view.centerXAnchor)
            let centerY = imgView.centerYAnchor.constraint(equalTo: strongSelf.view.centerYAnchor)
            let width = imgView.widthAnchor.constraint(equalToConstant: strongSelf.view.frame.width )
            let height = imgView.heightAnchor.constraint(equalToConstant: strongSelf.view.frame.height)
            
            let targetCenterX = imgView.centerXAnchor.constraint(equalTo: strongSelf.thumbnailsButton.centerXAnchor)
            targetCenterX.isActive = false
            let targetCenterY = imgView.centerYAnchor.constraint(equalTo: strongSelf.thumbnailsButton.centerYAnchor)
            targetCenterY.isActive = false
            
            let imgViewConstraints = [
                centerX,
                centerY,
                width,
                height
            ]
            
            NSLayoutConstraint.activate(imgViewConstraints)
            
            UIView.animate(
                withDuration: 0.75,
                delay: 0,
                animations: {
                    
                    width.constant = 0
                    height.constant = 0
                    
                    centerX.isActive = false
                    centerY.isActive = false
                    
                    targetCenterX.isActive = true
                    targetCenterY.isActive = true
                    
                    imgView.layoutIfNeeded()
                    
                },
                completion: { completed in
                    
                    imgView.removeFromSuperview()
                    
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.updateThumbnailsButton()
                    
            })
            
        }
        
    }
    
    // MARK: - Actions
    @objc private func captureImage(_ sender: UIButton) {
        (navigationController as? ImageScannerController)?.flashToBlack()
        disableUserInterface()
        captureSessionManager?.capturePhoto()
    }
    
    @objc private func toggleAutoScan() {
        if CaptureSession.current.isAutoScanEnabled {
            CaptureSession.current.isAutoScanEnabled = false
            autoScanButton.title = NSLocalizedString("wescan.scanning.manual", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Manual", comment: "The manual button state")
        } else {
            CaptureSession.current.isAutoScanEnabled = true
            autoScanButton.title = NSLocalizedString("wescan.scanning.auto", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Auto", comment: "The auto button state")
        }
    }
    
    @objc private func toggleFlash() {
        let state = CaptureSession.current.toggleFlash()
        
        let flashImage = UIImage(named: "flash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let flashOffImage = UIImage(named: "flashUnavailable", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        
        switch state {
        case .on:
            flashEnabled = true
            flashButton.image = flashImage
            flashButton.tintColor = .yellow
        case .off:
            flashEnabled = false
            flashButton.image = flashImage
            flashButton.tintColor = .white
        case .unknown, .unavailable:
            flashEnabled = false
            flashButton.image = flashOffImage
            flashButton.tintColor = UIColor.lightGray
        }
    }
    
    @objc private func cancelImageScannerController() {
        if let imageScannerController = navigationController as? ImageScannerController {
            imageScannerController.imageScannerDelegate?.imageScannerControllerDidCancel(imageScannerController)
        }
    }
    
    @objc private func saveScannedDocumentsButtonAction() {
        if let imageScannerController = navigationController as? ImageScannerController {
            imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFinishScanningWithResults: documents)
        }
    }
    
}

// MARK: - Tap to Focus
extension ScannerViewController {
    
    /// Called when the AVCaptureDevice detects that the subject area has changed significantly. When it's called, we reset the focus so the camera is no longer out of focus.
    @objc internal func subjectAreaDidChange() {
        /// Reset the focus and exposure back to automatic
        do {
            try CaptureSession.current.resetFocusToAuto()
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager = captureSessionManager else { return }
            captureSessionManager.delegate?.captureSessionManager(captureSessionManager, didFailWithError: error)
            return
        }
        
        /// Remove the focus rectangle if one exists
        CaptureSession.current.removeFocusRectangleIfNeeded(focusRectangle, animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard  let touch = touches.first else { return }
        let touchPoint = touch.location(in: view)
        let convertedTouchPoint: CGPoint = videoPreviewLayer.captureDevicePointOfInterest(for: touchPoint)
        
        CaptureSession.current.removeFocusRectangleIfNeeded(focusRectangle, animated: false)
        
        do {
            try CaptureSession.current.setFocusPointToTapPoint(convertedTouchPoint)
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager = captureSessionManager else { return }
            captureSessionManager.delegate?.captureSessionManager(captureSessionManager, didFailWithError: error)
            return
        }
    }
    
}

// MARK: - RectangleDetectionDelegateProtocol
extension ScannerViewController: RectangleDetectionDelegateProtocol {
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didFailWithError error: Error) {
        
        didStartCapturingPicture = false
        activityIndicator.stopAnimating()
        enableUserInterface()
        
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
    }
    
    func didStartCapturingPicture(for captureSessionManager: CaptureSessionManager) {
        captureSessionManager.stop()
        didStartCapturingPicture = true
        activityIndicator.startAnimating()
        disableUserInterface()
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didCapturePicture picture: UIImage, withQuad quad: Quadrilateral?) {
        didStartCapturingPicture = false
        activityIndicator.stopAnimating()
        disableUserInterface()
        captureSessionManager.stop()
        showEditScanViewController(for: picture, withQuad: quad)
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didDetectQuad quad: Quadrilateral?, _ imageSize: CGSize) {
        
        guard let quad = quad else {
            // If no quad has been detected, we remove the currently displayed on on the quadView.
            quadView.removeQuadrilateral()
            return
        }
        
        if let q = detectedQuad, didStartCapturingPicture {
            quadView.drawQuadrilateral(quad: q, strokeColor:UIColor.red, animated: true)
            return
        }
        
        let portraitImageSize = CGSize(width: imageSize.height, height: imageSize.width)
        
        let scaleTransform = CGAffineTransform.scaleTransform(forSize: portraitImageSize, aspectFillInSize: quadView.bounds.size)
        let scaledImageSize = imageSize.applying(scaleTransform)
        
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        
        let imageBounds = CGRect(origin: .zero, size: scaledImageSize).applying(rotationTransform)
        
        let translationTransform = CGAffineTransform.translateTransform(fromCenterOfRect: imageBounds, toCenterOfRect: quadView.bounds)
        
        let transforms = [scaleTransform, rotationTransform, translationTransform]
        
        let transformedQuad = quad.applyTransforms(transforms)
        
        detectedQuad = transformedQuad
        quadView.drawQuadrilateral(quad: transformedQuad, animated: true)
        
    }
    
}

// MARK: - GalleryViewControllerDelegate
extension ScannerViewController: GalleryViewControllerDelegate {
    
    func didSaveResult(results: ImageScannerResults) {
        
        if let index = documents.index(where: { (r) -> Bool in
            return r.id.uuidString == results.id.uuidString
        })
        {
            documents.remove(at: index)
            documents.insert(results, at: index)
            updateThumbnailsButton()
            updateSaveButton()
            enableUserInterface()
            navigationController?.popViewController(animated: true)
        }
        
    }
    
    func didDeleteResult(results: ImageScannerResults) {
        
        if let index = documents.index(where: { (r) -> Bool in
            return r.id.uuidString == results.id.uuidString
        })
        {
            documents.remove(at: index)
            updateThumbnailsButton()
            updateSaveButton()
            enableUserInterface()
            
            if documents.count == 0 {
                navigationController?.popViewController(animated: true)
            }
            
        }
        
    }
    
}

// MARK: - EditScanViewControllerProtocol
extension ScannerViewController: EditScanViewControllerDelegate {
    
    func finishedEditingWith(results: ImageScannerResults) {
        self.save(result: results)
    }
    
}


class WrapperView: UIView {
    let minimumSize: CGSize = CGSize(width: 44.0, height: 44.0)
    let underlyingView: UIView
    init(underlyingView: UIView) {
        self.underlyingView = underlyingView
        super.init(frame: underlyingView.bounds)
        
        underlyingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(underlyingView)
        
        NSLayoutConstraint.activate([
            underlyingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            underlyingView.centerYAnchor.constraint(equalTo: centerYAnchor),
            underlyingView.heightAnchor.constraint(equalToConstant: underlyingView.frame.height),
            underlyingView.widthAnchor.constraint(equalToConstant: underlyingView.frame.width),
            heightAnchor.constraint(greaterThanOrEqualToConstant: minimumSize.height),
            widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSize.width)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
