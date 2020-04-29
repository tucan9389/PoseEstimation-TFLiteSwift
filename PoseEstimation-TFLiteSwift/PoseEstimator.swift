/*
* Copyright Doyoung Gwak 2020
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

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
    typealias Line = (from: Keypoint, to: Keypoint)
    var keypoints: [Keypoint] = []
    var lines: [Line] = []
    
    func filteredKeypoints(with threshold: Float?) -> [Keypoint] {
        guard let threshold = threshold else { return keypoints }
        return keypoints.filter { $0.score > threshold }
    }
    
    func filteredLines(with threshold: Float?) -> [Line] {
        guard let threshold = threshold else { return lines }
        return lines.filter { $0.from.score > threshold && $0.to.score > threshold }
    }
}

enum PoseEstimationError: Error {
    case failToCreateInputData
    case failToInference
}

protocol PoseEstimator {
    func inference(with input: PoseEstimationInput) -> Result<PoseEstimationOutput, PoseEstimationError>
}
