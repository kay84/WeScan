//
//  EditScanViewControllerDelegate.swift
//  WeScan
//
//  Created by Alexander Kraicsich on 20.05.19.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import UIKit

protocol EditScanViewControllerDelegate: NSObjectProtocol {
    func finishedEditingWith(results: ImageScannerResults)
    
}

extension EditScanViewControllerDelegate {
    func finishedEditingWith(results: ImageScannerResults) {}
}
