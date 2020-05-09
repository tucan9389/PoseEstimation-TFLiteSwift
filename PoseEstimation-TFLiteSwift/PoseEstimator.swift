//
//  PoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo
import UIKit

struct PreprocessOptions {
    let cropArea: CropArea
    
    enum CropArea {
        case customAspectFill(rect: CGRect)
        case squareAspectFill
    }
}

struct PostprocessOptions {
    let partThreshold: Float?
    let bodyPart: Int?
    let humanType: HumanType
    
    enum HumanType {
        case singlePerson
        case multiPerson(pairThreshold: Float?, nmsFilterSize: Int, maxHumanNumber: Int?)
    }
}

enum PoseEstimationInput {
    case pixelBuffer(pixelBuffer: CVPixelBuffer, preprocessOptions: PreprocessOptions, postprocessOptions: PostprocessOptions)
    case uiImage(uiImage: UIImage, preprocessOptions: PreprocessOptions, postprocessOptions: PostprocessOptions)
    
    var pixelBuffer: CVPixelBuffer? {
        switch self {
        case .pixelBuffer(let pixelBuffer, _, _):
            return pixelBuffer
        case .uiImage(let uiImage, _, _):
            return uiImage.pixelBufferFromImage()
        }
    }
    
    var cropArea: PreprocessOptions.CropArea {
        switch self {
        case .pixelBuffer(_, let preprocessOptions, _):
            return preprocessOptions.cropArea
        case .uiImage(_, let preprocessOptions, _):
            return preprocessOptions.cropArea
        }
    }
    
    var imageSize: CGSize {
        switch self {
        case .pixelBuffer(let pixelBuffer, _, _):
            return pixelBuffer.size
        case .uiImage(let uiImage, _, _):
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
    
    var partThreshold: Float? {
        return postprocessOptions.partThreshold
    }
    
    var bodyPart: Int? {
        return postprocessOptions.bodyPart
    }
    
    var postprocessOptions: PostprocessOptions {
        switch self {
        case .pixelBuffer(_, _, let options):
            return options
        case .uiImage(_, _, let options):
            return options
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

struct KeypointElement: Equatable {
    let col: Int
    let row: Int
    let val: Float32
    
    init(element: (col: Int, row: Int, val: Float32)) {
        col = element.col
        row = element.row
        val = element.val
    }
    
    static func == (lhs: KeypointElement, rhs: KeypointElement) -> Bool {
        return lhs.col == rhs.col && lhs.row == rhs.row
    }
}

struct PoseEstimationOutput {
    
    var outputs: [TFLiteFlatArray<Float32>]
    var humans: [Human] = []
    
    struct Human {
        typealias Line = (from: Keypoint, to: Keypoint)
        var keypoints: [Keypoint?] = []
        var lines: [Line] = []
    }
}

enum PoseEstimationError: Error {
    case failToCreateInputData
    case failToInference
}

protocol PoseEstimator {
    func inference(_ input: PoseEstimationInput) -> Result<PoseEstimationOutput, PoseEstimationError>
    func postprocessOnLastOutput(options: PostprocessOptions) -> PoseEstimationOutput?
    var partNames: [String] { get }
    var pairNames: [String]? { get }
}
