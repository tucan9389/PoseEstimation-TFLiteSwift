//
//  PoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo
import UIKit

enum PoseEstimationInput {
    enum CropArea {
        case customAspectFill(rect: CGRect)
        case squareAspectFill
    }
    case pixelBuffer(pixelBuffer: CVPixelBuffer, cropArea: CropArea)
    case uiImage(uiImage: UIImage, cropArea: CropArea)
    
    var pixelBuffer: CVPixelBuffer? {
        switch self {
        case .pixelBuffer(let pixelBuffer, _):
            return pixelBuffer
        case .uiImage(let uiImage, _):
            return uiImage.pixelBufferFromImage()
        }
    }
    
    var cropArea: CropArea {
        switch self {
        case .pixelBuffer(_, let cropArea):
            return cropArea
        case .uiImage(_, let cropArea):
            return cropArea
        }
    }
    
    var imageSize: CGSize {
        switch self {
        case .pixelBuffer(let pixelBuffer, _):
            return pixelBuffer.size
        case .uiImage(let uiImage, _):
            return uiImage.size
        }
    }
    
    var targetSquare: CGRect {
        switch cropArea {
        case .customAspectFill(let rect):
            return rect
        case .squareAspectFill:
            let size = imageSize
            let minLength = min(size.width, size.height)
            return CGRect(x: (size.width - minLength) / 2,
                          y: (size.height - minLength) / 2,
                          width: minLength, height: minLength)
        }
    }
    
    func croppedPixelBuffer(with inputModelSize: CGSize) -> CVPixelBuffer? {
        guard let pixelBuffer = pixelBuffer else { return nil }
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        assert(sourcePixelFormat == kCVPixelFormatType_32BGRA)
        
        // Resize `targetSquare` of input image to `modelSize`.
        return pixelBuffer.resize(from: targetSquare, to: inputModelSize)
    }
}

struct Keypoint {
    let position: CGPoint
    let score: Float
}

struct PoseEstimationOutput {
    
    var outputs: [TFLiteFlatArray<Float32>]
    var humans: [Human] = []
    
    struct Human {
        typealias Line = (from: Keypoint, to: Keypoint)
        var keypoints: [Keypoint?] = []
        var lines: [Line] = []
        
        func filteredKeypoints(with threshold: Float?) -> [Keypoint?] {
            guard let threshold = threshold else { return keypoints }
            return keypoints.map {
                guard let kp = $0, kp.score > threshold else { return nil }
                return kp
            }
        }
        
        func filteredLines(with threshold: Float?) -> [Line] {
            guard let threshold = threshold else { return lines }
            return lines.filter { $0.from.score > threshold && $0.to.score > threshold }
        }
    }
}

enum PoseEstimationError: Error {
    case failToCreateInputData
    case failToInference
}

protocol PoseEstimator {
    func inference(_ input: PoseEstimationInput, with threshold: Float?, on partIndex: Int?) -> Result<PoseEstimationOutput, PoseEstimationError>
    func postprocessOnLastOutput(with threshold: Float?, on partIndex: Int?) -> PoseEstimationOutput?
    var partNames: [String] { get }
    var pairNames: [String]? { get }
}
