//
//  GalleryViewController.swift
//  WeScan
//
//  Created by Bobo on 6/22/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

final class GalleryViewController: UIPageViewController {
    
    var results: [ImageScannerResults]
    internal var currentIndex: Int = 0
    weak var galleryDelegate: GalleryViewControllerDelegate?
    
    private var rotationAngle = Measurement<UnitAngle>(value: 0, unit: .degrees)
    private var enhancedImageIsAvailable:Bool {
        let result = results[currentIndex]
        return result.enhancedImageURL != nil
    }
    private var isCurrentlyDisplayingEnhancedImage:Bool {
        let result = results[currentIndex]
        return result.doesUserPreferEnhancedImage
    }
    
    lazy private var doneBarButtonItem: UIBarButtonItem = {
        let title = NSLocalizedString("wescan.button.done", tableName: nil, bundle: Bundle(for: ImageScannerController.self), value: "Done", comment: "The right button of the ScanGalleryViewController")
        let barButtonItem = UIBarButtonItem(title: title, style: UIBarButtonItem.Style.done, target: self, action: #selector(saveImageScannerController(_:)))
        return barButtonItem
    }()
    
    lazy private var toolsView: EditToolsView = {
        let view = EditToolsView(bgcolor: UIColor(white: 0.0, alpha: 0.6), delegate:self)
        return view
    }()
    
    lazy internal var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.color = .black
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    
    init(with results: [ImageScannerResults]) {
        self.results = results
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = doneBarButtonItem
        
        if results.isEmpty {
            navigationController?.popViewController(animated: true)
            return
        }
        
        delegate = self
        if results.count > 1 {
            dataSource = self
        }
        
        let result = results[currentIndex]
        updateTitleFor(index: currentIndex)
        setupViews()
        setupConstraints()
        
        let viewController = ReviewViewController(image:result.displayImage, index:currentIndex)
        setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
        
        toolsView.setEnhanceButtonActive(isCurrentlyDisplayingEnhancedImage)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        results = []
    }
    
    private func setupViews() {
        view.addSubview(toolsView)
        view.addSubview(activityIndicator)
    }
    
    private func setupConstraints() {
        let bottomContainerViewConstraints = [
            toolsView.heightAnchor.constraint(equalToConstant: 34.0),
            toolsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0.0),
            toolsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0),
            view.bottomAnchor.constraint(equalTo: toolsView.bottomAnchor, constant: 20.0)
        ]
        let activityIndicatorConstraints = [
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(bottomContainerViewConstraints + activityIndicatorConstraints)
    }
    
    // MARK: - Actions
    internal func deleteCurrentImage() {
        
        let removed = results.remove(at: currentIndex)
        galleryDelegate?.didDeleteResult(results: removed)

        guard results.isEmpty == false else {
            navigationController?.popViewController(animated: true)
            return
        }

        currentIndex -= 1
        if currentIndex < 0 {
            currentIndex = 0
        }
        
        let result = results[currentIndex]
        let viewController = ReviewViewController(image:result.displayImage, index:currentIndex)
        let direction = (currentIndex > 0) ? UIPageViewController.NavigationDirection.reverse : UIPageViewController.NavigationDirection.forward
        setViewControllers([viewController], direction: direction, animated: true, completion: nil)
        updatesForCurrentIndex()
    }
    
    internal func editCurrentImage() {

        if self.navigationController?.viewControllers.first is WeScan.EditScanViewController {
            navigationController?.popViewController(animated: true)
            return
        }
        
        let result = results[currentIndex]
        guard let img = result.originalImage else { return }
        
        let quad = result.detectedRectangle
        let editViewController = EditScanViewController(image: img, quad: quad, rotateImage: false, isCropScanScreen: true)
        editViewController.editScanDelegate = self
        editViewController.modalTransitionStyle = .crossDissolve
        present(editViewController, animated: true, completion: nil)
    }
    
    internal func toggleEnhancedImage() {
        
        activityIndicator.startAnimating()
        
        var result = results[currentIndex]
        result.doesUserPreferEnhancedImage.toggle()
        results[currentIndex] = result
        
        let img = result.displayImage.rotated(by: rotationAngle) ?? result.displayImage
        let viewController = ReviewViewController(image: img, index:currentIndex)
        let direction = (currentIndex > 0) ? UIPageViewController.NavigationDirection.reverse : UIPageViewController.NavigationDirection.forward
        setViewControllers([viewController], direction: direction, animated: false, completion: nil)
        
        toolsView.setEnhanceButtonActive(isCurrentlyDisplayingEnhancedImage)
        
        activityIndicator.stopAnimating()
        
    }
    
    internal func rotateImage() {
       
        activityIndicator.startAnimating()
        
        rotationAngle.value += 90
        if rotationAngle.value == 360 {
            rotationAngle.value = 0
        }

        let result = results[currentIndex]
        let img = result.displayImage.rotated(by: rotationAngle) ?? result.displayImage
        let viewController = ReviewViewController(image: img, index:currentIndex)
        let direction = (currentIndex > 0) ? UIPageViewController.NavigationDirection.reverse : UIPageViewController.NavigationDirection.forward
        setViewControllers([viewController], direction: direction, animated: false, completion: nil)
        
        toolsView.setEnhanceButtonActive(isCurrentlyDisplayingEnhancedImage)
        
        activityIndicator.stopAnimating()
        
    }
    
    @objc private func saveImageScannerController(_ sender: UIButton) {
        
        var result = results[currentIndex]
        if result.rotationAngle != rotationAngle {
            result.rotationAngle = rotationAngle
            result.scannedImage = result.scannedImage?.rotated(by: rotationAngle) ?? result.scannedImage
        }

        galleryDelegate?.didSaveResult(results: result)
        
    }
    
    // MARK: - Convenience Functions
    internal func updatesForCurrentIndex() {
        updateTitleFor(index: currentIndex)
        toolsView.setEnhanceButtonActive(isCurrentlyDisplayingEnhancedImage)
    }

    private func updateTitleFor(index: Int) {
        
        if results.count > 1 {
            title = String(format: NSLocalizedString("wescan.gallery.title", tableName: nil, bundle: Bundle(for: ImageScannerController.self), value: "%i of %i", comment: "The title indicating the index of the   current image and the total number of images"), index + 1, results.count)
        }
        else {
            title = nil
        }
        
    }

}

// MARK: - EditScanViewControllerProtocol
extension GalleryViewController: EditScanViewControllerDelegate {
    
    func finishedEditingWith(results: ImageScannerResults) {
        
        let old = self.results[self.currentIndex]
        var new = results
        new.id = old.id
        new.doesUserPreferEnhancedImage = old.doesUserPreferEnhancedImage
        self.results[self.currentIndex] = new
        
        let viewController = ReviewViewController(image: new.displayImage, index:self.currentIndex)
        let direction = (self.currentIndex > 0) ? UIPageViewController.NavigationDirection.reverse : UIPageViewController.NavigationDirection.forward
        setViewControllers([viewController], direction: direction, animated: false, completion: nil)
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - EditToolsViewDelegate
extension GalleryViewController: EditToolsViewDelegate {

    func editToolsView(editToolsView: EditToolsView, didPressDeleteButton: UIButton) {
        self.deleteCurrentImage()
    }
    
    func editToolsView(editToolsView: EditToolsView, didPressEditButton: UIButton) {
        self.editCurrentImage()
    }
    
    func editToolsView(editToolsView: EditToolsView, didPressToggleEnhancedButton: UIButton) {
        self.toggleEnhancedImage()
    }
    
    func editToolsView(editToolsView: EditToolsView, didPressRotateButton: UIButton) {
        self.rotateImage()
    }
    
}

// MARK: - UIPageViewControllerDataSource
extension GalleryViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let reviewViewController = viewController as? ReviewViewController else { return nil }
        
        let newIndex = reviewViewController.index
        if newIndex > 0 {
            let result = results[newIndex - 1]
            return ReviewViewController(image: result.displayImage, index:newIndex - 1)
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let reviewViewController = viewController as? ReviewViewController else { return nil }
        
        let newIndex = reviewViewController.index
        if newIndex < results.count - 1 {
            let result = results[newIndex + 1]
            return ReviewViewController(image: result.displayImage, index:newIndex + 1)
        }
        return nil
    }
    
}

// MARK: - UIPageViewControllerDelegate
extension GalleryViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let reviewViewController = pageViewController.viewControllers?.first as? ReviewViewController else {
            updatesForCurrentIndex()
            return
        }
        currentIndex = reviewViewController.index
        updatesForCurrentIndex()
    }
    
}
