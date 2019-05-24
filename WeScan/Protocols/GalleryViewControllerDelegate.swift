//
//  GalleryViewControllerDelegateProtocol.swift
//  WeScan
//
//  Created by Alexander Kraicsich on 22.05.19.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import Foundation

protocol GalleryViewControllerDelegate: NSObjectProtocol {
    
    func didDeleteResult(results: ImageScannerResults)
    func didSaveResult(results: ImageScannerResults)
    
}

extension GalleryViewControllerDelegate {
    func didDeleteResult(results: ImageScannerResults) {}
    func didSaveResult(results: ImageScannerResults) {}
}
