//
//  ScanGalleryViewController.swift
//  WeScan
//
//  Created by Bobo on 6/22/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

final class ScanGalleryViewController: UIPageViewController {
    
    var results: [ImageScannerResults]
    
    weak var scanGalleryDelegate: ImageScannerResultsDelegateProtocol?
    
    lazy private var doneBarButtonItem: UIBarButtonItem = {
        let title = NSLocalizedString("wescan.button.done", tableName: nil, bundle: Bundle(for: ImageScannerController.self), value: "Done", comment: "The right button of the ScanGalleryViewController")
        let barButtonItem = UIBarButtonItem(title: title, style: UIBarButtonItemStyle.done, target: self, action: #selector(saveImageScannerController(_:)))
        return barButtonItem
    }()
    
    lazy private var bottomContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
        container.addSubview(self.deleteButton)
        container.addSubview(self.editButton)
        return container
    }()
    
    lazy private var deleteButton: UIButton = {
        let title = NSLocalizedString("wescan.button.delete", tableName: nil, bundle: Bundle(for: ImageScannerController.self), value: "Delete", comment: "The bottom left button of the ScanGalleryViewController")
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(deleteCurrentImage(_:)), for: .touchUpInside)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
        
    }()
    
    lazy private var editButton: UIButton = {
        let title = NSLocalizedString("wescan.button.edit", tableName: nil, bundle: Bundle(for: ImageScannerController.self), value: "Edit", comment: "The bottom right button of the ScanGalleryViewController")
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(editCurrentImage(_:)), for: .touchUpInside)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        
        guard let result = results.first else {
            fatalError("This ViewController should be initialized with at least one ImageScannerResults")
        }
        
        dataSource = self
        delegate = self
        
        navigationItem.rightBarButtonItem = doneBarButtonItem
        updateTitleFor(index: 0)
        
        view.addSubview(bottomContainerView)
        setupConstraints()
        
        let viewController = ReviewViewController(results: result)
        setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
    }
    
    private func setupConstraints() {
        let deleteButtonConstraints = [
            deleteButton.widthAnchor.constraint(equalToConstant: 64.0),
            bottomContainerView.trailingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 10.0),
            bottomContainerView.bottomAnchor.constraint(equalTo: deleteButton.bottomAnchor, constant: 0.0),
            bottomContainerView.topAnchor.constraint(equalTo: deleteButton.topAnchor, constant: 0.0)
        ]

        let editButtonConstraints = [
            editButton.widthAnchor.constraint(equalToConstant: 44.0),
            editButton.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: 10.0),
            bottomContainerView.bottomAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 0.0),
            bottomContainerView.topAnchor.constraint(equalTo: editButton.topAnchor, constant: 0.0)
        ]
        
        let toolbarConstraints = [
            bottomContainerView.heightAnchor.constraint(equalToConstant: 44.0),
            bottomContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0.0),
            bottomContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0),
            view.bottomAnchor.constraint(equalTo: bottomContainerView.bottomAnchor, constant: 0.0)
        ]
        
        NSLayoutConstraint.activate(deleteButtonConstraints + editButtonConstraints + toolbarConstraints)
    }
    
    // MARK: - Actions
    
    @objc private func deleteCurrentImage(_ sender: Any?) {
        guard let currentIndex = currentIndex else {
            return
        }
        
        results.remove(at: currentIndex)
        scanGalleryDelegate?.didUpdateResults(results: results)

        guard results.isEmpty == false else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        let viewController = ReviewViewController(results: results[max(currentIndex - 1, 0)])
        let direction = (currentIndex > 0) ? UIPageViewControllerNavigationDirection.reverse : UIPageViewControllerNavigationDirection.forward
        setViewControllers([viewController], direction: direction, animated: true, completion: nil)
        updateTitleForCurrentIndex()
    }
    
    @objc private func editCurrentImage(_ sender: Any?) {
        guard let currentReviewViewController = viewControllers?.first as? ReviewViewController else {
                return
        }

        let editViewController = EditScanViewController(result: currentReviewViewController.results)
        editViewController.delegate = self
        editViewController.modalTransitionStyle = .crossDissolve
        present(editViewController, animated: true, completion: nil)
    }
    
    @objc private func saveImageScannerController(_ sender: UIButton) {
        if let imageScannerController = navigationController as? ImageScannerController {
            imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFinishScanningWithResults: results)
        }
    }
    
    // MARK: - Convenience Functions
    
    private func updateTitleForCurrentIndex() {
        guard let currentIndex = currentIndex else {
            return
        }
        updateTitleFor(index: currentIndex)
    }

    private func updateTitleFor(index: Int) {
        title = String(format: NSLocalizedString("wescan.gallery.title", tableName: nil, bundle: Bundle(for: ImageScannerController.self), value: "%i of %i", comment: "The title indicating the index of the current image and the total number of images"), index + 1, results.count)
    }
    
    private var currentIndex: Int? {
        guard let currentReviewViewController = viewControllers?.first as? ReviewViewController else {
                return nil
        }

        return results.index(of: currentReviewViewController.results)
    }
    
}

extension ScanGalleryViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let reviewViewController = viewController as? ReviewViewController,
        let index = results.index(of: reviewViewController.results),
        index > 0 else {
            return nil
        }
        
        return ReviewViewController(results: results[index - 1])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let reviewViewController = viewController as? ReviewViewController,
            let index = results.index(of: reviewViewController.results),
            index < results.count - 1 else {
                return nil
        }
        
        return ReviewViewController(results: results[index + 1])
    }
    
}

extension ScanGalleryViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        updateTitleForCurrentIndex()
    }
    
}

extension ScanGalleryViewController: ImageScannerResultsDelegateProtocol {
    
    func didUpdateResults(results: [ImageScannerResults]) {
        guard let currentReviewViewController = viewControllers?.first as? ReviewViewController else {
            return
        }
        
        currentReviewViewController.reloadImage()
    }
    
}
