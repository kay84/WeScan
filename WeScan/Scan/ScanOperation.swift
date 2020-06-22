//
//  ScanOperation.swift
//  WeScan
//
//  Created by Boris Emorine on 6/21/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

final class ScanOperation: Operation {
    
    typealias GenerateScannedImageCompletionHandler = (_ scannedImage:UIImage?, _ enhancedImage:UIImage?) -> ()
    
    @objc enum OperationState: Int {
        case ready
        case executing
        case finished
    }
    
    private var image: UIImage
    private var scannedImage: UIImage? = nil
    private var enhancedImage: UIImage? = nil
    private var quad: Quadrilateral
    var completionHandler:GenerateScannedImageCompletionHandler? = nil
    
    @objc private dynamic var state: OperationState
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isReady: Bool {
        return state == .ready
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    required init(withImage image: UIImage, detectedQuad quad:Quadrilateral, _ completion: GenerateScannedImageCompletionHandler?) {
        self.completionHandler = completion
        self.state = .ready
        self.image = image
        self.quad = quad
        super.init()
    }
    
    override func start() {
        self.state = .executing
        guard isCancelled == false else {
            finish()
            return
        }
        
        execute { [weak self] in
            self?.finish()
        }

    }
    
    private func execute(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            try? self?.generateScannedImage(completion: {
                DispatchQueue.main.async {
                    completion()
                }
            })
        }
    }
    
    private func generateScannedImage(completion: (() -> Void)?) throws {
        
        print("generateScannedImage")
        
        guard let ciImage = CIImage(image: self.image) else {
            let error = ImageScannerControllerError.ciImageCreation
            throw(error)
        }
        
        var cartesianScaledQuad = self.quad.toCartesian(withHeight: self.image.size.height)
        cartesianScaledQuad.reorganize()
        
        let filteredImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
            "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
            "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
            ])
        
        let enhancedImage:UIImage? = nil // filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()
        
        var uiImage: UIImage!
        
        // Let's try to generate the CGImage from the CIImage before creating a UIImage.
        if let cgImage = CIContext(options: nil).createCGImage(filteredImage, from: filteredImage.extent) {
            uiImage = UIImage(cgImage: cgImage)
        } else {
            uiImage = UIImage(ciImage: filteredImage, scale: 1.0, orientation: .up)
        }

        self.scannedImage = uiImage.withFixedOrientation()
        self.enhancedImage = enhancedImage
        completion?()
    }
    
    private func finish() {
        state = .finished
        completionHandler?(scannedImage, enhancedImage)
        scannedImage = nil
        enhancedImage = nil
    }
    
}
